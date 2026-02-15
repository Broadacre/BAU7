//
//  BAU7Objects.h
//  BAU7Objects
//
//  Created by Dan Brooker on 8/24/21.
//

#import <Foundation/Foundation.h>

#import <UIKit/UIKit.h>
#import "enums.h"
NS_ASSUME_NONNULL_BEGIN

#define OFFSET 128
#define TILEOFFSET 8320
#define TILEEND 10048
#define AVATARIMAGE 721
//#define TESTSHAPE 178
//#define TESTSHAPE AVATARIMAGE
#define TESTSHAPE 159
//#define NUMBEROFTILES (TILEEND-TILEOFFSET)/16
#define NUMBEROFTILES 5000
#define PALLETINDEXVALUE 256+PALLETINDEX*768
#define PALLETINDEX 0

#define TILEPIXELSIZE 1
#define TILEPIXELSCALE 1
#define TILEPIXELSIZESCALED TILEPIXELSIZE*TILEPIXELSCALE
#define TILESIZE 8
#define CHUNKSIZE 16
#define CHUNKPIXELS TILESIZE*TILEPIXELSIZE*CHUNKSIZE

#define SUPERCHUNKSIZE  16
#define MAPSIZE 12
#define TOTALMAPSIZE SUPERCHUNKSIZE*MAPSIZE
#define HEIGHTOFFSET 4





@class BABooleanBitmap;
@class BAActor;

@interface U7AnimationSequence: NSObject <NSSecureCoding>
{
@public
    BOOL infinite;
    enum AnimationSequenceType type;
    BOOL RotateRight;
    BOOL RotateLeft;
    BOOL Mirrored;
    NSMutableArray * animationSequence;
}
-(long)numberOfFrames;
-(long)frameForStep:(long)step;
-(void)dump;
@end



@interface U7MapChunkCoordinate: NSObject
{
    //position within the chunk
    CGPoint chunkTilePosition;
    //index of the chunk
    long mapChunkIndex;
}
-(void)setChunkTilePosition:(CGPoint)theChunkTilePosition;
-(void)setMapChunkID:(long)theID;
-(CGPoint)GlobalPixelCoordinate;
-(CGPoint)GlobalTileCoordinate;
-(CGPoint)getChunkTilePosition;
-(CGPoint)mapChunkCoordinate;
-(long)getMapChunk;
-(void)dump;
@end

@interface U7Color: NSObject <NSSecureCoding>
{
    @public
    float red;
    float green;
    float blue;
    float alpha;
}
-(UIColor*)UIColorForU7Color;
-(float)redValue;
-(float)greenValue;
-(float)blueValue;
-(float)alphaValue;


@end

@interface U7Palette : NSObject <NSSecureCoding>
{
    @public
    NSMutableArray * colors;
}

@end
@interface U7Shape : NSObject <NSSecureCoding>
{@public
    BOOL tile;
    
    //shape info
    BOOL rotatable;
    BOOL animated;
    BOOL notWalkable;
    BOOL water;
    UInt8 tileSizeZ;
    int shapeType;
    BOOL trap;
    BOOL door;
    BOOL vehiclePart;
    BOOL selectable;
    int TileSizeXMinus1;
    int TileSizeYMinus1;
    BOOL lightSource;
    BOOL translucent;
    
    
    int numberOfFrames;
    NSMutableArray * frames;
}
-(CGSize)sizeForFrame:(int)frameNumber;
-(CGSize)tileSize;
-(void)dumpFrame:(int)frameIndex;
-(long)numberOfFrames;
@end

@interface U7ShapeReference : NSObject <NSSecureCoding>
{
    @public
    BOOL GameObject;  //debug
    BOOL StaticObject;  //debug
    BOOL GroundObject;  //debug
    long shapeID;
    int frameNumber;
    
    long parentChunkID;
    int parentChunkXCoord;
    int parentChunkYCoord;
    int xloc;
    int yloc;
    int lift;
    
    float eulerRotation;
    int speed;
    int depth;
    
    BOOL animates;
    long numberOfFrames;
    long currentFrame;
    
    float maxY;
    float maxX;//tactical during drawChunk
    float maxZ;//tactical during drawChunk
    
    // Container tracking
    BOOL isContainer;          // YES if this object is a container (type 12)
    BOOL isContainerContent;   // YES if this object was inside a container
    long containerShapeRef;    // Reference to parent container (if isContainerContent == YES)
}
-(void)incrementCurrentFrame;
-(CGPoint)globalCoordinate;
-(CGRect)originRect;
-(NSString *)exportToXML;
@end

