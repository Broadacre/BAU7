//
//  ViewController.m
//  BAU7
//
//  Created by Dan Brooker on 8/6/21.
//

#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"
#import "RandoMapView.h"
#import "IslandMapView.h"
#import "BAMapViewController.h"
#import "RandoMapViewController.h"

#define HEIGHTMAXIMUM 16
#define CHUNKSTODRAW 10
#define INITIALHEIGHT 4
#define REFRESHRATE 0.1
#define PALLETCYCLERATE 0.25


uint16_t ReverseInt16( uint16_t nonreversed )
{
    uint16_t reversed = 0;

    for ( uint16_t i = 0; i < 16; i++ )
    {
        reversed |= ( nonreversed >> ( 16 - i - 1 ) & 1 ) << i;
    }

    return reversed;
}







@interface BAMapViewController () <UIGestureRecognizerDelegate>
@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) NSTimer *palletCycleTimer;
@end

@implementation BAMapViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    mapType=BAMapTypeNormal;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.refreshTimer invalidate];
    self.refreshTimer = nil;
    [self.palletCycleTimer invalidate];
    self.palletCycleTimer = nil;
}

- (void)dealloc {
    [self.refreshTimer invalidate];
    [self.palletCycleTimer invalidate];
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSLog(@"viewDidAppear called");
    
    if(!u7Env)
    {
        NSLog(@"u7Env is nil, showing alert");
       
        UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:@"Loading U7 Environment"
                                                          message:@"This may take a while"
                                                          preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
                    while (topController.presentedViewController)
                    {
                        topController = topController.presentedViewController;
                    }
                    
                    [topController presentViewController:alertController animated:YES completion:^{
                        NSLog(@"Alert completion block running");
                        
                        u7Env=[[U7Environment alloc]init];
                        if(!self->u7view)
                        {
                            NSLog(@"Calling setupView from alert");
                            [self setupView];
                        }
                       
                        
                        [alertController dismissViewControllerAnimated:YES completion:nil];
                        
                    }];
                    

    }
    else
    {
        NSLog(@"u7Env exists, calling setupView directly");
        [self setupView];
    }
    //NSLog(@"totalsize: %li",u7Env->totalSize);
   
}
-(void)setupView
    {
        NSLog(@"setupView called");
        
        if(!u7view)
        {
            switch (mapType) {
                case BAMapTypeNormal:
                    u7view=[[BAMapView alloc]init];
                    break;
                case BAMapTypeRandom:
                    u7view=[[RandoMapView alloc]init];
                    break;
                case BAMapTypeIsland:
                    u7view=[[IslandMapView alloc]init];
                    break;
                default:
                    break;
            }
        }
    
        
        u7view->environment=u7Env;
        u7view->map=u7Env->Map;
        [self specialSetup];
        
        CGRect rect=CGRectMake(0, 0, [u7view chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE, [u7view chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE);
        u7view.frame=rect;
        
        [u7view dirtyMap];

        [scrollView addSubview:u7view];
        [scrollView bringSubviewToFront:u7view];
        
        // Configure scroll view to not delay touches
        scrollView.delaysContentTouches = NO;
        scrollView.canCancelContentTouches = YES;
        
        
        [xSlider setMaximumValue:(SUPERCHUNKSIZE*MAPSIZE)-CHUNKSTODRAW];
        [xSlider setMinimumValue:0];
        [xSlider setValue:56];
        
        [ySlider setMaximumValue:(SUPERCHUNKSIZE*MAPSIZE)-CHUNKSTODRAW];
        [ySlider setMinimumValue:0];
        [ySlider setValue:68];
        
        maxHeight=INITIALHEIGHT;
        [u7view setMaxHeight:maxHeight];
        
        palletCycle=0;
        self.refreshTimer = [NSTimer scheduledTimerWithTimeInterval:REFRESHRATE
          target:self
          selector:@selector(refresh)
          userInfo:nil
          repeats:YES];
        
        self.palletCycleTimer = [NSTimer scheduledTimerWithTimeInterval:PALLETCYCLERATE
          target:self
          selector:@selector(cyclePallet)
          userInfo:nil
          repeats:YES];
        
        UITapGestureRecognizer *singleFingerTap =
          [[UITapGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleSingleTap:)];
        singleFingerTap.numberOfTapsRequired = 1;
        singleFingerTap.numberOfTouchesRequired = 1;
        singleFingerTap.delegate = self;
        [scrollView addGestureRecognizer:singleFingerTap];
        
        NSLog(@"Added tap gesture recognizer to scrollView: %@", scrollView);
        NSLog(@"scrollView gesture recognizers: %@", scrollView.gestureRecognizers);
        
        // Enable user interaction on the map view
        u7view.userInteractionEnabled = YES;
        
        UILongPressGestureRecognizer *longTap = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTouch:)];
        longTap.delegate = self;
        [scrollView addGestureRecognizer:longTap];
        
        // Add pan gesture recognizer for dragging selected shapes
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        panGesture.delegate = self;
        panGesture.minimumNumberOfTouches = 1;
        panGesture.maximumNumberOfTouches = 1;
        [scrollView addGestureRecognizer:panGesture];
        
        
        [self setDrawModeNormal:self];
        
    }

