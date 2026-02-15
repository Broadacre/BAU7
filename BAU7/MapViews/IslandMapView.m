//
//  IslandMapView.m
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//
#import "Includes.h"
#import "BAMapView.h"
#import "RandoMapView.h"
#import "IslandMapView.h"

#define ISLAND_SIZE 10


@implementation IslandMapView

-(id)init
{
    self=[super init];
    map=[[U7Map alloc]init];
    drawTargetLocations=YES;
    
    interpreter=[[BAU7BitmapInterpreter alloc]init];
    [interpreter setEnvironment:environment];
    mainCharacter=NULL;
    
    return self;
}

- (void)drawRect:(CGRect)rect {
 
    [super drawRect:rect];
    
    
    /*
    //THis will highlite center of view
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGPoint cenlocation=CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    //logRect(self.bounds, @"bounds");
    CGRect cenRect=CGRectMake(cenlocation.x, cenlocation.y, 10, 10);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, .35);
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1);
    CGContextFillRect(context, cenRect);
    CGContextStrokeRect(context, cenRect);
    */
    
    
    if(mainCharacter)
    {
        //CGRect theRect=CGRectMake(100, 100, 100, 100);
        
        
        //logPoint([mainCharacter getGlobalLocation], @"mainCharacter Global Location");
        /*
        //THis will highlite character location
        CGPoint location=[self globalToViewLocation:[mainCharacter getGlobalLocation]];
        
        CGRect theRect=CGRectMake(location.x, location.y, 10, 10);
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetRGBFillColor(context, 0.0, 1.0, 0.0, .35);
        CGContextSetRGBStrokeColor(context, 0.0, 1.0, 0.0, 1);
        CGContextFillRect(context, theRect);
        CGContextStrokeRect(context, theRect);
         */
        
        
    }
}



-(void)generateMap
{
    [self initWithChunkID:0];
    mainCharacter=NULL;
    CGPoint islandOffset=CGPointMake(1, 1);
    baseBitmap=[BAIntBitmap createWithCGSize:CGSizeMake(map->mapWidth,map->mapHeight)];
    [baseBitmap fillWithValue:WaterTileType];
  
    BAIslandGenerator * generator=[BAIslandGenerator createWithSize:CGSizeMake(ISLAND_SIZE, ISLAND_SIZE)];
    [generator setBaseTileType:WaterTileType];
    [generator setFillTileType:GrassTileType];
    [generator setPercentToFill:90];
    [generator setValidIslandThreshhold:.4];
    BAIntBitmap * islandBitmap=[generator generate];
    [islandBitmap dump];
    /*
    BAIntBitmap * islandBitmap=[self createTestIslandThree:CGSizeMake(ISLAND_SIZE, ISLAND_SIZE)];
   
     */
    //islandBitmap=[self createIsland:CGSizeMake(ISLAND_SIZE, ISLAND_SIZE)];
    /*
    CGPoint villageStartPoint=[islandBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:CGSizeMake(7,7)];
    if(validLocation(villageStartPoint))
    [self addStreetsForMask:NarrowRoadTileType toBitmap:islandBitmap forMask:[self streetMaskBitmap] AtStartPoint:villageStartPoint];
     */
    [self insertTestAreas:islandBitmap];
     
    //[islandBitmap dump];
    
    
    [islandBitmap copyToBitmap:baseBitmap atPosition:islandOffset];
   
    BAIntBitmap* finalBitmap=[self postProcess:baseBitmap regionToProcess:CGRectMake(0, 0, ISLAND_SIZE+2, ISLAND_SIZE+2)];
    [self populateChunks:finalBitmap];
    /*
    if(validLocation(villageStartPoint))
    {
        [self addHousesForMask:[[self streetMaskBitmap]inverse] AtStartPoint:CGPointMake(islandOffset.x+villageStartPoint.x, islandOffset.y+villageStartPoint.y)];
    }
     */
    //[self insertTestChunks];
    
}



