//
//  BARandomDungeonGenerator.h
//  BAU7
//
//  Created by Dan Brooker on 2/10/24.
//

#import "Includes.h"
#import "BAProceduralGenerator.h"

NS_ASSUME_NONNULL_BEGIN
@interface BADungeonNode : NSObject
{
    @public
    enum BACardinalDirection direction;
    CGPoint startPoint;
    int iterations;
}
+(BADungeonNode*)createWithStartPoint:(CGPoint)start forDirection:(enum BACardinalDirection)theDirection forIterations:(int)theIterations;
@end

@interface BARandomDungeonGenerator : BAProceduralGenerator
{
    BATable * dungeonTable;
    int minimumCorridorLength;
    int maximumCorridorLength;
}
    +(BARandomDungeonGenerator*)createWithSize:(CGSize)theSize;

@end

NS_ASSUME_NONNULL_END
