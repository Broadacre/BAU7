//
//  BARandomDungeonGeneratorDeaux.m
//  BAU7
//
//  Created by Dan Brooker on 2/15/24.
//
#import "Includes.h"
#import "BARandomDungeonGeneratorDeux.h"

@implementation BAEdge

+(BAEdge*)edgeFromPoints:(CGPoint)firstPoint andPoint:(CGPoint)secondPoint
{
    BAEdge * edge=[[BAEdge alloc]init];
    edge->pointOne=firstPoint;
    edge->pointTwo=secondPoint;
    return edge;
}


-(void)dump
{
    NSLog(@"P1:%f,%f...P2:%f,%f",pointOne.x,pointOne.y,pointTwo.x,pointTwo.y);
}

-(BOOL)isEqualTo:(BAEdge*)comparisonEdge
{
    BOOL firstMatch=FALSE;
    BOOL secondMatch=FALSE;
    if(CGPointEqualToPoint(pointOne, comparisonEdge->pointOne)||CGPointEqualToPoint(pointOne, comparisonEdge->pointTwo))
        firstMatch=TRUE;
    if(CGPointEqualToPoint(pointTwo, comparisonEdge->pointOne)||CGPointEqualToPoint(pointTwo, comparisonEdge->pointTwo))
        secondMatch=TRUE;
    if(firstMatch&&secondMatch)
        return YES;
    return NO;
    
}


-(BOOL)containsPoint:(CGPoint)thePoint
{
    if(CGPointEqualToPoint(pointOne, thePoint)||CGPointEqualToPoint(pointTwo, thePoint))
        return YES;
    return NO;
}

@end

@implementation BAEdgeArray

-(id)init
{
    self=[super init];
    edges=[[NSMutableArray alloc]init];
    
    return self;
}

-(void)clear
{
    [edges removeAllObjects];
}


-(void)addEdge:(BAEdge*)theEdge
{
    [edges addObject:theEdge];
}

-(void)removeEdge:(BAEdge*)theEdge
{
    [edges removeObject:theEdge];
}

-(BOOL)containsEdge:(BAEdge*) theEdge;
{
    for(id edge in edges)
    {
        if([edge isEqualTo:theEdge])
            return YES;
    }
    return FALSE;
}


-(BOOL)containsPoint:(CGPoint)thePoint
{
    for(id edge in edges)
    {
        if([edge containsPoint:thePoint])
            return YES;
    }
    return FALSE;
}

-(BAEdge*)edgeAtIndex:(long)index
{
    if(index>=0&&index<[edges count])
        return [edges objectAtIndex:index];
    return NULL;
}

-(long)count
{
    return [edges count];
}

-(BAEdge*)firstEdgeNotInArray:(NSArray*)compArray
{
    BAEdge * edge=NULL;
    for(long count=0;count<[edges count];count++)
    {
        edge=[edges objectAtIndex:count];
        for(long compCount=0;compCount<[compArray count];compCount++)
        {
            BAEdge * compEdge=[compArray objectAtIndex:compCount];
            if([compEdge isEqualTo:edge])
            {
                continue;
            }
            else return edge;
        }
    }
    return NULL;
}


-(BAEdgeArray*)copy
{
    BAEdgeArray * edgeArray=[[BAEdgeArray alloc]init];
    edgeArray->edges=[edges mutableCopy];
    return edgeArray;
}

@end

@implementation BARandomDungeonGeneratorDeux
#define NUMBER_OF_RECTS 50
#define TILE_SIZE 1
#define STRENGTH TILE_SIZE
#define MIN_ROOM_SIZE 40
#define START_POINT 300
#define SCALE 16

#define MAX_ROOM_SIZE 100
#define AREA_FILL_PERCENT 0.5f

+(BARandomDungeonGeneratorDeux*)createWithSize:(CGSize)theSize
{
    BARandomDungeonGeneratorDeux *generator=[[BARandomDungeonGeneratorDeux alloc]init];
    generator->size=theSize;
    BAIntBitmap * tempStartBitmap=[BAIntBitmap createWithCGSize:theSize];
    [generator setStartingBitmap:tempStartBitmap];
    return generator;
}

