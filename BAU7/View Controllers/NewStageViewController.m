//
//  NewStageViewController.m
//  BAU7
//
//  Created by Dan Brooker on 3/25/22.
//
#import "BATable.h"
#import "includes.h"
#import "BAU7Objects.h"
#import "U7CharacterSprite.h"
#import "BABitmap.h"
#import "Globals.h"
#import "BASpriteAction.h"
#import "BAActionManager.h"
#import "BAAIManager.h"
#import "BASprite.h"
#import "BAMapView.h"
#import "BABitmap.h"
#import "CGPointUtilities.h"
#import "CGRectUtilities.h"
#import "NewStageViewController.h"
#import "BAImageUpscaler.h"


#define CHUNKSTODRAW 8
#define INITIALHEIGHT 4
#define REFRESHRATE .01



@interface NewStageViewController ()

@end

@implementation NewStageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    //BABooleanBitmap * bbitmap=[BABooleanBitmap createWithCGSize:CGSizeMake(10, 10)];
    //[bbitmap setValueAtPosition:YES forPosition:CGPointMake(5, 5)];
    //[bbitmap dump];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if(!u7Env)
    {
        NSLog(@"u7Env is still loading, waiting for notification...");
        
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Loading U7 Environment"
                                              message:@"Please wait..."
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController)
        {
            topController = topController.presentedViewController;
        }
        
        [topController presentViewController:alertController animated:YES completion:nil];
        
        // Wait for environment to finish loading
        [[NSNotificationCenter defaultCenter] addObserverForName:@"U7EnvironmentReady"
                                                           object:nil
                                                            queue:[NSOperationQueue mainQueue]
                                                       usingBlock:^(NSNotification *note) {
            NSLog(@"U7 Environment ready, setting up stage view");
            [alertController dismissViewControllerAnimated:YES completion:^{
                [self setupView];
            }];
        }];
    }
    else
    {
        [self setupView];
    }
}

