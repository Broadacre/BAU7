//
//  BAActionManager.m
//  BAU7
//
//  Created by Dan Brooker on 9/23/21.
//
#import "Includes.h"
#import "BAActionManager.h"

@implementation ShortestPathStep

- (id)initWithPosition:(CGPoint)pos
{
    if ((self = [super init])) {
        position = pos;
        gScore = 0;
        hScore = 0;
        parent = nil;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@  pos=[%.0f;%.0f]  g=%d  h=%d  f=%d", [super description], position.x, position.y, gScore, hScore, [self fScore]];
}

- (BOOL)isEqual:(id)other
{
    if (![other isKindOfClass:[ShortestPathStep class]]) return NO;
    ShortestPathStep *otherStep = (ShortestPathStep *)other;
    return CGPointEqualToPoint(position, otherStep->position);
}

- (NSUInteger)hash
{
    // Create a unique hash from the position
    // Cast to integers first to ensure consistent hashing
    NSInteger x = (NSInteger)position.x;
    NSInteger y = (NSInteger)position.y;
    return (NSUInteger)((x * 73856093) ^ (y * 19349663));
}

- (int)fScore
{
    return gScore + hScore;
}

@end

@implementation BAActionSequence

-(id)init
{
    self=[super init];
    
    actions=[[NSMutableArray alloc]init];
    doesLoop=YES;
    complete=NO;
    currentActionIndex=0;
    return self;
}

-(void)clear
{
    [actions removeAllObjects];
    currentActionIndex=0;
}

-(void)update
{
    NSLog(@"update sequence");
    if(complete)
        return;
    BASpriteAction * action=[actions objectAtIndex:currentActionIndex];
    if(action)
    {
        if([action isComplete])
        {
            [self incrementIndex];
        }
    }
}


-(BASpriteAction *)firstAction
{
    return [actions objectAtIndex:0];
}


-(BASpriteAction *)lastAction
{
    return [actions lastObject];
}


-(BASpriteAction *)nextAction
{
    
    if(actions)
    {
        if(currentActionIndex+1>=[actions count])
        {
            if(doesLoop)
            {
            return [actions objectAtIndex:0];
            }
            return NULL;
        }
        return [actions objectAtIndex:currentActionIndex+1];
    }
    return NULL;
}

-(BASpriteAction *)popAction
{
    BASpriteAction * theAction=NULL;
    if(complete)
        return NULL;
    [self incrementIndex];
    theAction=[actions objectAtIndex:currentActionIndex];
    return theAction;
   
}


-(BASpriteAction *)currentAction
{
    if(complete)
        return NULL;
    return [self actionAtIndex:currentActionIndex];
}

-(void)incrementIndex
{
    if((currentActionIndex+1)>=[actions count])
        {
        if(doesLoop)
        {
            [self resetActions];  //should this go somewhere else?
            currentActionIndex=0;
        }
        else
            complete=YES;
        
        }
    else
        currentActionIndex++;
    
    
    //NSLog(@"index: %li",currentActionIndex);
}

-(void)addAction:(BASpriteAction *)theAction
{
    if(theAction&&actions)
        [actions addObject:theAction];
}

-(void)insertAction:(BASpriteAction *)theAction atIndex:(long)theIndex
{
    if(theAction&&actions)
        [actions insertObject:theAction atIndex:theIndex];
}
-(void)insertActionAtNextIndex:(BASpriteAction *)theAction
{
    if(theAction)
        [self insertAction:theAction atIndex:currentActionIndex+1];
}

-(BASpriteAction *)actionAtIndex:(long)index
{
    if(actions)
    {
        return [actions objectAtIndex:index];
    }
    return NULL;
}


-(long)count
{
    if(actions)
    {
        return [actions count];
    }
    return 0;
}



-(void)dump
{
    for(long index=0;index<[actions count];index++)
    {
        BASpriteAction * action=[actions objectAtIndex:index];
        [action dump];
    }
}

+(BAActionSequence*)ActionSequenceFromCGPointArray:(CGPointArray*)pointArray
{
    BAActionSequence * actionSequence=[[BAActionSequence alloc]init];
    if(pointArray)
    {
        for(long index=0;index<[pointArray count];index++)
        {
            BASpriteAction * action=[[BASpriteAction alloc]init];
            //init move action here
            [action setActionType:MoveActionType];
            [action setTargetLocation:[pointArray pointAtIndex:index]];
            [actionSequence addAction:action];
            
        }
    }
    return  actionSequence;
}


-(void)resetActions
{
    for(long index=0;index<[actions count];index++)
    {
        BASpriteAction * action=[actions objectAtIndex:index];
        [action reset];
    }
}

@end

#define MAX_ITERATIONS 100000

@implementation BAActionManager
-(id)init
{
    self=[super init];
    
    currentAction=[[BASpriteAction alloc]init];
    subAction=[[BASpriteAction alloc]init];
    //currentSequence=[[BAActionSequence alloc]init];
    currentSequence=[[BAActionSequence alloc]init];
    actionSequenceComplete=NO;
    targetGlobalLocation=CGPointMake(-1, -1);
    pointArrayIndex=0;
    maxIterations=MAX_ITERATIONS;
    
    // Initialize background pathfinding
    pathfindingQueue = dispatch_queue_create("com.bau7.pathfinding", DISPATCH_QUEUE_SERIAL);
    pathfindingInProgress = NO;
    pendingPath = nil;
    
    return self;
}

#pragma mark Setters
-(void)setActor:(BAActor*)theActor
{
    if(theActor)
    {
        actor=theActor;
        [self setShapeReference:theActor->shapeReference];
    }
}

-(void)setEnvironment:(U7Environment*)theEnvironment
{
    if(theEnvironment)
        environment=theEnvironment;
}
-(void)setMap:(U7Map*)theMap
{
    if(theMap)
    {
        map=theMap;
    }

}

-(void)setTargetLocation:(CGPoint)theLocation
{
    if([map isPassable:theLocation])
        targetGlobalLocation=theLocation;
    
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

-(void)setShapeReference:(U7ShapeReference *)theShapeReference
{
    //if(theShapeReference)
    //    shapeReference=theShapeReference;
}

-(void)setSequenceComplete:(BOOL)isComplete
{
    actionSequenceComplete=isComplete;
}


-(void)addActionToSequence:(BASpriteAction*)theAction
{
    if(!theAction)
        return;
    [currentSequence addAction:theAction];
}


-(void)setBounds:(CGRect)theBounds
{
    bounds=theBounds;
}


-(void)setActionSequence:(BAActionSequence*)theSequence
{
    if(theSequence)
    {
        currentSequence=theSequence;
        currentAction=[theSequence firstAction];
    }
}



-(void)setAction:(enum BAActionType)theActionType forDirection:(enum BACardinalDirection)theDirection forTarget:(CGPoint)target
{
    
    
    if(actionType==theActionType&&theDirection==[currentAction getDirection]&&CGPointEqualToPoint(target,[currentAction getTargetLocation]))
    {
        //NSLog(@"same");
        [currentAction setCurrentDistance:0];
        [currentAction setComplete:NO];
    }
    else
    {
        actionType=theActionType;
        [currentAction setTargetLocation:target];
        [currentAction reset];
        
        
        [currentAction setActionType:theActionType];
        [currentAction setDirection:theDirection];
        if(environment)
        {
            [currentAction setAnimationSequence:[environment sequenceForType:[currentAction AnimationSequenceTypeForState]]];
        }
        else
            NSLog(@"Bad environment");
    }
    
    
    
    
    if(!currentAction)
        NSLog(@"Bad Action");
    
    switch (theActionType) {
        case NoActionType:
        {
            
        }
            break;
        case IdleActionType:
        {
            
        }
            break;
        case MoveActionType:
        {
            //[currentAction setTargetDistance:arc4random_uniform(20)];
        //[currentAction setAnimationSequence:[environment sequenceForType:WalkNorthAnimationSequenceType]];
           
        }
            break;
        case AttackActionType:
        {
            
        }
            break;
        case SitActionType:
        {
            
        }
            break;
        case BowActionType:
        {
            
            
        }
            break;
        case BowRecoverActionType:
        {
            
            
        }
            break;
        case KneelActionType:
        {
            
        }
            break;
        case KneelRecoverActionType:
        {
            
        }
            break;
            
        default:
            break;
    }
    if(actor)
        actor->shapeReference->currentFrame=[currentAction frameID];
}

-(void)setCGPointArray:(CGPointArray*)thePointArray
{
    if(thePointArray)
        pointArray=thePointArray;
}

-(void)step
{
    //NSLog(@"AM Step");
    [self update];
   
}

-(void)update
{
    //if(currentSequence)
    //    [currentSequence update];
    [self updateAction];
    //[self updateActionSequence];
    [self updateCurrentAction];  //updateMoveAction
    //[currentAction dump];
    [currentAction step];
}



-(void)updateAction
{
    //NSLog(@"updateAction");
    if(currentAction)
    {
        //if(currentAction->type==PerformActionSequenceActionType)
        //{
        //    currentAction=[currentSequence firstAction];
        //}
        if([currentAction isComplete])
        {
            
            [self resetPath];
            //if(currentSequence)
            //    currentAction=[currentSequence currentAction];
            //else currentAction=NULL;
            currentAction=NULL;
            if(!currentAction)
                actionSequenceComplete=YES;
            [actor->aiManager setState:NoBAState];
        }
        else
            [actor->aiManager setState:ActionInProgressBAState];
    }
    else
        if([currentSequence count])
            currentAction=[currentSequence popAction];
}
/*
-(void)updateActionSequence
{
if(currentAction)
{
    if(currentAction->type==PerformActionSequenceActionType)
    {
        currentAction=[currentSequence firstAction];
    }
    if([currentAction isComplete])
        {
            NSLog(@"currentAction complete!");
            [self resetPath];
            currentAction=[currentSequence popAction];
           // [currentSequence incrementIndex];
            if(!currentAction)
            {
                NSLog(@"actionSequenceComplete!");
                actionSequenceComplete=YES;
            }
        }
}

    

}
*/
-(void)updateCurrentAction
{
    // NSLog(@"updateCurrentAction");
    if(!currentAction)
        return;
    
    switch ([currentAction getActionType]) {
        case NoActionType:
        {
            
        }
            break;
        case IdleActionType:
        {
            
            [self updateGeneralAction];
        }
            break;
        case MoveActionType:
        {
            //NSLog(@"move");
            [self updateMoveAction];
            
            
            
        }
            break;
        case AttackActionType:
        {
            
            [self updateAttackAction];
        }
            break;
        case Attack2HActionType:
        {
            
            [self updateGeneralAction];
        }
            break;
        case SitActionType:
        {
            
            [self updateGeneralAction];
        }
            break;
            
        case  SitRecoveryActionType:
        {
            [self updateGeneralAction];
        }
            break;
        case BowActionType:
        {
            
            [self updateGeneralAction];
            
        }
            break;
        case BowRecoverActionType:
        {
            
            [self updateGeneralAction];
        }
            break;
        case KneelActionType:
        {
            
            [self updateGeneralAction];
        }
            break;
        case KneelRecoverActionType:
        {
            
            [self updateGeneralAction];
        }
            break;
        case MoveOnPathActionType:
        {
            if(!currentAction)
            {
                NSLog(@"No action");
                //currentAction=[currentSequence nextAction];
            }
           if(![currentAction started])
           {
               //[self setupMoveToAction];
           }
            else
            {
                NSLog(@"move");
                //[currentAction dump];
            }
            
        }
            break;
        
        case PerformActionSequenceActionType:
        {
            if(!currentAction)
            {
                NSLog(@"No action");
                currentAction=[currentSequence nextAction];
            }
           if(![currentAction started])
           {
               //[self setupMoveToAction];
           }
            else
            {
                NSLog(@"move");
                //[currentAction dump];
            }
            
        }
            break;
        case HarvestItemActionType:
        {
            [self updateHarvestAction];
            break;
        }
        case MoveToSpriteActionType:
        {
            [self updateMoveToActorAction];
            break;
        }
        case DeadActionType:
        {
            [self updateGeneralAction];
            break;
        }
        case UserMoveActionType:
        {
            [self updateUserMoveAction];
            break;
        }
        default:
            break;
    }
}

-(void)updateGeneralAction
{
    // NSLog(@"updateBowAction");
     
     [currentAction setDirection:NorthCardinalDirection];
     enum AnimationSequenceType thetype=[currentAction AnimationSequenceTypeForState];
    // NSLog(@"AnimationSequenceType: %i",thetype);
     
     //[sequence dump];
    if(environment)
         {
        U7AnimationSequence * sequence=[environment sequenceForType:thetype];
        [currentAction setAnimationSequence:sequence];
         }
     float newRotation=[currentAction rotation];
    actor->shapeReference->eulerRotation=newRotation;
         if(actor)
             actor->shapeReference->currentFrame=[currentAction frameID];
}

-(void)updateHarvestAction
{
    
    //NSLog(@"harvest... iteration: %f",currentAction->currentIterations);
    enum BACardinalDirection direction=[self DirectionTowardPoint:actor->globalLocation toPoint:[currentAction getTargetLocation]];
    [currentAction setDirection:direction];
    
    enum AnimationSequenceType thetype=[currentAction AnimationSequenceTypeForState];
   // NSLog(@"AnimationSequenceType: %i",thetype);
    
    //[sequence dump];
        if(environment)
        {
            U7AnimationSequence * sequence=[environment sequenceForType:thetype];
            [currentAction setAnimationSequence:sequence];
        }
    float newRotation=[currentAction rotation];
   actor->shapeReference->eulerRotation=newRotation;
        if(actor)
            actor->shapeReference->currentFrame=[currentAction frameID];

   BASprite *targetSprite=[actor checkCGPointArrayForResource:actor->adjacentPoints forResource:TreeResourceType];
    if(!targetSprite)
    {
        [self clearAction];
    }
    else
    {
        if([currentAction getCurrentIterations]==[currentAction getTargetIterations]-1)
         {
             [map removeSpriteAtLocation:[currentAction getTargetLocation] forSprite:targetSprite];
         //[actor addObjectToInventory:targetSprite atLocation:targetSprite->globalLocation];
         }
    }
   
    //currentAction->currentIterations++;
}

-(void)updateAttackAction
{
    
    //NSLog(@"harvest... iteration: %f",currentAction->currentIterations);
    enum BACardinalDirection direction=[self DirectionTowardPoint:actor->globalLocation toPoint:[currentAction getTargetLocation]];
    [currentAction setDirection:direction];
    
    enum AnimationSequenceType thetype=[currentAction AnimationSequenceTypeForState];
   // NSLog(@"AnimationSequenceType: %i",thetype);
    
    //[sequence dump];
        if(environment)
        {
            U7AnimationSequence * sequence=[environment sequenceForType:thetype];
            [currentAction setAnimationSequence:sequence];
        }
    float newRotation=[currentAction rotation];
   actor->shapeReference->eulerRotation=newRotation;
        if(actor)
            actor->shapeReference->currentFrame=[currentAction frameID];

   //BASprite *targetSprite=[actor checkCGPointArrayForResource:actor->adjacentPoints forResource:TreeResourceType];
    BAActor *targetActor=[actor checkCGPointArrayForActor:actor->adjacentPoints forActor:NoActorBAActorType];
    if(![self isValidTargetActor:targetActor])
    {
        [self clearAction];
    }
    else
    {
        if([currentAction getCurrentIterations]==[currentAction getTargetIterations]-1)
         {
             NSLog(@"Attack");
             
             targetActor->HP--;
             //[map removeSpriteAtLocation:[currentAction getTargetLocation] forSprite:targetSprite];
         //[actor addObjectToInventory:targetSprite atLocation:targetSprite->globalLocation];
         }
    }
   
    //currentAction->currentIterations++;
}

-(void)updateUserMoveAction
{
    // NSLog(@"updateMoveAction");
     //build path if necessary
    
     //move along path
     
    enum BACardinalDirection direction=[currentAction getDirection];
    long newLocationX=[actor getGlobalLocation].x+[currentAction translationPoint].x;
    long newLocationY=[actor getGlobalLocation].y+[currentAction translationPoint].y;
    CGPoint newLocation=CGPointMake(newLocationX,newLocationY);
     
     if([map isPassable:newLocation])
         {

         [actor setGlobalLocation:newLocation];
        if(environment)
             {
                 [currentAction setAnimationSequence:[environment sequenceForType:[currentAction AnimationSequenceTypeForState]]];
             }
         float newRotation=[currentAction rotation];
             actor->shapeReference->eulerRotation=newRotation;
             if(actor)
                 actor->shapeReference->currentFrame=[currentAction frameID];
             
         //[currentAction addDistance:1];
         
         }
     else
         {
         [self clearAction];
         }
          
}

-(void)updateMoveAction
{
   // NSLog(@"updateMoveAction");
    //build path if necessary
    if(!buildPathComplete)
    {
        // Check if we're already calculating a path
        if (pathfindingInProgress) {
            return; // Wait for path calculation to complete
        }
        
        CGPoint newTarget=[currentAction getTargetLocation];
        //logPoint(newTarget, @"New Target");
        newTarget=CGPointMake(newTarget.x, newTarget.y);
        if([map isPassable:newTarget])
        {
            [self setTargetLocation:newTarget];
            [self resetPath];
            
            // Use async pathfinding instead of blocking call
            CGPoint tile=[map nearestPassableAdjacentTile:newTarget from:[actor getGlobalLocation]];
            if(validLocation(tile))
            {
                [self buildPathAsync:tile];
            }
            //NSLog(@"%li steps",[shortestPath count]);
        }
        else
        {
            [self clearAction];
        }
        return; // Wait for async path to complete
    }
    //move along path
    if([actor isAdjacent:targetGlobalLocation])
           {
           
            BASprite *targetSprite=[actor checkCGPointArrayForResource:actor->adjacentPoints forResource:StoneResourceType];
            if(targetSprite)
            {
                //NSLog(@"Target Found");
                [actor addObjectToInventory:targetSprite atLocation:targetSprite->globalLocation];
                
            }
            [self clearAction];
           }
    else if([shortestPath count])
                {
                ShortestPathStep *s = [shortestPath objectAtIndex:0];
                if([map isPassable:s->position])
                    {

                    //[mapView moveSprite:sprite toPosition:s->position];
                    enum BACardinalDirection direction=[self DirectionTowardPoint:[actor getGlobalLocation] toPoint:s->position];
                    
                    [actor setGlobalLocation:s->position];
                        
                    
                    [currentAction setDirection:direction];
                        if(environment)
                        {
                            [currentAction setAnimationSequence:[environment sequenceForType:[currentAction AnimationSequenceTypeForState]]];
                        }
                    float newRotation=[currentAction rotation];
                        actor->shapeReference->eulerRotation=newRotation;
                        if(actor)
                            actor->shapeReference->currentFrame=[currentAction frameID];
                        
                    [currentAction addDistance:1];
                    
                    //[currentAction setTargetDistance:1];
                    [shortestPath removeObjectAtIndex:0];
                    }
                else
                    {
                    //NSLog(@"Adding to do not target");
                    [doNotTargetList addObject:targetSprite];
                    [self clearAction];
                    //type=WanderAIType;
                    }
                }
        else
        {
            [self clearAction];
        }
        
    
}

-(void)clearAction
{
    [currentAction setComplete:YES];
    targetGlobalLocation=invalidLocation();
    targetActor=NULL;
    return;
}

-(BOOL)isValidTargetActor:(BAActor*)theActor
{
    if(!theActor)
        return NO;
    if(theActor->dead)
        return NO;
    
    return YES;
}

-(void)updateMoveToActorAction
{
   // NSLog(@"updateMoveAction");
    //build path if necessary
    [self setTargetActor:[currentAction getTargetActor]];
    if(![self isValidTargetActor:targetActor])
    {
        [self clearAction];
        return;
    }
    
    targetGlobalLocation=targetActor->globalLocation;
    //if(!targetSprite)
    //    return;
    
    if(!buildPathComplete||targetActor->moved)
    {
        // Check if we're already calculating a path
        if (pathfindingInProgress) {
            return; // Wait for path calculation to complete
        }
        
        if(targetActor)
        {
            if(targetActor->moved)
                NSLog(@"moved");
            else
                NSLog(@"did not move");
        }
        
        CGPoint newTarget=[targetActor getGlobalLocation];
        //logPoint(newTarget, @"New Target");
        newTarget=CGPointMake(newTarget.x, newTarget.y);
        if([map isPassable:newTarget])
        {
            [self setTargetLocation:newTarget];
            [self resetPath];
            
            // Use async pathfinding instead of blocking call
            CGPoint tile=[map nearestPassableAdjacentTile:newTarget from:[actor getGlobalLocation]];
            if(validLocation(tile))
            {
                [self buildPathAsync:tile];
            }
            //NSLog(@"%li steps",[shortestPath count]);
        }
        else
        {
            [self clearAction];
            return;
        }
        return; // Wait for async path to complete
    }
    //move along path
    if([actor isAdjacent:targetGlobalLocation])
           {
           
            //BAActor *targetActor=[actor checkCGPointArrayForActor:actor->adjacentPoints forActor:NoActorBAActorType];
            if([self isValidTargetActor:targetActor])
            {
                //NSLog(@"Target Found");
                //[actor addObjectToInventory:targetSprite atLocation:targetSprite->globalLocation];
               // NSLog(@"Attack!");
                //targetActor->HP--;
            }
               [self clearAction];
               return;
           }
    else if([shortestPath count])
                {
                ShortestPathStep *s = [shortestPath objectAtIndex:0];
                if([map isPassable:s->position])
                    {

                    //[mapView moveSprite:sprite toPosition:s->position];
                    enum BACardinalDirection direction=[self DirectionTowardPoint:[actor getGlobalLocation] toPoint:s->position];
                    
                    [actor setGlobalLocation:s->position];
                        
                    
                    [currentAction setDirection:direction];
                        if(environment)
                        {
                            [currentAction setAnimationSequence:[environment sequenceForType:[currentAction AnimationSequenceTypeForState]]];
                        }
                    float newRotation=[currentAction rotation];
                        actor->shapeReference->eulerRotation=newRotation;
                        if(actor)
                            actor->shapeReference->currentFrame=[currentAction frameID];
                        
                    [currentAction addDistance:1];
                    
                    //[currentAction setTargetDistance:1];
                    [shortestPath removeObjectAtIndex:0];
                    }
                else
                    {
                    [self clearAction];
                        return;
                    }
                }
        else
        {
            [self clearAction];
            return;
            //NSLog(@"help!");
        }
        
    
}


-(enum AnimationSequenceType)randomWalkDirection
    {
        int randomNumber=arc4random_uniform(4);
        switch (randomNumber) {
            case 0:
                return WalkNorthAnimationSequenceType;
                break;
            case 1:
                return WalkSouthAnimationSequenceType;
                break;
            case 2:
                return WalkEastAnimationSequenceType;
                break;
            case 3:
                return WalkWestAnimationSequenceType;
                break;
                
            default:
                break;
        }
        
        return WalkWestAnimationSequenceType;
    }

-(enum BACardinalDirection)randomDirection
    {
        int randomNumber=arc4random_uniform(8);
        switch (randomNumber) {
            case 0:
                return NorthCardinalDirection;
                break;
            case 1:
                return NorthEastCardinalDirection;
                break;
            case 2:
                return EastCardinalDirection;
                break;
            case 3:
                return SouthEastCardinalDirection;
                break;
            case 4:
                return SouthCardinalDirection;
                break;
            case 5:
                return SouthWestCardinalDirection;
                break;
            case 6:
                return WestCardinalDirection;
                break;
            case 7:
                return NorthWestCardinalDirection;
                break;
                
            default:
                break;
        }
        
        return NorthWestCardinalDirection;
    }

/* */
-(CGPoint)randomPointInBounds
{
    int randomX=arc4random_uniform(bounds.size.width-2)+1;
    int randomY=arc4random_uniform(bounds.size.height-2)+1;
    //NSLog(@"randomPointInBounds: bounds size: %f,%f bounds origin: %f,%f randomPoint: %i,%i",bounds.size.width,bounds.size.height,bounds.origin.x,bounds.origin.y,randomX,randomY);
    return CGPointMake(bounds.origin.x+randomX, bounds.origin.y+randomY);
}

-(CGPoint)randomPointInDefinedBounds:(CGRect)theBounds
{
    int randomX=arc4random_uniform(theBounds.size.width-2)+1;
    int randomY=arc4random_uniform(theBounds.size.height-2)+1;
    //NSLog(@"randomPointInDefinedBounds: bounds size: %f,%f bounds origin: %f,%f randomPoint: %f,%f",theBounds.size.width,theBounds.size.height,theBounds.origin.x,theBounds.origin.y,theBounds.origin.x+randomX,theBounds.origin.y+randomY);
    return CGPointMake(theBounds.origin.x+randomX, theBounds.origin.y+randomY);
}


-(enum BACardinalDirection)DirectionTowardPoint:(CGPoint)startPoint toPoint:(CGPoint)destinationPoint
{
    if(destinationPoint.x>startPoint.x&&destinationPoint.y>startPoint.y)
    {
        return SouthEastCardinalDirection;
    }
    else if(destinationPoint.x>startPoint.x&&destinationPoint.y<startPoint.y)
    {
        return NorthEastCardinalDirection;
    }
    else if(destinationPoint.x>startPoint.x&&destinationPoint.y==startPoint.y)
    {
        return EastCardinalDirection;
    }
    else if(destinationPoint.x==startPoint.x&&destinationPoint.y>startPoint.y)
    {
        return SouthCardinalDirection;
    }
    else if(destinationPoint.x==startPoint.x&&destinationPoint.y<startPoint.y)
    {
        return NorthCardinalDirection;
    }
    else if(destinationPoint.x<startPoint.x&&destinationPoint.y>startPoint.y)
    {
        return SouthWestCardinalDirection;
    }
    else if(destinationPoint.x<startPoint.x&&destinationPoint.y==startPoint.y)
    {
        return WestCardinalDirection;
    }
    else if(destinationPoint.x<startPoint.x&&destinationPoint.y<startPoint.y)
    {
        return NorthWestCardinalDirection;
    }
    return NorthCardinalDirection;
}

#pragma -mark A*

-(void)buidPathToAdjacent:(CGPoint)target
{
    /**/
    
    //NSLog(@"buidPathToAdjacent from %f %f to %f %f",[sprite getGlobalLocation].x,[sprite getGlobalLocation].y,target.x,target.y);
    CGPoint tile=[map nearestPassableAdjacentTile:target from:[actor getGlobalLocation]];
    if(validLocation(tile))
        [self buildPath:tile];
     
}
-(void)resetPath
{
    spOpenSteps=nil;
    spClosedSteps=nil;
    shortestPath=nil;
    buildPathComplete=NO;

}

- (void)buildPath:(CGPoint)target
{
    //NSLog(@"buildPath");
  
    long iterations=0;
    // Init shortest path properties
    spOpenSteps = [NSMutableArray array];
    NSMutableSet *closedSet = [NSMutableSet set];  // O(1) lookups
    NSMutableDictionary *openDict = [NSMutableDictionary dictionary];  // O(1) lookups for open list
    shortestPath = nil;
    
    // Get current tile coordinate and desired tile coord
    CGPoint fromTileCoor = [actor getGlobalLocation];
    CGPoint toTileCoord = target;
    //NSLog(@"A* Path from %f,%f to %f, %f",fromTileCoor.x,fromTileCoor.y,toTileCoord.x,toTileCoord.y);
    // Check that there is a path to compute ;-)
    
    if (CGPointEqualToPoint(fromTileCoor, toTileCoord)) {
        //NSLog(@"Same Spot!");
        return;
    }
    // Must check that the desired location is walkable
    if (![map isPassable:toTileCoord] ) {
        
        //NSLog(@"Not Passable!");
        //currentPlayedEffect = [[SimpleAudioEngine sharedEngine] playEffect:@"hitWall.wav"];
        return;
    }
    
    // Helper block to create consistent string keys from points
    NSString *(^keyForPoint)(CGPoint) = ^NSString *(CGPoint pt) {
        return [NSString stringWithFormat:@"%.0f,%.0f", pt.x, pt.y];
    };
    
    // Start by adding the from position to the open list
    ShortestPathStep *startStep = [[ShortestPathStep alloc] initWithPosition:fromTileCoor];
    [self insertInOpenSteps:startStep];
    openDict[keyForPoint(fromTileCoor)] = startStep;
    
    do {
        // Get the lowest F cost step
        // Because the list is ordered, the first step is always the one with the lowest F cost
        ShortestPathStep *currentStep = [spOpenSteps objectAtIndex:0];

        // Add the current step to the closed set
        [closedSet addObject:currentStep];

        // Remove it from the open list
        [openDict removeObjectForKey:keyForPoint(currentStep->position)];
        [spOpenSteps removeObjectAtIndex:0];
        
        // If the currentStep is at the desired tile coordinate, we have done
        if (CGPointEqualToPoint(currentStep->position, toTileCoord))
        {
            [self constructPathAndStartAnimationFromStep:currentStep];
            spOpenSteps = nil; // Set to nil to release unused memory
            break;
        }
        
        // Get the adjacent tiles coord of the current step
        NSArray *adjSteps = [map walkableAdjacentTilesCoordForTileCoord:currentStep->position];
        //NSLog(@"adjacent steps: %li",[adjSteps count]);
        for (NSValue *v in adjSteps) {
            
            CGPoint adjPosition = [v CGPointValue];
            ShortestPathStep *step = [[ShortestPathStep alloc] initWithPosition:adjPosition];
            
            // Check if the step isn't already in the closed set - O(1) lookup
            if ([closedSet containsObject:step]) {
                continue; // Ignore it
            }
            
            // Compute the cost from the current step to that step
            int moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            
            // Check if the step is already in the open list - O(1) lookup
            NSString *stepKey = keyForPoint(adjPosition);
            ShortestPathStep *existingStep = openDict[stepKey];
            
            if (existingStep == nil) { // Not on the open list, so add it
                
                // Set the current step as the parent
                step->parent = currentStep;

                // The G score is equal to the parent G score + the cost to move from the parent to it
                step->gScore = currentStep->gScore + moveCost;
                
                // Compute the H score which is the estimated movement cost to move from that step to the desired tile coordinate
                step->hScore = [self computeHScoreFromCoord:step->position toCoord:toTileCoord];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertInOpenSteps:step];
                openDict[stepKey] = step;
            }
            else { // Already in the open list
                
                // Check to see if the G score for that step is lower if we use the current step to get there
                if ((currentStep->gScore + moveCost) < existingStep->gScore) {
                    
                    // The G score is equal to the parent G score + the cost to move from the parent to it
                    existingStep->gScore = currentStep->gScore + moveCost;
                    existingStep->parent = currentStep;
                    
                    // Because the G Score has changed, the F score may have changed too
                    // So to keep the open list ordered we have to remove the step, and re-insert it
                    NSUInteger index = [spOpenSteps indexOfObject:existingStep];
                    if (index != NSNotFound) {
                        [spOpenSteps removeObjectAtIndex:index];
                        [self insertInOpenSteps:existingStep];
                    }
                }
            }
        }
        iterations++;
    } while (([spOpenSteps count] > 0)&&iterations<maxIterations);
    //while (([spOpenSteps count] > 0));
    if(iterations>=maxIterations)
    {
        //NSLog(@"A* maxIterations!");
        shortestPath=nil;
    }
    else
    {
        //NSLog(@"pathsize: %li iterations: %li",[shortestPath count],iterations);
    }
    if (shortestPath == nil) { // No path found
        //currentPlayedEffect = [[SimpleAudioEngine sharedEngine] playEffect:@"hitWall.wav"];
        //NSLog(@"No Path");
    }
    //else NSLog(@"numberOfSteps: %li",[shortestPath count]);
}


// Insert a path step (ShortestPathStep) in the ordered open steps list (spOpenSteps)
- (void)insertInOpenSteps:(ShortestPathStep *)step
{
    int stepFScore = [step fScore]; // Compute only once the step F score's
    long count = [spOpenSteps count];
    int i = 0; // It will be the index at which we will insert the step
    for (; i < count; i++) {
        if (stepFScore <= [[spOpenSteps objectAtIndex:i] fScore]) { // if the step F score's is lower or equals to the step at index i
            // Then we found the index at which we have to insert the new step
            break;
        }
    }
    // Insert the new step at the good index to preserve the F score ordering
    [spOpenSteps insertObject:step atIndex:i];
}

// Compute the H score from a position to another (from the current position to the final desired position
- (int)computeHScoreFromCoord:(CGPoint)fromCoord toCoord:(CGPoint)toCoord
{
    // Here we use the Manhattan method, which calculates the total number of step moved horizontally and vertically to reach the
    // final desired step from the current step, ignoring any obstacles that may be in the way
    int value=abs(toCoord.x - fromCoord.x) + abs(toCoord.y - fromCoord.y);
    //int value=simpleDistance(toCoord, fromCoord);
    //float fvalue=sqrtf( ((fromCoord.x-toCoord.x)*(fromCoord.x-toCoord.x))+
    //                   ((fromCoord.y-toCoord.y)*(fromCoord.y-toCoord.y))
                       
    //                   );
    //int value=fvalue;
    //NSLog(@"value %i",value);
    return value;
}

// Compute the cost of moving from a step to an adjecent one
- (int)costToMoveFromStep:(ShortestPathStep *)fromStep toAdjacentStep:(ShortestPathStep *)toStep
{
    return ((fromStep->position.x != toStep->position.x) && (fromStep->position.y != toStep->position.y)) ? 14 : 10;
}


// Go backward from a step (the final one) to reconstruct the shortest computed path
- (void)constructPathAndStartAnimationFromStep:(ShortestPathStep *)step
{
    shortestPath = [NSMutableArray array];
    
    do {
        if (step->parent != nil) { // Don't add the last step which is the start position (remember we go backward, so the last one is the origin position ;-)
            [shortestPath insertObject:step atIndex:0]; // Always insert at index 0 to reverse the path
        }
        step = step->parent; // Go backward
    } while (step != nil); // Until there is not more parent
    
    // Call the popStepAndAnimate to initiate the animations
    //[self popStepAndAnimate];
}

#pragma mark - Async Pathfinding

// Build path on background thread
- (void)buildPathAsync:(CGPoint)target
{
    if (pathfindingInProgress) {
        return; // Already calculating a path
    }
    
    pathfindingInProgress = YES;
    
    // Capture values needed for pathfinding
    CGPoint fromLocation = [actor getGlobalLocation];
    U7Map *mapRef = map;
    
    dispatch_async(pathfindingQueue, ^{
        // Perform A* on background thread
        NSMutableArray *calculatedPath = [self calculatePathFrom:fromLocation to:target withMap:mapRef];
        
        // Return to main thread to apply the path
        dispatch_async(dispatch_get_main_queue(), ^{
            if (calculatedPath) {
                self->pendingPath = calculatedPath;
                self->shortestPath = calculatedPath;
                self->buildPathComplete = YES;
            }
            self->pathfindingInProgress = NO;
        });
    });
}

// Thread-safe path calculation (doesn't modify instance variables directly)
- (NSMutableArray *)calculatePathFrom:(CGPoint)fromTileCoor to:(CGPoint)toTileCoord withMap:(U7Map *)mapRef
{
    long iterations = 0;
    NSMutableArray *openSteps = [NSMutableArray array];
    NSMutableSet *closedSet = [NSMutableSet set];
    NSMutableDictionary *openDict = [NSMutableDictionary dictionary];
    NSMutableArray *resultPath = nil;
    
    if (CGPointEqualToPoint(fromTileCoor, toTileCoord)) {
        return nil;
    }
    
    if (![mapRef isPassable:toTileCoord]) {
        return nil;
    }
    
    NSString *(^keyForPoint)(CGPoint) = ^NSString *(CGPoint pt) {
        return [NSString stringWithFormat:@"%.0f,%.0f", pt.x, pt.y];
    };
    
    ShortestPathStep *startStep = [[ShortestPathStep alloc] initWithPosition:fromTileCoor];
    [self insertStep:startStep inOpenSteps:openSteps];
    openDict[keyForPoint(fromTileCoor)] = startStep;
    
    do {
        ShortestPathStep *currentStep = [openSteps objectAtIndex:0];
        [closedSet addObject:currentStep];
        [openDict removeObjectForKey:keyForPoint(currentStep->position)];
        [openSteps removeObjectAtIndex:0];
        
        if (CGPointEqualToPoint(currentStep->position, toTileCoord)) {
            resultPath = [self constructPathFromStep:currentStep];
            break;
        }
        
        NSArray *adjSteps = [mapRef walkableAdjacentTilesCoordForTileCoord:currentStep->position];
        
        for (NSValue *v in adjSteps) {
            CGPoint adjPosition = [v CGPointValue];
            ShortestPathStep *step = [[ShortestPathStep alloc] initWithPosition:adjPosition];
            
            if ([closedSet containsObject:step]) {
                continue;
            }
            
            int moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            NSString *stepKey = keyForPoint(adjPosition);
            ShortestPathStep *existingStep = openDict[stepKey];
            
            if (existingStep == nil) {
                step->parent = currentStep;
                step->gScore = currentStep->gScore + moveCost;
                step->hScore = [self computeHScoreFromCoord:step->position toCoord:toTileCoord];
                [self insertStep:step inOpenSteps:openSteps];
                openDict[stepKey] = step;
            } else {
                if ((currentStep->gScore + moveCost) < existingStep->gScore) {
                    existingStep->gScore = currentStep->gScore + moveCost;
                    existingStep->parent = currentStep;
                    
                    NSUInteger index = [openSteps indexOfObject:existingStep];
                    if (index != NSNotFound) {
                        [openSteps removeObjectAtIndex:index];
                        [self insertStep:existingStep inOpenSteps:openSteps];
                    }
                }
            }
        }
        iterations++;
    } while (([openSteps count] > 0) && iterations < maxIterations);
    
    return resultPath;
}

// Thread-safe insert into open steps
- (void)insertStep:(ShortestPathStep *)step inOpenSteps:(NSMutableArray *)openSteps
{
    int stepFScore = [step fScore];
    long count = [openSteps count];
    int i = 0;
    
    for (; i < count; i++) {
        if (stepFScore <= [[openSteps objectAtIndex:i] fScore]) {
            break;
        }
    }
    [openSteps insertObject:step atIndex:i];
}

// Thread-safe path reconstruction
- (NSMutableArray *)constructPathFromStep:(ShortestPathStep *)step
{
    NSMutableArray *path = [NSMutableArray array];
    
    do {
        if (step->parent != nil) {
            [path insertObject:step atIndex:0];
        }
        step = step->parent;
    } while (step != nil);
    
    return path;
}

// Check if pathfinding is currently in progress
- (BOOL)isPathfindingInProgress
{
    return pathfindingInProgress;
}






@end
