//
//  BAU7Objects.m
//  BAU7Objects
//
//  Created by Dan Brooker on 8/24/21.
//
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreGraphics/CGGeometry.h>
#import "BABitmap.h"
#import "CGPointUtilities.h"
#import "BAU7Objects.h"
#import "BASpriteAction.h"
#import "BAActionManager.h"
#import "BASprite.h"
#import "BAEnvironmentMap.h"

@implementation U7AnimationSequence

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    animationSequence=[[NSMutableArray alloc]init];
    infinite=YES;
    RotateRight=NO;
    RotateLeft=NO;
    type=IdleSouthAnimationSequenceType;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:infinite forKey:@"infinite"];
    [coder encodeInt:(int)type forKey:@"type"];
    [coder encodeBool:RotateRight forKey:@"RotateRight"];
    [coder encodeBool:RotateLeft forKey:@"RotateLeft"];
    [coder encodeBool:Mirrored forKey:@"Mirrored"];
    [coder encodeObject:animationSequence forKey:@"animationSequence"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        infinite = [coder decodeBoolForKey:@"infinite"];
        type = (enum AnimationSequenceType)[coder decodeIntForKey:@"type"];
        RotateRight = [coder decodeBoolForKey:@"RotateRight"];
        RotateLeft = [coder decodeBoolForKey:@"RotateLeft"];
        Mirrored = [coder decodeBoolForKey:@"Mirrored"];
        animationSequence = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [NSNumber class], nil] forKey:@"animationSequence"] mutableCopy];
    }
    return self;
}
-(void)addFrame:(int)frameNumber
{
    NSNumber * number=[NSNumber numberWithInt:frameNumber];
    [animationSequence addObject:number];
}
-(long)numberOfFrames
{
    return [animationSequence count];
}
-(long)frameForStep:(long)step
{
    long index=0;
    //if(step>[self numberOfFrames]-1)
    //    return 0;
    
    if(infinite)
    {
        index=step%[self numberOfFrames];
    }
    else
    {
        //NSLog(@"step: %li divided:%li",step,(step/[self numberOfFrames]));
        if((step/[self numberOfFrames]))
        {
            
            index=[self numberOfFrames]-1;
        }
        else
            index=step%[self numberOfFrames];
    }
        
    return [[animationSequence objectAtIndex:index]intValue];
}
-(void)dump
{
    NSLog(@"U7AnimationSequence Dump");
    NSLog(@"type:%i",type);
    NSLog(@"RotateRight:%i",RotateRight);
    NSLog(@"RotateLeft:%i",RotateLeft);
    NSLog(@"Mirrored:%i",Mirrored);
    NSLog(@"numberOfFrames:%li",[self numberOfFrames]);
    for(int count=0;count<[animationSequence count];count++)
    {
        NSNumber * number=[animationSequence objectAtIndex:count];
        NSLog(@"Frame: %i",[number intValue]);
    }
}
@end



@implementation U7MapChunkCoordinate
-(id)init
{
    self=[super init];
    chunkTilePosition=CGPointMake(0.0, 0.0);  //from 0-15
    mapChunkIndex=0;
    return self;
}
-(void)setChunkTilePosition:(CGPoint)theChunkTilePosition
{
    chunkTilePosition=theChunkTilePosition;
}

-(void)setMapChunkID:(long)theID
{
    mapChunkIndex=theID;
}

-(CGPoint)GlobalPixelCoordinate
{
    CGPoint globalCoordinate=[self GlobalTileCoordinate];
    globalCoordinate.x=globalCoordinate.x*TILESIZE;
    globalCoordinate.y=globalCoordinate.y*TILESIZE;
    
    return globalCoordinate;
}

-(CGPoint)GlobalTileCoordinate
{
    long total=TOTALMAPSIZE;
    long chunkYPos=mapChunkIndex/total;
    //NSLog(@"Chunky:%li mapindex:%li Total %i",chunkYPos,mapChunkIndex,TOTALMAPSIZE);
    long chunkXPos=mapChunkIndex-(chunkYPos*TOTALMAPSIZE);
    long xpos=(chunkXPos*CHUNKSIZE)+chunkTilePosition.x;
    long ypos=(chunkYPos*CHUNKSIZE)+chunkTilePosition.y;
    //NSLog(@"chunk: %li,%li,GlobalTileCoordinate:%li,%li",chunkYPos,chunkXPos, xpos,ypos);
    return CGPointMake(xpos, ypos);
}
-(CGPoint)mapChunkCoordinate
{
    long total=TOTALMAPSIZE;
    long chunkYPos=mapChunkIndex/total;
    //NSLog(@"Chunky:%li mapindex:%li Total %i",chunkYPos,mapChunkIndex,TOTALMAPSIZE);
    long chunkXPos=mapChunkIndex-(chunkYPos*TOTALMAPSIZE);
    return CGPointMake(chunkXPos, chunkYPos);
}
-(CGPoint)getChunkTilePosition
{
    return chunkTilePosition;
}

-(long)getMapChunk
{
    return mapChunkIndex;
}

-(void)dump
{
    NSLog(@"Position:%f,%f Chunk:%li",chunkTilePosition.x,chunkTilePosition.y,mapChunkIndex);
}

@end
@implementation U7Color

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    red=0.0;
    green=0.0;
    blue=0.0;
    alpha=1.0;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeFloat:red forKey:@"red"];
    [coder encodeFloat:green forKey:@"green"];
    [coder encodeFloat:blue forKey:@"blue"];
    [coder encodeFloat:alpha forKey:@"alpha"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        red = [coder decodeFloatForKey:@"red"];
        green = [coder decodeFloatForKey:@"green"];
        blue = [coder decodeFloatForKey:@"blue"];
        alpha = [coder decodeFloatForKey:@"alpha"];
    }
    return self;
}
#define COLORLENGTH 63
-(UIColor*)UIColorForU7Color
{
    return ([UIColor colorWithRed:red/COLORLENGTH green:green/COLORLENGTH blue:blue/COLORLENGTH alpha:alpha]);
}
-(float)redValue
{
    return red/COLORLENGTH;
}
-(float)greenValue
{
    return green/COLORLENGTH;
}
-(float)blueValue
{
    return blue/COLORLENGTH;
}
-(float)alphaValue
{
    return (alpha);
}
@end

@implementation U7Palette

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    colors=[[NSMutableArray alloc]init];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:colors forKey:@"colors"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        colors = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Color class], nil] forKey:@"colors"] mutableCopy];
    }
    return self;
}


@end

@implementation U7Shape

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    tile=NO;
    
    rotatable=NO;
    animated=NO;
    notWalkable=NO;
    water=NO;
    tileSizeZ=0;
    shapeType=0;
    trap=NO;
    door=NO;
    vehiclePart=NO;
    selectable=NO;
    TileSizeXMinus1=0;
    TileSizeYMinus1=0;
    lightSource=NO;
    translucent=NO;
    
    numberOfFrames=0;
    frames=[[NSMutableArray alloc]init];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:tile forKey:@"tile"];
    [coder encodeBool:rotatable forKey:@"rotatable"];
    [coder encodeBool:animated forKey:@"animated"];
    [coder encodeBool:notWalkable forKey:@"notWalkable"];
    [coder encodeBool:water forKey:@"water"];
    [coder encodeInt:tileSizeZ forKey:@"tileSizeZ"];
    [coder encodeInt:shapeType forKey:@"shapeType"];
    [coder encodeBool:trap forKey:@"trap"];
    [coder encodeBool:door forKey:@"door"];
    [coder encodeBool:vehiclePart forKey:@"vehiclePart"];
    [coder encodeBool:selectable forKey:@"selectable"];
    [coder encodeInt:TileSizeXMinus1 forKey:@"TileSizeXMinus1"];
    [coder encodeInt:TileSizeYMinus1 forKey:@"TileSizeYMinus1"];
    [coder encodeBool:lightSource forKey:@"lightSource"];
    [coder encodeBool:translucent forKey:@"translucent"];
    [coder encodeInt:numberOfFrames forKey:@"numberOfFrames"];
    [coder encodeObject:frames forKey:@"frames"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        tile = [coder decodeBoolForKey:@"tile"];
        rotatable = [coder decodeBoolForKey:@"rotatable"];
        animated = [coder decodeBoolForKey:@"animated"];
        notWalkable = [coder decodeBoolForKey:@"notWalkable"];
        water = [coder decodeBoolForKey:@"water"];
        tileSizeZ = [coder decodeIntForKey:@"tileSizeZ"];
        shapeType = [coder decodeIntForKey:@"shapeType"];
        trap = [coder decodeBoolForKey:@"trap"];
        door = [coder decodeBoolForKey:@"door"];
        vehiclePart = [coder decodeBoolForKey:@"vehiclePart"];
        selectable = [coder decodeBoolForKey:@"selectable"];
        TileSizeXMinus1 = [coder decodeIntForKey:@"TileSizeXMinus1"];
        TileSizeYMinus1 = [coder decodeIntForKey:@"TileSizeYMinus1"];
        lightSource = [coder decodeBoolForKey:@"lightSource"];
        translucent = [coder decodeBoolForKey:@"translucent"];
        numberOfFrames = [coder decodeIntForKey:@"numberOfFrames"];
        frames = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Bitmap class], nil] forKey:@"frames"] mutableCopy];
    }
    return self;
}
-(void)dumpFrame:(int)frameIndex
{
    U7Bitmap * bitmap=[frames objectAtIndex:frameIndex];
    if(bitmap)
       [bitmap dump];
}
-(CGSize)sizeForFrame:(int)frameNumber
{
    CGSize theSize=CGSizeMake(0, 0);
    U7Bitmap * bitmap=[frames objectAtIndex:frameNumber];
    if(bitmap)
        theSize=CGSizeMake(bitmap->width, bitmap->height);
    else NSLog(@"Bad Bitmap");
    return theSize;
}


-(CGSize)tileSize
{
    return CGSizeMake(TileSizeXMinus1+1, TileSizeYMinus1+1);
}

-(long)numberOfFrames
{
    if(frames)
    {
        long value= [frames count];
        return value;
    }
    return 0;
}

-(void)dump
{
    NSLog(@"Tile:%i",tile);
    NSLog(@"rotatable:%i",rotatable);
    NSLog(@"animated:%i",animated);
    NSLog(@"notWalkable:%i",notWalkable);
    NSLog(@"water:%i",water);
    NSLog(@"tileSizeZ:%i",tileSizeZ);
    NSLog(@"shapeType:%i",shapeType);
    NSLog(@"trap:%i",trap);
    NSLog(@"door:%i",door);
    NSLog(@"vehiclePart:%i",vehiclePart);
    NSLog(@"selectable:%i",selectable);
    NSLog(@"TileSizeXMinus1:%i",TileSizeXMinus1);
    NSLog(@"TileSizeYMinus1:%i",TileSizeYMinus1);
    NSLog(@"lightSource:%i",lightSource);
    NSLog(@"translucent:%i",translucent);
    NSLog(@"numberOfFrames:%i",numberOfFrames);
}

@end

@implementation U7ShapeReference

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    shapeID=-1;
    frameNumber=-1;
    parentChunkID=-1;
    parentChunkXCoord=-1;
    parentChunkYCoord=-1;
    lift=-1;
    speed=1;
    
    animates=NO;
    numberOfFrames=0;
    currentFrame=0;
    
    GameObject=NO;
    
    
    StaticObject=NO;  //debug
    GroundObject=NO;  //debug
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:GameObject forKey:@"GameObject"];
    [coder encodeBool:StaticObject forKey:@"StaticObject"];
    [coder encodeBool:GroundObject forKey:@"GroundObject"];
    [coder encodeInt64:shapeID forKey:@"shapeID"];
    [coder encodeInt:frameNumber forKey:@"frameNumber"];
    [coder encodeInt64:parentChunkID forKey:@"parentChunkID"];
    [coder encodeInt:parentChunkXCoord forKey:@"parentChunkXCoord"];
    [coder encodeInt:parentChunkYCoord forKey:@"parentChunkYCoord"];
    [coder encodeInt:xloc forKey:@"xloc"];
    [coder encodeInt:yloc forKey:@"yloc"];
    [coder encodeInt:lift forKey:@"lift"];
    [coder encodeFloat:eulerRotation forKey:@"eulerRotation"];
    [coder encodeInt:speed forKey:@"speed"];
    [coder encodeInt:depth forKey:@"depth"];
    [coder encodeBool:animates forKey:@"animates"];
    [coder encodeInt64:numberOfFrames forKey:@"numberOfFrames"];
    [coder encodeInt64:currentFrame forKey:@"currentFrame"];
    [coder encodeFloat:maxY forKey:@"maxY"];
    [coder encodeFloat:maxX forKey:@"maxX"];
    [coder encodeFloat:maxZ forKey:@"maxZ"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        GameObject = [coder decodeBoolForKey:@"GameObject"];
        StaticObject = [coder decodeBoolForKey:@"StaticObject"];
        GroundObject = [coder decodeBoolForKey:@"GroundObject"];
        shapeID = [coder decodeInt64ForKey:@"shapeID"];
        frameNumber = [coder decodeIntForKey:@"frameNumber"];
        parentChunkID = [coder decodeInt64ForKey:@"parentChunkID"];
        parentChunkXCoord = [coder decodeIntForKey:@"parentChunkXCoord"];
        parentChunkYCoord = [coder decodeIntForKey:@"parentChunkYCoord"];
        xloc = [coder decodeIntForKey:@"xloc"];
        yloc = [coder decodeIntForKey:@"yloc"];
        lift = [coder decodeIntForKey:@"lift"];
        eulerRotation = [coder decodeFloatForKey:@"eulerRotation"];
        speed = [coder decodeIntForKey:@"speed"];
        depth = [coder decodeIntForKey:@"depth"];
        animates = [coder decodeBoolForKey:@"animates"];
        numberOfFrames = [coder decodeInt64ForKey:@"numberOfFrames"];
        currentFrame = [coder decodeInt64ForKey:@"currentFrame"];
        
        // Validate currentFrame against numberOfFrames from cache
        // This prevents issues if cached data has inconsistencies
        if (numberOfFrames > 0 && currentFrame >= numberOfFrames) {
            currentFrame = 0;
        }
        
        maxY = [coder decodeFloatForKey:@"maxY"];
        maxX = [coder decodeFloatForKey:@"maxX"];
        maxZ = [coder decodeFloatForKey:@"maxZ"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    U7ShapeReference*  copy = [[U7ShapeReference alloc] init];

    if (copy) {
        // Copy NSObject subclasses
        copy->shapeID=shapeID;
        copy->frameNumber=frameNumber;
        copy->parentChunkXCoord=parentChunkXCoord;
        copy->parentChunkYCoord=parentChunkYCoord;
        copy->lift=lift;
        copy->speed=speed;
        
        copy->animates=animates;
        copy->numberOfFrames=numberOfFrames;
        copy->currentFrame=currentFrame;
        
        copy->GameObject=GameObject;
        
        
        copy->StaticObject=StaticObject;  //debug
        copy->GroundObject=GroundObject;  //debug
        
    }

    return copy;
}

-(void)dump
{
    NSLog(@"shapeID: %li  frameNumber: %i chunkXCoord: %i parentChunkYCoord: %i lift: %i",shapeID,frameNumber,parentChunkXCoord,parentChunkYCoord,lift);
}


-(void)incrementCurrentFrame
{
    if(animates)
    {
        //NSLog(@"incrementCurrentFrame");
        // Use numberOfFrames-1 as max, but also ensure it's positive
        // This prevents issues if numberOfFrames is incorrectly set
        long maxFrame = (numberOfFrames > 0) ? (numberOfFrames - 1) : 0;
        
        if(currentFrame < maxFrame)
            currentFrame++;
        else
            currentFrame=0;
    }
    
}


-(CGPoint)globalCoordinate
{
    U7MapChunkCoordinate * coordinate=[[U7MapChunkCoordinate alloc]init];
    [coordinate setChunkTilePosition:CGPointMake(parentChunkXCoord, parentChunkYCoord)];
    [coordinate setMapChunkID:parentChunkID];
    return [coordinate GlobalTileCoordinate];
}


-(CGRect)originRect
{
    
    return CGRectMake([self globalCoordinate].x*TILESIZE, [self globalCoordinate].y*TILESIZE, TILESIZE, TILESIZE);
}

// Method to export the U7ShapeReference instance to XML
- (NSString *)exportToXML {
    NSMutableString *xmlString = [NSMutableString string];
    [xmlString appendString:@"<U7ShapeReference>\n"];
    [xmlString appendFormat:@"  <GameObject>%@</GameObject>\n", self->GameObject ? @"true" : @"false"];
    [xmlString appendFormat:@"  <StaticObject>%@</StaticObject>\n", self->StaticObject ? @"true" : @"false"];
    [xmlString appendFormat:@"  <GroundObject>%@</GroundObject>\n", self->GroundObject ? @"true" : @"false"];
    [xmlString appendFormat:@"  <shapeID>%ld</shapeID>\n", self->shapeID];
    [xmlString appendFormat:@"  <frameNumber>%d</frameNumber>\n", self->frameNumber];
    [xmlString appendFormat:@"  <parentChunkID>%ld</parentChunkID>\n", self->parentChunkID];
    [xmlString appendFormat:@"  <parentChunkXCoord>%d</parentChunkXCoord>\n", self->parentChunkXCoord];
    [xmlString appendFormat:@"  <parentChunkYCoord>%d</parentChunkYCoord>\n", self->parentChunkYCoord];
    [xmlString appendFormat:@"  <xloc>%d</xloc>\n", self->xloc];
    [xmlString appendFormat:@"  <yloc>%d</yloc>\n", self->yloc];
    [xmlString appendFormat:@"  <lift>%d</lift>\n", self->lift];
    [xmlString appendFormat:@"  <eulerRotation>%f</eulerRotation>\n", self->eulerRotation];
    [xmlString appendFormat:@"  <speed>%d</speed>\n", self->speed];
    [xmlString appendFormat:@"  <depth>%d</depth>\n", self->depth];
    [xmlString appendFormat:@"  <animates>%@</animates>\n", self->animates ? @"true" : @"false"];
    [xmlString appendFormat:@"  <numberOfFrames>%ld</numberOfFrames>\n", self->numberOfFrames];
    [xmlString appendFormat:@"  <currentFrame>%ld</currentFrame>\n", self->currentFrame];
    [xmlString appendFormat:@"  <maxY>%f</maxY>\n", self->maxY];
    [xmlString appendFormat:@"  <maxX>%f</maxX>\n", self->maxX];
    [xmlString appendFormat:@"  <maxZ>%f</maxZ>\n", self->maxZ];
    [xmlString appendString:@"</U7ShapeReference>"];
    
    return xmlString;
}


@end


@implementation U7ShapeRecord

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    tile=NO;
    length=0;
    offset=0;
    flatLocation=0;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:tile forKey:@"tile"];
    [coder encodeInt:flatLocation forKey:@"flatLocation"];
    [coder encodeInt32:length forKey:@"length"];
    [coder encodeInt32:offset forKey:@"offset"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        tile = [coder decodeBoolForKey:@"tile"];
        flatLocation = [coder decodeIntForKey:@"flatLocation"];
        length = [coder decodeInt32ForKey:@"length"];
        offset = [coder decodeInt32ForKey:@"offset"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    U7ShapeRecord *copy = [[U7ShapeRecord alloc] init];
    if (copy) {
        copy->tile = tile;
        copy->flatLocation = flatLocation;
        copy->length = length;
        copy->offset = offset;
    }
    return copy;
}

-(void)dump
{
    NSLog(@"Offset: %u  length: %u isTile: %i",offset,length,tile);
}
@end

@implementation U7Bitmap

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    width=0;
    height=0;
    rightX=0;
    leftX=0;
    topY=0;
    bottomY=0;
    
    palletCycles=0;
    useTransparency=NO;
    
    bitmaps=[[NSMutableArray alloc]init];
    images=[[NSMutableArray alloc]init];
    CGImages=[[NSMutableArray alloc]init];
    //bitmap=[[NSMutableArray alloc]init];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt:width forKey:@"width"];
    [coder encodeInt:height forKey:@"height"];
    [coder encodeInt:rightX forKey:@"rightX"];
    [coder encodeInt:leftX forKey:@"leftX"];
    [coder encodeInt:topY forKey:@"topY"];
    [coder encodeInt:bottomY forKey:@"bottomY"];
    [coder encodeInt:palletCycles forKey:@"palletCycles"];
    [coder encodeBool:useTransparency forKey:@"useTransparency"];
    [coder encodeObject:bitmaps forKey:@"bitmaps"];
    
    // Encode main image as PNG data
    if (image) {
        NSData *imageData = UIImagePNGRepresentation(image);
        [coder encodeObject:imageData forKey:@"imageData"];
    }
    
    // Encode CGImages array as PNG data array
    NSMutableArray *imageDataArray = [[NSMutableArray alloc] init];
    for (NSValue *value in CGImages) {
        CGImageRef cgImage;
        [value getValue:&cgImage];
        if (cgImage) {
            UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
            NSData *data = UIImagePNGRepresentation(uiImage);
            if (data) {
                [imageDataArray addObject:data];
            }
        }
    }
    [coder encodeObject:imageDataArray forKey:@"CGImagesData"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        width = [coder decodeIntForKey:@"width"];
        height = [coder decodeIntForKey:@"height"];
        rightX = [coder decodeIntForKey:@"rightX"];
        leftX = [coder decodeIntForKey:@"leftX"];
        topY = [coder decodeIntForKey:@"topY"];
        bottomY = [coder decodeIntForKey:@"bottomY"];
        palletCycles = [coder decodeIntForKey:@"palletCycles"];
        useTransparency = [coder decodeBoolForKey:@"useTransparency"];
        bitmaps = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [NSNumber class], nil] forKey:@"bitmaps"] mutableCopy];
        
        // Decode main image
        NSData *imageData = [coder decodeObjectOfClass:[NSData class] forKey:@"imageData"];
        if (imageData) {
            image = [UIImage imageWithData:imageData];
        }
        
        // Decode CGImages array
        CGImages = [[NSMutableArray alloc] init];
        images = [[NSMutableArray alloc] init];
        NSArray *imageDataArray = [coder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSData class], nil] forKey:@"CGImagesData"];
        for (NSData *data in imageDataArray) {
            UIImage *uiImage = [UIImage imageWithData:data];
            if (uiImage) {
                CGImageRef cgImage = uiImage.CGImage;
                CGImageRetain(cgImage);
                NSValue *cgImageValue = [NSValue valueWithBytes:&cgImage objCType:@encode(CGImageRef)];
                [CGImages addObject:cgImageValue];
            }
        }
    }
    return self;
}

