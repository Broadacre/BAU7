//
//  BAU7BitmapInterpreter.m
//  BAU7
//
//  Created by Dan Brooker on 12/11/22.
//

#import "Includes.h"
#import "BAU7BitmapInterpreter.h"


@implementation BATileComparator
-(id)init
{
    self=[super init];
    
    [self reset];
    return self;
}

-(void)reset
{
    North=NO;
    NorthEast=NO;
    East=NO;
    SouthEast=NO;
    South=NO;
    SouthWest=NO;
    West=NO;
    NorthWest=NO;
    
    
    mixed=NO;
    lastTileType=NoTileType;
    fromTileType=NoTileType;
    testTileType=NoTileType;
}

-(void)dump
{
    
    NSLog(@"North: %i",North);
    NSLog(@"NorthEast: %i",NorthEast);
    NSLog(@"East: %i",East);
    NSLog(@"SouthEast: %i",SouthEast);
    NSLog(@"South: %i",South);
    NSLog(@"SouthWest: %i",SouthWest);
    NSLog(@"West: %i",West);
    NSLog(@"NorthWest: %i",NorthWest);
    
    
    NSLog(@"mixed: %i",mixed);
}

-(void)compareBitmapTiletype:(BAIntBitmap*)bitmap aPosition:(CGPoint)position forType:(enum BATileType)tileType
{
    [self reset];
    
    //collect data for mixed
   
    fromTileType=[bitmap valueAtPosition:position from:@"compareBitmapTiletype"];
    lastTileType=fromTileType;
    
    CGPoint thePoint;
    
    for(int direction=0;direction<8;direction++)
    {
        switch (direction) {
            case 0:
                thePoint=CGPointMake(position.x, position.y-1);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    North=YES;
                }
                break;
            case 1:
                thePoint=CGPointMake(position.x+1, position.y-1);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    NorthEast=YES;
                }
                break;
            case 2:
                thePoint=CGPointMake(position.x+1, position.y);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    East=YES;
                }
                break;
            case 3:
                thePoint=CGPointMake(position.x+1, position.y+1);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    SouthEast=YES;
                }
                break;
            case 4:
                thePoint=CGPointMake(position.x, position.y+1);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    South=YES;
                }
                break;
            case 5:
                thePoint=CGPointMake(position.x-1, position.y+1);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    SouthWest=YES;
                }
                break;
            case 6:
                thePoint=CGPointMake(position.x-1, position.y);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    West=YES;
                }
                break;
            case 7:  //Northwest
                thePoint=CGPointMake(position.x-1, position.y-1);
                if([self doCompareLogicAtPoint:thePoint forBitmap:bitmap forTileType:tileType])
                {
                    NorthWest=YES;
                }
                break;
            default:
                break;
        }
    }
}
-(BOOL)doCompareLogicAtPoint:(CGPoint)thePoint forBitmap:(BAIntBitmap*)bitmap forTileType:(enum BATileType)tileType
{
    BOOL match=NO;
    if([bitmap validPosition:thePoint])
    {
        testTileType=[bitmap valueAtPosition:thePoint from:@"compareBitmapTiletype"];
        if(testTileType==tileType)
        {
            match=YES;
        }
        if(!mixed)//check for mixed
        {
            if(lastTileType!=fromTileType)
            {
                if(testTileType!=lastTileType&&testTileType!=fromTileType)
                {
                    mixed=YES;
                }
            }
            else
                lastTileType=testTileType;
        }
        
    }
    return match;
}

@end

@implementation BAU7BitmapInterpreter

-(BOOL)setEnvironment:(U7Environment*)theEnvironment
{
    if(!theEnvironment)
        return NO;
    
    environment=theEnvironment;
    return YES;
    
}

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

-(enum BATileType)TileTypeForTransitionType:(enum BATileType)fromType toTileType:(enum BATileType)toType forTransition:(enum BATransitionType)transitionType
{
    enum BATileType tileType=NoTileType;
    //NSLog(@"TileTypeForTransitionType: from: %i to: %i",fromType,toType);
    
#pragma mark From Woods
    
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
    else if(fromType==WoodsTileType&&toType==WaterTileType)
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                
                tileType=GrassToWater_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=GrassToWater_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=GrassToWater_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=GrassToWater_West_TransitionTileType ;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=GrassToWater_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=GrassToWater_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=GrassToWater_InsideCorner_SouthWest_TransitionTileType ;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=GrassToWater_InsideCorner_NorthWest_TransitionTileType ;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthWest_TransitionTileType ;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthWest_TransitionTileType ;
                break;
                
            case ThreeSidedTranstionType:
            {
                //NSLog(@"ThreeSidedTranstionType");
                tileType=InvalidTileType;
            }
            case FourSidedTransitionType:
            {
                //NSLog(@"FourSidedTransitionType");
                tileType=InvalidTileType;
            }
            case TwoSidedOppositeTransitionType:
            {
                //NSLog(@"TwoSidedOppositeTransitionType");
                tileType=InvalidTileType;
            }
            case InvalidTransitionType:
                //NSLog(@"InvalidTransitionType");
                break;
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
    
    
#pragma mark From Swamp
    else if(
       (fromType==SwampTileType&&toType==GrassTileType)||
       (fromType==SwampTileType&&toType==MountainTileType)||
       (fromType==SwampTileType&&toType==WaterTileType)||
       (fromType==SwampTileType&&toType==DesertTileType)||
        (fromType==SwampTileType&&toType==WideRoadTileType)||
       (fromType==SwampTileType&&toType==NarrowRoadTileType)||
       (fromType==SwampTileType&&toType==CarriagePathTileType)||
      (fromType==SwampTileType&&toType==WidePathTileType)||
       (fromType==SwampTileType&&toType==NarrowPathTileType)||
      (fromType==SwampTileType&&toType==StreamPathTileType)||
       (fromType==SwampTileType&&toType==RiverPathTileType)
       )
    {
        //NSLog(@"SwampTileType to GrassTileType");
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=SwampToGrass_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=SwampToGrass_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=SwampToGrass_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=SwampToGrass_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=SwampToGrass_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=SwampToGrass_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=SwampToGrass_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=SwampToGrass_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=SwampToGrass_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=SwampToGrass_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=SwampToGrass_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=SwampToGrass_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=SwampToGrass_Solo_TransitionTileType;
                
                //NSLog(@"SwampToGrass_Solo_TransitionTileType");
                tileType=SwampToGrass_Solo_TransitionTileType;
            default:
                break;
        }
    }
    
#pragma mark From MountainTileType
    
    else if(
    (fromType==MountainTileType&&toType==GrassTileType)||
       (fromType==MountainTileType&&toType==SwampTileType)||
       (fromType==MountainTileType&&toType==WoodsTileType)||
        (fromType==MountainTileType&&toType==WideRoadTileType)||
       (fromType==MountainTileType&&toType==NarrowRoadTileType)||
       (fromType==MountainTileType&&toType==CarriagePathTileType)||
      (fromType==MountainTileType&&toType==WidePathTileType)||
       (fromType==MountainTileType&&toType==NarrowPathTileType)||
      (fromType==MountainTileType&&toType==StreamPathTileType)||
       (fromType==MountainTileType&&toType==RiverPathTileType)
       )
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=MountainToGrass_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=MountainToGrass_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=MountainToGrass_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=MountainToGrass_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=MountainToGrass_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=MountainToGrass_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=MountainToGrass_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=MountainToGrass_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=MountainToGrass_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=MountainToGrass_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=MountainToGrass_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=MountainToGrass_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=InvalidTileType;
            default:
                break;
        }
    }
  
#pragma mark From DungeonTileType
    
    else if(fromType==DungeonTileType)
    {
        NSLog(@"DungeonTileType!!!!...transition: %i",transitionType);
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=DungeonAreaNorthWallTileType;
                break;
            case EastTransitionType:
                tileType=DungeonAreaEastWallTileType;
                break;
            case SourthTransitionType:
                tileType=DungeonAreaSouthWallTileType;
                break;
            case WestTransitionType:
                tileType=DungeonAreaWestWallTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=DungeonCornerNorthEast_TileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=DungeonCornerSouthEast_TileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=DungeonCornerSouthWest_TileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=DungeonCornerNorthWest_TileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=DungeonNorthEastOutsideCornerBAAreaType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=DungeonSouthEastOutsideCornerBAAreaType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=DungeonSouthWestOutsideCornerBAAreaType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=DungeonNorthWestOutsideCornerBAAreaType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=InvalidTileType;
            default:
                break;
        }
    }
#pragma mark From WaterTileType
    else if(fromType==WaterTileType&&toType==GrassTileType)
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=WaterToGrass_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=WaterToGrass_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=WaterToGrass_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=WaterToGrass_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=WaterToGrass_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=WaterToGrass_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=WaterToGrass_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=WaterToGrass_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=WaterToGrass_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=WaterToGrass_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=WaterToGrass_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=WaterToGrass_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=InvalidTileType;
            default:
                break;
        }
    }
    
    else if(fromType==WaterTileType&&toType==SwampTileType)
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=WaterToGrass_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=WaterToGrass_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=WaterToGrass_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=WaterToGrass_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=WaterToGrass_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=WaterToGrass_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=WaterToGrass_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=WaterToGrass_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=WaterToGrass_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=WaterToGrass_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=WaterToGrass_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=WaterToGrass_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=InvalidTileType;
            default:
                break;
        }
    }
    
    
    
