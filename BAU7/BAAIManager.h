//
//  BAAIManager.h
//  BAU7
//
//  Created by Dan Brooker on 4/22/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BAActor;
@class BASpriteArray;

@interface BAStateManager: NSObject
{
    long hunger;
    long thirst;
    long tired;
    long fear;
    long cold;
    long heat;
    long anger;
    bool dead;
    
    enum BAState currentState;
    
}
-(void)step;
-(void)determineState;
-(enum BAState)getCurrentState;
-(void)setDead:(BOOL)isDead;
@end

@interface AIManager : NSObject
{
    @public
    BAActor * actor;
    BAStateManager * stateManager;
    BAActionManager * actionManager;
    BASprite * targetSprite;
    CGPointArray * surroundingTiles;
    
    enum BAResourceType desiredResourceType;
    
    BASpriteArray * resourceSprites;
    BASpriteArray * threatSprites;
    
    enum BAState currentState;
    
    BASpriteAction * userAction;
    
    BOOL AIEnabled;
}
-(void)step;
-(void)setActor:(BAActor*)theActor;
-(void)setState:(enum BAState)theState;
@end

NS_ASSUME_NONNULL_END
