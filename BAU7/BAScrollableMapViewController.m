//
//  BAScrollableMapViewController.m
//  BAU7
//
//  Created by Dan Brooker on 11/19/25.
//

#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"
#import "BAScrollableMapViewController.h"

#define HEIGHTMAXIMUM 16
#define INITIALHEIGHT 4
#define REFRESHRATE 0.1
#define PALLETCYCLERATE 0.25
#define VISIBLE_CHUNKS 12  // Number of chunks to render at once

@interface BAScrollableMapViewController ()

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) NSTimer *palletCycleTimer;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UILabel *zoomLabel;
@property (nonatomic, assign) CGPoint currentChunkOrigin;
@property (nonatomic, assign) BOOL isUpdatingContent;

@end

@implementation BAScrollableMapViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAppearance];
    maxHeight = INITIALHEIGHT;
    palletCycle = 0;
    self.currentChunkOrigin = CGPointMake(0, 0);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!u7Env) {
        [self showLoadingAndInitialize];
    } else {
        [self setupMapView];
    }
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

#pragma mark - Setup

- (void)setupAppearance {
    self.view.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:1.0];
    
    // Setup scroll view if not from storyboard
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:scrollView];
    }
    
    scrollView.delegate = self;
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    scrollView.bounces = YES;
    scrollView.bouncesZoom = YES;
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    // Enable smooth scrolling
    scrollView.scrollsToTop = NO;
    scrollView.directionalLockEnabled = NO;
    
    // Setup info labels
    [self setupInfoLabels];
}

- (void)setupInfoLabels {
    // Location label
    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.locationLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.locationLabel.textColor = [UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0];
    self.locationLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
    self.locationLabel.textAlignment = NSTextAlignmentCenter;
    self.locationLabel.layer.cornerRadius = 4;
    self.locationLabel.clipsToBounds = YES;
    self.locationLabel.text = @" Chunk: 0, 0 ";
    
    [self.view addSubview:self.locationLabel];
    
    // Zoom label
    self.zoomLabel = [[UILabel alloc] init];
    self.zoomLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.zoomLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.zoomLabel.textColor = [UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0];
    self.zoomLabel.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.7];
    self.zoomLabel.textAlignment = NSTextAlignmentCenter;
    self.zoomLabel.layer.cornerRadius = 4;
    self.zoomLabel.clipsToBounds = YES;
    self.zoomLabel.text = @" Zoom: 1.0x ";
    
    [self.view addSubview:self.zoomLabel];
    
    // Constraints
    [NSLayoutConstraint activateConstraints:@[
        [self.locationLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:8],
        [self.locationLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
        [self.locationLabel.heightAnchor constraintEqualToConstant:24],
        
        [self.zoomLabel.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-8],
        [self.zoomLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
        [self.zoomLabel.heightAnchor constraintEqualToConstant:24],
    ]];
}

- (void)showLoadingAndInitialize {
    // Create loading overlay
    UIView *loadingView = [[UIView alloc] initWithFrame:self.view.bounds];
    loadingView.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.12 alpha:0.95];
    loadingView.tag = 999;
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] 
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.color = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0];
    spinner.center = CGPointMake(loadingView.center.x, loadingView.center.y - 40);
    spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                               UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    [spinner startAnimating];
    
    UILabel *loadingLabel = [[UILabel alloc] init];
    loadingLabel.text = @"Loading Britannia...";
    loadingLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
    loadingLabel.textColor = [UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0];
    loadingLabel.textAlignment = NSTextAlignmentCenter;
    [loadingLabel sizeToFit];
    loadingLabel.center = CGPointMake(loadingView.center.x, loadingView.center.y + 20);
    loadingLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                    UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    UILabel *subtitleLabel = [[UILabel alloc] init];
    subtitleLabel.text = @"Preparing the world map";
    subtitleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    subtitleLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    subtitleLabel.textAlignment = NSTextAlignmentCenter;
    [subtitleLabel sizeToFit];
    subtitleLabel.center = CGPointMake(loadingView.center.x, loadingView.center.y + 50);
    subtitleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin |
                                     UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    
    [loadingView addSubview:spinner];
    [loadingView addSubview:loadingLabel];
    [loadingView addSubview:subtitleLabel];
    [self.view addSubview:loadingView];
    
    // Load on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        U7Environment *env = [[U7Environment alloc] init];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->u7Env = env;
            
            [UIView animateWithDuration:0.3 animations:^{
                loadingView.alpha = 0;
            } completion:^(BOOL finished) {
                [loadingView removeFromSuperview];
                [self setupMapView];
            }];
        });
    });
}