#pragma mark From GrassTileType
    
    
    else if(fromType==GrassTileType&&toType==WoodsTileType)
    {
        NSLog(@"Grass to Woods");
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=GrassToWoods_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=GrassToWoods_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=GrassToWoods_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=GrassToWoods_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=GrassToWoods_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=GrassToWoods_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=GrassToWoods_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=GrassToWoods_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=GrassToWoods_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=GrassToWoods_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=GrassToWoods_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=GrassToWoods_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=InvalidTileType;
            default:
                break;
        }
    }
    
    else if(fromType==GrassTileType&&toType==SwampTileType)
    {
        NSLog(@"Grass to Swamp");
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=GrassToSwamp_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=GrassToSwamp_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=GrassToSwamp_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=GrassToSwamp_West_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=GrassToSwamp_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=GrassToSwamp_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=GrassToSwamp_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=GrassToSwamp_InsideCorner_NorthWest_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=GrassToSwamp_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=GrassToSwamp_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=GrassToSwamp_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=GrassToSwamp_OutsideCorner_NorthWest_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=InvalidTileType;
            default:
                break;
        }
    }
    
    else if(fromType==GrassTileType&&toType==WaterTileType)
    {
        //NSLog(@"GrassTileType to water");
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                
                tileType=GrassToWater_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=GrassToWater_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=GrassToWater_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=GrassToWater_West_TransitionTileType ;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=GrassToWater_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=GrassToWater_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=GrassToWater_InsideCorner_SouthWest_TransitionTileType ;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=GrassToWater_InsideCorner_NorthWest_TransitionTileType ;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthWest_TransitionTileType ;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthWest_TransitionTileType ;
                break;
                
            case ThreeSidedTranstionType:
            {
                //NSLog(@"ThreeSidedTranstionType");
                tileType=InvalidTileType;
            }
            case FourSidedTransitionType:
            {
                //NSLog(@"FourSidedTransitionType");
                tileType=InvalidTileType;
            }
            case TwoSidedOppositeTransitionType:
            {
                //NSLog(@"TwoSidedOppositeTransitionType");
                tileType=InvalidTileType;
            }
            case InvalidTransitionType:
                //NSLog(@"InvalidTransitionType");
                break;
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
#pragma mark From DesertTileType
    //NSLog(@"Fall through more");
    
    else if(fromType==DesertTileType&&toType==WaterTileType)
    {
        //NSLog(@"DesertTileType to water");
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                
                tileType=DesertToWater_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=DesertToWater_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=DesertToWater_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=DesertToWater_West_TransitionTileType ;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=DesertToWater_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=DesertToWater_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=DesertToWater_InsideCorner_SouthWest_TransitionTileType ;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=DesertToWater_InsideCorner_NorthWest_TransitionTileType ;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=DesertToWater_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=DesertToWater_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=DesertToWater_OutsideCorner_SouthWest_TransitionTileType ;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=DesertToWater_OutsideCorner_NorthWest_TransitionTileType ;
                break;
                
            case ThreeSidedTranstionType:
            {
                //NSLog(@"ThreeSidedTranstionType");
                tileType=DesertToGrass_Solo_TransitionTileType;
            }
                break;
            case FourSidedTransitionType:
            {
                //NSLog(@"FourSidedTransitionType");
                tileType=DesertToGrass_Solo_TransitionTileType;
            }
                break;
            case TwoSidedOppositeTransitionType:
            {
                //NSLog(@"TwoSidedOppositeTransitionType");
                tileType=DesertToGrass_Solo_TransitionTileType;
            }
                break;
            case InvalidTransitionType:
                //NSLog(@"InvalidTransitionType");
                break;
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
    else if(
            (fromType==DesertTileType&&toType==GrassTileType)||
            (fromType==DesertTileType&&toType==SwampTileType)||
            (fromType==DesertTileType&&toType==WoodsTileType)||
            (fromType==DesertTileType&&toType==WideRoadTileType)||
           (fromType==DesertTileType&&toType==NarrowRoadTileType)||
           (fromType==DesertTileType&&toType==CarriagePathTileType)||
          (fromType==DesertTileType&&toType==WidePathTileType)||
           (fromType==DesertTileType&&toType==NarrowPathTileType)||
          (fromType==DesertTileType&&toType==StreamPathTileType)||
           (fromType==DesertTileType&&toType==RiverPathTileType)
        )
    {
        //NSLog(@"GrassTileType to water");
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                
                tileType=DesertToGrass_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=DesertToGrass_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=DesertToGrass_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=DesertToGrass_West_TransitionTileType ;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=DesertToGrass_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=DesertToGrass_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=DesertToGrass_InsideCorner_SouthWest_TransitionTileType ;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=DesertToGrass_InsideCorner_NorthWest_TransitionTileType ;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=DesertToGrass_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=DesertToGrass_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=DesertToGrass_OutsideCorner_SouthWest_TransitionTileType ;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=DesertToGrass_OutsideCorner_NorthWest_TransitionTileType ;
                break;
                
            case ThreeSidedTranstionType:
            {
                //NSLog(@"ThreeSidedTranstionType");
                tileType=DesertToGrass_Solo_TransitionTileType;
            }
                break;
            case FourSidedTransitionType:
            {
                //NSLog(@"FourSidedTransitionType");
                tileType=DesertToGrass_Solo_TransitionTileType;
            }
                break;
            case TwoSidedOppositeTransitionType:
            {
                //NSLog(@"TwoSidedOppositeTransitionType");
                tileType=DesertToGrass_Solo_TransitionTileType;
            }
                break;
            case InvalidTransitionType:
                //NSLog(@"InvalidTransitionType");
                break;
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
#pragma mark Path To Water
    
    else if(
        (fromType==WideRoadTileType&&toType==WaterTileType)||
       (fromType==NarrowRoadTileType&&toType==WaterTileType)||
       (fromType==CarriagePathTileType&&toType==WaterTileType)||
      (fromType==WidePathTileType&&toType==WaterTileType)||
       (fromType==NarrowPathTileType&&toType==WaterTileType)||
      (fromType==StreamPathTileType&&toType==WaterTileType)||
       (fromType==RiverPathTileType&&toType==WaterTileType)
       )
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                
                tileType=GrassToWater_North_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=GrassToWater_East_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=GrassToWater_South_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=GrassToWater_West_TransitionTileType ;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=GrassToWater_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=GrassToWater_InsideCorner_SouthEast_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=GrassToWater_InsideCorner_SouthWest_TransitionTileType ;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=GrassToWater_InsideCorner_NorthWest_TransitionTileType ;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthEast_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthWest_TransitionTileType ;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthWest_TransitionTileType ;
                break;
                
            case ThreeSidedTranstionType:
            {
                //NSLog(@"ThreeSidedTranstionType");
                tileType=InvalidTileType;
            }
            case FourSidedTransitionType:
            {
                //NSLog(@"FourSidedTransitionType");
                tileType=InvalidTileType;
            }
            case TwoSidedOppositeTransitionType:
            {
                //NSLog(@"TwoSidedOppositeTransitionType");
                tileType=InvalidTileType;
            }
            case InvalidTransitionType:
                //NSLog(@"InvalidTransitionType");
                break;
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }

#pragma mark From WideRoadTiletype
    
    else if(fromType==WideRoadTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=WideRoadNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=WideRoadEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=WideRoadNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=WideRoadNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=WideRoadSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=WideRoadSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=WideRoadIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=WideRoadDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=WideRoadDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=WideRoadDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=WideRoadDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=WideRoadNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=WideRoadSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=WideRoadEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=WideRoadWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
#pragma mark From NarrowRoadTiletype
    
    else if(fromType==NarrowRoadTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=NarrowRoadNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=NarrowRoadEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=NarrowRoadNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=NarrowRoadNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=NarrowRoadSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=NarrowRoadSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=NarrowRoadIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=NarrowRoadDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=NarrowRoadDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=NarrowRoadDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=NarrowRoadDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=NarrowRoadNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=NarrowRoadSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=NarrowRoadEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=NarrowRoadWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
#pragma mark From DirtCavePassageTileType
    
    else  if(fromType==DirtCavePassageTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=DirtCavePassageNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=DirtCavePassageEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=DirtCavePassageNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=DirtCavePassageNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=DirtCavePassageSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=DirtCavePassageSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=DirtCavePassageIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=DirtCavePassageDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=DirtCavePassageDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=DirtCavePassageDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=DirtCavePassageDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=DirtCavePassageNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=DirtCavePassageSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=DirtCavePassageEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=DirtCavePassageWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }

#pragma mark From DungeonPassageTileType
    
    else if(fromType==DungeonPassageTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=DungeonPassageNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=DungeonPassageEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=DungeonPassageNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=DungeonPassageNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=DungeonPassageSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=DungeonPassageSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=DungeonPassageIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=DungeonPassageDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=DungeonPassageDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=DungeonPassageDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=DungeonPassageDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=DungeonPassageNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=DungeonPassageSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=DungeonPassageEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=DungeonPassageWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
#pragma mark From CarriagePathTileType
    
    else if(fromType==CarriagePathTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=CarriagePathNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=CarriagePathEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=CarriagePathNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=CarriagePathNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=CarriagePathSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=CarriagePathSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=CarriagePathIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=CarriagePathDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=CarriagePathDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=CarriagePathDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=CarriagePathDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=CarriagePathNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=CarriagePathSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=CarriagePathEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=CarriagePathWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }

#pragma mark From WidePathTileType
    
    else if(fromType==WidePathTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=WidePathNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=WidePathEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=WidePathNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=WidePathNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=WidePathSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=WidePathSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=WidePathIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=WidePathDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=WidePathDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=WidePathDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=WidePathDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=WidePathNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=WidePathSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=WidePathEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=WidePathWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
   
#pragma mark From NarrowPathTileType
    
    else if(fromType==NarrowPathTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=NarrowPathNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=NarrowPathEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=NarrowPathNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=NarrowPathNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=NarrowPathSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=NarrowPathSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=NarrowPathIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=NarrowPathDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=NarrowPathDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=NarrowPathDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=NarrowPathDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=NarrowPathNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=NarrowPathSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=NarrowPathEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=NarrowPathWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
#pragma mark From StreamPathTileType
    
    else if(fromType==StreamPathTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=StreamPathNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=StreamPathEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=StreamPathNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=StreamPathNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=StreamPathSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=StreamPathSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                // No chunk for this type
                tileType=StreamPathIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=StreamPathDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=StreamPathDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=StreamPathDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=StreamPathDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=StreamPathNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=StreamPathSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=StreamPathEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=StreamPathWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    
#pragma mark From RiverPathTileType
    
    
    
    else if(fromType==RiverPathTileType)
    {
        switch (transitionType) {
            case ThreeSidedTranstionType:
                tileType=NoTileType ;
                break;
            case FourSidedTransitionType:
                tileType=NoTileType ;
                break;
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType ;
                break;
            case NoPathTransitionType:
                tileType=NoTileType ;
                break;
               
            case NorthSouth_PathTransitionType:
                tileType=RiverPathNorthSouth_TileType ;
                break;
            case EastWest_PathTransitionType:
                tileType=RiverPathEastWest_TileType ;
                break;
            case NorthToEast_PathTransitionType:
                tileType=RiverPathNorthToEast_TileType ;
                break;
            case NorthToWest_PathTransitionType:
                tileType=RiverPathNorthToWest_TileType ;
                break;
            case SouthToEast_PathTransitionType:
                tileType=RiverPathSouthToEast_TileType ;
                break;
            case SouthToWest_PathTransitionType:
                tileType=RiverPathSouthToWest_TileType ;
                break;
               
            case Intersection_FourWay_PathTransitionType:
                tileType=RiverPathIntersection_FourWay_TileType ;
                break;
            case DeadEndWest_PathTransitionType:
                tileType=RiverPathDeadEndWest_TileType ;
                break;
            case DeadEndEast_PathTransitionType:
                tileType=RiverPathDeadEndEast_TileType ;
                break;
            case DeadEndNorth_PathTransitionType:
                tileType=RiverPathDeadEndNorth_TileType ;
                break;
            case DeadEndSouth_PathTransitionType:
                tileType=RiverPathDeadEndSouth_TileType ;
                break;
            case ThreeWayNorthPathTransitionType:
                tileType=RiverPathNorthThreeWay_TileType ;
                break;
            case ThreeWaySouthPathTransitionType:
                tileType=RiverPathSouthThreeWay_TileType ;
                break;
            case ThreeWayEastPathTransitionType:
                tileType=RiverPathEastThreeWay_TileType ;
                break;
            case ThreeWayWestPathTransitionType:
                tileType=RiverPathWestThreeWay_TileType ;
                break;
                
            default:
            {
                //NSLog(@"no tiletype");
                break;
            }
        }
    }
    

    
    
    
    
    return tileType;
    
}


-(enum BATransitionType)transitionTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType invalidateMixed:(BOOL)invalidMixed
{
    /*
    if(x==2&&y==2)
    {
        NSLog(@"transitionTypeForTile at %i,%i from %i, to %i",x,y,fromType,toType);
    }
     */
    //NSLog(@"transitionTypeForTile at %i,%i from %i, to %i",x,y,fromType,toType);
    //BOOL North=NO;
    //BOOL NorthEast=NO;
    //BOOL East=NO;
    //BOOL SouthEast=NO;
    //BOOL South=NO;
    //BOOL SouthWest=NO;
    //BOOL West=NO;
    //BOOL NorthWest=NO;
    
    BOOL verbose=NO;
   
    enum BATransitionType tempTransitionType=NoTransitionType;
    //enum BATileType currentTileType=[[mapArray objectAtIndex:row*TOTALMAPSIZE+column]intValue];
    //enum bui
    if([self IsTileType:bitmap atX:x atY:y forTileType:fromType])
    {
        
        
        BATileComparator * comparator=[[BATileComparator alloc]init];
                                       
        [comparator compareBitmapTiletype:bitmap aPosition:CGPointMake(x, y) forType:toType];
        /*
        if(x==2&&y==2)
        {
            [comparator dump];
        }
        */
        //if(fromType==WoodsTileType)
         //   [comparator dump];
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
 

-(U7Shape*)shapeReferenceForTileType:(enum BATileType)tileType
{
    U7Shape * shape;
    
    switch (tileType) {
        case GrassTileType:
            shape=[environment->U7Shapes objectAtIndex:4];
            break;
        case WoodsTileType:
            shape=[environment->U7Shapes objectAtIndex:7];
            break;
        case WaterTileType:
            shape=[environment->U7Shapes objectAtIndex:20];
            break;
        case
            MountainTileType:
            shape=[environment->U7Shapes objectAtIndex:1];
            break;
            
        case GrassToWater_North_TransitionTileType:
        case GrassToWater_InsideCorner_NorthEast_TransitionTileType:
        case GrassToWater_East_TransitionTileType:
        case GrassToWater_InsideCorner_SouthEast_TransitionTileType:
        case GrassToWater_South_TransitionTileType:
        case GrassToWater_InsideCorner_SouthWest_TransitionTileType:
        case GrassToWater_West_TransitionTileType:
        case GrassToWater_InsideCorner_NorthWest_TransitionTileType:
        case GrassToWater_OutsideCorner_NorthEast_TransitionTileType:
        case GrassToWater_OutsideCorner_SouthEast_TransitionTileType:
        case GrassToWater_OutsideCorner_SouthWest_TransitionTileType:
        case GrassToWater_OutsideCorner_NorthWest_TransitionTileType:
            shape=[environment->U7Shapes objectAtIndex:4];
            break;
            
        case WaterToGrass_North_TransitionTileType:
        case WaterToGrass_InsideCorner_NorthEast_TransitionTileType:
        case WaterToGrass_East_TransitionTileType:
        case WaterToGrass_InsideCorner_SouthEast_TransitionTileType:
        case WaterToGrass_South_TransitionTileType:
        case WaterToGrass_InsideCorner_SouthWest_TransitionTileType:
        case WaterToGrass_West_TransitionTileType:
        case WaterToGrass_InsideCorner_NorthWest_TransitionTileType:
        case WaterToGrass_OutsideCorner_NorthEast_TransitionTileType:
        case WaterToGrass_OutsideCorner_SouthEast_TransitionTileType:
        case WaterToGrass_OutsideCorner_SouthWest_TransitionTileType:
        case WaterToGrass_OutsideCorner_NorthWest_TransitionTileType:
                shape=[environment->U7Shapes objectAtIndex:4];
                break;
        default:
            shape=[environment->U7Shapes objectAtIndex:9];
            break;
            break;
    }
    return shape;
    
}

-(int)chunkIDForTileType:(enum BATileType)tileType
{
    //NSLog(@"type %i",tileType);
    switch (tileType) {
        case InvalidTileType:
            return 880;
            break;
        case NoTileType:
            return 1836; //error
            break;
        case SolidRockTileType:
            return 883;
            break;
        case GrassTileType:
            return 1798;
            break;
        case WoodsTileType:
            return 2655;
            break;
        case WaterTileType:
            return 0;
            break;
        case
            MountainTileType:
            return 2819;
            break;
        case
        SwampTileType:
            return 1128;
            break;
        case
        DesertTileType:
            return 228;
            break;
            
        case NarrowPathTileType:
            return 2921;
            break;
        case WidePathTileType:
            return 520;
            break;
            
        case StreamPathTileType:
            return 145;
            break;
            
        case RiverPathTileType:
            return 2600;
            break;
            
        case CarriagePathTileType:
            return 258;
            break;
            
        case NarrowRoadTileType:
            return 240;
            break;
            
        case WideRoadTileType:
            return 464;
            break;
            
        case DungeonPassageTileType:
            return 2477;
            break;
            
#pragma mark Grass to Water Chunk ID
            
        case GrassToWater_North_TransitionTileType:
            return 15;
            break;
        case GrassToWater_OutsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 80;
            break;
        case GrassToWater_East_TransitionTileType:
            return 31;
            break;
        case GrassToWater_OutsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 72;
            break;
        case GrassToWater_South_TransitionTileType:
            return 22;
            break;
        case GrassToWater_OutsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 73;
            break;
        case GrassToWater_West_TransitionTileType:
            return 39;
            break;
        case GrassToWater_OutsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 81;
            break;
            
            
        case GrassToWater_InsideCorner_NorthEast_TransitionTileType :
            return 40;
            break;
        case GrassToWater_InsideCorner_SouthEast_TransitionTileType :
            return 48;
            break;
        case GrassToWater_InsideCorner_SouthWest_TransitionTileType :
            return 66;
            break;
        case GrassToWater_InsideCorner_NorthWest_TransitionTileType :
            return 58;
            break;
            
#pragma mark Grass to Woods Chunk ID
            
        case GrassToWoods_North_TransitionTileType:
            return 2723;
            break;
        case GrassToWoods_East_TransitionTileType:
            return 2650;
            break;
        case GrassToWoods_South_TransitionTileType:
            return 2823;
            break;
        case GrassToWoods_West_TransitionTileType:
            return 2582;
            break;
            
            
        case GrassToWoods_OutsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 2917;
            break;
        case GrassToWoods_OutsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 2585;
            break;
        case GrassToWoods_OutsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 2586;
            break;
        case GrassToWoods_OutsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 2680;
            break;
            
            
        case GrassToWoods_InsideCorner_NorthEast_TransitionTileType :
            return 2702;
            break;
        case GrassToWoods_InsideCorner_SouthEast_TransitionTileType :
            return 2654;
            break;
        case GrassToWoods_InsideCorner_SouthWest_TransitionTileType :
            return 2655;
            break;
        case GrassToWoods_InsideCorner_NorthWest_TransitionTileType :
            return 2701;
            break;
            
#pragma mark Grass to Desert Chunk ID
        case GrassToDesert_North_TransitionTileType:
            return 960;
            break;
        case GrassToDesert_East_TransitionTileType:
            return 963;
            break;
        case GrassToDesert_South_TransitionTileType:
            return 970;
            break;
        case GrassToDesert_West_TransitionTileType:
            return 968;
            break;
            
        case GrassToDesert_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 972;
            break;
        case GrassToDesert_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 964;
            break;
        case GrassToDesert_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 965;
            break;
        case GrassToDesert_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 973;
            break;
       
        case GrassToDesert_OutsideCorner_NorthEast_TransitionTileType:
            return 967;
            break;
        case GrassToDesert_OutsideCorner_SouthEast_TransitionTileType:
            return 975;
            break;
        case GrassToDesert_OutsideCorner_SouthWest_TransitionTileType:
            return 974;
            break;
        case GrassToDesert_OutsideCorner_NorthWest_TransitionTileType:
            return 966;
            break;
#pragma mark Grass to Swamp Chunk ID
            
        case GrassToSwamp_North_TransitionTileType:
            return 1098;
            break;
        case GrassToSwamp_East_TransitionTileType:
            return 1090;
            break;
        case GrassToSwamp_South_TransitionTileType:
            return 1100;
            break;
        case GrassToSwamp_West_TransitionTileType:
            return 1092;
            break;
            
        case GrassToSwamp_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 1075 ;
            break;
        case GrassToSwamp_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 1087 ;
            break;
        case GrassToSwamp_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 1082 ;
            break;
        case GrassToSwamp_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return  1074;
            break;
       
        case GrassToSwamp_OutsideCorner_NorthEast_TransitionTileType:
            return 1084;
            break;
        case GrassToSwamp_OutsideCorner_SouthEast_TransitionTileType:
            return 1076;
            break;
        case GrassToSwamp_OutsideCorner_SouthWest_TransitionTileType:
            return 1073;
            break;
        case GrassToSwamp_OutsideCorner_NorthWest_TransitionTileType:
            return 1081;
            break;
#pragma mark Water to Grass Chunk ID
        case WaterToGrass_North_TransitionTileType:
            return 909;
            break;
        case WaterToGrass_East_TransitionTileType:
            return 2023;
            break;
        case WaterToGrass_South_TransitionTileType:
            return 287;
            break;
        case WaterToGrass_West_TransitionTileType:
            return 260;
            break;
       
            
        case WaterToGrass_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 285 ;
            break;
        case WaterToGrass_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 1583;
            break;
        case WaterToGrass_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 2138;
            break;
        case WaterToGrass_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 286;
            break;
            
        case WaterToGrass_OutsideCorner_NorthEast_TransitionTileType:
            return 2136;
            break;
        case WaterToGrass_OutsideCorner_SouthEast_TransitionTileType:
            return 1581 ;
            break;
        case WaterToGrass_OutsideCorner_SouthWest_TransitionTileType:
            return 2137;
            break;
        case WaterToGrass_OutsideCorner_NorthWest_TransitionTileType:
            return 1862;
            break;
            
#pragma mark Water to Desert Chunk ID
        case WaterToDesert_North_TransitionTileType:
            return 3020;
            break;
        case WaterToDesert_East_TransitionTileType:
            return 3027;
            break;
        case WaterToDesert_South_TransitionTileType:
            return 3021;
            break;
        case WaterToDesert_West_TransitionTileType:
            return 3023;
            break;
            
        case WaterToDesert_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 3024;
            break;
        case WaterToDesert_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 3028;
            break;
        case WaterToDesert_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 3046;
            break;
        case WaterToDesert_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 3034;
            break;
       
        case WaterToDesert_OutsideCorner_NorthEast_TransitionTileType:
            return 3033;
            break;
        case WaterToDesert_OutsideCorner_SouthEast_TransitionTileType:
            return 3049;
            break;
        case WaterToDesert_OutsideCorner_SouthWest_TransitionTileType:
            return 3037;
            break;
        case WaterToDesert_OutsideCorner_NorthWest_TransitionTileType:
            return 3032;
            break;
            
#pragma mark Woods to Grass Chunk ID

        case WoodsToGrass_Solo_TransitionTileType:
            return 167;
            break;
        case WoodsToGrass_North_TransitionTileType:
            return 2823;
            break;
        case WoodsToGrass_East_TransitionTileType:
            return 2582;
            break; 
        case WoodsToGrass_South_TransitionTileType:
            return 2723;
            break;
        case WoodsToGrass_West_TransitionTileType:
            return 2650;
            break;
            
        case WoodsToGrass_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 2916;
            break;
        case WoodsToGrass_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 2680;
            break;
        case WoodsToGrass_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 2917;
            break;
        case WoodsToGrass_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 2585;
            break;
       
        case WoodsToGrass_OutsideCorner_NorthEast_TransitionTileType:
            return 2655;
            break;
        case WoodsToGrass_OutsideCorner_SouthEast_TransitionTileType:
            return 2701;
            break;
        case WoodsToGrass_OutsideCorner_SouthWest_TransitionTileType:
            return 2702;
            break;
        case WoodsToGrass_OutsideCorner_NorthWest_TransitionTileType:
            return 2654;
            break;
    
            
        
            
        //Swamp to Grass
#pragma mark Swamp to Grass Chunk ID
        case SwampToGrass_Solo_TransitionTileType:
            return 1112;
            break;
            
        case SwampToGrass_North_TransitionTileType:
            return 1100;
            break;
        case SwampToGrass_East_TransitionTileType:
            return 1092;
            break;
        case SwampToGrass_South_TransitionTileType:
            return 1098;
            break;
        case SwampToGrass_West_TransitionTileType:
            return 1090;
            break;
            
        case SwampToGrass_InsideCorner_NorthEast_TransitionTileType:
            return 1073;
            break;
        case SwampToGrass_InsideCorner_SouthEast_TransitionTileType:
            return 1081;
            break;
        case SwampToGrass_InsideCorner_SouthWest_TransitionTileType:
            return 1084;
            break;
        case SwampToGrass_InsideCorner_NorthWest_TransitionTileType:
            return 1076 ;
            break;
       
        case SwampToGrass_OutsideCorner_NorthEast_TransitionTileType:
            return 1082;
            break;
        case SwampToGrass_OutsideCorner_SouthEast_TransitionTileType:
            return 1074;
            break;
        case SwampToGrass_OutsideCorner_SouthWest_TransitionTileType:
            return 1075;
            break;
        case SwampToGrass_OutsideCorner_NorthWest_TransitionTileType:
            return 1087;
            break;
            //Swamp to Grass

            //Swamp to Grass
#pragma mark Swamp to Water Chunk ID
            case SwampToWater_North_TransitionTileType:
                return 2;
                break;
            case SwampToWater_East_TransitionTileType:
                return 2;
                break;
            case SwampToWater_South_TransitionTileType:
                return 2;
                break;
            case SwampToWater_West_TransitionTileType:
                return 2;
                break;
                
            case SwampToWater_InsideCorner_NorthEast_TransitionTileType:
                //return 40;
                return 2;
                break;
            case SwampToWater_InsideCorner_SouthEast_TransitionTileType:
                //return 48; 3032 76 78
                return 2;
                break;
            case SwampToWater_InsideCorner_SouthWest_TransitionTileType:
                //return 66; 3031 75
                return 2;
                break;
            case SwampToWater_InsideCorner_NorthWest_TransitionTileType:
                //return 58;
                return 2;
                break;
           
            case SwampToWater_OutsideCorner_NorthEast_TransitionTileType:
                return 2;
                break;
            case SwampToWater_OutsideCorner_SouthEast_TransitionTileType:
                return 2;
                break;
            case SwampToWater_OutsideCorner_SouthWest_TransitionTileType:
                return 2;
                break;
            case SwampToWater_OutsideCorner_NorthWest_TransitionTileType:
                return 2;
                break;

#pragma mark Swamp to Mountain Chunk ID
        case SwampToMountain_North_TransitionTileType:
            return 2;
            break;
        case SwampToMountain_East_TransitionTileType:
            return 2;
            break;
        case SwampToMountain_South_TransitionTileType:
            return 2;
            break;
        case SwampToMountain_West_TransitionTileType:
            return 2;
            break;
            
        case SwampToMountain_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 2;
            break;
        case SwampToMountain_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 2;
            break;
        case SwampToMountain_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 2;
            break;
        case SwampToMountain_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 2;
            break;
       
        case SwampToMountain_OutsideCorner_NorthEast_TransitionTileType:
            return 2;
            break;
        case SwampToMountain_OutsideCorner_SouthEast_TransitionTileType:
            return 2;
            break;
        case SwampToMountain_OutsideCorner_SouthWest_TransitionTileType:
            return 2;
            break;
        case SwampToMountain_OutsideCorner_NorthWest_TransitionTileType:
            return 2;
            break;
            
#pragma mark Mountain To Grass Chunk ID
    //Mountain to Grass
                
        case MountainToGrass_North_TransitionTileType:
            return 2844;
            break;
        case MountainToGrass_East_TransitionTileType:
            return 1386;
            break;
        case MountainToGrass_South_TransitionTileType:
            return 730;
            break;
        case MountainToGrass_West_TransitionTileType:
            return 2841;
            break;
            
        case MountainToGrass_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 721;
            break;
        case MountainToGrass_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 2836;
            break;
        case MountainToGrass_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 722;
            break;
        case MountainToGrass_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 2833;
            break;
       
        case MountainToGrass_OutsideCorner_NorthEast_TransitionTileType:
            return 726;
            break;
        case MountainToGrass_OutsideCorner_SouthEast_TransitionTileType:
            return 2837;
            break;
        case MountainToGrass_OutsideCorner_SouthWest_TransitionTileType:
            return 725;
            break;
        case MountainToGrass_OutsideCorner_NorthWest_TransitionTileType:
            return 727;
            break;
            
#pragma mark Mountain To Water Chunk ID
        
        case MountainToWater_North_TransitionTileType:
            return 747;
            break;
        case MountainToWater_East_TransitionTileType:
            return 745;
            break;
        case MountainToWater_South_TransitionTileType:
            return 746;
            break;
        case MountainToWater_West_TransitionTileType:
            return 744;
            break;
            
        case MountainToWater_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 737;
            break;
        case MountainToWater_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 739;
            break;
        case MountainToWater_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 738;
            break;
        case MountainToWater_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 736;
            break;
       
        case MountainToWater_OutsideCorner_NorthEast_TransitionTileType:
            return 742 ;
            break;
        case MountainToWater_OutsideCorner_SouthEast_TransitionTileType:
            return 740 ;
            break;
        case MountainToWater_OutsideCorner_SouthWest_TransitionTileType:
            return 741 ;
            break;
        case MountainToWater_OutsideCorner_NorthWest_TransitionTileType:
            return 743 ;
            break;
            
#pragma mark Mountain To Water Swamp ID
        
        case MountainToSwamp_North_TransitionTileType:
            return 747;
            break;
        case MountainToSwamp_East_TransitionTileType:
            return 745;
            break;
        case MountainToSwamp_South_TransitionTileType:
            return 746;
            break;
        case MountainToSwamp_West_TransitionTileType:
            return 744;
            break;
            
        case MountainToSwamp_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 742;
            break;
        case MountainToSwamp_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 740;
            break;
        case MountainToSwamp_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 741;
            break;
        case MountainToSwamp_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 743;
            break;
       
        case MountainToSwamp_OutsideCorner_NorthEast_TransitionTileType:
            return 737;
            break;
        case MountainToSwamp_OutsideCorner_SouthEast_TransitionTileType:
            return 739;
            break;
        case MountainToSwamp_OutsideCorner_SouthWest_TransitionTileType:
            return 738;
            break;
        case MountainToSwamp_OutsideCorner_NorthWest_TransitionTileType:
            return 736;
            break;
            
#pragma mark Mountain to Desert Chunk ID
            
            
        case MountainToDesert_North_TransitionTileType:
            return 763;
            break;
        case MountainToDesert_East_TransitionTileType:
            return 761;
            break;
        case MountainToDesert_South_TransitionTileType:
            return 765;
            break;
        case MountainToDesert_West_TransitionTileType:
            return 760;
            break;
            
        case MountainToDesert_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 758;
            break;
        case MountainToDesert_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 756;
            break;
        case MountainToDesert_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 757;
            break;
        case MountainToDesert_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 759;
            break;
       
        case MountainToDesert_OutsideCorner_NorthEast_TransitionTileType:
            return 769;
            break;
        case MountainToDesert_OutsideCorner_SouthEast_TransitionTileType:
            return 755;
            break;
        case MountainToDesert_OutsideCorner_SouthWest_TransitionTileType:
            return 754;
            break;
        case MountainToDesert_OutsideCorner_NorthWest_TransitionTileType:
            return 768;
            break;
      
            
            
#pragma mark Desert To Grass Chunk ID
    //Desert to Grass
            
        case DesertToGrass_Solo_TransitionTileType:
            return 1942;
            break;
            
        case DesertToGrass_North_TransitionTileType:
            return 970;
            break;
        case DesertToGrass_East_TransitionTileType:
            return 968;
            break;
        case DesertToGrass_South_TransitionTileType:
            return 960;
            break;
        case DesertToGrass_West_TransitionTileType:
            return 963;
            break;
            
        case DesertToGrass_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 965;
            break;
        case DesertToGrass_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 973;
            break;
        case DesertToGrass_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 972;
            break;
        case DesertToGrass_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 964;
            break;
       
        case DesertToGrass_OutsideCorner_NorthEast_TransitionTileType:
            return 974;
            break;
        case DesertToGrass_OutsideCorner_SouthEast_TransitionTileType:
            return 966;
            break;
        case DesertToGrass_OutsideCorner_SouthWest_TransitionTileType:
            return 967;
            break;
        case DesertToGrass_OutsideCorner_NorthWest_TransitionTileType:
            return 975;
            break;
            
#pragma mark Desert To Water Chunk ID
        
        case DesertToWater_North_TransitionTileType:
            return 3021;
            break;
        case DesertToWater_East_TransitionTileType:
            return 3023;
            break;
        case DesertToWater_South_TransitionTileType:
            return 3020;
            break;
        case DesertToWater_West_TransitionTileType:
            return 3027;
            break;
            
        case DesertToWater_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 3046;
            break;
        case DesertToWater_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 3034;
            break;
        case DesertToWater_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 3033;
            break;
        case DesertToWater_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 3028;
            break;
       
        case DesertToWater_OutsideCorner_NorthEast_TransitionTileType:
            return 3037 ;
            break;
        case DesertToWater_OutsideCorner_SouthEast_TransitionTileType:
            return 3032 ;
            break;
        case DesertToWater_OutsideCorner_SouthWest_TransitionTileType:
            return  3024;
            break;
        case DesertToWater_OutsideCorner_NorthWest_TransitionTileType:
            return 3049 ;
            break;

#pragma mark Desert To Mountain Chunk ID
        
        case DesertToMountain_North_TransitionTileType:
            return 765;
            break;
        case DesertToMountain_East_TransitionTileType:
            return 760;
            break;
        case DesertToMountain_South_TransitionTileType:
            return 763;
            break;
        case DesertToMountain_West_TransitionTileType:
            return 761;
            break;
            
        case DesertToMountain_InsideCorner_NorthEast_TransitionTileType:
            //return 40;
            return 757;
            break;
        case DesertToMountain_InsideCorner_SouthEast_TransitionTileType:
            //return 48; 3032 76 78
            return 759;
            break;
        case DesertToMountain_InsideCorner_SouthWest_TransitionTileType:
            //return 66; 3031 75
            return 758;
            break;
        case DesertToMountain_InsideCorner_NorthWest_TransitionTileType:
            //return 58;
            return 756;
            break;
       
        case DesertToMountain_OutsideCorner_NorthEast_TransitionTileType:
            return 754 ;
            break;
        case DesertToMountain_OutsideCorner_SouthEast_TransitionTileType:
            return 768 ;
            break;
        case DesertToMountain_OutsideCorner_SouthWest_TransitionTileType:
            return 769 ;
            break;
        case DesertToMountain_OutsideCorner_NorthWest_TransitionTileType:
            return 755 ;
            break;
            
        
        case StoneCaveAreaTileType:
            return 891;
            break;
            
        case StoneCaveAreaNorthWallTileType:
            return 1355;
            break;
        case StoneCaveAreaSouthWallTileType:
            return 1352;
            break;
        case StoneCaveAreaEastWallTileType:
            return 1353;
            break;
        case StoneCaveAreaWestWallTileType:
            return 174;
            break;
            
        case StoneCaveNorthEastCornerTileType:
            return 2018;
            break;
        case StoneCaveNorthWestCornerTileType:
            return 2017;
            break;
        case StoneCaveSouthEastCornerTileType:
            return 2058;
            break;
        case StoneCaveSouthWestCornerTileType:
            return 2057;
            break;
    
        case CavePassageNorthSouth_TileType:
            return 1326;
            break; //1325, 1628
        case CavePassageEastWest_TileType:
            return 1619;
            break; // 1623, 2319, 1617, 1619, 1618
        case CavePassageNorthToEast_TileType:
            return 1322;
            break; // 2019
        case CavePassageNorthToWest_TileType:
            return 1324;
            break; // 2052,
        case CavePassageSouthToEast_TileType:
            return 1320;
            break; // 1327, 2279
        case CavePassageSouthToWest_TileType:
            return 1591;
            break; // 2278
        case CavePassageIntersection_FourWay_TileType:
            return 1264;
            break; //2318
        case CavePassageDeadEndWest_TileType:
            return 1351;
            break; //
        case CavePassageDeadEndEast_TileType:
            return 1350;
            break; // 1347, 1346
        case CavePassageDeadEndNorth_TileType:
            return 1340;
            break; // 1341
        case CavePassageDeadEndSouth_TileType:
            return 1349;
            break; // 1348, 1345,1344
        case CaveCornerNorthWest_TileType:
            return 2017;
            break; // 2105
        case CaveCornerNorthEast_TileType:
            return 2018;
            break; //
        case CaveCornerSouthWest_TileType:
            return 2055;
            break; // 2057
        case CaveCornerSouthEast_TileType:
            return 20158;
            break; //
#pragma mark Dirt Cave Passage Chunk ID
        case DirtCavePassageTileType:
            return 2044;
            break;
        case DirtCavePassageNorthSouth_TileType:
            return 1550;
            break;
        case DirtCavePassageEastWest_TileType:
            return 1970;
            break;
        case DirtCavePassageNorthToEast_TileType:
            return 1566 ;
            break; // 2019
        case DirtCavePassageNorthToWest_TileType:
            return 1567;
            break; // 2052,
        case DirtCavePassageSouthToEast_TileType:
            return 1558;
            break; // 1327, 2279
        case DirtCavePassageSouthToWest_TileType:
            return 1461 ;
            break; // 2278
        case DirtCavePassageIntersection_FourWay_TileType:
            return 1782;
            break; //2318
        case DirtCavePassageDeadEndWest_TileType:
            return 179;
            break; //
        case DirtCavePassageDeadEndEast_TileType:
            return 178;
            break; // 1347, 1346
        case DirtCavePassageDeadEndNorth_TileType:
            return 182;
            break; // 1341
        case DirtCavePassageDeadEndSouth_TileType:
            return 1805;
            break; // 1348, 1345,1344
        case DirtCavePassageNorthThreeWay_TileType:
            return 1285;
            break; //
        case DirtCavePassageSouthThreeWay_TileType:
            return 1284;
            break; //
        case DirtCavePassageEastThreeWay_TileType:
            return 1286;
            break; //
        case DirtCavePassageWestThreeWay_TileType:
            return 1287;
            break; //
        
        
        case DirtCaveCornerNorthWest_TileType:
            return 2055 ;
            break; // 2105
        case DirtCaveCornerNorthEast_TileType:
            return 20158;
            break; //
        case DirtCaveCornerSouthWest_TileType:
            return 2017;
            break; // 2057
        case DirtCaveCornerSouthEast_TileType:
            return 2018 ;
            break; //
    
#pragma mark DungeonTileType Chunk ID
            
        case DungeonTileType:
            return 2381;
            break; //
         
        case DungeonAreaNorthWallTileType:
            return 2390;
            break;
        case DungeonAreaSouthWallTileType:
            return 2574;
            break;
        case DungeonAreaEastWallTileType:
            return 2391;
            break;
        case DungeonAreaWestWallTileType:
            return 2576;
            break;
        
        case DungeonCornerNorthWest_TileType:
            return 2457;
            break; //
        case DungeonCornerNorthEast_TileType:
            return 2458;
            break; //
        case DungeonCornerSouthWest_TileType:
            return 2465;
            break; //
        case DungeonCornerSouthEast_TileType:
            return 2466;
            //;
            break; //
        
        
            
            
        case DungeonNorthEastOutsideCornerBAAreaType:
            return 2529;
            break; //
        case DungeonNorthWestOutsideCornerBAAreaType:
            return 2530;
            break; //
        case DungeonSouthEastOutsideCornerBAAreaType:
            return 2521;
            break; //
        case DungeonSouthWestOutsideCornerBAAreaType:
            return 2522;
            break; //
            
        case DungeonSouthWestSouthEastOutsideCornerBAAreaType:
            return 2523;
            break; //
        case DungeonNorthEastSouthEastOutsideCornerBAAreaType:
            return 2524;
            break; //
        case DungeonNorthWestSouthWestOutsideCornerBAAreaType:
            return 2532;
            break; //
        case DungeonNorthWestNorthEastOutsideCornerBAAreaType:
            return 2575;
            break; //
        case DungeonNorthWestSouthEastOutsideCornerBAAreaType:
            return 1836;
            break; //
        case DungeonSouthWestNorthEastOutsideCornerBAAreaType:
            return 1836;
            break; //
            
        case DungeonNorthWestSouthWestSouthEastOutsideCornerBAAreaType:
            return 2525;
            break; //
        case DungeonNorthEastSouthWestSouthEastOutsideCornerBAAreaType:
            return 2526;
            break; //
        case  DungeonNorthWestNorthEastSouthWestOutsideCornerBAAreaType:
            return 2533;
            break; //
        case  DungeonNorthWestNorthEastSouthEastOutsideCornerBAAreaType:
            return 2534;
            break; //
            
        case  DungeonFourWayOutsideCornerBAAreaType:
            return 2451;
            break; //
        case DungeonDeadEndWest_TileType:
            return 2497;
            break; //
            
#pragma mark DungeonPassageChunk ID
        
        case DungeonPassageNorthSouth_TileType:
            return 2477;
            break; //
        case DungeonPassageEastWest_TileType:
            return 2473;
            break; //
            
        case DungeonPassageNorthToEast_TileType:
            return 2493;
            break; //
        case DungeonPassageNorthToWest_TileType:
            return 2494 ;
            break; //
        case DungeonPassageSouthToEast_TileType:
            return 2485 ;
            break; //
        case DungeonPassageSouthToWest_TileType:
            return 2486;
            break; //
            
        case DungeonPassageIntersection_FourWay_TileType:
            return 2543;
            break;
        case DungeonPassageDeadEndWest_TileType:
            return 2132;
            break;
        case DungeonPassageDeadEndEast_TileType:
            return 2503;
            break; //
        case DungeonPassageDeadEndNorth_TileType:
            return 2509;
            break; //
        case DungeonPassageDeadEndSouth_TileType:
            return 2504;
            break; // 2501
            
        case DungeonPassageNorthThreeWay_TileType:
            return 2518;
            break; // 2501
        case DungeonPassageSouthThreeWay_TileType:
            return 2517;
            break; // 2501
        case DungeonPassageEastThreeWay_TileType:
            return 2519;
            break; // 2501
        case DungeonPassageWestThreeWay_TileType:
            return 2520;
            break; // 2501
            
#pragma mark Wide Road Chunk ID
            
        case WideRoadNorthSouth_TileType:
            return 464;
            break; //239
        case WideRoadEastWest_TileType:
            return 238;
            break; //381
        case WideRoadNorthToEast_TileType:
            return 270 ;
            break; //
        case WideRoadNorthToWest_TileType:
            return 271 ;
            break; //
        case WideRoadSouthToEast_TileType:
            return 262;
            break; //
        case WideRoadSouthToWest_TileType:
            return 263;
            break; //
        case WideRoadIntersection_FourWay_TileType:
            return 234;
            break; //
        case WideRoadDeadEndWest_TileType:
            return 457;
            break; //
        case WideRoadDeadEndEast_TileType:
            return 459;
            break; //
        case WideRoadDeadEndNorth_TileType:
            return 458;
            break; //
        case WideRoadDeadEndSouth_TileType:
            return 456;
            break; //
        case WideRoadNorthThreeWay_TileType:
            return 268;
            break; //
        case WideRoadSouthThreeWay_TileType:
            return 261;
            break; //
        case WideRoadEastThreeWay_TileType:
            return 232;
            break; //
        case WideRoadWestThreeWay_TileType:
            return 269;
            break; //
            
#pragma mark Narrow Road Chunk ID
        case NarrowRoadNorthSouth_TileType:
            return 240;
            break; //239
        case NarrowRoadEastWest_TileType:
            return 254;
            break; //381
        case NarrowRoadNorthToEast_TileType:
            return 244 ;
            break; //
        case NarrowRoadNorthToWest_TileType:
            return 245 ;
            break; //
        case NarrowRoadSouthToEast_TileType:
            return 242;
            break; //
        case NarrowRoadSouthToWest_TileType:
            return 243;
            break; //
        case NarrowRoadIntersection_FourWay_TileType:
            return 250;
            break; //
        case NarrowRoadDeadEndWest_TileType:
            return 254;
            break; //
        case NarrowRoadDeadEndEast_TileType:
            return 254;
            break; //
        case NarrowRoadDeadEndNorth_TileType:
            return 240;
            break; //
        case NarrowRoadDeadEndSouth_TileType:
            return 240;
            break; //
        case NarrowRoadNorthThreeWay_TileType:
            return 255;
            break; //
        case NarrowRoadSouthThreeWay_TileType:
            return 251;
            break; //
        case NarrowRoadEastThreeWay_TileType:
            return 247;
            break; //
        case NarrowRoadWestThreeWay_TileType:
            return 249;
            break; //
          

    
#pragma mark CarriagePath Chunk ID
        case CarriagePathNorthSouth_TileType:
            return 259;
            break; //239
        case CarriagePathEastWest_TileType:
            return 266;
            break; //381
        case CarriagePathNorthToEast_TileType:
            return 468 ;
            break; //
        case CarriagePathNorthToWest_TileType:
            return 469;
            break; //
        case CarriagePathSouthToEast_TileType:
            return 460;
            break; //
        case CarriagePathSouthToWest_TileType:
            return 461;
            break; //
        case CarriagePathIntersection_FourWay_TileType:
            return 332;
            break; //
        case CarriagePathDeadEndWest_TileType:
            return 327;
            break; //
        case CarriagePathDeadEndEast_TileType:
            return 326;
            break; //
        case CarriagePathDeadEndNorth_TileType:
            return 343;
            break; //
        case CarriagePathDeadEndSouth_TileType:
            return 342;
            break; //
        case CarriagePathNorthThreeWay_TileType:
            return 336;
            break; //
        case CarriagePathSouthThreeWay_TileType:
            return 334;
            break; //
        case CarriagePathEastThreeWay_TileType:
            return 333;
            break; //
        case CarriagePathWestThreeWay_TileType:
            return 341;
            break; //
            
    
#pragma mark WidePath Chunk ID
        case WidePathNorthSouth_TileType:
            return 520;
            break; //239
        case WidePathEastWest_TileType:
            return 264;
            break; //381
        case WidePathNorthToEast_TileType:
            return 322;
            break; //
        case WidePathNorthToWest_TileType:
            return 323;
            break; //
        case WidePathSouthToEast_TileType:
            return 320;
            break; //
        case WidePathSouthToWest_TileType:
            return 321;
            break; //
        case WidePathIntersection_FourWay_TileType:
            return 335;
            break; //
        case WidePathDeadEndWest_TileType:
            return 327;
            break; //
        case WidePathDeadEndEast_TileType:
            return 326;
            break; //
        case WidePathDeadEndNorth_TileType:
            return 343;
            break; //
        case WidePathDeadEndSouth_TileType:
            return 342;
            break; //
        case WidePathNorthThreeWay_TileType:
            return 336;
            break; //
        case WidePathSouthThreeWay_TileType:
            return 334;
            break; //
        case WidePathEastThreeWay_TileType:
            return 333;
            break; //
        case WidePathWestThreeWay_TileType:
            return 341;
            break; //
            
#pragma mark NarrowPath Chunk ID
        case NarrowPathNorthSouth_TileType:
            return 2920;
            break; //239
        case NarrowPathEastWest_TileType:
            return 2922;
            break; //381
        case NarrowPathNorthToEast_TileType:
            return 2926;
            break; //
        case NarrowPathNorthToWest_TileType:
            return 2927;
            break; //
        case NarrowPathSouthToEast_TileType:
            return 2910;
            break; //
        case NarrowPathSouthToWest_TileType:
            return 2911;
            break; //
        case NarrowPathIntersection_FourWay_TileType:
            return 335;
            break; //
        case NarrowPathDeadEndWest_TileType:
            return 3044;
            break; //
        case NarrowPathDeadEndEast_TileType:
            return 3043;
            break; //
        case NarrowPathDeadEndNorth_TileType:
            return 3050;
            break; //
        case NarrowPathDeadEndSouth_TileType:
            return 3048;
            break; //
        case NarrowPathNorthThreeWay_TileType:
            return 3051;
            break; //
        case NarrowPathSouthThreeWay_TileType:
            return 2925;
            break; //
        case NarrowPathEastThreeWay_TileType:
            return 2924;
            break; //
        case NarrowPathWestThreeWay_TileType:
            return 3052;
            break; //
            
#pragma mark StreamPath Chunk ID
        case StreamPathNorthSouth_TileType:
            return 1980;
            break; //239
        case StreamPathEastWest_TileType:
            return 1981;
            break; //381
        case StreamPathNorthToEast_TileType:
            return 143;
            break; //
        case StreamPathNorthToWest_TileType:
            return 1991;
            break; //
        case StreamPathSouthToEast_TileType:
            return 94;
            break; //
        case StreamPathSouthToWest_TileType:
            return 144;
            break; //
        case StreamPathIntersection_FourWay_TileType:
            return 0;
            break; //
        case StreamPathDeadEndWest_TileType:
            return 1998;
            break; //
        case StreamPathDeadEndEast_TileType:
            return 1999;
            break; //
        case StreamPathDeadEndNorth_TileType:
            return 283;
            break; //
        case StreamPathDeadEndSouth_TileType:
            return 1996;
            break; //
        case StreamPathNorthThreeWay_TileType:
            return 131;
            break; //
        case StreamPathSouthThreeWay_TileType:
            return 150;
            break; //
        case StreamPathEastThreeWay_TileType:
            return 135;
            break; //
        case StreamPathWestThreeWay_TileType:
            return 13;
            break; //
            
#pragma mark RiverPath Chunk ID
        case RiverPathNorthSouth_TileType:
            return 2600;
            break; //239
        case RiverPathEastWest_TileType:
            return 2601;
            break; //381
        case RiverPathNorthToEast_TileType:
            return 2610;
            break; //
        case RiverPathNorthToWest_TileType:
            return 2611;
            break; //
        case RiverPathSouthToEast_TileType:
            return 2802;
            break; //
        case RiverPathSouthToWest_TileType:
            return 2603;
            break; //
        case RiverPathIntersection_FourWay_TileType:
            return 0;
            break; //
        case RiverPathDeadEndWest_TileType:
            return 0;
            break; //
        case RiverPathDeadEndEast_TileType:
            return 0;
            break; //
        case RiverPathDeadEndNorth_TileType:
            return 283;
            break; //
        case RiverPathDeadEndSouth_TileType:
            return 284;
            break; //
        case RiverPathNorthThreeWay_TileType:
            return 2615;
            break; //
        case RiverPathSouthThreeWay_TileType:
            return 0;
            break; //
        case RiverPathEastThreeWay_TileType:
            return 0;
            break; //
        case RiverPathWestThreeWay_TileType:
            return 0;
            break; //
            
        default:
            return 1836;
            break;
    }
    
    return NoTileType;
}

-(enum BATileType)TileTypeForSymbol:(NSString*)theSymbol
{
    int symbol=[theSymbol intValue];
    //
    NSLog(@"%i",symbol);
    switch (symbol) {
        case 1:
            return GrassTileType;
            break;
        case 0:
            return WoodsTileType;
            break;
        case 3:
            return WaterTileType;
            break;
        case 4:
            return MountainTileType;
            break;
            
        //grass transition
        case 5:
            return GrassToWater_North_TransitionTileType;
            break;
        case 6:
            return GrassToWater_InsideCorner_NorthEast_TransitionTileType;
            break;
        case 7:
            return GrassToWater_East_TransitionTileType;
            break;
        case 8:
            return GrassToWater_InsideCorner_SouthEast_TransitionTileType;
            break;
        case 9:
            return GrassToWater_South_TransitionTileType;
            break;
        case 10:
            return GrassToWater_InsideCorner_SouthWest_TransitionTileType;
            break;
        case 11:
            return GrassToWater_West_TransitionTileType;
            break;
        case 12:
            return GrassToWater_InsideCorner_NorthWest_TransitionTileType;
            break;
        case 13:
            return GrassToWater_OutsideCorner_NorthEast_TransitionTileType;
            break;
        case 14:
            return GrassToWater_OutsideCorner_SouthEast_TransitionTileType;
            break;
        case 15:
            return GrassToWater_OutsideCorner_SouthWest_TransitionTileType;
            break;
        case 16:
            return GrassToWater_OutsideCorner_NorthWest_TransitionTileType;
            break;
            
            
        case 17:
            return WaterToGrass_North_TransitionTileType;
            break;
        case 18:
            return WaterToGrass_East_TransitionTileType;
            break;
        case 19:
            return WaterToGrass_South_TransitionTileType;
            break;
        case 20:
            return WaterToGrass_West_TransitionTileType;
            break;
        case 21:
            return WaterToGrass_InsideCorner_NorthEast_TransitionTileType;
            break;
        case 22:
            return WaterToGrass_InsideCorner_SouthEast_TransitionTileType;
            break;
        case 23:
            return WaterToGrass_InsideCorner_SouthWest_TransitionTileType;
            break;
        case 24:
            return WaterToGrass_InsideCorner_NorthWest_TransitionTileType;
            break;
        case 25:
            return WaterToGrass_OutsideCorner_NorthEast_TransitionTileType;
            break;
        case 26:
            return WaterToGrass_OutsideCorner_SouthEast_TransitionTileType;
            break;
        case 27:
            return WaterToGrass_OutsideCorner_SouthWest_TransitionTileType;
            break;
        case 28:
            return WaterToGrass_OutsideCorner_NorthWest_TransitionTileType;
            break;
        default:
            break;
    }
    return 0;
}

-(BAIntBitmap*)tileBitmapForDungeon:(BAIntBitmap*)dungeonBitmap
{
    if(!dungeonBitmap)
        return NULL;
    BAIntBitmap * newBitmap=[BAIntBitmap createWithCGSize:dungeonBitmap->size];
    for(int y=0;y<newBitmap->size.height;y++)
    {
        for(int x=0;x<newBitmap->size.width;x++)
        {
            int value=[dungeonBitmap valueAtPosition:CGPointMake(x, y) from:@"BAU7BitmapInterpreter tileBitmapForDungeon"];
            
            enum BATileType tileType=NoTileType;
            if(value==0)
                tileType=SolidRockTileType;
            else if(value==1)
            {
                enum BAAreaType areaType=[self areaTypeForTile:dungeonBitmap atX:x atY:y fromTileType:AreaTileType];
                tileType=[self tileTypeForAreaType:areaType forEnvironmentType:dungeonTileSetType];
            }
            else if(value==2)
            {
                enum BAPathType pathType=[self pathTypeForTile:dungeonBitmap atX:x atY:y fromTileType:NarrowPathTileType];
                tileType=[self tileTypeForPathType:pathType forTileType:dungeonTileSetType];
            }
               
            
            [newBitmap setValueAtPosition:tileType forPosition:CGPointMake(x, y)];
            
        }
    }
    
    
    return newBitmap;
}

-(enum BATileType)tileTypeForPathType:(enum BAPathType)pathType forTileType:(enum BATileSetType)tileSetType
{
    enum BATileType tileType=NoTileType;
    
    switch (tileSetType) {
        case dirtCaveTileSetType:
            {
                if(pathType==Intersection_FourWay_PathType)
                    return DirtCavePassageIntersection_FourWay_TileType;
                
                //corners
                else if(pathType==NorthToWest_PathType)
                    return DirtCavePassageNorthToWest_TileType;
                else if(pathType==NorthToEast_PathType)
                    return DirtCavePassageNorthToEast_TileType;
                else if(pathType==SouthToEast_PathType)
                    return DirtCavePassageSouthToEast_TileType;
                else if(pathType==SouthToWest_PathType)
                    return DirtCavePassageSouthToWest_TileType;
                //passages
                
                else if(pathType==NorthSouth_PathType)
                    return DirtCavePassageNorthSouth_TileType;
                else if(pathType==EastWest_PathType)
                    return DirtCavePassageEastWest_TileType;
                
                //deadends
                else if(pathType==DeadEndWest_PathType)
                    return DirtCavePassageDeadEndWest_TileType;
                else if(pathType==DeadEndEast_PathType)
                    return DirtCavePassageDeadEndEast_TileType;
                else if(pathType==DeadEndNorth_PathType)
                    return DirtCavePassageDeadEndNorth_TileType;
                else if(pathType==DeadEndSouth_PathType)
                    return DirtCavePassageDeadEndSouth_TileType;
                
                //Threeway
                else if(pathType==ThreeWayNorthPathType)
                    return DirtCavePassageNorthThreeWay_TileType;
                else if(pathType==ThreeWaySouthPathType)
                    return DirtCavePassageSouthThreeWay_TileType;
                else if(pathType==ThreeWayEastPathType)
                    return DirtCavePassageEastThreeWay_TileType;
                else if(pathType==ThreeWayWestPathType)
                    return DirtCavePassageWestThreeWay_TileType;
            }
            break;

        case pavedRoadTileSetType:
            {
                if(pathType==Intersection_FourWay_PathType)
                    return WideRoadIntersection_FourWay_TileType;
                //corners
                else if(pathType==NorthToWest_PathType)
                    return WideRoadNorthToWest_TileType;
                else if(pathType==NorthToEast_PathType)
                    return WideRoadNorthToEast_TileType;
                else if(pathType==SouthToEast_PathType)
                    return WideRoadSouthToEast_TileType;
                else if(pathType==SouthToWest_PathType)
                    return WideRoadSouthToWest_TileType;
                //passages
                
                else if(pathType==NorthSouth_PathType)
                    return WideRoadNorthSouth_TileType;
                else if(pathType==EastWest_PathType)
                    return WideRoadEastWest_TileType;
                
                //deadends
                else if(pathType==DeadEndWest_PathType)
                    return WideRoadDeadEndWest_TileType;
                else if(pathType==DeadEndEast_PathType)
                    return WideRoadDeadEndEast_TileType;
                else if(pathType==DeadEndNorth_PathType)
                    return WideRoadDeadEndNorth_TileType;
                else if(pathType==DeadEndSouth_PathType)
                    return WideRoadDeadEndSouth_TileType;
                
                //Threeway
                else if(pathType==ThreeWayNorthPathType)
                    return NoTileType;
                else if(pathType==ThreeWaySouthPathType)
                    return NoTileType;
                else if(pathType==ThreeWayEastPathType)
                    return NoTileType;
                else if(pathType==ThreeWayWestPathType)
                    return NoTileType;
            }
            break;
        case stoneCaveTileSetType:
            {
                if(pathType==Intersection_FourWay_PathType)
                    return DungeonPassageIntersection_FourWay_TileType;
                //corners
                else if(pathType==NorthToWest_PathType)
                    return CavePassageNorthToWest_TileType;
                else if(pathType==NorthToEast_PathType)
                    return CavePassageNorthToEast_TileType;
                else if(pathType==SouthToEast_PathType)
                    return CavePassageSouthToEast_TileType;
                else if(pathType==SouthToWest_PathType)
                    return CavePassageSouthToWest_TileType;
                //passages
                
                else if(pathType==NorthSouth_PathType)
                    return CavePassageNorthSouth_TileType;
                else if(pathType==EastWest_PathType)
                    return CavePassageEastWest_TileType;
                
                //deadends
                else if(pathType==DeadEndWest_PathType)
                    return CavePassageDeadEndWest_TileType;
                else if(pathType==DeadEndEast_PathType)
                    return CavePassageDeadEndEast_TileType;
                else if(pathType==DeadEndNorth_PathType)
                    return CavePassageDeadEndNorth_TileType;
                else if(pathType==DeadEndSouth_PathType)
                    return CavePassageDeadEndSouth_TileType;
                
                //Threeway
                else if(pathType==ThreeWayNorthPathType)
                    return NoTileType;
                else if(pathType==ThreeWaySouthPathType)
                    return NoTileType;
                else if(pathType==ThreeWayEastPathType)
                    return NoTileType;
                else if(pathType==ThreeWayWestPathType)
                    return NoTileType;
            }
            break;
        case dungeonTileSetType:
            {
                if(pathType==Intersection_FourWay_PathType)
                    return DungeonPassageIntersection_FourWay_TileType;
                //corners
                else if(pathType==NorthToWest_PathType)
                    return DungeonPassageNorthToWest_TileType;
                else if(pathType==NorthToEast_PathType)
                    return DungeonPassageNorthToEast_TileType;
                else if(pathType==SouthToEast_PathType)
                    return DungeonPassageSouthToEast_TileType;
                else if(pathType==SouthToWest_PathType)
                    return DungeonPassageSouthToWest_TileType;
                //passages
                
                else if(pathType==NorthSouth_PathType)
                    return DungeonPassageNorthSouth_TileType;
                else if(pathType==EastWest_PathType)
                    return DungeonPassageEastWest_TileType;
                
                //deadends
                else if(pathType==DeadEndWest_PathType)
                    return DungeonPassageDeadEndWest_TileType;
                else if(pathType==DeadEndEast_PathType)
                    return DungeonPassageDeadEndEast_TileType;
                else if(pathType==DeadEndNorth_PathType)
                    return DungeonPassageDeadEndNorth_TileType;
                else if(pathType==DeadEndSouth_PathType)
                    return DungeonPassageDeadEndSouth_TileType;
                
                //Threeway
                else if(pathType==ThreeWayNorthPathType)
                    return NoTileType;
                else if(pathType==ThreeWaySouthPathType)
                    return NoTileType;
                else if(pathType==ThreeWayEastPathType)
                    return NoTileType;
                else if(pathType==ThreeWayWestPathType)
                    return NoTileType;
            }
            break;
        default:
            break;
    }
    
    
    
    return tileType;
    
}

-(enum BATransitionType)pathTransitionTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)pathType
{
    
    BATileComparator * comparator=[[BATileComparator alloc]init];
    
    [comparator compareBitmapTiletype:bitmap aPosition:CGPointMake(x, y) forType:pathType];
    
    //return Intersection_FourWay_PathType;
    
    enum BATransitionType tempTransitionType=NoTransitionType;
        
        //Four Way
        
         if(comparator->North&&comparator->West&&comparator->East&&comparator->South)
        {
            return Intersection_FourWay_PathTransitionType;
        }
        //Corners
    
        
        else if(!comparator->North&&comparator->West&&!comparator->East&&comparator->South)
        {
            return SouthToWest_PathTransitionType;
        }
    
        else if(comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            return NorthToEast_PathTransitionType;
        }
    
        else if(!comparator->North&&!comparator->West&&comparator->East&&comparator->South)
        {
            return SouthToEast_PathTransitionType;
        }
    
        else if(comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            return NorthToWest_PathTransitionType;
        }
    
    //passages
    
        else if(comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            return NorthSouth_PathTransitionType;
        }
        else if(!comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            return EastWest_PathTransitionType;
        }
    //deadends
        else if(comparator->North&&!comparator->West&&!comparator->East&&!comparator->South)
        {
            return  DeadEndSouth_PathTransitionType;
        }
        else if(!comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            return DeadEndEast_PathTransitionType;
        }
        else if(!comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            return DeadEndWest_PathTransitionType;
        }
        else if(!comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            return DeadEndNorth_PathTransitionType;
        }
    
        
        //three way
        
        else if(comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            return ThreeWayNorthPathTransitionType;
        }
        
        else if(!comparator->North&&comparator->West&&comparator->East&&comparator->South)
        {
            return ThreeWaySouthPathTransitionType;
        }
        
        else if(comparator->North&&!comparator->West&&comparator->East&&comparator->South)
        {
            return ThreeWayEastPathTransitionType;
        }
        
        else if(comparator->North&&comparator->West&&!comparator->East&&comparator->South)
        {
            return ThreeWayWestPathTransitionType;
        }
    /*
        //opposite
        else if(comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(!comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(comparator->NorthEast&&comparator->SouthWest)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(comparator->SouthEast&&comparator->NorthWest)
        {
            return TwoSidedOppositeTransitionType;
        }
        
        
    
    
    
        else if(comparator->North&&!comparator->West&&!comparator->East&&!comparator->South)
            {
                //NSLog(@"North!");
                tempTransitionType=NorthTransitionType ;
            }
        else if (!comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            tempTransitionType=EastTransitionType ;
        }
        else if (!comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            tempTransitionType=SourthTransitionType;
        }
        else if (!comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            tempTransitionType=WestTransitionType;
        }
        //inside corners
        else if (comparator->South&&comparator->East&&comparator->SouthEast&&!comparator->West)
        {
            tempTransitionType=InsideCornerSouthEastTransitionType ;
        }
        
        else if (comparator->South&&comparator->West&&comparator->SouthWest&&!comparator->East)
        {
            tempTransitionType=InsideCornerSouthWestTransitionType ;
        }
        else if (comparator->North&&comparator->NorthEast&&comparator->East&&!comparator->West)
        {
            tempTransitionType=InsideCornerNorthEastTransitionType ;
        }
        else if (comparator->North&&comparator->NorthWest&&comparator->West&&!comparator->East)
        {
            tempTransitionType=InsideCornerNorthWestTransitionType ;
        }
        
        //outside corners
        
        else if(comparator->SouthWest&&!comparator->West&&!comparator->South)
        {
            return OutSideCornerSouthWestTransitionType;
        }
        else if(comparator->SouthEast&&!comparator->East&&!comparator->South)
        {
            return OutSideCornerSouthEastTransitionType;
        }
        else if(comparator->NorthEast&&!comparator->East&&!comparator->North)
        {
            return OutSideCornerNorthEastTransitionType;
        }
        
        else if(comparator->NorthWest&&!comparator->West&&!comparator->North)
        {
            return OutSideCornerNorthWestTransitionType;
        }
        
       */
        
        
        //else if (!North&&!West&&!East&&!South&&NorthEast)
        {
        //    tempTileType=GrassToWater_NorthEast_TransitionTileType;
        }
        
    
           
    return tempTransitionType;
}


-(enum BAPathType)pathTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)pathType
{
    
    BATileComparator * comparator=[[BATileComparator alloc]init];
    
    [comparator compareBitmapTiletype:bitmap aPosition:CGPointMake(x, y) forType:pathType];
    
    //return Intersection_FourWay_PathType;
    
    enum BATransitionType tempTransitionType=NoTransitionType;
        
        //Four Way
        
         if(comparator->North&&comparator->West&&comparator->East&&comparator->South)
        {
            return Intersection_FourWay_PathType;
        }
        //Corners
    
        
        else if(comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            return SouthToWest_PathType;
        }
    
        else if(comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            return SouthToEast_PathType;
        }
    
        else if(comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            return NorthToEast_PathType ;
        }
    
        else if(comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            return NorthToWest_PathType;
        }
    
    //passages
    
        else if(comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            return NorthSouth_PathType;
        }
        else if(!comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            return EastWest_PathType;
        }
    //deadends
        else if(comparator->North&&!comparator->West&&!comparator->East&&!comparator->South)
        {
            return  DeadEndSouth_PathType;
        }
        else if(!comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            return DeadEndEast_PathType;
        }
        else if(!comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            return DeadEndWest_PathType;
        }
        else if(!comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            return DeadEndNorth_PathType;
        }
    
        
        //three way
        
        else if(comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            return ThreeWayNorthPathType;
        }
        
        else if(!comparator->North&&comparator->West&&comparator->East&&comparator->South)
        {
            return ThreeWaySouthPathType;
        }
        
        else if(comparator->North&&!comparator->West&&comparator->East&&comparator->South)
        {
            return ThreeWayEastPathType;
        }
        
        else if(comparator->North&&comparator->West&&!comparator->East&&comparator->South)
        {
            return ThreeWayWestPathType;
        }
    /*
        //opposite
        else if(comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(!comparator->North&&comparator->West&&comparator->East&&!comparator->South)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(comparator->NorthEast&&comparator->SouthWest)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(comparator->SouthEast&&comparator->NorthWest)
        {
            return TwoSidedOppositeTransitionType;
        }
        
        
    
    
    
        else if(comparator->North&&!comparator->West&&!comparator->East&&!comparator->South)
            {
                //NSLog(@"North!");
                tempTransitionType=NorthTransitionType ;
            }
        else if (!comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
        {
            tempTransitionType=EastTransitionType ;
        }
        else if (!comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
        {
            tempTransitionType=SourthTransitionType;
        }
        else if (!comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
        {
            tempTransitionType=WestTransitionType;
        }
        //inside corners
        else if (comparator->South&&comparator->East&&comparator->SouthEast&&!comparator->West)
        {
            tempTransitionType=InsideCornerSouthEastTransitionType ;
        }
        
        else if (comparator->South&&comparator->West&&comparator->SouthWest&&!comparator->East)
        {
            tempTransitionType=InsideCornerSouthWestTransitionType ;
        }
        else if (comparator->North&&comparator->NorthEast&&comparator->East&&!comparator->West)
        {
            tempTransitionType=InsideCornerNorthEastTransitionType ;
        }
        else if (comparator->North&&comparator->NorthWest&&comparator->West&&!comparator->East)
        {
            tempTransitionType=InsideCornerNorthWestTransitionType ;
        }
        
        //outside corners
        
        else if(comparator->SouthWest&&!comparator->West&&!comparator->South)
        {
            return OutSideCornerSouthWestTransitionType;
        }
        else if(comparator->SouthEast&&!comparator->East&&!comparator->South)
        {
            return OutSideCornerSouthEastTransitionType;
        }
        else if(comparator->NorthEast&&!comparator->East&&!comparator->North)
        {
            return OutSideCornerNorthEastTransitionType;
        }
        
        else if(comparator->NorthWest&&!comparator->West&&!comparator->North)
        {
            return OutSideCornerNorthWestTransitionType;
        }
        
       */
        
        
        //else if (!North&&!West&&!East&&!South&&NorthEast)
        {
        //    tempTileType=GrassToWater_NorthEast_TransitionTileType;
        }
        
    
           
    return tempTransitionType;
}

#pragma mark Area

-(enum BAAreaType)areaTypeForTile:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y fromTileType:(enum BATileType)areaType
{
    
    BATileComparator * comparator=[[BATileComparator alloc]init];
    
    [comparator compareBitmapTiletype:bitmap aPosition:CGPointMake(x, y) forType:areaType];
    
    //return Intersection_FourWay_PathType;
    
    //enum BATransitionType tempTransitionType=NoTransitionType;
    
    //Four Way
    
    if(comparator->North&&comparator->West&&comparator->East&&comparator->South&&comparator->SouthEast&&comparator->SouthWest&&comparator->NorthEast&&comparator->NorthWest)
    {
        return FourWayAreaType;
    }
    //Corners
    
    
    else if(comparator->North&&comparator->West&&!comparator->East&&!comparator->South)
    {
        return SouthEastCornerBAAreaType  ;
    }
    
    else if(comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
    {
        return SouthWestCornerBAAreaType;
    }
    
    else if(!comparator->North&&!comparator->West&&comparator->East&&comparator->South)
    {
        return NorthWestCornerBAAreaType ;
    }
    
    else if(!comparator->North&&comparator->West&&!comparator->East&&comparator->South)
    {
        return NorthEastCornerBAAreaType;
    }
    
    //walls
    
    else if(!comparator->North&&comparator->West&&comparator->East&&comparator->South)
    {
        return NorthWallBAAreaType;
    }
    else if(comparator->North&&comparator->West&&comparator->East&&!comparator->South)
    {
        return SouthWallBAAreaType;
    }
    else if(comparator->North&&comparator->West&&!comparator->East&&comparator->South)
    {
        return EastWallBAAreaType;
    }
    else if(comparator->North&&!comparator->West&&comparator->East&&comparator->South)
    {
        return WestWallBAAreaType;
    }
    
    
    //ouside corners
    
    else if (comparator->North&&comparator->West&&comparator->East&&comparator->South&&comparator->SouthEast&&comparator->SouthWest&&!comparator->NorthEast&&comparator->NorthWest)
    {
        return NorthEastOutsideCornerBAAreaType;
    }
    else if (comparator->North&&comparator->West&&comparator->East&&comparator->South&&comparator->SouthEast&&comparator->SouthWest&&comparator->NorthEast&&!comparator->NorthWest)
    {
        return NorthWestOutsideCornerBAAreaType;
    }
    else if (comparator->North&&comparator->West&&comparator->East&&comparator->South&&!comparator->SouthEast&&comparator->SouthWest&&comparator->NorthEast&&comparator->NorthWest)
    {
        return SouthEastOutsideCornerBAAreaType;
    }
    else if (comparator->North&&comparator->West&&comparator->East&&comparator->South&&comparator->SouthEast&&!comparator->SouthWest&&comparator->NorthEast&&comparator->NorthWest)
    {
        return SouthWestOutsideCornerBAAreaType;
    }
    
    
    /*
    else if(!comparator->North&&!comparator->West&&comparator->East&&!comparator->South)
    {
        return DeadEndWest_PathType;
    }
    else if(!comparator->North&&!comparator->West&&!comparator->East&&comparator->South)
    {
        return DeadEndNorth_PathType;
    }
    
    
    //three way
    
    else if(comparator->North&&comparator->West&&comparator->East&&!comparator->South)
    {
        return ThreeWayNorthPathType;
    }
    
    else if(!comparator->North&&comparator->West&&comparator->East&&comparator->South)
    {
        return ThreeWaySouthPathType;
    }
    
    else if(comparator->North&&!comparator->West&&comparator->East&&comparator->South)
    {
        return ThreeWayEastPathType;
    }
    
    else if(comparator->North&&comparator->West&&!comparator->East&&comparator->South)
    {
        return ThreeWayWestPathType;
    }
     */
    return NoTileType;
}


-(enum BATileType)tileTypeForAreaType:(enum BAAreaType)areaType forEnvironmentType:(enum BATileSetType)tileSetType
{
    enum BATileType tileType=NoTileType;
    
    switch (tileSetType) {
        case dirtCaveTileSetType:
            {
                if(areaType==Intersection_FourWay_PathType)
                    return DirtCavePassageIntersection_FourWay_TileType;
                
                //corners
                else if(areaType==NorthToWest_PathType)
                    return DirtCavePassageNorthToWest_TileType;
                else if(areaType==NorthToEast_PathType)
                    return DirtCavePassageNorthToEast_TileType;
                else if(areaType==SouthToEast_PathType)
                    return DirtCavePassageSouthToEast_TileType;
                else if(areaType==SouthToWest_PathType)
                    return DirtCavePassageSouthToWest_TileType;
                //passages
                
                else if(areaType==NorthSouth_PathType)
                    return DirtCavePassageNorthSouth_TileType;
                else if(areaType==EastWest_PathType)
                    return DirtCavePassageEastWest_TileType;
                
                //deadends
                else if(areaType==DeadEndWest_PathType)
                    return DirtCavePassageDeadEndWest_TileType;
                else if(areaType==DeadEndEast_PathType)
                    return DirtCavePassageDeadEndEast_TileType;
                else if(areaType==DeadEndNorth_PathType)
                    return DirtCavePassageDeadEndNorth_TileType;
                else if(areaType==DeadEndSouth_PathType)
                    return DirtCavePassageDeadEndSouth_TileType;
                
                //Threeway
                else if(areaType==ThreeWayNorthPathType)
                    return DirtCavePassageNorthThreeWay_TileType;
                else if(areaType==ThreeWaySouthPathType)
                    return DirtCavePassageSouthThreeWay_TileType;
                else if(areaType==ThreeWayEastPathType)
                    return DirtCavePassageEastThreeWay_TileType;
                else if(areaType==ThreeWayWestPathType)
                    return DirtCavePassageWestThreeWay_TileType;
            }
            break;

        
        case stoneCaveTileSetType:
            {
                if(areaType==FourWayAreaType)
                    return StoneCaveAreaTileType;
                //corners
                else if(areaType==SouthEastCornerBAAreaType)
                    return StoneCaveSouthEastCornerTileType;
                else if(areaType==SouthWestCornerBAAreaType)
                    return StoneCaveSouthWestCornerTileType;
                else if(areaType==NorthEastCornerBAAreaType)
                    return StoneCaveNorthEastCornerTileType;
                else if(areaType==NorthWestCornerBAAreaType)
                    return StoneCaveNorthWestCornerTileType;
               
                
                //walls
                
                else if(areaType==NorthWallBAAreaType)
                    return StoneCaveAreaNorthWallTileType;
                else if(areaType==SouthWallBAAreaType)
                    return StoneCaveAreaSouthWallTileType;
                else if(areaType==EastWallBAAreaType)
                    return StoneCaveAreaEastWallTileType;
                else if(areaType==WestWallBAAreaType)
                    return StoneCaveAreaWestWallTileType;
                
                
                //deadends
                else if(areaType==DeadEndWest_PathType)
                    return CavePassageDeadEndWest_TileType;
                else if(areaType==DeadEndEast_PathType)
                    return CavePassageDeadEndEast_TileType;
                else if(areaType==DeadEndNorth_PathType)
                    return CavePassageDeadEndNorth_TileType;
                else if(areaType==DeadEndSouth_PathType)
                    return CavePassageDeadEndSouth_TileType;
                
                //Threeway
                else if(areaType==ThreeWayNorthPathType)
                    return NoTileType;
                else if(areaType==ThreeWaySouthPathType)
                    return NoTileType;
                else if(areaType==ThreeWayEastPathType)
                    return NoTileType;
                else if(areaType==ThreeWayWestPathType)
                    return NoTileType;
            }
            break;
        case dungeonTileSetType:
            {
                if(areaType==FourWayAreaType)
                    return DungeonTileType;
                //corners
                else if(areaType==SouthEastCornerBAAreaType)
                    return DungeonCornerSouthEast_TileType;
                else if(areaType==SouthWestCornerBAAreaType)
                    return DungeonCornerSouthWest_TileType;
                else if(areaType==NorthEastCornerBAAreaType)
                    return DungeonCornerNorthEast_TileType;
                else if(areaType==NorthWestCornerBAAreaType)
                    return DungeonCornerNorthWest_TileType;
               
                
                //walls
                
                else if(areaType==NorthWallBAAreaType)
                    return DungeonAreaNorthWallTileType;
                else if(areaType==SouthWallBAAreaType)
                    return DungeonAreaSouthWallTileType;
                else if(areaType==EastWallBAAreaType)
                    return DungeonAreaEastWallTileType;
                else if(areaType==WestWallBAAreaType)
                    return DungeonAreaWestWallTileType;
                
                //deadends
                else if(areaType==DeadEndWest_PathType)
                    return DungeonPassageDeadEndWest_TileType;
                else if(areaType==DeadEndEast_PathType)
                    return DungeonPassageDeadEndEast_TileType;
                else if(areaType==DeadEndNorth_PathType)
                    return DungeonPassageDeadEndNorth_TileType;
                else if(areaType==DeadEndSouth_PathType)
                    return DungeonPassageDeadEndSouth_TileType;
                
                //Threeway
                else if(areaType==ThreeWayNorthPathType)
                    return NoTileType;
                else if(areaType==ThreeWaySouthPathType)
                    return NoTileType;
                else if(areaType==ThreeWayEastPathType)
                    return NoTileType;
                else if(areaType==ThreeWayWestPathType)
                    return NoTileType;
                
                //outside corners
                else if(areaType==NorthEastOutsideCornerBAAreaType)
                    return DungeonNorthEastOutsideCornerBAAreaType;
                else if(areaType==NorthWestOutsideCornerBAAreaType)
                    return DungeonNorthWestOutsideCornerBAAreaType;
                else if(areaType==SouthEastOutsideCornerBAAreaType)
                    return DungeonSouthEastOutsideCornerBAAreaType;
                else if(areaType==SouthWestOutsideCornerBAAreaType)
                    return DungeonSouthWestOutsideCornerBAAreaType;
            }
            break;
        default:
            break;
    }
    
    
    
    return tileType;
    
}
-(BAIntBitmap*)transitionBitmapForBaseBitmap:(BAIntBitmap*)baseBitmap
{
    if(!baseBitmap)
        return NULL;
    BAIntBitmap * bitmap=[BAIntBitmap createWithCGSize:baseBitmap->size];
    for(int y=0;y<baseBitmap->size.height;y++)
    {
        for(int x=0;x<baseBitmap->size.width;x++)
        {
            enum BATileType currentTileType=0;
            enum BATransitionType transitionType=0;
            
            currentTileType=[baseBitmap valueAtPosition:CGPointMake(x, y) from:@"transitionBitmapForBaseBitmap"];
            //NSLog(@"currentTileType %i",currentTileType);
            switch (currentTileType) {
                case GrassTileType:
                    transitionType=[self transitionTypeFromGrassTileType:baseBitmap atX:x atY:y];
                    break;
                case DesertTileType:
                    transitionType=[self transitionTypeFromDesertTileType:baseBitmap atX:x atY:y];
                    break;
                case WoodsTileType:
                    transitionType=[self transitionTypeFromWoodsTileType:baseBitmap atX:x atY:y];
                    break;
                case SwampTileType:
                    transitionType=[self transitionTypeFromSwampTileType:baseBitmap atX:x atY:y];
                    break;
                case MountainTileType:
                    transitionType=[self transitionTypeFromMountainTileType:baseBitmap atX:x atY:y];
                    break;
                    
                case WaterTileType:
                    transitionType=[self transitionTypeFromWaterTileType:baseBitmap atX:x atY:y];
                    break;
                case WideRoadTileType:
                case NarrowRoadTileType:
                case CarriagePathTileType:
                case WidePathTileType:
                case NarrowPathTileType:
                case StreamPathTileType:
                case RiverPathTileType:
                case DirtCavePassageTileType:
                case DungeonPassageTileType:
                    transitionType=[self transitionTypeForPath:baseBitmap atX:x atY:y];
                    break;
                case DungeonTileType:
                    transitionType=[self transitionTypeFromDungeonTileType:baseBitmap atX:x atY:y];
                    break;
                default:
                    break;
            }
            //transitionType=[self transitionTypeForTile:baseBitmap atX:x atY:y fromTileType:WaterTileType toTileType:GrassTileType];
            [bitmap setValueAtPosition:transitionType forPosition:CGPointMake(x, y)];
            
        }
    }
    return bitmap;
}

-(enum BATransitionType)transitionTypeForPath:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    
    enum BATransitionType transitionType=NoTransitionType;
    
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WideRoadTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:NarrowRoadTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:CarriagePathTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WidePathTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:NarrowPathTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:StreamPathTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:RiverPathTileType toTileType:WaterTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
    enum BATileType pathType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"transitionTypeForPath"];
    transitionType=[self pathTransitionTypeForTile:bitmap atX:x atY:y fromTileType:pathType];
    if(transitionType!=NoTransitionType)
    {
        //NSLog(@"transitionTypeForPath %i",transitionType);
        return transitionType;
    }
    return transitionType;
}

-(enum BATransitionType)transitionTypeFromGrassTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
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

-(enum BATransitionType)transitionTypeFromWaterTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    enum BATransitionType transitionType=NoTransitionType;
    
    //Check Water
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WaterTileType toTileType:GrassTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WaterTileType toTileType:SwampTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WaterTileType toTileType:WoodsTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;
    
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WaterTileType toTileType:DesertTileType invalidateMixed:NO];
    if(transitionType!=NoTransitionType)
        return transitionType;

   
    return transitionType;
}


-(enum BATransitionType)transitionTypeFromWoodsTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    enum BATransitionType transitionType=NoTransitionType;
    //NSLog(@"woods");
    //Check Water
    //transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WoodsTileType toTileType:WaterTileType];
    if(transitionType)
        return transitionType;
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WoodsTileType toTileType:GrassTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WoodsTileType toTileType:WaterTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WoodsTileType toTileType:SwampTileType invalidateMixed:NO];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WoodsTileType toTileType:MountainTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:WoodsTileType toTileType:DesertTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    return transitionType;
}

-(enum BATransitionType)transitionTypeFromSwampTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    enum BATransitionType transitionType=NoTransitionType;
    
    
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:SwampTileType toTileType:GrassTileType invalidateMixed:YES];
    if(transitionType)
    {
        //NSLog(@"Transitiontype: %i",transitionType);
        return transitionType;
    }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:SwampTileType toTileType:MountainTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:SwampTileType toTileType:WaterTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:SwampTileType toTileType:DesertTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    return transitionType;
}

