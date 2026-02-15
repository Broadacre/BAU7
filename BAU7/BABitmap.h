//
//  BABitmap.h
//  BAU7
//
//  Created by Dan Brooker on 12/11/22.
//

#import <Foundation/Foundation.h>

#import "CGPointUtilities.h"
NS_ASSUME_NONNULL_BEGIN

@interface BABitmap : NSObject
{
    @public
    CGSize size;
}
-(void)dump;
-(void)clear;
-(BOOL)validPosition:(CGPoint)thePosition;
-(CGRect)getBounds;
-(CGPoint)midpoint;
-(float)width;
-(float)height;
@end

@interface BACharBitmap : BABitmap
{
    @public
    NSMutableArray * bitmap;
}
+(BACharBitmap*)createWithCGSize:(CGSize)theSize;
-(char)valueAtPosition:(CGPoint)position;
-(void)setValueAtPosition:(char)theValue forPosition:(CGPoint)position;
-(void)setValueForRect:(char)theValue forRect:(CGRect)theRect;
-(void)fillWithValue:(char)theValue;
@end



@interface BABooleanBitmap : BABitmap
{
    NSMutableArray * bitmap;
}
+(BABooleanBitmap*)createWithCGSize:(CGSize)theSize;
-(BOOL)valueAtPosition:(CGPoint)position;
-(void)setValueAtPosition:(BOOL)theValue forPosition:(CGPoint)position;
-(void)fillWithValue:(BOOL)theValue;
-(void)fillWithArray:(NSArray*)theArray;
-(void)frameWithValue:(BOOL)theValue;
-(BABooleanBitmap*)inverse;
@end


@interface BAIntBitmap : BABitmap
{
@public
    NSMutableArray * bitmap;
}
+(BAIntBitmap*)createWithCGSize:(CGSize)theSize;
+(BAIntBitmap*)clipBitmapToSize:(BAIntBitmap *)sourceBitmap forSize:(CGSize)theSize padWithValue:(int)padValue;
+(BAIntBitmap*)clipBitmapToRect:(BAIntBitmap *)sourceBitmap forSize:(CGRect)theRect padWithValue:(int)padValue;
-(int)valueAtPosition:(CGPoint)position from:(NSString*)caller;
-(void)setValueAtPosition:(int)theValue forPosition:(CGPoint)position;
-(void)setValuesAtPositions:(int)theValue forPositions:(CGPointArray*)positions;
-(void)setValueForRect:(int)theValue forRect:(CGRect)theRect;
-(void)setValueForRectWithMask:(int)theValue forRect:(CGRect)theRect forMask:(BABooleanBitmap*)theMask;
-(void)fillWithValue:(int)theValue;
-(void)fillWithArray:(NSArray*)theArray;
-(long)countOfValue:(int)theValue;
-(BOOL)containsValue:(int)theValue forPosition:(CGPoint)position;
-(void)frameWithValue:(int)theValue;
-(CGPoint)closestPositionOnYAxisWithValue:(int)theValue atX:(long)x atZeroY:(BOOL)startAtZeroY;
-(CGPoint)closestPositionOnXAxisWithValue:(int)theValue atY:(long)y atZeroX:(BOOL)startAtZeroX;
-(CGPointArray *)closestPositionOnXAxisWithValue:(int)theValue atZeroX:(BOOL)startAtZeroX;
-(CGPointArray *)closestPositionOnYAxisWithValue:(int)theValue atZeroY:(BOOL)startAtZeroY;
-(CGPointArray *)BordersOnXAxisWithValue:(int)theValue atZeroX:(BOOL)startAtZeroX;
-(CGPointArray *)BordersOnYAxisWithValue:(int)theValue atZeroY:(BOOL)startAtZeroY;
-(CGPointArray *)allBordersWithValue:(int)theValue;
-(BOOL)copyToBitmap:(BAIntBitmap*)destination atPosition:(CGPoint)thePosition;
-(BOOL)isRectFilledWithValue:(CGRect)theRect withValue:(int)theValue;
-(CGPointArray *)originsOfRectsFilledWithValue:(int)theValue ofSize:(CGSize)size;
-(CGPoint)originOfRandomRectFilledWithValue:(int)theValue ofSize:(CGSize) theSize;
-(BOOL)compareBitmap:(BAIntBitmap*)comparisonBitmap atPosition:(CGPoint)position;
-(BOOL)compareBitmapWithMask:(BAIntBitmap*)comparisonBitmap withMask:(BABooleanBitmap*)maskBitmap atPosition:(CGPoint)position;
-(CGPointArray*)pointsMatchingBitmapWithMask:(BAIntBitmap*)comparisonBitmap forMask:(BABooleanBitmap*)theMask;

@end



NS_ASSUME_NONNULL_END
