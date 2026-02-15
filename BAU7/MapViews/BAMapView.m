//
//  BAU7View.m
//  BAU7View
//
//  Created by Dan Brooker on 8/24/21.
//
#import "Includes.h"
#import "BAMapView.h"
#import "BAImageUpscaler.h"
#define MAXPASSES 16
#define MINI_MAP_SCALE 0.2f
#define MAP_SCALE 1.0f
#define MAX_MAP_SCALE 10.0f
#define MIN_MAP_SCALE 0.0025f

@implementation BASpawn
-(id)init
{
    self=[super init];
    spawnType=NoBASpawnType;
    resourceType=NoResourceType;
    actorType=NoActorBAActorType;
    frequencyCounter=0;
    trigger=NO;
    return self;
}

-(void)increaseFrequencyCounter
{
    frequencyCounter++;
    if(frequencyCounter>=frequency)
    {
        frequencyCounter=0;
        trigger=YES;
    }
    else
        trigger=NO;
}
-(BOOL)isTriggered
{
    return trigger;
}
-(void)setFrequency:(long)theFrequency
{
    frequency=theFrequency;
}
-(enum BASpawnType)getSpawnType
{
    return spawnType;
}

+(BASpawn*)ResourceSpawnOfType:(enum BAResourceType)theResourceType
{
    BASpawn *theSpawn=[[BASpawn alloc]init];
    theSpawn->spawnType=ResourceBASpawnType;
    theSpawn->resourceType=theResourceType;
    
    return theSpawn;
}

+(BASpawn*)NPCSpawnOfType:(enum BAActorType)theActorType
{
    BASpawn *theSpawn=[[BASpawn alloc]init];
    theSpawn->spawnType=NPCBASpawnType;
    theSpawn->actorType=theActorType;
    
    return theSpawn;
}

-(enum BAResourceType)getResourceType
{
    return resourceType;
}
@end


@implementation BAMapView

-(id)init
{
    self=[super init];
    
    selectedShapes=[[NSMutableArray alloc]init];
    spawns=[[NSMutableArray alloc]init];
    triggeredSpawns=[[NSMutableArray alloc]init];
    drawMode=MiniMapDrawMode;
    //drawMode=NormalMapDrawMode;
    
    environment=NULL;
    
    
    drawTiles=YES;
    drawGroundObjects=YES;
    drawGameObjects=YES;
    drawStaticObjects=YES;
    drawPassability=NO;
    drawTargetLocations=YES;
    drawChunkHighlite=NO;
    drawShapeHighlite=NO;
    drawEnvironmentMap=NO;
    drawShapeIDs=NO;
    
    chunksWide=1;
    chunksHigh=0;
    maxHeight=MAXPASSES;
    startPoint=CGPointMake(0,0);
    
    
    palletCycle=0;
    
    mapScale=MAP_SCALE;
    miniMapScale=MINI_MAP_SCALE;
    
    // Initialize optimization structures
    [self initializeOptimizationStructures];
    
    return self;
}

-(void)didMoveToWindow
{
    [super didMoveToWindow];
    
    if (self.window) {
        // View is now in a window - start water animation
        [self startWaterAnimation];
    } else {
        // View removed from window - stop animation to save resources
        [self stopWaterAnimation];
    }
}

-(void)dealloc
{
    [self stopWaterAnimation];
}

#pragma mark - Optimization Setup

-(void)initializeOptimizationStructures
{
    // Object pool for shape references - preallocate to avoid per-frame allocations
    NSInteger initialPoolSize = 1000;
    self.shapeReferencePool = [[NSMutableArray alloc] initWithCapacity:initialPoolSize];
    for (NSInteger i = 0; i < initialPoolSize; i++) {
        [self.shapeReferencePool addObject:[[U7ShapeReference alloc] init]];
    }
    self.poolIndex = 0;
    
    // Reusable array for sorting shapes
    self.reusableShapeArray = [[NSMutableArray alloc] initWithCapacity:1000];
    
    // Cache for sorted shapes per chunk
    self.chunkSortedShapesCache = [[NSMutableDictionary alloc] init];
    
    // Image cache to avoid recreating UIImage objects
    self.imageCache = [[NSCache alloc] init];
    self.imageCache.countLimit = 500;
    
    // Background queue for sorting operations
    self.sortingQueue = dispatch_queue_create("com.ba.mapview.sorting", DISPATCH_QUEUE_SERIAL);
    self.useAsyncSorting = NO; // Can be enabled for very large maps
    
    // Water animation setup
    self.waterAnimationFrame = 0;
    self.lastWaterUpdateTime = 0;
    self.waterAnimationInterval = 0.15; // ~6.6 fps for water, authentic U7 feel
    self.waterAnimationEnabled = YES;
    
    // Update draw options bitmask
    [self updateDrawOptionsFromFlags];
}

#pragma mark - Water Animation

-(void)startWaterAnimation
{
    if (self.waterAnimationTimer) {
        return; // Already running
    }
    
    self.waterAnimationTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateWaterAnimation:)];
    self.waterAnimationTimer.preferredFramesPerSecond = 60; // Check frequently, but only update water at waterAnimationInterval
    [self.waterAnimationTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.waterAnimationEnabled = YES;
}

-(void)stopWaterAnimation
{
    [self.waterAnimationTimer invalidate];
    self.waterAnimationTimer = nil;
    self.waterAnimationEnabled = NO;
}

-(void)updateWaterAnimation:(CADisplayLink*)displayLink
{
    if (!self.waterAnimationEnabled) {
        return;
    }
    
    NSTimeInterval currentTime = displayLink.timestamp;
    NSTimeInterval elapsed = currentTime - self.lastWaterUpdateTime;
    
    if (elapsed >= self.waterAnimationInterval) {
        self.lastWaterUpdateTime = currentTime;
        
        // Advance water animation frame (0-7 for 8-frame water cycle)
        self.waterAnimationFrame = (self.waterAnimationFrame + 1) % 8;
        
        // Update the global palette cycle to match
        palletCycle = (unsigned int)self.waterAnimationFrame;
        
        // Request redraw
        [self setNeedsDisplay];
    }
}

-(void)setWaterAnimationSpeed:(NSTimeInterval)interval
{
    self.waterAnimationInterval = interval;
}

-(NSInteger)waterCycleForPaletteRange:(int)paletteIndex
{
    // U7 palette cycling ranges:
    // 224-231: Water (8 colors, cycle range)
    // 232-239: Lava/fire effects (8 colors)
    // 240-243: Lightning/sparks (4 colors)
    // 244-247: Another effect (4 colors)
    // 248-251: Another effect (4 colors)
    // 252-254: Small cycle (3 colors)
    
    if (paletteIndex >= 224 && paletteIndex <= 231) {
        // Water: 8-frame cycle
        return self.waterAnimationFrame % 8;
    } else if (paletteIndex >= 232 && paletteIndex <= 239) {
        // Lava: 8-frame cycle (can use same or offset)
        return self.waterAnimationFrame % 8;
    } else if (paletteIndex >= 240 && paletteIndex <= 243) {
        // 4-frame cycle
        return (self.waterAnimationFrame / 2) % 4;
    } else if (paletteIndex >= 244 && paletteIndex <= 247) {
        // 4-frame cycle
        return (self.waterAnimationFrame / 2) % 4;
    } else if (paletteIndex >= 248 && paletteIndex <= 251) {
        // 4-frame cycle
        return (self.waterAnimationFrame / 2) % 4;
    } else if (paletteIndex >= 252 && paletteIndex <= 254) {
        // 3-frame cycle
        return self.waterAnimationFrame % 3;
    }
    
    return 0;
}

#pragma mark - Shape Selection

