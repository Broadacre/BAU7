//
//  CGRectUtilities.m
//  BAU7
//
//  Created by Dan Brooker on 2/16/24.
//

#import <Foundation/Foundation.h>
#import "Includes.h"
#include "CGRectUtilities.h"

void logRect(CGRect theRect,NSString* text)
{
    NSLog(@"%@ %f %f %f %f",text,theRect.origin.x,theRect.origin.y, theRect.size.width,theRect.size.height);
}
void logSize(CGSize theSize, NSString* text)
{
    NSLog(@"%@ %f %f",text,theSize.width,theSize.height);
}

long indexOfRectInArray(NSArray* theArray, CGRect theRect)
{
    for(long index=0;index<[theArray count];index++)
    {
        NSValue * value=[theArray objectAtIndex:index];
        CGRect compareRect=[value CGRectValue];
        if(CGRectEqualToRect(compareRect, theRect))
        {
            return index;
        }
    }
    return -1;
}

BOOL arrayContainsRect(NSArray* theArray, CGRect theRect)
{
    if(!theArray)
    {
        NSLog(@"arrayContainsRect badArray");
        return NO;
    }
    long index=indexOfRectInArray(theArray, theRect);
    if(index>0)
        return YES;
    
    return NO;
}

CGPoint randomCGPointInRect(CGRect theRect)
{
    int xPos=randomInSpan(theRect.origin.x,theRect.size.width+theRect.origin.x);
    int yPos=randomInSpan(theRect.origin.y,theRect.size.height+theRect.origin.y);
    CGPoint thePoint=CGPointMake(xPos, yPos);
    //logPoint(thePoint, @"Point");
    return thePoint;
}

CGPoint CGRectMidpoint(CGRect theRect)
{
    return CGPointMake(CGRectGetMidX(theRect), CGRectGetMidY(theRect));
}


CGRect translateRect(CGRect theRect, float xTranslate, float yTranslate)
{
    CGRect newRect=CGRectMake(theRect.origin.x+xTranslate, theRect.origin.y+yTranslate, theRect.size.width, theRect.size.height);
    
    return newRect;
}


float areaOfRectsInArray(NSArray * theArray)
{
    float totalArea=0;
    
    if(!theArray)
    {
        NSLog(@"averageAreaOfRectsInArray badArray");
        return -1;
    }
    
    
    for (int index = 0; index < [theArray count]; index++)
    {
        CGRect currentRect=[[theArray objectAtIndex:index]CGRectValue];
        totalArea+=(currentRect.size.width*currentRect.size.height);
    }
    return totalArea;
}

float averageAreaOfRectsInArray(NSArray * theArray)
{
    float totalArea=0;
    
    if(!theArray)
    {
        NSLog(@"averageAreaOfRectsInArray badArray");
        return -1;
    }
    
    
    for (int index = 0; index < [theArray count]; index++)
    {
        CGRect currentRect=[[theArray objectAtIndex:index]CGRectValue];
        totalArea+=(currentRect.size.width*currentRect.size.height);
    }
    totalArea=totalArea/[theArray count];
    return totalArea;
}

BOOL doRectsInArrayIntersect(NSArray * theArray)
{
    if(!theArray)
    {
        NSLog(@"doRectsInArrayIntersect badArray");
        return  NO;
    }
    
    for (int current = 0; current < [theArray count]; current++)
    {
        for (int other = 0; other < [theArray count]; other++)
        {
            CGRect currentRect=[[theArray objectAtIndex:current]CGRectValue];
            CGRect otherRect=[[theArray objectAtIndex:other]CGRectValue];
            
            if (current == other || !CGRectIntersectsRect(currentRect, otherRect)) continue;
            return YES;
        }
    }
    return NO;
}


CGSize boundsOfRectsInArray(NSArray * theArray, float areaThresholdToInclude)
{
    
    float maxY=0;
    float maxX=0;
    
    if(!theArray)
    {
        NSLog(@"doRectsInArrayIntersect badArray");
        return  CGSizeMake(-1, -1);
    }
    
    for(int count=0;count<[theArray count];count++)
    {
        CGRect theRect=[[theArray objectAtIndex:count]CGRectValue];
        float area=theRect.size.width*theRect.size.height;
        if(area>areaThresholdToInclude)
        {
            if(theRect.size.height+theRect.origin.y>maxY)
                maxY=theRect.size.height+theRect.origin.y;
            if(theRect.size.width+theRect.origin.x>maxX)
                maxX=theRect.size.width+theRect.origin.x;
        }
    }
    
    return CGSizeMake(maxX, maxY);
}


CGPoint getMinPointsOfRectsInArray(NSArray * theArray)
{
    float minY=1000000;
    float minX=1000000;
    
    if(!theArray)
    {
        NSLog(@"doRectsInArrayIntersect badArray");
        return  invalidLocation();
    }
    
    for(int count=0;count<[theArray count];count++)
    {
        CGRect theRect=[[theArray objectAtIndex:count]CGRectValue];
        //for now include discards...ignore area
        //float area=theRect.size.width*theRect.size.height;
        //if(area>(meanArea*roomThreshold))
        {
            if(theRect.origin.y<minY)
                minY=theRect.origin.y;
            if(theRect.origin.x<minX)
                minX=theRect.origin.x;
        }
    }
    return CGPointMake(minX, minY);
}

void translateRectsInArray(NSMutableArray * theArray,float xTranslate, float yTranslate)
{
    if(!theArray)
    {
        NSLog(@"translateRectsInArray badArray");
        return;
    }
    
    for (long index = 0; index < [theArray count]; index++)
    {
        
        CGRect currentRect=[[theArray objectAtIndex:index]CGRectValue];
        CGRect newCurrentRect=translateRect(currentRect, xTranslate, yTranslate);
        
        [theArray replaceObjectAtIndex:index withObject:[NSValue valueWithCGRect:newCurrentRect]];
    }
    
}
