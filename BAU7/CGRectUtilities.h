//
//  CGRectUtilities.h
//  BAU7
//
//  Created by Dan Brooker on 2/16/24.
//



void logRect(CGRect theRect,NSString* text);
void logSize(CGSize theSize, NSString* text);
long indexOfRectInArray(NSArray* theArray, CGRect theRect);
BOOL arrayContainsRect(NSArray* theArray, CGRect theRect);
CGPoint randomCGPointInRect(CGRect theRect);
CGPoint CGRectMidpoint(CGRect theRect);
CGRect translateRect(CGRect theRect, float xTranslate, float yTranslate);
float areaOfRectsInArray(NSArray * theArray);
float averageAreaOfRectsInArray(NSArray * theArray);
BOOL doRectsInArrayIntersect(NSArray * theArray);
CGSize boundsOfRectsInArray(NSArray * theArray, float areaThresholdToInclude);
CGPoint getMinPointsOfRectsInArray(NSArray * theArray);
void translateRectsInArray(NSMutableArray * theArray,float xTranslate, float yTranslate);
