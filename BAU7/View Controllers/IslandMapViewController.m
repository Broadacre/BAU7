//
//  RandoMapViewController.m
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//

#import <GameController/GameController.h>
#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"
#import "BAMapViewController.h"
#import "RandoMapView.h"
#import "IslandMapView.h"
#import "IslandMapViewController.h"
#define HEIGHTMAXIMUM 16
#define CHUNKSTODRAW 20
#define INITIALHEIGHT 7
#define REFRESHRATE .1f


#define STARTX 0
#define STARTY 0
#define STARTZOOM .5






@implementation IslandMapViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    mapType=BAMapTypeIsland;
    zoomScale=STARTZOOM;
}
   
    

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(!tables)
    {
        tables=[BATable BATablesFromFile:@"tables"];
        for(long index=0;index<[tables count];index++)
        {
            BATable* table=[tables objectAtIndex:index];
            [table dump];
        }
    }
     
}

-(void)viewDidLayoutSubviews
{
    
    [self resetScrollView];
}

-(void)specialSetup
{
    NSLog(@"Island SpecialSetup");
    
    [u7view generateMap];
    [u7view setChunkWidth:CHUNKSTODRAW];
    mapLocation=CGPointMake(0, 0);
    [u7view setStartPoint:mapLocation];
    
    U7MapChunk *chunk= [u7Env mapChunkForLocation:CGPointMake(STARTX,STARTY)];
    U7Shape * shape=[u7Env->U7Shapes objectAtIndex:AVATARIMAGE];
    U7ShapeReference * newReference=[[U7ShapeReference alloc]init];
    shape->animated=YES;
    newReference->shapeID=AVATARIMAGE;
    newReference->parentChunkXCoord=5;
    newReference->parentChunkYCoord=5;
    newReference->lift=0;
    newReference->frameNumber=0;
    newReference->currentFrame=0;
    newReference->numberOfFrames=[shape numberOfFrames];
    newReference->animates=YES;
    [chunk->gameItems addObject:newReference];
    
}


-(void)setupView
    {
    [super setupView];
    [self setupController];
    }
    

-(void)update
{
    [u7view setNeedsDisplay];
    if(mainCharacter)
    {
        CGPoint charLocation=[self globalToViewLocation:mainCharacter->globalLocation];
        CGPoint scrollViewBoundsCenter=CGPointMake(scrollView.bounds.size.width/2, scrollView.bounds.size.height/2);
        
    
        
        CGPoint scaledPoint=CGPointMake((charLocation.x*zoomScale)-scrollViewBoundsCenter.x, (charLocation.y*zoomScale)-scrollViewBoundsCenter.y);
        
        [scrollView setContentOffset:scaledPoint animated:NO];
        //scrollView.center=self.view.center;
        
    }
}
-(IBAction)reset:(id)sender
{
    mainCharacter=NULL;
    [u7view generateMap];
    [u7view generateMiniMap];
    
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
    
    //[self insertTempDungeon];
}



-(void)setupController
{
    NSLog(@"controllers: %li",[[GCController controllers]count]);
    if(![[GCController controllers]count])
        return;
    
    self.controller=[[GCController controllers]objectAtIndex:0];
    
    GCExtendedGamepad *profile = self.controller.extendedGamepad;
    profile.valueChangedHandler = ^(GCExtendedGamepad *gamepad, GCControllerElement *element)
    {
        [self handleGamepad:gamepad forElement:element];
    };


}

