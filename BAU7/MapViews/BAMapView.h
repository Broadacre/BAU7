//
//  BAU7View.h
//  BAU7View
//
//  Created by Dan Brooker on 8/24/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class CGPointArray;
@class BAActor;



@interface BASpawn : NSObject
{
    BOOL trigger;
    BOOL random;
    long frequency;
    enum BASpawnType spawnType;
    enum BAResourceType resourceType;
    
    long frequencyCounter;
    enum BAActorType actorType;
}
-(void)increaseFrequencyCounter;
-(BOOL)isTriggered;
-(void)setFrequency:(long)theFrequency;
-(enum BASpawnType)getSpawnType;
+(BASpawn*)ResourceSpawnOfType:(enum BAResourceType)theResourceType;
+(BASpawn*)NPCSpawnOfType:(enum BAActorType)theActorType;
-(enum BAResourceType)getResourceType;

@end

// Draw options bitmask for faster boolean checks
typedef NS_OPTIONS(NSUInteger, BADrawOptions) {
    BADrawOptionTiles           = 1 << 0,
    BADrawOptionGroundObjects   = 1 << 1,
    BADrawOptionStaticObjects   = 1 << 2,
    BADrawOptionGameObjects     = 1 << 3,
    BADrawOptionPassability     = 1 << 4,
    BADrawOptionTargetLocations = 1 << 5,
    BADrawOptionChunkHighlite   = 1 << 6,
    BADrawOptionShapeHighlite   = 1 << 7,
    BADrawOptionEnvironmentMap  = 1 << 8,
    BADrawOptionShapeIDs        = 1 << 9,
};

@interface BAMapView : UIView
{
    @public
    float mapScale;
    BOOL drawTiles;
    BOOL drawGroundObjects;
    BOOL drawGameObjects;
    BOOL drawStaticObjects;
    BOOL drawPassability;
    BOOL drawTargetLocations;
    BOOL drawChunkHighlite;
    BOOL drawShapeHighlite;
    BOOL drawEnvironmentMap;
    BOOL drawShapeIDs;
    int maxHeight;
    int chunksWide;
    int chunksHigh;
    
    unsigned int palletCycle;
    
    CGPoint startPoint;
    
    U7MapChunk * selectedChunk;
    U7Environment * environment;
    U7Map * map;
    
    //NSMutableArray * actors;
    NSArray * depthSortedShapes;
    
    NSMutableArray * selectedShapes;
    NSMutableArray * spawns;
    NSMutableArray * triggeredSpawns;
    
    //NSMutableArray * rectArray;  // for dungeon generation
    enum BAMapDrawMode drawMode;
    float miniMapScale;
    UIImage * miniMap;
    
    BAU7BitmapInterpreter * interpreter;
    
    
    BAActor * mainCharacter;
    
    
    BAIntBitmap * baseBitmap; 

    // Drag state
    BOOL _isDragging;
    CGPoint _dragStartLocation;
    CGPoint _dragCurrentLocation;
    NSMutableArray *_dragOriginalPositions;
}

// Optimization properties
@property (nonatomic, assign) BADrawOptions drawOptions;
@property (nonatomic, strong) NSMutableArray *shapeReferencePool;
@property (nonatomic, strong) NSMutableArray *reusableShapeArray;
@property (nonatomic, assign) NSInteger poolIndex;
@property (nonatomic, strong) NSMutableDictionary *chunkSortedShapesCache;
@property (nonatomic, strong) NSCache *imageCache;
@property (nonatomic, assign) BOOL useAsyncSorting;
@property (nonatomic, strong) dispatch_queue_t sortingQueue;

// Water animation properties
@property (nonatomic, strong) CADisplayLink *waterAnimationTimer;
@property (nonatomic, assign) NSInteger waterAnimationFrame;
@property (nonatomic, assign) NSTimeInterval lastWaterUpdateTime;
@property (nonatomic, assign) NSTimeInterval waterAnimationInterval; // seconds between frames
@property (nonatomic, assign) BOOL waterAnimationEnabled;
-(int)chunkwidth;
-(int)chunkheight;
-(void)selectChunkAtLocation:(CGPoint)location;
-(void)setChunkWidth:(int)theChunkWidth;
-(void)setChunkHeight:(int)theChunkHeight;
-(void)setStartPoint:(CGPoint)thePoint;
-(void)setMaxHeight:(int)theMaxHeight;
-(void)setPalletCycle:(int)thePalletCycle;
-(void)setDrawMode:(enum BAMapDrawMode)theDrawMode;
-(void)setMapScale:(float)theMapScale;
-(float)getMapScale;
-(float)getMaxMapScale;
-(float)getMinMapScale;

-(CGSize)contentSize;

