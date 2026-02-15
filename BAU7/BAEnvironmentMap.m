//
//  BAEnvironmentMap.m
//  BAU7
//
//  Created by Dan Brooker on 6/10/22.
//

#import <Foundation/Foundation.h>
#import "Includes.h"
#import "BAEnvironmentMap.h"

@implementation BAEnvironmentMapTile

-(id)init
{
    self=[super init];
    environmentType=NoBAEnvironmentType;
    
    return self;
}

-(enum BAEnvironmentType)getEnvironmentType
{
    return environmentType;
}

-(void)setEnvironmentType:(enum BAEnvironmentType)theEnvironmentType
{
    environmentType=theEnvironmentType;
}
@end

@implementation BAEnvironmentMap

-(id)init
{
    self=[super init];
    environmentMap=[[NSMutableArray alloc]init];
    //allow for differentChunkSizes??
    [self initEnvironmentMap:CGSizeMake(CHUNKSIZE, CHUNKSIZE)];
    return self;
}
-(void)setEnvironmentTypeAtPosition:(enum BAEnvironmentType)environmentType atPosition:(CGPoint)chunkPosition
{
    long index=(chunkPosition.y*size.width)+chunkPosition.x;
    BAEnvironmentMapTile * mapTile=[environmentMap objectAtIndex:index];
    [mapTile setEnvironmentType:environmentType];
}


-(void)initEnvironmentMap:(CGSize)size
{
    [environmentMap removeAllObjects];
    for(long index=0;index<(size.width*size.height);index++)
    {
        BAEnvironmentMapTile * tile=[[BAEnvironmentMapTile alloc]init];
        [environmentMap addObject:tile];
    }
}

+(BAEnvironmentMap*)environmentMapForU7MapChunk:(U7MapChunk*)mapChunk
{
    BAEnvironmentMap * environmentMap=[[BAEnvironmentMap alloc]init];
    
    return environmentMap;
}

-(enum BAEnvironmentType)environmentTypeAtPosition:(CGPoint)chunkPosition
{
    long index=(chunkPosition.y*size.width)+chunkPosition.x;
    BAEnvironmentMapTile * tile=[environmentMap objectAtIndex:index];
    return [tile getEnvironmentType];
}

@end
