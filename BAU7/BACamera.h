//
//  BACamera.h
//  BAU7
//
//  Created by Dan Brooker on 10/2/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BACamera : NSObject
{
    CGPoint center;
    CGRect bounds;
    
    U7Environment * environment;
    
}
-(void)setEnvironment:(U7Environment*)theEnvironment;
-(void)setCenter:(CGPoint)globalCenter;
-(void)setBounds:(CGRect)theBounds;
-(CGPoint)getCenter;
-(CGRect)getBounds;
-(long)chunkIDAtGlobalPoint:(CGPoint)globalPoint;
-(CGPoint)chunkIndexAtGlobalPoint:(CGPoint)globalPoint;
@end

NS_ASSUME_NONNULL_END