-(void)specialSetup
{
    NSLog(@"SpecialSetup");
    [u7view setChunkWidth:CHUNKSTODRAW];
    mapLocation=CGPointMake(    29, 67);
    [u7view setStartPoint:mapLocation];
}

-(void)resetScrollView
{
    [scrollView setMinimumZoomScale:.001];
    [scrollView setZoomScale:1];
    [scrollView setMaximumZoomScale:100];
}

-(IBAction)setDrawModeNormal:(id)sender
{
    [u7view setDrawMode:NormalMapDrawMode];
    
    CGRect rect=CGRectMake(0, 0, [u7view chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE, [u7view chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE);
    u7view.frame=rect;
    
    scrollView.contentSize = [u7view contentSize];
    [self resetScrollView];
}
-(IBAction)setDrawModeMiniMap:(id)sender
{
    [u7view setDrawMode:MiniMapDrawMode];
    [u7view generateMiniMap];
    CGRect rect=CGRectMake(0, 0, [u7view contentSize].width, [u7view contentSize].height);
    u7view.frame=rect;
    scrollView.contentSize = [u7view contentSize];
    
    [self resetScrollView];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    // Don't allow simultaneous recognition with scroll view's pan gesture when dragging
    if ([u7view isDragging]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // For pan gestures, only begin if we have a selected shape and are in the highlight area
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint location = [gestureRecognizer locationInView:u7view];
        
        // Check if we have selected shapes and the touch is within their bounds
        NSArray *selectedShapes = [u7view getSelectedShapes];
        if ([selectedShapes count] > 0) {
            for (U7ShapeReference *shape in selectedShapes) {
                CGRect highlightRect = [u7view highlightRectForShape:shape];
                if (CGRectContainsPoint(highlightRect, location)) {
                    return YES; // Allow pan gesture to begin for dragging
                }
            }
        }
        
        // If no selected shape is under the touch, don't start our pan gesture
        // This allows the scroll view's pan to work normally
        return NO;
    }
    
    return YES;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:u7view];
    NSLog(@"touchesBegan at: %f, %f", location.x, location.y);
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:u7view];
    NSLog(@"tap:%f,%f",location.x,location.y);
    
    // Don't process tap if we're dragging
    if ([u7view isDragging]) {
        return;
    }
    
    // Try to select a shape at this location
    [u7view toggleShapeSelectionAtViewLocation:location];
    
    // If no shape was selected, move the actor (existing behavior)
    if ([[u7view getSelectedShapes] count] == 0) {
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

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:u7view];
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
        {
            // Try to start dragging if we have selected shapes and are within bounds
            BOOL startedDrag = [u7view beginDragAtViewLocation:location];
            if (startedDrag) {
                // Disable scroll view scrolling while dragging
                scrollView.scrollEnabled = NO;
                NSLog(@"Started dragging shape at: %f, %f", location.x, location.y);
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            if ([u7view isDragging]) {
                [u7view continueDragAtViewLocation:location];
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        {
            if ([u7view isDragging]) {
                [u7view endDrag];
                NSLog(@"Ended dragging shape at: %f, %f", location.x, location.y);
            }
            // Re-enable scroll view scrolling
            scrollView.scrollEnabled = YES;
            break;
        }
            
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            if ([u7view isDragging]) {
                [u7view cancelDrag];
                NSLog(@"Cancelled dragging shape");
            }
            // Re-enable scroll view scrolling
            scrollView.scrollEnabled = YES;
            break;
        }
            
        default:
            break;
    }
}


- (void) longTouch: (UILongPressGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:[recognizer.view superview]];
    if (recognizer.state == UIGestureRecognizerStateEnded) {
         NSLog(@"UIGestureRecognizerStateEnded");
        if(1)  //only make 1
        //if(![u7view->actors count])  //only make 1
        {
            for(int count=0;count<5;count++)
            {
                long offsetX=(mapLocation.x*CHUNKSIZE*TILESIZE)+location.x;
                long offsetY=(mapLocation.y*CHUNKSIZE*TILESIZE)+location.y;
                CGPoint newLocation=CGPointMake(offsetX, offsetY);
                [u7view randomActor:WispCharacterSprite useRandomSprite:YES forLocation:pointToSizedSpace(newLocation,TILESIZE)];
            }
            
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
            [manager setAction:MoveActionType forDirection:[manager DirectionTowardPoint:pointToSizedSpace(newLocation,TILESIZE) toPoint:manager->targetGlobalLocation] forTarget:pointToSizedSpace(newLocation,TILESIZE)];
            [manager->currentAction setTargetDistanceTraveled:1];
        }
        }
   
    
      
}



