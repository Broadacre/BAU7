//
//  BATransitionStrategyRegistry.h
//  BAU7
//
//  Created by Refactoring on 2/15/26.
//

#import <Foundation/Foundation.h>
#import "BATerrainTransitionStrategy.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Registry that manages terrain transition strategies.
 * Uses a combination of explicit strategy objects and data-driven fallback
 * to provide tile type mappings for all terrain transitions.
 */
@interface BATransitionStrategyRegistry : NSObject

/**
 * Singleton instance
 */
+(instancetype)sharedRegistry;

/**
 * Register a strategy for a specific terrain type
 */
-(void)registerStrategy:(id<BATerrainTransitionStrategy>)strategy;

/**
 * Get the appropriate tile type for a terrain transition
 */
-(enum BATileType)tileTypeFrom:(enum BATileType)fromType 
                            to:(enum BATileType)toType 
                  forTransition:(enum BATransitionType)transition;

@end

NS_ASSUME_NONNULL_END
