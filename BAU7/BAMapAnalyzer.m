//
//  BAMapAnalyzer.m
//  BAU7
//
//  Created by Tom on 2/16/26.
//

#import "Includes.h"
#import "BAMapAnalyzer.h"

@protocol U7StaticItemLike <NSObject>
@optional
- (long)shapeID;       // Actual property name in U7ShapeReference
- (int)frameNumber;    // Actual property name in U7ShapeReference
- (long)shapeIndex;    // Fallback for other types
- (int)frameIndex;     // Fallback for other types
- (id)shape;           // object that may respond to -index
@end

@implementation BAMapAnalyzer
{
    U7Map *_map;
    NSMutableArray *_cities;
    NSMutableArray *_roads;
    NSMutableDictionary *_terrainStats;
    NSMutableSet *_visitedTiles;
    int *_terrainGrid; // 192x192 grid of terrain types
}

- (instancetype)initWithMap:(U7Map *)map
{
    self = [super init];
    if (self) {
        _map = map;
        _cities = [NSMutableArray array];
        _roads = [NSMutableArray array];
        _terrainStats = [NSMutableDictionary dictionary];
        _visitedTiles = [NSMutableSet set];
        
        // Allocate terrain grid (192x192 chunks)
        _terrainGrid = calloc(192 * 192, sizeof(int));
    }
    return self;
}

- (void)analyze
{
    NSLog(@"Starting map analysis...");
    
    // Phase 0: Sample shapes to find what IDs are actually used
    [self sampleShapeDistribution];
    
    // Phase 1: Analyze terrain FIRST (needed for city vs dungeon detection)
    [self analyzeTerrainDistribution];
    
    // Phase 2: Find individual building structures
    NSArray *buildings = [self scanForBuildings];
    
    // Phase 3: Group nearby buildings into cities (filtering out dungeons)
    [self groupBuildingsIntoCities:buildings];
    
    // Phase 4: (Future) Detect roads, etc.
    
    NSLog(@"Analysis complete! Found %lu cities", (unsigned long)[_cities count]);
}