-(void)doPathTest:(BAIntBitmap*)bitmap
{
    
}


-(BAIntBitmap*)postProcess:(BAIntBitmap*)bitmap regionToProcess:(CGRect)theRegion
{
    /* */
   // [baseBitmap dump];
    BAIntBitmap * bitmapToProcess=[BAIntBitmap clipBitmapToRect:bitmap forSize:theRegion padWithValue:GrassTileType];
    [bitmapToProcess dump];
    
    BAIntBitmap * processedBitmap=NULL;
    BAIntBitmap * transitionBitmap=NULL;
    //first cull bad invalid transitions
    
    BOOL validTiles=NO;
    while (!validTiles) {
         validTiles=YES;
        
        transitionBitmap=[self createTransitionBitmap:bitmapToProcess];
        
        processedBitmap=[self doTransitions:transitionBitmap forSource:bitmapToProcess];
        if(!processedBitmap)
            validTiles=NO;
        
    }
    /*  */
    //transitions are done now fill in non-transitions
    for(int  y=0; y < [processedBitmap height]; y++)
    {
        for(int x = 0; x < [processedBitmap width]; x++)
        {
            enum BATileType tileType=0;
            tileType=[processedBitmap valueAtPosition:CGPointMake(x, y) from:@"postProcess"];
            if(tileType==NoTileType)
            {
                tileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"postProcess"];
                [processedBitmap setValueAtPosition:tileType forPosition:CGPointMake(x, y)];
            }
        }
    }
   
    return processedBitmap;
}

-(BAIntBitmap*)createTransitionBitmap:(BAIntBitmap*)bitmap
{
    BAIntBitmap * transitionBitmap=NULL;
    
    BOOL dirty=YES;
    int cullIterations=0;
    while(dirty)
    {
        cullIterations++;
        transitionBitmap=[interpreter transitionBitmapForBaseBitmap:bitmap];
        dirty=NO;
        for(int y=0; y < [bitmap height]; y++)
        {
            for(int x = 0; x < [bitmap width]; x++)
            {
                enum BATransitionType transitionType=0;
                transitionType=[transitionBitmap valueAtPosition:CGPointMake(x, y) from:@"postProcess"];
                if(transitionType==InvalidTransitionType)
                {
                    //NSLog(@"Invalid");
                    [bitmap setValueAtPosition:GrassTileType forPosition:CGPointMake(x, y)];
                    dirty=YES;
                }
            }
        }
    }
    
    NSLog(@"Cull iterations: %i",cullIterations);
    //[transitionBitmap dump];
    return transitionBitmap;
}

-(BAIntBitmap*)doTransitions:(BAIntBitmap*)transitionBitmap forSource:(BAIntBitmap*)sourceBitmap;
{
    BAIntBitmap * processedBitmap=[BAIntBitmap createWithCGSize:sourceBitmap->size];
    
    for(int y=0; y < [sourceBitmap height]; y++)
    {
        for(int x = 0; x < [sourceBitmap width]; x++)
        {
            enum BATileType tileType=0;
            enum BATileType toTileType=0;
            enum BATileType fromTileType=0;
            enum BATransitionType transitionType=0;
            fromTileType=[sourceBitmap valueAtPosition:CGPointMake(x, y) from:@"doTransitions"];
            transitionType=[transitionBitmap valueAtPosition:CGPointMake(x, y) from:@"doTransitions"];
            toTileType=[interpreter TileTypeForAtTransitionPosition:sourceBitmap atPosition:CGPointMake(x, y) fromTileType:fromTileType toTileType:toTileType forTransition:transitionType];
            tileType=[interpreter TileTypeForTransitionType:fromTileType toTileType:toTileType forTransition:transitionType];
            
            if(tileType)
            {
                //NSLog(@"type!");
                if(tileType==InvalidTileType)
                {
                    [sourceBitmap setValueAtPosition:toTileType forPosition:CGPointMake(x, y)];
                    {
                        //NSLog(@"!!! Invalid!!!");
                        return NULL;
                    }
                    
                }
                [processedBitmap setValueAtPosition:tileType forPosition:CGPointMake(x, y)];
            }
            
        }
    }
    return processedBitmap;
}