-(void)handleGamepad:(GCExtendedGamepad*) gamepad forElement:(GCControllerElement *)element
{
    if (@available(iOS 13.0, *)) {
        if ((gamepad.buttonMenu == element) && gamepad.buttonMenu.isPressed)
        {
            
            CGPoint thePoint=[self->u7view chunkWithGrass];
            thePoint=CGPointMake(thePoint.x*CHUNKSIZE*TILESIZE, thePoint.y*CHUNKSIZE*TILESIZE);
            logPoint(thePoint, @"Actor Point");
            [self addActor:thePoint];
            NSLog(@"buttonMenu");
        }
    } else {
        // Fallback on earlier versions
    }
    
    if(!mainCharacter)
        return;
    if ((gamepad.rightTrigger == element) && gamepad.rightTrigger.isPressed)
        NSLog(@"Right Trigger:%f",gamepad.rightTrigger.value);
    if ((gamepad.leftTrigger == element) && gamepad.leftTrigger.isPressed)
        NSLog(@"Left Trigger");
    if((gamepad.leftThumbstick==element))
    {
        int xValue=0;
        int yValue=0;
#define ThumbDistance 6
        //NSLog(@"Left Thumb x:%f y:%f",gamepad.leftThumbstick.xAxis.value,gamepad.leftThumbstick.yAxis.value);
        /*
        if(gamepad.leftThumbstick.xAxis.value>ThumbThreshold||gamepad.leftThumbstick.xAxis.value<-ThumbThreshold)
        {
            if(gamepad.leftThumbstick.xAxis.value<0)
                xValue=-4;
            if(gamepad.leftThumbstick.xAxis.value>0)
                xValue=4;
        }
        if(gamepad.leftThumbstick.yAxis.value>ThumbThreshold||gamepad.leftThumbstick.yAxis.value<-ThumbThreshold)
        {
            if(gamepad.leftThumbstick.yAxis.value<0)
                yValue=-4;
            if(gamepad.leftThumbstick.yAxis.value>0)
                yValue=4;
        }
    */
        xValue=gamepad.leftThumbstick.xAxis.value*ThumbDistance;
        yValue=-gamepad.leftThumbstick.yAxis.value*ThumbDistance;
       if(!self->mainCharacter->aiManager->userAction)
       {
           BASpriteAction * action=[[BASpriteAction alloc]init];
           [action setActionType:UserMoveActionType];
           enum BACardinalDirection direction=[self->mainCharacter->aiManager->actionManager DirectionTowardPoint:CGPointMake(0, 0) toPoint:CGPointMake(xValue, yValue)];
           [action setDirection:direction];
           //[action setTargetLocation:destination];
           [action setTargetIterations:1];
           [self->mainCharacter setUserAction:action];
       }
      
       
        
    }
#define ZoomScale 0.05f
    if((gamepad.rightThumbstick==element))
    {
        //NSLog(@"rightThumbstick Thumb x:%f y:%f",gamepad.rightThumbstick.xAxis.value,gamepad.rightThumbstick.yAxis.value);
        self->zoomScale+=gamepad.rightThumbstick.yAxis.value*ZoomScale;
        NSLog(@"Zoomscale: %f",zoomScale);
        [self resetScrollView];
    }
    if((gamepad.dpad==element))
    {
        
        if(gamepad.dpad.left.isPressed)
        {
            NSLog(@"dpad left");
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:UserMoveActionType];
           
            [action setDirection:WestCardinalDirection];
            //[action setTargetLocation:destination];
            [action setTargetIterations:1];
            [self->mainCharacter setUserAction:action];
        }
            
        if(gamepad.dpad.right.isPressed)
        {
            NSLog(@"dpad right");
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:UserMoveActionType];
            
            [action setDirection:EastCardinalDirection];
            //[action setTargetLocation:destination];
            [action setTargetIterations:1];
            [self->mainCharacter setUserAction:action];
        }
        if(gamepad.dpad.up.isPressed)
        {
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:UserMoveActionType];
            
            [action setDirection:NorthCardinalDirection];
            //[action setTargetLocation:destination];
            [action setTargetIterations:1];
            [self->mainCharacter setUserAction:action];
            NSLog(@"dpad up");
        }
        if(gamepad.dpad.down.isPressed)
        {
            BASpriteAction * action=[[BASpriteAction alloc]init];
            [action setActionType:UserMoveActionType];
            
            [action setDirection:SouthCardinalDirection];
            //[action setTargetLocation:destination];
            [action setTargetIterations:1];
            [self->mainCharacter setUserAction:action];
            NSLog(@"dpad down");
        }
    }
    
    if (@available(iOS 13.0, *)) {
        if ((gamepad.buttonOptions == element) && gamepad.buttonOptions.isPressed)
        {
            if(self->mainCharacter)
            {
                static long var=0;
                BASpriteAction * action=[[BASpriteAction alloc]init];
                [action setActionType:MoveActionType];
                
                CGRect targetRect=CGRectMake(self->mainCharacter->globalLocation.x-10, self->mainCharacter->globalLocation.y-10, 20, 20);
                //var++;
                //NSLog(@"Var: %li",var);
                //logPoint(actor->globalLocation, @"Actor:");
                //logRect(targetRect, @"TargetRect");
                CGPoint randomPoint=randomCGPointInRect(targetRect);
                var=(randomPoint.x-self->mainCharacter->globalLocation.x);
                //NSLog(@"Var: %li",var);
                [action setTargetLocation:randomPoint];
                
                [self->mainCharacter setUserAction:action];
                
            }
            
            NSLog(@"buttonOptions");
        }
    } else {
        // Fallback on earlier versions
    }
    
    
    
}