-(void)drawChunkDepthSorted:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y;
-(void)drawShape:(U7ShapeReference*)theReference forFrame:(long)frame forX:(int)xPos forY:(int)yPos forZ:(int)zPos forPalletCycle:(int)palletCycle;
-(void)dirtyMap;
-(BAActor*)randomActor:(int)shapeID useRandomSprite:(BOOL)randomSprite forLocation:(CGPoint)location;
-(BAActor*)randomActor:(int)shapeID useRandomSprite:(BOOL)randomSprite forLocation:(CGPoint)location forTarget:(CGPoint)targetLocation;
-(void)drawPassability:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y;
-(void)removeSpritesFromMap;
-(void)initWithChunkID:(int)chunkId;


-(void)updateMapChunksWithChunkIDArray:(NSArray*)chunkIDArray atPoint:(CGPoint)startPoint forWidth:(int)width forHeight:(int)height;
-(void)updateMapChunksWithChunkID:(int)chunkID atPoint:(CGPoint)startPoint forWidth:(int)width forHeight:(int)height;
-(void)addShape:(int)shapeID forFrame:(int)FrameID isAnimated:(BOOL)animated forLift:(int)lift atLocation:(CGPoint)globalLocation;

-(void)addLineOfShapes:(int)shapeID forFrame:(int)FrameID isAnimated:(BOOL)animated forLift:(int)lift startAt:(CGPoint)startPoint endAt:(CGPoint)endPoint;
-(void)addRectOfShape:(int)shapeID forFrame:(int)FrameID isAnimated:(BOOL)animated forLift:(int)lift startAt:(CGPoint)startPoint forSize:(CGSize)size;

 -(void)addShapesFromPointArray:(CGPointArray*)pointArray forShape:(int)shapeID forFrame:(int)frameID isAnimated:(BOOL)animated forLift:(int)lift;



-(NSArray*)findShapesWithID:(int)shapeID forFrame:(int)frameID;
-(CGPointArray*)shapeLocationsWithID:(int)shapeID forFrame:(int)frameID;
-(CGPoint)nearestShapeWithID:(int)shapeID forFrame:(int)frameID fromOrigin:(CGPoint)origin;
-(BASprite*)spriteAtLocation:(CGPoint)location ofResourceType:(enum BAResourceType)resourceType;
-(void)removeSpriteAtLocation:(CGPoint)location forSprite:(BASprite*)theSprite;
//spawns
-(void)updateSpawn;
-(void)addSpawn:(BASpawn*)theSpawn;
-(NSArray*)getTriggeredSpawns;

-(void)generateMiniMap;
-(void)generateMap;

-(CGPoint)chunkWithGrass;

-(CGPoint)globalToViewLocation:(CGPoint)globalLocation;

// Optimization methods
-(void)initializeOptimizationStructures;
-(void)updateDrawOptionsFromFlags;
-(U7ShapeReference*)obtainPooledShapeReference;
-(void)resetShapeReferencePool;
-(void)invalidateChunkCache:(U7MapChunk*)mapChunk;
-(void)invalidateAllChunkCaches;
-(void)prepareForDrawingCycle;

// Water animation methods
-(void)startWaterAnimation;
-(void)stopWaterAnimation;
-(void)updateWaterAnimation:(CADisplayLink*)displayLink;
-(void)setWaterAnimationSpeed:(NSTimeInterval)interval;
-(NSInteger)waterCycleForPaletteRange:(int)paletteIndex;

// Shape selection methods
-(U7ShapeReference*)shapeAtViewLocation:(CGPoint)viewLocation;
-(NSArray*)shapesAtViewLocation:(CGPoint)viewLocation;
-(void)selectShape:(U7ShapeReference*)shape;
-(void)deselectShape:(U7ShapeReference*)shape;
-(void)deselectAllShapes;
-(void)toggleShapeSelectionAtViewLocation:(CGPoint)viewLocation;
-(NSArray*)getSelectedShapes;

// Shape manipulation methods
-(void)moveShape:(U7ShapeReference*)shape toGlobalTileLocation:(CGPoint)globalTile;
-(CGPoint)viewLocationToGlobalTile:(CGPoint)viewLocation;
-(CGPoint)viewLocationToGlobalTileForShape:(U7ShapeReference*)shape atViewLocation:(CGPoint)viewLocation;

// Shape dragging methods
-(BOOL)beginDragAtViewLocation:(CGPoint)viewLocation;
-(void)continueDragAtViewLocation:(CGPoint)viewLocation;
-(void)endDrag;
-(void)cancelDrag;
-(BOOL)isDragging;
-(CGRect)highlightRectForShape:(U7ShapeReference*)reference;

@end

NS_ASSUME_NONNULL_END