-(void)populateChunks:(BAIntBitmap*)bitmap
{
    for(int y=0;y<([bitmap height]);y++)
    {
        for(int x=0;x<([bitmap width]);x++)
        {
            U7MapChunk * mapChunk=[map->map objectAtIndex:(y*TOTALMAPSIZE)+x];
            enum BATileType tileType=[self tileTypeAtPoint:bitmap atX:x atY:y];
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

-(CGPoint)inlandPointWithValue:(int)theValue;
{
    CGPoint point=invalidLocation();
    CGPointArray * pointArray;
    
    //first get point Array and direction
    int direction=arc4random_uniform(4);
    switch (direction) {
        case 0: //from top
            {
            pointArray=[baseBitmap BordersOnYAxisWithValue:theValue atZeroY:YES ];
            }
            break;
        case 1: //from bottom
            {
            pointArray=[baseBitmap BordersOnYAxisWithValue:theValue atZeroY:NO ];
            }
            break;
        case 2: //from left
            {
            pointArray=[baseBitmap BordersOnXAxisWithValue:theValue atZeroX:YES ];
            }
            break;
        case 3: //from right
            {
            pointArray=[baseBitmap BordersOnXAxisWithValue:theValue atZeroX:NO ];
            }
            break;
        default:
            break;
    }
    
    //Now get random Point on Array
    CGPoint startPoint=[pointArray getRandomPoint];
    
    //how far in will we go (use midpoint of map as max)
    int inset=[baseBitmap width]/2;
    inset=randomInSpan(1, inset-1);
    
    switch (direction) {
        case 0: //from top
            {
            point=CGPointSubtractFromPoint(startPoint, CGPointMake(0, inset));
            }
            break;
        case 1: //from bottom
            {
                point=CGPointAddToPoint(startPoint, CGPointMake(0, inset));
            }
            break;
        case 2: //from left
            {
                point=CGPointAddToPoint(startPoint, CGPointMake( inset,0));
            }
            break;
        case 3: //from right
            {
            point=CGPointSubtractFromPoint(startPoint, CGPointMake(inset, 0));
            }
            break;
        default:
            break;
    }
    
    if([baseBitmap valueAtPosition:point from:@"inlandPointWithValue"]==theValue)
    {
        return point;
    }
      
    
    return invalidLocation();
}


-(BAIntBitmap*)createTestIsland:(CGPoint)atLocation forSize:(CGSize)size
{
    BAIntBitmap * bitmap=[BAIntBitmap createWithCGSize:CGSizeMake(size.width, size.height)];
    
    int grassSize=ISLAND_SIZE-2;
    int mountainSize=grassSize-4;
    int insetSize=mountainSize-4;
    int newInset=insetSize-4;
    int newestInset=newInset-2;
    
    [bitmap fillWithValue:WaterTileType];
    
    [bitmap setValueForRect:MountainTileType forRect:CGRectMake((ISLAND_SIZE-grassSize)/2, (ISLAND_SIZE-grassSize)/2, grassSize, grassSize)];
    
   
    [bitmap setValueForRect:SwampTileType forRect:CGRectMake((ISLAND_SIZE-mountainSize)/2, (ISLAND_SIZE-mountainSize)/2, mountainSize, mountainSize)];
    
    [bitmap setValueForRect:WaterTileType forRect:CGRectMake((ISLAND_SIZE-insetSize)/2, (ISLAND_SIZE-insetSize)/2, insetSize, insetSize)];
    
    [bitmap setValueForRect:SwampTileType forRect:CGRectMake((ISLAND_SIZE-newInset)/2, (ISLAND_SIZE-newInset)/2, newInset, newInset)];
    
    [bitmap setValueForRect:MountainTileType forRect:CGRectMake((ISLAND_SIZE-newestInset)/2, (ISLAND_SIZE-newestInset)/2, newestInset, newestInset)];
    /**/
    return bitmap;
}

-(BAIntBitmap*)createTestIslandTwo:(CGPoint)atLocation forSize:(CGSize)size
{
    BAIntBitmap * bitmap=[BAIntBitmap createWithCGSize:CGSizeMake(size.width, size.height)];
    
    int grassSize=ISLAND_SIZE-2;
    int mountainSize=grassSize-4;
    int insetSize=mountainSize-4;
    int newInset=insetSize-4;
    int newestInset=newInset-2;
    
    [bitmap fillWithValue:WaterTileType];
    
    [bitmap setValueForRect:GrassTileType forRect:CGRectMake((ISLAND_SIZE-grassSize)/2, (ISLAND_SIZE-grassSize)/2, grassSize, grassSize)];
    
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(4, 4)];
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(5, 4)];
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(6, 4)];
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(4, 5)];
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(5, 5)];
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(6, 5)];
    [bitmap setValueAtPosition:MountainTileType forPosition:CGPointMake(7, 5)];
    /**/
    return bitmap;
}