-(void)dump
{
    NSLog(@"");
    NSLog(@"Bitmap Dump");
    NSLog(@" width: %u, height: %u",width,height);
    NSLog(@" rightX: %u, leftX: %u, topY: %u, bottomY: %u",rightX,leftX,topY,bottomY);
    NSLog(@" reverse Translate X: %i, reverse Translate Y: %i",[self reverseTranslateX],[self reverseTranslateY]);
    NSLog(@"");
}

-(int)translateX:(int)offset
{
    return leftX+offset;
}

-(int)translateY:(int)offset

{
    return topY+offset;
}

-(int)reverseTranslateX
{
    //return rightX-leftX-1;
    return -(leftX+1);
}

-(int)reverseTranslateY
{
    //return rightY-leftY-1;
    return -(topY+1);
}
@end




@implementation U7ChunkIndex

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    shapeIndex=0;
    frameIndex=0;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt64:shapeIndex forKey:@"shapeIndex"];
    [coder encodeInt:frameIndex forKey:@"frameIndex"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        shapeIndex = [coder decodeInt64ForKey:@"shapeIndex"];
        frameIndex = [coder decodeIntForKey:@"frameIndex"];
    }
    return self;
}
-(void)dump
{
    NSLog(@"shapeIndex:%li  frameIndex:%i",shapeIndex,frameIndex);
}

@end
@implementation U7Chunk

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    chunkMap=[[NSMutableArray alloc]init];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:chunkMap forKey:@"chunkMap"];
    [coder encodeBool:hasAnimatedTiles forKey:@"hasAnimatedTiles"];
    
    // Encode tileImage
    if (tileImage) {
        NSData *imageData = UIImagePNGRepresentation(tileImage);
        [coder encodeObject:imageData forKey:@"tileImageData"];
    }
    
    // Encode tileImages array
    if (tileImages) {
        NSMutableArray *imageDataArray = [[NSMutableArray alloc] init];
        for (UIImage *img in tileImages) {
            NSData *data = UIImagePNGRepresentation(img);
            if (data) {
                [imageDataArray addObject:data];
            }
        }
        [coder encodeObject:imageDataArray forKey:@"tileImagesData"];
    }
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        chunkMap = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7ChunkIndex class], nil] forKey:@"chunkMap"] mutableCopy];
        hasAnimatedTiles = [coder decodeBoolForKey:@"hasAnimatedTiles"];
        
        // Decode tileImage
        NSData *imageData = [coder decodeObjectOfClass:[NSData class] forKey:@"tileImageData"];
        if (imageData) {
            tileImage = [UIImage imageWithData:imageData];
        }
        
        // Decode tileImages array
        NSArray *imageDataArray = [coder decodeObjectOfClasses:[NSSet setWithObjects:[NSArray class], [NSData class], nil] forKey:@"tileImagesData"];
        if (imageDataArray) {
            tileImages = [[NSMutableArray alloc] init];
            for (NSData *data in imageDataArray) {
                UIImage *img = [UIImage imageWithData:data];
                if (img) {
                    [tileImages addObject:img];
                }
            }
        }
    }
    return self;
}

-(void)dump
{
    NSLog(@"dump");
    for(int y=0;y<CHUNKSIZE;y++)
    {
        for(int x=0;x<CHUNKSIZE;x++)
        {
            U7ChunkIndex * chunkIndex=[chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
            NSLog(@"x:%i y:%i",x,y);
            [chunkIndex dump];
        }
        
        
    }

    NSLog(@"done");
}


-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
        environment=theEnvironment;
    else
    {
        NSLog(@"U7Chunk setEnvironment error");
    }
}

-(void)createTileImage
{
    // First, check if this chunk has any animated tiles (water, lava, etc.)
    // Any tile with palette cycles > 1 is animated
    hasAnimatedTiles = NO;
    U7Shape * shape;
    
    for(int y=0;y<CHUNKSIZE;y++)
    {
        for(int x=0;x<CHUNKSIZE;x++)
        {
            U7ChunkIndex * chunkIndex=[chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
            if(shape->tile)
            {
                if(chunkIndex->frameIndex <= ([shape->frames count]-1))
                {
                    U7Bitmap * bitmap=[shape->frames objectAtIndex:chunkIndex->frameIndex];
                    if(bitmap->palletCycles > 1)
                    {
                        hasAnimatedTiles = YES;
                        break;
                    }
                }
            }
        }
        if(hasAnimatedTiles) break;
    }
    
    // Create the base tile image (frame 0)
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(CHUNKSIZE*TILESIZE, CHUNKSIZE*TILESIZE), YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    for(int y=0;y<CHUNKSIZE;y++)
    {
        for(int x=0;x<CHUNKSIZE;x++)
        {
            U7ChunkIndex * chunkIndex=[chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
            if(shape->tile)
            {
                if(chunkIndex->frameIndex > ([shape->frames count]-1))
                {
                    //NSLog(@"Frame too big!");
                }
                else
                {
                    U7Bitmap * bitmap=[shape->frames objectAtIndex:chunkIndex->frameIndex];
                    UIImage* flippedImage = [UIImage imageWithCGImage:bitmap->image.CGImage
                                                                scale:bitmap->image.scale
                                                          orientation:UIImageOrientationDownMirrored];
                    [flippedImage drawInRect:CGRectMake(x*TILESIZE, y*TILESIZE, TILESIZE, TILESIZE)];
                }
            }
        }
    }
    UIGraphicsPopContext();
    tileImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // If chunk has animated tiles, create all animation frames
    if(hasAnimatedTiles)
    {
        [self createAnimatedTileImages];
    }
}

-(void)createAnimatedTileImages
{
    // Create 8 frames of animated tile images for palette cycling
    tileImages = [[NSMutableArray alloc] initWithCapacity:8];
    
    for(int frame=0; frame<8; frame++)
    {
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(CHUNKSIZE*TILESIZE, CHUNKSIZE*TILESIZE), YES, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        UIGraphicsPushContext(context);
        
        for(int y=0;y<CHUNKSIZE;y++)
        {
            for(int x=0;x<CHUNKSIZE;x++)
            {
                U7ChunkIndex * chunkIndex=[chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
                U7Shape * shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
                if(shape->tile)
                {
                    if(chunkIndex->frameIndex > ([shape->frames count]-1))
                    {
                        //NSLog(@"Frame too big!");
                    }
                    else
                    {
                        U7Bitmap * bitmap=[shape->frames objectAtIndex:chunkIndex->frameIndex];
                        
                        // Determine which image to use based on animation
                        CGImageRef imageToDraw;
                        if(bitmap->palletCycles > 1 && [bitmap->CGImages count] > 1)
                        {
                            // Use the animated frame for any palette-cycled tile
                            int imageIndex = frame % bitmap->palletCycles;
                            if(imageIndex < [bitmap->CGImages count])
                            {
                                [[bitmap->CGImages objectAtIndex:imageIndex] getValue:&imageToDraw];
                            }
                            else
                            {
                                imageToDraw = bitmap->image.CGImage;
                            }
                        }
                        else
                        {
                            // Non-animated tile, use base image
                            imageToDraw = bitmap->image.CGImage;
                        }
                        
                        UIImage* flippedImage = [UIImage imageWithCGImage:imageToDraw
                                                                    scale:bitmap->image.scale
                                                              orientation:UIImageOrientationDownMirrored];
                        [flippedImage drawInRect:CGRectMake(x*TILESIZE, y*TILESIZE, TILESIZE, TILESIZE)];
                    }
                }
            }
        }
        UIGraphicsPopContext();
        UIImage * frameImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        [tileImages addObject:frameImage];
    }
}

-(UIImage*)tileImageForAnimationFrame:(NSInteger)frame
{
    if(hasAnimatedTiles && tileImages && [tileImages count] > 0)
    {
        NSInteger index = frame % [tileImages count];
        return [tileImages objectAtIndex:index];
    }
    return tileImage;
}

@end

@implementation U7MapChunk

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    dirty=NO;
    animates=NO;
    highlited=NO;
    masterChunkID=-1;
    masterChunk=NULL;
    flatChunkID=-1;
    staticItems=[[NSMutableArray alloc]init];
    gameItems=[[NSMutableArray alloc]init];
    sprites=[[NSMutableArray alloc]init];
    groundObjects=[[NSMutableArray alloc]init];
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeBool:animates forKey:@"animates"];
    [coder encodeBool:dirty forKey:@"dirty"];
    [coder encodeBool:highlited forKey:@"highlited"];
    [coder encodeInt:masterChunkID forKey:@"masterChunkID"];
    [coder encodeInt:flatChunkID forKey:@"flatChunkID"];
    [coder encodeObject:staticItems forKey:@"staticItems"];
    [coder encodeObject:gameItems forKey:@"gameItems"];
    [coder encodeObject:groundObjects forKey:@"groundObjects"];
    // Note: sprites, passabilityBBitMap, environmentMap, masterChunk, and environment are rebuilt after load
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        animates = [coder decodeBoolForKey:@"animates"];
        dirty = [coder decodeBoolForKey:@"dirty"];
        highlited = [coder decodeBoolForKey:@"highlited"];
        masterChunkID = [coder decodeIntForKey:@"masterChunkID"];
        flatChunkID = [coder decodeIntForKey:@"flatChunkID"];
        staticItems = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7ShapeReference class], nil] forKey:@"staticItems"] mutableCopy];
        gameItems = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7ShapeReference class], nil] forKey:@"gameItems"] mutableCopy];
        groundObjects = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7ShapeReference class], nil] forKey:@"groundObjects"] mutableCopy];
        sprites = [[NSMutableArray alloc] init];
        // masterChunk will be reconnected after full load
    }
    return self;
}


-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
        environment=theEnvironment;
    else
    {
        NSLog(@"U7MapChunk setEnvironment error");
    }
}