-(id)init
{
    self=[super init];
    averageArea=0;
    rectArray=[[NSMutableArray alloc]init];
    //fixedRectArray=[[NSMutableArray alloc]init];
    borderRectArray=[[NSMutableArray alloc]init];
    finalRectArray=[[NSMutableArray alloc]init];
    passageArray=[[NSMutableArray alloc]init];
    edgeArray=[[BAEdgeArray alloc]init];
    passageRectArray=[[NSMutableArray alloc]init];
    nearestNeighborEdgeArray=[[BAEdgeArray alloc]init];
    
    
    rectsHaveDirection=NO;
    separationComplete=NO;
    nudgeComplete=NO;
    edgeComplete=NO;
    passageComplete=NO;
    rectGenComplete=NO;
    shouldGeneratePassages=YES; //broken right now
    
    discardThreshold=.75f;
    numberOfRects=NUMBER_OF_RECTS;
    
    //Temp starting stuff
    
    
    
    return self;
}

-(void)setShouldGeneratePassages:(BOOL)shouldGenerate
{
    shouldGeneratePassages=shouldGenerate;
}

-(void)setDiscardThreshold:(CGFloat) threshold
{
    if(threshold>0)
        discardThreshold=threshold;
}

-(void)prepareToGenerate
{
    @synchronized(self) {
        
        [rectArray removeAllObjects];
        //[fixedRectArray removeAllObjects];
        [borderRectArray removeAllObjects];
        [edgeArray clear];
        [nearestNeighborEdgeArray clear];
        [finalRectArray removeAllObjects];
        [passageRectArray removeAllObjects];
        separationComplete=NO;
        nudgeComplete=NO;
        edgeComplete=NO;
        passageComplete=NO;
        rectGenComplete=NO;
        
        //[self readBitmap];
        [self generateBorders];
        //[self generateRects];
        
        [self doRectArray];
    }
}

-(void)generateRects
{
    for(int count=0;count<numberOfRects;count++)
    {
        [self addRandomRect];
    }
    /**/
    averageArea=averageAreaOfRectsInArray(rectArray);
}

-(void)addRandomRect
{
    int startX=[startingBitmap midpoint].x;
    int startY=[startingBitmap midpoint].y;
    int width=randomInSpan(MIN_ROOM_SIZE, MAX_ROOM_SIZE)*TILE_SIZE;
    int height=randomInSpan(MIN_ROOM_SIZE, MAX_ROOM_SIZE)*TILE_SIZE;
    CGRect rect=CGRectMake(startX-(width/2), startY-(height/2), width, height);
    [rectArray addObject:[NSValue valueWithCGRect:rect]];
    numberOfRects=[rectArray count];
}
#define BORDER_THICK 4
#define BORDER_THICKNESS (BORDER_THICK * TILE_SIZE)
-(void)generateBorders
{
    //left
    CGRect rect=CGRectMake(-BORDER_THICKNESS, -BORDER_THICKNESS, BORDER_THICKNESS, startingBitmap->size.height+BORDER_THICKNESS+BORDER_THICKNESS);
    [borderRectArray addObject:[NSValue valueWithCGRect:rect]];
    //top
    rect=CGRectMake(-BORDER_THICKNESS, -BORDER_THICKNESS, (startingBitmap->size.width+BORDER_THICKNESS+BORDER_THICKNESS), BORDER_THICKNESS);
    [borderRectArray addObject:[NSValue valueWithCGRect:rect]];
    //bottom
    rect=CGRectMake(-BORDER_THICKNESS, startingBitmap->size.height, (startingBitmap->size.width+BORDER_THICKNESS+BORDER_THICKNESS), BORDER_THICKNESS);

    [borderRectArray addObject:[NSValue valueWithCGRect:rect]];
    //right
    rect=CGRectMake(startingBitmap->size.width, -BORDER_THICKNESS, BORDER_THICKNESS, startingBitmap->size.height+BORDER_THICKNESS+BORDER_THICKNESS);
    [borderRectArray addObject:[NSValue valueWithCGRect:rect]];
    
}