-(U7ShapeReference*)shapeAtViewLocation:(CGPoint)viewLocation
{
    // We need to check shapes based on their RENDERED position, not tile footprint
    // This means accounting for lift offset and bitmap bounds
    
    NSMutableArray *candidateShapes = [[NSMutableArray alloc] init];
    
    // Check multiple chunks around the tap location since shapes can extend across chunks
    // and elevated shapes can appear offset from their actual tile position
    
    // First, calculate the approximate chunk range to check
    // We need to check a wider area because elevated shapes are drawn offset
    CGFloat maxLiftOffset = maxHeight * HEIGHTOFFSET;
    
    CGPoint minGlobalPixel = CGPointMake(
        (startPoint.x * CHUNKSIZE * TILESIZE) + ((viewLocation.x - maxLiftOffset) / mapScale),
        (startPoint.y * CHUNKSIZE * TILESIZE) + ((viewLocation.y - maxLiftOffset) / mapScale)
    );
    
    CGPoint maxGlobalPixel = CGPointMake(
        (startPoint.x * CHUNKSIZE * TILESIZE) + ((viewLocation.x + maxLiftOffset) / mapScale),
        (startPoint.y * CHUNKSIZE * TILESIZE) + ((viewLocation.y + maxLiftOffset) / mapScale)
    );
    
    int minChunkX = (int)floor(minGlobalPixel.x / (CHUNKSIZE * TILESIZE));
    int maxChunkX = (int)floor(maxGlobalPixel.x / (CHUNKSIZE * TILESIZE));
    int minChunkY = (int)floor(minGlobalPixel.y / (CHUNKSIZE * TILESIZE));
    int maxChunkY = (int)floor(maxGlobalPixel.y / (CHUNKSIZE * TILESIZE));
    
    // Expand range slightly to catch edge cases
    minChunkX = MAX(0, minChunkX - 1);
    minChunkY = MAX(0, minChunkY - 1);
    maxChunkX = MIN(TOTALMAPSIZE - 1, maxChunkX + 1);
    maxChunkY = MIN(TOTALMAPSIZE - 1, maxChunkY + 1);
    
    NSLog(@"shapeAtViewLocation: viewLocation(%f, %f) checking chunks (%d,%d) to (%d,%d)",
          viewLocation.x, viewLocation.y, minChunkX, minChunkY, maxChunkX, maxChunkY);
    
    // Check all chunks in range
    for (int chunkY = minChunkY; chunkY <= maxChunkY; chunkY++) {
        for (int chunkX = minChunkX; chunkX <= maxChunkX; chunkX++) {
            CGPoint chunkCoord = CGPointMake(chunkX, chunkY);
            U7MapChunk *mapChunk = [map mapChunkForLocation:chunkCoord];
            if (!mapChunk) continue;
            
            // Check all height levels
            for (int height = 0; height <= maxHeight; height++) {
                // Check all tiles in the chunk
                for (int tileY = 0; tileY < CHUNKSIZE; tileY++) {
                    for (int tileX = 0; tileX < CHUNKSIZE; tileX++) {
                        CGPoint localTile = CGPointMake(tileX, tileY);
                        
                        // Check each type of object
                        U7ShapeReference *refs[3];
                        refs[0] = [mapChunk gameShapeForLocation:localTile forHeight:height];
                        refs[1] = [mapChunk staticShapeForLocation:localTile forHeight:height];
                        refs[2] = [mapChunk groundShapeForLocation:localTile forHeight:height];
                        
                        for (int i = 0; i < 3; i++) {
                            U7ShapeReference *ref = refs[i];
                            if (!ref) continue;
                            
                            // Skip if already added (can happen with multi-chunk search)
                            if ([candidateShapes containsObject:ref]) continue;
                            
                            // Get shape and bitmap for actual rendered bounds
                            U7Shape *shape = [environment->U7Shapes objectAtIndex:ref->shapeID];
                            if ([shape->frames count] == 0) continue;
                            
                            // Validate frame number is within bounds
                            if (ref->frameNumber >= [shape->frames count]) {
                                NSLog(@"WARNING: Shape %ld has invalid frame number %d (max: %lu). Skipping.",
                                      (long)ref->shapeID, ref->frameNumber, (unsigned long)[shape->frames count] - 1);
                                continue;
                            }
                            
                            U7Bitmap *bitmap = [shape->frames objectAtIndex:ref->frameNumber];
                            if (!bitmap) continue;
                            
                            // Calculate the shape's RENDERED position in view coordinates
                            // This matches the formula in drawShapeOptimized
                            CGFloat globalTileX = (chunkX * CHUNKSIZE) + ref->parentChunkXCoord;
                            CGFloat globalTileY = (chunkY * CHUNKSIZE) + ref->parentChunkYCoord;
                            
                            // Convert to view-relative tile position
                            CGFloat viewTileX = globalTileX - (startPoint.x * CHUNKSIZE);
                            CGFloat viewTileY = globalTileY - (startPoint.y * CHUNKSIZE);
                            
                            CGRect renderRect;
                            if (shape->tile) {
                                // Tiles are drawn at their tile position
                                renderRect = CGRectMake(
                                    viewTileX * TILESIZE * mapScale,
                                    viewTileY * TILESIZE * mapScale,
                                    TILESIZE * mapScale,
                                    TILESIZE * mapScale
                                );
                            } else {
                                // Non-tiles use bitmap offset and lift
                                CGFloat offsetX = ((viewTileX + 1) * TILESIZE * mapScale) 
                                                + ([bitmap reverseTranslateX] * mapScale) 
                                                - (ref->lift * HEIGHTOFFSET * mapScale);
                                CGFloat offsetY = ((viewTileY + 1) * TILESIZE * mapScale) 
                                                + ([bitmap reverseTranslateY] * mapScale) 
                                                - (ref->lift * HEIGHTOFFSET * mapScale);
                                
                                renderRect = CGRectMake(
                                    offsetX,
                                    offsetY,
                                    bitmap->width * mapScale,
                                    bitmap->height * mapScale
                                );
                            }
                            
                            // Check if tap point is within the rendered bounds
                            if (CGRectContainsPoint(renderRect, viewLocation)) {
                                // Mark the object type for depth calculation
                                if (i == 0) ref->GameObject = YES;
                                else if (i == 1) ref->StaticObject = YES;
                                else if (i == 2) ref->GroundObject = YES;
                                
                                [candidateShapes addObject:ref];
                            }
                        }
                    }
                }
            }
        }
    }
    
    if ([candidateShapes count] == 0) {
        NSLog(@"No shape at location");
        return nil;
    }
    
    // Calculate depth for each candidate using the same formula as buildSortedShapesForChunk
    // Higher depth = drawn later = on top
    for (U7ShapeReference *reference in candidateShapes) {
        U7Shape *shape = [environment->U7Shapes objectAtIndex:reference->shapeID];
        
        int tileSizeX = shape->TileSizeXMinus1 + 1;
        int tileSizeY = shape->TileSizeYMinus1 + 1;
        
        // Back corner position (NW corner)
        int backX = reference->parentChunkXCoord - tileSizeX + 1;
        int backY = reference->parentChunkYCoord - tileSizeY + 1;
        
        int maxX = (backX + 1) * TILESIZE;
        int maxY = (backY + 1) * TILESIZE;
        
        // Check if this is a floor object
        BOOL isFloorObject = NO;
        if (reference->GroundObject) {
            isFloorObject = YES;
        } else if (reference->lift == 0 && reference->StaticObject) {
            if (reference->shapeID == 190 || reference->shapeID == 483) {
                isFloorObject = YES;
            } else {
                int footprintSize = tileSizeX * tileSizeY;
                if (footprintSize >= 4 && shape->tileSizeZ == 0) {
                    isFloorObject = YES;
                }
            }
        }
        
        if (isFloorObject) {
            reference->depth = -1000000 + ((maxX + maxY) * 128);
        } else {
            reference->depth = ((maxX + maxY) * 128) + (reference->lift * HEIGHTOFFSET);
        }
    }
    
    // Sort candidates by depth - highest depth is on top (drawn last)
    NSArray *sortedCandidates = [candidateShapes sortedArrayUsingComparator:^NSComparisonResult(U7ShapeReference *a, U7ShapeReference *b) {
        // Primary sort: by depth (higher depth = on top)
        if (a->depth > b->depth) return NSOrderedAscending;
        if (a->depth < b->depth) return NSOrderedDescending;
        
        // Secondary sort: by lift
        if (a->lift > b->lift) return NSOrderedAscending;
        if (a->lift < b->lift) return NSOrderedDescending;
        
        // Tertiary: game objects on top of static on top of ground
        if (a->GameObject && !b->GameObject) return NSOrderedAscending;
        if (!a->GameObject && b->GameObject) return NSOrderedDescending;
        if (a->StaticObject && b->GroundObject) return NSOrderedAscending;
        if (a->GroundObject && b->StaticObject) return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    // Return the topmost shape (first in sorted array = highest depth)
    U7ShapeReference *topShape = [sortedCandidates firstObject];
    
    if (topShape) {
        U7Shape *shapeInfo = [environment->U7Shapes objectAtIndex:topShape->shapeID];
        NSLog(@"Selected topmost shape %ld at height %d, depth %d, size (%d, %d)",
              (long)topShape->shapeID, topShape->lift, topShape->depth,
              shapeInfo->TileSizeXMinus1 + 1, shapeInfo->TileSizeYMinus1 + 1);
    }
    
    return topShape;
}

-(NSArray*)shapesAtViewLocation:(CGPoint)viewLocation
{
    NSMutableArray *shapes = [[NSMutableArray alloc] init];
    
    // Convert view location to global tile coordinates
    CGPoint globalPixel = CGPointMake(
        (startPoint.x * CHUNKSIZE * TILESIZE) + (viewLocation.x / mapScale),
        (startPoint.y * CHUNKSIZE * TILESIZE) + (viewLocation.y / mapScale)
    );
    
    CGPoint globalTile = CGPointMake(
        floor(globalPixel.x / TILESIZE),
        floor(globalPixel.y / TILESIZE)
    );
    
    // Find the chunk containing this location
    CGPoint chunkCoord = CGPointMake(
        floor(globalTile.x / CHUNKSIZE),
        floor(globalTile.y / CHUNKSIZE)
    );
    
    U7MapChunk *mapChunk = [map mapChunkForLocation:chunkCoord];
    if (!mapChunk) return shapes;
    
    // Local tile position within chunk
    CGPoint localTile = CGPointMake(
        (int)globalTile.x % CHUNKSIZE,
        (int)globalTile.y % CHUNKSIZE
    );
    
    // Get all shapes at all height levels
    for (int height = 0; height <= maxHeight; height++) {
        U7ShapeReference *ref = [mapChunk groundShapeForLocation:localTile forHeight:height];
        if (ref) [shapes addObject:ref];
        
        ref = [mapChunk staticShapeForLocation:localTile forHeight:height];
        if (ref) [shapes addObject:ref];
        
        ref = [mapChunk gameShapeForLocation:localTile forHeight:height];
        if (ref) [shapes addObject:ref];
    }
    
    return shapes;
}

-(void)selectShape:(U7ShapeReference*)shape
{
    if (shape && ![selectedShapes containsObject:shape]) {
        [selectedShapes addObject:shape];
        drawShapeHighlite = YES;
        [self setNeedsDisplay];
    }
}

-(void)deselectShape:(U7ShapeReference*)shape
{
    if (shape && [selectedShapes containsObject:shape]) {
        [selectedShapes removeObject:shape];
        if ([selectedShapes count] == 0) {
            drawShapeHighlite = NO;
        }
        [self setNeedsDisplay];
    }
}

-(void)deselectAllShapes
{
    [selectedShapes removeAllObjects];
    drawShapeHighlite = NO;
    [self setNeedsDisplay];
}

-(void)toggleShapeSelectionAtViewLocation:(CGPoint)viewLocation
{
    NSLog(@"toggleShapeSelectionAtViewLocation: view(%f, %f) scale:%f startPoint:(%f, %f)", 
          viewLocation.x, viewLocation.y, mapScale, startPoint.x, startPoint.y);
    
    U7ShapeReference *shape = [self shapeAtViewLocation:viewLocation];
    
    if (shape) {
        if ([selectedShapes containsObject:shape]) {
            [self deselectShape:shape];
        } else {
            // Deselect all others and select this one (single selection mode)
            [self deselectAllShapes];
            [self selectShape:shape];
        }
        
        // Log selection info
        U7Shape *shapeInfo = [environment->U7Shapes objectAtIndex:shape->shapeID];
        NSLog(@"Selected shape ID: %ld, frame: %d, lift: %d, size: (%d, %d), pos: (%d, %d)",
              (long)shape->shapeID,
              shape->frameNumber,
              shape->lift,
              shapeInfo->TileSizeXMinus1 + 1,
              shapeInfo->TileSizeYMinus1 + 1,
              shape->parentChunkXCoord,
              shape->parentChunkYCoord);
    } else {
        [self deselectAllShapes];
        NSLog(@"No shape at location");
    }
}

-(NSArray*)getSelectedShapes
{
    return [selectedShapes copy];
}

#pragma mark - View Location Conversion

-(CGPoint)viewLocationToGlobalTile:(CGPoint)viewLocation
{
    // Convert view location to global tile coordinates
    // This accounts for the shape's lift when determining where to place it
    CGPoint globalPixel = CGPointMake(
        (startPoint.x * CHUNKSIZE * TILESIZE) + (viewLocation.x / mapScale),
        (startPoint.y * CHUNKSIZE * TILESIZE) + (viewLocation.y / mapScale)
    );
    
    CGPoint globalTile = CGPointMake(
        floor(globalPixel.x / TILESIZE),
        floor(globalPixel.y / TILESIZE)
    );
    
    return globalTile;
}

-(CGPoint)viewLocationToGlobalTileForShape:(U7ShapeReference*)shape atViewLocation:(CGPoint)viewLocation
{
    // Convert view location to global tile, accounting for the shape's lift
    // When dragging, we want the shape to follow the cursor position
    // But we need to account for the visual offset caused by lift
    
    // The visual offset from lift moves the shape UP and LEFT on screen
    // So we need to compensate by adding that offset back to the tap location
    CGFloat liftOffsetPixels = shape->lift * HEIGHTOFFSET;
    
    CGPoint adjustedViewLocation = CGPointMake(
        viewLocation.x + (liftOffsetPixels * mapScale),
        viewLocation.y + (liftOffsetPixels * mapScale)
    );
    
    return [self viewLocationToGlobalTile:adjustedViewLocation];
}

#pragma mark - Shape Manipulation

-(void)moveShape:(U7ShapeReference*)shape toGlobalTileLocation:(CGPoint)globalTile
{
    if (!shape) return;
    
    // Validate global tile is in bounds
    int maxTiles = TOTALMAPSIZE * CHUNKSIZE;
    if (globalTile.x < 0 || globalTile.y < 0 || 
        globalTile.x >= maxTiles || globalTile.y >= maxTiles) {
        NSLog(@"moveShape: Invalid global tile (%.0f, %.0f)", globalTile.x, globalTile.y);
        return;
    }
    
    // Get current chunk
    U7MapChunk *currentChunk = [map mapChunkAtIndex:shape->parentChunkID];
    if (!currentChunk) {
        NSLog(@"moveShape: Could not find current chunk %ld", shape->parentChunkID);
        return;
    }
    
    // Calculate new chunk coordinates
    CGPoint newChunkCoord = CGPointMake(
        floor(globalTile.x / CHUNKSIZE),
        floor(globalTile.y / CHUNKSIZE)
    );
    
    // Calculate new local coordinates within chunk
    int newLocalX = (int)globalTile.x % CHUNKSIZE;
    int newLocalY = (int)globalTile.y % CHUNKSIZE;
    
    // Handle negative modulo
    if (newLocalX < 0) newLocalX += CHUNKSIZE;
    if (newLocalY < 0) newLocalY += CHUNKSIZE;
    
    // Check if chunk changed
    long newChunkID = (long)(newChunkCoord.y * TOTALMAPSIZE + newChunkCoord.x);
    
    // Validate new chunk ID
    if (newChunkID < 0 || newChunkID >= [map->map count]) {
        NSLog(@"moveShape: Invalid new chunk ID %ld", newChunkID);
        return;
    }
    
    if (newChunkID != shape->parentChunkID) {
        // Need to move shape to a different chunk
        U7MapChunk *newChunk = [map mapChunkAtIndex:newChunkID];
        if (!newChunk) {
            NSLog(@"moveShape: Could not find target chunk %ld", newChunkID);
            return;
        }
        
        // Remove from current chunk's arrays - check which array it's in
        BOOL removed = NO;
        if (shape->GameObject && [currentChunk->gameItems containsObject:shape]) {
            [currentChunk->gameItems removeObject:shape];
            removed = YES;
        } else if (shape->StaticObject && [currentChunk->staticItems containsObject:shape]) {
            [currentChunk->staticItems removeObject:shape];
            removed = YES;
        } else if (shape->GroundObject && [currentChunk->groundObjects containsObject:shape]) {
            [currentChunk->groundObjects removeObject:shape];
            removed = YES;
        }
        
        if (!removed) {
            // Try to find it in any array
            if ([currentChunk->gameItems containsObject:shape]) {
                [currentChunk->gameItems removeObject:shape];
                shape->GameObject = YES;
                shape->StaticObject = NO;
                shape->GroundObject = NO;
                removed = YES;
            } else if ([currentChunk->staticItems containsObject:shape]) {
                [currentChunk->staticItems removeObject:shape];
                shape->StaticObject = YES;
                shape->GameObject = NO;
                shape->GroundObject = NO;
                removed = YES;
            } else if ([currentChunk->groundObjects containsObject:shape]) {
                [currentChunk->groundObjects removeObject:shape];
                shape->GroundObject = YES;
                shape->GameObject = NO;
                shape->StaticObject = NO;
                removed = YES;
            }
        }
        
        if (!removed) {
            NSLog(@"moveShape: Shape not found in any array of chunk %ld", shape->parentChunkID);
        }
        
        // Update local coordinates BEFORE adding to new chunk
        shape->parentChunkXCoord = newLocalX;
        shape->parentChunkYCoord = newLocalY;
        
        // Add to new chunk's arrays
        if (shape->GameObject) {
            [newChunk->gameItems addObject:shape];
        } else if (shape->StaticObject) {
            [newChunk->staticItems addObject:shape];
        } else if (shape->GroundObject) {
            [newChunk->groundObjects addObject:shape];
        } else {
            // Default to game items if type unknown
            [newChunk->gameItems addObject:shape];
            shape->GameObject = YES;
        }
        
        // Update chunk ID
        shape->parentChunkID = newChunkID;
        
        // Invalidate both chunk caches
        [self invalidateChunkCache:currentChunk];
        [self invalidateChunkCache:newChunk];
        
        // Rebuild passability/environment maps for both chunks
        // Note: Do NOT call updateShapeInfo here - that method rebuilds ground objects
        // from tile data and is only meant for initial load. The shape arrays already
        // have the correct data, we just need to recalculate the derived maps.
        [currentChunk createPassability];
        [currentChunk createEnvironmentMap];
        [newChunk createPassability];
        [newChunk createEnvironmentMap];
        
        // Mark chunks as dirty so they redraw with updated overlays
        currentChunk->dirty = YES;
        newChunk->dirty = YES;
        
        NSLog(@"Moved shape %ld to chunk %ld", (long)shape->shapeID, newChunkID);
    } else {
        // Shape stayed in the same chunk
        // Update local coordinates BEFORE recalculating passability
        shape->parentChunkXCoord = newLocalX;
        shape->parentChunkYCoord = newLocalY;
        
        // Rebuild passability and environment maps with updated coordinates
        // Note: Do NOT call updateShapeInfo here - it would duplicate ground objects
        [self invalidateChunkCache:currentChunk];
        [currentChunk createPassability];
        [currentChunk createEnvironmentMap];
        
        // Mark chunk as dirty so it redraws with updated overlays
        currentChunk->dirty = YES;
    }
}

-(void)updateDrawOptionsFromFlags
{
    BADrawOptions options = 0;
    if (drawTiles)           options |= BADrawOptionTiles;
    if (drawGroundObjects)   options |= BADrawOptionGroundObjects;
    if (drawStaticObjects)   options |= BADrawOptionStaticObjects;
    if (drawGameObjects)     options |= BADrawOptionGameObjects;
    if (drawPassability)     options |= BADrawOptionPassability;
    if (drawTargetLocations) options |= BADrawOptionTargetLocations;
    if (drawChunkHighlite)   options |= BADrawOptionChunkHighlite;
    if (drawShapeHighlite)   options |= BADrawOptionShapeHighlite;
    if (drawEnvironmentMap)  options |= BADrawOptionEnvironmentMap;
    if (drawShapeIDs)        options |= BADrawOptionShapeIDs;
    self.drawOptions = options;
}

-(U7ShapeReference*)obtainPooledShapeReference
{
    if (self.poolIndex < (NSInteger)self.shapeReferencePool.count) {
        U7ShapeReference *ref = self.shapeReferencePool[self.poolIndex++];
        // Reset the reference for reuse
        ref->GameObject = NO;
        ref->StaticObject = NO;
        ref->GroundObject = NO;
        ref->shapeID = 0;
        ref->frameNumber = 0;
        ref->parentChunkID = 0;
        ref->parentChunkXCoord = 0;
        ref->parentChunkYCoord = 0;
        ref->lift = 0;
        ref->eulerRotation = 0;
        ref->speed = 0;
        ref->depth = 0;
        ref->animates = NO;
        ref->numberOfFrames = 0;
        ref->currentFrame = 0;
        ref->maxX = 0;
        ref->maxY = 0;
        ref->maxZ = 0;
        return ref;
    }
    
    // Expand pool if needed
    U7ShapeReference *ref = [[U7ShapeReference alloc] init];
    [self.shapeReferencePool addObject:ref];
    self.poolIndex++;
    return ref;
}

-(void)resetShapeReferencePool
{
    self.poolIndex = 0;
}

-(void)prepareForDrawingCycle
{
    [self resetShapeReferencePool];
    [self.reusableShapeArray removeAllObjects];
}

-(void)invalidateChunkCache:(U7MapChunk*)mapChunk
{
    if (mapChunk) {
        NSNumber *key = @(mapChunk->flatChunkID);
        [self.chunkSortedShapesCache removeObjectForKey:key];
    }
}

-(void)invalidateAllChunkCaches
{
    [self.chunkSortedShapesCache removeAllObjects];
}



-(void)setMap:(U7Map*)theMap
{
    if(theMap)
    {
        map=theMap;
        [self invalidateAllChunkCaches]; // New map requires fresh cache
    }
}

-(void)selectChunkAtLocation:(CGPoint)location
{
    int x=startPoint.x+(location.x/(CHUNKSIZE*TILESIZE));
    int y=startPoint.y+(location.y/(CHUNKSIZE*TILESIZE));
    CGPoint selectedLocation=CGPointMake(x, y);
    NSLog(@"startpoint: %f,%f selected: %f,%f",startPoint.x,startPoint.y,selectedLocation.x,selectedLocation.y);
    if(selectedChunk)
        selectedChunk->highlited=NO;
    
    selectedChunk=[map mapChunkForLocation:selectedLocation];
    if(selectedChunk)
    {
        //selectedChunk->highlited=YES;
        pasteboardChunk=selectedChunk;
        NSLog(@"masterchunk ID: %i",selectedChunk->masterChunkID);
    }
    
}

-(void)generateMiniMap
{
    
    //miniMap=[[UIImage alloc]init];
    NSLog(@"Generating Mini Map");
    CGSize size = CGSizeMake(TOTALMAPSIZE*CHUNKSIZE*TILESIZE*miniMapScale, TOTALMAPSIZE*CHUNKSIZE*TILESIZE*miniMapScale);
    NSLog(@"Minimap size %f %f:",size.width,size.height);
    UIGraphicsBeginImageContextWithOptions(size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    //[[UIColor orangeColor] setFill];
    //UIRectFill(CGRectMake(0, 0, size.width, size.height));
    /**/
    for(int y=0;y<TOTALMAPSIZE;y++)
    {
        for(int x=0;x<TOTALMAPSIZE;x++)
        {
            if((y>=TOTALMAPSIZE)||(x>=TOTALMAPSIZE))
            {
                //do nothing
            }
            else
            {
                
                U7MapChunk * mapChunk=[map mapChunkForLocation:CGPointMake(x, y)];
                //[self drawChunkDepthSorted:mapChunk forX:x forY:y forScale:miniMapScale];
                [self drawChunkTileImage:mapChunk forX:x forY:y forScale:miniMapScale];
               
            }
            
        }
    }
    UIGraphicsPopContext();
    miniMap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // Create path.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES);
    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"ImageU7.png"];

    // Save image.
    [UIImagePNGRepresentation(miniMap) writeToFile:filePath atomically:YES];
    
    NSLog(@"Done");
}

-(void)drawChunkTileImage:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y forScale:(float)scale;
{
    
    CGRect chunkRect=CGRectMake((x*CHUNKSIZE*TILESIZE*scale), (y*CHUNKSIZE*TILESIZE*scale),CHUNKSIZE*TILESIZE*scale, CHUNKSIZE*TILESIZE*scale);

    U7Chunk * masterChunk=mapChunk->masterChunk;
   
    [[UIImage imageWithCGImage:masterChunk->tileImage.CGImage scale:masterChunk->tileImage.scale orientation:UIImageOrientationUp] drawInRect:chunkRect];
 
}

/**/
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
 
    // Drawing code
    //if([environment->U7Shapes count])
        //[self drawMap];
    [self update];
    switch (drawMode) {
        case NormalMapDrawMode:
            [self refreshMap];
            break;
        case MiniMapDrawMode:
            [self drawMiniMap];
            break;
        default:
            break;
    }
  
        
    //NSLog(@"currentFrame: %li",currentFrame);
}

-(void)drawMiniMap
{
    [miniMap drawInRect:CGRectMake(0.f, 0.f, miniMap.size.width, miniMap.size.height)];
    
    
   
}

-(void)update
{
    [self updateSpawn];
    [self removeSpritesFromMap];
    for(int count=0;count<[map->actors count];count++)
    {
        BAActor * actor=[map->actors objectAtIndex:count];
        [actor step];
    }
    
    
    [self addSpritesToMap];
    
}

-(void)setChunkWidth:(int)theChunkWidth
{
    if(theChunkWidth)
        {
        chunksWide=theChunkWidth;
        if(!chunksHigh)  // for compatibility
            chunksHigh=theChunkWidth;
        }
}


-(void)setChunkHeight:(int)theChunkHeight
{
    if(theChunkHeight)
        chunksHigh=theChunkHeight;
}

-(int)chunkwidth
{
    return chunksWide;
}

-(int)chunkheight
{
    return chunksHigh;
}


-(void)setStartPoint:(CGPoint)thePoint
{
    // Check if we're moving to a completely different area
    CGFloat deltaX = fabs(thePoint.x - startPoint.x);
    CGFloat deltaY = fabs(thePoint.y - startPoint.y);
    
    // If moving more than the visible chunk area, clear cache to free memory
    if (deltaX > chunksWide || deltaY > chunksHigh) {
        [self invalidateAllChunkCaches];
    }
    
    startPoint=thePoint;
    //NSLog(@"startPoint at %f,%f maxHeight:%i",startPoint.x,startPoint.y, maxHeight);
}
-(void)setMaxHeight:(int)theMaxHeight
{
    if(theMaxHeight>-2)
    {
        maxHeight=theMaxHeight;
        [self invalidateAllChunkCaches]; // Height change requires recalculation
    }
    [self setNeedsDisplay];
}


-(void)setPalletCycle:(int)thePalletCycle
{
    palletCycle=thePalletCycle;
}


-(void)setDrawMode:(enum BAMapDrawMode)theDrawMode
{
    drawMode=theDrawMode;
    [self invalidateAllChunkCaches]; // Draw mode change may affect caching
    switch (drawMode) {
        case NormalMapDrawMode:
            
            break;
        case MiniMapDrawMode:
            break;
        default:
            break;
    }
}

-(void)setMapScale:(float)theMapScale
{
    // Clamp the scale to valid range
    float newScale = theMapScale;
    if (newScale < MIN_MAP_SCALE) {
        newScale = MIN_MAP_SCALE;
    } else if (newScale > MAX_MAP_SCALE) {
        newScale = MAX_MAP_SCALE;
    }
    
    if (newScale != mapScale) {
        mapScale = newScale;
        [self invalidateAllChunkCaches]; // Scale change requires recalculation
        [self setNeedsDisplay];
    }
}

-(float)getMapScale
{
    return mapScale;
}

-(float)getMaxMapScale
{
    return MAX_MAP_SCALE;
}

-(float)getMinMapScale
{
    return MIN_MAP_SCALE;
}

-(CGSize)contentSize
{
    CGSize theSize=(CGSizeMake(0, 0));
    switch (drawMode) {
        case NormalMapDrawMode:
            theSize=CGSizeMake(chunksWide*CHUNKSIZE*TILESIZE*mapScale, chunksHigh*CHUNKSIZE*TILESIZE*mapScale);
            break;
        case MiniMapDrawMode:
            theSize=miniMap.size;
            break;
        default:
            break;
    }
    return theSize;
}

-(void)drawMap
{
    //NSLog(@"drawMap at %f,%f maxHeight:%i",startPoint.x,startPoint.y, maxHeight);
    //CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextClearRect(context, self.bounds);
    for(int y=0;y<chunksHigh;y++)
    {
        for(int x=0;x<chunksWide;x++)
        {
            if((y>=TOTALMAPSIZE)||(x>=TOTALMAPSIZE))
            {
                //do nothing
            }
            else
            {
                U7MapChunk * mapChunk=[map->map objectAtIndex:((y+startPoint.y)*TOTALMAPSIZE)+(x+startPoint.x)];
                //[mapChunk dump];
                [self drawChunkDepthSorted:mapChunk forX:x forY:y forScale:1];
            }
           
        }
    }
    //printf("\n");
}

-(void)dirtyMap
{
    //NSLog(@"drawMap at %f,%f maxHeight:%i",startPoint.x,startPoint.y, maxHeight);
    //CGContextRef context = UIGraphicsGetCurrentContext();
    //CGContextClearRect(context, self.bounds);
    for(int y=0;y<chunksHigh;y++)
    {
        for(int x=0;x<chunksWide;x++)
        {
            if((y>=TOTALMAPSIZE)||(x>=TOTALMAPSIZE))
            {
                //do nothing
            }
            else
            {
                U7MapChunk * mapChunk=[map->map objectAtIndex:((y+startPoint.y)*TOTALMAPSIZE)+(x+startPoint.x)];
                mapChunk->dirty=YES;
                [self invalidateChunkCache:mapChunk];
            }
           
        }
    }
    //printf("\n");
}

-(void)refreshMap
{
    // Prepare for new drawing cycle - reset object pools
    [self prepareForDrawingCycle];
    
    // Update draw options bitmask for efficient checking
    [self updateDrawOptionsFromFlags];
    
    // Get visible rect for frustum culling
    CGRect visibleRect = self.bounds;
    CGFloat chunkPixelSize = CHUNKSIZE * TILESIZE * mapScale;
    
    // Calculate visible chunk range to avoid unnecessary iterations
    int minVisibleX = MAX(0, (int)(visibleRect.origin.x / chunkPixelSize));
    int maxVisibleX = MIN(chunksWide, (int)ceil((visibleRect.origin.x + visibleRect.size.width) / chunkPixelSize));
    int minVisibleY = MAX(0, (int)(visibleRect.origin.y / chunkPixelSize));
    int maxVisibleY = MIN(chunksHigh, (int)ceil((visibleRect.origin.y + visibleRect.size.height) / chunkPixelSize));
    
    // Pre-calculate frequently used values
    int totalMapSize = TOTALMAPSIZE;
    int startX = (int)startPoint.x;
    int startY = (int)startPoint.y;
    
    // Draw visible chunks with frustum culling
    for (int y = minVisibleY; y < maxVisibleY; y++) {
        int mapY = y + startY;
        if (mapY >= totalMapSize) continue;
        
        for (int x = minVisibleX; x < maxVisibleX; x++) {
            int mapX = x + startX;
            if (mapX >= totalMapSize) continue;
            
            // Calculate chunk rect for additional culling check
            CGRect chunkRect = CGRectMake(x * chunkPixelSize, y * chunkPixelSize, chunkPixelSize, chunkPixelSize);
            
            // Skip if chunk is completely outside visible area
            if (!CGRectIntersectsRect(visibleRect, chunkRect)) {
                continue;
            }
            
            U7MapChunk *mapChunk = [map->map objectAtIndex:(mapY * totalMapSize) + mapX];
            [self drawChunkDepthSortedOptimized:mapChunk forX:x forY:y forScale:mapScale];
            mapChunk->dirty = NO;
        }
    }
    
    // Draw overlays using bitmask checks (faster than individual BOOLs)
    BADrawOptions options = self.drawOptions;
    
    if (options & BADrawOptionTargetLocations) {
        [self drawTargetLocationsOptimized];
    }
    
    if (options & BADrawOptionPassability) {
        [self drawPassabilityOverlayForVisibleChunks:minVisibleX maxX:maxVisibleX minY:minVisibleY maxY:maxVisibleY];
    }
    
    if (options & BADrawOptionChunkHighlite) {
        [self drawChunkHighliteOverlayForVisibleChunks:minVisibleX maxX:maxVisibleX minY:minVisibleY maxY:maxVisibleY];
    }
    
    if (options & BADrawOptionShapeHighlite) {
        [self drawShapeHighlite];
    }
    
    if (options & BADrawOptionEnvironmentMap) {
        [self drawEnvironmentMapOverlayForVisibleChunks:minVisibleX maxX:maxVisibleX minY:minVisibleY maxY:maxVisibleY];
    }
}

#pragma mark - Optimized Overlay Drawing

-(void)drawTargetLocationsOptimized
{
    if ([map->actors count] == 0) return;
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set colors once for all target locations
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.15);
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 0.55);
    
    for (int actorIndex = 0; actorIndex < [map->actors count]; actorIndex++) {
        BAActor *actor = [map->actors objectAtIndex:actorIndex];
        if (!actor->aiManager->actionManager) continue;
        
        BAActionManager *manager = actor->aiManager->actionManager;
        CGPoint location = manager->targetGlobalLocation;
        U7MapChunkCoordinate *mapChunkCoordinate = [environment MapChunkCoordinateForGlobalTilePosition:location];
        CGPoint chunkCoordinate = [mapChunkCoordinate mapChunkCoordinate];
        
        CGPoint offsetChunkLocation = CGPointMake(chunkCoordinate.x - startPoint.x, chunkCoordinate.y - startPoint.y);
        CGPoint chunkTilePos = [mapChunkCoordinate getChunkTilePosition];
        CGPoint offsetTileLocation = CGPointMake(
            ((offsetChunkLocation.x * TILESIZE * CHUNKSIZE) + chunkTilePos.x * TILESIZE) * mapScale,
            ((offsetChunkLocation.y * TILESIZE * CHUNKSIZE) + chunkTilePos.y * TILESIZE) * mapScale
        );
        
        CGRect imageFrame = CGRectMake(offsetTileLocation.x, offsetTileLocation.y, TILESIZE * mapScale, TILESIZE * mapScale);
        CGContextFillRect(context, imageFrame);
        CGContextStrokeRect(context, imageFrame);
    }
}