- (id)copyWithZone:(NSZone *)zone
{
    U7MapChunk*  copy = [[U7MapChunk alloc] init];

    if (copy) {
        // Copy NSObject subclasses
        
        for(long index=0;index<[groundObjects count];index++)
        {
            U7ShapeReference * shapeReference=[groundObjects objectAtIndex:index];
            U7ShapeReference * newReference=[shapeReference copy];
            [copy->groundObjects addObject:newReference];
        }
        for(long index=0;index<[staticItems count];index++)
        {
            U7ShapeReference * shapeReference=[staticItems objectAtIndex:index];
            U7ShapeReference * newReference=[shapeReference copy];
            [copy->staticItems addObject:newReference];
        }
        
        for(long index=0;index<[gameItems count];index++)
        {
            U7ShapeReference * shapeReference=[gameItems objectAtIndex:index];
            U7ShapeReference * newReference=[shapeReference copy];
            [copy->gameItems addObject:newReference];
        }
        copy->masterChunkID=masterChunkID;
        copy->masterChunk=masterChunk;
        
    }

    return copy;
}
-(BOOL)passabilityForLocation:(CGPoint)location atHeight:(int)height
{
    if(!passabilityBBitMap)
        return NO;
    int value=[passabilityBBitMap valueAtPosition:location];
    return value;
}
-(void)createEnvironmentMap
{
    environmentMap=[[BAEnvironmentMap alloc]init];
    U7Shape * tileShape=NULL;
    for(int y=0;y<CHUNKSIZE;y++)
    {
        for(int x=0;x<CHUNKSIZE;x++)
        {
            U7ChunkIndex * chunkIndex=[masterChunk->chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
            tileShape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
            if(tileShape->water)
            {
                [environmentMap setEnvironmentTypeAtPosition:WaterBAEnvironmentType atPosition:CGPointMake(x,y)];
            }
            else
            [environmentMap setEnvironmentTypeAtPosition:GrassBAEnvironmentType atPosition:CGPointMake(x,y)];
        }
    }
    
}

-(void)createPassability
{
    //we will assign a number for passability:
    //zero means no
    //Use height for walkable things like rugs, boards, boxes, etc
    //passabilityBitMap=[[NSMutableArray alloc]init];
    passabilityBBitMap=[BABooleanBitmap createWithCGSize:CGSizeMake(CHUNKSIZE, CHUNKSIZE)];
    BOOL passability;
    
    //first get tiles
    U7Shape * shape=NULL;
    
    for(int y=0;y<CHUNKSIZE;y++)
    {
        for(int x=0;x<CHUNKSIZE;x++)
        {
            U7ChunkIndex * chunkIndex=[masterChunk->chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
            //if(shape->tile)
            {
            //if(shape->tileSizeZ<2)
                [passabilityBBitMap setValueAtPosition:!shape->notWalkable forPosition:CGPointMake(x, y)];
            //else
            //   passability=[NSNumber numberWithInt:!shape->notWalkable];
            }
            
            
            //[passabilityBitMap addObject:passability];
        }
    }
    
   
    //game objects
    
    for(int count=0;count<[gameItems count];count++)
    {
        U7ShapeReference * reference=[gameItems objectAtIndex:count];
        U7Shape * shape=[environment->U7Shapes objectAtIndex:reference->shapeID];
        //if(shape->notWalkable)
        if(reference->lift<2)
            for(int ySize=0;ySize<shape->TileSizeYMinus1+1;ySize++)
            {
                for(int xSize=0;xSize<shape->TileSizeXMinus1+1;xSize++)
                {
                    
                    int newX=reference->parentChunkXCoord-xSize;
                    int newY=reference->parentChunkYCoord-ySize;
                    if(shape->tileSizeZ<2||shape->door)
                        
                        passability=1;
                    else
                        passability=0;
                    if(newX>=0&&newY>=0&&newX<CHUNKSIZE&&newY<CHUNKSIZE)
                    {
                        //[passabilityBitMap replaceObjectAtIndex:(newY*CHUNKSIZE)+newX withObject:passability];
                        
                        [passabilityBBitMap setValueAtPosition:passability forPosition:CGPointMake(newX, newY)];
                    }
                    
                }
            }
    }
    
    //ground objects
    // we do ground objects after game objects because they are more permanent
    for(int y=0;y<CHUNKSIZE;y++)
    {
        for(int x=0;x<CHUNKSIZE;x++)
        {
            U7ChunkIndex * chunkIndex=[masterChunk->chunkMap objectAtIndex:(y*CHUNKSIZE)+x];
            shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
            if(!shape->tile)
            {
            //if(shape->notWalkable)
            {
               
                for(int ySize=0;ySize<shape->TileSizeYMinus1+1;ySize++)
                {
                    for(int xSize=0;xSize<shape->TileSizeXMinus1+1;xSize++)
                    {
                        
                        int newX=x-xSize;
                        int newY=y-ySize;
                        if(shape->tileSizeZ<2||shape->door)
                            passability=1;
                        else
                            passability=0;
                        if(newX>=0&&newY>=0&&newX<CHUNKSIZE&&newY<CHUNKSIZE)
                        {
                            //[passabilityBitMap replaceObjectAtIndex:(newY*CHUNKSIZE)+newX withObject:passability];
                            [passabilityBBitMap setValueAtPosition:passability forPosition:CGPointMake(newX, newY)];
                        }
                        else
                        {
                        }
                    }
                }
            }
            }
        }
    }
    
    
    //static
    //skip for now until we can not count roof
    
    for(int count=0;count<[staticItems count];count++)
    {
        U7ShapeReference * reference=[staticItems objectAtIndex:count];
        U7Shape * shape=[environment->U7Shapes objectAtIndex:reference->shapeID];
        //if(shape->notWalkable)
        if(reference->lift<2)
            for(int ySize=0;ySize<shape->TileSizeYMinus1+1;ySize++)
            {
                for(int xSize=0;xSize<shape->TileSizeXMinus1+1;xSize++)
                {
                    
                    int newX=reference->parentChunkXCoord-xSize;
                    int newY=reference->parentChunkYCoord-ySize;
                    if(shape->tileSizeZ<2||shape->door)
                        passability=1;
                    else
                        passability=0;
                    if(newX>=0&&newY>=0&&newX<CHUNKSIZE&&newY<CHUNKSIZE)
                    {
                        //[passabilityBitMap replaceObjectAtIndex:(newY*CHUNKSIZE)+newX withObject:passability];
                    [passabilityBBitMap setValueAtPosition:passability  forPosition:CGPointMake(newX, newY)];
                    }
                    
                }
            }
    }
    

    
}

-(void)dump
{
    NSLog(@"masterChunkID %i, flatChunkID:%i",masterChunkID,flatChunkID);
}


-(void)updateShapeInfo:(U7Environment*)env
{
    //NSLog(@"updateShapeInfo");
    U7Chunk * chunk=[env->U7Chunks objectAtIndex:masterChunkID];
    U7ChunkIndex *chunkIndex;
    //[chunkIndex dump];
    U7Shape * shape;
    for(int tileY=0;tileY<CHUNKSIZE;tileY++)
        {
        for(int tileX=0;tileX<CHUNKSIZE;tileX++)
            {
            chunkIndex=[chunk->chunkMap objectAtIndex:(tileY*CHUNKSIZE)+tileX];
            shape=[env->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
            if(!shape->tile)
                {
                    
                    U7ShapeReference * newReference=[[U7ShapeReference alloc]init];
                    
                    newReference->shapeID=chunkIndex->shapeIndex;
                    newReference->parentChunkXCoord=tileX;
                    newReference->parentChunkYCoord=tileY;
                    //newReference->xloc=tileX*TILESIZE+(x*CHUNKSIZE);
                    //newReference->yloc=tileY*TILESIZE+(y*CHUNKSIZE);
                    newReference->lift=0;
                    newReference->frameNumber=chunkIndex->frameIndex;
                    newReference->currentFrame=chunkIndex->frameIndex;
                    newReference->animates=shape->animated;
                    newReference->parentChunkID=flatChunkID;
                    if(newReference->animates)
                        newReference->currentFrame=0;
                    /*
                    if(shape->animated)
                    {
                        newReference->currentFrame=currentFrame%[shape numberOfFrames];
                    }
                    */
                    
                    newReference->GroundObject=YES;
                    newReference->numberOfFrames=[shape numberOfFrames];
                    
                    //NSString * xmlString=[newReference exportToXML];
                    //NSLog(@"%@",xmlString);
                    [groundObjects addObject:newReference];
                }
            }
        }
    
    
    if(staticItems)
    {
        
        for(int x=0;x<[staticItems count];x++)
        {
            
            U7ShapeReference * reference=[staticItems objectAtIndex:x];
            U7Shape * shape=[env->U7Shapes objectAtIndex:reference->shapeID];
            reference->animates=shape->animated;
            reference->parentChunkID=flatChunkID;
            if(shape->animated)
                self->animates=YES;
            reference->numberOfFrames=[shape numberOfFrames];
            
            // Validate and fix frame numbers
            if(reference->numberOfFrames > 0) {
                if(reference->frameNumber >= reference->numberOfFrames) {
                    reference->frameNumber = 0;
                }
                if(reference->currentFrame >= reference->numberOfFrames) {
                    reference->currentFrame = 0;
                }
            }
            
        }
    }
    else
        NSLog(@"bad");
    
    if(gameItems)
    {
        
        for(int x=0;x<[gameItems count];x++)
        {
            
            U7ShapeReference * reference=[gameItems objectAtIndex:x];
            U7Shape * shape=[env->U7Shapes objectAtIndex:reference->shapeID];
            reference->animates=shape->animated;
            reference->parentChunkID=flatChunkID;
            if(shape->animated)
                self->animates=YES;
            reference->numberOfFrames=[shape numberOfFrames];
            
            // Validate and fix frame numbers
            if(reference->numberOfFrames > 0) {
                if(reference->frameNumber >= reference->numberOfFrames) {
                    reference->frameNumber = 0;
                }
                if(reference->currentFrame >= reference->numberOfFrames) {
                    reference->currentFrame = 0;
                }
            }
            
        }
    }
    else
        NSLog(@"baaaaaad");
}



-(U7ShapeReference*)staticShapeForLocation:(CGPoint)location forHeight:(int)height
{
    if(!staticItems)
        return NULL;
    if(![staticItems count])
        return NULL;
    for(int i=0;i<[staticItems count];i++)
    {
        U7ShapeReference * reference=[staticItems objectAtIndex:i];
        if(reference->parentChunkYCoord==location.y&&reference->parentChunkXCoord==location.x&&reference->lift==height)
            return reference;
    }
    return NULL;
}


-(U7ShapeReference*)gameShapeForLocation:(CGPoint)location forHeight:(int)height
{
    if(!gameItems)
            return NULL;
    if(![gameItems count])
        return NULL;
    for(int i=0;i<[gameItems count];i++)
    {
        U7ShapeReference * reference=[gameItems objectAtIndex:i];
        if(reference->parentChunkYCoord==location.y&&reference->parentChunkXCoord==location.x&&reference->lift==height)
            return reference;
    }
    return NULL;
}


-(U7ShapeReference*)groundShapeForLocation:(CGPoint)location forHeight:(int)height
{
    if(!groundObjects)
            return NULL;
    if(![groundObjects count])
        return NULL;
    for(int i=0;i<[groundObjects count];i++)
    {
        U7ShapeReference * reference=[groundObjects objectAtIndex:i];
        if(reference->parentChunkYCoord==location.y&&reference->parentChunkXCoord==location.x&&reference->lift==height)
            return reference;
    }
    return NULL;
}

-(void)addSprite:(BASprite*)theSprite atLocation:(CGPoint)location
{
    [theSprite setShapeChunkLocation:location];
    [sprites addObject:theSprite];
}

-(void)removeSprite:(BASprite*)theSprite
{
    
    [sprites removeObject:theSprite];
    /*
    long index=[sprites indexOfObject:theSprite];
    if(index!=NSNotFound)
    {
        //NSLog(@"removeSprite at index: %li",index);
        [sprites removeObjectAtIndex:index];
    }
    else
        NSLog(@"Not Found");
     */
    
}
-(void)removeAllSprites
{
    [sprites removeAllObjects];
}

-(void)removeAllObjects
{
    [staticItems removeAllObjects];
    [gameItems removeAllObjects];
    [sprites removeAllObjects];
    [groundObjects removeAllObjects];
}

-(NSArray*)findShapesWithID:(int)shapeID forFrame:(int)frameID
{
    NSMutableArray * shapes=[[NSMutableArray alloc]init];
    if(staticItems)
    {
        for(long index=0;index<[staticItems count];index++)
        {
            U7ShapeReference* shapeReference=[staticItems objectAtIndex:index];
            if(shapeReference->shapeID==shapeID&&shapeReference->frameNumber==frameID)
            {
                //NSLog(@"hit staticItems!");
                [shapes addObject:shapeReference];
            }
        }
    }
    
    if(gameItems)
    {
        for(long index=0;index<[gameItems count];index++)
        {
            U7ShapeReference* shapeReference=[gameItems objectAtIndex:index];
            if(shapeReference->shapeID==shapeID&&shapeReference->frameNumber==frameID)
            {
               //NSLog(@"hit gameItems!");
                [shapes addObject:shapeReference];
            }
        }
    }
    
    if(sprites)
    {
        for(long index=0;index<[sprites count];index++)
        {
            U7ShapeReference* shapeReference=[sprites objectAtIndex:index];
            if(shapeReference->shapeID==shapeID&&shapeReference->frameNumber==frameID)
            {
                //NSLog(@"hit sprites!");
                [shapes addObject:shapeReference];
            }
        }
    }
    
    if(groundObjects)
    {
        for(long index=0;index<[groundObjects count];index++)
        {
            U7ShapeReference* shapeReference=[groundObjects objectAtIndex:index];
            if(shapeReference->shapeID==shapeID&&shapeReference->frameNumber==frameID)
            {
               //NSLog(@"hit groundObjects!");
                [shapes addObject:shapeReference];
            }
        }
    }
    if([shapes count])
        return [shapes copy];
    return NULL;
}


-(enum BAEnvironmentType)environmentTypeAtLocation:(CGPoint)localLocation
{
    return [environmentMap environmentTypeAtPosition:localLocation];
}

@end

@implementation U7Map

+(BOOL)supportsSecureCoding { return YES; }

-(id)init
{
    self=[super init];
    map=[[NSMutableArray alloc]init];
    actors=[[NSMutableArray alloc]init];;
    environment=NULL;
    return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeInt64:mapWidth forKey:@"mapWidth"];
    [coder encodeInt64:mapHeight forKey:@"mapHeight"];
    [coder encodeInt64:chunkSize forKey:@"chunkSize"];
    [coder encodeInt64:tileSize forKey:@"tileSize"];
    [coder encodeObject:map forKey:@"map"];
    // actors and environment are rebuilt after load
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        mapWidth = [coder decodeInt64ForKey:@"mapWidth"];
        mapHeight = [coder decodeInt64ForKey:@"mapHeight"];
        chunkSize = [coder decodeInt64ForKey:@"chunkSize"];
        tileSize = [coder decodeInt64ForKey:@"tileSize"];
        map = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7MapChunk class], nil] forKey:@"map"] mutableCopy];
        actors = [[NSMutableArray alloc] init];
    }
    return self;
}




-(void)replaceChunkAtIndex:(long)index withChunk:(U7MapChunk*)theChunk
{
    if(theChunk)
        if(index>=0&&index<[map count])
        {
            [map removeObjectAtIndex:index];
            [map insertObject:[theChunk copy] atIndex:index];
        }
    
}


-(U7MapChunk*)mapChunkAtIndex:(long)index
{
    return [map objectAtIndex:index];
}

-(U7MapChunk*)mapChunkForLocation:(CGPoint)theLocation
{
    //NSLog(@"mapChunkForLocation: %f,%f",theLocation.x,theLocation.y);
    if(map)
    {
        long index=[self chunkIDForChunkCoordinate:theLocation];
        //NSLog(@"index: %li for %f,%f",index,theLocation.x,theLocation.y);
        return [map objectAtIndex:index];
        //return [Map->map objectAtIndex:1000];
    }
    return NULL;
}


-(U7MapChunkCoordinate*)MapChunkCoordinateForGlobalTilePosition:(CGPoint)thePosition
{
    //coordinate in TILE space
    U7MapChunkCoordinate * coordinate=[[U7MapChunkCoordinate alloc]init];
    //=(INT(G7/16)*G2)+(INT(F7/16))
    //=F7-INT(F7/16)*16
    long chunkID=[self chunkIDForGlobalTileCoordinate:thePosition];
    
    
    long tileY=thePosition.y;
    tileY=tileY%CHUNKSIZE;
    //tileY=thePosition.y-tileY;
    long tileX=thePosition.x;
    tileX=tileX%CHUNKSIZE;
    //tileX=thePosition.y-tileY;
    [coordinate setChunkTilePosition:CGPointMake(tileX, tileY)];
    
    
    [coordinate setMapChunkID:chunkID];
    
    return coordinate;
}

