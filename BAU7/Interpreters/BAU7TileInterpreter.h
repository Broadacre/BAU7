//
//  BAU7TileInterpreter.h
//  BAU7
//
//  Created by Dan Brooker on 3/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAU7TileInterpreter : NSObject

-(enum BATransitionType)transitionType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y;
@end

NS_ASSUME_NONNULL_END