-(void)drawPassabilityOverlayForVisibleChunks:(int)minX maxX:(int)maxX minY:(int)minY maxY:(int)maxY
{
    int totalMapSize = TOTALMAPSIZE;
    int startX = (int)startPoint.x;
    int startY = (int)startPoint.y;
    
    for (int y = minY; y < maxY; y++) {
        int mapY = y + startY;
        if (mapY >= totalMapSize) continue;
        
        for (int x = minX; x < maxX; x++) {
            int mapX = x + startX;
            if (mapX >= totalMapSize) continue;
            
            U7MapChunk *mapChunk = [map->map objectAtIndex:(mapY * totalMapSize) + mapX];
            [self drawPassability:mapChunk forX:x forY:y];
        }
    }
}

-(void)drawChunkHighliteOverlayForVisibleChunks:(int)minX maxX:(int)maxX minY:(int)minY maxY:(int)maxY
{
    for (int y = minY; y < maxY; y++) {
        for (int x = minX; x < maxX; x++) {
            [self drawMapChunkHighlite:x forY:y];
        }
    }
}

-(void)drawEnvironmentMapOverlayForVisibleChunks:(int)minX maxX:(int)maxX minY:(int)minY maxY:(int)maxY
{
    int totalMapSize = TOTALMAPSIZE;
    int startX = (int)startPoint.x;
    int startY = (int)startPoint.y;
    
    for (int y = minY; y < maxY; y++) {
        int mapY = y + startY;
        if (mapY >= totalMapSize) continue;
        
        for (int x = minX; x < maxX; x++) {
            int mapX = x + startX;
            if (mapX >= totalMapSize) continue;
            
            U7MapChunk *mapChunk = [map->map objectAtIndex:(mapY * totalMapSize) + mapX];
            [self drawEnvironmentMap:mapChunk forX:x forY:y];
        }
    }
}