-(void)refresh
{
    //NSLog(@"Refresh");
    //[u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(void)cyclePallet
{
    //[u7view dirtyMap];
    palletCycle++;
    [u7view setPalletCycle:palletCycle];
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return u7view;
}


-(CGPoint)globalToViewLocation:(CGPoint)globalLocation
{
    
    return [u7view globalToViewLocation:globalLocation];
}

-(IBAction)setMaxHeight:(id)sender
{
    [u7view setMaxHeight:maxHeight];
}

-(IBAction)incrementMaxHeight:(id)sender
{
    
    if((maxHeight+1)>HEIGHTMAXIMUM)
    {
        
    }
    else
    {
    maxHeight++;
        [u7view dirtyMap];
    [u7view setMaxHeight:maxHeight];
    }
    NSLog(@"maxHeight:%i ",maxHeight);
}

-(IBAction)decrementMaxHeight:(id)sender

{
    
    if((maxHeight-1)<(-1))
    {
        
    }
    else
    {
    maxHeight--;
        [u7view dirtyMap];
    [u7view setMaxHeight:maxHeight];
    }
    NSLog(@"maxHeight:%i ",maxHeight);
}

-(IBAction)updateXPos:(id)sender
{
    int XPos=[xSlider value];
    mapLocation.x=XPos;
    [u7view setStartPoint:mapLocation];
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(IBAction)updateYPos:(id)sender
{
    int YPos=[ySlider value];
    mapLocation.y=YPos;
    [u7view setStartPoint:mapLocation];
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
    
}

-(IBAction)mapUp:(id)sender
{
    
    if((mapLocation.y-1)<0)
    {
        
    }
    else
    {
    mapLocation.y--;
    //[heightSlider setValue:maxHeight];
        
    [ySlider setValue:mapLocation.y];
    [u7view setStartPoint:mapLocation];
        [u7view dirtyMap];
    [u7view setNeedsDisplay];
    }
}
-(IBAction)mapDown:(id)sender
{
    
    if((mapLocation.y+1)>((SUPERCHUNKSIZE*MAPSIZE)-CHUNKSTODRAW)-1)
    {
        
    }
    else
    {
    mapLocation.y++;
    //[heightSlider setValue:maxHeight];
        
    [ySlider setValue:mapLocation.y];
    [u7view setStartPoint:mapLocation];
        [u7view dirtyMap];
    [u7view setNeedsDisplay];
    }
}

-(IBAction)mapLeft:(id)sender
{
    if((mapLocation.x-1)<0)
    {
        
    }
    else
    {
    mapLocation.x--;
    //[heightSlider setValue:maxHeight];
        
    [xSlider setValue:mapLocation.x];
    [u7view setStartPoint:mapLocation];
        [u7view dirtyMap];
    [u7view setNeedsDisplay];
    }
}

-(IBAction)mapRight:(id)sender
{
    if((mapLocation.x+1)>((SUPERCHUNKSIZE*MAPSIZE)-CHUNKSTODRAW)-1)
    {
        
    }
    else
    {
    mapLocation.x++;
    //[heightSlider setValue:maxHeight];
    [xSlider setValue:mapLocation.x];
    [u7view setStartPoint:mapLocation];
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
    }
}




-(IBAction)toggleDrawTiles:(id)sender
{
    u7view->drawTiles=!u7view->drawTiles;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(IBAction)toggleDrawGroundObjects:(id)sender
{
    
    u7view->drawGroundObjects=!u7view->drawGroundObjects;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(IBAction)toggleDrawGameObjects:(id)sender
{
    
    u7view->drawGameObjects=!u7view->drawGameObjects;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(IBAction)toggleDrawStaticObjects:(id)sender
{
    
    u7view->drawStaticObjects=!u7view->drawStaticObjects;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(IBAction)toggleDrawPassability:(id)sender
{
    u7view->drawPassability=!u7view->drawPassability;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}
-(IBAction)toggleDrawEnvironmentMap:(id)sender
{
    u7view->drawEnvironmentMap=!u7view->drawEnvironmentMap;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}

-(IBAction)toggleDrawTargets:(id)sender
{
    u7view->drawTargetLocations=!u7view->drawTargetLocations;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}


-(IBAction)toggleDrawChunkHighlite:(id)sender
{
    u7view->drawChunkHighlite=!u7view->drawChunkHighlite;
    [u7view dirtyMap];
    [u7view setNeedsDisplay];
}
@end
