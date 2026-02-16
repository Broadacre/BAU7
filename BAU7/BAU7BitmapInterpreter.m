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

-(id)init
{
    self = [super init];
    if (self) {
        // Load tile-to-chunk mapping from JSON
        NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"TileToChunkMapping" 
                                                              ofType:@"json" 
                                                         inDirectory:@"Resources/TileMappings"];
        if (jsonPath) {
            NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
            NSError *error = nil;
            NSDictionary *jsonMapping = [NSJSONSerialization JSONObjectWithData:jsonData 
                                                                        options:0 
                                                                          error:&error];
            
            if (error) {
                NSLog(@"ERROR parsing TileToChunkMapping.json: %@", error);
                tileToChunkMapping = @{};
            } else {
                // Convert string keys to NSNumber keys for integer lookup
                NSMutableDictionary *intMapping = [NSMutableDictionary dictionaryWithCapacity:[jsonMapping count]];
                for (NSString *key in jsonMapping) {
                    NSNumber *intKey = @([key intValue]);
                    intMapping[intKey] = jsonMapping[key];
                }
                tileToChunkMapping = [intMapping copy];
                NSLog(@"Loaded %lu tile-to-chunk mappings from JSON", (unsigned long)[tileToChunkMapping count]);
            }
        } else {
            NSLog(@"ERROR: Could not find TileToChunkMapping.json");
            tileToChunkMapping = @{}; // Empty dict as fallback
        }
    }
    return self;
}

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
    // Look up chunk ID from mapping dictionary
    NSNumber *chunkID = tileToChunkMapping[@(tileType)];
    
    if (chunkID) {
        return [chunkID intValue];
    }
    
    // Fallback for unmapped types
    NSLog(@"WARNING: No chunk mapping for tileType %d", (int)tileType);
    return 1836; // Default error chunk
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
