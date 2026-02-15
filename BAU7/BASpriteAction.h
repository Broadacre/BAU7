//
//  BASpriteAction.h
//  BAU7
//
//  Created by Dan Brooker on 9/23/21.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class CGPointArray;
enum BAActionType
{
    NoActionType=0,
    IdleActionType=1,
    MoveActionType=2,
    AttackActionType=3,
    Attack2HActionType=4,
    SitActionType=5,
    SitRecoveryActionType=6,
    BowActionType=7,
    BowRecoverActionType=8,
    KneelActionType=9,
    KneelRecoverActionType=10,
    MoveAdjacentToTargetActionType=11,
    PickUpItemActionType=12,
    HarvestItemActionType=13,
    MoveToSpriteActionType=14,
    DeadActionType=15,
    
    UserMoveActionType=100,
    
    //deprecated???
    MoveOnPathActionType=1000,
    PerformActionSequenceActionType=1010
};

@interface BASpriteAction : NSObject
{
    //@public
    long currentAnimationStep;
    long currentDistance;
    float currentDuration;
    float currentIterations;
    
    BOOL complete;
    BOOL moves;
    BOOL hasStarted; //has the action started?
    
    float targetIterations;
    float targetDuration;
    float targetDistanceTraveled;
    float targetDistanceFromTarget;
    
    enum BAActionType type;
    enum BACardinalDirection direction;
    CGPoint targetLocation;
    BASprite * targetSprite;
    BAActor * targetActor;
    CGPointArray* path;
    U7AnimationSequence * animationSequence;
}

-(id)init;
-(void)reset;
-(void)dump;

//setters
-(void)setAnimationSequence:(U7AnimationSequence*)sequence;
-(void)setDirection:(enum BACardinalDirection)theDirection;
-(void)setActionType:(enum BAActionType)theType;
-(void)setComplete:(BOOL)isComplete;
-(void)setTargetDistanceTraveled:(int)theDistance;
-(void)setTargetDuration:(float)theDuration;
-(void)setTargetIterations:(float)theIterations;
-(void)setTargetSprite:(BASprite*)theSprite;
-(void)setTargetActor:(BAActor*)theActor;
-(void)setCurrentDistance:(int)theDistance;
-(void)setPath:(CGPointArray*)thePath;
-(void)setTargetLocation:(CGPoint)theTarget;
-(void)setCurrentIteration:(float)iteration;

//getters
-(BOOL)started;
-(BOOL)isComplete;
-(float)getDistance;
-(float)getDuration;
-(float)getTargetDistanceTraveled;
-(float)getTargetDuration;
-(float)getTargetIterations;
-(enum BACardinalDirection)getDirection;
-(enum BAActionType)getActionType;
-(CGPoint)getTargetLocation;
-(BASprite*)getTargetSprite;
-(BAActor*)getTargetActor;
-(float)getCurrentIterations;

//Utils
-(void)step;
-(long)frameID;
-(CGPoint)translationPoint;
-(CGPoint)translate;
-(void)addDuration:(float)timeToAdd;
-(void)addDistance:(long)distanceToAdd;
-(BOOL)checkComplete;
-(float)rotation;
-(BOOL)doesSequenceTypeMove:(enum AnimationSequenceType)type;
-(enum BACardinalDirection)directionForAnimationSequenceType:(enum AnimationSequenceType)type;
-(enum AnimationSequenceType)AnimationSequenceTypeForState;
@end

NS_ASSUME_NONNULL_END