-(void)setupView
{
    if(!tables)
        tables=[BATable BATablesFromFile:@"tables"];
    //NSLog(@"totalsize: %li",u7Env->totalSize);
    if(!stageMap)
    {
        stageMap=[[BAMapView alloc]init];
        stageMap->map=[[U7Map alloc]init];
        stageMap->environment=u7Env;
        stageMap->map->environment=u7Env;
        [stageMap setChunkWidth:CHUNKSTODRAW];
        mapLocation=CGPointMake(0, 0);
        [stageMap setStartPoint:mapLocation];
        CGRect rect=CGRectMake(0, 0, [stageMap chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE, [stageMap chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE);
        //CGSize size=contentView.frame.size;
        stageMap.frame=rect;
        
        //[self.view addSubview:stageMap];
        //[self.view bringSubviewToFront:stageMap];
        
        [stageMap setMaxHeight:10];
        stageMap->drawTargetLocations=NO;
        
        //[self generateDungeon];
        [self generateMap];
        //[map setMaxHeight:INITIALHEIGHT];
        //[map dirtyMap];
    }
        
    //[self generateMap];
    
    [scrollView addSubview:stageMap];
    [scrollView bringSubviewToFront:stageMap];
    scrollView.contentSize = CGSizeMake([stageMap chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE, [stageMap chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE);
    
    [scrollView setMinimumZoomScale:.1];
    [scrollView setZoomScale:3];
    [scrollView setMaximumZoomScale:10];
    
    
    NSTimer* timer=NULL;
    timer= [NSTimer scheduledTimerWithTimeInterval:REFRESHRATE
      target:self
      selector:@selector(update)
      userInfo:nil
      repeats:YES];
    
    UITapGestureRecognizer *singleFingerTap =
      [[UITapGestureRecognizer alloc] initWithTarget:self
                                              action:@selector(handleSingleTap:)];
    [self.view addGestureRecognizer:singleFingerTap];
    
    UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouch:)];
    longTap.minimumPressDuration = 0.3; // Shorter press to start drag
    [self.view addGestureRecognizer:longTap];
    
    // Add pan gesture for dragging selected shapes
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:panGesture];
    
    // Make pan require long press to fail (so scrolling works normally)
    // Or make them work together for drag operations
    [panGesture requireGestureRecognizerToFail:singleFingerTap];
    
    BAActor * actor=[stageMap randomActor:1 useRandomSprite:YES forLocation:CGPointMake(60, 60)];
    //actor setA
    [self updateActorsLabel];
    //[self generateSpawns];
    
    //BATable * table=[[BATable alloc]init];
}

-(void)generateSpawns
{
    BASpawn * spawn=[BASpawn ResourceSpawnOfType:StoneResourceType];
    [spawn setFrequency:100000];
    [stageMap addSpawn:spawn];
    
    spawn=[BASpawn NPCSpawnOfType:NoActorBAActorType];
    [spawn setFrequency:500];
    [stageMap addSpawn:spawn];
    
    spawn=[BASpawn ResourceSpawnOfType:TreeResourceType];
    [spawn setFrequency:100];
    [stageMap addSpawn:spawn];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return stageMap;
}

-(void)updateActorsLabel
{
    NSString * labelString=[NSString stringWithFormat:@"Actors Count:%li",[stageMap->map->actors count]];
    [spritesLabel setText:labelString];
}
-(void)createActorAtLocation:(CGPoint)location
{
    BAActor* actor=[stageMap randomActor:AvatarMaleCharacterSprite useRandomSprite:YES forLocation:location];
    BASprite * sprite=[BASprite spriteFromU7Shape:331 forFrame:6 forEnvironment:u7Env];
    
    sprite->resourceType=StoneResourceType;
    sprite->map=stageMap->map;
    [self updateActorsLabel];
    //[actor->inventory addObject:sprite];
}

#define NUMBER_OF_NPCS 1
#define NPC_AREA 60

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:stageMap];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSLog(@"UIGestureRecognizerStateEnded - Tap");
        
        // First, try to select a shape at this location
        [stageMap toggleShapeSelectionAtViewLocation:location];
        
        // If no shape was selected, create actors (old behavior)
        NSArray *selectedShapes = [stageMap getSelectedShapes];
        if ([selectedShapes count] == 0) {
            long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
            long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
            CGPoint newLocation=pointToSizedSpace(CGPointMake(offsetX, offsetY), TILESIZE);
            for(int count=0;count<NUMBER_OF_NPCS;count++)
            {
                CGPointArray* pointArray=[[CGPointArray alloc]init];
                CGPoint point= randomCGPointInRect(CGRectMake(newLocation.x-(NPC_AREA/2), newLocation.y-(NPC_AREA/2), NPC_AREA, NPC_AREA));
                [pointArray addPoint:point];
                for(long index=0;index<[pointArray count];index++)
                {
                    CGPoint thePoint=[pointArray pointAtIndex:index];
                    if([stageMap->map isPassable:thePoint])
                        [self createActorAtLocation:thePoint];
                }
            }
        }
    }
    [self updateActorsLabel];
}