-(BAIntBitmap*)createTestIslandThree:(CGSize)size
{
    BAIntBitmap * bitmap=[BAIntBitmap createWithCGSize:CGSizeMake(size.width, size.height)];
    [bitmap fillWithValue:SolidRockTileType];
    
    return bitmap;
}

-(void)insertTestChunks
{
    BABooleanBitmap * streetMask=[self streetMaskBitmap];
    streetMask=[streetMask inverse];
    //[self addHousesForMask:streetMask AtStartPoint:<#(CGPoint)#>]
    
    
    /*
    CGPoint point=[baseBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:CGSizeMake(3, 3)];
     
     long index=[u7Env->Map chunkIDForChunkCoordinate:CGPointMake(62, 142)];
     U7MapChunk * chunk=[u7Env->Map mapChunkAtIndex:index];
     index=[map chunkIDForChunkCoordinate:CGPointMake(point.x+1,point.y+1)];
     [map replaceChunkAtIndex:index withChunk:chunk];
  
    
     NSArray * compareBitmapArray= @[ @(GrassTileType), @(GrassTileType),@(WaterTileType),
                                      @(GrassTileType), @(GrassTileType),@(WaterTileType),
                                      @(GrassTileType), @(GrassTileType),@(WaterTileType),];
     NSArray * maskArray= @[ @(1), @(1),@(1),
                             @(1), @(1),@(1),
                             @(1), @(1),@(1),];
     BAIntBitmap *compareBitmap=[BAIntBitmap createWithCGSize:CGSizeMake(3, 3)];
     [compareBitmap fillWithArray:compareBitmapArray];
     BABooleanBitmap * maskBitmap=[BABooleanBitmap createWithCGSize:CGSizeMake(3, 3)];
     [maskBitmap fillWithArray:maskArray];
     
     //CGPointArray * pointArray=[baseBitmap BordersOnXAxisWithValue:GrassTileType atZeroX:NO];
     CGPointArray * pointArray=[baseBitmap pointsMatchingBitmapWithMask:compareBitmap forMask:maskBitmap];
     if([pointArray count])
     {
         CGPoint dockPoint=[pointArray nearestToCGPoint:point];
         //point=[baseBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:CGSizeMake(3, 3)];
          
         index=[u7Env->Map chunkIDForChunkCoordinate:CGPointMake(69, 112)];
          chunk=[u7Env->Map mapChunkAtIndex:index];
          index=[map chunkIDForChunkCoordinate:CGPointMake(dockPoint.x+1,dockPoint.y+1)];
          [map replaceChunkAtIndex:index withChunk:chunk];
     }
    */
    
}

-(CGPointArray*)getVillagePoints:(int)count
{
    CGPointArray *pointArray=NULL;
    
    return pointArray;
}

