//
//  BAU7TileInterpreter.m
//  BAU7
//
//  Created by Dan Brooker on 3/5/24.
//
#import "Includes.h"
#import "BAU7TileInterpreter.h"

@implementation BAU7TileInterpreter

-(BOOL)IsOutOfBounds:(BABitmap*)bitmap atX:(int)x atY:(int)y
   {
       if( x<0 || y<0 )
       {
           return true;
       }
       else if( x>[bitmap width]-1 || y>[bitmap height]-1 )
       {
           return true;
       }
       return false;
   }

-(BOOL)IsTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y forTileType:(enum BATileType)tileType
   {
       // Consider out-of-bound a wall
       //NSLog(@"GetAdjacentTiles: %i, %i",x,y);
       if([self IsOutOfBounds:bitmap atX:x atY:y] )
       {
           //NSLog(@"Out of Bounds");
           return false;
       }
       enum BATileType tempTileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"BAU7BitmapInterpreter IsTileType"];
       if(tempTileType==tileType)
       {
           return true;
       }

       return false;
   }

-(enum BATransitionType)transitionTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType invalidateMixed:(BOOL)invalidMixed
{
       
    BOOL verbose=NO;
   
    enum BATransitionType tempTransitionType=NoTransitionType;
    if([self IsTileType:bitmap atX:x atY:y forTileType:fromType])
    {
        
        
        BATileComparator * comparator=[[BATileComparator alloc]init];
                                       
        [comparator compareBitmapTiletype:bitmap aPosition:CGPointMake(x, y) forType:toType];

        if(invalidMixed)
        {
            if(comparator->mixed)
            {
                if(verbose) NSLog(@"mixed");
                return InvalidTransitionType;
            }
        }
        
         if(comparator->North&&comparator->West&&comparator->East&&comparator->South)
        {
            if(verbose) NSLog(@"FourSidedTransitionType");
            return FourSidedTransitionType;
        }
        
        //three sided
        
        else if(comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            if(verbose) NSLog(@"ThreeSidedTranstionType1");
            return ThreeSidedTranstionType;
        }
        
        else if(!comparator->North&&comparator->West&&comparator->East&&comparator->South)
        {
            if(verbose) NSLog(@"ThreeSidedTranstionType2");
            return ThreeSidedTranstionType;
        }
        
        else if(comparator->North&&!comparator->West&&comparator->East&&comparator->South)
        {
            if(verbose) NSLog(@"ThreeSidedTranstionType3");
            return ThreeSidedTranstionType;
        }
        
        else if(comparator->North&&comparator->West&&!comparator->East&&comparator->South)
        {
            if(verbose) NSLog(@"ThreeSidedTranstionType4");
            return ThreeSidedTranstionType;
        }
        
        //opposite
       else if(comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
            {
                if(verbose) NSLog(@"TwoSidedOppositeTransitionType1");
                return TwoSidedOppositeTransitionType;
            }
        else if(!comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            if(verbose) NSLog(@"TwoSidedOppositeTransitionType2");
            return TwoSidedOppositeTransitionType;
        }
        /*
        else if(comparator->NorthEast&&comparator->SouthWest)
        {
            NSLog(@"TwoSidedOppositeTransitionType3");
            return TwoSidedOppositeTransitionType;
        }
        else if(comparator->SouthEast&&comparator->NorthWest)
        {
            NSLog(@"TwoSidedOppositeTransitionType4");
            return TwoSidedOppositeTransitionType;
        }
        */
        
        /* */
        else if(comparator->North&&!comparator->West&&!comparator->East&&!comparator->South)
            {
                if(verbose) NSLog(@"NorthTransitionType");
                //NSLog(@"North!");
                tempTransitionType=NorthTransitionType ;
            }
        else if (!comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            if(verbose) NSLog(@"EastTransitionType");
            tempTransitionType=EastTransitionType ;
        }
        else if (!comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            if(verbose) NSLog(@"SourthTransitionType");
            tempTransitionType=SourthTransitionType;
        }
        else if (!comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            if(verbose) NSLog(@"WestTransitionType");
            tempTransitionType=WestTransitionType;
        }
        //inside corners
        else if (comparator->South&&comparator->East&&comparator->SouthEast&&!comparator->West)
        {
            if(verbose) NSLog(@"InsideCornerSouthEastTransitionType");
            tempTransitionType=InsideCornerSouthEastTransitionType ;
        }
        
        else if (comparator->South&&comparator->West&&comparator->SouthWest&&!comparator->East)
        {
            if(verbose) NSLog(@"InsideCornerSouthWestTransitionType");
            tempTransitionType=InsideCornerSouthWestTransitionType ;
        }
        else if (comparator->North&&comparator->NorthEast&&comparator->East&&!comparator->West)
        {
            if(verbose) NSLog(@"InsideCornerNorthEastTransitionType");
            tempTransitionType=InsideCornerNorthEastTransitionType ;
        }
        else if (comparator->North&&comparator->NorthWest&&comparator->West&&!comparator->East)
        {
            if(verbose) NSLog(@"InsideCornerNorthWestTransitionType");
            tempTransitionType=InsideCornerNorthWestTransitionType ;
        }
        
        //outside corners
        
        else if(comparator->SouthWest&&!comparator->West&&!comparator->South)
        {
            if(verbose)NSLog(@"OutSideCornerSouthWestTransitionType");
            return OutSideCornerSouthWestTransitionType;
        }
        else if(comparator->SouthEast&&!comparator->East&&!comparator->South)
        {
            if(verbose) NSLog(@"OutSideCornerSouthEastTransitionType");
            return OutSideCornerSouthEastTransitionType;
        }
        else if(comparator->NorthEast&&!comparator->East&&!comparator->North)
        {
            if(verbose) NSLog(@"OutSideCornerNorthEastTransitionType");
            return OutSideCornerNorthEastTransitionType;
        }
        
        else if(comparator->NorthWest&&!comparator->West&&!comparator->North)
        {
            if(verbose) NSLog(@"OutSideCornerNorthWestTransitionType");
            return OutSideCornerNorthWestTransitionType;
        }
    }
    //NSLog(@"No Transition");
    return tempTransitionType;
}

-(enum BATransitionType)transitionType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    enum BATransitionType transitionType=NoTransitionType;
    
    //Check Water
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:GrassTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
    //transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:GrassTileType toTileType:SwampTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
    //transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:GrassTileType toTileType:WoodsTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
   // transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:GrassTileType toTileType:DesertTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
   
    return transitionType;
}

