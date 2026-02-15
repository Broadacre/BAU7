//
//  RandoMapView.m
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//
#import "Includes.h"
#import "BAMapView.h"
#import "RandoMapView.h"
#define MAXPASSES 16




#define PERCENTARETREES 0
#define PERCENTGRASS 65
#define PERCENTWATER 40
#define PERCENTROCK 0


@implementation BAMapContinent


-(id)init
{
    self=[super init];
    
    pointArray=[[CGPointArray alloc]init];
    
    return self;
}
-(BOOL)chunkInContinent:(CGPoint)chunkPosition
{
    return [pointArray containsPoint:chunkPosition];
}


-(BOOL)addPosition:(CGPoint)thePosition
{
    return [pointArray addPoint:thePosition];
}

-(long)numberOfChunks
{
    return [pointArray count];
}


-(CGPoint)pointAtIndex:(long)theIndex
{
    return [pointArray pointAtIndex:theIndex];
}

@end

@implementation RandoMapView

-(id)init
{
    self=[super init];
    map=[[U7Map alloc]init];
    drawTargetLocations=YES;
    
    interpreter=[[BAU7BitmapInterpreter alloc]init];
    [interpreter setEnvironment:environment];
    
    
    return self;
}

-(void)selectChunkAtLocation:(CGPoint)location
{
    int x=startPoint.x+(location.x/(CHUNKSIZE*TILESIZE));
    int y=startPoint.y+(location.y/(CHUNKSIZE*TILESIZE));
    CGPoint selectedLocation=CGPointMake(x, y);
    NSLog(@"startpoint: %f,%f selected: %f,%f",startPoint.x,startPoint.y,selectedLocation.x,selectedLocation.y);
    if(selectedChunk)
        selectedChunk->highlited=NO;
    
    selectedChunk=[map mapChunkForLocation:selectedLocation];
    if(selectedChunk)
    {
        if(pasteboardChunk)
        {
            
            //U7MapChunk * newChunk=[u7Env mapChunkForLocation:CGPointMake(66, 133)];
            [map replaceChunkAtIndex:[map chunkIDForChunkCoordinate:selectedLocation] withChunk:pasteboardChunk];
        }
        //selectedChunk->highlited=YES;
        
    }
        
    
}


-(void)selectContinentAtLocation:(CGPoint)location
{
    int x=startPoint.x+(location.x/(CHUNKSIZE*TILESIZE));
    int y=startPoint.y+(location.y/(CHUNKSIZE*TILESIZE));
    NSLog(@"startpoint: %f,%f selected: %i,%i",startPoint.x,startPoint.y,x,y);
    
    BAMapContinent * continent=[self defineContinent:baseBitmap forPostion:CGPointMake(x, y) forTileType:GrassTileType];
    NSLog(@"Continent has %li chunks",[continent numberOfChunks]);
    for(long index=0;index<[continent numberOfChunks];index++)
    {
        //NSLog(@"chunk");
        CGPoint chunkLocation=[continent pointAtIndex:index];
        U7MapChunk * chunk=[map->map objectAtIndex:(chunkLocation.y*TOTALMAPSIZE)+chunkLocation.x];
        chunk->highlited=YES;
    }
}




-(void)generateMap
{
    [self initWithChunkID:0];
    
    baseBitmap= [self makeTown];
    //[baseBitmap dump];
    for(int y=0;y<(TOTALMAPSIZE);y++)
    {
        for(int x=0;x<(TOTALMAPSIZE);x++)
        {
            U7MapChunk * mapChunk=[map->map objectAtIndex:(y*TOTALMAPSIZE)+x];
            enum BATileType tileType=[self tileTypeAtPoint:baseBitmap atX:x atY:y];
            //enum BATileType tileType=[self TileTypeForSymbol:symbol];
            mapChunk->masterChunkID=[interpreter chunkIDForTileType:tileType];
            mapChunk->masterChunk=[environment->U7Chunks objectAtIndex:mapChunk->masterChunkID];
            [mapChunk setEnvironment:environment];
            if(environment)
            {
                [mapChunk updateShapeInfo:environment];
                [mapChunk createPassability];
                [mapChunk createEnvironmentMap];
            }
            else
                NSLog(@"Bad Environment");
            mapChunk->dirty=YES;
            
        }
    }
    
}