#pragma mark - Optimized Chunk Drawing

-(void)drawChunkDepthSortedOptimized:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y forScale:(float)scale
{
    // Check cache first - if chunk hasn't changed, use cached sorted shapes
    NSNumber *cacheKey = @(mapChunk->flatChunkID);
    NSArray *cachedShapes = nil;
    BOOL useCache = !mapChunk->dirty && !mapChunk->animates;
    
    if (useCache) {
        cachedShapes = self.chunkSortedShapesCache[cacheKey];
    }
    
    NSArray *shapesToDraw;
    
    if (cachedShapes && [mapChunk->sprites count] == 0) {
        // Use cached shapes for static chunks without sprites
        shapesToDraw = cachedShapes;
    } else {
        // Build and sort shapes
        shapesToDraw = [self buildSortedShapesForChunk:mapChunk];
        
        // Cache if chunk is static (no sprites, no animations)
        if ([mapChunk->sprites count] == 0 && !mapChunk->animates) {
            self.chunkSortedShapesCache[cacheKey] = shapesToDraw;
        }
    }
    
    // Draw the tile image background first
    U7Chunk *masterChunk = mapChunk->masterChunk;
    CGRect chunkRect = CGRectMake(x * CHUNKSIZE * TILESIZE * scale,
                                   y * CHUNKSIZE * TILESIZE * scale,
                                   CHUNKSIZE * TILESIZE * scale,
                                   CHUNKSIZE * TILESIZE * scale);
    
    // Use animated tile image if chunk has water tiles
    UIImage *tileImageToDraw = [masterChunk tileImageForAnimationFrame:self.waterAnimationFrame];
    
    [[UIImage imageWithCGImage:tileImageToDraw.CGImage
                         scale:tileImageToDraw.scale
                   orientation:UIImageOrientationUp] drawInRect:chunkRect];
    
    // Draw sorted shapes
    int chunkOffsetX = x * CHUNKSIZE;
    int chunkOffsetY = y * CHUNKSIZE;
    
    for (U7ShapeReference *reference in shapesToDraw) {
        [self drawShapeOptimized:reference
                         forX:reference->parentChunkXCoord + chunkOffsetX
                         forY:reference->parentChunkYCoord + chunkOffsetY
                         forZ:reference->lift
                forPalletCycle:palletCycle
                      forScale:scale];
        
        if (reference->animates) {
            [reference incrementCurrentFrame];
            
            // Safety check: ensure currentFrame stays within bounds using ACTUAL frame count from shape
            // This prevents crashes when reference->numberOfFrames is stale or incorrect
            if (reference->shapeID >= 0 && reference->shapeID < [environment->U7Shapes count]) {
                U7Shape *shape = [environment->U7Shapes objectAtIndex:reference->shapeID];
                long actualFrameCount = [shape->frames count];
                
                if (actualFrameCount > 0 && reference->currentFrame >= actualFrameCount) {
                    reference->currentFrame = 0;
                    // Also fix the stored numberOfFrames for future iterations
                    reference->numberOfFrames = actualFrameCount;
                }
            }
        }
    }
}

