//
//  BAEnvironmentMap.h
//  BAU7
//
//  Created by Dan Brooker on 6/10/22.
//

#ifndef BAEnvironmentMap_h
#define BAEnvironmentMap_h


#endif /* BAEnvironmentMap_h */

@interface BAEnvironmentMapTile : NSObject
{
    enum BAEnvironmentType environmentType;
    long wear;
}
-(enum BAEnvironmentType)getEnvironmentType;
-(void)setEnvironmentType:(enum BAEnvironmentType)theEnvironmentType;
@end

@interface BAEnvironmentMap: NSObject
{
    CGSize size;
    NSMutableArray * environmentMap;
    
}
-(void)initEnvironmentMap:(CGSize)size;
-(void)setEnvironmentTypeAtPosition:(enum BAEnvironmentType)environmentType atPosition:(CGPoint)chunkPosition;
+(BAEnvironmentMap*)environmentMapForU7MapChunk:(U7MapChunk*)mapChunk;
-(enum BAEnvironmentType)environmentTypeAtPosition:(CGPoint)chunkPosition;
@end
