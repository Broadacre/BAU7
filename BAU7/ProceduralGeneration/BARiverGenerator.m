//
//  BARiverGenerator.m
//  BAU7
//
//  Created by Dan Brooker on 2/2/24.
//
#import "Includes.h"
#import "BARiverGenerator.h"

@implementation BARiverGenerator
+(BARiverGenerator*)createWithSize:(CGSize)theSize
{
    BARiverGenerator *generator=[[BARiverGenerator alloc]init];
    generator->size=theSize;
    return generator;
}


-(BAIntBitmap*)generate
{
    BAIntBitmap* baseBitmap=[BAIntBitmap createWithCGSize:size];
    CGRect theRect=CGRectMake(0, 0, size.width, size.height);
    
    //BOOL validMap=NO;
    [baseBitmap fillWithValue:baseTileType];
    /*
    int startX=0;
    int endX=size.width;
    int startY=size.height/2;
    int endY=startY;
     */
    
    /*
    int startX=size.width/2;
    int endX=startX;
    int startY=0;
    int endY=size.height;
     
    int startX=0;
    int endX=size.width;
    int startY=0;
    int endY=size.height;
    
    CGPoint startPoint=CGPointMake(startX, startY);
    CGPoint endPoint=CGPointMake(endX, endY);
     */
    CGPoint startPoint=randomCGPointInRect(theRect);
    CGPoint endPoint=randomCGPointInRect(theRect);
    logPoint(startPoint, @"startPoint");
    logPoint(endPoint, @"endPoint");
    CGPointArray * array=pointsOnLine(startPoint, endPoint);
    [baseBitmap setValuesAtPositions:fillTileType forPositions:array];
    if([array count]>5)
    {
        CGPoint midPoint=[array approximateMidpoint];
        CGPoint midMidPoint=averageOfPoints(midPoint, endPoint);
        CGPoint finalMidMidPoint=[array nearestToCGPoint:midMidPoint];
        int offset=randomInSpan(3, 5);
        CGPoint fork=CGPointMake(endPoint.x+offset, endPoint.y+offset);
        CGPointArray * forkArray=pointsOnLine(finalMidMidPoint, fork);
        [baseBitmap setValuesAtPositions:fillTileType forPositions:forkArray];
    }
    
    
    
    //[array dump];
    //[baseBitmap ]
    return baseBitmap;
}
@end