- (void) longTouch: (UILongPressGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:stageMap];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"Long press began");
        
        // Try to select a shape at this location for dragging
        U7ShapeReference *shape = [stageMap shapeAtViewLocation:location];
        if (shape) {
            [stageMap deselectAllShapes];
            [stageMap selectShape:shape];
            isDraggingShape = YES;
            NSLog(@"Started dragging shape %ld", (long)shape->shapeID);
        } else {
            isDraggingShape = NO;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        // Handle drag during long press
        if (isDraggingShape) {
            NSArray *selectedShapes = [stageMap getSelectedShapes];
            if ([selectedShapes count] > 0) {
                U7ShapeReference *shape = [selectedShapes firstObject];
                CGPoint globalTile = [stageMap viewLocationToGlobalTileForShape:shape atViewLocation:location];
                [stageMap moveShape:shape toGlobalTileLocation:globalTile];
                [stageMap setNeedsDisplay];
            }
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        NSLog(@"Long press ended");
        
        if (isDraggingShape) {
            // Finish drag operation
            NSArray *selectedShapes = [stageMap getSelectedShapes];
            if ([selectedShapes count] > 0) {
                U7ShapeReference *shape = [selectedShapes firstObject];
                CGPoint globalTile = [stageMap viewLocationToGlobalTileForShape:shape atViewLocation:location];
                [stageMap moveShape:shape toGlobalTileLocation:globalTile];
                NSLog(@"Finished dragging shape %ld to tile (%.0f, %.0f)", 
                      (long)shape->shapeID, globalTile.x, globalTile.y);
            }
            isDraggingShape = NO;
            [stageMap setNeedsDisplay];
        } else {
            // Old behavior - move actor or create one
            if(![stageMap->map->actors count]) {
                long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
                long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
                CGPoint newLocation=pointToSizedSpace(CGPointMake(offsetX, offsetY), TILESIZE);
                BAActor* actor=[stageMap randomActor:AvatarMaleCharacterSprite useRandomSprite:NO forLocation:newLocation];
                BAActionManager * manager=actor->aiManager->actionManager;
                
                CGPointArray * pointArray=[stageMap shapeLocationsWithID:342 forFrame:0];
                pointArray=sortPathByDistance(pointArray, newLocation);
                [manager setCGPointArray:pointArray];
                BAActionSequence * actionSequence=[BAActionSequence ActionSequenceFromCGPointArray:pointArray];
                    
                BASpriteAction * action=[[BASpriteAction alloc]init];
                [action setActionType: MoveActionType];
                [action setTargetLocation:newLocation];
                [actionSequence insertAction:action atIndex:0];
            } else {
                long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
                long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
                
                CGPoint newLocation=pointToSizedSpace(CGPointMake(offsetX, offsetY), TILESIZE);
                
                BAActor * actor=[stageMap->map->actors objectAtIndex:0];
                [stageMap removeSpritesFromMap];
                [actor setGlobalLocation:newLocation];
                
                BAActionManager * manager=actor->aiManager->actionManager;
                    
                [manager->currentAction setComplete:NO];
                manager->actionSequenceComplete=NO;
                [manager resetPath];
            }
        }
    }
   
    [self updateActorsLabel];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:stageMap];
    
    // Only handle pan if we have selected shapes
    NSArray *selectedShapes = [stageMap getSelectedShapes];
    if ([selectedShapes count] == 0) {
        return;
    }
    
    U7ShapeReference *shape = [selectedShapes firstObject];
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        // Check if pan started on the selected shape
        U7ShapeReference *shapeAtLocation = [stageMap shapeAtViewLocation:location];
        if (shapeAtLocation == shape) {
            isDraggingShape = YES;
            NSLog(@"Pan drag started on shape %ld", (long)shape->shapeID);
        } else {
            isDraggingShape = NO;
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        if (isDraggingShape) {
            CGPoint globalTile = [stageMap viewLocationToGlobalTileForShape:shape atViewLocation:location];
            [stageMap moveShape:shape toGlobalTileLocation:globalTile];
            [stageMap setNeedsDisplay];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded || 
             recognizer.state == UIGestureRecognizerStateCancelled) {
        if (isDraggingShape) {
            CGPoint globalTile = [stageMap viewLocationToGlobalTileForShape:shape atViewLocation:location];
            [stageMap moveShape:shape toGlobalTileLocation:globalTile];
            NSLog(@"Pan drag ended - shape %ld at tile (%.0f, %.0f)", 
                  (long)shape->shapeID, globalTile.x, globalTile.y);
            isDraggingShape = NO;
            [stageMap setNeedsDisplay];
        }
    }
}


-(void)update
{
    [stageMap setNeedsDisplay];
    triggeredSpawns=[stageMap getTriggeredSpawns];
    [self handleSpawns];
    }

#define NUMBER_OF_RESOURCES 0
-(void)generateMap
{
    [stageMap initWithChunkID:883];
    [stageMap->map createEnvironmentMaps];
    [stageMap updateMapChunksWithChunkID:1 atPoint:CGPointMake(1,1) forWidth:6 forHeight:6];
    
    
  
}

-(void)generateDungeon
{
    BATable * table=[BATable fetchTableByTitleFromArray:tables forTitle:@"Dungeon Generation"];
    if(table)
        [table dump];
    
    int xpos=randomInSpan(2, 4);
    int ypos=randomInSpan(2, 4);
    
    [stageMap initWithChunkID:883];
    [stageMap->map createEnvironmentMaps];
    
    
    
    
    [stageMap updateMapChunksWithChunkID:1 atPoint:CGPointMake(xpos,ypos) forWidth:1  forHeight:1];
    
    
    
    
}