-(void)setPassageTileType:(enum BATileType)tileType
{
    if(tileType>0)
        passageTileType=tileType;
    else
        passageTileType=NoTileType;
}

-(void)setStartingBitmap:(BAIntBitmap *)theBitmap
{
    if(!theBitmap)
        return;
    
    startingBitmap=theBitmap;
    //[theBitmap setValueAtPosition:1 forPosition:CGPointMake(3, 3)];
    //[self readBitmap];
    //[startingBitmap dump];
}

//read bitmap before generation and add fixed rects

-(void)readBitmap
{
    NSLog(@"readBitmap");
    for(long y=0;y<startingBitmap->size.height;y++)
    {
        for(long x=0;x<startingBitmap->size.width;x++)
        {
            int value=[startingBitmap valueAtPosition:CGPointMake(x, y) from:@"BADungeonGenerationView tileBitmapForDungeon"];
            if(value==1)
            {
                CGRect theRect=CGRectMake(x, y, TILE_SIZE, TILE_SIZE);
                //[fixedRectArray addObject:[NSValue valueWithCGRect:theRect]];
                [rectArray addObject:[NSValue valueWithCGRect:theRect]];
                //logRect(theRect, @"readbitmap");
            }
        }
    }
    NSLog(@"done");
}




-(NSMutableArray*)fragmentEdgeArray:(BAEdgeArray*)edgeArray;
{
    //NSLog(@"Starting edge count: %li",[edgeArray count]);
    BAEdgeArray * edgeArrayCopy=[edgeArray copy];
    BAEdgeArray * currentEdgeArray=[[BAEdgeArray alloc]init];
    NSMutableArray * fragments=[[NSMutableArray alloc]init];
    NSMutableArray * toDelete=[[NSMutableArray alloc]init];
    
    long numberOfEdges=[edgeArray count];
    
    long finds=1;
    while([toDelete count]<numberOfEdges)
    {
        while(finds)
        {
            //NSLog(@"go");
            finds=0;
            for(long index=0;index<[edgeArrayCopy count];index++)
            {
                
                BAEdge * edge=[edgeArrayCopy edgeAtIndex:index];
                //NSLog(@"count %li",[edgeArrayCopy count]);
                if([currentEdgeArray count]==0)
                {
                    finds++;
                    [currentEdgeArray addEdge:edge];
                    [toDelete addObject:edge];
                }
                else if([toDelete containsObject:edge])
                {
                    //we've allready hit this one
                    //NSLog(@"Pass");
                    continue;
                }
                else if([currentEdgeArray containsPoint:edge->pointOne]||[currentEdgeArray containsPoint:edge->pointTwo])
                {
                    finds++;
                    [currentEdgeArray addEdge:edge];
                    [toDelete addObject:edge];
                }
            }
        }
        //NSLog(@"yo");
        //run out of finds for this run
        [fragments addObject:currentEdgeArray];
        [edgeArrayCopy->edges removeObjectsInArray:toDelete];
        if([toDelete count]<numberOfEdges)
        {
            currentEdgeArray=[[BAEdgeArray alloc]init];
            finds=1;
        }
        
    }
    
    
    //[edgeArray->edges removeObjectsInArray:toDelete];
    
    //NSLog(@"%li fragments",[fragments count]);
    for(long fragCount=0;fragCount<[fragments count];fragCount++)
    {
        BAEdgeArray * theEArray=[fragments objectAtIndex:fragCount];
        //NSLog(@"EdgeCount:%li",[theEArray count]);
    }
    
    return fragments;
}