-(BABooleanBitmap*)streetMaskBitmap
{
    BABooleanBitmap *bitmap=[BABooleanBitmap createWithCGSize:CGSizeMake(7, 7)];
    
    NSArray * maskArray= @[
                            @(0),@(0), @(0),@(0),@(0),@(0),@(0),
                            @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                            @(0),@(1), @(0),@(1),@(0),@(1),@(0),
                            @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                            @(0),@(1), @(0),@(1),@(0),@(1),@(0),
                            @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                            @(0),@(0), @(0),@(0),@(0),@(0),@(0)
    ];
    
    [bitmap fillWithArray:maskArray];
    
    return bitmap;
}

-(void)addStreetsForMask:(enum BATileType)tileType toBitmap:(BAIntBitmap*)targetBitmap forMask:(BABooleanBitmap*)mask AtStartPoint:(CGPoint)thePoint
{
    
    
    if(validLocation(thePoint))
        
    {
        [targetBitmap setValueForRectWithMask:tileType forRect:CGRectMake(thePoint.x, thePoint.y, mask->size.width, mask->size.height) forMask:mask];
        
    }
}

-(void)addHousesForMask:(BABooleanBitmap*)mask AtStartPoint:(CGPoint)thePoint
{
    //Get House index
    [mask frameWithValue:0];
    long index=[u7Env->Map chunkIDForChunkCoordinate:CGPointMake(62, 142)];
    U7MapChunk * chunk=[u7Env->Map mapChunkAtIndex:index];
    //and place per mask
    for(long y=0;y<mask->size.height;y++)
    {
        for(long x=0;x<mask->size.width;x++)
        {
            if([mask valueAtPosition:CGPointMake(x, y)])
            {
                CGPoint point=CGPointMake(thePoint.x+x, thePoint.y+y);
                index=[map chunkIDForChunkCoordinate:point];
                [map replaceChunkAtIndex:index withChunk:chunk];
            }
            
        }
    }
}

-(void)insertTestAreas:(BAIntBitmap*)theBitmap
    {
        //[self addRiverTwo:theBitmap ofSize:CGSizeMake(ISLAND_SIZE-1, ISLAND_SIZE-1)];
        //[self addTestDungeon:theBitmap ofSize:CGSizeMake(ISLAND_SIZE-2, ISLAND_SIZE-2)];
        
        /*
        [self addTestPath:NarrowRoadTileType toBitmap:theBitmap forSize:CGSizeMake(4, 4)];
        [self addTestArea:SwampTileType toBitmap:theBitmap forSize:CGSizeMake(3, 3)];
        [self addTestArea:MountainTileType toBitmap:theBitmap forSize:CGSizeMake(5, 5)];
        [self addTestArea:WoodsTileType toBitmap:theBitmap forSize:CGSizeMake(4, 4)];
        [self addTestArea:DesertTileType toBitmap:theBitmap forSize:CGSizeMake(3, 3)];
        */
    }
-(void)addTestDungeon:(BAIntBitmap*)targetBitmap ofSize:(CGSize)theSize
{
    CGPoint point=[targetBitmap originOfRandomRectFilledWithValue:SolidRockTileType ofSize:theSize];
    if(validLocation(point))
    {
        BARandomDungeonGeneratorDeux * generator=[BARandomDungeonGeneratorDeux createWithSize:theSize];
        [generator setFillTileType: DungeonTileType];
        [generator setBaseTileType:SolidRockTileType];
        [generator setPassageTileType:DungeonPassageTileType];
        [generator setShouldGeneratePassages:NO];
        BAIntBitmap * bitmap=[generator generate];
        if(bitmap)
        {
            if(bitmap->size.width>theSize.width||
               bitmap->size.height>theSize.height)
            {
                bitmap=[BAIntBitmap clipBitmapToSize:bitmap forSize:theSize padWithValue:GrassTileType];
            }
            
            [bitmap copyToBitmap:targetBitmap atPosition:point];
            
        }
    }
}

