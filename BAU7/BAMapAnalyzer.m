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
    
    // Phase 1: Find individual building structures
    NSArray *buildings = [self scanForBuildings];
    
    // Phase 2: Group nearby buildings into cities
    [self groupBuildingsIntoCities:buildings];
    
    // Phase 3: Count terrain types
    [self analyzeTerrainDistribution];
    
    // Phase 4: (Future) Detect roads, dungeons, etc.
    
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
        
        // If we have 10+ buildings, it's a city
        if ([cityBuildings count] >= 10) {
            // Calculate city bounds
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
            
            NSDictionary *city = @{
                @"x": @(minX),
                @"y": @(minY),
                @"width": @(maxX - minX),
                @"height": @(maxY - minY),
                @"buildingCount": @([cityBuildings count]),
                @"tileCount": @(totalTiles)
            };
            
            NSLog(@"Found city: %lu buildings, %d tiles at (%d, %d)", 
                  (unsigned long)[cityBuildings count], totalTiles, minX, minY);
            
            [_cities addObject:city];
        }
    }
    
    NSLog(@"City detection complete: Found %lu cities", (unsigned long)[_cities count]);
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
    
    // Broader detection for building-related shapes
    return (shapeID >= 270 && shapeID <= 750) ||   // Main building components
           (shapeID >= 800 && shapeID <= 850);     // Some additional structures
}

- (void)analyzeTerrainDistribution
{
    NSLog(@"Analyzing terrain distribution...");
    
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    int totalSamples = 0;
    
    // Scan each chunk and determine dominant terrain type
    for (int chunkY = 0; chunkY < 192; chunkY++) {
        for (int chunkX = 0; chunkX < 192; chunkX++) {
            
            long chunkIndex = [_map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
            U7MapChunk *mapChunk = [_map mapChunkAtIndex:chunkIndex];
            if (!mapChunk) continue;
            
            U7Chunk *chunk = mapChunk->masterChunk;
            if (!chunk || !chunk->chunkMap) continue;
            
            // Sample center tile of chunk to determine terrain
            int centerTile = 8 * 16 + 8; // Middle of 16x16 chunk
            if (centerTile < [chunk->chunkMap count]) {
                U7ChunkIndex *chunkIdx = chunk->chunkMap[centerTile];
                long shapeID = chunkIdx->shapeIndex;
                
                int terrainType = [self terrainTypeForShapeID:shapeID];
                _terrainGrid[chunkY * 192 + chunkX] = terrainType;
                
                NSString *terrainName = [self terrainNameForType:terrainType];
                counts[terrainName] = @([counts[terrainName] intValue] + 1);
                totalSamples++;
            }
        }
    }
    
    // Convert to percentages
    for (NSString *terrain in counts) {
        float percentage = ([counts[terrain] floatValue] / totalSamples) * 100.0f;
        _terrainStats[terrain] = @(percentage);
    }
    
    NSLog(@"Terrain analysis complete");
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
    // Water (shapes 0-100 are typically water/coast)
    if (shapeID >= 0 && shapeID <= 100) {
        return TerrainTypeWater;
    }
    
    // Grass (main terrain)
    if (shapeID >= 1 && shapeID <= 50) {
        return TerrainTypeGrass;
    }
    
    // Mountains
    if (shapeID >= 1010 && shapeID <= 1050) {
        return TerrainTypeMountain;
    }
    
    // Trees/forest (147-149 are trees based on the shape distribution)
    if (shapeID >= 147 && shapeID <= 149) {
        return TerrainTypeForest;
    }
    
    // Swamp
    if (shapeID >= 1060 && shapeID <= 1100) {
        return TerrainTypeSwamp;
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
    // Convert terrain grid to NSData for export
    NSData *terrainGridData = [NSData dataWithBytes:_terrainGrid length:192 * 192 * sizeof(int)];
    
    return @{
        @"cities": _cities,
        @"terrain": _terrainStats,
        @"terrainGrid": terrainGridData,
        @"gridSize": @(192),
        @"metadata": @{
            @"mapSize": @{@"width": @(192*16), @"height": @(192*16)},
            @"analyzedAt": [[NSDate date] description]
        }
    };
}

- (void)dealloc
{
    if (_terrainGrid) {
        free(_terrainGrid);
        _terrainGrid = NULL;
    }
}

@end
