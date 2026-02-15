//
//  RandoMapView.h
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//

#import <UIKit/UIKit.h>
#import "BAMapView.h"
NS_ASSUME_NONNULL_BEGIN


@interface BAMapContinent:NSObject
{
    CGPointArray * pointArray;
}
-(BOOL)addPosition:(CGPoint)thePosition;
-(BOOL)chunkInContinent:(CGPoint)chunkPosition;
-(long)numberOfChunks;
-(CGPoint)pointAtIndex:(long)theIndex;
@end

@interface RandoMapView : BAMapView
{
    @public
    //NSArray * baseMap;//need to move to this
    
    
}

-(void)generateMap;

//-(enum BATransitionType)transitionTypeForTile:(NSArray*)mapArray atX:(int)x atY:(int)y fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType;
-(BAMapContinent*)defineContinent:(BAIntBitmap*)sourceBitmap forPostion:(CGPoint)position forTileType:(enum BATileType)type;
-(void)selectContinentAtLocation:(CGPoint)location;

@end

NS_ASSUME_NONNULL_END