-(long)chunkIDForGlobalTileCoordinate:(CGPoint)coordinate
{
    long chunkX=coordinate.x/CHUNKSIZE;
    long chunkY=coordinate.y/CHUNKSIZE;
    
    return [self chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
}



-(long)chunkIDForChunkCoordinate:(CGPoint)coordinate
{
    int x=coordinate.x;
    int y=coordinate.y;
    int index=x+(y*(MAPSIZE*SUPERCHUNKSIZE));
    return index;
}

-(int)isPassable:(CGPoint)theLocation
{
    
    //OLD
    /*
    U7Shape * shape=[self tileShapeAtGlobalTilePosition:theLocation];
    if(shape->notWalkable)
        return NO;
     */
    
    //NEW
    U7MapChunkCoordinate* mapCoordinate=[self MapChunkCoordinateForGlobalTilePosition:theLocation];
    if(mapCoordinate)
    {
        U7MapChunk * chunk=[self mapChunkAtIndex:[mapCoordinate getMapChunk]];
        if(chunk)
        {
            int passability=[chunk passabilityForLocation:[mapCoordinate getChunkTilePosition] atHeight:1];
            return passability;
        }
    }
    return NO;
    
}
-(BOOL)validMapPosition:(CGPoint)position
{
    if(position.x<0||position.y<0)
        return NO;
    //if(position.y>(tilesHigh-1)||position.x>(tilesWide-1))
    //    return NO;
    return YES;
}

-(U7Shape*)tileShapeAtGlobalTilePosition:(CGPoint)thePosition
{
    U7Shape * shape=NULL;
    U7MapChunkCoordinate* mapCoordinate=[self MapChunkCoordinateForGlobalTilePosition:thePosition];
    if(mapCoordinate)
    {
        U7MapChunk * chunk=[self mapChunkAtIndex:[mapCoordinate getMapChunk]];
        //U7Chunk * masterChunk=[U7Chunks objectAtIndex:chunk->masterChunkID];
        U7Chunk * masterChunk=chunk->masterChunk;
        U7ChunkIndex * chunkIndex=[masterChunk->chunkMap objectAtIndex:([mapCoordinate getChunkTilePosition].y  *CHUNKSIZE)+[mapCoordinate getChunkTilePosition].x];
        shape=[environment->U7Shapes objectAtIndex:chunkIndex->shapeIndex];
        if(shape->tile)
        {
            return shape;
        }
        //[chunkIndex dump];
    }
    
    
    return shape;
}






- (NSArray *)walkableAdjacentTilesCoordForTileCoord:(CGPoint)tileCoord
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:8];
    
    BOOL t = NO;
    BOOL l = NO;
    BOOL b = NO;
    BOOL r = NO;
    
    // Top
    CGPoint p = CGPointMake(tileCoord.x, tileCoord.y - 1);
    if ([self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        t = YES;
    }
    
    // Left
     p = CGPointMake(tileCoord.x-1, tileCoord.y);
    if ([self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        l = YES;
    }
    
    // Bottom
     p = CGPointMake(tileCoord.x, tileCoord.y + 1);
    if ([self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        b = YES;
    }
    
    // Right
    
     p = CGPointMake(tileCoord.x+1, tileCoord.y);
    if ([self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        r = YES;
    }
    
    // Top Left
    
     p = CGPointMake(tileCoord.x-1, tileCoord.y - 1);
    if (t && l && [self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        t = YES;
    }
    
    // Bottom Left
     p = CGPointMake(tileCoord.x-1, tileCoord.y + 1);
    if (b && l && [self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        t = YES;
    }
    
    // Top Right
    p = CGPointMake(tileCoord.x+1, tileCoord.y - 1);
    if (t && r && [self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        t = YES;
    }
    
    // Bottom Right
    p = CGPointMake(tileCoord.x+1, tileCoord.y +1);
    if (b && r && [self validMapPosition:p] && [self isPassable:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
        t = YES;
    }
    
    return [NSArray arrayWithArray:tmp];
}

-(CGPoint)nearestPassableAdjacentTile:(CGPoint)destination from:(CGPoint)origin
{
    CGPoint bestPosition=CGPointMake(-100,-100);
    float distance=100000;
    //top
    CGPoint top=CGPointMake(destination.x, destination.y-1);
    if([self validMapPosition:top])
    {
        if([self isPassable:top]){
            //return [tiles objectAtIndex:(top.y*tilesWide)+top.x];;
            
            //float newdistance=abs(top.x - origin.x) + abs(top.y - origin.y);
            float newdistance=simpleDistance(top, origin);
            if(newdistance<distance)
            {
                distance=newdistance;
                bestPosition=top;
            }
            
        }
    }
    //bottom
    CGPoint bottom=CGPointMake(destination.x, destination.y+1);
    if([self validMapPosition:bottom])
    {
        if([self isPassable:bottom])
        {
            //return [tiles objectAtIndex:(bottom.y*tilesWide)+bottom.x];;
            //float newdistance=abs(bottom.x - origin.x) + abs(bottom.y - origin.y);
            float newdistance=simpleDistance(bottom, origin);
            if(newdistance<distance)
               {
                   distance=newdistance;
                   bestPosition=bottom;
               }
        }
    }
    //right
    CGPoint right=CGPointMake(destination.x+1, destination.y);
    if([self validMapPosition:right])
    {
        if([self isPassable:right])
            //return [tiles objectAtIndex:(right.y*tilesWide)+right.x];;
        {
            //float newdistance=abs(right.x - origin.x) + abs(right.y - origin.y);
            float newdistance=simpleDistance(right, origin);
            if(newdistance<distance)
               {
                   distance=newdistance;
                   bestPosition=right;
               }
        }
    }
    //left
    CGPoint left=CGPointMake(destination.x-1, destination.y);
    if([self validMapPosition:left])
    {
        if([self isPassable:left])
            //return [tiles objectAtIndex:(right.y*tilesWide)+right.x];;
        {
            //float newdistance=abs(left.x - origin.x) + abs(left.y - origin.y);
            float newdistance=simpleDistance(left, origin);
            if(newdistance<distance)
               {
                   distance=newdistance;
                   bestPosition=left;
               }
        }
            //return [tiles objectAtIndex:(left.y*tilesWide)+left.x];;
    }
    if([self validMapPosition:bestPosition])
    {
      
        return bestPosition;
    }
    return CGPointMake(-1, -1);
}

-(NSArray *)findShapesWithID:(int)shapeID forFrame:(int)frameID
{
    NSMutableArray * shapeReferences=[[NSMutableArray alloc]init];
    //NSLog(@"count: %li",[map count]);
    for(long index=0;index<[map count];index++)
    {
        U7MapChunk * chunk=[map objectAtIndex:index];
        if(chunk)
        {
            NSArray * shapesInChunk=[chunk findShapesWithID:shapeID forFrame:frameID];
            
            if(shapesInChunk)
            {
                for(long chunkIndex=0;chunkIndex<[shapesInChunk count];chunkIndex++)
                {
                    U7ShapeReference * shapeReference=[shapesInChunk objectAtIndex:chunkIndex];
                    [shapeReferences addObject:shapeReference];
                }
            }
            
        }
        
    }
    if([shapeReferences count])
        return [shapeReferences copy];
    
    return NULL;
}

-(BASprite*)spriteAtLocation:(CGPoint)globalLocation ofResourceType:(enum BAResourceType)resourceType
{
    BASprite * theSprite=NULL;
    
    U7MapChunkCoordinate * coordinate=[self MapChunkCoordinateForGlobalTilePosition:globalLocation];
    
    U7MapChunk * mapChunk=[self mapChunkForLocation:[coordinate mapChunkCoordinate]];
    
    NSMutableArray * chunkSprites=mapChunk->sprites;
    if(![chunkSprites count])
        return NULL;
    for(long index=0;index<[chunkSprites count];index++)
    {
        BASprite * tempSprite=[chunkSprites objectAtIndex:index];
        if(tempSprite->resourceType==resourceType)
        {
            if(CGPointEqualToPoint(CGPointMake(tempSprite->shapeReference->parentChunkXCoord,tempSprite->shapeReference->parentChunkYCoord), [coordinate getChunkTilePosition]))
            {
                //NSLog(@"yes");
                theSprite=tempSprite;
               break;
            }
            
        }
    }
    
    return theSprite;
}

-(BAActor*)actorAtLocation:(CGPoint)globalLocation ofActorType:(enum BAActorType)actorType
{
    BAActor * theActor=NULL;
    for(long index=0;index<[actors count];index++)
    {
        BAActor * tempActor=[actors objectAtIndex:index];
        if(tempActor->actorType==actorType)
        {
            //NSLog(@"yes");
            if(CGPointEqualToPoint([tempActor getGlobalLocation], globalLocation))
            {
                //NSLog(@"yes");
                theActor=tempActor;
               break;
            }
            
        }
    }
    
    return theActor;
}


-(void)removeSpriteAtLocation:(CGPoint)location forSprite:(BASprite*)theSprite
{
    
    U7MapChunkCoordinate * coordinate=[self MapChunkCoordinateForGlobalTilePosition:location];
     U7MapChunk * mapChunk=[self mapChunkForLocation:[coordinate mapChunkCoordinate]];
    [mapChunk removeSprite:theSprite];
    
}

-(void)removeActorAtLocation:(CGPoint)location forActor:(BAActor*)theActor
{
    
    [actors removeObject:theActor];
    
}

-(void)removeAllSprites
{
    for(long index=0;index<[map count];index++)
    {
        U7MapChunk * mapChunk=[map objectAtIndex:index];
        [mapChunk removeAllSprites];
    }
   
}

-(void)createPassabilityMaps
{
    NSLog(@"createPassabilityMaps");
    dispatch_apply([map count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
        U7MapChunk * mapChunk = [map objectAtIndex:index];
        [mapChunk createPassability];
    });
    
        //[mapChunk dump];
    //printf("\n");
    NSLog(@"done");
}

-(void)createEnvironmentMaps
{
    NSLog(@"createEnvironmentMaps");
    dispatch_apply([map count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t index) {
        U7MapChunk * mapChunk = [map objectAtIndex:index];
        [mapChunk createEnvironmentMap];
    });
    NSLog(@"done");
}

-(enum BAEnvironmentType)environmentTypeForLocation:(CGPoint)globalLocation
{
    U7MapChunkCoordinate * coordinate=[self MapChunkCoordinateForGlobalTilePosition:globalLocation];
    
    U7MapChunk * mapChunk=[self mapChunkForLocation:[coordinate mapChunkCoordinate]];
    U7ShapeReference* shapeReference=[mapChunk groundShapeForLocation:[coordinate getChunkTilePosition] forHeight:0];
    
    enum BAEnvironmentType environmentType=[environment environmentTypeForShapeID:shapeReference->shapeID];
    
    return environmentType;
}

@end


@implementation U7Environment

+(BOOL)supportsSecureCoding { return YES; }

#pragma mark - Cache Management

+(NSString*)cacheFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths firstObject];
    return [cachesDirectory stringByAppendingPathComponent:@"U7Environment.cache"];
}

+(NSString*)cacheVersion
{
    // Increment this when data structures change to invalidate old caches
    return @"1.0.0";
}

+(BOOL)cacheExists
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:[self cacheFilePath]];
}

+(void)clearCache
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *cachePath = [self cacheFilePath];
    if ([fileManager fileExistsAtPath:cachePath]) {
        NSError *error;
        [fileManager removeItemAtPath:cachePath error:&error];
        if (error) {
            NSLog(@"Error clearing cache: %@", error);
        } else {
            NSLog(@"Cache cleared successfully");
        }
    }
}

-(BOOL)saveToCache
{
    NSLog(@"Saving environment to cache...");
    NSError *error;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self requiringSecureCoding:YES error:&error];
    if (error) {
        NSLog(@"Error archiving environment: %@", error);
        return NO;
    }
    
    BOOL success = [data writeToFile:[U7Environment cacheFilePath] atomically:YES];
    if (success) {
        NSLog(@"Environment saved to cache successfully (%lu bytes)", (unsigned long)[data length]);
    } else {
        NSLog(@"Failed to write cache to disk");
    }
    NSLog(@"done");
    return success;
}

+(nullable U7Environment*)loadFromCache
{
    if (![self cacheExists]) {
        NSLog(@"No cache file found");
        return nil;
    }
    
    NSLog(@"Loading environment from cache...");
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:[self cacheFilePath]];
    if (!data) {
        NSLog(@"Failed to read cache file");
        return nil;
    }
    
    U7Environment *environment = [NSKeyedUnarchiver unarchivedObjectOfClass:[U7Environment class] fromData:data error:&error];
    if (error) {
        NSLog(@"Error unarchiving environment: %@", error);
        [self clearCache]; // Clear corrupted cache
        return nil;
    }
    
    NSLog(@"Environment loaded from cache successfully");
    return environment;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:[U7Environment cacheVersion] forKey:@"cacheVersion"];
    [coder encodeObject:pallet forKey:@"pallet"];
    [coder encodeObject:transparencyPallet forKey:@"transparencyPallet"];
    [coder encodeObject:U7Shapes forKey:@"U7Shapes"];
    [coder encodeObject:U7FaceShapes forKey:@"U7FaceShapes"];
    [coder encodeObject:U7SpriteShapes forKey:@"U7SpriteShapes"];
    [coder encodeObject:U7GumpShapes forKey:@"U7GumpShapes"];
    [coder encodeObject:U7FontShapes forKey:@"U7FontShapes"];
    [coder encodeObject:Map forKey:@"Map"];
    [coder encodeObject:U7Chunks forKey:@"U7Chunks"];
    [coder encodeObject:animationSequences forKey:@"animationSequences"];
}

-(instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        NSString *version = [coder decodeObjectOfClass:[NSString class] forKey:@"cacheVersion"];
        if (![version isEqualToString:[U7Environment cacheVersion]]) {
            NSLog(@"Cache version mismatch, need to rebuild");
            return nil;
        }
        
        pallet = [coder decodeObjectOfClass:[U7Palette class] forKey:@"pallet"];
        transparencyPallet = [coder decodeObjectOfClass:[U7Palette class] forKey:@"transparencyPallet"];
        U7Shapes = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Shape class], nil] forKey:@"U7Shapes"] mutableCopy];
        U7FaceShapes = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Shape class], nil] forKey:@"U7FaceShapes"] mutableCopy];
        U7SpriteShapes = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Shape class], nil] forKey:@"U7SpriteShapes"] mutableCopy];
        U7GumpShapes = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Shape class], nil] forKey:@"U7GumpShapes"] mutableCopy];
        U7FontShapes = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Shape class], nil] forKey:@"U7FontShapes"] mutableCopy];
        Map = [coder decodeObjectOfClass:[U7Map class] forKey:@"Map"];
        U7Chunks = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7Chunk class], nil] forKey:@"U7Chunks"] mutableCopy];
        animationSequences = [[coder decodeObjectOfClasses:[NSSet setWithObjects:[NSMutableArray class], [U7AnimationSequence class], nil] forKey:@"animationSequences"] mutableCopy];
        
        // Reconnect references that couldn't be serialized
        [self reconnectReferencesAfterLoad];
    }
    return self;
}

-(void)reconnectReferencesAfterLoad
{
    NSLog(@"Reconnecting references after cache load...");
    
    // Set environment reference on Map
    Map->environment = self;
    
    // Reconnect U7Chunks with environment and masterChunk references
    for (U7Chunk *chunk in U7Chunks) {
        chunk->environment = self;
    }
    
    // Reconnect U7MapChunks with their masterChunk and environment
    // AND fix numberOfFrames for all shape references
    for (U7MapChunk *mapChunk in Map->map) {
        mapChunk->environment = self;
        if (mapChunk->masterChunkID >= 0 && mapChunk->masterChunkID < [U7Chunks count]) {
            mapChunk->masterChunk = [U7Chunks objectAtIndex:mapChunk->masterChunkID];
        }
        
        // Fix numberOfFrames for all shape references in this chunk
        // This corrects any stale values from cached data
        [self fixShapeFrameCountsForMapChunk:mapChunk];
    }
    
    // Recreate passability and environment maps (these are fast to generate)
    [self createPassabilityMaps];
    [self createEnvironmentMaps];
    
    NSLog(@"References reconnected successfully");
}

-(void)fixShapeFrameCountsForMapChunk:(U7MapChunk*)mapChunk
{
    // Fix frame counts for groundObjects
    for (U7ShapeReference *ref in mapChunk->groundObjects) {
        if (ref->shapeID >= 0 && ref->shapeID < [U7Shapes count]) {
            U7Shape *shape = [U7Shapes objectAtIndex:ref->shapeID];
            long actualFrameCount = [shape numberOfFrames];
            if (ref->numberOfFrames != actualFrameCount) {
                ref->numberOfFrames = actualFrameCount;
            }
            // Validate and fix frameNumber
            if (actualFrameCount > 0 && ref->frameNumber >= actualFrameCount) {
                NSLog(@"WARNING: Fixing invalid frameNumber %d for shapeID %li (max %li)",
                      ref->frameNumber, ref->shapeID, actualFrameCount - 1);
                ref->frameNumber = 0;
            }
            // Validate and fix currentFrame
            if (actualFrameCount > 0 && ref->currentFrame >= actualFrameCount) {
                ref->currentFrame = 0;
            }
        }
    }
    
    // Fix frame counts for staticItems
    for (U7ShapeReference *ref in mapChunk->staticItems) {
        if (ref->shapeID >= 0 && ref->shapeID < [U7Shapes count]) {
            U7Shape *shape = [U7Shapes objectAtIndex:ref->shapeID];
            long actualFrameCount = [shape numberOfFrames];
            if (ref->numberOfFrames != actualFrameCount) {
                ref->numberOfFrames = actualFrameCount;
            }
            if (actualFrameCount > 0 && ref->frameNumber >= actualFrameCount) {
                NSLog(@"WARNING: Fixing invalid frameNumber %d for shapeID %li (max %li)",
                      ref->frameNumber, ref->shapeID, actualFrameCount - 1);
                ref->frameNumber = 0;
            }
            if (actualFrameCount > 0 && ref->currentFrame >= actualFrameCount) {
                ref->currentFrame = 0;
            }
        }
    }
    
    // Fix frame counts for gameItems
    for (U7ShapeReference *ref in mapChunk->gameItems) {
        if (ref->shapeID >= 0 && ref->shapeID < [U7Shapes count]) {
            U7Shape *shape = [U7Shapes objectAtIndex:ref->shapeID];
            long actualFrameCount = [shape numberOfFrames];
            if (ref->numberOfFrames != actualFrameCount) {
                ref->numberOfFrames = actualFrameCount;
            }
            if (actualFrameCount > 0 && ref->frameNumber >= actualFrameCount) {
                NSLog(@"WARNING: Fixing invalid frameNumber %d for shapeID %li (max %li)",
                      ref->frameNumber, ref->shapeID, actualFrameCount - 1);
                ref->frameNumber = 0;
            }
            if (actualFrameCount > 0 && ref->currentFrame >= actualFrameCount) {
                ref->currentFrame = 0;
            }
        }
    }
}

-(id)init
{
    // Cache loading and saving disabled
    
    // Perform full initialization
    NSLog(@"Performing full initialization...");
    self=[super init];
    if (!self) return nil;
    
    //load palettes
    pallet=[[U7Palette alloc]init];
    transparencyPallet=[[U7Palette alloc]init];
    [self loadPaletes];
  
    //Load shapes in parallel - they're independent of each other
    dispatch_group_t shapeGroup = dispatch_group_create();
    dispatch_queue_t loadQueue = dispatch_queue_create("com.app.assetLoading", DISPATCH_QUEUE_CONCURRENT);
    
    __block NSMutableArray *u7Shapes, *u7SpriteShapes, *u7FaceShapes, *u7GumpShapes, *u7FontShapes;
    
    dispatch_group_async(shapeGroup, loadQueue, ^{
        u7Shapes = [self loadShapes:@"SHAPES" withExtension:@"VGA" hasTiles:YES];
    });
    dispatch_group_async(shapeGroup, loadQueue, ^{
        u7SpriteShapes = [self loadShapes:@"SPRITES" withExtension:@"VGA" hasTiles:NO];
    });
    dispatch_group_async(shapeGroup, loadQueue, ^{
        u7FaceShapes = [self loadShapes:@"FACES" withExtension:@"VGA" hasTiles:NO];
    });
    dispatch_group_async(shapeGroup, loadQueue, ^{
        u7GumpShapes = [self loadShapes:@"GUMPS" withExtension:@"VGA" hasTiles:NO];
    });
    dispatch_group_async(shapeGroup, loadQueue, ^{
        u7FontShapes = [self loadShapes:@"FONTS" withExtension:@"VGA" hasTiles:NO];
    });
    
    dispatch_group_wait(shapeGroup, DISPATCH_TIME_FOREVER);
    
    U7Shapes = u7Shapes;
    U7SpriteShapes = u7SpriteShapes;
    U7FaceShapes = u7FaceShapes;
    U7GumpShapes = u7GumpShapes;
    U7FontShapes = u7FontShapes;
    
    [self loadShapeInfo];
    
    //load Map
    U7Chunks=[[NSMutableArray alloc]init];
    Map =[[U7Map alloc]init];
    Map->environment=self;
    
    [self loadChunks];  //first
    [self loadMap]; //second
    staticShapeRecords=[[NSMutableArray alloc]init];
    [self loadStaticShapeRecords];  //must load map before these
    gameShapeRecords=[[NSMutableArray alloc]init];
    [self loadGameShapeRecords];  //must load map before these
    [self processContainerContents];  //separate container contents from regular items
    [self updateShapeInfo];  //must load map before these
    [self updateChunkInfo];  //must load map before these
    [self createPassabilityMaps];
    [self createEnvironmentMaps];
    
    animationSequences=[self composeAnimationSequences];
    
    // Cache saving disabled
    // dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    //     [self saveToCache];
    // });
    
    return self;
}



#pragma mark PALLETE LOADING

-(void)loadPaletes
{
    
    NSLog(@"Load Paletes");
    NSString* path = [[NSBundle mainBundle] pathForResource:@"PALETTES" ofType:@"FLX"];
    NSData * data=[NSData dataWithContentsOfFile:path];
    
    if(!data)
        
    {
        NSLog(@"Bad Paletes Data");
    }
    else NSLog(@"Good pallete data");
    
    // DEBUG: Will log palette colors after loading
    BOOL shouldLogPalette = YES;
    
    int count=0;
    for (int i = PALLETINDEXVALUE; i <PALLETINDEXVALUE+768; i+=3)
    {
        
        int RedComponent=[self getCharFromNSData:data atByteOffset:i];
        int GreenComponent=[self getCharFromNSData:data atByteOffset:i+1];
        int BlueComponent=[self getCharFromNSData:data atByteOffset:i+2];
        //NSLog(@"%i, %i: RedComponent: %i, BlueComponent: %i, GreenComponent: %i, ",count,i,RedComponent,BlueComponent,GreenComponent);
        U7Color * color=[[U7Color alloc]init];
        U7Color * transparencyColor=[[U7Color alloc]init];
        color->red=RedComponent;
        color->blue=BlueComponent;
        color->green=GreenComponent;
        transparencyColor->red=RedComponent;
        transparencyColor->blue=BlueComponent;
        transparencyColor->green=GreenComponent;
        
        // Set alpha values
        if(count >= 224 && count <= 254)
        {
            // Indices 224-254: In transparency palette, use alpha 0.25
            color->alpha = 1.0;  // Normal palette: opaque
            transparencyColor->alpha = 0.25;  // Transparency palette: 25% opacity
        }
        else if(count == 255)
        {
            // Index 255: Fully transparent in both palettes
            color->alpha = 0;
            transparencyColor->alpha = 0;
        }
        else
        {
            // Indices 0-223: Normal alpha behavior
            color->alpha = 1.0;  // Normal palette: opaque
            transparencyColor->alpha = 0.5;  // Transparency palette: 50% opacity
        }
        
        // Special color handling for index 254 in normal palette
        if(count==254)
        {
            color->red=0.999*COLORLENGTH;
            color->blue=0.999*COLORLENGTH;
            color->green=1*COLORLENGTH;
            color->alpha=0.266;
        }
        // Special color handling for index 255 in both palettes
        if(count==255)
        {
            color->red=0.999*COLORLENGTH;
            color->blue=0.999*COLORLENGTH;
            color->green=1*COLORLENGTH;
            
            transparencyColor->red=0.999*COLORLENGTH;
            transparencyColor->blue=0.999*COLORLENGTH;
            transparencyColor->green=1*COLORLENGTH;
        }
        [pallet->colors addObject:color];
        [transparencyPallet->colors addObject:transparencyColor];
        count++;
    }
    
    // Special handling ONLY for transparency palette index 254
    // This pixel index gets a special semi-transparent white color when rendering translucent shapes
    U7Color * color254 = [transparencyPallet->colors objectAtIndex:254];
    color254->red = 0.999 * COLORLENGTH;
    color254->green = 0.999 * COLORLENGTH;
    color254->blue = 1 * COLORLENGTH;
    color254->alpha = 0.266;
    
    NSLog(@"Transparency palette index 254 set to: RGB=(255,255,255) alpha=0.266");
    
    // DEBUG: Log palette colors in the cycling range
    if(shouldLogPalette) {
        NSLog(@"=== PALETTE COLORS (indices 224-254) ===");
        for(int idx = 224; idx <= 254; idx++) {
            U7Color *c = [pallet->colors objectAtIndex:idx];
            int r = (int)(c->red / 63.0 * 255);
            int g = (int)(c->green / 63.0 * 255);
            int b = (int)(c->blue / 63.0 * 255);
            NSLog(@"  Index %d: RGB=(%3d,%3d,%3d) raw=(%2d,%2d,%2d)",
                  idx, r, g, b, (int)c->red, (int)c->green, (int)c->blue);
        }
    }
    
   
    //NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
}

