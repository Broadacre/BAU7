//
//  BAMapAnalyzer.m
//  BAU7
//
//  Created by Tom on 2/16/26.
//

#import "Includes.h"
#import "BAMapAnalyzer.h"

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
    
    float mountainPercent = (float)mountainCount / totalSampled * 100.0;
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
    // Mountain shapes from U7 inspection
    return (shapeID == 180 || shapeID == 182 || shapeID == 183 || shapeID == 195 ||
            shapeID == 324 || shapeID == 395 || shapeID == 396 || 
            shapeID == 969 || shapeID == 983);
}

- (void)analyzeTerrainDistribution
{
    NSLog(@"Analyzing terrain distribution...");
    
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    NSMutableDictionary *shapeIDSamples = [NSMutableDictionary dictionary]; // Track shape IDs per terrain
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
            
            // FIRST: Check if chunk contains ANY mountain shapes
            // Mountains are objects placed on top, so their presence overrides base terrain
            BOOL hasMountainShapes = NO;
            int maxCount = [chunk->chunkMap count];
            
            for (int tileIdx = 0; tileIdx < maxCount; tileIdx++) {
                U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIdx];
                long shapeID = chunkIdx->shapeIndex;
                
                if ([self isMountainShape:shapeID]) {
                    hasMountainShapes = YES;
                    break; // Found a mountain shape - this is a mountain chunk
                }
            }
            
            int dominantTerrain;
            int terrainTilesCount = 0;
            NSMutableDictionary *shapeIDCounts = [NSMutableDictionary dictionary];
            
            if (hasMountainShapes) {
                // If chunk has mountain shapes, it's a mountain chunk
                dominantTerrain = TerrainTypeMountain;
                
                // Still track shape IDs for diagnostic
                for (int tileIdx = 0; tileIdx < maxCount; tileIdx++) {
                    U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIdx];
                    long shapeID = chunkIdx->shapeIndex;
                    if (![self isBuildingShape:shapeID]) {
                        terrainTilesCount++;
                        NSNumber *key = @(shapeID);
                        shapeIDCounts[key] = @([shapeIDCounts[key] intValue] + 1);
                    }
                }
            } else {
                // Count terrain types across ALL tiles in this chunk
                // Skip building shapes - we want the UNDERLYING terrain
                int terrainTypeCounts[7] = {0}; // Array for each terrain type (0-6)
                
                for (int tileIdx = 0; tileIdx < maxCount; tileIdx++) {
                    U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIdx];
                    long shapeID = chunkIdx->shapeIndex;
                    
                    // SKIP BUILDING SHAPES - we only want terrain
                    if ([self isBuildingShape:shapeID]) {
                        continue;
                    }
                    
                    int terrainType = [self terrainTypeForShapeID:shapeID];
                    terrainTypeCounts[terrainType]++;
                    terrainTilesCount++;
                    
                    // Track shape IDs for diagnostic
                    NSNumber *key = @(shapeID);
                    shapeIDCounts[key] = @([shapeIDCounts[key] intValue] + 1);
                }
                
                // Find the most common terrain type in this chunk (among non-building tiles)
                dominantTerrain = TerrainTypeOther;
                int maxTerrainCount = 0;
                
                for (int i = 0; i < 7; i++) {
                    if (terrainTypeCounts[i] > maxTerrainCount) {
                        maxTerrainCount = terrainTypeCounts[i];
                        dominantTerrain = i;
                    }
                }
            }
            
            // Store the dominant terrain for this chunk
            _terrainGrid[chunkY * 192 + chunkX] = dominantTerrain;
            
            NSString *terrainName = [self terrainNameForType:dominantTerrain];
            counts[terrainName] = @([counts[terrainName] intValue] + 1);
            totalChunks++;
            
            // Log corner chunks (should all be water) and first few for diagnostic
            BOOL isCorner = (chunkX == 0 && chunkY == 0) || 
                           (chunkX == 0 && chunkY == 191) ||
                           (chunkX == 191 && chunkY == 0) ||
                           (chunkX == 191 && chunkY == 191);
            
            // ALSO log the user's test chunk
            BOOL isTestChunk = (chunkX == 53 && chunkY == 60);
            
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
    NSLog(@"Terrain breakdown: water=%@ grass=%@ mountains=%@ forest=%@ swamp=%@ desert=%@ other=%@",
          counts[@"water"], counts[@"grass"], counts[@"mountains"], counts[@"forest"], 
          counts[@"swamp"], counts[@"desert"], counts[@"other"]);
    
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
    TerrainTypeOther = 0
};

- (int)terrainTypeForShapeID:(long)shapeID
{
    // Based on ACTUAL corner chunk analysis (all corners are water):
    // CONFIRMED WATER: Shape 19 (31.6%), Shape 30 (2.1%)
    // CONFIRMED TREES: Shapes 147-149 (~13%)
    // CONFIRMED MOUNTAINS: 180, 182, 183, 195, 324, 395, 396, 969, 983 (from Buck's U7 inspection)
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
    
    // WATER - Shapes seen in all four corner chunks
    if (shapeID == 19 || shapeID == 30) {
        return TerrainTypeWater;
    }
    
    // Also check nearby water shapes (coastline/shallow water)
    if (shapeID >= 31 && shapeID <= 70) {
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
    
    // Swamp (71-100 range)
    if (shapeID >= 71 && shapeID <= 100) {
        return TerrainTypeSwamp;
    }
    
    // Desert (101-129 range)
    if (shapeID >= 101 && shapeID <= 129) {
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