-(void)drawMiniChunk:(U7MapChunk*)mapChunk forX:(int)x forY:(int)y
{
    /*
    enum BATileType tileType=[self tileTypeAtPoint:baseBitmap atX:x atY:y];
    U7Shape* shape=[interpreter shapeReferenceForTileType:tileType];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    U7Bitmap * bitmap=[shape->frames objectAtIndex:0];
    CGRect imageFrame=CGRectMake(0, 0, 0, 0);
    if(bitmap->CGImage)
    {
        if(shape->tile)
        {

            imageFrame=CGRectMake(x*TILESIZE*TILEPIXELSCALE, y*TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE, TILESIZE*TILEPIXELSCALE);
            
        }
 
    CGContextDrawImage(context,imageFrame,bitmap->CGImage);
     
     
    }
    else
    {
        
           NSLog(@"Bad Image");
    }
    */
}



-(BAIntBitmap*)makeTown
{
    //NSLog(@"Make Cavern");
    //NSMutableArray * mapArray=[self randomFillMap:@"0"];
    //NSMutableArray * mapArray=[self createMap:WaterTileType];
    BAIntBitmap * bitmap=[BAIntBitmap createWithCGSize:CGSizeMake(TOTALMAPSIZE, TOTALMAPSIZE)];
    [bitmap fillWithValue:WaterTileType];
    
    [self doMapLogicForTileType:MountainTileType forMapArray:bitmap forPercentTile:PERCENTROCK forIterations:3];
    [self doMapLogicForTileType:WaterTileType forMapArray:bitmap forPercentTile:PERCENTWATER forIterations:5];
    [self doMapLogicForTileType:GrassTileType forMapArray:bitmap forPercentTile:PERCENTGRASS forIterations:1];
    [self doMapLogicForTileType:WoodsTileType forMapArray:bitmap forPercentTile:PERCENTARETREES forIterations:1];
  
    
    for(int x=0;x<2;x++)
    {
        NSLog(@"%i",x);
        int count=1;
        while(count)
        {
            count=[self cullBadTiles:bitmap forTileType:WaterTileType toTileType:GrassTileType];
        }
        
        count=1;
        while(count)
        {
            count=[self cullBadTiles:bitmap forTileType:GrassTileType toTileType:WaterTileType];
        }
        
    }
    
    
    [self postProcess:bitmap];
    return bitmap;
    }

-(void)doMapLogicForTileType:(enum BATileType)tileType forMapArray:(BAIntBitmap*)bitmap forPercentTile:(int)percentage forIterations:(int)iterations
{
    [self randomFill:tileType forBitmap:bitmap shouldOverWrite:NO ForFill:percentage];
    /* */
    for(int i=0;i<iterations;i++)
    {
        //NSLog(@"ITERATIONS");
        for(int  row=0; row <= TOTALMAPSIZE-1; row++)
        {
            for(int column = 0; column <= TOTALMAPSIZE-1; column++)
            {
                //NSLog(@"yes");
                enum BATileType oldTileType=[bitmap valueAtPosition:CGPointMake(column, row) from:@"RandomMapView doMapLogicForTileType"];
                int logic=[self PlaceTileLogic:bitmap atX:column atY:row forTileType:tileType];
                enum BATileType tempTileType;
                if(logic)
                {
                    
                    if(!(oldTileType==tileType))
                        tempTileType=oldTileType;
                    
                    //if([oldSymbol isEqualToString:@"3"])
                    //    tempString=oldSymbol;
                    else
                        tempTileType=WaterTileType;
                }
                else
                    tempTileType=tileType;
                if(tempTileType)
                {
                    [bitmap setValueAtPosition:tempTileType forPosition:CGPointMake(column, row)];
                    
                }
                
                   
            }
        }
    }
}

-(int)PlaceTileLogic:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y forTileType:(enum BATileType)tileType
   {
       int numTiles = [self GetAdjacentTiles:bitmap atX:x atY:y forScopeX:1 forScopeY:1 forTileType:tileType];
       //NSLog(@"numWalls: %i",numTiles);
      
       enum BATileType tempTileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"RandomMapView PlaceTileLogic"];
       if(tempTileType==tileType)
       {
           if( numTiles >= 4 )
           {
               return 0;
           }
           if(numTiles<2)
           {
               return 1;
           }

       }
       else
       {
           if(numTiles>=5)
           {
               return 0;
           }
       }
       return 1;
   }


