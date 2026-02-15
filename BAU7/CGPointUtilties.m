//
//  Utilties.m
//  BAU7
//
//  Created by Dan Brooker on 9/30/21.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#include <CoreGraphics/CGGeometry.h>
#import "CGRectUtilities.h"
#import "CGPointUtilities.h"
int randomInSpan(int minimum, int maximum)
{
    int answer=arc4random() % (maximum+1-minimum)+minimum;
    
    return answer;
    
}

float distance(CGPoint position1, CGPoint position2)
{
    CGFloat xDist = (position2.x - position1.x); //[2]
    CGFloat yDist = (position2.y - position1.y); //[3]
    CGFloat distance = sqrt((xDist * xDist) + (yDist * yDist));
    return fabs(distance);
}

float simpleDistance(CGPoint position1, CGPoint position2)
{
    float distance=fabs(position1.x - position2.x) + fabs(position1.y - position2.y);
    return distance;
}

bool validLocation(CGPoint location)
{
    if(location.x>=0&&location.y>=0)
        return YES;
    return NO;
}

CGPoint invalidLocation(void)
{
    return CGPointMake(-1,-1);
}

//will provide evenly spaced coordinates such as a tilesize
CGPoint pointToSizedSpace(CGPoint originalPoint,int size)
{
    int newLocationX=originalPoint.x/size;
    int newLocationY=originalPoint.y/size;
    //newLocationX=newLocationX*size;
    //newLocationY=newLocationY*size;
    //NSLog(@"New Point: %i %i",newLocationX,newLocationY);
    return(CGPointMake(newLocationX, newLocationY));
}

CGPoint CGPointSubtractFromPoint(CGPoint originalPoint,CGPoint pointToSubtract)
{
    return CGPointMake(originalPoint.x-pointToSubtract.x, originalPoint.y-pointToSubtract.y);
}

CGPoint CGPointAddToPoint(CGPoint originalPoint,CGPoint pointToAdd)
{
    return CGPointMake(originalPoint.x+pointToAdd.x, originalPoint.y+pointToAdd.y);
}




CGPoint averageOfPoints(CGPoint pointOne,CGPoint pointTwo)
{
    float xTotal=0;
    float yTotal=0;
    
    xTotal+=(pointOne.x+pointTwo.x);
    yTotal+=(pointOne.y+pointTwo.y);
    
    xTotal=xTotal/2;
    yTotal=yTotal/2;
    return CGPointMake(xTotal, yTotal);
}


void logPoint(CGPoint thePoint,NSString* text)
{
    NSLog(@"%@ %f %f",text,thePoint.x,thePoint.y);
}






@implementation CGPointArray
-(id)init
{
    self=[super init];
    points=[[NSMutableArray alloc]init];
    return self;
}

-(BOOL)addPoint:(CGPoint)thePoint
{
   
[points addObject:[NSValue valueWithCGPoint:thePoint]];
    return YES;
   
}


-(BOOL)addUniquePoint:(CGPoint)thePoint
{
    if(![self containsPoint:thePoint])
    {
        [points addObject:[NSValue valueWithCGPoint:thePoint]];
        return YES;
    }
    else
        return NO;
}
-(BOOL)containsPoint:(CGPoint)thePoint
{
    long position=[self pointIndex:thePoint];
    if(position>=0)
    {
        return YES;
    }
    return NO;
}

-(long)pointIndex:(CGPoint)thePoint
{
    for(long index=0;index<[points count];index++)
    {
        NSValue *theValue=[points objectAtIndex:index];
        CGPoint tempPoint=[theValue CGPointValue];
        if(CGPointEqualToPoint(tempPoint, thePoint))
        {
            return index;
        }
    }
    return -1;
}
-(BOOL)removePoint:(CGPoint)thePoint
{
    long position=[self pointIndex:thePoint];
    if(position>=0)
    {
        [points removeObjectAtIndex:position];
        return YES;
        
    }
    return NO;
}


-(long)count
{
    return [points count];
}

-(CGPoint)pointAtIndex:(long)theIndex
{
    NSValue *theValue=[points objectAtIndex:theIndex];
    CGPoint tempPoint=[theValue CGPointValue];
    return tempPoint;
}

-(void)dump
{
    for(long index=0;index<[points count];index++)
    {
        CGPoint point=[self pointAtIndex:index];
        NSLog(@"Point %li: %f,%f",index,point.x,point.y);
    }
}

-(CGPoint)nearestToCGPoint:(CGPoint)originPoint
{
    float distance=10000000000;
    CGPoint thePoint=invalidLocation();
    if([points count])
    {
        //NSLog(@"%li points",[points count]);
        //logPoint(originPoint, @"startPoint");
        for(long index=0;index<[points count];index++)
        {
            CGPoint currentPoint=[self pointAtIndex:index];
            float newDistance=simpleDistance(originPoint, currentPoint);
            //NSLog(@"newDistance: %f",newDistance);
            if(newDistance<distance)
            {
                distance=newDistance;;
                //NSLog(@"distance: %f",distance);
                thePoint=currentPoint;
                //logPoint(thePoint, @"point");
            }
            
        }
    }
    //logPoint(thePoint, @"result");
    return thePoint;
}

