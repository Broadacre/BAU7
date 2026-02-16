//
//  BAWoodsTransitionStrategy.m
//  BAU7
//
//  Created by Refactoring on 2/15/26.
//

#import "BAWoodsTransitionStrategy.h"

@implementation BAWoodsTransitionStrategy

-(enum BATileType)sourceTileType
{
    return WoodsTileType;
}

-(enum BATileType)tileTypeForTransition:(enum BATransitionType)transition 
                             toTileType:(enum BATileType)toTileType
{
    // Woods can transition to Grass, Desert, Swamp, Mountain, and various road/path types
    // All use the same WoodsToGrass_* tile types
    if (!(toTileType == GrassTileType ||
          toTileType == DesertTileType ||
          toTileType == SwampTileType ||
          toTileType == MountainTileType ||
          toTileType == WideRoadTileType ||
          toTileType == NarrowRoadTileType ||
          toTileType == CarriagePathTileType ||
          toTileType == WidePathTileType ||
          toTileType == NarrowPathTileType ||
          toTileType == StreamPathTileType ||
          toTileType == RiverPathTileType)) {
        return NoTileType; // Not a valid transition for Woods
    }
    
    switch (transition) {
        case NorthTransitionType:
            return WoodsToGrass_North_TransitionTileType;
        case EastTransitionType:
            return WoodsToGrass_East_TransitionTileType;
        case SourthTransitionType:
            return WoodsToGrass_South_TransitionTileType;
        case WestTransitionType:
            return WoodsToGrass_West_TransitionTileType;
            
        // Inside corners
        case InsideCornerNorthEastTransitionType:
            return WoodsToGrass_InsideCorner_NorthEast_TransitionTileType;
        case InsideCornerSouthEastTransitionType:
            return WoodsToGrass_InsideCorner_SouthEast_TransitionTileType;
        case InsideCornerSouthWestTransitionType:
            return WoodsToGrass_InsideCorner_SouthWest_TransitionTileType;
        case InsideCornerNorthWestTransitionType:
            return WoodsToGrass_InsideCorner_NorthWest_TransitionTileType;
            
        // Outside corners
        case OutSideCornerNorthEastTransitionType:
            return WoodsToGrass_OutsideCorner_NorthEast_TransitionTileType;
        case OutSideCornerSouthEastTransitionType:
            return WoodsToGrass_OutsideCorner_SouthEast_TransitionTileType;
        case OutSideCornerSouthWestTransitionType:
            return WoodsToGrass_OutsideCorner_SouthWest_TransitionTileType;
        case OutSideCornerNorthWestTransitionType:
            return WoodsToGrass_OutsideCorner_NorthWest_TransitionTileType;
            
        // Multi-sided transitions
        case ThreeSidedTranstionType:
        case FourSidedTransitionType:
        case TwoSidedOppositeTransitionType:
            return WoodsToGrass_Solo_TransitionTileType;
            
        default:
            return NoTileType;
    }
}

@end
