//
//  BACamera.m
//  BAU7
//
//  Created by Dan Brooker on 10/2/21.
//

#import <UIKit/UIKit.h>
#import "Includes.h"
#import "BACamera.h"

@implementation BACamera

-(id)init
{
    self=[super init];
    
    
    
    return self;
    
}

-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
        environment=theEnvironment;
}


-(void)setCenter:(CGPoint)globalCenter
{
    center=globalCenter;
}

-(void)setBounds:(CGRect)theBounds
{
    bounds=theBounds;
}

-(CGPoint)getCenter
{
    return center;
}

-(CGRect)getBounds
{
    return bounds;
}


-(long)chunkIDAtGlobalPoint:(CGPoint)globalPoint
{
    CGPoint ChunkIndex=[self chunkIndexAtGlobalPoint:globalPoint];
    long ChunkID=ChunkIndex.x+(ChunkIndex.y*SUPERCHUNKSIZE*CHUNKSIZE);
    
    return ChunkID;
}


-(CGPoint)chunkIndexAtGlobalPoint:(CGPoint)globalPoint
{
    long ChunkX=globalPoint.x/CHUNKSIZE*TILESIZE;
    long ChunkY=globalPoint.y/CHUNKSIZE*TILESIZE;
    return CGPointMake(ChunkX, ChunkY);
}

@end