-(void)cullDuplicateEdges:(BAEdgeArray*)edgeArray
{
    BAEdgeArray * culledEdgeArray=[[BAEdgeArray alloc]init];
    NSMutableArray * toDeleteArray=[[NSMutableArray alloc]init];
    //NSLog(@"Pre Cull Count:%li",[edgeArray count]);
    for(long index=0;index<[edgeArray count];index++)
    {
        BAEdge * edge=[edgeArray edgeAtIndex:index];
        if(![culledEdgeArray containsEdge:edge])
        {
            [culledEdgeArray addEdge:edge];
        }
        else
        {
            [toDeleteArray addObject:edge];
        }
    }
    [edgeArray->edges removeObjectsInArray:toDeleteArray];
    //NSLog(@"Post Cull Count:%li",[culledEdgeArray count]);
    //return culledEdgeArray;
}

-(BAIntBitmap*)generate
{
    [self prepareToGenerate];
    while (!passageComplete) {
        [self update];
    }
    return [self createBitmap];
}

-(BAIntBitmap*)generateStepped
{
   
    
    [self prepareToGenerate];
    return [self createBitmap];
    //return startingBitmap;
}




-(void)generateEdges
{
    [edgeArray clear];
    [nearestNeighborEdgeArray clear];
    for(long count=0;count<[rectArray count];count++)
    {
        CGRect rect=[[rectArray objectAtIndex:count]CGRectValue];
        float area=rect.size.width*rect.size.height;
        if(area>discardThreshold)
        {
            [finalRectArray addObject:[NSValue valueWithCGRect:rect]];
        }
    }
    //sort rects on x value small x to large x origin
    NSArray * sortedRects= [finalRectArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                   {
                                CGRect firstRect=[(NSValue*)a CGRectValue];
                                CGRect secondRect=[(NSValue*)b CGRectValue];
                                if (firstRect.origin.x > secondRect.origin.x)
                                       return NSOrderedDescending;
                                   else if (firstRect.origin.x < secondRect.origin.x)
                                       return NSOrderedAscending;
                                   return NSOrderedSame;
                               }];
   
    
    //NSLog(@"iterate");
    for(long count=0;count<[sortedRects count];count++)
    {
        if(count<([sortedRects count]-1))
        {
            CGRect rect=[[sortedRects objectAtIndex:count]CGRectValue];
            CGRect nextRect=[[sortedRects objectAtIndex:count+1]CGRectValue];
            //NSLog(@"Rect: %f %f, %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
            CGPoint firstPoint=CGRectMidpoint(rect);
            CGPoint secondPoint=CGRectMidpoint(nextRect);
            
            BAEdge * edge=[BAEdge edgeFromPoints:firstPoint andPoint:secondPoint];
            [edgeArray addEdge:edge];
        }
        //else last rect
        
    }
    [self nearestNeighborEdges:nearestNeighborEdgeArray];
    BAEdgeArray * testArray=[[BAEdgeArray alloc]init];
    [self nearestNeighborEdges:testArray];
    [self fragmentEdgeArray:testArray];
}