#pragma mark SHAPE CREATION

-(NSMutableArray *)loadShapes:(NSString*)name withExtension:(NSString*)extension hasTiles:(BOOL)tiles
{
    NSMutableArray * shapes=NULL;
    NSMutableArray * records=[self loadShapeRecords:name withExtension:extension hasTiles:tiles];
    if(records)
    {
        shapes=[self createShapesFromRecords:records forFilename:name withExtentsion:extension];
    }
    return shapes;
}

-(NSMutableArray*)loadShapeRecords:(NSString*)name withExtension:(NSString*)extension hasTiles:(BOOL)tiles
{
    NSLog(@"loadShapeRecords: %@.%@",name,extension);
    NSMutableArray* theRecords=[[NSMutableArray alloc]init];
    NSString* path = [[NSBundle mainBundle] pathForResource:name ofType:extension];
    NSData * data=[NSData dataWithContentsOfFile:path];
    if(data)
    {
        NSLog(@"Good Data! Length: %lu",[data length]);
        UInt32 records=[self getUint32FromNSData:data atByteOffset:84];
        NSLog(@"records: %u",records);
        UInt32 index=128;
        for (UInt32 i=0; i <records; i++)
        {
            UInt32 offset=[self getUint32FromNSData:data atByteOffset:index];
            index+=4;
            UInt32 length=[self getUint32FromNSData:data atByteOffset:index];
            index+=4;
            U7ShapeRecord * shapeRecord=[[U7ShapeRecord alloc]init];
            shapeRecord->length=length;
            shapeRecord->offset=offset;
            if(tiles&&i<150)
            {
                shapeRecord->tile=YES;
            }
            [theRecords addObject:shapeRecord];
        }
    }
    else
        NSLog(@"Bad Data");
    return theRecords;
}

-(NSMutableArray*)createShapesFromRecords:(NSMutableArray*)records forFilename:(NSString*) fileName withExtentsion:(NSString*)extension
{
    NSMutableArray * shapes=[[NSMutableArray alloc]init];
    
    for(int i=0;i<[records count];i++)
    {
        //U7ShapeRecord * record=[shapeRecords objectAtIndex:i];
        U7Shape * shape=[[U7Shape alloc]init];
        [shapes addObject:shape];
    }
    NSLog(@"number of shapes:%li",[shapes count]);
    
    NSString* path = [[NSBundle mainBundle] pathForResource:fileName ofType:extension];
    NSData * data=[NSData dataWithContentsOfFile:path];
    if(!records)
        return NULL;
    if(!data)
        return NULL;
    NSLog(@"Good Data! Length: %lu",[data length]);
    
    for(int i=0;i<[shapes count];i++)
    {
        U7ShapeRecord * record=[records objectAtIndex:i];
        U7Shape * shape=[shapes objectAtIndex:i];
        if(!record->tile)
        {
            //NSLog(@"Record: %i",i);
            [self loadShape:data atOffset:record->offset forLength:record->length forShape:shape];
            if(shape)
            {

            }
            else
            {
                NSLog(@"Bad Shape");
            }
        }
        else if(record->tile)
        {
            [self loadTile:data forRecord:(record) forShape:shape];
        }
    }

    NSLog(@"NumberOfShapes: %li",[U7Shapes count]);
    
    
    
    
    return shapes;
}

-(void)loadShapeInfo
{
    NSLog(@"* loadShapeInfo");
    if(!U7Shapes)
    {
        return;
    }
    NSString* path = [[NSBundle mainBundle] pathForResource:@"TFA" ofType:@"DAT"];
    NSData * data=[NSData dataWithContentsOfFile:path];
    UInt32 index=0;
    if(!data)
    {
        return;
    }
    for(int count=0;count<[U7Shapes count];count++)
    {
        U7Shape * shape=[U7Shapes objectAtIndex:count];
        
        UInt32 bitfield=[self getUint32FromNSData:data atByteOffset:index];
        index+=3;
        //bit 0 mystery
        //bit 1 rotation
        UInt32 rotatable=0x00000000;
        rotatable=rotatable+(bitfield<<30);
        rotatable=rotatable>>31;
        
        shape->rotatable=rotatable;
        
        //bit 2 animated
        UInt32 animated=0x00000000;
        animated=animated+(bitfield<<29);
        animated=animated>>31;
        shape->animated=animated;
        //bit 3 animated
        UInt32 NotWalkable=0x00000000;
        NotWalkable=NotWalkable+(bitfield<<28);
        NotWalkable=NotWalkable>>31;
        shape->notWalkable=NotWalkable;
        //bit 4 Water
        UInt32 Water=0x00000000;
        Water=Water+(bitfield<<27);
        Water=Water>>31;
        shape->water=Water;
        //NSLog(@"animated: %i",shape->animated);
        //bit 5 - 7 tileSizeZ (3 bits)
        UInt32 tileSizeZ=0x00000000;
        tileSizeZ=tileSizeZ+(bitfield<<24);
        tileSizeZ=tileSizeZ>>29;
        shape->tileSizeZ=tileSizeZ;
        
        //bit 8 - 11 ShapeType (4 bits)
        UInt32 ShapeType=0x00000000;
        ShapeType=ShapeType+(bitfield<<20);
        ShapeType=ShapeType>>28;
        shape->shapeType=ShapeType;
        //bit 12 Trap
        UInt32 Trap=0x00000000;
        Trap=Trap+(bitfield<<19);
        Trap=Trap>>31;
        shape->trap=Trap;
        //bit 13 Door
        UInt32 Door=0x00000000;
        Door=Door+(bitfield<<18);
        Door=Door>>31;
        shape->door=Door;
        //bit 14 VehiclePart
        UInt32 VehiclePart=0x00000000;
        VehiclePart=VehiclePart+(bitfield<<17);
        VehiclePart=VehiclePart>>31;
        shape->vehiclePart=VehiclePart;
        //bit 15 NotSelectable
        UInt32 NotSelectable=0x00000000;
        NotSelectable=NotSelectable+(bitfield<<16);
        NotSelectable=NotSelectable>>31;
        shape->selectable=NotSelectable;
        //bit 16 TileSizeXMinus1 (3 bits)
        UInt32 TileSizeXMinus1=0x00000000;
        TileSizeXMinus1=TileSizeXMinus1+(bitfield<<13);
        TileSizeXMinus1=TileSizeXMinus1>>29;
        shape->TileSizeXMinus1=TileSizeXMinus1;
        //bit 19 TileSizeYMinus1 (3 bits)
        UInt32 TileSizeYMinus1=0x00000000;
        TileSizeYMinus1=TileSizeYMinus1+(bitfield<<10);
        TileSizeYMinus1=TileSizeYMinus1>>29;
        shape->TileSizeYMinus1=TileSizeYMinus1;
        //bit 22 LightSource
        UInt32 LightSource=0x00000000;
        LightSource=LightSource+(bitfield<<9);
        LightSource=LightSource>>31;
        shape->lightSource=LightSource;
        //bit 23 NotSelectable
        UInt32 Translucent=0x00000000;
        Translucent=Translucent+(bitfield<<8);
        Translucent=Translucent>>31;
        shape->translucent=Translucent;
        
        // DEBUG: Specifically log shape 667's bitfield and all flags
        if(count == 667) {
            NSLog(@"=== SHAPE 667 BITFIELD ANALYSIS ===");
            NSLog(@"  Shape index: %d", count);
            NSLog(@"  Raw bitfield: 0x%08X", bitfield);
            NSLog(@"  Translucent (bit 23, shift<<8>>31): %d", Translucent);
            NSLog(@"  LightSource (bit 22): %d", shape->lightSource);
            NSLog(@"  Tile: %d *** IS THIS A TILE? ***", shape->tile);
            NSLog(@"  Animated: %d", shape->animated);
            NSLog(@"  Number of frames: %ld", [shape->frames count]);
            
            // Try adjacent bit positions to see if translucent is elsewhere
            UInt32 bit21 = (bitfield << 10) >> 31;
            UInt32 bit22 = (bitfield << 9) >> 31;
            UInt32 bit24 = (bitfield << 7) >> 31;
            UInt32 bit25 = (bitfield << 6) >> 31;
            NSLog(@"  Bit 21: %d, Bit 22: %d, Bit 24: %d, Bit 25: %d", bit21, bit22, bit24, bit25);
        }
        
        // DEBUG: Log translucent shapes
        static int translucentShapeCount = 0;
        if(Translucent) {
            translucentShapeCount++;
            if(translucentShapeCount <= 5) {
                NSLog(@"*** Shape with translucent=YES loaded (count=%d, shapeType=%d)",
                      translucentShapeCount, ShapeType);
            }
        }
        
        // DEBUG: Specifically log shape 667
        if(ShapeType == 667) {
            NSLog(@"*** SHAPE 667 LOADED: translucent=%d, bitfield=0x%08X",
                  Translucent, bitfield);
        }
    }
}


#pragma mark GRAPHIC UTILS

-(void)loadTile:(NSData*)data forRecord:(U7ShapeRecord*)record forShape:(U7Shape*)shape
{

    int numberOfTiles=(record->length)/64;
    //NSLog(@"Number of Tiles: %i",numberOfTiles);
    shape->numberOfFrames=numberOfTiles;
    shape->tile=YES;
    
    // DEBUG: Log tile loading with translucency info
    NSLog(@"*** loadTile called: shape->translucent=%d", shape->translucent);
    
    NSMutableArray * pixelArray=[[NSMutableArray alloc]init];
    
    for(int x=0;x<numberOfTiles;x++)
    {
        U7Bitmap * bitmap=[[U7Bitmap alloc]init];
        
        // FIX: Set useTransparency for tiles too!
        bitmap->useTransparency = shape->translucent;
        
        [pixelArray removeAllObjects];
        for(int y=0;y<64;y++)
        {
            unsigned char pixel=[self getCharFromNSData:data atByteOffset:record->offset+y+(x*64)];
            //printf("%i,", pixel);
            if(pixel>=224)
            {
                pixel=[self cyclePixel:pixel forCycle:0 forMaxCycles:bitmap->palletCycles forBitmap:bitmap];
            }
            NSNumber *
            pixelNumber=[NSNumber numberWithUnsignedChar:pixel];
            [pixelArray addObject:pixelNumber];
            //index++;
        }
        //printf("\n");
        
        NSMutableArray * tileBitmap=[pixelArray mutableCopy];
        [bitmap->bitmaps addObject:tileBitmap];
        //bitmap->bitmap=[pixelArray mutableCopy];
        bitmap->width=TILESIZE;
        bitmap->height=TILESIZE;
        
        U7Palette * thePallet=pallet;
        
        if(bitmap->useTransparency)
        {
            thePallet=transparencyPallet;
        }
        
        CGImageRef imageRef=[self createImageForBitmap:pixelArray forWidth:bitmap->width forHeight:bitmap->height forPallet:thePallet];
        NSValue *cgImageValue = [NSValue valueWithBytes:&imageRef objCType:@encode(CGImageRef)];
        [bitmap->CGImages addObject:cgImageValue];
        
        //bitmap->CGImage=[self createImageForBitmap:pixelArray forWidth:TILESIZE forHeight:TILESIZE forPallet:thePallet];
        bitmap->image=[[UIImage alloc] initWithCGImage:imageRef];
        
        
        
        if(bitmap->palletCycles)
        {
            //NSLog(@"palletCycles:%i",bitmap->palletCycles);
            for(int bcount=1;bcount<bitmap->palletCycles;bcount++)
            {
                
                [pixelArray removeAllObjects];
                for(int y=0;y<64;y++)
                {
                    unsigned char pixel=[self getCharFromNSData:data atByteOffset:record->offset+y+(x*64)];
                    //printf("%i,", pixel);
                    if(pixel>=224)
                    {
                        pixel=[self cyclePixel:pixel forCycle:bcount forMaxCycles:bitmap->palletCycles forBitmap:bitmap];
                    }
                    NSNumber *
                    pixelNumber=[NSNumber numberWithUnsignedChar:pixel];
                    [pixelArray addObject:pixelNumber];
                    //index++;
                }
                //printf("\n");
                
                NSMutableArray * tileBitmap=[pixelArray mutableCopy];
                [bitmap->bitmaps addObject:tileBitmap];
                //bitmap->bitmap=[pixelArray mutableCopy];
                bitmap->width=TILESIZE;
                bitmap->height=TILESIZE;
                
                U7Palette * thePallet=pallet;
                
                if(bitmap->useTransparency)
                {
                    thePallet=transparencyPallet;
                }
                
                CGImageRef imageRef=[self createImageForBitmap:pixelArray forWidth:bitmap->width forHeight:bitmap->height forPallet:thePallet];
                NSValue *cgImageValue = [NSValue valueWithBytes:&imageRef objCType:@encode(CGImageRef)];
                [bitmap->CGImages addObject:cgImageValue];
                
                //bitmap->CGImage=[self createImageForBitmap:pixelArray forWidth:TILESIZE forHeight:TILESIZE forPallet:thePallet];
                bitmap->image=[[UIImage alloc] initWithCGImage:imageRef];
                
            }
           
        }
        [shape->frames addObject:bitmap];
    }

}

-(void)loadShape:(NSData*)data atOffset:(UInt32)offset forLength:(UInt32)length forShape:(U7Shape*)shape
{
   
    //U7Shape * shape=[[U7Shape alloc]init];
    UInt32 size=0;
    UInt32 headerLength=0;
    UInt32 frameCount=0;
    UInt32 index=0;
    if(data)
    {
        index=offset;
        //NSLog(@"Start of RLE");
        //NSLog(@"Offset: %i, length: %i",RLEIndex,length);
        //NSLog(@"** loadShape at %li",offset);
        size=[self getUint32FromNSData:data atByteOffset:offset];
        //NSLog(@"Size: %u",size);
        index+=4;
        //NSLog(@"Start Of Frame Info: %u",index);
        headerLength=[self getUint32FromNSData:data atByteOffset:index];
        //NSLog(@"size: %u headerLength: %u shapeEnd: %u",size,headerLength,offset+size);
        if(size==length)
       {
           UInt32 FrameOffset=0;
           //NSLog(@"RLE!");
           frameCount=(headerLength-4)/4;
           //NSLog(@"frameCount: %u",frameCount);
           for(int frameNumber=0;frameNumber<frameCount;frameNumber++)
           {
               
               U7Bitmap * bitmap=[[U7Bitmap alloc]init];
               bitmap->useTransparency=shape->translucent;
               
               // DEBUG: Log ALL translucent bitmaps
               static int translucentBitmapCount = 0;
               if(bitmap->useTransparency) {
                   translucentBitmapCount++;
                   if(translucentBitmapCount <= 20) {
                       NSLog(@"*** Creating translucent bitmap #%d (shape->translucent=%d)",
                             translucentBitmapCount, shape->translucent);
                   }
               }
               
               FrameOffset=[self getUint32FromNSData:data atByteOffset:index];
               index+=4;
               //NSLog(@"FrameOffset: %u, Total Offset: %u",FrameOffset,FrameOffset+offset);
               [self decodeU7ShapeRLE:data atOffset:FrameOffset+offset forBitmap:bitmap];
               [shape->frames addObject:bitmap];
           }
       }
       
    }
}