-(NSMutableArray *)createMap:(enum BATileType)fillTileType
    {
        //NSLog(@"RandomFill");
         NSMutableArray * mapArray=[[NSMutableArray alloc]init];
        
        for(int x=0;x<TOTALMAPSIZE;x++)
        {
            for(int y=0;y<TOTALMAPSIZE;y++)
            {
                [mapArray addObject:[NSNumber numberWithInt:fillTileType]];
            }
        }
        //NSLog(@"RandomFill 2");
       //int mapMiddle = 0; // Temp variable
       for(int row=0; row < TOTALMAPSIZE; row++)
        {
            //NSLog(@"RandomFill 2: %i",row);
           for(int column = 0; column < TOTALMAPSIZE; column++)
           {
               // If coordinants lie on the the edge of the map (creates a border)
               
               
               enum BATileType tempTileType;
               /**/
               if(column == 0)
               {
                   tempTileType=fillTileType;
               }
               else if (row == 0)
               {
                   tempTileType=fillTileType;
               }
               else if (column == TOTALMAPSIZE-1)
               {
                   tempTileType=fillTileType;
               }
               else if (row == TOTALMAPSIZE-1)
               {
                   tempTileType=fillTileType;
               }
               // Else, fill with a wall a random percent of the time
               

          // [mapArray removeObjectAtIndex:(row*tilesWide+column)];
           //[mapArray insertObject:tempString atIndex:(row*tilesWide+column)];
           }
       }
        return [mapArray mutableCopy];
    }



-(void)randomFill:(enum BATileType)tileType forBitmap:(BAIntBitmap*)bitmap shouldOverWrite:(BOOL)overWrite ForFill:(int)fillPercent
    {
        
        //NSLog(@"RandomFill 2");
       int mapMiddle = 0; // Temp variable
       for(int row=0; row < TOTALMAPSIZE; row++)
        {
            //NSLog(@"RandomFill 2: %i",row);
           for(int column = 0; column < TOTALMAPSIZE; column++)
           {
               
               
               enum BATileType tempTileType=0;
               
               {
                   
                   enum BATileType currentTileType=[bitmap valueAtPosition:CGPointMake(column, row) from:@"RandomMapView randomFill"];
                   
                   if(currentTileType==1)
                   {
                       mapMiddle = (TOTALMAPSIZE / 2);

                       if(row == mapMiddle)
                       {
                           //tempString=@"1";
                       }
                       else
                       {
                           if([self RandomPercent:(arc4random_uniform(fillPercent)+20)])
                               tempTileType=tileType;
                           else
                           {
                               //tempString=@"1";
                           }
                       }
                   }
                   if(tempTileType)
                   {
                       [bitmap setValueAtPosition:tempTileType forPosition:CGPointMake(column, row)];
                   
                   }
                   }
                   
           }
       }
    }

-(void)buildBorders:(enum BATileType)wallTileType forMap:(BAIntBitmap*)bitmap
    {
        //NSLog(@"RandomFill");
       
        //NSLog(@"RandomFill 2");
        [bitmap frameWithValue:wallTileType];
      /*
        for(int row=0; row < TOTALMAPSIZE; row++)
        {
            //NSLog(@"RandomFill 2: %i",row);
           for(int column = 0; column < TOTALMAPSIZE; column++)
           {
               // If coordinants lie on the the edge of the map (creates a border)
               
               enum BATileType tempTileType=0;
              
               if(column == 0)
               {
                   tempTileType=wallTileType;
               }
               else if (row == 0)
               {
                   tempTileType=wallTileType;
               }
               else if (column == TOTALMAPSIZE-1)
               {
                   tempTileType=wallTileType;
               }
               else if (row == TOTALMAPSIZE-1)
               {
                   tempTileType=wallTileType;
               }
               // Else, fill with a wall a random percent of the time
               
               if(tempTileType)
               {
                [bitmap setValueAtPosition:tempTileType forPosition:CGPointMake(column, row)];
           
               }
           }
       }
*/
    }


    -(int)RandomPercent:(int) percent
    {
        if(percent>=arc4random_uniform(100))
        {
            return 1;
        }
        return 0;
    }





   


-(int)GetAdjacentTiles:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y forScopeX:(int)scopeX forScopeY:(int)scopeY forTileType:(enum BATileType)tileType
   {
       //NSLog(@"GetAdjacentTiles: %i, %i",x,y);
       int startX = x - scopeX;
       int startY = y - scopeY;
       int endX = x + scopeX;
       int endY = y + scopeY;

       int iX = startX;
       int iY = startY;
       //NSLog(@"GetAdjacentWalls: %i, %i",iX,iY);
       int tileCounter = 0;

       for(iY = startY; iY <= endY; iY++) {
           for(iX = startX; iX <= endX; iX++)
           {
               if(!(iX==x && iY==y))
               {
                   if([interpreter IsTileType:bitmap atX:iX atY:iY forTileType:tileType])
                   {
                       tileCounter += 1;
                   }
               }
           }
       }
       return tileCounter;
   }