@interface BAContainerObject : NSObject <NSSecureCoding>
{
    @public
    U7ShapeReference *containerShape;  // The container itself (chest, barrel, etc)
    NSMutableArray *contents;          // Array of U7ShapeReference objects inside
    BOOL isEmpty;                      // YES if container has no contents
}
-(instancetype)initWithContainer:(U7ShapeReference*)container;
-(void)addContent:(U7ShapeReference*)content;
-(NSInteger)contentCount;
@end



@interface U7ShapeRecord : NSObject <NSCopying, NSSecureCoding>

{
@public
    @public
    BOOL tile;
    int flatLocation;
    UInt32 length;
    UInt32 offset;
}
-(void)dump;
@end

@interface U7Bitmap : NSObject <NSSecureCoding>
{
@public
    int width;
    int height;
    
    UInt16 rightX;
    UInt16 leftX;
    UInt16 topY;
    UInt16 bottomY;
    
    BOOL useTransparency;
    
    int palletCycles;
    NSMutableArray * bitmaps; // multiple versions for pallet cycle
    //NSMutableArray * bitmap;
    UIImage * image;
    NSMutableArray * images;
    //CGImageRef CGImage;
    NSMutableArray * CGImages;
}
-(int)translateX:(int)offset;
-(int)translateY:(int)offset;
-(int)reverseTranslateX;
-(int)reverseTranslateY;
-(void)dump;

@end


@interface U7ChunkIndex: NSObject <NSSecureCoding>
{
    @public
    long shapeIndex;
    int frameIndex;
}
@end

@class U7Environment;
@class BASprite;
@class BAEnvironmentMap;

@interface U7Chunk : NSObject <NSSecureCoding>
{
    @public
    U7Environment * environment;
    NSMutableArray * chunkMap;
    UIImage * tileImage;
    NSMutableArray * tileImages; // Array of UIImages for palette cycling (water animation)
    BOOL hasAnimatedTiles;       // YES if this chunk contains water/animated tiles
}

-(void)setEnvironment:(U7Environment*)theEnvironment;
-(void)createTileImage;
-(void)createAnimatedTileImages;
-(UIImage*)tileImageForAnimationFrame:(NSInteger)frame;
@end
@interface U7MapChunk : NSObject <NSCopying, NSSecureCoding>
{
    @public
    BOOL animates;
    BOOL dirty;
    BOOL highlited;
    int masterChunkID;
    int flatChunkID;
    U7Chunk * masterChunk;
    NSMutableArray * staticItems;
    NSMutableArray * gameItems;
    NSMutableArray * sprites;
    NSMutableArray * groundObjects;
    NSMutableArray * containers;  // Array of BAContainerObject - tracks container relationships
    
    //NSMutableArray * passabilityBitMap;
    BABooleanBitmap * passabilityBBitMap;
    BAEnvironmentMap * environmentMap;
    
    U7Environment * environment;
}
-(void)setEnvironment:(U7Environment*)theEnvironment;
-(void)createEnvironmentMap;
-(void)createPassability;
-(U7ShapeReference*)staticShapeForLocation:(CGPoint)location forHeight:(int)height;
-(U7ShapeReference*)gameShapeForLocation:(CGPoint)location forHeight:(int)height;
-(U7ShapeReference*)groundShapeForLocation:(CGPoint)location forHeight:(int)height;
-(U7MapChunk*)mapChunkAtIndex:(long)index;
-(void)updateShapeInfo:(U7Environment*)env;
-(void)dump;
-(void)addSprite:(BASprite*)theSprite atLocation:(CGPoint)location;
-(void)removeSprite:(BASprite*)theSprite;
-(void)removeAllSprites;
-(void)removeAllObjects;
-(BOOL)passabilityForLocation:(CGPoint)location atHeight:(int)height;
-(NSArray*)findShapesWithID:(int)shapeID forFrame:(int)frameID;
-(enum BAEnvironmentType)environmentTypeAtLocation:(CGPoint)localLocation;

@end