-(U7Bitmap*)decodeU7ShapeRLE:(NSData*)data atOffset:(long)offset forBitmap:(U7Bitmap*)bitmap
{
    //NSLog(@"*** decodeU7ShapeRLE at %li",offset);
    
    NSMutableArray * thebitmap=[[NSMutableArray alloc]init];
    long index=offset;
    
    UInt16 MaxX=[self getUint16FromNSData:data atByteOffset:index];
    index+=2;
    UInt16 OffsetX=[self getUint16FromNSData:data atByteOffset:index];
    index+=2;
    UInt16 OffsetY=[self getUint16FromNSData:data atByteOffset:index];
    index+=2;
    UInt16 MaxY=[self getUint16FromNSData:data atByteOffset:index];
    index+=2;
    
    //error control
    if(MaxX>1000)
        MaxX=0;
    if(MaxY>1000)
        MaxY=0;
    
    bitmap->width=(MaxX+OffsetX+1);
    bitmap->height=(MaxY+OffsetY+1);
    
    bitmap->rightX=MaxX;
    bitmap->leftX=OffsetX;
    bitmap->bottomY=MaxY;
    bitmap->topY=OffsetY;
    //[bitmap dump];
    if(bitmap->width>1000)
        bitmap->width=0;
    
    if(bitmap->height>1000)
        bitmap->height=0;
    //NSLog(@" MaxX: %u, OffsetX: %u, OffsetY: %u, MaxY: %u",MaxX,OffsetX,OffsetY,MaxY);
    
    //NSLog(@" Width: %u, Height: %u",(MaxX+OffsetX+1),(MaxY+OffsetY+1));
    
    //fill bitmap with black for now - transparent in future?
    NSMutableArray * pixelArray=[[NSMutableArray alloc]init];
    for(int count=0;count<(bitmap->width)*(bitmap->height);count++)
    {
        NSNumber * pixelNumber=[NSNumber numberWithUnsignedChar:255];
        [pixelArray addObject:pixelNumber];
    }
    //bitmap->bitmap=[pixelArray mutableCopy];
    thebitmap = [NSMutableArray arrayWithArray: pixelArray];
    [bitmap->bitmaps addObject:thebitmap];
    //NSLog(@"Starting RLE Decode at: %li",index);
    BOOL finished=NO;
    int count=0;
    int total=0;
    while(!finished)
    {
    long spanLength=[self decodeU7RLESpan:data atOffset:index forBitmap:bitmap forPalletCycle:0];
    index+=spanLength;
    count++;
    total+=spanLength;
    if(!spanLength)
        finished=YES;
    }
    
    U7Palette * thePallet=pallet;
    if(bitmap->useTransparency)
    {
        thePallet=transparencyPallet;
        NSLog(@"*** USING TRANSPARENCY PALETTE for bitmap");
    }
    else
    {
        static int normalPaletteCount = 0;
        normalPaletteCount++;
        if(normalPaletteCount <= 5 || normalPaletteCount % 1000 == 0) {
            NSLog(@"Using normal palette for bitmap #%d", normalPaletteCount);
        }
    }
    
    CGImageRef imageRef=[self createImageForBitmap:thebitmap forWidth:bitmap->width forHeight:bitmap->height forPallet:thePallet];
    NSValue *cgImageValue = [NSValue valueWithBytes:&imageRef objCType:@encode(CGImageRef)];
    [bitmap->CGImages addObject:cgImageValue];
   // bitmap->CGImage=[self createImageForBitmap:thebitmap forWidth:bitmap->width forHeight:bitmap->height forPallet:thePallet];
    bitmap->image=[[UIImage alloc] initWithCGImage:imageRef];
    //[bitmap->bitmaps addObject:thebitmap];
    
    //now do pallet cycles.  we start at count 1 since we already did the first above
    if(bitmap->palletCycles)
    //if(0)
    {
        //NSLog(@"yes: %i",bitmap->palletCycles);
        for(int bcount=1;bcount<bitmap->palletCycles;bcount++)
        {
            //NSLog(@"%i",bcount);
            NSMutableArray * pixelArray=[[NSMutableArray alloc]init];
            for(int count=0;count<(bitmap->width)*(bitmap->height);count++)
            {
                NSNumber * pixelNumber=[NSNumber numberWithUnsignedChar:255];
                [pixelArray addObject:pixelNumber];
            }
            //bitmap->bitmap=[pixelArray mutableCopy];
            NSMutableArray * thebitmap = [NSMutableArray arrayWithArray: pixelArray];
            [bitmap->bitmaps addObject:thebitmap];
            //NSLog(@"Starting RLE Decode at: %li",index);
            BOOL finished=NO;
            long index=offset+8;
            
            int count=0;
            int total=0;
            while(!finished)
            {
                long spanLength=[self decodeU7RLESpan:data atOffset:index forBitmap:bitmap forPalletCycle:bcount];
                index+=spanLength;
                count++;
                total+=spanLength;
                if(!spanLength)
                    finished=YES;
            }
            
            U7Palette * thePallet=pallet;
            if(bitmap->useTransparency)
            {
                thePallet=transparencyPallet;
            }
            
            CGImageRef imageRef=[self createImageForBitmap:thebitmap forWidth:bitmap->width forHeight:bitmap->height forPallet:thePallet];
            NSValue *cgImageValue = [NSValue valueWithBytes:&imageRef objCType:@encode(CGImageRef)];
            [bitmap->CGImages addObject:cgImageValue];
            //bitmap->CGImage=[self createImageForBitmap:thebitmap forWidth:bitmap->width forHeight:bitmap->height forPallet:thePallet];
            bitmap->image=[[UIImage alloc] initWithCGImage:imageRef];
            //[bitmap->bitmaps addObject:thebitmap];
        }
        
        //NSLog(@"cycle");
    }
   
    
    return bitmap;
}

-(unsigned char)cyclePixel:(unsigned char)pixel forCycle:(int)cycle forMaxCycles:(int)maxCycles forBitmap:(U7Bitmap*)bitmap
{
    int floor=0;
    int newPixel=pixel;
    if(pixel<=231)
    {
        floor=231-7;
        bitmap->palletCycles=8;
        newPixel-=cycle;
        int variance=floor-newPixel;
        if(newPixel<floor)
            newPixel=231-variance;
    }
    
    else if(pixel<=239)
        {
            floor=239-7;
            bitmap->palletCycles=8;
            newPixel-=cycle;
            int variance=floor-newPixel;
            if(newPixel<floor)
                newPixel=239-variance;
        }
    else if(pixel<=243)
        {
            floor=243-3;
            bitmap->palletCycles=4;
            newPixel-=cycle;
            int variance=floor-newPixel;
            if(newPixel<floor)
                newPixel=243-variance;
        }
    else if(pixel<=247)
        {
            floor=247-3;
            bitmap->palletCycles=4;
            newPixel-=cycle;
            int variance=floor-newPixel;
            if(newPixel<floor)
                newPixel=247-variance;
        }
    else if(pixel<=251)
        {
            floor=251-3;
            bitmap->palletCycles=4;
            newPixel-=cycle;
            int variance=floor-newPixel;
            if(newPixel<floor)
                newPixel=251-variance;
        }
            
    else if(pixel<=254)
        {
            floor=254-2;
            bitmap->palletCycles=3;
            newPixel-=cycle;
            int variance=floor-newPixel;
            if(newPixel<floor)
                newPixel=254-variance;
        }
    pixel=newPixel;
    return  pixel;
}


-(long)decodeU7RLESpan:(NSData*)data atOffset:(long)offset forBitmap:(U7Bitmap*)bitmap forPalletCycle:(int)palletCycle
{
    //NSLog(@"**** decodeU7RLESpan at %li",offset);
    NSMutableArray * currentBitmap=[bitmap->bitmaps objectAtIndex:palletCycle];
    int BlockLength=0;
    int BlockType=0;
    long index=offset;
    int bitmapindex=0;
    if(data)
    {
        UInt16 BlockData=[self getUint16FromNSData:data atByteOffset:index];
        index+=2;
        if(BlockData==0)
        {
            //NSLog(@"end");
            return 0;
        }
        BlockLength=BlockData>>1;
        BlockType=BlockData&1;
        SInt16 XStart=[self getSInt16FromNSData:data atByteOffset:index];
        index+=2;
        SInt16 YStart=[self getSInt16FromNSData:data atByteOffset:index];
        index+=2;
        int xPos=[bitmap translateX:XStart];
        int yPos=[bitmap translateY:YStart];
        //int xPos=bitmap->width+XStart-1;
        //int yPos=bitmap->height+YStart-1;
        
        if(BlockType==0)
        {
            //NSLog(@"BlockLength: %i,type: %i, XStart: %i, YStart: %i",BlockLength,BlockType,XStart,YStart);
            for(int count=0;count<BlockLength;count++)
            {
                //NSLog(@"x: %i y: %i",xPos,yPos);
                int dataIndex=((yPos*bitmap->width)+xPos);
                unsigned char pixel=[self getCharFromNSData:data atByteOffset:index];
                if(!bitmap->useTransparency)
                {
                    if(pixel>=224)
                    {
                        pixel=[self cyclePixel:pixel forCycle:palletCycle forMaxCycles:bitmap->palletCycles forBitmap:bitmap];
                    }
                }
                
                NSNumber * pixelNumber=[NSNumber numberWithUnsignedChar:pixel];
                [currentBitmap replaceObjectAtIndex:dataIndex withObject:[pixelNumber copy]];
                index++;
                xPos++;
                //printf("%i,", dataIndex);
                bitmapindex++;
            }
            //printf("\n");
        }
        else
        {
            
            int EndX=XStart+BlockLength;
            
            
            //NSLog(@"BlockLength: %i,type: %i, XStart: %i, YStart: %i,EndX: %i",BlockLength,BlockType,XStart,YStart,EndX);
            
            while (XStart<EndX)
            {
                UInt8 RunData=[self getUint8FromNSData:data atByteOffset:index];
                index+=1;
                int RunLength=RunData>>1;
                int RunType=RunData&1;
                if(RunType==0)
                {
                    //NSLog(@"Raw Image with length of %i at XStart %i",RunLength,XStart);
                    for(int count=0;count<RunLength;count++)
                    {
                        //NSLog(@"x: %i y: %i",xPos,yPos);
                        int dataIndex=((yPos*bitmap->width)+xPos);
                        unsigned char pixel=[self getCharFromNSData:data atByteOffset:index];
                        if(!bitmap->useTransparency)
                        {
                            if(pixel>=224)
                            {
                                pixel=[self cyclePixel:pixel forCycle:palletCycle forMaxCycles:bitmap->palletCycles forBitmap:bitmap];
                            }
                        }
                        NSNumber * pixelNumber=[NSNumber numberWithUnsignedChar:pixel];
                        [currentBitmap replaceObjectAtIndex:dataIndex withObject:[pixelNumber copy]];
                        index++;
                        xPos++;
                        //printf("%i,", dataIndex);
                        bitmapindex++;
                    }
                    //printf("\n");
                }
                else
                {
                    unsigned char pixel=[self getCharFromNSData:data atByteOffset:index];
                    index++;
                    
                    //NSLog(@"Encoded Image with length of %i at XStart %i",RunLength,XStart);
                    for(int count=0;count<RunLength;count++)
                    {
                        //NSLog(@"x: %i y: %i",xPos,yPos);
                        int dataIndex=((yPos*bitmap->width)+xPos);
                        NSNumber * pixelNumber=[NSNumber numberWithUnsignedChar:pixel];
                        [currentBitmap replaceObjectAtIndex:dataIndex withObject:[pixelNumber copy]];
                        //printf("%i,", dataIndex);
                        bitmapindex++;
                        xPos++;
                        
                    }
                    //printf("\n");
                }
                XStart+=RunLength;
            }
        }
        
        /**/
        
       
        
    }
    long total=index-offset;
    //NSLog(@"Total: %li",total);
    return total;
}


    
-(CGImageRef)createImageForBitmap:(NSArray *)bitmap forWidth:(int)width forHeight:(int)height forPallet:(U7Palette*)thePallet
    {
        if(width==0||height==0)
            return NULL;
        
        // DEBUG: Check if using transparency palette
        static int transparencyBitmapCount = 0;
        BOOL isTransparencyPallet = (thePallet == transparencyPallet);
        
        if(isTransparencyPallet) {
            transparencyBitmapCount++;
            if(transparencyBitmapCount <= 3) {
                NSLog(@"*** Creating translucent bitmap #%d (width=%d, height=%d)", transparencyBitmapCount, width, height);
            }
        }
        
        // Use direct pixel buffer manipulation - much faster than CGContextFillRect per pixel
        NSUInteger bytesPerPixel = 4;
        NSUInteger bytesPerRow = bytesPerPixel * width;
        NSUInteger bitsPerComponent = 8;
        
        unsigned char *rawData = (unsigned char *)calloc(height * bytesPerRow, sizeof(unsigned char));
        if (!rawData)
            return NULL;
        
        // Collect pixel index statistics for first translucent bitmap
        NSMutableDictionary *pixelIndexCounts = nil;
        if(isTransparencyPallet && transparencyBitmapCount <= 3) {
            pixelIndexCounts = [[NSMutableDictionary alloc] init];
        }
        
        for(int y=0;y<height;y++)
        {
            for(int x=0;x<width;x++)
            {
                int paletteIndex=[[bitmap objectAtIndex:(y*width)+x ]intValue];
                
                // Count pixel indices
                if(pixelIndexCounts) {
                    NSNumber *key = @(paletteIndex);
                    NSNumber *count = pixelIndexCounts[key];
                    pixelIndexCounts[key] = @(count ? count.intValue + 1 : 1);
                }
                
                U7Color * color=[thePallet->colors objectAtIndex:paletteIndex];
                
                // Flip Y coordinate to match UIKit coordinate system
                int flippedY = (height - 1) - y;
                NSUInteger byteIndex = (bytesPerRow * flippedY) + (x * bytesPerPixel);
                
                // ARGB format for kCGImageAlphaPremultipliedFirst
                unsigned char alpha = (unsigned char)([color alphaValue] * 255);
                unsigned char red = (unsigned char)([color redValue] * 255);
                unsigned char green = (unsigned char)([color greenValue] * 255);
                unsigned char blue = (unsigned char)([color blueValue] * 255);
                
                // Premultiply alpha
                rawData[byteIndex] = alpha;
                rawData[byteIndex + 1] = (unsigned char)((red * alpha) / 255);
                rawData[byteIndex + 2] = (unsigned char)((green * alpha) / 255);
                rawData[byteIndex + 3] = (unsigned char)((blue * alpha) / 255);
            }
        }
        
        // Log pixel statistics
        if(pixelIndexCounts) {
            NSLog(@"=== TRANSLUCENT BITMAP #%d PIXEL INDICES ===", transparencyBitmapCount);
            NSArray *sortedKeys = [[pixelIndexCounts allKeys] sortedArrayUsingSelector:@selector(compare:)];
            for(NSNumber *key in sortedKeys) {
                int idx = key.intValue;
                int count = [pixelIndexCounts[key] intValue];
                U7Color *color = [thePallet->colors objectAtIndex:idx];
                int r = (int)(color->red / 63.0 * 255);
                int g = (int)(color->green / 63.0 * 255);
                int b = (int)(color->blue / 63.0 * 255);
                NSLog(@"  Palette index %d: %d pixels, RGB=(%d,%d,%d) alpha=%.2f",
                      idx, count, r, g, b, color->alpha);
            }
        }
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(rawData, width, height,
                                                  bitsPerComponent, bytesPerRow, colorSpace,
                                                  kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Big);
        
        CGImageRef cgimage = CGBitmapContextCreateImage(ctx);
        
        CGContextRelease(ctx);
        CGColorSpaceRelease(colorSpace);
        free(rawData);
        
        if(cgimage)
            return cgimage;
        return NULL;
    }

-(U7Chunk*)chunkForID:(int)theID
{
    if([U7Chunks count])
    {
        return [U7Chunks objectAtIndex:theID];
    }
    return NULL;;
}


#pragma mark MAP CREATION

-(void)loadChunks
{
    NSLog(@"loadChunks");
    NSString* path = [[NSBundle mainBundle] pathForResource:@"U7CHUNKS" ofType:@""];
    NSData * data=[NSData dataWithContentsOfFile:path];
    if(data)
    {
        NSLog(@"Good Data");
        
        
        unsigned long numberOfChunks=[data length]/512;
        NSLog(@"numberOfChunks: %li",numberOfChunks);
        unsigned long index=0;
        //unsigned long index=1446*512;
        //for(int i=0;i<1;i++)
        for(int i=0;i<numberOfChunks;i++)
        {
            //if(i==566)NSLog(@"Chunk: %i index:%lu",i,index);
            U7Chunk * chunk=[[U7Chunk alloc]init];
            for(int tileIndex=0;tileIndex<256;tileIndex++)
            {
                //get shape number
             
                UInt16 shapeWord=[self getUint16FromNSData:data atByteOffset:index];
                
                UInt16 shapeReference=0x0000;
                shapeReference=shapeReference+(shapeWord<<6);
                shapeReference=shapeReference>>6;;
                
                UInt16 frame=0x0000;
                frame=frame+(shapeWord<<1);
                frame=frame>>11;
                
                
                U7ChunkIndex * chunkIndex=[[U7ChunkIndex alloc]init];
                chunkIndex->frameIndex=frame;
                chunkIndex->shapeIndex=shapeReference;
                
                [chunk->chunkMap addObject:chunkIndex];
                index+=2;
               
                
            }
            [chunk setEnvironment:self];
            [U7Chunks addObject:chunk];
        }
        
    }
    else
        NSLog(@"Bad Data");
    //NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
}

-(void)loadMap
{
    NSLog(@"loadMap");
    NSString* path = [[NSBundle mainBundle] pathForResource:@"U7MAP" ofType:@""];
    NSData * data=[NSData dataWithContentsOfFile:path];
    if(data)
    {
       // NSLog(@"Good Data");
        //unsigned long numberOfChunks=[data length]/2;
        //NSLog(@"numberOfChunks: %li",numberOfChunks);
        for(int mapy=0;mapy<TOTALMAPSIZE;mapy++)
        {
            for(int mapx=0;mapx<TOTALMAPSIZE;mapx++)
            {
                int chunkID=[self chunkIDForMapAddress:data forChunkX:mapx forChunkY:mapy];
                U7MapChunk * mapChunk=[[U7MapChunk alloc]init];
                mapChunk->masterChunkID=chunkID;
                mapChunk->masterChunk=[U7Chunks objectAtIndex:chunkID];
                mapChunk->flatChunkID=mapx+(mapy*TOTALMAPSIZE);
                [mapChunk setEnvironment:self];
                //NSNumber * chunkIDNum=[NSNumber numberWithInt:chunkID];
                [Map->map addObject:mapChunk];
            }
            //printf("\n");
            
        }
      
        
        //NSLog(@"Map Size: %li",[Map->map count]);
        
        
    }
    else
        NSLog(@"Bad Data");
    //NSString* content = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
    NSLog(@"done");
}


-(void)updateShapeInfo
{
    NSLog(@"updateShapeInfo");
    for(int y=0;y<TOTALMAPSIZE;y++)
    {
        for(int x=0;x<TOTALMAPSIZE;x++)
        {
          
        U7MapChunk * mapChunk=[self->Map->map objectAtIndex:(y*TOTALMAPSIZE)+x];
        [mapChunk updateShapeInfo:self];
        //[mapChunk dump];
            
           
        }
    }
    NSLog(@"done");
    //printf("\n");
}

