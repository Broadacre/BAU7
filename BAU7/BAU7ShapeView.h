//
//  BAU7ShapeView.h
//  BAU7ShapeView
//
//  Created by Dan Brooker on 9/6/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAU7ShapeView : UIView
{
    @public
    int shapeID;
    int currentFrame;
    BOOL animate;
    BOOL showOrigin;
    U7Environment * environment;
    U7Shape * shape;
    NSMutableArray * currentShapeLibrary;
}
-(void)setShapeID:(int)theShapeID;
-(void)setEnvironment:(U7Environment*)theEnvironment;
-(void)setShapeLibrary:(NSMutableArray*)theLibrary;
-(void)setFrameNumber:(int)frameNumber;
-(CGSize)sizeForFrame:(int)frameNumber;
-(long)numberOfFrames;

@end

NS_ASSUME_NONNULL_END