-(void)insertTempDungeon
{
    
    BAIntBitmap * newBitmap=[u7view->interpreter tileBitmapForDungeon:tempDungeonBitmap];
    
    for(long y=0;y<newBitmap->size.height;y++)
    {
        for(long x=0;x<newBitmap->size.width;x++)
        {
            //int value=[newBitmap valueAtPosition:CGPointMake(x, y)];
            
            enum BATileType tileType=NoTileType;
            tileType=[newBitmap valueAtPosition:CGPointMake(x, y) from:@"IslandMapViewController insertTempDungeon"];
            
            U7MapChunk * mapChunk=[u7view->map->map objectAtIndex:(y*TOTALMAPSIZE)+x];
            [mapChunk removeAllObjects];
            mapChunk->masterChunkID=[u7view->interpreter chunkIDForTileType:tileType];
            mapChunk->masterChunk=[u7Env->U7Chunks objectAtIndex:mapChunk->masterChunkID];
            [mapChunk setEnvironment:u7Env];
            if(u7Env)
            {
                [mapChunk updateShapeInfo:u7Env];
                [mapChunk createPassability];
                [mapChunk createEnvironmentMap];
            }
            mapChunk->dirty=YES;
            
            
            /**/
            
        }
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    //NSLog(@"tap");
  CGPoint location = [recognizer locationInView:u7view];
    //for(int x=0;x<100;x++)
    NSLog(@"tap:%f,%f",location.x,location.y);
    {
        if([u7view->map->actors count])
        {
            BAActor * actor=[u7view->map->actors objectAtIndex:0];
            if(actor)
            {
                
                BAActionManager * manager=actor->aiManager->actionManager;
                long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
                long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
                CGPoint newLocation=CGPointMake(offsetX, offsetY);
                if([u7view->map isPassable:pointToSizedSpace(newLocation,TILESIZE)])
                {
                    [manager setTargetLocation:pointToSizedSpace(newLocation,TILESIZE)];
                    
                    [manager->currentAction setComplete:NO];
                    manager->actionSequenceComplete=NO;
                    [manager resetPath];
                    [manager setAction:MoveActionType forDirection:[manager DirectionTowardPoint:location toPoint:manager->targetGlobalLocation]forTarget:pointToSizedSpace(newLocation,TILESIZE)];
                    [manager->currentAction setTargetDistanceTraveled:1];
                }
                
            }
        }
    }
    
}

- (void) longTouch: (UILongPressGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSLog(@"UIGestureRecognizerStateEnded");
        
        CGPoint location = [recognizer locationInView:[recognizer.view superview]];
        [self addActor:location];
    }
      
}

-(void) addActor:(CGPoint)location
{
    long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
    long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
    CGPoint newLocation=CGPointMake(offsetX, offsetY);
   
        if(!mainCharacter)  //only make 1
        {
            
            mainCharacter=[u7view randomActor:AvatarMaleCharacterSprite useRandomSprite:NO forLocation:pointToSizedSpace(newLocation,TILESIZE)];
            u7view->mainCharacter=mainCharacter;
        }
        else
        {
            [mainCharacter setGlobalLocation:pointToSizedSpace(newLocation,TILESIZE)];
            /*
            long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
            long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
            CGPoint newLocation=CGPointMake(offsetX, offsetY);
            BAActor * actor=[u7view->map->actors objectAtIndex:0];
            [u7view removeSpritesFromMap];
            [actor setGlobalLocation:pointToSizedSpace(newLocation,TILESIZE)];
            
            BAActionManager * manager=actor->aiManager->actionManager;
            
            [manager->currentAction setComplete:NO];
            manager->actionSequenceComplete=NO;
            [manager resetPath];
            [manager setAction:MoveActionType forDirection:[manager DirectionTowardPoint:pointToSizedSpace(newLocation,TILESIZE) toPoint:manager->targetGlobalLocation]forTarget:pointToSizedSpace(newLocation,TILESIZE)];
            [manager->currentAction setTargetDistanceTraveled:1];
             */
        }
        
}








@end