-(void)updateChunkInfo
{
    NSLog(@"updateChunkInfo");
    dispatch_apply([U7Chunks count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(size_t count) {
        U7Chunk * chunk = [U7Chunks objectAtIndex:count];
        [chunk createTileImage];
    });
    NSLog(@"done");
    //printf("\n");
}

-(void)createPassabilityMaps
{
    [Map createPassabilityMaps];
}

-(void)createEnvironmentMaps
{
    [Map createEnvironmentMaps];
}

-(void)loadStaticShapeRecords
{
    NSLog(@"* loadStaticShapeRecords");

    for(int count=0;count<(MAPSIZE*MAPSIZE);count++)
    {
        //NSLog(@"hex:%@",[NSString stringWithFormat:@"U7IFIX%02X",count]);
        NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"U7IFIX%02X",count] ofType:@""];
        NSMutableArray * shapes=[[NSMutableArray alloc]init];
        NSData * data=[NSData dataWithContentsOfFile:path];
        if(data)
        {
            //NSLog(@"%@ Good Data! Length: %lu",path,[data length]);
            UInt32 records=[self getUint32FromNSData:data atByteOffset:84];
            //NSLog(@"records: %u",records);
            
            UInt32 index=128;
            int superchunkY=count/MAPSIZE;
            int superchunkX=count-(superchunkY*MAPSIZE);
            int mapX=superchunkX*16;
            int mapY=superchunkY*16;
            //NSLog(@"mapX:%i mapY:%i",mapX,mapY);
            for (UInt32 i=0; i <records; i++)
            {
                int yOffset=i/SUPERCHUNKSIZE;
                int xOffset=i-(yOffset*SUPERCHUNKSIZE);
                int newMapX=mapX+xOffset;
                int newMapY=mapY+yOffset;
                int flatMap=(newMapY*CHUNKSIZE*MAPSIZE)+newMapX;
                //NSLog(@"index: %i xOffset: %i yOffset: %i newMapX:%i newMapY:%i flatMap:%i",i,xOffset,yOffset,newMapX,newMapY,flatMap);
                UInt32 offset=[self getUint32FromNSData:data atByteOffset:index];
                index+=4;
                UInt32 length=[self getUint32FromNSData:data atByteOffset:index];
                index+=4;
                U7ShapeRecord * shapeRecord=[[U7ShapeRecord alloc]init];
                shapeRecord->length=length;
                shapeRecord->offset=offset;
                shapeRecord->flatLocation=flatMap;
                
                //[shapeRecord dump];
                if(offset)
                    [shapes addObject:shapeRecord];
            }
        }
        //NSLog(@"Count: %li",[shapes count]);
        for(int rec=0;rec<[shapes count];rec++)
        {
            U7ShapeRecord * theRecord=[shapes objectAtIndex:rec];
            U7MapChunk * mapChunk=[Map->map objectAtIndex:theRecord->flatLocation];
            mapChunk->staticItems=[[self shapeReferencesForChunk:data forShapeRecord:theRecord]mutableCopy];
        }
    }
}

-(void)loadGameShapeRecords
{
    NSLog(@"* loadGameShapeRecords");
    
    //int count=68;
    for(int count=0;count<(MAPSIZE*MAPSIZE);count++)
    {
        //NSLog(@"hex:%@",[NSString stringWithFormat:@"U7IFIX%02X",count]);
        NSString* path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"U7IREG%02X",count] ofType:@""];
        //NSLog(@"%@",path);
        //NSMutableArray * shapes=[[NSMutableArray alloc]init];
        NSData * data=[NSData dataWithContentsOfFile:path];
        long index=0;
        if(data)
        {
            //NSLog(@"%@ Good Data! Length: %lu",path,[data length]);
            int superchunkY=count/MAPSIZE;
            int superchunkX=count-(superchunkY*MAPSIZE);
            int mapX=superchunkX*16;
            int mapY=superchunkY*16;
            //NSLog(@"mapX:%i mapY:%i %i",mapX,mapY,mapX+(mapY*MAPSIZE*SUPERCHUNKSIZE));
            
            //int chunkIndex=0;
            //while(chunkIndex<(SUPERCHUNKSIZE*SUPERCHUNKSIZE))
            while(index<[data length])
            {
                int type=[self getUint8FromNSData:data atByteOffset:index];
                index++;
                if(type==0)
                {
                    
                    //NSLog(@"index:%li empty",index);
                }
                else if(type==18)
                {
                    // Type 18 (0x12) format: "extra" format for spellbooks
                    // Format: 12, XY, shapeID, extradata (14 bytes)
                    // extradata = circle1..circle5, lift, circle6..circle9, flags(4)
                    // Total: 1 + 2 + 2 + 14 = 19 bytes
                    
                    // Check we have enough data for the full spellbook format
                    if(index + 18 > [data length])
                    {
                        NSLog(@"WARNING: Not enough data for type 18 (spellbook) at index %li in file %d", index-1, count);
                        break;
                    }
                    
                    // Read position
                    UInt8 xLoc=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 ChunkX=0x00;
                    ChunkX=ChunkX+(xLoc<<4);
                    ChunkX=ChunkX>>4;
                    UInt8 ChunkXLoc=0x00;
                    ChunkXLoc=ChunkXLoc+(xLoc>>4);
                    
                    index++;  // 1
                    
                    UInt8 yLoc=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 ChunkY=0x00;
                    ChunkY=ChunkY+(yLoc<<4);
                    ChunkY=ChunkY>>4;
                    UInt8 ChunkYLoc=0x00;
                    ChunkYLoc=ChunkYLoc+(yLoc>>4);
                    
                    index++;  // 2
                    
                    // Read shape (should be 761 for spellbooks)
                    UInt16 shapeWord=[self getUint16FromNSData:data atByteOffset:index];
                    UInt16 shapeReference=0x0000;
                    shapeReference=shapeReference+(shapeWord<<6);
                    shapeReference=shapeReference>>6;
                    UInt16 frame=0x0000;
                    frame=frame+(shapeWord<<1);
                    frame=frame>>11;
                    
                    index+=2;  // 4
                    
                    // Read spellbook extradata (14 bytes)
                    // circle1..circle5 (5 bytes) - which spells are in the book
                    index+=5;  // 9
                    
                    // lift (1 byte)
                    UInt8 lift=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 zLoc=0x00;
                    zLoc=zLoc+(lift>>4);
                    index+=1;  // 10
                    
                    // circle6..circle9 (4 bytes)
                    index+=4;  // 14
                    
                    // flags (4 bytes) - includes infinite spellbook flag
                    index+=4;  // 18
                    
                    // Validate shapeReference before adding
                    if(shapeReference >= [U7Shapes count])
                    {
                        NSLog(@"WARNING: Invalid shapeID %d (max %li) for type 18 at index %li in file %d",
                              shapeReference, [U7Shapes count]-1, index, count);
                        continue;
                    }
                    
                    // Add the spellbook to the map
                    int trueChunkX=mapX+ChunkXLoc;
                    int trueChunkY=mapY+ChunkYLoc;
                    
                    // Validate chunk coordinates
                    if(trueChunkX < 0 || trueChunkX >= (SUPERCHUNKSIZE*MAPSIZE) ||
                       trueChunkY < 0 || trueChunkY >= (SUPERCHUNKSIZE*MAPSIZE))
                    {
                        NSLog(@"WARNING: Invalid chunk coords (%d,%d) for type 18 in file %d", trueChunkX, trueChunkY, count);
                        continue;
                    }
                    
                    int flatChunkLocation=trueChunkX+(trueChunkY*SUPERCHUNKSIZE*MAPSIZE);
                    
                    if(flatChunkLocation < 0 || flatChunkLocation >= [Map->map count])
                    {
                        NSLog(@"WARNING: flatChunkLocation %d out of bounds (max %li) in file %d",
                              flatChunkLocation, [Map->map count]-1, count);
                        continue;
                    }
                    
                    U7MapChunk * mapChunk=[Map->map objectAtIndex:flatChunkLocation];
                    U7ShapeReference * shapeRef=[[U7ShapeReference alloc]init];
                    shapeRef->lift=zLoc;
                    shapeRef->parentChunkXCoord=ChunkX;
                    shapeRef->parentChunkYCoord=ChunkY;
                    shapeRef->shapeID=shapeReference;
                    shapeRef->GameObject=YES;
                    
                    // Set frame info from actual shape
                    U7Shape *actualShape = [U7Shapes objectAtIndex:shapeReference];
                    shapeRef->numberOfFrames = [actualShape numberOfFrames];
                    shapeRef->animates = actualShape->animated;
                    
                    // Validate and set frame
                    if(frame >= shapeRef->numberOfFrames && shapeRef->numberOfFrames > 0)
                    {
                        shapeRef->frameNumber = 0;
                        shapeRef->currentFrame = 0;
                    }
                    else
                    {
                        shapeRef->frameNumber = frame;
                        shapeRef->currentFrame = shapeRef->animates ? 0 : frame;
                    }
                    
                    [mapChunk->gameItems addObject:shapeRef];
                }
                else if(type==12)
                {
                    //NSLog(@"index:%li Extended",index);
                    // Extended format: 0C, XY, shapeID, type, proba, data1, lift, data2, [content]
                    
                    // Validate we have enough bytes
                    if(index + 12 > [data length])
                    {
                        // Not enough data, abort
                        break;
                    }
                    
                    //x
                    UInt8 xLoc=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 ChunkX=0x00;
                    ChunkX=ChunkX+(xLoc<<4);
                    ChunkX=ChunkX>>4;
                    UInt8 ChunkXLoc=0x00;
                    ChunkXLoc=ChunkXLoc+(xLoc>>4);
                    
                    index++;  //1
                    
                    UInt8 yLoc=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 ChunkY=0x00;
                    ChunkY=ChunkY+(yLoc<<4);
                    ChunkY=ChunkY>>4;
                    UInt8 ChunkYLoc=0x00;
                    ChunkYLoc=ChunkYLoc+(yLoc>>4);
                    
                    index++;  //2
                    
                    UInt16 shapeWord=[self getUint16FromNSData:data atByteOffset:index];
                    
                    //first 10 bits
                    UInt16 shapeReference=0x0000;
                    shapeReference=shapeReference+(shapeWord<<6);
                    shapeReference=shapeReference>>6;
                    
                    //last 6 bits -1 (5 bits before last bit)
                    UInt16 frame=0x0000;
                    frame=frame+(shapeWord<<1);
                    frame=frame>>11;
                    
                    index+=2;  //4 (shapeID is 2 bytes)
                    
                    // type field - referent of first item in container (0000 if empty)
                    UInt16 containerType=[self getUint16FromNSData:data atByteOffset:index];
                    index+=2;  //6
                    
                    // proba
                    index+=1;  //7
                    
                    // data1 (quality, quantity)
                    index+=2;  //9
                    
                    // lift
                    UInt8 lift=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 zLoc=0x00;
                    zLoc=zLoc+(lift>>4);
                    index+=1;  //10
                    
                    // data2 (resist, flags)
                    index+=2;  //12
                    
                    // NOTE: Don't skip container contents - let main loop parse them
                    // The containerType field is just metadata, not a reliable indicator of contents
                    // Container contents will be parsed as normal type 6 objects by the main loop
                    
                    // Validate shapeReference before adding
                    if(shapeReference >= [U7Shapes count])
                    {
                        NSLog(@"WARNING: Invalid shapeID %d (max %li) for type 12 at index %li in file %d",
                              shapeReference, [U7Shapes count]-1, index, count);
                        continue;  // Skip this item
                    }
                    
                    // Add the container itself to the map (not its contents)
                    int trueChunkX=mapX+ChunkXLoc;
                    int trueChunkY=mapY+ChunkYLoc;
                    
                    // Validate chunk coordinates
                    if(trueChunkX < 0 || trueChunkX >= (SUPERCHUNKSIZE*MAPSIZE) ||
                       trueChunkY < 0 || trueChunkY >= (SUPERCHUNKSIZE*MAPSIZE))
                    {
                        NSLog(@"WARNING: Invalid chunk coords (%d,%d) for type 12 in file %d", trueChunkX, trueChunkY, count);
                        continue;
                    }
                    
                    int flatChunkLocation=trueChunkX+(trueChunkY*SUPERCHUNKSIZE*MAPSIZE);
                    
                    if(flatChunkLocation < 0 || flatChunkLocation >= [Map->map count])
                    {
                        NSLog(@"WARNING: flatChunkLocation %d out of bounds (max %li) in file %d",
                              flatChunkLocation, [Map->map count]-1, count);
                        continue;
                    }
                    
                    U7MapChunk * mapChunk=[Map->map objectAtIndex:flatChunkLocation];
                    U7ShapeReference * shapeRef=[[U7ShapeReference alloc]init];
                    shapeRef->lift=zLoc;
                    shapeRef->parentChunkXCoord=ChunkX;
                    shapeRef->parentChunkYCoord=ChunkY;
                    shapeRef->shapeID=shapeReference;
                    shapeRef->GameObject=YES;
                    
                    // Set frame info from actual shape
                    U7Shape *actualShape = [U7Shapes objectAtIndex:shapeReference];
                    shapeRef->numberOfFrames = [actualShape numberOfFrames];
                    shapeRef->animates = actualShape->animated;
                    
                    // Validate and set frame
                    if(frame >= shapeRef->numberOfFrames && shapeRef->numberOfFrames > 0)
                    {
                        NSLog(@"WARNING: Frame %d exceeds max %li for shape %d in type 12",
                              frame, shapeRef->numberOfFrames-1, shapeReference);
                        shapeRef->frameNumber = 0;
                        shapeRef->currentFrame = 0;
                    }
                    else
                    {
                        shapeRef->frameNumber = frame;
                        shapeRef->currentFrame = shapeRef->animates ? 0 : frame;
                    }
                    
                    // Mark as container
                    shapeRef->isContainer = YES;
                    shapeRef->isContainerContent = NO;
                    shapeRef->containerShapeRef = 0;
                    
                    // Add container to gameItems (containers should render)
                    [mapChunk->gameItems addObject:shapeRef];
                }
                else if(type==6)
                {
                    //NSLog(@"index:%li standard",index);
                    
                    // Type 6 format: 06, XY, shapeID (2), lift, quality
                    // Total 6 bytes INCLUDING the type byte we already consumed
                    // So we need 5 more bytes
                    if(index + 5 > [data length])
                    {
                        NSLog(@"WARNING: Not enough data for type 6 at index %li in file %d", index-1, count);
                        break;
                    }
                    
                    //x
                    UInt8 xLoc=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 ChunkX=0x00;
                    ChunkX=ChunkX+(xLoc<<4);
                    ChunkX=ChunkX>>4;
                    UInt8 ChunkXLoc=0x00;
                    ChunkXLoc=ChunkXLoc+(xLoc>>4);
                    
                    index++;  //1
                    
                    
                    UInt8 yLoc=[self getUint8FromNSData:data atByteOffset:index];
                    UInt8 ChunkY=0x00;
                    ChunkY=ChunkY+(yLoc<<4);
                    ChunkY=ChunkY>>4;
                    UInt8 ChunkYLoc=0x00;
                    ChunkYLoc=ChunkYLoc+(yLoc>>4);
                    
                    
                    index++;  //2
                    
                    UInt16 shapeWord=[self getUint16FromNSData:data atByteOffset:index];
                    
                    //first 10 bits
                    UInt16 shapeReference=0x0000;
                    shapeReference=shapeReference+(shapeWord<<6);
                    shapeReference=shapeReference>>6;;
                    
                    //last 6 bits -1 (5 bits before last bit)
                    UInt16 frame=0x0000;
                    frame=frame+(shapeWord<<1);
                    frame=frame>>11;
                    
                    index+=2; //4
                    
                    //last 4 bits gives z
                    UInt8 zLoc=0x00;
                    UInt8 lift=[self getUint8FromNSData:data atByteOffset:index];
                    zLoc=zLoc+(lift>>4);
                    
                    // Check if this is a container content item
                    // Lower 4 bits of lift byte: 6 = inside (container content), 0-3 = outside (normal item)
                    UInt8 insideOutside = lift & 0x0F;  // Get lower 4 bits
                    BOOL isContainerContent = (insideOutside == 6);
                    
                    index+=1; //5
                    
                    // quality byte (we don't use it but need to skip it)
                    index+=1; //6
                    
                    // Validate shapeReference before adding
                    if(shapeReference >= [U7Shapes count])
                    {
                        NSLog(@"WARNING: Invalid shapeID %d (max %li) for type 6 at index %li in file %d",
                              shapeReference, [U7Shapes count]-1, index, count);
                        continue;  // Skip this item
                    }
                    
                    //int flatChunkLocation=mapX+ChunkX+((mapY+ChunkY)*MAPSIZE*SUPERCHUNKSIZE);
                    int trueChunkX=mapX+ChunkXLoc;
                    int trueChunkY=mapY+ChunkYLoc;
                    
                    // Validate chunk coordinates
                    if(trueChunkX < 0 || trueChunkX >= (SUPERCHUNKSIZE*MAPSIZE) ||
                       trueChunkY < 0 || trueChunkY >= (SUPERCHUNKSIZE*MAPSIZE))
                    {
                        NSLog(@"WARNING: Invalid chunk coords (%d,%d) for type 6 in file %d", trueChunkX, trueChunkY, count);
                        continue;
                    }
                    
                    int flatChunkLocation=trueChunkX+(trueChunkY*SUPERCHUNKSIZE*MAPSIZE);
                    
                    if(flatChunkLocation < 0 || flatChunkLocation >= [Map->map count])
                    {
                        NSLog(@"WARNING: flatChunkLocation %d out of bounds (max %li) in file %d",
                              flatChunkLocation, [Map->map count]-1, count);
                        continue;
                    }
                    
                    U7MapChunk * mapChunk=[Map->map objectAtIndex:flatChunkLocation];
                    U7ShapeReference * shapeRef=[[U7ShapeReference alloc]init];
                    shapeRef->lift=zLoc;
                    shapeRef->parentChunkXCoord=ChunkX;
                    shapeRef->parentChunkYCoord=ChunkY;
                    shapeRef->shapeID=shapeReference;
                    shapeRef->GameObject=YES;
                    
                    // Set numberOfFrames and animates from the actual shape
                    U7Shape *actualShape = [U7Shapes objectAtIndex:shapeReference];
                    shapeRef->numberOfFrames = [actualShape numberOfFrames];
                    shapeRef->animates = actualShape->animated;
                    
                    // Validate and set frame
                    if(frame >= shapeRef->numberOfFrames && shapeRef->numberOfFrames > 0)
                    {
                        //NSLog(@"WARNING: Frame %d exceeds max %li for shape %d in type 6",frame, shapeRef->numberOfFrames-1, shapeReference);
                        shapeRef->frameNumber = 0;
                        shapeRef->currentFrame = 0;
                    }
                    else
                    {
                        shapeRef->frameNumber = frame;
                        shapeRef->currentFrame = shapeRef->animates ? 0 : frame;
                    }
                    
                    // Check if this is container content based on lift byte
                    if(isContainerContent) {
                        // Container content - add to containers array, NOT gameItems
                        shapeRef->isContainerContent = YES;
                        
                        if(mapChunk->containers == nil) {
                            mapChunk->containers = [[NSMutableArray alloc] init];
                        }
                        [mapChunk->containers addObject:shapeRef];
                    } else {
                        // Normal item - add to gameItems
                        shapeRef->isContainerContent = NO;
                        [mapChunk->gameItems addObject:shapeRef];
                    }
                    //NSLog(@"Chunk x,y:%u,%u ChunkLoc x,y:%u,%u Shape:%u Frame:%u lift:%u",ChunkX,ChunkY,ChunkXLoc,ChunkYLoc,shapeReference,frame,lift);
                }
            }
        }
    }
}