- (void)sampleShapeDistribution
{
    NSMutableDictionary *shapeCounts = [NSMutableDictionary dictionary];
    int sampleSize = 0;
    
    // Sample every 8th chunk to get a quick overview
    for (int chunkY = 0; chunkY < 192; chunkY += 8) {
        for (int chunkX = 0; chunkX < 192; chunkX += 8) {
            
            long chunkIndex = [_map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
            U7MapChunk *mapChunk = [_map mapChunkAtIndex:chunkIndex];
            if (!mapChunk) continue;
            
            U7Chunk *chunk = mapChunk->masterChunk;
            if (!chunk || !chunk->chunkMap) continue;
            
            for (int i = 0; i < [chunk->chunkMap count]; i++) {
                U7ChunkIndex *chunkIdx = chunk->chunkMap[i];
                long shapeID = chunkIdx->shapeIndex;
                
                NSNumber *key = @(shapeID);
                shapeCounts[key] = @([shapeCounts[key] intValue] + 1);
                sampleSize++;
            }
        }
    }
    
    // Log top 20 most common shapes
    NSArray *sortedShapes = [shapeCounts keysSortedByValueUsingComparator:^NSComparisonResult(NSNumber *count1, NSNumber *count2) {
        return [count2 compare:count1]; // Descending order
    }];
    
    NSLog(@"Shape Distribution (sampled %d tiles):", sampleSize);
    for (int i = 0; i < MIN(20, [sortedShapes count]); i++) {
        NSNumber *shapeID = sortedShapes[i];
        int count = [shapeCounts[shapeID] intValue];
        NSLog(@"  Shape %ld: %d occurrences (%.1f%%)", [shapeID longValue], count, (count * 100.0 / sampleSize));
    }
}

- (NSArray *)scanForBuildings
{
    NSMutableArray *buildings = [NSMutableArray array];
    int mapWidth = 192;
    int mapHeight = 192;
    int chunkSize = 16;
    int buildingTilesFound = 0;
    
    NSLog(@"Scanning for individual buildings...");
    
    for (int chunkY = 0; chunkY < mapHeight; chunkY++) {
        for (int chunkX = 0; chunkX < mapWidth; chunkX++) {
            
            long chunkIndex = [_map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
            U7MapChunk *mapChunk = [_map mapChunkAtIndex:chunkIndex];
            if (!mapChunk) continue;
            
            U7Chunk *chunk = mapChunk->masterChunk;
            if (!chunk || !chunk->chunkMap) continue;
            
            for (int tileY = 0; tileY < chunkSize; tileY++) {
                for (int tileX = 0; tileX < chunkSize; tileX++) {
                    
                    int worldX = chunkX * chunkSize + tileX;
                    int worldY = chunkY * chunkSize + tileY;
                    NSString *key = [NSString stringWithFormat:@"%d,%d", worldX, worldY];
                    
                    if ([_visitedTiles containsObject:key]) {
                        continue;
                    }
                    
                    int tileIndex = tileY * chunkSize + tileX;
                    if (tileIndex < [chunk->chunkMap count]) {
                        U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIndex];
                        long shapeID = chunkIdx->shapeIndex;
                        
                        if ([self isBuildingShape:shapeID]) {
                            buildingTilesFound++;
                            
                            NSDictionary *building = [self floodFillBuildingsFromX:worldX y:worldY];
                            
                            if ([building[@"tileCount"] intValue] >= 6) {
                                [buildings addObject:building];
                            }
                        }
                    }
                }
            }
        }
    }
    
    NSLog(@"Found %lu individual buildings (%d total tiles)", (unsigned long)[buildings count], buildingTilesFound);
    return buildings;
}

- (void)groupBuildingsIntoCities:(NSArray *)buildings
{
    NSLog(@"Grouping buildings into cities...");
    
    NSMutableArray *remainingBuildings = [buildings mutableCopy];
    int cityRadius = 150; // Buildings within 150 tiles are part of the same city
    int dungeonCount = 0; // Track how many clusters we reject as dungeons
    
    while ([remainingBuildings count] > 0) {
        NSDictionary *seed = remainingBuildings[0];
        [remainingBuildings removeObjectAtIndex:0];
        
        int seedX = [seed[@"x"] intValue];
        int seedY = [seed[@"y"] intValue];
        
        NSMutableArray *cityBuildings = [NSMutableArray arrayWithObject:seed];
        
        // Find all buildings within radius
        NSMutableArray *toRemove = [NSMutableArray array];
        for (NSDictionary *building in remainingBuildings) {
            int bx = [building[@"x"] intValue];
            int by = [building[@"y"] intValue];
            
            int dx = bx - seedX;
            int dy = by - seedY;
            int distance = sqrt(dx*dx + dy*dy);
            
            if (distance < cityRadius) {
                [cityBuildings addObject:building];
                [toRemove addObject:building];
            }
        }
        
        [remainingBuildings removeObjectsInArray:toRemove];
        
        // If we have 10+ buildings, check if it's a city or dungeon
        if ([cityBuildings count] >= 10) {
            // Calculate cluster bounds
            int minX = 9999, maxX = 0, minY = 9999, maxY = 0;
            int totalTiles = 0;
            
            for (NSDictionary *b in cityBuildings) {
                int x = [b[@"x"] intValue];
                int y = [b[@"y"] intValue];
                int w = [b[@"width"] intValue];
                int h = [b[@"height"] intValue];
                int tiles = [b[@"tileCount"] intValue];
                
                if (x < minX) minX = x;
                if (x + w > maxX) maxX = x + w;
                if (y < minY) minY = y;
                if (y + h > maxY) maxY = y + h;
                totalTiles += tiles;
            }
            
            // Check surrounding terrain to distinguish city from dungeon
            BOOL isCity = [self isClusterACityAtX:minX y:minY width:(maxX - minX) height:(maxY - minY)];
            
            if (isCity) {
                NSDictionary *city = @{
                    @"x": @(minX),
                    @"y": @(minY),
                    @"width": @(maxX - minX),
                    @"height": @(maxY - minY),
                    @"buildingCount": @([cityBuildings count]),
                    @"tileCount": @(totalTiles)
                };
                
                NSLog(@"Found CITY: %lu buildings, %d tiles at (%d, %d)", 
                      (unsigned long)[cityBuildings count], totalTiles, minX, minY);
                
                [_cities addObject:city];
            } else {
                dungeonCount++;
                NSLog(@"Found DUNGEON (rejected): %lu buildings, %d tiles at (%d, %d)", 
                      (unsigned long)[cityBuildings count], totalTiles, minX, minY);
            }
        }
    }
    
    NSLog(@"City detection complete: Found %lu cities, %d dungeons", (unsigned long)[_cities count], dungeonCount);
}

- (BOOL)isClusterACityAtX:(int)worldX y:(int)worldY width:(int)width height:(int)height
{
    // FIRST: Check if the cluster has SIGNIFICANT mountain coverage
    // Dungeons have mountains as primary feature (>30%), cities might have decorative mountains
    float mountainPercent = [self mountainPercentInClusterAtX:worldX y:worldY width:width height:height];
    
    if (mountainPercent > 30.0) {
        NSLog(@"  Cluster at (%d,%d): DUNGEON - %.1f%% mountain shapes (dungeon entrance)",
              worldX, worldY, mountainPercent);
        return NO;
    }
    
    // Check the terrain SURROUNDING this cluster (not under it)
    // Sample chunks in a ring around the cluster bounds
    
    int minChunkX = MAX(0, worldX / 16 - 5);      // 5 chunks left
    int maxChunkX = MIN(191, (worldX + width) / 16 + 5);  // 5 chunks right
    int minChunkY = MAX(0, worldY / 16 - 5);      // 5 chunks above
    int maxChunkY = MIN(191, (worldY + height) / 16 + 5); // 5 chunks below
    
    int grassCount = 0;
    int mountainCount = 0;
    int waterCount = 0;
    int forestCount = 0;
    int otherCount = 0;
    int totalSampled = 0;
    
    for (int cy = minChunkY; cy <= maxChunkY; cy++) {
        for (int cx = minChunkX; cx <= maxChunkX; cx++) {
            int terrainType = _terrainGrid[cy * 192 + cx];
            totalSampled++;
            
            switch (terrainType) {
                case TerrainTypeGrass:
                    grassCount++;
                    break;
                case TerrainTypeMountain:
                    mountainCount++;
                    break;
                case TerrainTypeWater:
                    waterCount++;
                    break;
                case TerrainTypeForest:
                    forestCount++;
                    break;
                default:
                    otherCount++;
                    break;
            }
        }
    }
    
    // Cities are on grass/flat land; dungeons are on/in mountains
    // If >30% of surrounding chunks are mountains, it's a dungeon
    // If >40% are grass, it's a city
    
    mountainPercent = (float)mountainCount / totalSampled * 100.0;
    float grassPercent = (float)grassCount / totalSampled * 100.0;
    float waterPercent = (float)waterCount / totalSampled * 100.0;
    float forestPercent = (float)forestCount / totalSampled * 100.0;
    
    BOOL isCity;
    NSString *reason;
    
    if (mountainPercent > 30.0) {
        isCity = NO;
        reason = [NSString stringWithFormat:@"mountain %.1f%% > 30%%", mountainPercent];
    } else if (grassPercent > 40.0) {
        isCity = YES;
        reason = [NSString stringWithFormat:@"grass %.1f%% > 40%%", grassPercent];
    } else {
        // Ambiguous - default to city if more grass than mountains
        isCity = (grassPercent > mountainPercent);
        reason = [NSString stringWithFormat:@"grass %.1f%% vs mountain %.1f%% (ambiguous)", grassPercent, mountainPercent];
    }
    
    NSLog(@"  Cluster at (%d,%d): %@ - terrain: grass=%.1f%% mtn=%.1f%% water=%.1f%% forest=%.1f%% other=%.1f%%",
          worldX, worldY, 
          isCity ? @"CITY" : @"DUNGEON",
          grassPercent, mountainPercent, waterPercent, forestPercent, 
          (float)otherCount / totalSampled * 100.0);
    
    return isCity;
}

- (float)mountainPercentInClusterAtX:(int)worldX y:(int)worldY width:(int)width height:(int)height
{
    // Count mountain shapes vs total tiles in the cluster
    int mountainCount = 0;
    int totalTiles = 0;
    
    for (int y = worldY; y < worldY + height; y++) {
        for (int x = worldX; x < worldX + width; x++) {
            
            int chunkX = x / 16;
            int chunkY = y / 16;
            int tileX = x % 16;
            int tileY = y % 16;
            
            // Bounds check
            if (chunkX < 0 || chunkX >= 192 || chunkY < 0 || chunkY >= 192) {
                continue;
            }
            
            long chunkIndex = [_map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
            U7MapChunk *mapChunk = [_map mapChunkAtIndex:chunkIndex];
            if (!mapChunk) continue;
            
            U7Chunk *chunk = mapChunk->masterChunk;
            if (!chunk || !chunk->chunkMap) continue;
            
            int tileIndex = tileY * 16 + tileX;
            if (tileIndex >= [chunk->chunkMap count]) continue;
            
            U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIndex];
            long shapeID = chunkIdx->shapeIndex;
            
            totalTiles++;
            if ([self isMountainShape:shapeID]) {
                mountainCount++;
            }
        }
    }
    
    if (totalTiles == 0) return 0.0;
    return (float)mountainCount / totalTiles * 100.0;
}

- (NSDictionary *)floodFillBuildingsFromX:(int)startX y:(int)startY
{
    NSMutableArray *queue = [NSMutableArray array];
    [queue addObject:@[@(startX), @(startY)]];
    
    int minX = startX, maxX = startX;
    int minY = startY, maxY = startY;
    int tileCount = 0;
    
    while ([queue count] > 0) {
        NSArray *pos = [queue firstObject];
        [queue removeObjectAtIndex:0];
        
        int x = [pos[0] intValue];
        int y = [pos[1] intValue];
        
        NSString *key = [NSString stringWithFormat:@"%d,%d", x, y];
        if ([_visitedTiles containsObject:key]) {
            continue;
        }
        
        // Get tile at this position
        int chunkX = x / 16;
        int chunkY = y / 16;
        int tileX = x % 16;
        int tileY = y % 16;
        
        long chunkIndex = [_map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
        U7MapChunk *mapChunk = [_map mapChunkAtIndex:chunkIndex];
        if (!mapChunk) continue;
        
        U7Chunk *chunk = mapChunk->masterChunk;
        if (!chunk || !chunk->chunkMap) continue;
        
        // Get shape ID from chunk map
        int tileIndex = tileY * 16 + tileX;
        if (tileIndex >= [chunk->chunkMap count]) continue;
        
        U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIndex];
        long shapeID = chunkIdx->shapeIndex;
        
        if (![self isBuildingShape:shapeID]) {
            continue; // Not a building
        }
        
        // Mark as visited
        [_visitedTiles addObject:key];
        tileCount++;
        
        // Update bounds
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
        // Add neighbors to queue (with bounds checking)
        int maxWorldTile = 192 * 16; // 192 chunks * 16 tiles = 3072 tiles
        if (x + 1 < maxWorldTile) [queue addObject:@[@(x+1), @(y)]];
        if (x > 0) [queue addObject:@[@(x-1), @(y)]];
        if (y + 1 < maxWorldTile) [queue addObject:@[@(x), @(y+1)]];
        if (y > 0) [queue addObject:@[@(x), @(y-1)]];
    }
    
    return @{
        @"x": @(minX),
        @"y": @(minY),
        @"width": @(maxX - minX + 1),
        @"height": @(maxY - minY + 1),
        @"tileCount": @(tileCount)
    };
}

- (BOOL)isBuildingShape:(long)shapeID
{
    // Building components in Ultima VII:
    // Doors: ~270-350
    // Roofs: ~300-400
    // Walls (stone, brick, wood): ~400-700
    // Chimneys, signs: scattered ~500-800
    
    // EXCLUDE mountain shapes - they're terrain, not buildings
    if ([self isMountainShape:shapeID]) {
        return NO;
    }
    
    // Broader detection for building-related shapes
    return (shapeID >= 270 && shapeID <= 750) ||   // Main building components
           (shapeID >= 800 && shapeID <= 850);     // Some additional structures
}

- (BOOL)isMountainShape:(long)shapeID
{
    // Explicit mountain shapes from U7 inspection
    if (shapeID == 180 || shapeID == 182 || shapeID == 183 || shapeID == 195 ||
        shapeID == 324 || shapeID == 395 || shapeID == 396 || 
        shapeID == 969 || shapeID == 983) {
        return YES;
    }
    
    // Mountain/rock range (includes shapes like 132, 133, 135, 139, 144)
    if (shapeID >= 130 && shapeID <= 146) {
        return YES;
    }
    
    return NO;
}

- (BOOL)isDesertObject:(long)shapeID
{
    // Desert objects from U7 inspection (cacti, desert plants)
    return (shapeID == 962 || shapeID == 164);
}

- (void)analyzeTerrainDistribution
{
    NSLog(@"Analyzing terrain distribution...");
    
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    int totalChunks = 0;
    int sampleCount = 0;
    
    // Scan each chunk and determine dominant terrain type
    for (int chunkY = 0; chunkY < 192; chunkY++) {
        for (int chunkX = 0; chunkX < 192; chunkX++) {
            
            long chunkIndex = [_map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
            U7MapChunk *mapChunk = [_map mapChunkAtIndex:chunkIndex];
            if (!mapChunk) continue;
            
            U7Chunk *chunk = mapChunk->masterChunk;
            if (!chunk || !chunk->chunkMap) continue;
            
            int maxCount = (int)[chunk->chunkMap count];
            
            // DIAGNOSTIC for test chunks
            BOOL isTestChunk = (chunkX == 53 && chunkY == 60) || 
                              (chunkX == 21 && chunkY == 98) || (chunkX == 20 && chunkY == 99) ||
                              (chunkX == 80 && chunkY == 65) ||  // Swamp example
                              (chunkX == 139 && chunkY == 64) || (chunkX == 136 && chunkY == 66) || // Desert examples
                              // Transition chunks (original batch)
                              (chunkX == 41 && chunkY == 66) ||  // water→mountain
                              (chunkX == 39 && chunkY == 67) ||  // water→grass
                              (chunkX == 14 && chunkY == 87) ||  // water→barren
                              (chunkX == 78 && chunkY == 89) ||  // water→grass
                              (chunkX == 129 && chunkY == 79) || // water→desert
                              (chunkX == 129 && chunkY == 54) || // desert→grass
                              (chunkX == 128 && chunkY == 56) || // grass→mountain
                              (chunkX == 124 && chunkY == 49) || // swamp→grass
                              // Still showing green (new batch)
                              (chunkX == 19 && chunkY == 68) ||
                              (chunkX == 17 && chunkY == 67) ||
                              (chunkX == 10 && chunkY == 82);
            if (isTestChunk) {
                NSLog(@"DIAGNOSTIC: Checking chunk (%d,%d) for terrain shapes", chunkX, chunkY);
                NSLog(@"  Base terrain tiles: %lu", (unsigned long)[chunk->chunkMap count]);
                NSLog(@"  Static items: %lu", (unsigned long)[mapChunk->staticItems count]);
            }
            
            // FIRST: Check if chunk contains ANY special terrain objects (mountains, desert plants, etc)
            // These are OBJECTS in staticItems, not base terrain in chunkMap
            BOOL hasMountainShapes = NO;
            BOOL hasDesertObjects = NO;
            
            // Check staticItems (where mountains actually are!)
            if (mapChunk->staticItems) {
                int itemIdx = 0;
                for (id item in mapChunk->staticItems) {
                    if (isTestChunk) {
                        NSLog(@"  StaticItem[%d]: class=%@", itemIdx, NSStringFromClass([item class]));
                    }
                    
                    long shapeID = -1;
                    int frameIndex = -1;

                    // U7ShapeReference uses shapeID and frameNumber (not shapeIndex/frameIndex!)
                    // Try shapeID first (correct property name)
                    if ([item respondsToSelector:@selector(shapeID)]) {
                        shapeID = [item shapeID];
                    } else if ([item respondsToSelector:@selector(shapeIndex)]) {
                        shapeID = [item shapeIndex];
                    } else {
                        // Fallback to KVC
                        @try {
                            NSNumber *num = [item valueForKey:@"shapeID"];
                            if ([num isKindOfClass:[NSNumber class]]) {
                                shapeID = [num longValue];
                            } else {
                                num = [item valueForKey:@"shapeIndex"];
                                if ([num isKindOfClass:[NSNumber class]]) {
                                    shapeID = [num longValue];
                                }
                            }
                        } @catch (__unused NSException *e) {}
                    }

                    // Try frameNumber first (correct property name)
                    if ([item respondsToSelector:@selector(frameNumber)]) {
                        frameIndex = [item frameNumber];
                    } else if ([item respondsToSelector:@selector(frameIndex)]) {
                        frameIndex = [item frameIndex];
                    } else {
                        @try {
                            NSNumber *num = [item valueForKey:@"frameNumber"];
                            if ([num isKindOfClass:[NSNumber class]]) {
                                frameIndex = [num intValue];
                            } else {
                                num = [item valueForKey:@"frameIndex"];
                                if ([num isKindOfClass:[NSNumber class]]) {
                                    frameIndex = [num intValue];
                                }
                            }
                        } @catch (__unused NSException *e) {}
                    }
                    
                    if (isTestChunk) {
                        NSLog(@"    -> Extracted shapeID=%ld, frame=%d, isMountain=%d",
                              shapeID, frameIndex, (shapeID != -1 ? [self isMountainShape:shapeID] : -1));
                    }

                    if (shapeID == -1) {
                        // If we still couldn't determine the shape, skip
                        itemIdx++;
                        continue;
                    }
                    
                    if ([self isMountainShape:shapeID]) {
                        hasMountainShapes = YES;
                        if (isTestChunk) {
                            NSLog(@"  -> FOUND MOUNTAIN SHAPE %ld in staticItems!", shapeID);
                        }
                        break;
                    }
                    
                    // Check for desert objects (cacti, desert plants)
                    if ([self isDesertObject:shapeID]) {
                        hasDesertObjects = YES;
                        if (isTestChunk) {
                            NSLog(@"  -> FOUND DESERT OBJECT %ld in staticItems!", shapeID);
                        }
                    }
                    
                    itemIdx++;
                }
            }
            
            if (isTestChunk) {
                NSLog(@"  Result: hasMountainShapes = %d, hasDesertObjects = %d", hasMountainShapes, hasDesertObjects);
            }
            
            // ALWAYS collect base terrain shapes for diagnostic (even if chunk has mountains)
            int dominantTerrain;
            int terrainTilesCount = 0;
            NSMutableDictionary *shapeIDCounts = [NSMutableDictionary dictionary];
            NSMutableSet *uniqueBaseShapes = isTestChunk ? [NSMutableSet set] : nil;
            
            // Scan base terrain first (needed for both mountain and non-mountain chunks)
            for (int tileIdx = 0; tileIdx < maxCount; tileIdx++) {
                U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIdx];
                long shapeID = chunkIdx->shapeIndex;
                
                if (![self isBuildingShape:shapeID]) {
                    terrainTilesCount++;
                    NSNumber *key = @(shapeID);
                    shapeIDCounts[key] = @([shapeIDCounts[key] intValue] + 1);
                    if (isTestChunk) {
                        [uniqueBaseShapes addObject:@(shapeID)];
                    }
                }
            }
            
            if (isTestChunk && uniqueBaseShapes) {
                NSArray *sortedShapes = [[uniqueBaseShapes allObjects] sortedArrayUsingSelector:@selector(compare:)];
                NSLog(@"  Base terrain shapes in chunk (%d,%d): %@", chunkX, chunkY, sortedShapes);
            }
            
            // ALSO check if base terrain contains mountain shapes
            // (Mountains can be in staticItems OR base terrain tiles in transition chunks)
            if (!hasMountainShapes) {
                for (NSNumber *shapeKey in shapeIDCounts) {
                    long shapeID = [shapeKey longValue];
                    if ([self isMountainShape:shapeID]) {
                        hasMountainShapes = YES;
                        if (isTestChunk) {
                            NSLog(@"  -> FOUND MOUNTAIN SHAPE %ld in BASE TERRAIN!", shapeID);
                        }
                        break;
                    }
                }
            }
            
            if (hasMountainShapes) {
                // If chunk has mountain shapes, it's a mountain chunk
                dominantTerrain = TerrainTypeMountain;
            } else if (hasDesertObjects) {
                // If chunk has desert objects (cacti, etc), it's a desert chunk
                dominantTerrain = TerrainTypeDesert;
                if (isTestChunk) {
                    NSLog(@"  Classified as DESERT due to desert objects");
                }
            } else {
                // No mountain shapes - determine terrain from base tiles
                int terrainTypeCounts[8] = {0}; // Array for each terrain type (0-7, includes barren)
                
                // Special case: if chunk is 100% shape 10, it's desert (not grass)
                if ([shapeIDCounts count] == 1 && shapeIDCounts[@(10)] != nil && 
                    [shapeIDCounts[@(10)] intValue] == terrainTilesCount) {
                    dominantTerrain = TerrainTypeDesert;
                    if (isTestChunk) {
                        NSLog(@"  Special case: 100%% shape 10 = DESERT");
                    }
                } else {
                    // Count terrain types (already scanned shapes above)
                    for (NSNumber *shapeKey in shapeIDCounts) {
                        long shapeID = [shapeKey longValue];
                        int count = [shapeIDCounts[shapeKey] intValue];
                        int terrainType = [self terrainTypeForShapeID:shapeID];
                        terrainTypeCounts[terrainType] += count;
                    }
                    
                    // Find the most common terrain type in this chunk
                    dominantTerrain = TerrainTypeOther;
                    int maxTerrainCount = 0;
                    
                    for (int i = 0; i < 8; i++) {
                        if (terrainTypeCounts[i] > maxTerrainCount) {
                            maxTerrainCount = terrainTypeCounts[i];
                            dominantTerrain = i;
                        }
                    }
                }
            }
            
            // Store the dominant terrain for this chunk
            _terrainGrid[chunkY * 192 + chunkX] = dominantTerrain;
            
            NSString *terrainName = [self terrainNameForType:dominantTerrain];
            counts[terrainName] = @([counts[terrainName] intValue] + 1);
            totalChunks++;
            
            // Log classification result for test chunks
            if (isTestChunk) {
                NSLog(@"  CLASSIFIED AS: %@ (type %d)", terrainName, dominantTerrain);
            }
            
            // Log corner chunks (should all be water) and first few for diagnostic
            BOOL isCorner = (chunkX == 0 && chunkY == 0) || 
                           (chunkX == 0 && chunkY == 191) ||
                           (chunkX == 191 && chunkY == 0) ||
                           (chunkX == 191 && chunkY == 191);
            
            if ((sampleCount < 10 || isCorner || isTestChunk) && terrainTilesCount > 0) {
                // Find most common shape ID in this chunk
                NSNumber *topShape = nil;
                int topCount = 0;
                for (NSNumber *shapeID in shapeIDCounts) {
                    if ([shapeIDCounts[shapeID] intValue] > topCount) {
                        topCount = [shapeIDCounts[shapeID] intValue];
                        topShape = shapeID;
                    }
                }
                
                NSLog(@"%@chunk (%d,%d): dominant terrain=%@ (type %d), top shape=%@ (%d/%d terrain tiles, %d total)", 
                      isCorner ? @"CORNER " : @"Sample ", 
                      chunkX, chunkY, terrainName, dominantTerrain, topShape, topCount, terrainTilesCount, maxCount);
                
                if (!isCorner) sampleCount++;
            }
        }
    }
    
    // Convert to percentages
    for (NSString *terrain in counts) {
        float percentage = ([counts[terrain] floatValue] / totalChunks) * 100.0f;
        _terrainStats[terrain] = @(percentage);
    }
    
    NSLog(@"Terrain analysis complete: analyzed %d chunks", totalChunks);
    NSLog(@"Terrain breakdown: water=%@ grass=%@ mountains=%@ forest=%@ swamp=%@ desert=%@ barren=%@ other=%@",
          counts[@"water"], counts[@"grass"], counts[@"mountains"], counts[@"forest"], 
          counts[@"swamp"], counts[@"desert"], counts[@"barren"], counts[@"other"]);
    
    // Sample a few mountain chunks to verify they're stored correctly
    int mountainSamples = 0;
    for (int cy = 0; cy < 192 && mountainSamples < 5; cy++) {
        for (int cx = 0; cx < 192 && mountainSamples < 5; cx++) {
            int terrainType = _terrainGrid[cy * 192 + cx];
            if (terrainType == TerrainTypeMountain) {
                NSLog(@"  Sample mountain chunk (%d,%d): terrain grid value = %d", cx, cy, terrainType);
                mountainSamples++;
            }
        }
    }
}

// Terrain types for visualization
enum {
    TerrainTypeWater = 1,
    TerrainTypeGrass = 2,
    TerrainTypeMountain = 3,
    TerrainTypeForest = 4,
    TerrainTypeSwamp = 5,
    TerrainTypeDesert = 6,
    TerrainTypeBarren = 7,
    TerrainTypeOther = 0
};

- (int)terrainTypeForShapeID:(long)shapeID
{
    // Based on ACTUAL corner chunk analysis (all corners are water):
    // CONFIRMED WATER: Shape 19 (31.6%), Shape 30 (2.1%)
    // CONFIRMED TREES: Shapes 147-149 (~13%)
    // CONFIRMED MOUNTAINS: 180, 182, 183, 195, 324, 395, 396, 969, 983 (from Buck's U7 inspection)
    // CONFIRMED BARREN: Shapes 5, 49-57, 61, 185 (from chunks 21,98 and 20,99)
    // LIKELY GRASS: Shape 8 (9.8%), 10, 12, 17, 20, 21, 26 (not in water corners)
    
    // MOUNTAINS - Actual mountain shape IDs from Ultima VII
    if (shapeID == 180 || shapeID == 182 || shapeID == 183 || shapeID == 195 ||
        shapeID == 324 || shapeID == 395 || shapeID == 396 || 
        shapeID == 969 || shapeID == 983) {
        return TerrainTypeMountain;
    }
    
    // Also check nearby mountain shapes (likely rocks, cliffs)
    if (shapeID >= 130 && shapeID <= 146) {
        return TerrainTypeMountain;
    }
    
    // BARREN - Rocky/barren ground (before water check, as some overlap)
    if (shapeID == 5 || (shapeID >= 49 && shapeID <= 57) || shapeID == 61 || shapeID == 185) {
        return TerrainTypeBarren;
    }
    
    // WATER - Shapes seen in all four corner chunks
    if (shapeID == 19 || shapeID == 30) {
        return TerrainTypeWater;
    }
    
    // Also check nearby water shapes (coastline/shallow water, but NOT barren range)
    if (shapeID >= 31 && shapeID <= 48) {  // Reduced from 31-70 to exclude barren
        return TerrainTypeWater;
    }
    if (shapeID >= 58 && shapeID <= 70) {  // Water shapes above barren range
        return TerrainTypeWater;
    }
    
    // Trees/forest (147-149 confirmed from distribution)
    if (shapeID >= 147 && shapeID <= 149) {
        return TerrainTypeForest;
    }
    
    // Grass (shapes 8, 10, 12, 17, 20, 21, 26 - but NOT 19 or 30 which are water!)
    if ((shapeID >= 8 && shapeID <= 28 && shapeID != 19) || shapeID == 2) {
        return TerrainTypeGrass;
    }
    
    // Swamp (shapes 113-117 confirmed from chunk 80,65)
    if (shapeID >= 113 && shapeID <= 120) {
        return TerrainTypeSwamp;
    }
    
    // Desert (101-112 range, excluding swamp 113-120)
    if (shapeID >= 101 && shapeID <= 112) {
        return TerrainTypeDesert;
    }
    if (shapeID >= 121 && shapeID <= 129) {
        return TerrainTypeDesert;
    }
    
    return TerrainTypeOther;
}

- (NSString *)terrainNameForType:(int)terrainType
{
    switch (terrainType) {
        case TerrainTypeWater: return @"water";
        case TerrainTypeGrass: return @"grass";
        case TerrainTypeMountain: return @"mountains";
        case TerrainTypeForest: return @"forest";
        case TerrainTypeSwamp: return @"swamp";
        case TerrainTypeDesert: return @"desert";
        case TerrainTypeBarren: return @"barren";
        default: return @"other";
    }
}

// Terrain classification moved to terrainTypeForShapeID and terrainNameForType

- (NSString *)getResultsText
{
    NSMutableString *text = [NSMutableString string];
    
    [text appendString:@"=== ULTIMA VII MAP ANALYSIS ===\n\n"];
    
    // Cities
    [text appendFormat:@"Cities Found: %lu\n\n", (unsigned long)[_cities count]];
    
    for (int i = 0; i < MIN(10, [_cities count]); i++) {
        NSDictionary *city = _cities[i];
        [text appendFormat:@"City %d:\n", i+1];
        [text appendFormat:@"  Position: (%@, %@)\n", city[@"x"], city[@"y"]];
        [text appendFormat:@"  Size: %@ x %@ tiles\n", city[@"width"], city[@"height"]];
        [text appendFormat:@"  Buildings: %@ (%@ tiles)\n\n", city[@"buildingCount"], city[@"tileCount"]];
    }
    
    if ([_cities count] > 10) {
        [text appendFormat:@"... and %lu more cities\n\n", (unsigned long)[_cities count] - 10];
    }
    
    // Terrain distribution
    [text appendString:@"Terrain Distribution:\n"];
    NSArray *sortedKeys = [[_terrainStats allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString *key1, NSString *key2) {
        return [_terrainStats[key2] compare:_terrainStats[key1]];
    }];
    
    for (NSString *terrain in sortedKeys) {
        [text appendFormat:@"  %@: %.1f%%\n", terrain, [_terrainStats[terrain] floatValue]];
    }
    
    return text;
}

- (NSDictionary *)exportPatterns
{
    return [self exportPatternsForVisualization:YES];
}

- (NSDictionary *)exportPatternsForVisualization:(BOOL)includeTerrainGrid
{
    NSMutableDictionary *patterns = [NSMutableDictionary dictionary];
    
    patterns[@"cities"] = _cities;
    patterns[@"terrain"] = _terrainStats;
    patterns[@"metadata"] = @{
        @"mapSize": @{@"width": @(192*16), @"height": @(192*16)},
        @"analyzedAt": [[NSDate date] description]
    };
    
    // Include terrain grid for heat map visualization, but not for JSON export
    if (includeTerrainGrid && _terrainGrid) {
        NSData *terrainGridData = [NSData dataWithBytes:_terrainGrid length:192 * 192 * sizeof(int)];
        patterns[@"terrainGrid"] = terrainGridData;
        patterns[@"gridSize"] = @(192);
    }
    
    return patterns;
}

- (void)dealloc
{
    if (_terrainGrid) {
        free(_terrainGrid);
        _terrainGrid = NULL;
    }
}

@end