-(enum BATransitionType)transitionTypeFromMountainTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    enum BATransitionType transitionType=NoTransitionType;
    
   // NSLog(@"swamp");
   // NSLog(@"Transition: %i %i",x,y);
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:MountainTileType toTileType:GrassTileType invalidateMixed:YES];
    if(transitionType)
        {

            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:MountainTileType toTileType:WoodsTileType invalidateMixed:YES];
    if(transitionType)
        {

            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:MountainTileType toTileType:WaterTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:MountainTileType toTileType:SwampTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:MountainTileType toTileType:DesertTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    return transitionType;
}

-(enum BATransitionType)transitionTypeFromDesertTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    enum BATransitionType transitionType=NoTransitionType;
    
   // NSLog(@"swamp");
   // NSLog(@"Transition: %i %i",x,y);
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:DesertTileType toTileType:GrassTileType invalidateMixed:YES];
    if(transitionType)
        {

            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:DesertTileType toTileType:WoodsTileType invalidateMixed:YES];
    if(transitionType)
        {

            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:DesertTileType toTileType:WaterTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:DesertTileType toTileType:SwampTileType invalidateMixed:YES];
    if(transitionType)
        {
            //NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    return transitionType;
}

-(enum BATransitionType)transitionTypeFromDungeonTileType:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
{
    NSLog(@"transitionTypeFromDungeonTileType");
    enum BATransitionType transitionType=NoTransitionType;
    
   // NSLog(@"swamp");
   // NSLog(@"Transition: %i %i",x,y);
    transitionType=[self transitionTypeForTile:bitmap atX:x atY:y fromTileType:DungeonTileType toTileType:SolidRockTileType invalidateMixed:YES];
    if(transitionType)
        {

            NSLog(@"Transitiontype: %i",transitionType);
            return transitionType;
        }
    return transitionType;
}