-(IBAction)toggleDrawPassability:(id)sender
{
    stageMap->drawPassability=!stageMap->drawPassability;
    [stageMap dirtyMap];
    [stageMap setNeedsDisplay];
}

-(IBAction)toggleDrawChunkHighlite:(id)sender
{
    stageMap->drawChunkHighlite=!stageMap->drawChunkHighlite;
    [stageMap dirtyMap];
    [stageMap setNeedsDisplay];
}


-(IBAction)toggleDrawEnvironmentMap:(id)sender
{
    stageMap->drawEnvironmentMap=!stageMap->drawEnvironmentMap;
    [stageMap dirtyMap];
    [stageMap setNeedsDisplay];
}
-(IBAction)reset:(id)sender
{
    [stageMap->map removeAllSprites];
    [self generateMap];
}

-(IBAction)toggleFSRUpscaling:(id)sender
{
    useFSRUpscaling = !useFSRUpscaling;
    
    // Initialize the upscaler if needed
    BAImageUpscaler *upscaler = [BAImageUpscaler sharedUpscaler];
    
    if (useFSRUpscaling && ![upscaler isReady]) {
        // Initialize the FSR upscaler
        if (![upscaler initializeFSR]) {
            NSLog(@"Upscaler initialization failed - upscaling disabled");
            useFSRUpscaling = NO;
            return;
        }
    }
    
    // Clear the upscale cache when toggling off to free memory
    if (!useFSRUpscaling) {
        [upscaler clearCache];
    }
    
    // Dirty the map to force redraw with new settings
    [stageMap dirtyMap];
    [stageMap setNeedsDisplay];
    
    NSLog(@"Upscaling: %@", useFSRUpscaling ? @"ON" : @"OFF");
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

-(void)handleSpawns
{
    if(!triggeredSpawns)
    {
        return;
    }
    
    for(long index=0;index<[triggeredSpawns count];index++)
    {
        BASpawn * theSpawn=[triggeredSpawns objectAtIndex:index];
        switch([theSpawn getSpawnType])
        {
            case NoBASpawnType:
            {
            //NSLog(@"NoBASpawnType");
            break;
            }
            case ResourceBASpawnType:
            {
            //NSLog(@"ResourceBASpawnType");
                CGPoint point=randomCGPointInRect(CGRectMake(CHUNKSIZE, CHUNKSIZE, (CHUNKSIZE*6)-1, (CHUNKSIZE*6)-1));
                //BASprite * testSprite=[stageMap spriteAtLocation:point ofResourceType:[theSpawn getResourceType]];
                //if(testSprite)
               // {
                    //already occupied
               // }
                int shapeID=0;
                int frameID=0;
                switch([theSpawn getResourceType])
                {
                    case StoneResourceType:
                    {
                        shapeID=331;
                        frameID=6;
                        break;
                    }
                    case TreeResourceType:
                    {
                        shapeID=453;
                        frameID=0;
                        break;
                    }
                        
                    default:
                        break;
                }
                //else
                {
                    BASprite * sprite=[BASprite spriteFromU7Shape:shapeID forFrame:frameID forEnvironment:u7Env];
                    
                    sprite->globalLocation=point;
                    
                    sprite->resourceType=[theSpawn getResourceType];
                    sprite->spriteType=ResourceBASpriteType;
                    sprite->map=stageMap->map;
                    
                    U7MapChunkCoordinate * coordinate=[stageMap->map MapChunkCoordinateForGlobalTilePosition:point];
                   // [coordinate dump];
                    U7MapChunk * mapChunk=[stageMap->map mapChunkForLocation:[coordinate mapChunkCoordinate]];
                    [mapChunk addSprite:sprite atLocation:[coordinate getChunkTilePosition]];
                }
            break;
            }
            case NPCBASpawnType:
            {
                CGPoint point=randomCGPointInRect(CGRectMake(CHUNKSIZE, CHUNKSIZE, (CHUNKSIZE*6)-1, (CHUNKSIZE*6)-1));
                [self createActorAtLocation:point];
            }
            default:
                break;
        }
    }
    
}

@end