-(long)indexOfNearestPointToCGPoint:(CGPoint)originPoint
{
    float distance=10000000000;
    long theIndex=-1;
    if([points count])
    {
        //NSLog(@"%li points",[points count]);
        //logPoint(originPoint, @"startPoint");
        for(long index=0;index<[points count];index++)
        {
            CGPoint currentPoint=[self pointAtIndex:index];
            float newDistance=simpleDistance(originPoint, currentPoint);
            //NSLog(@"newDistance: %f",newDistance);
            if(newDistance<distance)
            {
                distance=newDistance;;
                //NSLog(@"distance: %f",distance);
                theIndex=index;
                //logPoint(thePoint, @"point");
            }
            
        }
    }
    return theIndex;
}


-(void)removeAllPoints
{
    [points removeAllObjects];
}


-(CGPoint)getRandomPoint
{
    if([self count])
    {
        CGPoint thePoint;
        long index=arc4random_uniform([self count]);
        //NSLog(@"index:%li",index);
        thePoint=[self pointAtIndex:index];
        if(validLocation(thePoint))
            return thePoint;
    }
    
    return invalidLocation();
}


-(BOOL)addPoints:(CGPointArray*)sourceArray
{
    if(!sourceArray)
        return NO;
   
    for(long index=0;index<[sourceArray count];index++)
    {
        CGPoint thePoint=[sourceArray pointAtIndex:index];
        [self addPoint:thePoint];
    }
    
    return YES;
}

-(BOOL)addUniquePoints:(CGPointArray*)sourceArray
{
    if(!sourceArray)
        return NO;
   
    for(long index=0;index<[sourceArray count];index++)
    {
        CGPoint thePoint=[sourceArray pointAtIndex:index];
        [self addUniquePoint:thePoint];
    }
    
    return YES;
}


-(CGPoint)average
{
    float xTotal=0;
    float yTotal=0;
    
    for(long index=0;index<[self count];index++)
    {
        CGPoint thePoint=[self pointAtIndex:index];
        xTotal+=thePoint.x;
        yTotal+=thePoint.y;
    }
    xTotal=xTotal/[self count];
    yTotal=yTotal/[self count];
    return CGPointMake(xTotal, yTotal);
}


-(CGPoint)approximateMidpoint
{
    CGPoint averagePoint=[self average];
    return [self nearestToCGPoint:averagePoint];
}

@end



CGPointArray* pointsOnLine(CGPoint startPoint, CGPoint endPoint)
{
    CGPointArray * array;
    array=[[CGPointArray alloc]init];
    
    /*
    int startX=startPoint.x;
    int startY=startPoint.y;
    int endX=endPoint.x;
    int endY=endPoint.y;
    
    
    
    float rise=endY-startY;
    float run=endX-startX;
    float slope=rise/run;
    
    //NSLog(@"slope: %f",slope);
    
    for(int x=0;x<abs(endX-startX);x++)
    {
        
        float y=x*slope;
        y=roundf(y);
        int newY=y;
        //NSLog(@"y:%f",y);
        CGPoint thePoint=CGPointMake(startX+x, startY+newY);
        [array addPoint:thePoint];
    }
    return array;
    
    */
    int dx = endPoint.x - startPoint.x;
    int dy = endPoint.y - startPoint.y;
    
    int steps;
    
    if (abs(dx) > abs(dy))
        steps = abs(dx);
    else
        steps = abs(dy);
    float Xincrement = dx / (float) steps;
    float Yincrement = dy / (float) steps;
    
    float x=startPoint.x;
    float y=startPoint.y;
    CGPoint thePoint=CGPointMake(roundf(x),roundf(y));
    CGPoint previousPoint=thePoint;
    [array addPoint:thePoint];
    for(int v=0; v < steps; v++)
    {
    x = x + Xincrement;
    y = y + Yincrement;
    thePoint=CGPointMake(roundf(x),roundf(y));
    
    if((thePoint.x!=previousPoint.x)&&(thePoint.y!=previousPoint.y))
        {
            //Diagonal... pad it out
            //decide if we will pad x or y
            float franctionalX=x-floor(x);
            float fractionalY=y-floor(y);
            if (franctionalX>fractionalY) {
                //pad x
                if(Xincrement<0)
                    [array addPoint:CGPointMake(previousPoint.x-1, previousPoint.y)];
                else
                    [array addPoint:CGPointMake(previousPoint.x+1, previousPoint.y)];
            } else {
                //pad y
                if(Yincrement<0)
                    [array addPoint:CGPointMake(previousPoint.x, previousPoint.y-1)];
                else
                    [array addPoint:CGPointMake(previousPoint.x, previousPoint.y+1)];
            }
        }
    [array addPoint:thePoint];
        previousPoint=thePoint;
    }
    return array;
}