-(enum BATileType)TileTypeForAtTransitionPosition:(BAIntBitmap*)bitmap  atPosition:(CGPoint)position fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType forTransition:(enum BATransitionType)transitionType
{
    
    enum BATileType tileType=NoTileType;
    CGPoint thePoint;
    thePoint=invalidLocation();
    //NSLog(@"TileTypeForTransitionType: from: %i to: %i",fromType,toType);
   switch (transitionType) {
            case NoTransitionType:
                thePoint=CGPointMake(-1, -1);
                break;
            case NorthTransitionType:
                thePoint=CGPointMake(position.x,position.y-1);
                break;
            case EastTransitionType:
                thePoint=CGPointMake(position.x+1,position.y);
                break;
            case SourthTransitionType:
                thePoint=CGPointMake(position.x,position.y+1);
                break;
            case WestTransitionType:
                thePoint=CGPointMake(position.x-1,position.y);
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                thePoint=CGPointMake(position.x+1,position.y-1);
                break;
            case InsideCornerSouthEastTransitionType:
                thePoint=CGPointMake(position.x+1,position.y+1);
                break;
            case InsideCornerSouthWestTransitionType:
                thePoint=CGPointMake(position.x-1,position.y+1);
                break;
            case InsideCornerNorthWestTransitionType:
                thePoint=CGPointMake(position.x-1,position.y-1);
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                thePoint=CGPointMake(position.x+1,position.y-1);
                break;
            case OutSideCornerSouthEastTransitionType:
                thePoint=CGPointMake(position.x+1,position.y+1);
                break;
            case OutSideCornerSouthWestTransitionType:
                thePoint=CGPointMake(position.x-1,position.y+1);
                break;
            case OutSideCornerNorthWestTransitionType:
                thePoint=CGPointMake(position.x-1,position.y-1);
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
           break;
           
            case NoPathTransitionType:
               
            case NorthSouth_PathTransitionType:
            case EastWest_PathTransitionType:
            case NorthToEast_PathTransitionType:
            case NorthToWest_PathTransitionType:
            case SouthToEast_PathTransitionType:
            case SouthToWest_PathTransitionType:
               
            case Intersection_FourWay_PathTransitionType:
            case DeadEndWest_PathTransitionType:
            case DeadEndEast_PathTransitionType:
            case DeadEndNorth_PathTransitionType:
            case DeadEndSouth_PathTransitionType:
            case ThreeWayNorthPathTransitionType:
            case ThreeWaySouthPathTransitionType:
            case ThreeWayEastPathTransitionType:
            case ThreeWayWestPathTransitionType:
           
            default:
                break;
        }
    if(transitionType==ThreeSidedTranstionType||transitionType==FourSidedTransitionType||transitionType==TwoSidedOppositeTransitionType)
    {
        tileType=GrassTileType;
    }
    if(validLocation(thePoint))
        tileType=[bitmap valueAtPosition:thePoint from:@"TileTypeForAtTransitionPosition"];
    
    
    return tileType;
    
    
}

@end
