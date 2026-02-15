//
//  RandoMapViewController.m
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//

#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"
#import "BAMapViewController.h"
#import "RandoMapView.h"
#import "RandoMapViewController.h"
#define HEIGHTMAXIMUM 16
#define CHUNKSTODRAW 20
#define INITIALHEIGHT 4
#define REFRESHRATE .25f


#define STARTX 2
#define STARTY 2






@implementation RandoMapViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    mapType=BAMapTypeRandom;
    
}
-(void)viewDidAppear:(BOOL)animated
{
   
    [super viewDidAppear:animated];
}

-(void)setupView
{
    [super setupView];
  
}

-(void)specialSetup
{
    NSLog(@"Rando SpecialSetup");
    [u7view setChunkWidth:CHUNKSTODRAW];
    mapLocation=CGPointMake(0, 0);
    [u7view setStartPoint:mapLocation];
    [u7view generateMap];
}


-(IBAction)reset:(id)sender
{
    [u7view generateMap];
    [u7view generateMiniMap];
    
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
    //[self insertTempDungeon];
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
            tileType=[newBitmap valueAtPosition:CGPointMake(x, y) from:@"RandoMapViewController insertTempDungeon"];
            
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
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
         NSLog(@"UIGestureRecognizerStateEnded");
        if(![u7view->map->actors count])  //only make 1
        {
            long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
            long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
            CGPoint newLocation=CGPointMake(offsetX, offsetY);
            [u7view randomActor:WispCharacterSprite useRandomSprite:YES forLocation:pointToSizedSpace(newLocation,TILESIZE)];
        }
        else
        {
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
        }
        }
   
    
      
}


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return u7view;
}






@end