CGPointArray* pointsOnLineWithSpacing(CGPoint startPoint, CGPoint endPoint, CGSize size)
{
    logPoint(startPoint, @"startpoint");
    logPoint(endPoint, @"endpoint");
    CGPointArray * array;
    array=[[CGPointArray alloc]init];
    
    int startX=startPoint.x;
    int startY=startPoint.y;
    int endX=endPoint.x;
    int endY=endPoint.y;
    
    
    
    float rise=endY-startY;
    float run=endX-startX;
    
    
    float slope=rise/run;
    if(!run)
        run=1;
    //if the slope is higher than the height, there will be more than one point added per x iteration
    int yIterations=0;
    if(slope==INFINITY)
    {
     //vertical
        //NSLog(@"Infinity");
        yIterations=ceil(rise/size.height);
    }
    else if(slope==0)
    {
        //horizontal
        yIterations=1;
    }
    else
    {
        yIterations=ceil(slope*size.height);
    }
    NSLog(@"size %f %f rise %f run %f, slope: %f yIterations %i",size.width,size.height, rise, run, slope,yIterations);
      
    
    for(int x=0;x<run;x+=size.width)
    {
        for(int iteration=1;iteration<(yIterations+1);iteration++)
        {
        float newX=x+(size.width/iteration);
        float newY=0;
        if(slope==INFINITY)
        {
         //vertical
            //NSLog(@"Infinity");
            newY=iteration*size.height;
        }
        else if(slope==0)
        {
            //horizontal
            newY=0;
        }
        else
        {
            newY=newX*slope;
        }
            
            
        
        newY=roundf(newY);
        int i_newY=startY+newY;
        int i_newX=startX+newX;
        //NSLog(@"y:%f",y);
        CGPoint thePoint=CGPointMake(i_newX, i_newY);
            logPoint(thePoint, @"LinePoint");
        [array addPoint:thePoint];
        }
        
    }
    return array;
}

CGPointArray* randomPointsInRect(int numberOfPoints,CGRect theRect)
{
    CGPointArray * pointrray;
    pointrray=[[CGPointArray alloc]init];
    
    for(int count=0;count<numberOfPoints;count++)
    {
        CGPoint thePoint=randomCGPointInRect(theRect);
        [pointrray addPoint:thePoint];
    }
    return pointrray;
}

CGPointArray* sortPathByDistance(CGPointArray * thePointArray,CGPoint startPoint)
{
    
    CGPointArray * newPointarray;
    newPointarray=[[CGPointArray alloc]init];
    long numberOfPoints=[thePointArray count];
    CGPoint currentPointInPath=startPoint;
    for(int count=0;count<numberOfPoints;count++)
    {
        CGPoint newPoint=[thePointArray nearestToCGPoint:currentPointInPath];
        [newPointarray addPoint:newPoint];
        [thePointArray removePoint:newPoint];
        currentPointInPath=newPoint;
    }
    return newPointarray;
}

CGPointArray* pointsSurroundingCGPoint(CGPoint thePoint,int range, bool includeOrigin)
{
    CGPointArray* pointArray=[[CGPointArray alloc]init];
//[adjacentPoints removeAllPoints];
//NSLog(@"GetAdjacentTiles: %i, %i",x,y);
int startX = thePoint.x - range;
int startY = thePoint.y - range;
int endX = thePoint.x + range;
int endY = thePoint.y + range;

int iX = startX;
int iY = startY;

for(iY = startY; iY <= endY; iY++) {
    for(iX = startX; iX <= endX; iX++)
    {
        if(!includeOrigin)
        {
        if(CGPointEqualToPoint(thePoint, CGPointMake(iX, iY)))
            {
            continue;
            }
        }
    [pointArray addPoint:CGPointMake(iX, iY)];
    }
}
    return pointArray;
}

BOOL indexOfLongInNSArray(long theNumber, NSArray* theArray)
{
    for(long index=0;index<[theArray count];index++)
    {
        NSNumber * number=[theArray objectAtIndex:index];
        if([number longValue]==theNumber)
        {
            return index;
        }
    }
    
    return -1;
}

NSArray* rectArrayFromCGPointArray(CGPointArray* pointArray, CGSize rectSize)
{
    NSMutableArray * rectArray=[[NSMutableArray alloc]init];
    
    if(!pointArray)
        return NULL;
    if(![pointArray count])
        return NULL;
    for(long index=0;index<[pointArray count];index++)
    {
        CGPoint currentPoint=[pointArray pointAtIndex:index];
        CGRect newRect=CGRectMake(currentPoint.x, currentPoint.y, rectSize.width, rectSize.height);
        [rectArray addObject:[NSValue valueWithCGRect:newRect]];
    }
    
    return ([rectArray copy]);
}