-(NSArray*)buildSortedShapesForChunk:(U7MapChunk*)mapChunk
{
    NSMutableArray *unsortedShapes = self.reusableShapeArray;
    [unsortedShapes removeAllObjects];
    
    U7Chunk *chunk = [environment->U7Chunks objectAtIndex:mapChunk->masterChunkID];
    BADrawOptions options = self.drawOptions;
    
    // Process all passes in optimized order
    for (int pass = -1; pass < maxHeight + 1; pass++) {
        for (int tileY = 0; tileY < CHUNKSIZE; tileY++) {
            for (int tileX = 0; tileX < CHUNKSIZE; tileX++) {
                
                U7ChunkIndex *chunkIndex = [chunk->chunkMap objectAtIndex:(tileY * CHUNKSIZE) + tileX];
                
                if (pass == -1) {
                    // Tiles are already drawn as part of the chunk tile image
                    // We don't need to add them here at all - the tileImage handles
                    // both static tiles and tiles with transparency correctly
                    
                    // Draw ground objects - check all height levels for ground objects
                    // Some ground objects like carpets might be at lift 0, but we should
                    // still check in case they have different lift values
                    if (options & BADrawOptionGroundObjects) {
                        // Check for ground objects at lift 0 (most common)
                        U7ShapeReference *reference = [mapChunk groundShapeForLocation:CGPointMake(tileX, tileY) forHeight:0];
                        if (reference) {
                            reference->GroundObject = YES;
                            [unsortedShapes addObject:reference];
                        }
                    }
                } else {
                    // Draw static objects
                    if (options & BADrawOptionStaticObjects) {
                        U7ShapeReference *reference = [mapChunk staticShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                        if (reference) {
                            reference->StaticObject = YES;
                            [unsortedShapes addObject:reference];
                        }
                    } else {
                        U7ShapeReference *reference = [mapChunk staticShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                        if (reference) {
                            U7ShapeReference *newReference = [self obtainPooledShapeReference];
                            newReference->shapeID = 644;
                            newReference->parentChunkXCoord = tileX;
                            newReference->parentChunkYCoord = tileY;
                            newReference->lift = pass;
                            newReference->currentFrame = 0;
                            [unsortedShapes addObject:newReference];
                        }
                    }
                    
                    // Draw game objects
                    if (options & BADrawOptionGameObjects) {
                        U7ShapeReference *reference = [mapChunk gameShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                        if (reference) {
                            reference->GameObject = YES;
                            [unsortedShapes addObject:reference];
                        }
                    } else {
                        U7ShapeReference *reference = [mapChunk gameShapeForLocation:CGPointMake(tileX, tileY) forHeight:pass];
                        if (reference) {
                            U7ShapeReference *newReference = [self obtainPooledShapeReference];
                            newReference->shapeID = 644;
                            newReference->parentChunkXCoord = tileX;
                            newReference->parentChunkYCoord = tileY;
                            newReference->lift = pass;
                            newReference->currentFrame = 0;
                            [unsortedShapes addObject:newReference];
                        }
                    }
                }
            }
        }
    }
    
    // Add sprites
    for (BASprite *sprite in mapChunk->sprites) {
        [unsortedShapes addObject:sprite->shapeReference];
    }
    
    // Calculate depths for isometric sorting
    // In isometric projection, objects further back (higher X+Y) should be drawn first
    // Objects at higher Z (lift) should be drawn later (on top)
    // 
    // Key insight: In U7, objects are anchored at their SOUTHEAST corner
    // (highest X and Y within their footprint). This means:
    // - parentChunkXCoord/YCoord is the SE corner position
    // - The object extends BACKWARDS (negative X and Y) from this point
    //
    // For proper sorting, we need to use the BACK (NW) corner of the object
    // This ensures that a large carpet doesn't appear in front of a chair
    // that's sitting on top of it
    for (U7ShapeReference *reference in unsortedShapes) {
        U7Shape *shape = [environment->U7Shapes objectAtIndex:reference->shapeID];
        
        // Calculate the back (NW) corner of the object
        // The anchor is at the SE corner, so we subtract the tile size to get NW
        int tileSizeX = shape->TileSizeXMinus1 + 1;
        int tileSizeY = shape->TileSizeYMinus1 + 1;
        
        // Back corner position (in tile units, then converted to pixels)
        int backX = reference->parentChunkXCoord - tileSizeX + 1;
        int backY = reference->parentChunkYCoord - tileSizeY + 1;
        
        reference->maxX = (backX + 1) * TILESIZE;
        reference->maxY = (backY + 1) * TILESIZE;
        reference->maxZ = reference->lift * HEIGHTOFFSET;
        
        // Depth formula for isometric sorting:
        // Objects with lower back-corner X+Y are drawn first (further back)
        // Objects at higher Z (lift) are drawn later (on top)
        //
        // We multiply X+Y by a factor larger than max possible Z contribution
        // to ensure position always takes precedence over height
        //
        // Ground objects and flat objects (carpets, rugs) need special handling:
        // They should be drawn BEFORE any objects at the same position,
        // even at lift 0. We give them a negative lift offset to ensure this.
        //
        // Carpets (shape 190, 483, etc.) are often stored as StaticObjects but
        // should be treated like ground objects for sorting purposes.
        // We detect them by checking if they're large flat objects at lift 0.
        int effectiveLift = reference->lift;
        
        BOOL isFloorObject = NO;
        if (reference->GroundObject) {
            isFloorObject = YES;
        } else if (reference->lift == 0 && reference->StaticObject) {
            // Check if this is a flat/carpet-like object
            // Carpets typically have large X/Y footprint but no height
            // Shape 190 is a known carpet shape
            if (reference->shapeID == 190 || reference->shapeID == 483) {
                isFloorObject = YES;
            } else {
                // For other static objects at lift 0, check if they have a large footprint
                // and would logically be floor coverings
                int footprintSize = tileSizeX * tileSizeY;
                if (footprintSize >= 4 && shape->tileSizeZ == 0) {
                    // Large footprint, no height = likely a floor covering
                    isFloorObject = YES;
                }
            }
        }
        
        if (isFloorObject) {
            // Floor objects need special handling for depth sorting.
            // They must ALWAYS be drawn before any non-floor objects in the same area.
            //
            // We use a very negative base depth (-1000000) to ensure all floor objects
            // are drawn before non-floor objects, while still maintaining proper order
            // among floor objects themselves using their back corner position.
            reference->depth = -1000000 + ((reference->maxX + reference->maxY) * 128);
        } else {
            reference->depth = ((reference->maxX + reference->maxY) * 128) + (effectiveLift * HEIGHTOFFSET);
        }
        /*
        // Extra debug for carpet shapes - only for chunks 407 and 423
        if ((reference->shapeID == 190 || reference->shapeID == 483) && 
            (mapChunk->masterChunkID == 407 || mapChunk->masterChunkID == 423)) {
            // Calculate carpet coverage area
            int coverMinX = reference->parentChunkXCoord - tileSizeX + 1;
            int coverMinY = reference->parentChunkYCoord - tileSizeY + 1;
            int coverMaxX = reference->parentChunkXCoord;
            int coverMaxY = reference->parentChunkYCoord;
            
            NSLog(@"CARPET DEBUG: Shape %ld at pos(%d,%d) covers tiles (%d,%d) to (%d,%d) - isFloorObject=%d, effectiveLift=%d, depth=%d",
                  (long)reference->shapeID,
                  reference->parentChunkXCoord, reference->parentChunkYCoord,
                  coverMinX, coverMinY, coverMaxX, coverMaxY,
                  isFloorObject, effectiveLift, reference->depth);
        }
        */
    }
    /*
    // Debug: Log shapes for chunks 407 and 423
    if (mapChunk->masterChunkID == 407 || mapChunk->masterChunkID == 423) {
        NSLog(@"=== Chunk %d Depth Sort Debug ===", mapChunk->masterChunkID);
        
        // Sort the shapes first to show them in draw order
        NSArray *debugSortedShapes = [unsortedShapes sortedArrayUsingComparator:^NSComparisonResult(U7ShapeReference *a, U7ShapeReference *b) {
            if (a->depth < b->depth) return NSOrderedAscending;
            if (a->depth > b->depth) return NSOrderedDescending;
            return NSOrderedSame;
        }];
        
        NSLog(@"Shapes in DRAW ORDER (first = behind, last = on top):");
        for (U7ShapeReference *reference in debugSortedShapes) {
            NSString *type = @"Unknown";
            if (reference->GroundObject) type = @"Ground";
            else if (reference->StaticObject) type = @"Static";
            else if (reference->GameObject) type = @"Game";
            
            U7Shape *shape = [environment->U7Shapes objectAtIndex:reference->shapeID];
            
            // Highlight carpets (190, 483) and chairs (873)
            NSString *highlight = @"";
            if (reference->shapeID == 190 || reference->shapeID == 483 || reference->shapeID == 873) {
                int tileSizeX = shape->TileSizeXMinus1 + 1;
                int tileSizeY = shape->TileSizeYMinus1 + 1;
                int footprint = tileSizeX * tileSizeY;
                highlight = [NSString stringWithFormat:@" *** CARPET/CHAIR *** tileSizeZ=%d footprint=%d", shape->tileSizeZ, footprint];
            }
            
            NSLog(@"Shape %ld (%@): pos(%d,%d) lift=%d depth=%d tileSize=(%d,%d)%@", 
                  (long)reference->shapeID, type,
                  reference->parentChunkXCoord, reference->parentChunkYCoord,
                  reference->lift, reference->depth,
                  shape->TileSizeXMinus1 + 1, shape->TileSizeYMinus1 + 1,
                  highlight);
        }
        NSLog(@"=================================");
    }
    */
    // Sort by depth with proper tie-breaking
    // When depths are equal, we need secondary criteria to ensure consistent ordering
    NSArray *sortedShapes = [unsortedShapes sortedArrayUsingComparator:^NSComparisonResult(U7ShapeReference *a, U7ShapeReference *b) {
        // Primary sort: by depth (lower depth = drawn first = behind)
        if (a->depth < b->depth) return NSOrderedAscending;
        if (a->depth > b->depth) return NSOrderedDescending;
        
        // Secondary sort: by lift (Z height) - lower objects drawn first (behind)
        if (a->lift < b->lift) return NSOrderedAscending;
        if (a->lift > b->lift) return NSOrderedDescending;
        
        // Tertiary sort: by Y position - objects further north drawn first (behind)
        if (a->parentChunkYCoord < b->parentChunkYCoord) return NSOrderedAscending;
        if (a->parentChunkYCoord > b->parentChunkYCoord) return NSOrderedDescending;
        
        // Quaternary sort: by X position - objects further west drawn first (behind)
        if (a->parentChunkXCoord < b->parentChunkXCoord) return NSOrderedAscending;
        if (a->parentChunkXCoord > b->parentChunkXCoord) return NSOrderedDescending;
        
        // Final tie-breaker: ground objects before static before game objects
        // Ground objects (like carpets) should be drawn first (behind)
        if (a->GroundObject && !b->GroundObject) return NSOrderedAscending;
        if (!a->GroundObject && b->GroundObject) return NSOrderedDescending;
        if (a->StaticObject && b->GameObject) return NSOrderedAscending;
        if (a->GameObject && b->StaticObject) return NSOrderedDescending;
        
        return NSOrderedSame;
    }];
    
    return sortedShapes;
}

#pragma mark - Optimized Shape Drawing

-(void)drawShapeOptimized:(U7ShapeReference*)theReference forX:(int)xPos forY:(int)yPos forZ:(int)zPos forPalletCycle:(int)cycle forScale:(float)scale
{
    // Bounds check for shapeID
    if (theReference->shapeID < 0 || theReference->shapeID >= [environment->U7Shapes count]) {
        NSLog(@"drawShapeOptimized: Invalid shapeID %ld (max %lu)", theReference->shapeID, (unsigned long)[environment->U7Shapes count]);
        return;
    }
    
    U7Shape *shape = [environment->U7Shapes objectAtIndex:theReference->shapeID];
    
    // Bounds check for currentFrame - clamp instead of skip to ensure shape renders
    long frameToUse = theReference->currentFrame;
    if (frameToUse < 0 || frameToUse >= [shape->frames count]) {
        NSLog(@"drawShapeOptimized: Invalid frame %ld for shapeID %ld (max %lu), clamping to 0", 
              theReference->currentFrame, theReference->shapeID, (unsigned long)[shape->frames count] - 1);
        frameToUse = 0;
        
        // Also fix the reference so future draws work correctly
        theReference->currentFrame = 0;
        if (theReference->frameNumber >= [shape->frames count]) {
            theReference->frameNumber = 0;
        }
    }
    
    U7Bitmap *bitmap = [shape->frames objectAtIndex:frameToUse];
    
    // Determine which image index to use
    // - For animated shapes (water, lava, torches), cycle through palette versions
    // - For translucent shapes, always use index 0 (the base translucency)
    int imageIndex = 0;
    if (bitmap->palletCycles > 1) {
        // Multiple palette cycles exist - check if this is for animation or translucency
        // Translucent shapes use the shape's translucent flag
        if (shape->translucent) {
            // Translucent shape - use base image (index 0)
            imageIndex = 0;
        } else if (shape->water) {
            // Water shape - use synchronized water animation frame
            // This ensures all water tiles animate together smoothly
            imageIndex = (int)(self.waterAnimationFrame % bitmap->palletCycles);
        } else {
            // Other animated shape (lava, torches, etc.) - use the cycle parameter
            imageIndex = cycle % bitmap->palletCycles;
        }
    }
    
    // Get the CGImage
    CGImageRef CGImageToDraw;
    [[bitmap->CGImages objectAtIndex:imageIndex] getValue:&CGImageToDraw];
    
    if (!CGImageToDraw) return;
    
    // Apply FSR upscaling if enabled
    CGImageRef finalImageToDraw = CGImageToDraw;
    if (useFSRUpscaling) {
        BAImageUpscaler *upscaler = [BAImageUpscaler sharedUpscaler];
        CGImageRef upscaledImage = [upscaler upscaleCGImage:CGImageToDraw];
        if (upscaledImage) {
            finalImageToDraw = upscaledImage;
        }
    }
    
    // Calculate the draw rect
    CGRect imageFrame;
    if (shape->tile) {
        // Tile
        imageFrame = CGRectMake(xPos * TILESIZE * scale,
                                yPos * TILESIZE * scale,
                                TILESIZE * scale,
                                TILESIZE * scale);
    } else {
        CGFloat offsetX = ((xPos + 1) * TILESIZE * scale) + ([bitmap reverseTranslateX] * scale) - (zPos * HEIGHTOFFSET * scale);
        CGFloat offsetY = ((yPos + 1) * TILESIZE * scale) + ([bitmap reverseTranslateY] * scale) - (zPos * HEIGHTOFFSET * scale);
        imageFrame = CGRectMake(offsetX, offsetY, bitmap->width * scale, bitmap->height * scale);
    }
    
    // Draw with appropriate orientation
    UIImageOrientation orientation;
    if (theReference->eulerRotation == 90) {
        orientation = UIImageOrientationLeft;
    } else if (theReference->eulerRotation == -90) {
        orientation = UIImageOrientationRight;
    } else {
        orientation = UIImageOrientationDownMirrored;
    }
    
    // Use the upscaled image's native scale for better quality rendering
    BAImageUpscaler *upscaler = [BAImageUpscaler sharedUpscaler];
    CGFloat imageScale = useFSRUpscaling ? (bitmap->image.scale / [upscaler currentScaleFactor]) : bitmap->image.scale;
    
    [[UIImage imageWithCGImage:finalImageToDraw
                         scale:imageScale
                   orientation:orientation] drawInRect:imageFrame];
    
    // Draw shape ID and lift labels if enabled
    if (drawShapeIDs && scale >= 0.5) {  // Only draw labels when zoomed in enough to read them
        NSString *shapeIDString = [NSString stringWithFormat:@"%ld:%d", (long)theReference->shapeID, zPos];
        
        // Position the label at the top-left of the shape
        CGFloat labelX = imageFrame.origin.x;
        CGFloat labelY = imageFrame.origin.y - (10 * scale);  // Above the shape
        
        // Ensure label stays on screen
        if (labelY < 0) labelY = imageFrame.origin.y;
        
        NSDictionary *textAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:8 * scale],
            NSForegroundColorAttributeName: [UIColor yellowColor],
            NSBackgroundColorAttributeName: [[UIColor blackColor] colorWithAlphaComponent:0.7]
        };
        
        [shapeIDString drawAtPoint:CGPointMake(labelX, labelY) withAttributes:textAttributes];
    }
}




-(void)drawChunkDepthSorted:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y forScale:(float)scale
{
    // Redirect to optimized version for backward compatibility
    [self drawChunkDepthSortedOptimized:mapChunk forX:x forY:y forScale:scale];
}






-(void)drawShape:(U7ShapeReference*)theReference forFrame:(long)frame forX:(int)xPos forY:(int)yPos forZ:(int)zPos forPalletCycle:(int)palletCycle forScale:(float)scale
 {
     // Redirect to optimized version
     [self drawShapeOptimized:theReference forX:xPos forY:yPos forZ:zPos forPalletCycle:palletCycle forScale:scale];
 }


-(void)drawMapChunkHighlite:(int)x forY:(int)y
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGRect theRect=CGRectMake(x*TILESIZE*CHUNKSIZE*mapScale,y*TILESIZE*CHUNKSIZE*mapScale, TILESIZE*CHUNKSIZE*mapScale, TILESIZE*CHUNKSIZE*mapScale);
    CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, .05);
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 0.55);
    CGContextFillRect(context, theRect);
    CGContextStrokeRect(context, theRect);
    
    U7MapChunk * mapChunk=[map->map objectAtIndex:((y+startPoint.y)*TOTALMAPSIZE)+(x+startPoint.x)];
    NSString * chunkIDString=[NSString stringWithFormat:@"%i \n %0.0f,%0.0f",mapChunk->masterChunkID,x+startPoint.x,y+startPoint.y];
    //U7Chunk * chunk=[environment->U7Chunks objectAtIndex:mapChunk->masterChunkID];
    
    NSMutableParagraphStyle* textStyle = NSMutableParagraphStyle.defaultParagraphStyle.mutableCopy;
        textStyle.alignment = NSTextAlignmentCenter;

    NSDictionary* textFontAttributes = @{NSFontAttributeName: [UIFont fontWithName: @"Helvetica" size: 12 * mapScale], NSForegroundColorAttributeName: UIColor.redColor, NSParagraphStyleAttributeName: textStyle};

    [chunkIDString drawInRect: theRect withAttributes: textFontAttributes];
    
}

