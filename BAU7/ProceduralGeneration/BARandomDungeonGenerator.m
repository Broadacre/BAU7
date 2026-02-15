//
//  BARandomDungeonGenerator.m
//  BAU7
//
//  Created by Dan Brooker on 2/10/24.
//

#import "BARandomDungeonGenerator.h"

@implementation BADungeonNode

-(id)init
{
    self=[super init];
    startPoint=invalidLocation();
    iterations=0;
    return self;
}

+(BADungeonNode*)createWithStartPoint:(CGPoint)start forDirection:(enum BACardinalDirection)theDirection forIterations:(int)theIterations
{
    BADungeonNode * node=[[BADungeonNode alloc]init];
    node->direction=theDirection;
    node->startPoint=start;
    node->iterations=theIterations;
    return node;
}

@end

@implementation BARandomDungeonGenerator
+(BARandomDungeonGenerator*)createWithSize:(CGSize)theSize
{
    BARandomDungeonGenerator *generator=[[BARandomDungeonGenerator alloc]init];
    generator->size=theSize;
    generator->dungeonTable=[BATable fetchTableByTitleFromArray:tables forTitle:@"River Generation"];
    generator->maximumCorridorLength=4;
    generator->minimumCorridorLength=2;
    return generator;
}

-(BAIntBitmap*)generate
{
    BAIntBitmap* baseBitmap=[BAIntBitmap createWithCGSize:size];
    CGRect theRect=CGRectMake(0, 0, size.width, size.height);
    [baseBitmap fillWithValue:baseTileType];
    BADungeonNode * node=[BADungeonNode createWithStartPoint:randomCGPointInRect(theRect) forDirection:randomNESWDirection() forIterations:50];
    
    NSMutableArray * workQueue=[[NSMutableArray alloc]init];
    
    [workQueue addObject:node];
    
    while([workQueue count])
    {
        BADungeonNode * node=[workQueue objectAtIndex:0];
        [self processNode:node forBitmap:baseBitmap forQueue:workQueue];
        [workQueue removeObject:node];
    }
    
    
    
    return baseBitmap;
}

-(void)processNode:(BADungeonNode*)node forBitmap:(BAIntBitmap*)bitmap forQueue:(NSMutableArray*)queue
{
    BATableEntry * entry;
    CGPoint currentPoint=node->startPoint;
    
    int iterations=0;
    while(iterations<node->iterations)
    {
        entry=[dungeonTable randomEntry];
        //[entry dump];
        switch (entry->value) {
            case 1:
                NSLog(@"Continues Straight");
               int distance=randomInSpan(minimumCorridorLength, maximumCorridorLength);
                for(int count=0;count<distance;count++)
                {
                    if([bitmap validPosition:CGPointAddToPoint(currentPoint,translatePoint(node->direction,1))])
                    {
                        //if( [bitmap valueAtPosition:CGPointAddToPoint(currentPoint,translatePoint(node->direction,1)) from:@"processNode"]==baseTileType) //only move forward if empty
                        {
                            currentPoint=CGPointAddToPoint(currentPoint,translatePoint(node->direction,1));
                            [bitmap setValueAtPosition:fillTileType forPosition:currentPoint];
                        }
                    }
                    iterations++;
                }
               
                
               
                break;
                
            case 2:
                NSLog(@"Left 90");
                node->direction=rotateNinetyDegreesCounterClockwise(node->direction);
                iterations++;
                break;
                
            case 3:
                NSLog(@"Right 90");
                node->direction=rotateNinetyDegreesClockwise(node->direction);
                iterations++;
                break;
        
            case 4:
            {
                BOOL left=randomInSpan(0, 1);
                enum BACardinalDirection newDirection;
                if(left)
                    newDirection=rotateNinetyDegreesCounterClockwise(node->direction);
                else
                    newDirection=rotateNinetyDegreesClockwise(node->direction);
                BADungeonNode * newNode=[BADungeonNode createWithStartPoint:currentPoint forDirection:newDirection forIterations:node->iterations/3];
                [queue addObject:newNode];
                NSLog(@"Split");
                iterations++;
            }
                break;
            case 5:
            {
               
                BADungeonNode * newNode=[BADungeonNode createWithStartPoint:currentPoint forDirection:rotateNinetyDegreesClockwise(node->direction) forIterations:node->iterations/3];
                [queue addObject:newNode];
                 newNode=[BADungeonNode createWithStartPoint:currentPoint forDirection:rotateNinetyDegreesCounterClockwise(node->direction) forIterations:node->iterations/3];
                [queue addObject:newNode];
                NSLog(@"Split");
                iterations++;
            }
                break;
                        
            default:
                break;
        }
        iterations++;
    }
}

@end