- (void)setupMapView {
    if (mapView) return;
    
    // Calculate total map size
    // Total map is SUPERCHUNKSIZE * MAPSIZE chunks = 192 chunks
    // Each chunk is CHUNKSIZE * TILESIZE * TILEPIXELSCALE pixels
    CGFloat totalMapWidth = SUPERCHUNKSIZE * MAPSIZE * CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat totalMapHeight = SUPERCHUNKSIZE * MAPSIZE * CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    
    // Create the map view to cover the entire map
    mapView = [[BAMapView alloc] init];
    mapView->environment = u7Env;
    mapView->map = u7Env->Map;
    
    // Configure for full map rendering
    [mapView setChunkWidth:VISIBLE_CHUNKS];
    [mapView setStartPoint:CGPointMake(0, 0)];
    [mapView setMaxHeight:maxHeight];
    [mapView setDrawMode:NormalMapDrawMode];
    
    // Set initial drawing options
    mapView->drawTiles = YES;
    mapView->drawGroundObjects = YES;
    mapView->drawGameObjects = YES;
    mapView->drawStaticObjects = YES;
    mapView->drawPassability = NO;
    mapView->drawTargetLocations = NO;
    mapView->drawChunkHighlite = NO;
    mapView->drawEnvironmentMap = NO;
    
    // Size the map view
    CGFloat visibleWidth = VISIBLE_CHUNKS * CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat visibleHeight = VISIBLE_CHUNKS * CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    mapView.frame = CGRectMake(0, 0, visibleWidth, visibleHeight);
    
    // Configure scroll view for the entire map
    scrollView.contentSize = CGSizeMake(totalMapWidth, totalMapHeight);
    
    // Zoom configuration
    [scrollView setMinimumZoomScale:0.1];
    [scrollView setZoomScale:1.0];
    [scrollView setMaximumZoomScale:8.0];
    
    [scrollView addSubview:mapView];
    
    // Start at a nice location (Britain area)
    CGPoint startChunk = CGPointMake(29, 67);
    [self scrollToChunk:startChunk animated:NO];
    
    // Setup timers
    [self setupTimers];
    
    // Initial render
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
    
    // Update labels
    [self updateLocationLabel];
    [self updateZoomLabel];
    
    // Add gesture recognizers
    [self setupGestureRecognizers];
}

- (void)setupTimers {
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
}

- (void)setupGestureRecognizers {
    // Double tap to zoom
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] 
        initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [scrollView addGestureRecognizer:doubleTap];
}

#pragma mark - Timer Callbacks

- (void)refresh {
    [mapView setNeedsDisplay];
}

- (void)cyclePallet {
    palletCycle++;
    [mapView setPalletCycle:palletCycle];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)sv {
    return mapView;
}

- (void)scrollViewDidScroll:(UIScrollView *)sv {
    if (self.isUpdatingContent) return;
    
    [self updateVisibleRegion];
    [self updateLocationLabel];
}

- (void)scrollViewDidZoom:(UIScrollView *)sv {
    [self updateZoomLabel];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv {
    [self updateVisibleRegion];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateVisibleRegion];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)sv withView:(UIView *)view atScale:(CGFloat)scale {
    [self updateVisibleRegion];
}

#pragma mark - Map Region Updates

- (void)updateVisibleRegion {
    // Calculate which chunk is at the center of the visible area
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat zoomScale = scrollView.zoomScale;
    
    // Get visible rect in content coordinates
    CGRect visibleRect = CGRectMake(
        contentOffset.x / zoomScale,
        contentOffset.y / zoomScale,
        scrollView.bounds.size.width / zoomScale,
        scrollView.bounds.size.height / zoomScale
    );
    
    // Calculate chunk coordinates
    CGFloat chunkPixelSize = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    int chunkX = (int)(CGRectGetMidX(visibleRect) / chunkPixelSize);
    int chunkY = (int)(CGRectGetMidY(visibleRect) / chunkPixelSize);
    
    // Clamp to valid range
    int maxChunk = (SUPERCHUNKSIZE * MAPSIZE) - VISIBLE_CHUNKS;
    chunkX = MAX(0, MIN(chunkX - VISIBLE_CHUNKS / 2, maxChunk));
    chunkY = MAX(0, MIN(chunkY - VISIBLE_CHUNKS / 2, maxChunk));
    
    // Only update if chunk origin changed significantly
    if (abs(chunkX - (int)self.currentChunkOrigin.x) > 2 ||
        abs(chunkY - (int)self.currentChunkOrigin.y) > 2) {
        
        self.currentChunkOrigin = CGPointMake(chunkX, chunkY);
        
        // Update map view position and content
        self.isUpdatingContent = YES;
        
        [mapView setStartPoint:self.currentChunkOrigin];
        
        // Reposition map view in scroll view
        CGFloat newX = chunkX * chunkPixelSize;
        CGFloat newY = chunkY * chunkPixelSize;
        mapView.frame = CGRectMake(newX, newY, mapView.frame.size.width, mapView.frame.size.height);
        
        [mapView dirtyMap];
        [mapView setNeedsDisplay];
        
        self.isUpdatingContent = NO;
    }
}

- (void)updateLocationLabel {
    CGPoint contentOffset = scrollView.contentOffset;
    CGFloat zoomScale = scrollView.zoomScale;
    
    CGFloat chunkPixelSize = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    int chunkX = (int)((contentOffset.x / zoomScale + scrollView.bounds.size.width / 2 / zoomScale) / chunkPixelSize);
    int chunkY = (int)((contentOffset.y / zoomScale + scrollView.bounds.size.height / 2 / zoomScale) / chunkPixelSize);
    
    self.locationLabel.text = [NSString stringWithFormat:@" Chunk: %d, %d ", chunkX, chunkY];
}

