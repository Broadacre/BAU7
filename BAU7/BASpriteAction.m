//
//  BASpriteAction.m
//  BAU7
//
//  Created by Dan Brooker on 9/23/21.
//
#import "BAU7Objects.h"
#import "CGPointUtilities.h"
#import "BABitmap.h"
#import "Globals.h"
#import "BASpriteAction.h"

@implementation BASpriteAction
-(id)init
{
    self=[super init];
    targetDuration=0;
    targetDistanceTraveled=0;
    targetIterations=0;
    type=NoActionType;
    moves=NO;
    direction=NorthCardinalDirection;
    [self reset];
    return self;
}

-(void)reset
{
    //NSLog(@"******reset");
    currentAnimationStep=0;
    currentDistance=0;
    currentDuration=0;
    currentIterations=0;
    complete=NO;
    hasStarted=NO;
}

-(void)dump
{
    //NSLog(@"currentAnimationStep: %li",currentAnimationStep);
    //NSLog(@"currentDistance: %li",currentDistance);
    //NSLog(@"currentDuration: %f",currentDuration);
    //NSLog(@"targetDuration: %f",targetDuration);
    // NSLog(@"targetDistance: %f",targetDistance);
    //NSLog(@"complete: %i",complete);
    //NSLog(@"hasStarted: %i",hasStarted);
    NSLog(@"type: %i",type);
    //NSLog(@"moves: %i",moves);
    //NSLog(@"direction: %i",direction);
    logPoint(targetLocation, @"Target");
   
}

#pragma mark Setters

-(void)setAnimationSequence:(U7AnimationSequence*)sequence
{
    if(sequence)
    {
        animationSequence=sequence;
        //direction=[self directionForAnimationSequenceType:sequence->type];
        moves=[self doesSequenceTypeMove:sequence->type];
    }
    
}

-(void)setDirection:(enum BACardinalDirection)theDirection
{
    direction=theDirection;
}


-(void)setActionType:(enum BAActionType)theType
{
    type=theType;
}

-(void)setComplete:(BOOL)isComplete
{
    if(isComplete)
    {
        currentDistance=0;
        currentDuration=0;
    }
    complete=isComplete;
}
-(void)setTargetDistanceTraveled:(int)theDistance
{
    targetDistanceTraveled=theDistance;
}
-(void)setTargetDuration:(float)theDuration
{
    targetDuration=theDuration;
}
-(void)setTargetIterations:(float)theIterations
{
    targetIterations=theIterations;
}

-(void)setTargetSprite:(BASprite*)theSprite
{
    if(theSprite)
        targetSprite=theSprite;
}


-(void)setTargetActor:(BAActor*)theActor
{
    if(theActor)
        targetActor=theActor;
}

-(void)setCurrentDistance:(int)theDistance
{
    currentDistance=theDistance;
}

-(void)setPath:(CGPointArray*)thePath
{
    if(thePath)
        path=thePath;
}

-(void)setTargetLocation:(CGPoint)theTarget
{
    if(validLocation(theTarget))
        targetLocation=theTarget;
}

-(void)setCurrentIteration:(float)iteration
{
    currentIterations=iteration;
}



#pragma mark Getters
-(BOOL)started
{
    return hasStarted;;
}

-(BOOL)isComplete
{
    return complete;
}

-(float)getDistance
{
    
    //NSLog(@"currentDistance:%ld",currentDistance);
    return currentDistance;
}

-(float)getDuration
{
    return currentDuration;
}


-(float)getTargetDistanceTraveled
{
    //NSLog(@"getTargetDistance:%f",targetDistance);
    return targetDistanceTraveled;
}

-(float)getTargetDuration
{
    return targetDuration;
}

-(float)getTargetIterations
{
    return targetIterations;
}

-(enum BACardinalDirection)getDirection
{
    //NSLog(@"Direction:%i",direction);
    return direction;
}

-(enum BAActionType)getActionType
{
    return type;
}

-(CGPoint)getTargetLocation
{
    return targetLocation;
}

-(BASprite*)getTargetSprite
{
    return targetSprite;
}
-(BAActor*)getTargetActor
{
    return targetActor;
}

-(float)getCurrentIterations
{
    return currentIterations;
}




#pragma mark Utils


-(void)step
{
    //NSLog(@"BASpriteAction Step\n");
    //printf("\n");
    complete=[self checkComplete];
    if(!complete)
    {
        currentAnimationStep++;
        hasStarted=YES;
        //currentIterations= currentAnimationStep/[animationSequence numberOfFrames];
        currentIterations++;
        //NSLog(@"iterations: %f",currentIterations);
    }
    else
    {
        //NSLog(@"BASpriteAction Step complete");
    }
    
}


-(long)frameID
{
    if(animationSequence)
    {
        return [animationSequence frameForStep:currentAnimationStep];
    }
    return 0;
}



-(CGPoint)translationPoint
{
    switch (direction) {
        case NorthCardinalDirection:
        {
            
                return CGPointMake(0,-1);
        }
            break;
        case NorthEastCardinalDirection:
        {
            
                return CGPointMake(1,-1);
        }
            break;
        case EastCardinalDirection:
        {
            
                return CGPointMake(1,0);
        }
            break;
        case SouthEastCardinalDirection:
        {
            return CGPointMake(1,1);
            
        }
            break;
        case SouthCardinalDirection:
        {
            
                return CGPointMake(0,1);
        }
            break;
        case SouthWestCardinalDirection:
        {
            
                return CGPointMake(-1,1);
        }
            break;
        case WestCardinalDirection:
        {
            
                return CGPointMake(-1,0);
        }
            break;
            
        case NorthWestCardinalDirection:
        {
            
                return CGPointMake(-1,-1);
        }
            break;
            
        default:
        {
            
        }
            break;
    }
    
    NSLog(@"translate error");
        return CGPointZero;
}