-(enum BATileType)tileTypeAtPoint:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
   {
       // Consider out-of-bound a wall
       //NSLog(@"GetAdjacentTiles: %i, %i",x,y);
       if([interpreter IsOutOfBounds:bitmap atX:x atY:y] )
       {
           //NSLog(@"Out of Bounds");
           return 0;
       }
       enum BATileType tempTileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"RandomMapView tileTypeAtPoint"];
       return tempTileType;
   }
/*
-(BOOL)IsTileType:(NSArray*)mapArray atX:(int)x atY:(int)y forTileType:(enum BATileType)tileType
   {
       // Consider out-of-bound a wall
       //NSLog(@"GetAdjacentTiles: %i, %i",x,y);
       if([self IsOutOfBounds:x atY:y] )
       {
           //NSLog(@"Out of Bounds");
           return false;
       }
       enum BATileType tempTileType=[[mapArray objectAtIndex:(y*TOTALMAPSIZE)+x]intValue];
       if(tempTileType==tileType)
       {
           return true;
       }

       return false;
   }


-(BOOL)IsOutOfBounds:(int)x atY:(int)y
   {
       if( x<0 || y<0 )
       {
           return true;
       }
       else if( x>TOTALMAPSIZE-1 || y>TOTALMAPSIZE-1 )
       {
           return true;
       }
       return false;
   }
 */
-(int)cullBadTiles:(BAIntBitmap*)bitmap forTileType:(enum BATileType)tileType toTileType:(enum BATileType)toTileType
{
    /* */
    //NSLog(@"cull");
    int count=0;
    for(int  row=0; row < TOTALMAPSIZE; row++)
    {
        for(int column = 0; column < TOTALMAPSIZE; column++)
        {
            int x=column;
            int y=row;
            enum BATransitionType transitionType=0;
            //enum BATileType currentTileType=[[mapArray objectAtIndex:row*TOTALMAPSIZE+column]intValue];
            //enum bui
            if([interpreter IsTileType:bitmap atX:x atY:y forTileType:tileType])
            {
                transitionType=[interpreter transitionTypeForTile:bitmap atX:x atY:y fromTileType:tileType toTileType:toTileType invalidateMixed:NO];
                if(transitionType)
                    if(transitionType==ThreeSidedTranstionType
                       ||transitionType==FourSidedTransitionType
                       ||transitionType==TwoSidedOppositeTransitionType)
                        {
                        //NSLog(@"type!");
                            [bitmap setValueAtPosition:toTileType forPosition:CGPointMake(column, row)];
                       
                        count++;
                        }
            }
            
            
            
            
        }
    }
    return count;
}