-(void)nearestNeighborEdges:(BAEdgeArray*)edgeArray;
{
    [nearestNeighborEdgeArray clear];
    NSArray * sortedRects= [finalRectArray sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                   {
                                CGRect firstRect=[(NSValue*)a CGRectValue];
                                CGRect secondRect=[(NSValue*)b CGRectValue];
                                if (firstRect.origin.x > secondRect.origin.x)
                                       return NSOrderedDescending;
                                   else if (firstRect.origin.x < secondRect.origin.x)
                                       return NSOrderedAscending;
                                   return NSOrderedSame;
                               }];
    
    for(long count=0;count<[sortedRects count];count++)
    {
    float closestDistance=5000;
    float nextClosestDistance=5000;
    
    long closestIndex=0;
    long nextClosestIndex=0;
        
        
    CGRect rect=[[sortedRects objectAtIndex:count]CGRectValue];
    CGPoint rectMidpoint=CGRectMidpoint(rect);
    for(long index=0;index<[sortedRects count];index++)
        {
            if(index==count)
                continue; //same rect
            CGRect comparisonRect=[[sortedRects objectAtIndex:index]CGRectValue];
            CGPoint comparisonRectMidpoint=CGRectMidpoint(comparisonRect);
            
            float tempDistance=simpleDistance(rectMidpoint,comparisonRectMidpoint);
            
            if(tempDistance<=nextClosestDistance)
            {
                if(tempDistance<=closestDistance)
                {
                    
                    closestDistance=tempDistance;
                    closestIndex=index;
                }
                else
                {
                    nextClosestDistance=tempDistance;
                    nextClosestIndex=index;
                }
                    
            }
           
        }
        //NSLog(@"rect:%li closest index: %li next: %li",count,closestIndex,nextClosestIndex);
        CGRect firstNeighbor=[[sortedRects objectAtIndex:closestIndex]CGRectValue];
        BAEdge * newEdge=[BAEdge edgeFromPoints:CGRectMidpoint(rect) andPoint:CGRectMidpoint(firstNeighbor)];
        [nearestNeighborEdgeArray addEdge:newEdge];
        CGRect secondNeighbor=[[sortedRects objectAtIndex:nextClosestIndex]CGRectValue];
        newEdge=[BAEdge edgeFromPoints:CGRectMidpoint(rect) andPoint:CGRectMidpoint(secondNeighbor)];
        [edgeArray addEdge:newEdge];
        
        /*
        CGRect nextRect=[[sortedRects objectAtIndex:count+1]CGRectValue];
        //NSLog(@"Rect: %f %f, %f %f",rect.origin.x,rect.origin.y,rect.size.width,rect.size.height);
        CGPoint firstPoint=CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
        CGPoint secondPoint=CGPointMake(CGRectGetMidX(nextRect), CGRectGetMidY(nextRect));
        
        BAEdge * edge=[BAEdge edgeFromPoints:firstPoint andPoint:secondPoint];
        [edgeArray addObject:edge];
        
        
    
        
        //else last rect
        */
        
        [self cullDuplicateEdges:edgeArray];
        
        
    }
    
}



-(void)doRectArray
{
    //NSLog(@"doRectArray");
    //int counter=0;
    //do
    {
        //NSLog(@"doRectArray");
        for (int current = 0; current < [rectArray count]; current++)
        {
            for (int other = 0; other < [rectArray count]; other++)
            {
                for(int border=0;border <[borderRectArray count];border++)
                {
                    
               
                CGRect borderRect=[[borderRectArray objectAtIndex:border]CGRectValue];
                CGRect currentRect=[[rectArray objectAtIndex:current]CGRectValue];
                CGRect otherRect=[[rectArray objectAtIndex:other]CGRectValue];
                if (current == other)
                    continue;
                //if(!CGRectIntersectsRect(currentRect, otherRect))
                //    continue;
                //if(!CGRectIntersectsRect(currentRect, borderRect))
                //    continue;
                //NSLog(@"continuing");
               //get centers of Rects
                CGPoint currentCenter=CGPointMake(CGRectGetMidX(currentRect), CGRectGetMidY(currentRect));
                CGPoint otherCenter=CGPointMake(CGRectGetMidX(otherRect), CGRectGetMidY(otherRect));
                CGPoint borderCenter=CGPointMake(CGRectGetMidX(borderRect), CGRectGetMidY(borderRect));
                    CGPoint bitmapCenter=[startingBitmap midpoint];
                //First handle intersect with other
                CGFloat dx =0;
                CGFloat dy = 0;
                if(CGRectIntersectsRect(currentRect, otherRect))
                {
                    dx = currentCenter.x - otherCenter.x;
                    dy = currentCenter.y - otherCenter.y;
                }
               else if(CGRectIntersectsRect(currentRect, borderRect))
               {
                   dx = currentCenter.x - bitmapCenter.x;
                   dy = currentCenter.y - bitmapCenter.y;
               }
                //NSLog(@"%i %i %f %f ",current,other, dx,dy);
                // Normalize the components
                CGFloat magnitude = sqrt(dx*dx+dy*dy);
                if(magnitude==0)
                    continue;
                dx /= magnitude;
                dy /= magnitude;
                
                dx *=STRENGTH;
                dy *=STRENGTH;
                    
                //var direction = (rooms[other].Middle - rooms[current].Middle).normalized;
                
                //NSLog(@"%i %f %f %f ",current,magnitude,dx,dy);
               
                
                if(CGRectIntersectsRect(currentRect, borderRect))
                    {
                        CGRect newCurrentRect=CGRectMake(currentRect.origin.x-dx, currentRect.origin.y-dy, currentRect.size.width, currentRect.size.height);
                            //logRect(newCurrentRect, @"newCurrentRect");
                        [rectArray replaceObjectAtIndex:current withObject:[NSValue valueWithCGRect:newCurrentRect]];
                    }
                
                else if(CGRectIntersectsRect(currentRect, otherRect))
                {
                    CGRect newCurrentRect=CGRectMake(currentRect.origin.x+dx, currentRect.origin.y+dy, currentRect.size.width, currentRect.size.height);
                        //logRect(newCurrentRect, @"newCurrentRect");
                    [rectArray replaceObjectAtIndex:current withObject:[NSValue valueWithCGRect:newCurrentRect]];
                    CGRect newOtherRect=CGRectMake(otherRect.origin.x-dx, otherRect.origin.y-dy, otherRect.size.width, otherRect.size.height);
                    
                    [rectArray replaceObjectAtIndex:other withObject:[NSValue valueWithCGRect:newOtherRect]];
                }
                
            }
        }
                
        }
        //counter++;
    }
    //while(counter<10);
    //while ([self doRectsIntersect]);

    //StopTimer(true);
}




