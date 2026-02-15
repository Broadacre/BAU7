//
//  NewMapViewController.m
//  BAU7
//
//  Created by Dan Brooker on 11/18/21.
//
#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"

#import "NewMapViewController.h"

#define HEIGHTMAXIMUM 16
#define CHUNKSTODRAW 8
#define INITIALHEIGHT 4
#define REFRESHRATE .1
#define CHUNKOVERFLOW 3  //2 chunks on either side



@implementation NewMapViewController

-(CGPoint)mapLocationForGlobal
{
    int x;
    int y;
    
    x=globalLocation.x/(CHUNKSIZE*TILESIZE);
    y=globalLocation.y/(CHUNKSIZE*TILESIZE);
    
    return CGPointMake(x, y);
}

-(CGPoint)globalLocationForMapLocation
{
    int x;
    int y;
    
    x=mapLocation.x*CHUNKSIZE*TILESIZE;
    y=mapLocation.y*CHUNKSIZE*TILESIZE;
    
    return CGPointMake(x, y);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    firstLayout=YES;
    chunksToDraw=CHUNKSTODRAW;
    if(!u7Env)
        u7Env=[[U7Environment alloc]init];
    if(!mapView)
        NSLog(@"Bad Mapview");
    [mapView init];
    mapOrigin=CGPointMake(0, 0);
    shift=CGPointMake(0, 0);
    oldShift=shift;
    mapLocation=CGPointMake(55, 85);
    globalLocation=[self globalLocationForMapLocation];
    logPoint(globalLocation, @"globalLoc");
    //mapView.frame = CGRectMake(0, 0, self.view.frame.size.width, sself.view.frame.size.height);
    [self setupMapView];
    //mapView.frame=CGRectMake(100,100,2000, 2000);
    //mapView.center=self.view.center;
    [mapView dirtyMap];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    NSLog(@"viewDidAppear");
    [super viewDidAppear:animated];
    //mapView= [[BAMapView alloc] init];
    

    //[self.view addSubview:mapView];
    //[self.view  bringSubviewToFront:mapView];
    NSTimer* timer=NULL;
    timer= [NSTimer scheduledTimerWithTimeInterval:REFRESHRATE
      target:self
      selector:@selector(targetMethod)
      userInfo:nil
      repeats:YES];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [mapView addGestureRecognizer:pan];
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
 
    float width=self.view.frame.size.width;
    float height=self.view.frame.size.height;
    chunksWide=width/(CHUNKSIZE*TILESIZE);
    chunksHigh=height/(CHUNKSIZE*TILESIZE);
    NSLog(@"size: %f,%f  Chunks: %i,%i",width,height,chunksWide,chunksHigh);

    chunksHigh=chunksHigh+(CHUNKOVERFLOW*2);
    chunksWide=chunksWide+(CHUNKOVERFLOW*2);
    
    NSLog(@"size: %f,%f  Chunks: %i,%i",width,height,chunksWide,chunksHigh);
    CGFloat offScreenX=(width-(chunksWide*CHUNKSIZE*TILESIZE))/2;
    CGFloat offScreenY=(height-(chunksHigh*CHUNKSIZE*TILESIZE))/2;
    maxOffScreenShift=CGPointMake(offScreenX, offScreenY);
    logPoint(maxOffScreenShift, @"maxOffScreenShift");
    
    CGSize size=CGSizeMake(chunksWide*CHUNKSIZE*TILESIZE,chunksHigh*CHUNKSIZE*TILESIZE);
    mapView.frame=CGRectMake(0, 0, size.width, size.height);
    [mapView setChunkWidth:chunksWide];
    [mapView setChunkHeight:chunksHigh];
    
    CGPoint newPoint=CGPointAddToPoint(mapView.center, maxOffScreenShift);
    logPoint(newPoint, @"newPoint");
    mapView.center=newPoint;
    
    
    //[self recenterIfNecessary:maxOffScreenShift];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.view];
    [self recenterIfNecessary:translation];
    
    [recognizer setTranslation:CGPointZero inView:self.view];
    
}

-(IBAction) test
{
    NSLog(@"test");
    CGPoint newOrigin=CGPointAddToPoint(mapOrigin, CGPointMake(0, 1));
    [self setMapOrigin:newOrigin];
}

-(void)setMapOrigin:(CGPoint)newOrigin
{
    mapOrigin=newOrigin;
    mapView.frame=CGRectMake(mapOrigin.x, mapOrigin.y, mapView.frame.size.width, mapView.frame.size.height);
}

-(void)targetMethod
{
    //[u7view dirtyMap];
    //NSLog(@"a");
    [mapView setNeedsDisplay];
}

-(void)setupMapView
{
    NSLog(@"setupMapView");
    //[mapView removeFromSuperview];
    mapView->environment=u7Env;
    mapView->map=u7Env->Map;
    [mapView setChunkWidth:chunksWide];
    [mapView setChunkHeight:chunksHigh];
    [mapView setChunkWidth:CHUNKSTODRAW];
    [mapView setStartPoint:mapLocation];
    [mapView setMaxHeight:INITIALHEIGHT];
    NSLog(@"done");
    
}


- (void)recenterIfNecessary:(CGPoint)translation
{
    
    //logPoint(translation, @"translation");
    
    shift=CGPointAddToPoint(shift, translation);
    //logPoint(globalLocation, @"global location pre-translation");
    globalLocation=CGPointSubtractFromPoint(globalLocation, translation);
    //logPoint(globalLocation, @"global location post-translation");

    BOOL redraw=NO;
    //logPoint(shift, @"shift");
    //NSLog(@"recenterIfNecessary");
    CGFloat newX=0;
    CGFloat newY=0;
    if(fabs(shift.x)>CHUNKSIZE*TILESIZE)
    {
        //NSLog(@"recenter");
        if(shift.x>0)
            shift.x=shift.x-(CHUNKSIZE*TILESIZE);
        else
            shift.x=shift.x+(CHUNKSIZE*TILESIZE);
        
            
        newX=shift.x-oldShift.x;
        //NSLog(@"newX: %f",newX);
        redraw=YES;
    }
    else
        newX=translation.x;
    
    if(fabs(shift.y)>CHUNKSIZE*TILESIZE)
    {
        //NSLog(@"recenter");
        if(shift.y>0)
            shift.y=shift.y-(CHUNKSIZE*TILESIZE);
        else
            shift.y=shift.y+(CHUNKSIZE*TILESIZE);
        newY=shift.y-oldShift.y;
        //NSLog(@"newY: %f",newY);
        redraw=YES;
    }
    else
        newY=translation.y;
    
    CGPoint newPoint=CGPointAddToPoint(mapView.center, CGPointMake(newX, newY));
    //logPoint(newPoint, @"newPoint");
    mapView.center=newPoint;
    oldShift=shift;
    mapLocation=[self mapLocationForGlobal];
    [mapView setStartPoint:mapLocation];
}

@end
