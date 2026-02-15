//
//  BAIslandGenerator.m
//  BAU7
//
//  Created by Dan Brooker on 1/30/24.
//
#import "Includes.h"
#import "BAIslandGenerator.h"

#define VALID_ISLAND_THRESHHOLD 0.4f

@implementation BAIslandGenerator
+(BAIslandGenerator*)createWithSize:(CGSize)theSize
{
    BAIslandGenerator *generator=[[BAIslandGenerator alloc]init];
    generator->size=theSize;
    generator->interpreter=[[BAU7BitmapInterpreter alloc]init];
    generator->validIslandThreshold= VALID_ISLAND_THRESHHOLD;
    generator->percentToFill=70;
    return generator;
}


-(void)setValidIslandThreshhold:(float)theThreshhold
{
    if(theThreshhold>0)
        validIslandThreshold=theThreshhold;
}

-(void)setPercentToFill:(float)thePercent
{
    if(thePercent>0)
        percentToFill=thePercent;
}


-(BAIntBitmap*)generate
{
    BAIntBitmap* baseBitmap=[BAIntBitmap createWithCGSize:size];
    
    BOOL validMap=NO;
    long iterations=0;
    
    while(!validMap)
    {
        [baseBitmap fillWithValue:baseTileType];
        
        [self doMapLogicForTileType:fillTileType forMapArray:baseBitmap forPercentTile:percentToFill forIterations:1 forSize:size];
        
        for(int x=0;x<2;x++)
        {
            //NSLog(@"%i",x);
            int count=1;
            while(count)
            {
                count=[self cullBadTiles:baseBitmap forTileType:baseTileType toTileType:fillTileType];
            }
            
            count=1;
            while(count)
            {
                count=[self cullBadTiles:baseBitmap forTileType:fillTileType toTileType:baseTileType];
            }
        }
        float count=[baseBitmap countOfValue:fillTileType];
        if(count>((size.width*size.height)*validIslandThreshold))
           validMap=YES;
        iterations++;
        
    }
    NSLog(@"Valid Island Iterations:%li",iterations);
    return baseBitmap;
}

-(int)cullBadTiles:(BAIntBitmap*)bitmap forTileType:(enum BATileType)tileType toTileType:(enum BATileType)toTileType
{
    /* */
    //NSLog(@"cull");
    int count=0;
    for(int  row=0; row < [bitmap height]; row++)
    {
        for(int column = 0; column < [bitmap width]; column++)
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

-(void)doMapLogicForTileType:(enum BATileType)tileType forMapArray:(BAIntBitmap*)bitmap forPercentTile:(int)percentage forIterations:(int)iterations forSize:(CGSize)size
{
    [self randomFill:tileType forBitmap:bitmap ForFill:percentage];
    /* */
    for(int i=0;i<iterations;i++)
    {
        //NSLog(@"ITERATIONS");
        
        for(int  row=0; row <= [bitmap height]-1; row++)
        {
            for(int column = 0; column <= [bitmap height]-1; column++)
            {
                //NSLog(@"yes");
                enum BATileType oldTileType=[bitmap valueAtPosition:CGPointMake(column, row) from:@"IslandMapView doMapLogicForTileType"];
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
#define BOOSTPERCENT 0 //WHYYY???
-(void)randomFill:(enum BATileType)tileType forBitmap:(BAIntBitmap*)bitmap ForFill:(int)fillPercent
    {
        
        //NSLog(@"RandomFill 2");
       int bitmapMiddle = 0; // Temp variable
       for(int y=0; y < [bitmap height]; y++)
        {
            //NSLog(@"RandomFill 2: %i",row);
           for(int x = 0; x < [bitmap width]; x++)
           {
               enum BATileType tempTileType=0;
               {
                   enum BATileType currentTileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"IslandMapView randomFill"];
                   
                   if(currentTileType==baseTileType)
                   {
                       bitmapMiddle = ([bitmap width] / 2);

                       if(y == bitmapMiddle)
                       {
                           //tempString=@"1";
                       }
                       else
                       {
                           if([self RandomPercent:(arc4random_uniform(fillPercent)+BOOSTPERCENT)])
                               tempTileType=tileType;
                           else
                           {
                               //tempString=@"1";
                           }
                       }
                   }
                   if(tempTileType)
                   {
                       [bitmap setValueAtPosition:tempTileType forPosition:CGPointMake(x, y)];
                   
                   }
                   }
                   
           }
       }
    }
-(int)RandomPercent:(int) percent
{
    int random=arc4random_uniform(100);
    if(percent>=random)
    {
        return 1;
    }
    return 0;
}


-(int)PlaceTileLogic:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y forTileType:(enum BATileType)tileType
   {
       int numTiles = [self GetAdjacentTiles:bitmap atX:x atY:y forScopeX:1 forScopeY:1 forTileType:tileType];
       //NSLog(@"numWalls: %i",numTiles);
      
       enum BATileType tempTileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"IslandMapView PlaceTileLogic"];
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

@end