-(void)postProcess:(BAIntBitmap*)bitmap
{
    /* */
    for(int  row=0; row < TOTALMAPSIZE; row++)
    {
        for(int column = 0; column < TOTALMAPSIZE; column++)
        {
            int x=column;
            int y=row;
            enum BATileType tileType=0;
            enum BATransitionType transitionType=0;
            //enum BATileType currentTileType=[[mapArray objectAtIndex:row*TOTALMAPSIZE+column]intValue];
            //enum bui
            if([interpreter IsTileType:bitmap atX:x atY:y forTileType:WaterTileType])
            {
                transitionType=[interpreter transitionTypeForTile:bitmap atX:x atY:y fromTileType:WaterTileType toTileType:GrassTileType invalidateMixed:NO];
                if(transitionType)
                    tileType=[interpreter TileTypeForTransitionType:WaterTileType toTileType:GrassTileType forTransition:transitionType];
                //tileType=[self ]
                
                if(tileType)
                {
                    //NSLog(@"type!");
                    
                    [bitmap setValueAtPosition:tileType forPosition:CGPointMake(column, row)];
                }
            }
            
            
            
            
        }
    }
     
     
    
}
/*

-(enum BATileType)TileTypeForTransitionType:(enum BATileType)fromType toTileType:(enum BATileType)toType forTransition:(enum BATransitionType)transitionType
{
    enum BATileType tileType=NoTileType;
    
    if(fromType==WaterTileType&&toType==GrassTileType)
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
                tileType=NoTileType;
            default:
                break;
        }
    }
    
    else if(fromType==GrassTileType&&toType==WaterTileType)
    {
        switch (transitionType) {
            case NoTransitionType:
                break;
            case NorthTransitionType:
                tileType=GrassToWater_South_TransitionTileType;
                break;
            case EastTransitionType:
                tileType=GrassToWater_West_TransitionTileType;
                break;
            case SourthTransitionType:
                tileType=GrassToWater_North_TransitionTileType;
                break;
            case WestTransitionType:
                tileType=GrassToWater_East_TransitionTileType;
                break;
            
            //inside corner
            case InsideCornerNorthEastTransitionType:
                tileType=GrassToWater_InsideCorner_SouthWest_TransitionTileType;
                break;
            case InsideCornerSouthEastTransitionType:
                tileType=GrassToWater_InsideCorner_NorthWest_TransitionTileType;
                break;
            case InsideCornerSouthWestTransitionType:
                tileType=GrassToWater_InsideCorner_NorthEast_TransitionTileType;
                break;
            case InsideCornerNorthWestTransitionType:
                tileType=GrassToWater_InsideCorner_SouthEast_TransitionTileType;
                break;
            
                
            //outside corner
            case OutSideCornerNorthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthWest_TransitionTileType;
                break;
            case OutSideCornerSouthEastTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthWest_TransitionTileType;
                break;
            case OutSideCornerSouthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_NorthEast_TransitionTileType;
                break;
            case OutSideCornerNorthWestTransitionType:
                tileType=GrassToWater_OutsideCorner_SouthEast_TransitionTileType;
                break;
                
            case ThreeSidedTranstionType:
            case FourSidedTransitionType:
            case TwoSidedOppositeTransitionType:
                tileType=NoTileType;
            default:
                break;
        }
    }
    
    
    return tileType;
    
}

-(enum BATransitionType)transitionTypeForTile:(NSArray*)mapArray atX:(int)x atY:(int)y fromTileType:(enum BATileType)fromType toTileType:(enum BATileType)toType
{
    BOOL North=NO;
    BOOL NorthEast=NO;
    BOOL East=NO;
    BOOL SouthEast=NO;
    BOOL South=NO;
    BOOL SouthWest=NO;
    BOOL West=NO;
    BOOL NorthWest=NO;
    

   
    enum BATransitionType tempTransitionType=NoTransitionType;
    //enum BATileType currentTileType=[[mapArray objectAtIndex:row*TOTALMAPSIZE+column]intValue];
    //enum bui
    if([self IsTileType:mapArray atX:x atY:y forTileType:fromType])
    {
        North=NO;
        NorthEast=NO;
        East=NO;
        SouthEast=NO;
        South=NO;
        SouthWest=NO;
        West=NO;
        NorthWest=NO;
        
        for(int direction=0;direction<8;direction++)
        {
            switch (direction) {
                case 0:
                    if([self IsTileType:mapArray atX:x atY:y-1 forTileType:toType])
                    {
                        North=YES;
                    }
                    break;
                case 1:
                    if([self IsTileType:mapArray atX:x+1 atY:y-1 forTileType:toType])
                    {
                        NorthEast=YES;
                    }
                    break;
                case 2:
                    if([self IsTileType:mapArray atX:x+1 atY:y forTileType:toType])
                    {
                        East=YES;
                    }
                    break;
                case 3:
                    if([self IsTileType:mapArray atX:x+1 atY:y+1 forTileType:toType])
                    {
                        SouthEast=YES;
                    }
                    break;
                case 4:
                    if([self IsTileType:mapArray atX:x atY:y+1 forTileType:toType])
                    {
                        South=YES;
                    }
                    break;
                case 5:
                    if([self IsTileType:mapArray atX:x-1 atY:y+1 forTileType:toType])
                    {
                        SouthWest=YES;
                    }
                    break;
                case 6:
                    if([self IsTileType:mapArray atX:x-1 atY:y forTileType:toType])
                    {
                        West=YES;
                    }
                    break;
                case 7:
                    if([self IsTileType:mapArray atX:x-1 atY:y-1 forTileType:toType])
                    {
                        NorthWest=YES;
                    }
                    break;
                default:
                    break;
            }
        }
        
        //singleton
        
         if(North&&West&&East&&South)
        {
            return FourSidedTransitionType;
        }
        
        //three sided
        
        else if(North&&West&&East&&!South)
        {
            return ThreeSidedTranstionType;
        }
        
        else if(!North&&West&&East&&South)
        {
            return ThreeSidedTranstionType;
        }
        
        else if(North&&!West&&East&&South)
        {
            return ThreeSidedTranstionType;
        }
        
        else if(North&&West&&!East&&South)
        {
            return ThreeSidedTranstionType;
        }
        
        //opposite
        else if(North&&!West&&!East&&South)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(!North&&West&&East&&!South)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(NorthEast&&SouthWest)
        {
            return TwoSidedOppositeTransitionType;
        }
        else if(SouthEast&&NorthWest)
        {
            return TwoSidedOppositeTransitionType;
        }
        
        else if(North&&!West&&!East&&!South)
            {
                //NSLog(@"North!");
                tempTransitionType=NorthTransitionType ;
            }
        else if (!North&&!West&&East&&!South)
        {
            tempTransitionType=EastTransitionType ;
        }
        else if (!North&&!West&&!East&&South)
        {
            tempTransitionType=SourthTransitionType;
        }
        else if (!North&&West&&!East&&!South)
        {
            tempTransitionType=WestTransitionType;
        }
        //inside corners
        else if (South&&East&&SouthEast&&!West)
        {
            tempTransitionType=InsideCornerSouthEastTransitionType ;
        }
        
        else if (South&&West&&SouthWest&&!East)
        {
            tempTransitionType=InsideCornerSouthWestTransitionType ;
        }
        else if (North&&NorthEast&&East&&!West)
        {
            tempTransitionType=InsideCornerNorthEastTransitionType ;
        }
        else if (North&&NorthWest&&West&&!East)
        {
            tempTransitionType=InsideCornerNorthWestTransitionType ;
        }
        
        //outside corners
        
        else if(SouthWest&&!West&&!South)
        {
            return OutSideCornerSouthWestTransitionType;
        }
        else if(SouthEast&&!East&&!South)
        {
            return OutSideCornerSouthEastTransitionType;
        }
        else if(NorthEast&&!East&&!North)
        {
            return OutSideCornerNorthEastTransitionType;
        }
        
        else if(NorthWest&&!West&&!North)
        {
            return OutSideCornerNorthWestTransitionType;
        }
        
       
        
        
        //else if (!North&&!West&&!East&&!South&&NorthEast)
        {
        //    tempTileType=GrassToWater_NorthEast_TransitionTileType;
        }
        
    }
           
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
*/
-(BAMapContinent*)defineContinent:(BAIntBitmap*)bitmap forPostion:(CGPoint)position forTileType:(enum BATileType)type
{
    CGPointArray * visitedPoints=[[CGPointArray alloc]init];
    BAMapContinent * continent=[[BAMapContinent alloc]init];
    CGPoint currentPoint=position;
    BOOL searching=YES;
    while(searching)
    {
        if([interpreter IsTileType:bitmap atX:currentPoint.x atY:currentPoint.y forTileType:type])
            {
                [continent addPosition:currentPoint];
                [visitedPoints addPoint:currentPoint];
                NSLog(@"visitedPoint: %li",[visitedPoints count]);
                
                for(int direction=0;direction<4;direction++)
                {
                    CGPoint tempPoint;
                    switch (direction) {
                        case 0://North
                            tempPoint=CGPointMake(currentPoint.x, currentPoint.y-1);
                            break;
                        case 1://East
                            tempPoint=CGPointMake(currentPoint.x+1, currentPoint.y);
                            break;
                        case 2://South
                            tempPoint=CGPointMake(currentPoint.x, currentPoint.y+1);
                            break;
                        case 3://West
                            tempPoint=CGPointMake(currentPoint.x-1, currentPoint.y);
                            break;
                            
                        default:
                            NSLog(@"error");
                            break;
                    }
                    if(![visitedPoints containsPoint:tempPoint])
                    {
                        if([interpreter IsTileType:bitmap atX:tempPoint.x atY:tempPoint.y forTileType:type])
                            {
                                [continent addPosition:tempPoint];
                            }
                    }
                
                }
                //currentPoint=CGPointMake(currentPoint.x+1, currentPoint.y);
            }
        CGPoint oldPoint=currentPoint;
        for(int count=0;count<[continent numberOfChunks];count++)
        {
            CGPoint nextPoint=[continent pointAtIndex:count];
            if(![visitedPoints containsPoint:nextPoint])
            {
                currentPoint=nextPoint;
                break;
            }
            
        }
        if(CGPointEqualToPoint(oldPoint, currentPoint))
        {
            searching=NO;
        }
        
    }
    
    return continent;
}

@end
