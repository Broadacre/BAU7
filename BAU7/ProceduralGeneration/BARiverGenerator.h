//
//  BARiverGenerator.h
//  BAU7
//
//  Created by Dan Brooker on 2/2/24.
//

#import "BAProceduralGenerator.h"

NS_ASSUME_NONNULL_BEGIN

@interface BARiverGenerator : BAProceduralGenerator
+(BARiverGenerator*)createWithSize:(CGSize)theSize;
@end

NS_ASSUME_NONNULL_END