-(void)drawPassability:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Batch rects by color to minimize context state changes
    NSMutableArray *redRects = [NSMutableArray array];
    NSMutableArray *greenRects = [NSMutableArray array];
    
    float baseX = x * TILESIZE * CHUNKSIZE * mapScale;
    float baseY = y * TILESIZE * CHUNKSIZE * mapScale;
    float scaledTileSize = TILESIZE * mapScale;
    
    for (int chunkY = 0; chunkY < CHUNKSIZE; chunkY++) {
        for (int chunkX = 0; chunkX < CHUNKSIZE; chunkX++) {
            CGPoint chunkLocation = CGPointMake(chunkX, chunkY);
            int passability = [mapChunk passabilityForLocation:chunkLocation atHeight:1];
            
            if (passability == 0) {
                CGRect rect = CGRectMake(baseX + (chunkX * scaledTileSize),
                                         baseY + (chunkY * scaledTileSize),
                                         scaledTileSize, scaledTileSize);
                [redRects addObject:[NSValue valueWithCGRect:rect]];
            } else if (passability == 1) {
                CGRect rect = CGRectMake(baseX + (chunkX * scaledTileSize),
                                         baseY + (chunkY * scaledTileSize),
                                         scaledTileSize, scaledTileSize);
                [greenRects addObject:[NSValue valueWithCGRect:rect]];
            }
        }
    }
    
    // Draw all red rects
    if ([redRects count] > 0) {
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.15);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 0.55);
        for (NSValue *value in redRects) {
            CGRect rect = [value CGRectValue];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
    
    // Draw all green rects
    if ([greenRects count] > 0) {
        CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 0.15);
        CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 0.55);
        for (NSValue *value in greenRects) {
            CGRect rect = [value CGRectValue];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
}

