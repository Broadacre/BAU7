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
    }
    return self;
}

- (void)analyze
{
    NSLog(@"Starting map analysis...");
    
    // Phase 1: Scan for building clusters (cities)
    [self scanForCities];
    
    // Phase 2: Count terrain types
    [self analyzeTerrainDistribution];
    
    // Phase 3: (Future) Detect roads, dungeons, etc.
    
    NSLog(@"Analysis complete! Found %lu cities", (unsigned long)[_cities count]);
}

- (void)scanForCities
{
    int mapWidth = 192;  // U7 map is 192 chunks wide (3 superchunks * 64 chunks)
    int mapHeight = 192; // 192 chunks tall
    int chunkSize = 16;  // Each chunk is 16x16 tiles
    
    // Scan every tile looking for building clusters
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
                        continue; // Already processed
                    }
                    
                    // Get shape ID from chunk map
                    int tileIndex = tileY * chunkSize + tileX;
                    if (tileIndex < [chunk->chunkMap count]) {
                        U7ChunkIndex *chunkIdx = chunk->chunkMap[tileIndex];
                        long shapeID = chunkIdx->shapeIndex;
                        
                        // Is this a building tile? (buildings are typically shapes 300-500, 800-900)
                        if ([self isBuildingShape:shapeID]) {
                            // Found unvisited building - flood fill to find cluster
                            NSDictionary *city = [self floodFillBuildingsFromX:worldX y:worldY];
                            
                            // Only count large clusters as cities (> 50 tiles)
                            if ([city[@"tileCount"] intValue] > 50) {
                                [_cities addObject:city];
                            }
                        }
                    }
                }
            }
        }
    }
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
    // Building shapes are typically in certain ranges in Ultima VII
    // This is a simple heuristic - may need refinement based on actual U7 data
    
    // Common building shape ranges in U7:
    // Walls, doors, roofs, etc. are typically shapes 300-500, 800-900
    return (shapeID >= 300 && shapeID <= 500) ||
           (shapeID >= 800 && shapeID <= 900);
}

- (void)analyzeTerrainDistribution
{
    int mapWidth = 192 * 16;
    int mapHeight = 192 * 16;
    int sampleEvery = 16; // Sample every 16th tile to save time
    
    NSMutableDictionary *counts = [NSMutableDictionary dictionary];
    int totalSamples = 0;
    
    for (int worldY = 0; worldY < mapHeight; worldY += sampleEvery) {
        for (int worldX = 0; worldX < mapWidth; worldX += sampleEvery) {
            
            int chunkX = worldX / 16;
            int chunkY = worldY / 16;
            int tileX = worldX % 16;
            int tileY = worldY % 16;
            
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
            
            NSString *terrainName = [self terrainNameForShapeID:shapeID];
            
            counts[terrainName] = @([counts[terrainName] intValue] + 1);
            totalSamples++;
        }
    }
    
    // Convert to percentages
    for (NSString *terrain in counts) {
        float percentage = ([counts[terrain] floatValue] / totalSamples) * 100.0f;
        _terrainStats[terrain] = @(percentage);
    }
}

- (NSString *)terrainNameForShapeID:(long)shapeID
{
    // Simple classification based on shape ID ranges
    // These ranges are approximations and may need refinement based on actual U7 data
    
    if ([self isBuildingShape:shapeID]) {
        return @"buildings";
    }
    
    // Grass/ground tiles (common base terrain)
    if (shapeID >= 0 && shapeID <= 50) {
        return @"grass";
    }
    
    // Trees/forest
    if (shapeID >= 150 && shapeID <= 250) {
        return @"forest";
    }
    
    // Water
    if (shapeID >= 50 && shapeID <= 100) {
        return @"water";
    }
    
    // Mountains/rocks
    if (shapeID >= 100 && shapeID <= 150) {
        return @"mountains";
    }
    
    // Swamp
    if (shapeID >= 600 && shapeID <= 650) {
        return @"swamp";
    }
    
    // Desert/sand
    if (shapeID >= 550 && shapeID <= 600) {
        return @"desert";
    }
    
    return @"other";
}

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
        [text appendFormat:@"  Size: %@ x %@\n", city[@"width"], city[@"height"]];
        [text appendFormat:@"  Buildings: %@\n\n", city[@"tileCount"]];
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
    return @{
        @"cities": _cities,
        @"terrain": _terrainStats,
        @"metadata": @{
            @"mapSize": @{@"width": @(192*16), @"height": @(192*16)},
            @"analyzedAt": [[NSDate date] description]
        }
    };
}

@end