@interface U7Map : NSObject <NSSecureCoding>
{
    @public
    long mapWidth;  //in chunks
    long mapHeight; //in chunks
    long chunkSize;  //in tiles
    long tileSize;  //in pixels
    NSMutableArray * map;  //of u7MapChunks
    NSMutableArray * actors;
    U7Environment * environment;
}
-(U7Shape*)tileShapeAtGlobalTilePosition:(CGPoint)thePosition;
-(void)replaceChunkAtIndex:(long)index withChunk:(U7MapChunk*)theChunk;
-(U7MapChunk*)mapChunkForLocation:(CGPoint)theLocation;
-(U7MapChunk*)mapChunkAtIndex:(long)index;
-(U7MapChunkCoordinate*)MapChunkCoordinateForGlobalTilePosition:(CGPoint)thePosition;
-(long)chunkIDForGlobalTileCoordinate:(CGPoint)coordinate;
-(long)chunkIDForChunkCoordinate:(CGPoint)coordinate;
-(int)isPassable:(CGPoint)theLocation;
-(BOOL)validMapPosition:(CGPoint)position;
- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord;
-(CGPoint)nearestPassableAdjacentTile:(CGPoint)destination from:(CGPoint)origin;

-(NSArray *)findShapesWithID:(int)shapeID forFrame:(int)frameID;

-(BASprite*)spriteAtLocation:(CGPoint)globalLocation ofResourceType:(enum BAResourceType)resourceType;
-(BAActor*)actorAtLocation:(CGPoint)globalLocation ofActorType:(enum BAActorType)actorType;
-(void)removeActorAtLocation:(CGPoint)location forActor:(BAActor*)theActor;
-(void)removeSpriteAtLocation:(CGPoint)location forSprite:(BASprite*)theSprite;
-(void)removeAllSprites;
-(void)createPassabilityMaps;
-(void)createEnvironmentMaps;
-(enum BAEnvironmentType)environmentTypeForLocation:(CGPoint)globalLocation;
@end

@interface U7Environment : NSObject <NSSecureCoding>
{
    @public
        
    //pallets
    U7Palette * pallet;
    U7Palette * transparencyPallet;
    
    //Shape Records
    NSMutableArray * shapeRecords;
    NSMutableArray * spriteShapeRecords;
    NSMutableArray * faceShapeRecords;
    NSMutableArray * gumpShapeRecords;
    NSMutableArray * fontShapeRecords;
    
    //Shapes
    NSMutableArray * U7Shapes;
    NSMutableArray * U7FaceShapes;
    NSMutableArray * U7SpriteShapes;
    NSMutableArray * U7GumpShapes;
    NSMutableArray * U7FontShapes;
    
    //These are part of the map
    U7Map * Map;
    NSMutableArray * U7Chunks;
    NSMutableArray * staticShapeRecords;
    NSMutableArray * gameShapeRecords;
    
    //Animation
    NSMutableArray * animationSequences;
    
    //Precomputed palette colors for faster image creation
    uint32_t *precomputedPaletteRGBA;
    uint32_t *precomputedTransparencyPaletteRGBA;
    
    
}

// Cache management
+(NSString*)cacheFilePath;
+(NSString*)cacheVersion;
+(BOOL)cacheExists;
+(void)clearCache;
-(BOOL)saveToCache;
+(nullable U7Environment*)loadFromCache;
-(void)fixShapeFrameCountsForMapChunk:(U7MapChunk*)mapChunk;

-(enum BAEnvironmentType)environmentTypeForShapeID:(long)theShapeID;
-(U7Chunk*)chunkForID:(int)theID;
-(U7MapChunk*)mapChunkForLocation:(CGPoint)theLocation;
-(long)numberOfRawChunks;
-(long)numberOfMapChunks;
-(long)numberOfShapes;
-(UInt16)chunkIDForMapAddress:(NSData *)data forChunkX:(int)x forChunkY:(int)y;
-(NSArray*)shapeReferencesForChunk:(NSData*)data forShapeRecord:(U7ShapeRecord*)record;
-(U7MapChunkCoordinate*)MapChunkCoordinateForGlobalTilePosition:(CGPoint)thePosition;
-(NSMutableArray*)composeAnimationSequences;
-(U7AnimationSequence*)sequenceForType:(enum AnimationSequenceType)type;
-(unsigned char)cyclePixel:(unsigned char)pixel forCycle:(int)cycle forMaxCycles:(int)maxCycles forBitmap:(U7Bitmap*)bitmap;
-(void)processContainerRelationships;  // Process all chunks to identify container contents

// Utility methods for reading data
-(SInt16)getSInt16FromNSData:(NSData *)data atByteOffset:(long)offset;
-(UInt16)getUint16FromNSData:(NSData *)data atByteOffset:(long)offset;
-(UInt32)getUint32FromNSData:(NSData *)data atByteOffset:(UInt32)offset;
-(UInt8)getUint8FromNSData:(NSData *)data atByteOffset:(long)offset;
-(unsigned char)getCharFromNSData:(NSData *)data atByteOffset:(long)offset;

@end

NS_ASSUME_NONNULL_END