-(void)drawShapeHighlite
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for(int index=0;index<[selectedShapes count];index++)
    {
        U7ShapeReference * reference=[selectedShapes objectAtIndex:index];
        
        // Get global tile coordinate of shape
        CGPoint globalTile = [reference globalCoordinate];
        
        // Convert to view coordinates (accounting for startPoint offset and scale)
        // This gives us the anchor point (SE corner of tile footprint)
        CGFloat viewX = (globalTile.x - (startPoint.x * CHUNKSIZE)) * TILESIZE * mapScale;
        CGFloat viewY = (globalTile.y - (startPoint.y * CHUNKSIZE)) * TILESIZE * mapScale;
        
        // Get the shape and its bitmap to calculate actual visual bounds
        U7Shape *shape = [environment->U7Shapes objectAtIndex:reference->shapeID];
        
        // Validate frame number is within bounds
        U7Bitmap *bitmap = nil;
        if (reference->frameNumber < [shape->frames count]) {
            bitmap = [shape->frames objectAtIndex:reference->frameNumber];
        } else {
            NSLog(@"WARNING: Shape %ld has invalid frame number %d (max: %lu). Using fallback bounds.",
                  (long)reference->shapeID, reference->frameNumber, (unsigned long)[shape->frames count] - 1);
        }
        
        CGRect theRect;
        
        if (bitmap) {
            // Calculate the actual visual bounds using the same formula as drawing
            // The shape is drawn at: anchor + 1 tile + bitmap offset - height offset
            CGFloat zPos = reference->lift;
            CGFloat offsetX = ((globalTile.x - (startPoint.x * CHUNKSIZE) + 1) * TILESIZE * mapScale) 
                            + ([bitmap reverseTranslateX] * mapScale) 
                            - (zPos * HEIGHTOFFSET * mapScale);
            CGFloat offsetY = ((globalTile.y - (startPoint.y * CHUNKSIZE) + 1) * TILESIZE * mapScale) 
                            + ([bitmap reverseTranslateY] * mapScale) 
                            - (zPos * HEIGHTOFFSET * mapScale);
            
            theRect = CGRectMake(offsetX, offsetY, bitmap->width * mapScale, bitmap->height * mapScale);
        } else {
            // Fallback to footprint if no bitmap available
            int tileSizeX = shape->TileSizeXMinus1 + 1;
            int tileSizeY = shape->TileSizeYMinus1 + 1;
            
            CGFloat rectX = viewX - ((tileSizeX - 1) * TILESIZE * mapScale);
            CGFloat rectY = viewY - ((tileSizeY - 1) * TILESIZE * mapScale);
            CGFloat rectW = tileSizeX * TILESIZE * mapScale;
            CGFloat rectH = tileSizeY * TILESIZE * mapScale;
            
            theRect = CGRectMake(rectX, rectY, rectW, rectH);
        }
        
        CGContextSetRGBFillColor(context, 1.0, .6, 0.0, .15);
        CGContextSetRGBStrokeColor(context, 1.0, .6, 0.0, 0.55);
        CGContextFillRect(context, theRect);
        CGContextStrokeRect(context, theRect);
        
        // Draw shape info label
        NSString *infoString = [NSString stringWithFormat:@"ID:%ld L:%d", (long)reference->shapeID, reference->lift];
        NSDictionary *textAttributes = @{
            NSFontAttributeName: [UIFont systemFontOfSize:10 * mapScale],
            NSForegroundColorAttributeName: [UIColor orangeColor]
        };
        [infoString drawAtPoint:CGPointMake(theRect.origin.x + 2, theRect.origin.y + 2) withAttributes:textAttributes];
    }
}

-(void)drawEnvironmentMap:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Batch rects by environment type for minimal context state changes
    NSMutableArray *waterRects = [NSMutableArray array];
    NSMutableArray *grassRects = [NSMutableArray array];
    NSMutableArray *otherRects = [NSMutableArray array];
    
    float baseX = x * TILESIZE * CHUNKSIZE * mapScale;
    float baseY = y * TILESIZE * CHUNKSIZE * mapScale;
    float scaledTileSize = TILESIZE * mapScale;
    
    for (int chunkY = 0; chunkY < CHUNKSIZE; chunkY++) {
        for (int chunkX = 0; chunkX < CHUNKSIZE; chunkX++) {
            CGPoint chunkLocation = CGPointMake(chunkX, chunkY);
            enum BAEnvironmentType type = [mapChunk environmentTypeAtLocation:chunkLocation];
            
            CGRect rect = CGRectMake(baseX + (chunkX * scaledTileSize),
                                     baseY + (chunkY * scaledTileSize),
                                     scaledTileSize, scaledTileSize);
            
            switch (type) {
                case WaterBAEnvironmentType:
                    [waterRects addObject:[NSValue valueWithCGRect:rect]];
                    break;
                case GrassBAEnvironmentType:
                    [grassRects addObject:[NSValue valueWithCGRect:rect]];
                    break;
                case NoBAEnvironmentType:
                default:
                    [otherRects addObject:[NSValue valueWithCGRect:rect]];
                    break;
            }
        }
    }
    
    // Draw water tiles (blue)
    if ([waterRects count] > 0) {
        CGContextSetRGBFillColor(context, 0.0, 0.0, 1.0, 0.15);
        CGContextSetRGBStrokeColor(context, 0.0, 0.0, 1.0, 0.55);
        for (NSValue *value in waterRects) {
            CGRect rect = [value CGRectValue];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
    
    // Draw grass tiles (green)
    if ([grassRects count] > 0) {
        CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, 0.15);
        CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 0.55);
        for (NSValue *value in grassRects) {
            CGRect rect = [value CGRectValue];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
    
    // Draw other tiles (red)
    if ([otherRects count] > 0) {
        CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.15);
        CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 0.55);
        for (NSValue *value in otherRects) {
            CGRect rect = [value CGRectValue];
            CGContextFillRect(context, rect);
            CGContextStrokeRect(context, rect);
        }
    }
}

 
/**/

#pragma -mark Sprites

-(BAActor*)randomActor:(int)shapeID useRandomSprite:(BOOL)randomSprite forLocation:(CGPoint)location forTarget:(CGPoint)targetLocation
{
    //logPoint(location,@"StartPoint");
    //logPoint(targetLocation,@"targetLocation");
    
    U7ShapeReference * theReference=[[U7ShapeReference alloc]init];
    if(location.x&&location.y)
        NSLog(@"%f",location.x);
    if(randomSprite)
        theReference->shapeID=randomHumanSpriteID();
    else
        theReference->shapeID=shapeID;
    
    theReference->lift=1;
    theReference->frameNumber=0;
    //theReference->currentFrame=currentFrame;
    theReference->GroundObject=YES;
    theReference->speed=speedForCharacterSprite(shapeID);
    
    //NSLog(@"The Speed: %i",theReference->speed);
    BAActor * theActor=[[BAActor alloc]init];
    [theActor setGlobalLocation:location];
    theActor->shapeReference=theReference;
    if(environment)
    {
       [theActor setEnvironment:environment];
       [theActor setMap:map];
    }
    
    //CGRect boundsRect=CGRectMake(sprite->globalLocation.x-40, sprite->globalLocation.y-40, 80, 80);
    CGRect boundsRect=CGRectMake(0,0, SUPERCHUNKSIZE*MAPSIZE*CHUNKSIZE, SUPERCHUNKSIZE*MAPSIZE*CHUNKSIZE);
    BAActionManager * manager=theActor->aiManager->actionManager;
    [manager setBounds:boundsRect];
    [manager setTargetLocation:targetLocation];
    [manager->currentAction setTargetDistanceTraveled:1];
    
    [manager setAction:PerformActionSequenceActionType forDirection:[manager DirectionTowardPoint:location toPoint:manager->targetGlobalLocation]forTarget:targetLocation];
    
    [manager->currentAction setTargetDistanceTraveled:1];
    [map->actors addObject:theActor];
    return theActor;
}

-(BAActor*)randomActor:(int)shapeID useRandomSprite:(BOOL)randomSprite forLocation:(CGPoint)location
{
    U7ShapeReference * theReference=[[U7ShapeReference alloc]init];
    if(location.x&&location.y)
    {
        //NSLog(@"%f",location.x);
    }
        
    if(randomSprite)
        theReference->shapeID=randomHumanSpriteID();
    else
        theReference->shapeID=shapeID;
    
    theReference->lift=1;
    theReference->frameNumber=0;
    //theReference->currentFrame=currentFrame;
    theReference->GroundObject=YES;
    theReference->speed=speedForCharacterSprite(shapeID);
    
    //NSLog(@"The Speed: %i",theReference->speed);
    BAActor * theActor=[[BAActor alloc]init];
    [theActor setGlobalLocation:location];
    theActor->shapeReference=theReference;
    if(environment)
    {
       [theActor setEnvironment:environment];
       [theActor setMap:map];
    }
    
    //CGRect boundsRect=CGRectMake(sprite->globalLocation.x-40, sprite->globalLocation.y-40, 80, 80);
    CGRect boundsRect=CGRectMake(0,0, SUPERCHUNKSIZE*MAPSIZE*CHUNKSIZE, SUPERCHUNKSIZE*MAPSIZE*CHUNKSIZE);
    if(theActor->aiManager->actionManager)
    //if(0)
    {
        BAActionManager * manager=theActor->aiManager->actionManager;
        [manager setBounds:boundsRect];
        [manager setTargetLocation:[manager randomPointInDefinedBounds:CGRectMake(theActor->globalLocation.x-20, theActor->globalLocation.y-20, 50, 50)]];
        
        [manager setAction:IdleActionType forDirection:[manager DirectionTowardPoint:location toPoint:manager->targetGlobalLocation]forTarget:[manager randomPointInDefinedBounds:CGRectMake(theActor->globalLocation.x-20, theActor->globalLocation.y-20, 40, 40)]];
        
        [manager->currentAction setTargetDistanceTraveled:1];
        
        theActor->aiManager->AIEnabled=NO;
    }
    
    [map->actors addObject:theActor];
    return theActor;
}

-(void)addSpritesToMap
{
    for(int count=0;count<[map->actors count];count++)
    {
        BAActor * actor=[map->actors objectAtIndex:count];
        U7MapChunkCoordinate * coordinate=[environment MapChunkCoordinateForGlobalTilePosition:CGPointMake(actor->globalLocation.x, actor->globalLocation.y) ];
        U7MapChunk * mapChunk=[map mapChunkForLocation:[coordinate mapChunkCoordinate]];
        [mapChunk addSprite:actor atLocation:[coordinate getChunkTilePosition]];
        
    }
}
-(void)removeSpritesFromMap
{
    for(int count=0;count<[map->actors count];count++)
    {
        BAActor * actor=[map->actors objectAtIndex:count];
        U7MapChunkCoordinate * coordinate=[environment MapChunkCoordinateForGlobalTilePosition:CGPointMake(actor->globalLocation.x, actor->globalLocation.y) ];
        U7MapChunk * mapChunk=[map mapChunkForLocation:[coordinate mapChunkCoordinate]];
        [mapChunk removeSprite:actor];
        
    }
}

-(void)initWithChunkID:(int)chunkId
{
    [self removeSpritesFromMap];
    [map->map removeAllObjects];
    [map->actors removeAllObjects];
    [self invalidateAllChunkCaches]; // Clear all caches for new map
    
    map->mapWidth=SUPERCHUNKSIZE*MAPSIZE;
    map->mapHeight=SUPERCHUNKSIZE*MAPSIZE;
    for(int y=0;y<(SUPERCHUNKSIZE*MAPSIZE);y++)
    {
        for(int x=0;x<(SUPERCHUNKSIZE*MAPSIZE);x++)
        {
            U7MapChunk * mapChunk=[[U7MapChunk alloc]init];
            mapChunk->masterChunkID=chunkId;
            mapChunk->masterChunk=[u7Env chunkForID:chunkId];
            mapChunk->flatChunkID=(y*SUPERCHUNKSIZE*MAPSIZE)+x;
            mapChunk->highlited=NO;
            mapChunk->environment=u7Env;
            [map->map addObject:mapChunk];
        }
    }
}