-(enum BATileType)TileTypeForTransitionType:(enum BATileType)fromType toTileType:(enum BATileType)toType forTransition:(enum BATransitionType)transitionType
{
    enum BATileType tileType=NoTileType;
    if(
       (fromType==WoodsTileType&&toType==GrassTileType)||
       (fromType==WoodsTileType&&toType==DesertTileType)||
       (fromType==WoodsTileType&&toType==SwampTileType)||
       (fromType==WoodsTileType&&toType==MountainTileType)||
       (fromType==WoodsTileType&&toType==WideRoadTileType)||
      (fromType==WoodsTileType&&toType==NarrowRoadTileType)||
      (fromType==WoodsTileType&&toType==CarriagePathTileType)||
     (fromType==WoodsTileType&&toType==WidePathTileType)||
      (fromType==WoodsTileType&&toType==NarrowPathTileType)||
     (fromType==WoodsTileType&&toType==StreamPathTileType)||
      (fromType==WoodsTileType&&toType==RiverPathTileType)
        )
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=WoodsToGrass_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=WoodsToGrass_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=WoodsToGrass_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=WoodsToGrass_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=WoodsToGrass_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=WoodsToGrass_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=WoodsToGrass_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=WoodsToGrass_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=WoodsToGrass_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=WoodsToGrass_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=WoodsToGrass_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=WoodsToGrass_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                
                    tileType=WoodsToGrass_Solo_TransitionTileType;
            default:
                break;
        }
    }
    return tileType;
}

@end