-(void)doNudge
{
    for (int current = 0; current < [rectArray count]; current++)
    {
       
    CGRect currentRect=[[rectArray objectAtIndex:current]CGRectValue];
    
    int xMultiplier=currentRect.origin.x/TILE_SIZE;
    int yMultiplier=currentRect.origin.y/TILE_SIZE;
        
    
    CGRect newCurrentRect=CGRectMake(TILE_SIZE*xMultiplier, TILE_SIZE*yMultiplier, currentRect.size.width, currentRect.size.height);
    
    [rectArray replaceObjectAtIndex:current withObject:[NSValue valueWithCGRect:newCurrentRect]];
    //long fixedIndex=indexOfRectInArray(fixedRectArray, currentRect);
    //if(fixedIndex>=0)
    {
        //[fixedRectArray replaceObjectAtIndex:fixedIndex withObject:[NSValue valueWithCGRect:newCurrentRect]];
    }
            
    }
    
    nudgeComplete=YES;
}

-(void)update
{
    if(!rectGenComplete)
    {
        [self addRandomRect];
        averageArea=averageAreaOfRectsInArray(rectArray);
        separationComplete=NO;
        float area=areaOfRectsInArray(rectArray);
        //if([rectArray count]>=numberOfRects)
        //if(area>=(size.width*size.height*.6))
        if(area>=(size.width*size.height*AREA_FILL_PERCENT))
        {
            rectGenComplete=YES;
        }
        
    }
    if(!separationComplete)
    {
        //NSLog(@"update");
        if(doRectsInArrayIntersect(rectArray))
        {
            
            [self doRectArray];
            //if(live)
             //   [self setNeedsDisplay];
        }
        else
        {
            
            separationComplete=YES;
        }
            
    }
    else
    {
    if(!nudgeComplete)
        {
            [self doNudge];
            [self moveRects];
        }
    if(!shouldGeneratePassages)
    {
        passageComplete=YES;
    }
    else if(!edgeComplete)
        {
            [self generateEdges];
            edgeComplete=YES;
        }
    else if(!passageComplete)
        {
        [self generatePassages];
        [self doPassageArray];
            [self cullPassageRects];
        passageComplete=YES;
        tempDungeonBitmap=[self createBitmap];
        //   [tempDungeonBitmap dump];
        }
    }
    
}


