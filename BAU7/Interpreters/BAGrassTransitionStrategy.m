//
//  BAGrassTransitionStrategy.m
//  BAU7
//
//  Created by Refactoring on 2/16/26.
//

#import "Includes.h"
#import "BAGrassTransitionStrategy.h"

@implementation BAGrassTransitionStrategy

-(enum BATileType)sourceTileType
{
    return GrassTileType;
}

-(enum BATileType)tileTypeForTransition:(enum BATransitionType)transition 
                             toTileType:(enum BATileType)toTileType
{
    // Grass to Water transitions
    if (toTileType == WaterTileType) {
        switch (transition) {
            case NorthTransitionType:
                return GrassToWater_North_TransitionTileType;
            case EastTransitionType:
                return GrassToWater_East_TransitionTileType;
            case SourthTransitionType:
                return GrassToWater_South_TransitionTileType;
            case WestTransitionType:
                return GrassToWater_West_TransitionTileType;
                
            // Inside corners
            case InsideCornerNorthEastTransitionType:
                return GrassToWater_InsideCorner_NorthEast_TransitionTileType;
            case InsideCornerSouthEastTransitionType:
                return GrassToWater_InsideCorner_SouthEast_TransitionTileType;
            case InsideCornerSouthWestTransitionType:
                return GrassToWater_InsideCorner_SouthWest_TransitionTileType;
            case InsideCornerNorthWestTransitionType:
                return GrassToWater_InsideCorner_NorthWest_TransitionTileType;
                
            // Outside corners
            case OutSideCornerNorthEastTransitionType:
                return GrassToWater_OutsideCorner_NorthEast_TransitionTileType;
            case OutSideCornerSouthEastTransitionType:
                return GrassToWater_OutsideCorner_SouthEast_TransitionTileType;
            case OutSideCornerSouthWestTransitionType:
                return GrassToWater_OutsideCorner_SouthWest_TransitionTileType;
            case OutSideCornerNorthWestTransitionType:
                return GrassToWater_OutsideCorner_NorthWest_TransitionTileType;
                
            // Multi-sided transitions
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                return InvalidTileType; // Grass to water doesn't support these in legacy code
                
            default:
                return NoTileType;
        }
    }
    
    // Not a Grass transition we handle
    return NoTileType;
}

@end