-(void)processContainerContents
{
    NSLog(@"=== CONTAINER CONTENTS DETECTION ===");
    NSLog(@"Container contents detected by lift byte (lower 4 bits == 6)");
    
    int totalContainers = 0;
    int totalContainerContents = 0;
    int chunksWithContents = 0;
    
    for(U7MapChunk *mapChunk in Map->map)
    {
        if(mapChunk->containers == nil) {
            mapChunk->containers = [[NSMutableArray alloc] init];
        }
        
        // Count containers in gameItems
        for(U7ShapeReference *ref in mapChunk->gameItems) {
            if(ref->isContainer) {
                totalContainers++;
            }
        }
        
        // Count container contents
        int contentsInChunk = (int)[mapChunk->containers count];
        if(contentsInChunk > 0) {
            totalContainerContents += contentsInChunk;
            chunksWithContents++;
        }
    }
    
    NSLog(@"Total containers (type 12): %d", totalContainers);
    NSLog(@"Total container contents (lift & 0x0F == 6): %d", totalContainerContents);
    NSLog(@"Chunks with container contents: %d", chunksWithContents);
    NSLog(@"Container contents are in 'containers' array and will NOT render");
}

#pragma mark UTILITY

-(enum BAEnvironmentType)environmentTypeForShapeID:(long)theShapeID
{
    NSArray * DirtAndRockArray =[NSArray arrayWithObjects:@1,@2,@3,@4,@5,@6,@7,@8,@9,nil];
    long result=indexOfLongInNSArray(theShapeID, DirtAndRockArray);
    if(result>=0)
    {
        return DirtAndRockBAEnvironmentType;
    }
    return NoBAEnvironmentType;
}

-(NSArray*)shapeReferencesForChunk:(NSData*)data forShapeRecord:(U7ShapeRecord*)record
{
    //NSLog(@"* shapeReferencesForChunk at index %u",record->offset);
    NSMutableArray * shapeReferences=[[NSMutableArray alloc]init];
    UInt32 index=record->offset;
    if(data)
    {
        //index=offset;
        int numberOfShapes=record->length/4;
        //NSLog(@"NumberOfShapes:%i",numberOfShapes);
        for(int count=0;count<numberOfShapes;count++)
            {
            UInt16 bitfield=[self getUint16FromNSData:data atByteOffset:index];
            index+=2;
            //first 4 bits
            UInt16 yLoc=0x0000;
            yLoc=yLoc+(bitfield<<12);
            yLoc=yLoc>>12;
            
            //2d 4 bits
            UInt16 xLoc=0x0000;
            xLoc=xLoc+(bitfield<<8);
            xLoc=xLoc>>12;
           
            //3d 4 bits
            UInt16 zLoc=0x0000;
            zLoc=zLoc+(bitfield<<4);
            zLoc=zLoc>>12;
            
            UInt16 shapeWord=[self getUint16FromNSData:data atByteOffset:index];
                index+=2;
            
            //first 10 bits
            UInt16 shapeReference=0x0000;
            shapeReference=shapeReference+(shapeWord<<6);
            shapeReference=shapeReference>>6;;
            
            //last 6 bits -1 (5 bits before last bit)
            UInt16 frame=0x0000;
            frame=frame+(shapeWord<<1);
            frame=frame>>11;
            
            // Validate shapeReference before creating the object
            if(shapeReference >= [U7Shapes count])
            {
                // Invalid shape ID, skip this entry
                continue;
            }
            
            U7ShapeReference * shape=[[U7ShapeReference alloc]init];
            shape->lift=zLoc;
            shape->parentChunkXCoord=xLoc;
            shape->parentChunkYCoord=yLoc;
            shape->frameNumber=frame;
            shape->currentFrame=frame;
            shape->shapeID=shapeReference;
            shape->StaticObject=YES;  // Mark as static object
            
            // Set frame info from actual shape (needed for proper rendering)
            U7Shape *actualShape = [U7Shapes objectAtIndex:shapeReference];
            shape->numberOfFrames = [actualShape numberOfFrames];
            shape->animates = actualShape->animated;
            
            // Validate and adjust frame if needed
            if(frame >= shape->numberOfFrames && shape->numberOfFrames > 0)
            {
                shape->frameNumber = 0;
                shape->currentFrame = 0;
            }
            else
            {
                shape->currentFrame = shape->animates ? 0 : frame;
            }
            
                
            //int unflatY=(record->flatLocation)/(SUPERCHUNKSIZE*MAPSIZE);
            //int unflatX=(record->flatLocation)-(unflatY*SUPERCHUNKSIZE*MAPSIZE);
            //if(unflatY==78)
            
            //NSNumber *chunkID=[Map->map objectAtIndex:record->flatLocation];
            //if([chunkID intValue]==2746)
            //NSLog(@"shapeReference location:%u locX:%i locY:%i shapeID:%u frame:%u offset:%u length:%u bitfield:%u x: %u y:%u z:%u",record->flatLocation,unflatX,unflatY, shape->shapeID,shape->frameNumber, record->offset,record->length,bitfield,xLoc,yLoc,zLoc);
                
                //NSLog(@"ChunkID: %i",[chunkID intValue]);
            [shapeReferences addObject:shape];
            }
    }
   
  
    return shapeReferences;
}

-(UInt16)chunkIDForMapAddress:(NSData *) data forChunkX:(int)x forChunkY:(int)y
{
    UInt16 chunkID=5000;
    
    //long offset=0;
    long index=0;
    
    int xregion=x/CHUNKSIZE;
    int yregion=y/CHUNKSIZE;
    //find start of map region
    int mapRegion=(yregion*MAPSIZE)+xregion;
    int offset=mapRegion*512;
    //if(x==0)
    //printf("mapy:%i x:%i y:%i,\n",y,xregion,yregion); //good!
    
    //now find column and row
    int column=x%16;
    int row=y%16;
    //NSLog(@"column:%i row:%i,",column,row); //good!
    
    //now calculate index
    index=offset+(row*CHUNKSIZE*2)+(column*2);
    
    //now get the data

    chunkID=[self getUint16FromNSData:data atByteOffset:index];
    //if(x==0) printf("%i %u,",offset,chunkID);
    
    
    return chunkID;
}






-(U7MapChunk*)mapChunkForLocation:(CGPoint)theLocation
{
    NSLog(@"mapChunkForLocation: %f,%f",theLocation.x,theLocation.y);
    if(Map)
    {
        return [Map mapChunkForLocation:theLocation];
    }
    return NULL;
}


-(long)numberOfRawChunks
{
    if(U7Chunks)
    {
        long value= [U7Chunks count];
        return value;
    }
    return 0;
}
-(long)numberOfMapChunks

{
    if(Map)
    {
        long value= [Map->map count];
        return value;
    }
    return 0;
}


-(long)numberOfShapes
{
    if(U7Shapes)
    {
        long value= [U7Shapes count];
        return value;
    }
    return 0;
}




-(U7MapChunkCoordinate*)MapChunkCoordinateForGlobalTilePosition:(CGPoint)thePosition
{
    if(Map)
    {
        return [Map MapChunkCoordinateForGlobalTilePosition:thePosition];
    }
    return NULL;
}
-(long)chunkIDForGlobalTileCoordinate:(CGPoint)coordinate
{
    if(Map)
    {
        return [Map chunkIDForGlobalTileCoordinate:coordinate];
    }
    return -1;
}

#pragma mark ANIMATION

-(NSMutableArray*)composeAnimationSequences
{
    NSMutableArray* sequences=[[NSMutableArray alloc]init];
    U7AnimationSequence * sequence=NULL;
    
#pragma mark IDLE
    //IdleNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    sequence->type=IdleNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //IdleSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    sequence->type=IdleSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //IdleEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    sequence->type=IdleEastAnimationSequenceType;
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    [sequences addObject:sequence];
    
    //IdleWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    sequence->type=IdleWestAnimationSequenceType;
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    [sequences addObject:sequence];
    
    
#pragma mark WALK
    //walk North
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StepRightNorth];
    [sequence addFrame:StepLeftNorth];
    sequence->type=WalkNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //walk South
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StepRightSouth];
    [sequence addFrame:StepLeftSouth];
    sequence->type=WalkSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //walk East
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StepRightSouth];
    [sequence addFrame:StepLeftSouth];
    sequence->type=WalkEastAnimationSequenceType;
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    [sequences addObject:sequence];
    
    //walk West
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StepRightNorth];
    [sequence addFrame:StepLeftNorth];
    sequence->type=WalkWestAnimationSequenceType;
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    [sequences addObject:sequence];
    
#pragma mark ATTACK 1H
    //AttackOneHandedNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackOneHandNorthOne];
    [sequence addFrame:AttackOneHandNorthTwo];
    [sequence addFrame:AttackOneHandNorthThree];
    sequence->type=AttackOneHandedNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //AttackOneHandedSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackOneHandSouthOne];
    [sequence addFrame:AttackOneHandSouthTwo];
    [sequence addFrame:AttackOneHandSouthThree];
    sequence->type=AttackOneHandedSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //AttackOneHandedEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackOneHandNorthOne];
    [sequence addFrame:AttackOneHandNorthTwo];
    [sequence addFrame:AttackOneHandNorthThree];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=AttackOneHandedNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //AttackOneHandedWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackOneHandSouthOne];
    [sequence addFrame:AttackOneHandSouthTwo];
    [sequence addFrame:AttackOneHandSouthThree];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=AttackOneHandedSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
#pragma mark ATTACK 2H
    //AttackTwoHandedNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackTwoHandNorthOne];
    [sequence addFrame:AttackTwoHandNorthTwo];
    [sequence addFrame:AttackTwoHandNorthThree];
    sequence->type=AttackTwoHandedNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //AttackTwoHandedSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackTwoHandNSouthOne];
    [sequence addFrame:AttackTwoHandSouthTwo];
    [sequence addFrame:AttackTwoHandSouthThree];
    sequence->type=AttackTwoHandedSouthAnimationSequenceType;
    sequence->infinite=NO;
    [sequences addObject:sequence];
    
    //AttackTwoHandedEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackTwoHandNorthOne];
    [sequence addFrame:AttackTwoHandNorthTwo];
    [sequence addFrame:AttackTwoHandNorthThree];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=AttackTwoHandedEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //AttackTwoHandedWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:AttackTwoHandNSouthOne];
    [sequence addFrame:AttackTwoHandSouthTwo];
    [sequence addFrame:AttackTwoHandSouthThree];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=AttackTwoHandedWestAnimationSequenceType;
    [sequences addObject:sequence];
    
#pragma mark SPECIAL
    //PerformSpecialNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:SpecialNorthOne];
    [sequence addFrame:SpecialNorthTwo];
    sequence->type=PerformSpecialNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //PerformSpecialSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:SpecialSouthOne];
    [sequence addFrame:SpecialSouthTwo];
    sequence->type=PerformSpecialSouthAnimationSequenceType;
    sequence->infinite=NO;
    [sequences addObject:sequence];
    
    //PerformSpecialEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:SpecialNorthOne];
    [sequence addFrame:SpecialNorthTwo];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=PerformSpecialEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //PerformSpecialWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:SpecialSouthOne];
    [sequence addFrame:SpecialSouthTwo];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=PerformSpecialWestAnimationSequenceType;
    [sequences addObject:sequence];
    
#pragma mark BOW
    //BowNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:BowNorth];
    sequence->type=BowNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //BowSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:BowSouth];
    [sequence addFrame:SpecialSouthTwo];
    sequence->type=BowSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //BowEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:BowNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=BowEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //BowWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:BowSouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=BowWestAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //BowRecoverNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    //[sequence addFrame:BowNorth];
    sequence->type=BowRecoverNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //BowRecoverSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    //[sequence addFrame:BowSouth];
    [sequence addFrame:SpecialSouthTwo];
    sequence->type=BowRecoverSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //BowRecoverEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    //[sequence addFrame:BowNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=BowRecoverEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //BowRecoverWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    //[sequence addFrame:BowSouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=BowRecoverWestAnimationSequenceType;
    [sequences addObject:sequence];
    
#pragma mark Kneel
    
    //KneelNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:KneelNorth];
    sequence->type=KneelNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //KneelSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:KneelSouth];
    sequence->type=KneelSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //KneelEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:KneelNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=KneelEastAnimationSequenceType;
    [animationSequences addObject:sequence];
    
    
    //KneelWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:KneelSouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=KneelWestAnimationSequenceType;
    [sequences addObject:sequence];
    
    //KneelRecoverNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    //[sequence addFrame:KneelNorth];
    sequence->type=KneelRecoverNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //KneelRecoverSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    //[sequence addFrame:KneelSouth];
    sequence->type=KneelRecoverSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //KneelRecoverEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    //[sequence addFrame:KneelNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=KneelRecoverEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //KneelRecoverWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    //[sequence addFrame:KneelSouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=KneelRecoverWestAnimationSequenceType;
    [sequences addObject:sequence];
    
#pragma mark SIT
    
    //SitNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:BowNorth];
    [sequence addFrame:SitNorth];
    sequence->type=SitNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //SitSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:BowSouth];
    [sequence addFrame:SitSouth];
    sequence->type=SitSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //SitEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandNorthFrameAction];
    [sequence addFrame:BowNorth];
    [sequence addFrame:SitNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=SitEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //SitWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:StandSouthFrameAction];
    [sequence addFrame:BowSouth];
    [sequence addFrame:SitSouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=SitWestAnimationSequenceType;
    [sequences addObject:sequence];
    
    //SitRecoverNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:BowNorth];
    [sequence addFrame:StandNorthFrameAction];
    //[sequence addFrame:SitNorth];
    sequence->type=SitRecoverNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //SitRecoverSouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:BowSouth];
    [sequence addFrame:StandSouthFrameAction];
   // [sequence addFrame:SitSouth];
    sequence->type=SitRecoverSouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //SitRecoverEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:BowNorth];
    [sequence addFrame:StandNorthFrameAction];
    //[sequence addFrame:SitNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=SitRecoverEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //SitRecoverWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:BowSouth];
    [sequence addFrame:StandSouthFrameAction];
    //[sequence addFrame:SitSouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=SitRecoverWestAnimationSequenceType;
    [sequences addObject:sequence];
    
#pragma mark LAY
    //LayNorthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:LayNorth];
    //[sequence addFrame:SitNorth];
    sequence->type=LayNorthAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //LaySouthAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:LaySouth];
   // [sequence addFrame:SitSouth];
    sequence->type=LaySouthAnimationSequenceType;
    [sequences addObject:sequence];
    
    //LayEastAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:LayNorth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=LayEastAnimationSequenceType;
    [sequences addObject:sequence];
    
    
    //LayWestAnimationSequenceType
    sequence=[[U7AnimationSequence alloc]init];
    [sequence addFrame:LaySouth];
    sequence->RotateLeft=YES;
    sequence->Mirrored=YES;
    sequence->type=LayWestAnimationSequenceType;
    [sequences addObject:sequence];
    
    return sequences;
}

-(U7AnimationSequence*)sequenceForType:(enum AnimationSequenceType)type
{
    U7AnimationSequence* sequence=NULL;
    
    for(int count=0;count<[animationSequences count];count++)
    {
        sequence=[animationSequences objectAtIndex:count];
        if(sequence->type==type)
        {
            //NSLog(@"found: %i",type);
            break;
        }
    }
    
    return sequence;
    
}


#pragma mark Utils

-(SInt16) getSInt16FromNSData:(NSData *)data atByteOffset:(long)offset
{
    
    if(data)
    {
        /*
        long newOffset=offset/2;
        const SInt16 * ints = [data bytes];
        result=(SInt16)ints[newOffset];
         */
        
        char buffer[2];
        [data getBytes:buffer range:NSMakeRange(offset, 2)];
        
        
        SInt16 *result = (SInt16*)buffer;
            return *result;
        
    }
    
    return 0;
}

-(UInt16) getUint16FromNSData:(NSData *)data atByteOffset:(long)offset
{
    if(data)
    {
        /*
        long newOffset=offset/2;
        const UInt16 * ints = [data bytes];
        result=(UInt16)ints[newOffset];
         */
        
        char buffer[2];
        [data getBytes:buffer range:NSMakeRange(offset, 2)];
        
        
        UInt16 *result = (UInt16*)buffer;
            return *result;
    }
    
    return 0;
}

-(UInt32) getUint32FromNSData:(NSData *)data atByteOffset:(UInt32)offset
{
    //UInt32 result=0;
    if(data)
    {
        /*
        UInt32 newOffset=offset/4;
        const UInt32 * ints = [data bytes];
        result=(UInt32)ints[newOffset];
         */
        char buffer[4];
        [data getBytes:buffer range:NSMakeRange(offset, 4)];
        
        
        UInt32 *result = (UInt32*)buffer;
            return *result;
    }
    
    return 0;
}



-(UInt8) getUint8FromNSData:(NSData *)data atByteOffset:(long)offset
{
    //UInt8 result=0;
    if(data)
    {
        //const UInt8 * ints = [data bytes];
        //result=(UInt8)ints[offset];
        char buffer[1];
        [data getBytes:buffer range:NSMakeRange(offset, 1)];
        
        
        UInt8 *result = (UInt8*)buffer;
            return *result;
    }
    
    return 0;
}

-(unsigned char) getCharFromNSData:(NSData *)data atByteOffset:(long)offset
{
    //int result=0;
    if(data)
    {
        
        //const char *bytes = [data bytes];
        //result=(char)bytes[offset];
        
        char buffer[1];
        [data getBytes:buffer range:NSMakeRange(offset, 1)];
        
        
        unsigned char *result = (unsigned char *)buffer;
            return *result;
    }
    
    return 0;
}

@end
