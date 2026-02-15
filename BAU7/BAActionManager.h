//
//  BAActionManager.h
//  BAU7
//
//  Created by Dan Brooker on 9/23/21.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@class BASprite;
@class BAActor;
@class CGPointArray;
@class BABooleanBitmap;

@interface ShortestPathStep : NSObject
{
    @public
    CGPoint position;
    int gScore;
    int hScore;
    ShortestPathStep *parent;
}
- (id)initWithPosition:(CGPoint)pos;
- (int)fScore;
@end

@interface BAActionSequence: NSObject
{
    BOOL doesLoop;
    BOOL complete;
    NSMutableArray * actions;
    long currentActionIndex;
}

-(void)clear;
-(long)count;
-(void)addAction:(BASpriteAction *)theAction;
-(void)insertAction:(BASpriteAction *)theAction atIndex:(long)theIndex;


-(void)update;


-(BASpriteAction *)nextAction;
-(BASpriteAction *)firstAction;
-(BASpriteAction *)lastAction;
-(BASpriteAction *)currentAction;

-(void)incrementIndex;

-(BASpriteAction *)actionAtIndex:(long)index;
+(BAActionSequence*)ActionSequenceFromCGPointArray:(CGPointArray*)pointArray;
-(void)dump;
-(void)resetActions;
-(void)insertActionAtNextIndex:(BASpriteAction *)theAction;

@end

@interface BAActionManager : NSObject

{
    @public
    enum BAActionType actionType;
    BAActor * actor;
    BAActionSequence * currentSequence;
    BASpriteAction * currentAction;
    BASpriteAction * subAction;
    U7Environment * environment;
    U7Map * map;
    CGRect bounds;
    CGPoint targetGlobalLocation;
    BASprite * targetSprite;
    BAActor * targetActor;
    BOOL actionSequenceComplete;
    BOOL subActionComplete;
    //moveThroughCGPointArray
    long pointArrayIndex;
    CGPointArray* pointArray;
    
    //A*
    long maxIterations;
    BABooleanBitmap * closedSteps;
    BOOL buildPathComplete;
    BOOL pathfindingInProgress;
    NSMutableArray *spOpenSteps;
    NSMutableArray *spClosedSteps;
    NSMutableArray *shortestPath;
    NSMutableArray *pendingPath;
    NSMutableArray *doNotTargetList;
    NSMutableArray *doNotGoToList;
    
    // Background pathfinding
    dispatch_queue_t pathfindingQueue;
    
}
-(void)update;
-(void)step;
-(void)setActor:(BAActor*)theActor;
-(void)setEnvironment:(U7Environment*)theEnvironment;
-(void)setMap:(U7Map*)theMap;
-(void)setTargetLocation:(CGPoint)theLocation;
-(void)setTargetSprite:(BASprite*)theSprite;
-(void)setTargetActor:(BAActor*)theActor;

-(void)setShapeReference:(U7ShapeReference *)theShapeReference;


-(void)setSequenceComplete:(BOOL)isComplete;
-(void)addActionToSequence:(BASpriteAction*)theAction;


-(void)setActionSequence:(BAActionSequence*)theSequence;

-(void)setBounds:(CGRect)theBounds;
-(void)setAction:(enum BAActionType)theActionType forDirection:(enum BACardinalDirection)theDirection forTarget:(CGPoint)target;

-(void)setCGPointArray:(CGPointArray*)thePointArray;

-(enum BACardinalDirection)randomDirection;
-(CGPoint)randomPointInBounds;
-(CGPoint)randomPointInDefinedBounds:(CGRect)theBounds;
-(enum BACardinalDirection)DirectionTowardPoint:(CGPoint)startPoint toPoint:(CGPoint)destinationPoint;
-(void)resetPath;
@end

NS_ASSUME_NONNULL_END
