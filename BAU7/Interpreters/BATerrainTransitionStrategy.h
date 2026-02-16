//
//  BATerrainTransitionStrategy.h
//  BAU7
//
//  Created by Refactoring on 2/15/26.
//

#import <Foundation/Foundation.h>
#import "BAU7BitmapInterpreter.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Strategy protocol for terrain transition tile mapping.
 * Each terrain type (Woods, Water, Mountain, etc.) implements this
 * to provide its specific transition tile mappings.
 */
@protocol BATerrainTransitionStrategy <NSObject>

/**
 * Returns the tile type for a given transition pattern.
 * @param transition The transition type (North, East, Corner, etc.)
 * @param toTileType The terrain type being transitioned TO
 * @return The specific tile type to use for this transition
 */
-(enum BATileType)tileTypeForTransition:(enum BATransitionType)transition 
                             toTileType:(enum BATileType)toTileType;

/**
 * Returns the source terrain type this strategy handles.
 */
-(enum BATileType)sourceTileType;

@end

NS_ASSUME_NONNULL_END
