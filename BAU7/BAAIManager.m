//
//  BAAIManager.m
//  BAU7
//
//  Created by Dan Brooker on 4/22/22.
//
#import "Includes.h"
#import "BAActionManager.h"
#import "BAAIManager.h"


@implementation BAStateManager

-(id)init
{
    self=[super init];
    hunger=0;
    thirst=0;
    tired=0;
    fear=0;
    cold=0;
    heat=0;
    anger=0;
    dead=NO;
    
    currentState=NoBAState;
    return self;
}

-(void)step
{
    hunger++;
    thirst++;
    [self determineState];
    //[self dump];
    
}
-(void)dump
{
    NSLog(@"StateManager Dump");
    NSLog(@"hunger: %li",hunger);
    NSLog(@"thirst: %li",thirst);
    NSLog(@"tired: %li",tired);
    NSLog(@"fear: %li",fear);
    NSLog(@"cold: %li",cold);
    NSLog(@"heat: %li",heat);
}

-(void)determineState
{
    if(dead)
    {
        currentState=DeadBAState;
        return;
    }
    else if(currentState==ActionInProgressBAState)
    {
        //NSLog(@"state:%u in progress",currentState);
       
    }
    else
    {
        //NSLog(@"state:%u let's wander",currentState);
        //currentState=RandomWanderBAState;
        currentState=AttackLikeAManiacBAState;
    }
    
    if(!(hunger%100))
    {
        //NSLog(@"hunger: %li",hunger);
        //currentState=RandomWanderBAState;
        //bow
        
        //BAActionSequence * actionSequence=actionManager->currentSequence;
        //[actionSequence insertActionAtNextIndex:actionTwo];
    
    }
    //else
    //    currentState=NoBAState;
}


-(enum BAState)getCurrentState
{
    return currentState;
}


-(void)setState:(enum BAState)theState
{
    currentState=theState;
}


-(void)setDead:(BOOL)isDead
{
    dead=isDead;
}

@end


@implementation AIManager

-(id)init
{
    self=[super init];
    actionManager=[[BAActionManager alloc]init];
    stateManager=[[BAStateManager alloc]init];
    
    resourceSprites=[[BASpriteArray alloc]init];
    threatSprites=[[BASpriteArray alloc]init];
    
    desiredResourceType=TreeResourceType;
    AIEnabled=YES;
    
    userAction=NULL;
    
    return self;
}

-(void)setActor:(BAActor*)theActor
{
    if(theActor)
    {
        actor=theActor;
    if(actionManager)
        [actionManager setActor:theActor];
    }
    
}

-(void)setState:(enum BAState)theState
{
    [stateManager setState:theState];
}

-(void)step
{
    [self doAI];
    [stateManager step];
    [actionManager step];
}

-(void)doAI
{
    
    //observe
    [self observe];
    //- look at map
    // -- threats
     //-- booty
   
    
   //CGPoint * point=[actor->map nea]
    
    //orient
    [self orient];
    
    
     
    
    /* - player needs
     -- hunger
     -- thirst
     -- sleep
     -- health
     
     - strategic long term goals
     --career
     --family
     --leisure
     
     
     **DO WE SCORE EACH?  WHAT ARE WEIGHTS?
     
     */
    

    
    //decide
    //should action change
    //weighted decision
    [self decide];
    
    
    
    //act
    //update action or leave current
    
    [self act];
    
}



-(void)observe
{
    [resourceSprites clear];
    [threatSprites clear];
    if(actor->HP<=0)
    {
        actor->dead=YES;
        [stateManager setDead:YES];
        return;
    }
   
    
    surroundingTiles=pointsSurroundingCGPoint(actor->globalLocation,10,NO);
    BASprite * sprite=[actor checkCGPointArrayForResource:surroundingTiles forResource:desiredResourceType];
    if(sprite)
        [resourceSprites addSprite:sprite];
    BAActor * threat=[actor checkCGPointArrayForActor:surroundingTiles forActor:NoActorBAActorType];
    if(threat)
    {
        [threatSprites addSprite:threat];
        //NSLog(@"hit");
    }
    //else
        //NSLog(@"Missss");
    
}

-(void)orient
{
    
}

-(void)decide
{
    
    currentState=[stateManager getCurrentState];
}


