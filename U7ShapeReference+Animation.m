//
//  U7ShapeReference+Animation.m
//  BAU7
//
//  Created to fix animation frame wrapping bug
//

#import "U7ShapeReference+Animation.h"

@implementation U7ShapeReference (Animation)

-(void)incrementCurrentFrame
{
    // Increment the current frame
    currentFrame++;
    
    // Wrap around to 0 if we've exceeded the number of frames
    // This prevents the "Invalid frame X for shapeID Y" error
    if (numberOfFrames > 0 && currentFrame >= numberOfFrames) {
        currentFrame = 0;
    }
    
    // Additional safety check: if numberOfFrames is 0 or negative, reset to 0
    if (numberOfFrames <= 0) {
        currentFrame = 0;
    }
}

-(CGPoint)globalCoordinate
{
    // Calculate the global tile coordinate from chunk coordinates
    long chunkX = parentChunkID % TOTALMAPSIZE;
    long chunkY = parentChunkID / TOTALMAPSIZE;
    
    CGFloat globalX = (chunkX * CHUNKSIZE) + parentChunkXCoord;
    CGFloat globalY = (chunkY * CHUNKSIZE) + parentChunkYCoord;
    
    return CGPointMake(globalX, globalY);
}

-(CGRect)originRect
{
    CGPoint global = [self globalCoordinate];
    return CGRectMake(global.x * TILESIZE, 
                     global.y * TILESIZE, 
                     TILESIZE, 
                     TILESIZE);
}

-(NSString *)exportToXML
{
    NSMutableString *xml = [NSMutableString string];
    [xml appendString:@"<U7ShapeReference>\n"];
    [xml appendFormat:@"  <GameObject>%@</GameObject>\n", GameObject ? @"true" : @"false"];
    [xml appendFormat:@"  <StaticObject>%@</StaticObject>\n", StaticObject ? @"true" : @"false"];
    [xml appendFormat:@"  <GroundObject>%@</GroundObject>\n", GroundObject ? @"true" : @"false"];
    [xml appendFormat:@"  <shapeID>%ld</shapeID>\n", (long)shapeID];
    [xml appendFormat:@"  <frameNumber>%d</frameNumber>\n", frameNumber];
    [xml appendFormat:@"  <parentChunkID>%ld</parentChunkID>\n", (long)parentChunkID];
    [xml appendFormat:@"  <parentChunkXCoord>%d</parentChunkXCoord>\n", parentChunkXCoord];
    [xml appendFormat:@"  <parentChunkYCoord>%d</parentChunkYCoord>\n", parentChunkYCoord];
    [xml appendFormat:@"  <xloc>%d</xloc>\n", xloc];
    [xml appendFormat:@"  <yloc>%d</yloc>\n", yloc];
    [xml appendFormat:@"  <lift>%d</lift>\n", lift];
    [xml appendFormat:@"  <eulerRotation>%f</eulerRotation>\n", eulerRotation];
    [xml appendFormat:@"  <speed>%d</speed>\n", speed];
    [xml appendFormat:@"  <depth>%d</depth>\n", depth];
    [xml appendFormat:@"  <animates>%@</animates>\n", animates ? @"true" : @"false"];
    [xml appendFormat:@"  <numberOfFrames>%ld</numberOfFrames>\n", (long)numberOfFrames];
    [xml appendFormat:@"  <currentFrame>%ld</currentFrame>\n", (long)currentFrame];
    [xml appendFormat:@"  <maxY>%f</maxY>\n", maxY];
    [xml appendFormat:@"  <maxX>%f</maxX>\n", maxX];
    [xml appendFormat:@"  <maxZ>%f</maxZ>\n", maxZ];
    [xml appendString:@"</U7ShapeReference>\n"];
    return xml;
}

@end
