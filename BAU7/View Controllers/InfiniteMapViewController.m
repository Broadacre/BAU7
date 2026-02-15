//
//  InfiniteMapViewController.m
//  BAU7
//
//  Created by Dan Brooker on 11/12/21.
//
#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"

#import "InfiniteMapViewController.h"

#define HEIGHTMAXIMUM 16
#define CHUNKSTODRAW 8
#define INITIALHEIGHT 4
#define REFRESHRATE .0001
#define CHUNKOVERFLOW 3  //2 chunks on either side


@interface MapScrollView ()

@property (nonatomic, strong) NSMutableArray *visibleLabels;
@property  CGPoint mapLocation;
@property  CGPoint oldPoint;
@property  CGPoint globalLocation;
@property BOOL firstLayout;
@property int chunksToDraw;
@property int chunksHigh;
@property int chunksWide;
@end


@implementation MapScrollView

-(CGPoint)mapLocationForGlobal
{
    int x;
    int y;
    
    x=_globalLocation.x/(CHUNKSIZE*TILESIZE);
    y=_globalLocation.y/(CHUNKSIZE*TILESIZE);
    
    return CGPointMake(x, y);
}

-(CGPoint)globalLocationForMapLocation
{
    int x;
    int y;
    
    x=_mapLocation.x*CHUNKSIZE*TILESIZE;
    y=_mapLocation.y*CHUNKSIZE*TILESIZE;
    
    return CGPointMake(x, y);
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        self.delegate=self;
        self.contentSize = CGSizeMake(3500, 3500);
        _firstLayout=YES;
        _chunksToDraw=CHUNKSTODRAW;
        _visibleLabels = [[NSMutableArray alloc] init];
        if(!u7Env)
            u7Env=[[U7Environment alloc]init];
        mapView= [[BAMapView alloc] init];
        _mapLocation=CGPointMake(    50, 65);
        _globalLocation=[self globalLocationForMapLocation];
        mapView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
        [self addSubview:mapView];
        [self setupMapView];
        
       

        //[self.mapView setUserInteractionEnabled:NO];
        
        // hide horizontal scroll indicator so our recentering trick is not revealed
        [self setShowsHorizontalScrollIndicator:NO];
    }
    return self;
}

-(void)setupMapView
{
    //[mapView removeFromSuperview];
    mapView->environment=u7Env;
    mapView->map=u7Env->Map;
    [mapView setChunkWidth:_chunksWide];
    [mapView setChunkHeight:_chunksHigh];
    [mapView setStartPoint:_mapLocation];
    [mapView setMaxHeight:INITIALHEIGHT];
    
    //CGRect rect=CGRectMake(0, 0, [_mapView chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE, [_mapView chunkwidth]*CHUNKSIZE*TILESIZE*TILEPIXELSCALE);
    //CGSize size=contentView.frame.size;
    //_mapView.frame=rect;
    
    //mapView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    //CGPoint center = [mapView convertPoint:mapView.center toView:self];
    //mapView.center=[self convertPoint:center toView:self];
    //[self addSubview:mapView];
    
    //[mapView dirtyMap];
    //[mapView setNeedsDisplay];
}

#pragma mark - Layout
- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return mapView;
}

// recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary
{
    //NSLog(@"recenterIfNecessary");
    CGPoint currentOffset = [self contentOffset];
    
    if(_firstLayout)
    {
        _oldPoint=currentOffset;
    }
    
    //logPoint(currentOffset, @"currentOffset");
    //logPoint(_oldPoint, @"_oldPoint");
    CGPoint variance=CGPointSubtractFromPoint(currentOffset, _oldPoint);
    //logPoint(variance, @"variance");
    _globalLocation=CGPointAddToPoint(_globalLocation, variance);
    //logPoint(_globalLocation, @"_globalLocation");
    _oldPoint=currentOffset;
    //_oldPoint=currentOffset;
    
    CGFloat contentWidth = [self contentSize].width;
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
    CGPoint centerOffset=CGPointMake(centerOffsetX, centerOffsetY);
    
    
    //CGFloat distanceFromCenterX = fabs(currentOffset.x - centerOffsetX);
    CGFloat distanceFromCenterX = currentOffset.x - centerOffsetX;
    CGFloat distanceFromCenterY = currentOffset.y - centerOffsetY;
    BOOL redraw=NO;
    //CGFloat distanceFromCenter = distance(currentOffset,centerOffset);
    if(_firstLayout)
        _firstLayout=NO;
    else
    {
        //if (distanceFromCenterX > (contentWidth / 4.0))
        CGFloat newX=currentOffset.x;
        CGFloat newY=currentOffset.y;
        
        if (fabs(distanceFromCenterX) > (CHUNKSIZE*TILESIZE*2))
        {
            //NSLog(@"Recenterx!");
            //NSLog(@"distanceX: %f",distanceFromCenterX);
            //NSLog(@"centeroffsetx: %f",centerOffsetX);
            CGFloat newDistanceX=fabs(distanceFromCenterX)-(CHUNKSIZE*TILESIZE*2);
            
            if(distanceFromCenterX<0)
                newDistanceX=-newDistanceX;
            newX=centerOffset.x-newDistanceX;
            redraw=YES;
        }
        if (fabs(distanceFromCenterY) > (CHUNKSIZE*TILESIZE*2))
        {
            //NSLog(@"Recentery!");
            //_oldPoint=CGPointMake(currentOffset.x, centerOffset.y-distanceFromCenterY);
            CGFloat newDistanceY=fabs(distanceFromCenterY)-(CHUNKSIZE*TILESIZE*2);
            
            if(distanceFromCenterY<0)
                newDistanceY=-newDistanceY;
            
            //NSLog(@"newDistanceY: %f",newDistanceY);
            newY=centerOffset.y-newDistanceY;
            redraw=YES;
        }
        _oldPoint=CGPointMake(newX, newY);
        //logPoint(_oldPoint, @"_oldPoint");
        
            
    }
    
    if(redraw)
    {
        
        _mapLocation=[self mapLocationForGlobal];
        [self setupMapView];
        [mapView dirtyMap];
        [mapView setNeedsDisplay];
        self.contentOffset=_oldPoint;
    }
    //printf("\n");
}
-(CGPoint)globalCenterPointOfMapView
{
    CGPoint thePoint;
    
    thePoint.x=((CHUNKSTODRAW*CHUNKSIZE*TILESIZE)/2)+(mapView->startPoint.x*CHUNKSIZE*TILESIZE);
    thePoint.y=((CHUNKSTODRAW*CHUNKSIZE*TILESIZE)/2)+(mapView->startPoint.y*CHUNKSIZE*TILESIZE);
    return thePoint;
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //NSLog(@"scroll");
    //[self recenterIfNecessary];
    
    // tile content in visible bounds
    //CGRect visibleBounds = [self convertRect:[self bounds] toView:mapView];
    //CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds);
    //CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds);
    
    //[self tileLabelsFromMinX:minimumVisibleX toMaxX:maximumVisibleX];
}

- (void)layoutSubviews
{
    //NSLog(@"layout");
    [super layoutSubviews];
 
    float width=self.frame.size.width;
    float height=self.frame.size.height;
    _chunksWide=width/(CHUNKSIZE*TILESIZE);
    _chunksHigh=height/(CHUNKSIZE*TILESIZE);
    //NSLog(@"size: %f,%f  Chunks: %i,%i",width,height,_chunksWide,_chunksHigh);

    _chunksHigh=_chunksHigh+(CHUNKOVERFLOW*2);
    _chunksWide=_chunksWide+(CHUNKOVERFLOW*2);
    
    self.contentSize = CGSizeMake(_chunksWide*CHUNKSIZE*TILESIZE,_chunksHigh*CHUNKSIZE*TILESIZE );
    [mapView setChunkWidth:_chunksWide];
    [mapView setChunkHeight:_chunksHigh];
    
    
    [self recenterIfNecessary];
}




@end


@implementation InfiniteMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSTimer* timer=NULL;
    timer= [NSTimer scheduledTimerWithTimeInterval:REFRESHRATE
      target:self
      selector:@selector(targetMethod)
      userInfo:nil
      repeats:YES];
    
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [scrollView setMinimumZoomScale:.1];
    [scrollView setZoomScale:3];
    [scrollView setMaximumZoomScale:10];
}

-(void)targetMethod
{
    //[u7view dirtyMap];
    [scrollView->mapView setNeedsDisplay];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