-(void)updateMapChunksWithChunkID:(int)chunkID atPoint:(CGPoint)startPoint forWidth:(int)width forHeight:(int)height
{
    if((startPoint.x+width)>chunksWide)
    {
        NSLog(@"Too Wide");
        return;
    }
    if((startPoint.y+height)>chunksHigh)
    {
        NSLog(@"Too High");
        return;
    }
    if(startPoint.x<0||startPoint.y<0)
    {
        NSLog(@"Bad Start Point");
        return;
    }
    
    
    
    for(int y=0;y<height;y++)
    {
        for(int x=0;x<width;x++)
        {
            U7MapChunk * mapChunk=[map->map objectAtIndex:((y+startPoint.y)*SUPERCHUNKSIZE*MAPSIZE)+(x+startPoint.x)];
            mapChunk->masterChunkID=chunkID;
            mapChunk->masterChunk=[u7Env chunkForID:chunkID];
            [mapChunk setEnvironment:environment];
            if(environment)
            {
                [mapChunk updateShapeInfo:environment];
                [mapChunk createPassability];
                [mapChunk createEnvironmentMap];
            }
            // Invalidate cache for modified chunk
            [self invalidateChunkCache:mapChunk];
        }
    }
    
}


-(void)updateMapChunksWithChunkIDArray:(NSArray*)chunkIDArray atPoint:(CGPoint)startPoint forWidth:(int)width forHeight:(int)height
{
    if((startPoint.x+width)>chunksWide)
    {
        NSLog(@"Too Wide");
        return;
    }
    if((startPoint.y+height)>chunksHigh)
    {
        NSLog(@"Too High");
        return;
    }
    if(startPoint.x<0||startPoint.y<0)
    {
        NSLog(@"Bad Start Point");
        return;
    }
    
    if((height*width)>[chunkIDArray count])
    {
        NSLog(@"Too Big");
        return;
    }
    
    int index=0;
    
    for(int y=0;y<height;y++)
    {
        for(int x=0;x<width;x++)
        {
            
            //NSLog(@"index: %i has: %i at %i chunkswide: %i",index,[[chunkIDArray objectAtIndex:index]intValue],(y*SUPERCHUNKSIZE*MAPSIZE)+x,SUPERCHUNKSIZE*MAPSIZE);
            U7MapChunk * mapChunk=[map->map objectAtIndex:((y+startPoint.y)*SUPERCHUNKSIZE*MAPSIZE)+(x+startPoint.x)];
            NSString * chunkID=[chunkIDArray objectAtIndex:index];
            mapChunk->masterChunkID=[chunkID intValue];
            mapChunk->masterChunk=[u7Env chunkForID:[chunkID intValue]];
            [mapChunk setEnvironment:environment];
            if(environment)
            {
                [mapChunk updateShapeInfo:environment];
                [mapChunk createPassability];
                [mapChunk createEnvironmentMap];
            }
            // Invalidate cache for modified chunk
            [self invalidateChunkCache:mapChunk];
            index++;
        }
    }
    
}

-(void)addShape:(int)shapeID forFrame:(int)FrameID isAnimated:(BOOL)animated forLift:(int)height atLocation:(CGPoint)globalLocation
{
    U7MapChunkCoordinate * mapChunkCoordinate=[map MapChunkCoordinateForGlobalTilePosition:globalLocation];
    
  
    
    U7MapChunk *chunk= [map mapChunkAtIndex:[mapChunkCoordinate getMapChunk]];
    //U7MapChunk *chunk= [map mapChunkForLocation:CGPointMake(2,2)];
    //U7MapChunk *chunk= [map mapChunkForLocation:[mapChunkCoordinate chunkCoordinate]];
    U7Shape * shape=[u7Env->U7Shapes objectAtIndex:shapeID];
    U7ShapeReference * newReference=[[U7ShapeReference alloc]init];
    shape->animated=NO;
    newReference->shapeID=shapeID;
    newReference->parentChunkXCoord=[mapChunkCoordinate getChunkTilePosition].x;
    newReference->parentChunkYCoord=[mapChunkCoordinate getChunkTilePosition].y;
    newReference->lift=height;
    newReference->frameNumber=FrameID;
    newReference->currentFrame=FrameID;
    newReference->numberOfFrames=[shape numberOfFrames];
    newReference->animates=NO;
    newReference->parentChunkID=[mapChunkCoordinate getMapChunk];
    [chunk->gameItems addObject:newReference];
    [chunk createPassability];
    [chunk createEnvironmentMap];
    
    // Invalidate cache for this chunk since we added a shape
    [self invalidateChunkCache:chunk];
}

-(void)addLineOfShapes:(int)shapeID forFrame:(int)FrameID isAnimated:(BOOL)animated forLift:(int)lift startAt:(CGPoint)startPoint endAt:(CGPoint)endPoint
{
    U7Shape * shape=[u7Env->U7Shapes objectAtIndex:shapeID];
    NSLog(@"shape size %i %i",shape->TileSizeXMinus1,shape->TileSizeYMinus1);
    CGPointArray * pointArray=pointsOnLineWithSpacing(startPoint,endPoint,[shape tileSize]);
    [pointArray dump];
    for(int index=0;index<[pointArray count];index++)
    {
        CGPoint point=[pointArray pointAtIndex:index];
        [self addShape:shapeID forFrame:FrameID isAnimated:animated forLift:lift atLocation:point];
    }
}

-(void)addRectOfShape:(int)shapeID forFrame:(int)FrameID isAnimated:(BOOL)animated forLift:(int)lift startAt:(CGPoint)startPoint forSize:(CGSize)size
{
    U7Shape * shape=[u7Env->U7Shapes objectAtIndex:shapeID];
    NSLog(@"shape size %i %i",shape->TileSizeXMinus1,shape->TileSizeYMinus1);
    
    for(int y=0;y<size.height;y++)
    {
        for(int x=0;x<size.width;x++)
        {
            int xPos=startPoint.x+(x*(shape->TileSizeXMinus1+1));
            int yPos=startPoint.y+(y*(shape->TileSizeYMinus1+1));
        [self addShape:shapeID forFrame:FrameID isAnimated:animated forLift:lift atLocation:CGPointMake(xPos, yPos)];
        }
    }
}

-(void)addShapesFromPointArray:(CGPointArray*)pointArray forShape:(int)shapeID forFrame:(int)frameID isAnimated:(BOOL)animated forLift:(int)lift
{
    //U7Shape * shape=[u7Env->U7Shapes objectAtIndex:shapeID];
    //NSLog(@"shape size %i %i",shape->TileSizeXMinus1,shape->TileSizeYMinus1);
    
    //[pointArray dump];
    for(int index=0;index<[pointArray count];index++)
    {
        CGPoint point=[pointArray pointAtIndex:index];
        [self addShape:shapeID forFrame:frameID isAnimated:animated forLift:lift atLocation:point];
    }
}


-(NSArray*)findShapesWithID:(int)shapeID forFrame:(int)frameID
{
    NSArray * shapes=[map findShapesWithID:shapeID forFrame:frameID];
    return shapes;
}

-(CGPointArray*)shapeLocationsWithID:(int)shapeID forFrame:(int)frameID
{
    NSArray * shapes=[self findShapesWithID:shapeID forFrame:frameID];
    CGPointArray * pointArray=NULL;
    if(shapes)
    {
        //NSLog(@"%li shapes",[shapes count]);
        pointArray=[[CGPointArray alloc]init];
        for(long index=0;index<[shapes count];index++)
        {
            U7ShapeReference * shape=[shapes objectAtIndex:index];
            //logPoint([shape globalCoordinate], @"global");
            [pointArray addPoint:[shape globalCoordinate]];
            
        }
        return pointArray;
    }
 
    return NULL;
    
}


-(CGPoint)nearestShapeWithID:(int)shapeID forFrame:(int)frameID fromOrigin:(CGPoint)origin
{
   
    CGPointArray * pointArray=[self shapeLocationsWithID:shapeID forFrame:frameID];
    
    if(pointArray)
    {
        CGPoint thePoint=[pointArray nearestToCGPoint:origin];
        //logPoint(thePoint, @"return point");
        return thePoint;
    }
    return invalidLocation();
}

-(BASprite*)spriteAtLocation:(CGPoint)location ofResourceType:(enum BAResourceType)resourceType
{
    BASprite * theSprite=NULL;
    
    U7MapChunkCoordinate * coordinate=[environment MapChunkCoordinateForGlobalTilePosition:CGPointMake(location.x, location.y) ];
    
    U7MapChunk * mapChunk=[map mapChunkForLocation:[coordinate mapChunkCoordinate]];
    
    NSMutableArray * chunkSprites=mapChunk->sprites;
    if(![chunkSprites count])
        return NULL;
    for(long index=0;index<[chunkSprites count];index++)
    {
        BASprite * tempSprite=[chunkSprites objectAtIndex:index];
        if(tempSprite->resourceType==resourceType)
            theSprite=tempSprite;
    }
    
    return theSprite;
}


-(void)removeSpriteAtLocation:(CGPoint)location forSprite:(BASprite*)theSprite
{
    U7MapChunkCoordinate * coordinate=[environment MapChunkCoordinateForGlobalTilePosition:CGPointMake(location.x, location.y) ];
    
    U7MapChunk * mapChunk=[map mapChunkForLocation:[coordinate mapChunkCoordinate]];
    
    NSMutableArray * chunkSprites=mapChunk->sprites;
    
    if(![chunkSprites count])
        return ;
    [chunkSprites removeObject:theSprite];
    
}

-(void)updateSpawn
{
    //NSLog(@"updateSpawn");
    [triggeredSpawns removeAllObjects];
    for(long index=0;index<[spawns count];index++)
    {
        BASpawn * spawn=[spawns objectAtIndex:index];
        [spawn increaseFrequencyCounter];
        if([spawn isTriggered])
        {
            //[self handleSpawn:spawn];
            [triggeredSpawns addObject:spawn];
        }
        
    }
}

-(void)addSpawn:(BASpawn*)theSpawn
{
    if(theSpawn)
        [spawns addObject:theSpawn];
}

-(NSArray*)getTriggeredSpawns
{
    return triggeredSpawns;
}

-(CGPoint)chunkWithGrass
{
    CGPoint thePoint=[baseBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:CGSizeMake(1, 1)];
    return CGPointMake(thePoint.x+1, thePoint.y+1);
}

-(CGPoint)globalToViewLocation:(CGPoint)globalLocation
{
    //long chunkLocationX=((globalLocation.x/TOTALMAPSIZE)-startPoint.x)*CHUNKSIZE;
    //long chunkLocationY=((globalLocation.y/TOTALMAPSIZE)-startPoint.y)*CHUNKSIZE;
    long chunkLocationX=(globalLocation.x-(startPoint.x*CHUNKSIZE))*TILESIZE;
    long chunkLocationY=(globalLocation.y-(startPoint.y*CHUNKSIZE))*TILESIZE;
    CGPoint screenCoord=CGPointMake(chunkLocationX, chunkLocationY);
    //logPoint(screenCoord, @"ScreenCoord");
    return screenCoord;
}

@end