-(void)act
{
    static long var=0;
    if(!AIEnabled)
    {
        
        if(!userAction)
        {
            //do nothing
            //NSLog(@"No Action");
        }
        else
        {
            if([userAction checkComplete])
            {
                NSLog(@"complete!");
                userAction=NULL;
            }
            else
            {
                actionManager->currentAction=userAction;
            }
        }
        
    
        return;
    }
    switch (currentState) {
        case FindFoodBAState:
        {
            NSLog(@"Find Food!");
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:SitRecoveryActionType];
            [action setTargetIterations:30];
            actionManager->currentAction=action;
        }
            break;
        case FindWoodBAState:
        {
           
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:MoveActionType];
            if([resourceSprites count])
           {
               BASprite * resourceSprite=[resourceSprites nearestSpriteWithType:ResourceBASpriteType fromLocation:actor->globalLocation];
               if(resourceSprite)
               {
                   action=[[BASpriteAction alloc]init];
                   
                   [action setActionType:MoveActionType];
                   [action setTargetLocation:resourceSprite->globalLocation];
                   
                   [actionManager addActionToSequence:action];
                   
                   action=[[BASpriteAction alloc]init];
                   [action setActionType:HarvestItemActionType];
                   [action setTargetLocation:resourceSprite->globalLocation];
                   [action setTargetIterations:50];
                   [actionManager addActionToSequence:action];
                   
               }
               
           }
            else
            {
                CGRect targetRect=CGRectMake(actor->globalLocation.x-10, actor->globalLocation.y-10, 20, 20);
                //var++;
                //NSLog(@"Var: %li",var);
                //logPoint(actor->globalLocation, @"Actor:");
                //logRect(targetRect, @"TargetRect");
                CGPoint randomPoint=randomCGPointInRect(targetRect);
                var=(randomPoint.x-actor->globalLocation.x);
                //NSLog(@"Var: %li",var);
                
                
                [action setTargetLocation:randomPoint];
                [actionManager addActionToSequence:action];
            }
            
           
            
            break;
            
        }
        case AttackLikeAManiacBAState:
        {
           
            
            //
            if([threatSprites count])
           {
               //NSLog(@"Yes");
               BAActor * threatActor=[threatSprites nearestActorWithType:NoActorBAActorType fromLocation:actor->globalLocation];
               if(threatActor&&(threatActor->dead==NO))
               {
                   BASpriteAction * action=[[BASpriteAction alloc]init];
                   
                   [action setActionType:MoveToSpriteActionType];
                   //[action setTargetLocation:threatSprite->globalLocation];
                   [action setTargetActor:threatActor];
                   [actionManager addActionToSequence:action];
                   
                   action=[[BASpriteAction alloc]init];
                   [action setActionType:AttackActionType];
                   [action setTargetLocation:threatActor->globalLocation];
                   [action setTargetIterations:1];
                   [actionManager addActionToSequence:action];
                   
               }
               
           }
            else
            {
                //NSLog(@"No");
                BASpriteAction * action=[[BASpriteAction alloc]init];
                [action setActionType:MoveActionType];
                CGRect targetRect=CGRectMake(actor->globalLocation.x-10, actor->globalLocation.y-10, 20, 20);
                //var++;
                //NSLog(@"Var: %li",var);
                //logPoint(actor->globalLocation, @"Actor:");
                //logRect(targetRect, @"TargetRect");
                CGPoint randomPoint=randomCGPointInRect(targetRect);
                var=(randomPoint.x-actor->globalLocation.x);
                //NSLog(@"Var: %li",var);
                
                
                [action setTargetLocation:randomPoint];
                [actionManager addActionToSequence:action];
            }
            
           
            
            break;
            
        }
        case RandomWanderBAState:
        {
            BASpriteAction * action=[[BASpriteAction alloc]init];
            
            [action setActionType:MoveActionType];
            
            
            //NSLog(@"old");
            //[surroundingTiles dump];
            //surroundingTiles=sortPathByDistance(surroundingTiles, actor->globalLocation);
            //NSLog(@"new");
            //[surroundingTiles dump];
           // BASprite * sprite=[actor checkCGPointArrayForResource:surroundingTiles forResource:StoneResourceType];
            BASprite * resourceSprite=[resourceSprites nearestSpriteWithType:ResourceBASpriteType fromLocation:actor->globalLocation];
            if(resourceSprite)
            {
                [action setTargetLocation:resourceSprite->globalLocation];
            }
            else
            {
                CGRect targetRect=CGRectMake(actor->globalLocation.x-10, actor->globalLocation.y-10, 20, 20);
                //var++;
                //NSLog(@"Var: %li",var);
                //logPoint(actor->globalLocation, @"Actor:");
                //logRect(targetRect, @"TargetRect");
                CGPoint randomPoint=randomCGPointInRect(targetRect);
                var=(randomPoint.x-actor->globalLocation.x);
                //NSLog(@"Var: %li",var);
                
                
                [action setTargetLocation:randomPoint];
            }
            
           
            actionManager->currentAction=action;
        }
            break;
        case DeadBAState:
        {
            NSLog(@"Dead!");
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:DeadActionType];
            //[action setTargetIterations:30];
            actionManager->currentAction=action;
        }
            break;
        case UserControlBAState:
        {
            BASpriteAction * action=[[BASpriteAction alloc]init];
            
            [action setActionType:UserMoveActionType];
           
            
            {
                CGRect targetRect=CGRectMake(actor->globalLocation.x-10, actor->globalLocation.y-10, 20, 20);
                //var++;
                //NSLog(@"Var: %li",var);
                //logPoint(actor->globalLocation, @"Actor:");
                //logRect(targetRect, @"TargetRect");
                CGPoint randomPoint=randomCGPointInRect(targetRect);
                var=(randomPoint.x-actor->globalLocation.x);
                //NSLog(@"Var: %li",var);
                
                
                [action setTargetLocation:randomPoint];
            }
            
           
            actionManager->currentAction=action;
        }
            break;
        default:
            //NSLog(@"default");
            break;
    }
    
}


@end