-(void)addTestArea:(enum BATileType)tileType toBitmap:(BAIntBitmap*)targetBitmap forSize:(CGSize)theSize
    {
    CGPoint point=[targetBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:theSize];
    if(validLocation(point))
        [targetBitmap setValueForRect:tileType forRect:CGRectMake(point.x, point.y, theSize.width, theSize.height)];
    }
-(void)addRiver:(BAIntBitmap*)targetBitmap ofSize:(CGSize)theSize
{
    CGPoint point=[targetBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:theSize];
    if(validLocation(point))
    {
        BARiverGenerator * generator=[BARiverGenerator createWithSize:theSize];
        [generator setFillTileType:StreamPathTileType];
        [generator setBaseTileType:GrassTileType];
        BAIntBitmap * bitmap=[generator generate];
        if(bitmap)
           [bitmap copyToBitmap:targetBitmap atPosition:point];
    }
}

-(void)addRiverTwo:(BAIntBitmap*)targetBitmap ofSize:(CGSize)theSize
{
    CGPoint point=[targetBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:theSize];
    if(validLocation(point))
    {
        BARandomDungeonGenerator * generator=[BARandomDungeonGenerator createWithSize:theSize];
        [generator setFillTileType:NarrowPathTileType];
        [generator setBaseTileType:GrassTileType];
        BAIntBitmap * bitmap=[generator generate];
        if(bitmap)
           [bitmap copyToBitmap:targetBitmap atPosition:point];
    }
}

-(void)addTestPath:(enum BATileType)tileType toBitmap:(BAIntBitmap*)targetBitmap forSize:(CGSize)theSize
    {
        
        NSArray * maskArray= @[
                                @(1), @(1),@(1),@(1),
                                @(1), @(1),@(1),@(1),
                                @(1), @(1),@(1),@(1),
                                @(1), @(1),@(1),@(1)
                                
        ];
        /*NSArray * maskArray= @[
                                @(0),@(0), @(0),@(0),@(0),@(0),@(0),
                                @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                                @(0),@(1), @(0),@(1),@(0),@(1),@(0),
                                @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                                @(0),@(1), @(0),@(1),@(0),@(1),@(0),
                                @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                                @(0),@(0), @(0),@(0),@(0),@(0),@(0),
        ];
        
        NSArray * maskArray= @[
                                @(0),@(0), @(0),@(1),@(0),@(0),@(0),
                                @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                                @(0),@(1), @(0),@(1),@(0),@(1),@(0),
                                @(1),@(1), @(1),@(1),@(1),@(1),@(1),
                                @(0),@(1), @(0),@(1),@(0),@(1),@(0),
                                @(0),@(1), @(1),@(1),@(1),@(1),@(0),
                                @(0),@(0), @(0),@(1),@(0),@(0),@(0),
        ];
         */
        BABooleanBitmap * maskBitmap=[BABooleanBitmap createWithCGSize:theSize];
        [maskBitmap fillWithArray:maskArray];
        CGPoint point=[targetBitmap originOfRandomRectFilledWithValue:GrassTileType ofSize:theSize];
        if(validLocation(point))
            
        {
            [targetBitmap setValueForRectWithMask:tileType forRect:CGRectMake(point.x, point.y, theSize.width, theSize.height) forMask:maskBitmap];
            
        }
        
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

-(enum BATileType)tileTypeAtPoint:(BAIntBitmap*)bitmap atX:(int)x atY:(int)y
   {
       // Consider out-of-bound a wall
       //NSLog(@"GetAdjacentTiles: %i, %i",x,y);
       if([interpreter IsOutOfBounds:bitmap atX:x atY:y] )
       {
           //NSLog(@"Out of Bounds");
           return 0;
       }
       enum BATileType tempTileType=[bitmap valueAtPosition:CGPointMake(x, y) from:@"IslandMapView tileTypeAtPoint"];
       return tempTileType;
   }








@end
