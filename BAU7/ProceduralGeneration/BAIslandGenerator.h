//
//  BAIslandGenerator.h
//  BAU7
//
//  Created by Dan Brooker on 1/30/24.
//

#import "BAProceduralGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BAIslandGenerator : BAProceduralGenerator
{
    
    BAU7BitmapInterpreter * interpreter;
    float validIslandThreshold;
    float percentToFill;
}
+(BAIslandGenerator*)createWithSize:(CGSize)theSize;
-(void)setValidIslandThreshhold:(float)theThreshhold;
-(void)setPercentToFill:(float)thePercent;
@end

NS_ASSUME_NONNULL_END