-(CGPoint)translate
{
    if(moves)
        return [self translationPoint];
    return CGPointZero;
}

-(void)addDuration:(float)timeToAdd
{
    currentDuration+=timeToAdd;
}

-(void)addDistance:(long)distanceToAdd
{
    currentDistance+=distanceToAdd;
}

-(BOOL)checkComplete
{
    if(complete)
        return YES;
    if(targetDuration)
    {
        if(currentDuration>=targetDuration)
        {
            NSLog(@"checkComplete duration YES");
            return YES;
        }
        
            NSLog(@"checkComplete duration NO");
    }
    if(targetDistanceTraveled)
    {
        if(currentDistance<=targetDistanceTraveled)
        {
            //NSLog(@"checkComplete targetDistance YES: currentDistance:%ld targetDistance %f",currentDistance,targetDistance);
            return YES;
        }
        //NSLog(@"checkComplete targetDistance NO: currentDistance:%ld targetDistance %f",currentDistance,targetDistance);
    }
    if(targetIterations)
    {
        //NSLog(@"targetIterations");
        if(currentIterations>=targetIterations)
        {
            //NSLog(@"yup");
            return YES;
        }
    }
    
    return NO;
}

-(float)rotation
{
    if(!animationSequence)
        return 0;
    if(animationSequence->RotateLeft)
        return -90;
    else if(animationSequence->RotateRight)
        return 90;
    return 0;
}



-(BOOL)doesSequenceTypeMove:(enum AnimationSequenceType)type
{
    if(type==WalkNorthAnimationSequenceType)
        return YES;
    else if(type==WalkSouthAnimationSequenceType)
        return YES;
    else if(type==WalkEastAnimationSequenceType)
        return YES;
    else if(type==WalkWestAnimationSequenceType)
        return YES;
    else return NO;
    
}

// maybe take this out of action and make it a stand alone function?
-(enum BACardinalDirection)directionForAnimationSequenceType:(enum AnimationSequenceType)type
{
    enum BACardinalDirection theDirection=NorthCardinalDirection;
    switch (type) {
            
        //idle
        case IdleNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case IdleSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case IdleEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case IdleWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        //walk
        case WalkNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case WalkSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case WalkEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case WalkWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        //Attack 1h
        case AttackOneHandedNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case AttackOneHandedSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case AttackOneHandedEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case AttackOneHandedWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        //Attack 2h
        case AttackTwoHandedNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case AttackTwoHandedSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case AttackTwoHandedEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case AttackTwoHandedWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        //Special
            
        case PerformSpecialNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case PerformSpecialSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case PerformSpecialEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case PerformSpecialWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        //Bow
            
        case BowNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case BowSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case BowEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case BowWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        case BowRecoverNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case BowRecoverSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case BowRecoverEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case BowRecoverWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
        //Kneel
            
        case KneelNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case KneelSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case KneelEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case KneelWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
            
        case KneelRecoverNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case KneelRecoverSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case KneelRecoverEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case KneelRecoverWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
            break;
        //Sit
            
        case SitNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case SitSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case SitEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case SitWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
                break;
            
        case SitRecoverNorthAnimationSequenceType:
            theDirection=NorthCardinalDirection;
            break;
        case SitRecoverSouthAnimationSequenceType:
            theDirection=SouthCardinalDirection;
            break;
        case SitRecoverEastAnimationSequenceType:
            theDirection=EastCardinalDirection;
            break;
        case SitRecoverWestAnimationSequenceType:
            theDirection=WestCardinalDirection;
                break;
        default:
            break;
    }
    return theDirection;
}


-(enum AnimationSequenceType)AnimationSequenceTypeForState
{
    switch (type) {
        case NoActionType:
        {
            
        }
            break;
        case IdleActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return IdleNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return IdleSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return IdleEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return IdleWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case UserMoveActionType:
        case MoveActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return WalkNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return WalkSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return WalkEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return WalkWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case AttackActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return AttackOneHandedNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return AttackOneHandedSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return AttackOneHandedEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return AttackOneHandedWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case Attack2HActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return AttackTwoHandedNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return AttackTwoHandedSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return AttackTwoHandedEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return AttackTwoHandedWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
        case SitActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return SitNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return SitSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return SitEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return SitWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
            
        case  SitRecoveryActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return SitRecoverNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return SitRecoverSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return SitRecoverEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return SitRecoverWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case BowActionType:
        {
            
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return BowNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return BowSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return BowEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return BowWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
            
        }
            break;
        case BowRecoverActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return BowRecoverNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return BowRecoverSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return BowRecoverEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return BowRecoverWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case KneelActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return KneelNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return KneelSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return KneelEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return KneelWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case KneelRecoverActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return KneelRecoverNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return KneelRecoverSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return KneelRecoverEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return KneelRecoverWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
        case HarvestItemActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return AttackTwoHandedNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return AttackTwoHandedSouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return AttackTwoHandedEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return AttackTwoHandedWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
            break;
            
        case DeadActionType:
        {
            switch (direction) {
                case NorthCardinalDirection:
                case NorthEastCardinalDirection:
                case NorthWestCardinalDirection:
                    return LayNorthAnimationSequenceType;
                    break;
                case SouthCardinalDirection:
                case SouthEastCardinalDirection:
                case SouthWestCardinalDirection:
                    return LaySouthAnimationSequenceType;
                    break;
                case EastCardinalDirection:
                    return LayEastAnimationSequenceType;
                    break;
                case WestCardinalDirection:
                    return LayWestAnimationSequenceType;
                    break;
                default:
                    break;
            }
        }
       
            break;
        default:
            break;
    }
    return IdleNorthAnimationSequenceType;
}




@end
