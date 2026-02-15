//
//  IslandMapView.h
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//

#import <UIKit/UIKit.h>
#import "BAMapView.h"
NS_ASSUME_NONNULL_BEGIN




@interface IslandMapView : BAMapView
{
    
}

-(void)generateMap;

//-(enum BATransitionType)transitionTypeForTile:(NSArray*)mapArray atX:(int)x atY:(int)y fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType;
-(CGPoint)globalToViewLocation:(CGPoint)globalLocation;
-(BAMapContinent*)defineContinent:(BAIntBitmap*)sourceBitmap forPostion:(CGPoint)position forTileType:(enum BATileType)type;
-(void)selectContinentAtLocation:(CGPoint)location;
-(CGPoint)chunkWithGrass;
@end

NS_ASSUME_NONNULL_END