- (void)updateZoomLabel {
    self.zoomLabel.text = [NSString stringWithFormat:@" Zoom: %.1fx ", scrollView.zoomScale];
}

#pragma mark - Gesture Handlers

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    if (scrollView.zoomScale < scrollView.maximumZoomScale) {
        // Zoom in to the tapped point
        CGPoint location = [recognizer locationInView:mapView];
        CGRect zoomRect = [self zoomRectForScale:scrollView.zoomScale * 2.0 withCenter:location];
        [scrollView zoomToRect:zoomRect animated:YES];
    } else {
        // Zoom out to minimum
        [scrollView setZoomScale:scrollView.minimumZoomScale animated:YES];
    }
}

- (CGRect)zoomRectForScale:(CGFloat)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    zoomRect.size.height = scrollView.frame.size.height / scale;
    zoomRect.size.width = scrollView.frame.size.width / scale;
    zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0);
    zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0);
    return zoomRect;
}

#pragma mark - Public Navigation Methods

- (void)scrollToLocation:(CGPoint)globalTileLocation animated:(BOOL)animated {
    CGFloat pixelX = globalTileLocation.x * TILESIZE * TILEPIXELSCALE;
    CGFloat pixelY = globalTileLocation.y * TILESIZE * TILEPIXELSCALE;
    
    CGPoint offset = CGPointMake(
        pixelX - scrollView.bounds.size.width / 2,
        pixelY - scrollView.bounds.size.height / 2
    );
    
    // Clamp to content bounds
    offset.x = MAX(0, MIN(offset.x, scrollView.contentSize.width - scrollView.bounds.size.width));
    offset.y = MAX(0, MIN(offset.y, scrollView.contentSize.height - scrollView.bounds.size.height));
    
    [scrollView setContentOffset:offset animated:animated];
}

- (void)scrollToChunk:(CGPoint)chunkCoordinate animated:(BOOL)animated {
    CGFloat chunkPixelSize = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat pixelX = chunkCoordinate.x * chunkPixelSize;
    CGFloat pixelY = chunkCoordinate.y * chunkPixelSize;
    
    CGPoint offset = CGPointMake(
        pixelX - scrollView.bounds.size.width / 2,
        pixelY - scrollView.bounds.size.height / 2
    );
    
    // Clamp to content bounds
    offset.x = MAX(0, MIN(offset.x, scrollView.contentSize.width - scrollView.bounds.size.width));
    offset.y = MAX(0, MIN(offset.y, scrollView.contentSize.height - scrollView.bounds.size.height));
    
    [scrollView setContentOffset:offset animated:animated];
    
    // Force immediate region update
    [self updateVisibleRegion];
}

#pragma mark - Height Controls

- (IBAction)incrementMaxHeight:(id)sender {
    if (maxHeight >= HEIGHTMAXIMUM) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] 
            initWithStyle:UIImpactFeedbackStyleLight];
        [feedback impactOccurred];
        return;
    }
    
    maxHeight++;
    [mapView setMaxHeight:maxHeight];
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
    
    NSLog(@"maxHeight: %i", maxHeight);
}

- (IBAction)decrementMaxHeight:(id)sender {
    if (maxHeight <= -1) {
        UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] 
            initWithStyle:UIImpactFeedbackStyleLight];
        [feedback impactOccurred];
        return;
    }
    
    maxHeight--;
    [mapView setMaxHeight:maxHeight];
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
    
    NSLog(@"maxHeight: %i", maxHeight);
}

#pragma mark - Drawing Toggles

- (IBAction)toggleDrawTiles:(id)sender {
    mapView->drawTiles = !mapView->drawTiles;
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
}

- (IBAction)toggleDrawGroundObjects:(id)sender {
    mapView->drawGroundObjects = !mapView->drawGroundObjects;
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
}

- (IBAction)toggleDrawGameObjects:(id)sender {
    mapView->drawGameObjects = !mapView->drawGameObjects;
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
}

- (IBAction)toggleDrawStaticObjects:(id)sender {
    mapView->drawStaticObjects = !mapView->drawStaticObjects;
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
}

- (IBAction)toggleDrawPassability:(id)sender {
    mapView->drawPassability = !mapView->drawPassability;
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
}

#pragma mark - Zoom Controls

- (IBAction)zoomIn:(id)sender {
    CGFloat newScale = MIN(scrollView.zoomScale * 1.5, scrollView.maximumZoomScale);
    [scrollView setZoomScale:newScale animated:YES];
}

- (IBAction)zoomOut:(id)sender {
    CGFloat newScale = MAX(scrollView.zoomScale / 1.5, scrollView.minimumZoomScale);
    [scrollView setZoomScale:newScale animated:YES];
}

- (IBAction)resetZoom:(id)sender {
    [scrollView setZoomScale:1.0 animated:YES];
}

@end