-(void)generatePassages
{
    [passageArray removeAllObjects];
    for(long count=0;count<[nearestNeighborEdgeArray count];count++)
    {
        BAEdge * edge=[nearestNeighborEdgeArray edgeAtIndex:count];
        BAPassage * passage=[BAPassage passageFromPoints:edge->pointOne andPoint:edge->pointTwo];
        if(passage)
           [passageArray addObject:passage];
    }
}


-(void)moveRects
{
    CGPoint mins=getMinPointsOfRectsInArray(rectArray);
    //logPoint(mins, @"mins");
    
    //[self translateRectsForX:-mins.x forY:-mins.y];
    translateRectsInArray(rectArray, -mins.x, -mins.y);
    translateRectsInArray(borderRectArray, -mins.x, -mins.y);
}


-(BAIntBitmap*)createBitmap
{
    
    
    CGSize bounds=boundsOfRectsInArray(rectArray, discardThreshold);
    logSize(bounds, @"***createBitmap Bounds");
    //BACharBitmap * bitmap=[[BACharBitmap alloc]init];
    BAIntBitmap * bitmap=[BAIntBitmap createWithCGSize:CGSizeMake(bounds.width+2, bounds.height+2)];
    [bitmap fillWithValue:baseTileType];
    for(int count=0;count<[passageRectArray count];count++)
    {
        CGRect theRect=[[passageRectArray objectAtIndex:count]CGRectValue];
        //float area=theRect.size.width*theRect.size.height;
        [bitmap setValueForRect:passageTileType forRect:theRect];
    }
    
    for(int count=0;count<[rectArray count];count++)
    {
        CGRect theRect=[[rectArray objectAtIndex:count]CGRectValue];
        float area=theRect.size.width*theRect.size.height;
        if(area>discardThreshold)
        {
            //NSLog(@"YESSSSS");
            [bitmap setValueForRect:fillTileType forRect:theRect];
        }
    }
    //[bitmap dump];
    return bitmap;
}


-(void)doPassageArray
{
    for (long current = 0; current < [passageArray count]; current++)
    {
        BAPassage * passage=[passageArray objectAtIndex:current];
        CGPointArray * passagePointArray=NULL;
        passagePointArray=pointsOnLineWithSpacing(passage->edgeOne->pointOne, passage->edgeOne->pointTwo,CGSizeMake(TILE_SIZE, TILE_SIZE));
        
        //[passagePointArray dump];
        NSArray * newRectArray=rectArrayFromCGPointArray(passagePointArray, CGSizeMake(TILE_SIZE, TILE_SIZE));
        [passageRectArray addObjectsFromArray: newRectArray];
        
        CGPointArray * passagePointArray2=NULL;
        passagePointArray2=pointsOnLineWithSpacing(passage->edgeTwo->pointOne, passage->edgeTwo->pointTwo,CGSizeMake(TILE_SIZE, TILE_SIZE));
        
        //[passagePointArray2 dump];
        NSArray * newRectArray2=rectArrayFromCGPointArray(passagePointArray2, CGSizeMake(TILE_SIZE, TILE_SIZE));
        [passageRectArray addObjectsFromArray: newRectArray2];
        
    }
}

//remove passages that overlap rooms
-(void)cullPassageRects
{
    
    NSMutableArray * toDeleteArray=[[NSMutableArray alloc]init];
    for (long index = 0; index < [passageRectArray count]; index++)
    {
        CGRect rect=[[passageRectArray objectAtIndex:index]CGRectValue];
        for(long count=0;count<[rectArray count];count++)
        {
        CGRect compareRect=[[rectArray objectAtIndex:count]CGRectValue];
        float area=compareRect.size.width*compareRect.size.height;
            if(area>discardThreshold)
             {
             if(CGRectIntersectsRect(rect, compareRect))
                {
                [toDeleteArray addObject:[passageRectArray objectAtIndex:index]];
                }
            }
        }
    }
    NSLog(@"cullPassageRects: %li",[toDeleteArray count]);
    [passageRectArray removeObjectsInArray:toDeleteArray];
}


-(NSMutableArray*)rects
{
    return [rectArray mutableCopy];
}

@end
