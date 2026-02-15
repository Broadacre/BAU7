//
//  Utilities.h
//  BAU7
//
//  Created by Dan Brooker on 9/30/21.
//

#ifndef Utilities_h
#define Utilities_h


#endif /* Utilities_h */

int randomInSpan(int minimum, int maximum);
float distance(CGPoint position1, CGPoint position2);
float simpleDistance(CGPoint position1, CGPoint position2);
bool validLocation(CGPoint location);
CGPoint invalidLocation(void);
CGPoint pointToSizedSpace(CGPoint originalPoint,int size);
CGPoint CGPointSubtractFromPoint(CGPoint originalPoint,CGPoint pointToSubtract);
CGPoint CGPointAddToPoint(CGPoint originalPoint,CGPoint pointToAdd);

CGPoint averageOfPoints(CGPoint pointOne,CGPoint pointTwo);
void logPoint(CGPoint thePoint,NSString* text);

@interface CGPointArray: NSObject
{
    @public
    NSMutableArray * points;
}
-(BOOL)addPoint:(CGPoint)thePoint;
-(BOOL)addUniquePoint:(CGPoint)thePoint;
-(BOOL)containsPoint:(CGPoint)thePoint;
-(BOOL)removePoint:(CGPoint)thePoint;
-(long)pointIndex:(CGPoint)thePoint;
-(long)count;
-(CGPoint)pointAtIndex:(long)theIndex;
-(void)dump;
-(CGPoint)nearestToCGPoint:(CGPoint)originPoint;
-(long)indexOfNearestPointToCGPoint:(CGPoint)originPoint;
-(void)removeAllPoints;
-(CGPoint)getRandomPoint;
-(BOOL)addPoints:(CGPointArray*)sourceArray;
-(BOOL)addUniquePoints:(CGPointArray*)sourceArray;
-(CGPoint)average;
-(CGPoint)approximateMidpoint;
@end

CGPointArray* pointsOnLine(CGPoint startPoint, CGPoint endPoint);
CGPointArray* pointsOnLineWithSpacing(CGPoint startPoint, CGPoint endPoint, CGSize size);
CGPointArray* randomPointsInRect(int numberOfPoints,CGRect theRect);
CGPointArray* sortPathByDistance(CGPointArray * thePointArray,CGPoint startPoint);
CGPointArray* pointsSurroundingCGPoint(CGPoint thePoint,int range, bool includeOrigin);

BOOL indexOfLongInNSArray(long theNumber, NSArray* theArray);

NSArray* rectArrayFromCGPointArray(CGPointArray* pointArray, CGSize rectSize);
