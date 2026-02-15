//
//  BAScrollableMapViewController.m
//  BAU7
//
//  Smooth scrolling map viewer for the entire U7 world
//

#import "Includes.h"
#import "BAU7Objects.h"
#import "Globals.h"
#import "BAMapView.h"
#import "BAScrollableMapViewController.h"
#import "BAImageUpscaler.h"
#import "BAActionManager.h"
#import "BAAIManager.h"

#define HEIGHTMAXIMUM 16
#define INITIALHEIGHT 4
#define REFRESHRATE 0.1
#define PALLETCYCLERATE 0.25
#define MIN_VISIBLE_CHUNKS 8   // Minimum chunks to render
#define CHUNK_PADDING 2        // Extra chunks beyond visible area for smooth scrolling

@interface BAScrollableMapViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSTimer *refreshTimer;
@property (nonatomic, strong) NSTimer *palletCycleTimer;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIButton *drawOptionsButton;
@property (nonatomic, assign) CGPoint lastChunkOrigin;
@property (nonatomic, assign) CGSize lastViewSize;
@property (nonatomic, assign) int visibleChunksWide;
@property (nonatomic, assign) int visibleChunksHigh;

// Drag properties
@property (nonatomic, assign) BOOL isDraggingShape;
@property (nonatomic, assign) CGPoint dragStartLocation;
@property (nonatomic, strong) U7ShapeReference *draggedShape;

// Actor properties
@property (nonatomic, strong) BAActor *userActor;
@property (nonatomic, assign) BOOL followActor;

@end

@implementation BAScrollableMapViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    maxHeight = INITIALHEIGHT;
    palletCycle = 0;
    self.lastChunkOrigin = CGPointMake(-1, -1);
    self.lastViewSize = CGSizeZero;
    self.visibleChunksWide = MIN_VISIBLE_CHUNKS;
    self.visibleChunksHigh = MIN_VISIBLE_CHUNKS;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!u7Env) {
        [self loadEnvironmentAndSetup];
    } else if (!mapView) {
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    // Check if view size changed (window resize, rotation, etc.)
    if (!CGSizeEqualToSize(self.view.bounds.size, self.lastViewSize)) {
        self.lastViewSize = self.view.bounds.size;
        [self handleViewSizeChange];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Animation in progress
    } completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // Transition complete - update map
        [self handleViewSizeChange];
    }];
}

- (void)dealloc {
    [self.refreshTimer invalidate];
    [self.palletCycleTimer invalidate];
}

#pragma mark - Loading

- (void)loadEnvironmentAndSetup {
    // Show loading indicator
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] 
        initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    spinner.center = self.view.center;
    spinner.color = [UIColor whiteColor];
    spinner.tag = 999;
    [spinner startAnimating];
    [self.view addSubview:spinner];
    
    // Load on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        U7Environment *env = [[U7Environment alloc] init];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->u7Env = env;
            [[self.view viewWithTag:999] removeFromSuperview];
            [self setupMapView];
        });
    });
}

#pragma mark - Setup

- (void)calculateVisibleChunksForSize:(CGSize)viewSize {
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    
    // Calculate how many chunks are needed to fill the view at CURRENT zoom
    // When zoomed in (zoomScale > 1), we need FEWER chunks
    // When zoomed out (zoomScale < 1), we need MORE chunks
    CGFloat currentZoom = scrollView ? scrollView.zoomScale : 1.0;
    
    // Effective view size in content coordinates
    // At zoom 2x, a 1000px view only shows 500px of content
    // At zoom 0.5x, a 1000px view shows 2000px of content
    CGFloat effectiveWidth = viewSize.width / currentZoom;
    CGFloat effectiveHeight = viewSize.height / currentZoom;
    
    // Calculate chunks needed plus padding for smooth scrolling
    int chunksWide = (int)ceil(effectiveWidth / chunkPixels) + CHUNK_PADDING * 2;
    int chunksHigh = (int)ceil(effectiveHeight / chunkPixels) + CHUNK_PADDING * 2;
    
    // Ensure minimum size for smooth experience
    chunksWide = MAX(chunksWide, MIN_VISIBLE_CHUNKS);
    chunksHigh = MAX(chunksHigh, MIN_VISIBLE_CHUNKS);
    
    // Cap at reasonable maximum to avoid Core Animation backing store limits
    // CA has issues with layer sizes > ~8192 points at 2x scale
    int maxReasonableChunks = 64; // 64 * 128 = 8192 pixels
    chunksWide = MIN(chunksWide, maxReasonableChunks);
    chunksHigh = MIN(chunksHigh, maxReasonableChunks);
    
    // Also cap at total map size
    int maxChunks = SUPERCHUNKSIZE * MAPSIZE;
    chunksWide = MIN(chunksWide, maxChunks);
    chunksHigh = MIN(chunksHigh, maxChunks);
    
    // Only log and update if changed
    if (chunksWide != self.visibleChunksWide || chunksHigh != self.visibleChunksHigh) {
        //NSLog(@"Zoom: %.2f, View: %.0fx%.0f, Effective: %.0fx%.0f, Chunks: %dx%d",
        //      currentZoom, viewSize.width, viewSize.height,
        //      effectiveWidth, effectiveHeight, chunksWide, chunksHigh);
    }
    
    self.visibleChunksWide = chunksWide;
    self.visibleChunksHigh = chunksHigh;
}

- (void)handleViewSizeChange {
    if (!mapView || !scrollView) return;
    
    CGSize newSize = self.view.bounds.size;
    
    // Recalculate how many chunks we need
    [self calculateVisibleChunksForSize:newSize];
    
    // Update map view chunk dimensions
    [mapView setChunkWidth:self.visibleChunksWide];
    [mapView setChunkHeight:self.visibleChunksHigh];
    
    // Resize map view frame
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat mapWidth = self.visibleChunksWide * chunkPixels;
    CGFloat mapHeight = self.visibleChunksHigh * chunkPixels;
    
    // Get current position
    CGFloat mapX = self.lastChunkOrigin.x * chunkPixels;
    CGFloat mapY = self.lastChunkOrigin.y * chunkPixels;
    
    mapView.frame = CGRectMake(mapX, mapY, mapWidth, mapHeight);
    
    // Force full redraw with new dimensions
    self.lastChunkOrigin = CGPointMake(-1, -1); // Force update
    [self updateMapForCurrentScroll];
    
    //NSLog(@"Window resized - Map view frame: %.0f x %.0f", mapWidth, mapHeight);
}

- (void)setupMapView {
    if (mapView) return;
    
    // Create scroll view if needed
    if (!scrollView) {
        scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:scrollView];
    }
    
    scrollView.delegate = self;
    scrollView.backgroundColor = [UIColor blackColor];
    scrollView.showsHorizontalScrollIndicator = YES;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.bounces = YES;
    scrollView.bouncesZoom = YES;
    
    // Zoom settings (set before calculating visible chunks)
    // Allow zooming out to see large portions of the map
    // and zooming in nearly to pixel level (32x gives ~4 screen pixels per game pixel on retina)
    scrollView.minimumZoomScale = 0.1;
    scrollView.maximumZoomScale = 32.0;
    scrollView.zoomScale = 1.0;
    
    // Calculate sizes
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat totalChunks = SUPERCHUNKSIZE * MAPSIZE;  // 192 chunks
    CGFloat totalMapSize = totalChunks * chunkPixels;
    
    // Create a container view that spans the entire map
    // This is what we'll use for zooming
    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, totalMapSize, totalMapSize)];
    self.containerView.backgroundColor = [UIColor blackColor];
    [scrollView addSubview:self.containerView];
    
    // Content size matches container
    scrollView.contentSize = self.containerView.frame.size;
    
    // Calculate initial visible chunks based on view size
    [self calculateVisibleChunksForSize:self.view.bounds.size];
    
    // Create map view sized for visible chunks
    mapView = [[BAMapView alloc] init];
    mapView->environment = u7Env;
    mapView->map = u7Env->Map;
    
    [mapView setChunkWidth:self.visibleChunksWide];
    [mapView setChunkHeight:self.visibleChunksHigh];
    [mapView setMaxHeight:maxHeight];
    [mapView setDrawMode:NormalMapDrawMode];
    
    // Enable all drawing
    mapView->drawTiles = YES;
    mapView->drawGroundObjects = YES;
    mapView->drawGameObjects = YES;
    mapView->drawStaticObjects = YES;
    mapView->drawPassability = NO;
    
    // Size map view for visible chunks
    CGFloat visibleWidth = self.visibleChunksWide * chunkPixels;
    CGFloat visibleHeight = self.visibleChunksHigh * chunkPixels;
    mapView.frame = CGRectMake(0, 0, visibleWidth, visibleHeight);
    
    // Add map view to container (not directly to scroll view)
    [self.containerView addSubview:mapView];
    
    // Setup location label
    [self setupLocationLabel];
    
    // Start at Britain (chunk 29, 67)
    CGFloat startX = 29 * chunkPixels;
    CGFloat startY = 67 * chunkPixels;
    [scrollView setContentOffset:CGPointMake(startX, startY) animated:NO];
    
    // Initial update
    [self updateMapForCurrentScroll];
    
    // Start timers
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
    
    // Setup tap gesture recognizer for setting actor target or initiating drag
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] 
        initWithTarget:self action:@selector(handleTap:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.delegate = self;
    [scrollView addGestureRecognizer:tapGesture];
    
    // Setup double-tap gesture for placing actor
    UITapGestureRecognizer *doubleTapGesture = [[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    doubleTapGesture.delegate = self;
    [scrollView addGestureRecognizer:doubleTapGesture];
    
    // Make single tap require double tap to fail
    [tapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    // Setup long press gesture for shape selection
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc]
        initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 0.3;
    longPressGesture.delegate = self;
    [scrollView addGestureRecognizer:longPressGesture];
    
    // Setup pan gesture recognizer for dragging shapes
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    panGesture.minimumNumberOfTouches = 1;
    panGesture.maximumNumberOfTouches = 1;
    [scrollView addGestureRecognizer:panGesture];
    
    // Make tap require long press to fail (so selection happens on long press, not tap)
    [tapGesture requireGestureRecognizerToFail:longPressGesture];
    
    // Make the scroll view's pan gesture require our pan gesture to fail
    // This gives our pan gesture priority when on a selected shape
    for (UIGestureRecognizer *gesture in scrollView.gestureRecognizers) {
        if ([gesture isKindOfClass:[UIPanGestureRecognizer class]] && gesture != panGesture) {
            [gesture requireGestureRecognizerToFail:panGesture];
        }
    }
    
    NSLog(@"Added gesture recognizers: tap, long press, two-finger tap, pan");
    
    // Store initial size
    self.lastViewSize = self.view.bounds.size;
}

- (void)setupLocationLabel {
    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.locationLabel.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightMedium];
    self.locationLabel.textColor = [UIColor whiteColor];
    self.locationLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.locationLabel.textAlignment = NSTextAlignmentCenter;
    self.locationLabel.text = @" Chunk: 0, 0 ";
    
    [self.view addSubview:self.locationLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.locationLabel.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor constant:8],
        [self.locationLabel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-8],
    ]];
    
    // Setup draw options button
    [self setupDrawOptionsButton];
}

- (void)setupDrawOptionsButton {
    self.drawOptionsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.drawOptionsButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImage *gearImage = [UIImage systemImageNamed:@"gearshape.fill"];
    [self.drawOptionsButton setImage:gearImage forState:UIControlStateNormal];
    self.drawOptionsButton.tintColor = [UIColor whiteColor];
    self.drawOptionsButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    self.drawOptionsButton.layer.cornerRadius = 22;
    self.drawOptionsButton.clipsToBounds = YES;
    
    [self.drawOptionsButton addTarget:self 
                               action:@selector(showDrawOptionsMenu:) 
                     forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.drawOptionsButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.drawOptionsButton.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor constant:-16],
        [self.drawOptionsButton.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-16],
        [self.drawOptionsButton.widthAnchor constraintEqualToConstant:44],
        [self.drawOptionsButton.heightAnchor constraintEqualToConstant:44],
    ]];
}

- (void)showDrawOptionsMenu:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController 
        alertControllerWithTitle:@"Draw Options"
        message:nil
        preferredStyle:UIAlertControllerStyleActionSheet];
    
    // Helper block to create toggle actions with checkmark
    void (^addToggleAction)(NSString *, BOOL *, UIAlertController *) = ^(NSString *title, BOOL *flag, UIAlertController *controller) {
        NSString *displayTitle = *flag ? [NSString stringWithFormat:@"✓ %@", title] : title;
        UIAlertAction *action = [UIAlertAction actionWithTitle:displayTitle 
                                                         style:UIAlertActionStyleDefault 
                                                       handler:^(UIAlertAction *action) {
            *flag = !(*flag);
            [self->mapView dirtyMap];
            [self->mapView setNeedsDisplay];
        }];
        [controller addAction:action];
    };
    
    // Add all draw options
    addToggleAction(@"Tiles", &mapView->drawTiles, alertController);
    addToggleAction(@"Ground Objects", &mapView->drawGroundObjects, alertController);
    addToggleAction(@"Game Objects", &mapView->drawGameObjects, alertController);
    addToggleAction(@"Static Objects", &mapView->drawStaticObjects, alertController);
    addToggleAction(@"Passability", &mapView->drawPassability, alertController);
    addToggleAction(@"Target Locations", &mapView->drawTargetLocations, alertController);
    addToggleAction(@"Chunk Highlight", &mapView->drawChunkHighlite, alertController);
    addToggleAction(@"Environment Map", &mapView->drawEnvironmentMap, alertController);
    addToggleAction(@"Shape IDs", &mapView->drawShapeIDs, alertController);
    
    // Height controls
    UIAlertAction *incrementHeight = [UIAlertAction actionWithTitle:@"↑ Increase Height" 
                                                              style:UIAlertActionStyleDefault 
                                                            handler:^(UIAlertAction *action) {
        if (self->maxHeight < HEIGHTMAXIMUM) {
            self->maxHeight++;
            [self->mapView setMaxHeight:self->maxHeight];
            [self->mapView dirtyMap];
        }
    }];
    [alertController addAction:incrementHeight];
    
    UIAlertAction *decrementHeight = [UIAlertAction actionWithTitle:@"↓ Decrease Height" 
                                                              style:UIAlertActionStyleDefault 
                                                            handler:^(UIAlertAction *action) {
        if (self->maxHeight > -1) {
            self->maxHeight--;
            [self->mapView setMaxHeight:self->maxHeight];
            [self->mapView dirtyMap];
        }
    }];
    [alertController addAction:decrementHeight];
    
    // FSR Upscaling toggle
    NSString *fsrTitle = useFSRUpscaling ? @"✓ FSR Upscaling" : @"FSR Upscaling";
    UIAlertAction *fsrAction = [UIAlertAction actionWithTitle:fsrTitle 
                                                        style:UIAlertActionStyleDefault 
                                                      handler:^(UIAlertAction *action) {
        useFSRUpscaling = !useFSRUpscaling;
        
        BAImageUpscaler *upscaler = [BAImageUpscaler sharedUpscaler];
        
        if (useFSRUpscaling && ![upscaler isReady]) {
            if (![upscaler initializeFSR]) {
                NSLog(@"FSR initialization failed - upscaling disabled");
                useFSRUpscaling = NO;
                return;
            }
            // Set quality mode - Quality is a good balance
            upscaler.qualityMode = BAFSRQualityModeQuality;
            upscaler.sharpness = 0.2f;
        }
        
        if (!useFSRUpscaling) {
            [upscaler clearCache];
        }
        
        [self->mapView dirtyMap];
        [self->mapView setNeedsDisplay];
        
        NSLog(@"FSR upscaling: %@", useFSRUpscaling ? @"ON" : @"OFF");
    }];
    [alertController addAction:fsrAction];
    
    // Follow Actor toggle
    NSString *followTitle = self.followActor ? @"✓ Follow Actor" : @"Follow Actor";
    UIAlertAction *followAction = [UIAlertAction actionWithTitle:followTitle 
                                                           style:UIAlertActionStyleDefault 
                                                         handler:^(UIAlertAction *action) {
        self.followActor = !self.followActor;
        
        if (self.followActor && self.userActor) {
            // Immediately center on actor when enabled
            [self centerOnActor:YES];
        }
        
        NSLog(@"Follow actor: %@", self.followActor ? @"ON" : @"OFF");
    }];
    [alertController addAction:followAction];
    
    // Cancel action
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" 
                                                           style:UIAlertActionStyleCancel 
                                                         handler:nil];
    [alertController addAction:cancelAction];
    
    // Configure popover for iPad
    if (alertController.popoverPresentationController) {
        alertController.popoverPresentationController.sourceView = sender;
        alertController.popoverPresentationController.sourceRect = sender.bounds;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Core Scrolling Logic

- (void)updateMapForCurrentScroll {
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat zoomScale = scrollView.zoomScale;
    
    // Get the visible rect in content coordinates (accounting for zoom)
    CGRect visibleRect;
    visibleRect.origin.x = scrollView.contentOffset.x / zoomScale;
    visibleRect.origin.y = scrollView.contentOffset.y / zoomScale;
    visibleRect.size.width = scrollView.bounds.size.width / zoomScale;
    visibleRect.size.height = scrollView.bounds.size.height / zoomScale;
    
    // Calculate which chunk is at the center of the visible area
    int centerChunkX = (int)(CGRectGetMidX(visibleRect) / chunkPixels);
    int centerChunkY = (int)(CGRectGetMidY(visibleRect) / chunkPixels);
    
    // Calculate top-left chunk to render (center minus half of visible chunks)
    int startChunkX = centerChunkX - self.visibleChunksWide / 2;
    int startChunkY = centerChunkY - self.visibleChunksHigh / 2;
    
    // Clamp to valid range
    int maxChunkX = (SUPERCHUNKSIZE * MAPSIZE) - self.visibleChunksWide;
    int maxChunkY = (SUPERCHUNKSIZE * MAPSIZE) - self.visibleChunksHigh;
    startChunkX = MAX(0, MIN(startChunkX, maxChunkX));
    startChunkY = MAX(0, MIN(startChunkY, maxChunkY));
    
    // Only update if the chunk origin changed
    if (startChunkX != (int)self.lastChunkOrigin.x || 
        startChunkY != (int)self.lastChunkOrigin.y) {
        
        self.lastChunkOrigin = CGPointMake(startChunkX, startChunkY);
        
        // Update map view's start point (which chunks to render)
        [mapView setStartPoint:CGPointMake(startChunkX, startChunkY)];
        
        // Position the map view within the container at the correct location
        CGFloat mapX = startChunkX * chunkPixels;
        CGFloat mapY = startChunkY * chunkPixels;
        CGFloat mapWidth = self.visibleChunksWide * chunkPixels;
        CGFloat mapHeight = self.visibleChunksHigh * chunkPixels;
        mapView.frame = CGRectMake(mapX, mapY, mapWidth, mapHeight);
        
        // Mark map as dirty and redraw
        [mapView dirtyMap];
        [mapView setNeedsDisplay];
        
        //NSLog(@"Rendering chunks from (%d, %d), size %dx%d at position (%.0f, %.0f)",startChunkX, startChunkY, self.visibleChunksWide, self.visibleChunksHigh, mapX, mapY);
    }
    
    // Update location label
    self.locationLabel.text = [NSString stringWithFormat:@" Chunk: %d, %d | View: %dx%d ", 
                               centerChunkX, centerChunkY,
                               self.visibleChunksWide, self.visibleChunksHigh];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)sv {
    return self.containerView;
}

- (void)scrollViewDidScroll:(UIScrollView *)sv {
    [self updateMapForCurrentScroll];
}

- (void)scrollViewDidZoom:(UIScrollView *)sv {
    // Store previous chunk counts
    int previousChunksWide = self.visibleChunksWide;
    int previousChunksHigh = self.visibleChunksHigh;
    
    // Recalculate visible chunks based on current zoom
    [self calculateVisibleChunksForSize:self.view.bounds.size];
    
    // Check if chunk count changed - this is the key for performance
    if (self.visibleChunksWide != previousChunksWide || 
        self.visibleChunksHigh != previousChunksHigh) {
        
        // Update map view dimensions
        [mapView setChunkWidth:self.visibleChunksWide];
        [mapView setChunkHeight:self.visibleChunksHigh];
        
        // Resize the map view frame
        CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
        CGFloat mapWidth = self.visibleChunksWide * chunkPixels;
        CGFloat mapHeight = self.visibleChunksHigh * chunkPixels;
        CGFloat mapX = self.lastChunkOrigin.x * chunkPixels;
        CGFloat mapY = self.lastChunkOrigin.y * chunkPixels;
        
        mapView.frame = CGRectMake(mapX, mapY, mapWidth, mapHeight);
        
        // Force full update since dimensions changed
        self.lastChunkOrigin = CGPointMake(-1, -1);
        
        //NSLog(@"Zoom changed chunks: %dx%d -> %dx%d", previousChunksWide, previousChunksHigh, self.visibleChunksWide, self.visibleChunksHigh);
    }
    
    [self updateMapForCurrentScroll];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)sv {
    [self updateMapForCurrentScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self updateMapForCurrentScroll];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)sv withView:(UIView *)view atScale:(CGFloat)scale {
    // Final update after zoom completes
    [self handleViewSizeChange];
}

#pragma mark - Tap Gesture Handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // Allow tap to work with other gestures
    if ([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]]) {
        return YES;
    }
    // Allow long press to work with scroll
    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    // Don't allow simultaneous pan when we're dragging a shape
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        return NO; // We want our pan to be exclusive when dragging
    }
    return YES;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    // For pan gesture, only begin if we have a selected shape at the touch point
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        CGPoint locationInContainer = [gestureRecognizer locationInView:self.containerView];
        CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
        
        CGFloat mapViewX = locationInContainer.x - (self.lastChunkOrigin.x * chunkPixels);
        CGFloat mapViewY = locationInContainer.y - (self.lastChunkOrigin.y * chunkPixels);
        CGPoint locationInMapView = CGPointMake(mapViewX, mapViewY);
        
        NSArray *selectedShapes = [mapView getSelectedShapes];
        if ([selectedShapes count] > 0) {
            U7ShapeReference *shapeAtLocation = [mapView shapeAtViewLocation:locationInMapView];
            if (shapeAtLocation) {
                // Check if it matches any selected shape
                for (U7ShapeReference *selectedShape in selectedShapes) {
                    if (selectedShape->shapeID == shapeAtLocation->shapeID &&
                        selectedShape->parentChunkXCoord == shapeAtLocation->parentChunkXCoord &&
                        selectedShape->parentChunkYCoord == shapeAtLocation->parentChunkYCoord &&
                        selectedShape->parentChunkID == shapeAtLocation->parentChunkID) {
                        NSLog(@"gestureRecognizerShouldBegin: YES - on selected shape");
                        return YES; // Allow pan to begin - we're on a selected shape
                    }
                }
            }
        }
        NSLog(@"gestureRecognizerShouldBegin: NO - not on selected shape");
        return NO; // Don't intercept pan if not on selected shape
    }
    return YES;
}

- (void)handleTap:(UITapGestureRecognizer *)recognizer {
    // Short click moves actor if on screen
    
    // Get tap location in container view coordinates (the full map space)
    CGPoint locationInContainer = [recognizer locationInView:self.containerView];
    
    // Convert to chunk coordinates
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    
    // Get position within the map view (which only shows a portion of the map)
    // The map view starts at lastChunkOrigin, so we need to offset
    CGFloat mapViewX = locationInContainer.x - (self.lastChunkOrigin.x * chunkPixels);
    CGFloat mapViewY = locationInContainer.y - (self.lastChunkOrigin.y * chunkPixels);
    
    CGPoint locationInMapView = CGPointMake(mapViewX, mapViewY);
    
    // Check if tap is within the map view bounds
    if (mapViewX < 0 || mapViewY < 0 || 
        mapViewX >= mapView.frame.size.width || 
        mapViewY >= mapView.frame.size.height) {
        NSLog(@"Tap outside map view bounds");
        return;
    }
    
    // Convert to global tile coordinates
    CGPoint globalTile = [mapView viewLocationToGlobalTile:locationInMapView];
    
    // Check if we have a user actor - if so, move to target location
    if (self.userActor) {
        // Check if the target location is passable
        if ([mapView->map isPassable:globalTile]) {
            // Get the action manager
            BAActionManager *manager = self.userActor->aiManager->actionManager;
            
            // Clear any current action and reset path to start fresh
            [manager resetPath];
            [manager->currentSequence clear];
            
            // Create a new move action
            BASpriteAction *moveAction = [[BASpriteAction alloc] init];
            [moveAction setActionType:MoveActionType];
            [moveAction setTargetLocation:globalTile];
            
            // Set as the current action
            manager->currentAction = moveAction;
            manager->actionSequenceComplete = NO;
            
            NSLog(@"Set actor target to tile (%.0f, %.0f)", globalTile.x, globalTile.y);
            
            [mapView dirtyMap];
            [mapView setNeedsDisplay];
        } else {
            NSLog(@"Target location (%.0f, %.0f) is not passable", globalTile.x, globalTile.y);
        }
    } else {
        NSLog(@"No actor on screen - use double-tap to place actor");
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state != UIGestureRecognizerStateBegan) return;
    
    // Get location in container view coordinates
    CGPoint locationInContainer = [recognizer locationInView:self.containerView];
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    
    // Get position within the map view
    CGFloat mapViewX = locationInContainer.x - (self.lastChunkOrigin.x * chunkPixels);
    CGFloat mapViewY = locationInContainer.y - (self.lastChunkOrigin.y * chunkPixels);
    CGPoint locationInMapView = CGPointMake(mapViewX, mapViewY);
    
    // Check if tap is within the map view bounds
    if (mapViewX < 0 || mapViewY < 0 || 
        mapViewX >= mapView.frame.size.width || 
        mapViewY >= mapView.frame.size.height) {
        NSLog(@"Long press outside map view bounds");
        return;
    }
    
    // Try to select a shape at this location
    [mapView toggleShapeSelectionAtViewLocation:locationInMapView];
    
    // Log selected shapes
    NSArray *selectedShapes = [mapView getSelectedShapes];
    if ([selectedShapes count] > 0) {
        NSLog(@"Long press selected %lu shape(s)", (unsigned long)[selectedShapes count]);
    } else {
        NSLog(@"No shape at long press location");
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer {
    // Double-tap: places actor at location
    NSLog(@"handleDoubleTap called!");
    
    // Get location in container view coordinates
    CGPoint locationInContainer = [recognizer locationInView:self.containerView];
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    
    NSLog(@"Location in container: (%.0f, %.0f)", locationInContainer.x, locationInContainer.y);
    
    // Get position within the map view
    CGFloat mapViewX = locationInContainer.x - (self.lastChunkOrigin.x * chunkPixels);
    CGFloat mapViewY = locationInContainer.y - (self.lastChunkOrigin.y * chunkPixels);
    CGPoint locationInMapView = CGPointMake(mapViewX, mapViewY);
    
    // Check if tap is within the map view bounds
    if (mapViewX < 0 || mapViewY < 0 || 
        mapViewX >= mapView.frame.size.width || 
        mapViewY >= mapView.frame.size.height) {
        NSLog(@"Double-tap outside map view bounds");
        return;
    }
    
    // Convert to global tile coordinates
    CGPoint globalTile = [mapView viewLocationToGlobalTile:locationInMapView];
    
    // Check if location is passable
    if (![mapView->map isPassable:globalTile]) {
        NSLog(@"Cannot place actor at impassable location (%.0f, %.0f)", globalTile.x, globalTile.y);
        return;
    }
    
    // If we have an existing actor, remove it first
    if (self.userActor) {
        // Remove actor from map (this handles removing from actors array)
        [mapView->map removeActorAtLocation:self.userActor->globalLocation forActor:self.userActor];
        
        // Also remove the sprite/shape reference from the appropriate map chunk
        if (self.userActor->shapeReference) {
            [mapView->map removeSpriteAtLocation:self.userActor->globalLocation forSprite:self.userActor];
        }
        
        // Clear sprites from map view cache
        [mapView removeSpritesFromMap];
        
        NSLog(@"Removed previous user actor");
        self.userActor = nil;
    }
    
    // Create new user actor at location
    self.userActor = [mapView randomActor:AvatarMaleCharacterSprite useRandomSprite:NO forLocation:globalTile];
    
    // Disable AI - we control this actor manually via taps
    self.userActor->aiManager->AIEnabled = NO;
    
    // Set initial action to idle
    BAActionManager *manager = self.userActor->aiManager->actionManager;
    [manager->currentAction setActionType:IdleActionType];
    [manager->currentAction setComplete:NO];
    
    NSLog(@"Placed user actor at tile (%.0f, %.0f)", globalTile.x, globalTile.y);
    
    [mapView dirtyMap];
    [mapView setNeedsDisplay];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint locationInContainer = [recognizer locationInView:self.containerView];
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    
    // Convert to map view coordinates
    CGFloat mapViewX = locationInContainer.x - (self.lastChunkOrigin.x * chunkPixels);
    CGFloat mapViewY = locationInContainer.y - (self.lastChunkOrigin.y * chunkPixels);
    CGPoint locationInMapView = CGPointMake(mapViewX, mapViewY);
    
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan: {
            // Check if we're starting on a selected shape
            NSArray *selectedShapes = [mapView getSelectedShapes];
            NSLog(@"Pan began - selected shapes count: %lu", (unsigned long)[selectedShapes count]);
            
            if ([selectedShapes count] > 0) {
                // Check if pan started on the selected shape
                U7ShapeReference *shapeAtLocation = [mapView shapeAtViewLocation:locationInMapView];
                NSLog(@"Shape at pan location: %@, shapeID: %ld", shapeAtLocation, shapeAtLocation ? (long)shapeAtLocation->shapeID : -1);
                
                if (shapeAtLocation) {
                    // Check if it's the same shape (by comparing shapeID and position)
                    for (U7ShapeReference *selectedShape in selectedShapes) {
                        NSLog(@"Comparing with selected shape ID: %ld at (%d, %d)", 
                              (long)selectedShape->shapeID, 
                              selectedShape->parentChunkXCoord, 
                              selectedShape->parentChunkYCoord);
                        
                        if (selectedShape->shapeID == shapeAtLocation->shapeID &&
                            selectedShape->parentChunkXCoord == shapeAtLocation->parentChunkXCoord &&
                            selectedShape->parentChunkYCoord == shapeAtLocation->parentChunkYCoord &&
                            selectedShape->parentChunkID == shapeAtLocation->parentChunkID) {
                            
                            self.isDraggingShape = YES;
                            self.draggedShape = selectedShape;
                            self.dragStartLocation = locationInMapView;
                            
                            // Disable scroll view scrolling while dragging
                            scrollView.scrollEnabled = NO;
                            
                            NSLog(@"Started dragging shape %ld", (long)self.draggedShape->shapeID);
                            break;
                        }
                    }
                }
                
                if (!self.isDraggingShape) {
                    NSLog(@"Pan started but not on selected shape");
                }
            } else {
                self.isDraggingShape = NO;
            }
            break;
        }
            
        case UIGestureRecognizerStateChanged: {
            if (self.isDraggingShape && self.draggedShape) {
                // Calculate tile offset from drag start
                CGFloat tileSize = TILESIZE * mapView->mapScale;
                
                CGFloat deltaX = locationInMapView.x - self.dragStartLocation.x;
                CGFloat deltaY = locationInMapView.y - self.dragStartLocation.y;
                
                int tileDeltaX = (int)(deltaX / tileSize);
                int tileDeltaY = (int)(deltaY / tileSize);
                
                // Only update if moved at least one tile
                if (tileDeltaX != 0 || tileDeltaY != 0) {
                    // Calculate current global tile position
                    // parentChunkID is calculated as: chunkX + (chunkY * chunksPerRow)
                    long chunksPerRow = SUPERCHUNKSIZE * MAPSIZE;  // 192 chunks
                    long chunkX = self.draggedShape->parentChunkID % chunksPerRow;
                    long chunkY = self.draggedShape->parentChunkID / chunksPerRow;
                    
                    CGPoint currentGlobalTile = CGPointMake(
                        chunkX * CHUNKSIZE + self.draggedShape->parentChunkXCoord,
                        chunkY * CHUNKSIZE + self.draggedShape->parentChunkYCoord
                    );
                    
                    // Calculate new global tile position
                    CGPoint newGlobalTile = CGPointMake(
                        currentGlobalTile.x + tileDeltaX,
                        currentGlobalTile.y + tileDeltaY
                    );
                    
                    NSLog(@"Drag: chunkID=%ld, chunk(%ld,%ld), local(%d,%d), global(%.0f,%.0f) -> (%.0f,%.0f)",
                          self.draggedShape->parentChunkID,
                          chunkX, chunkY,
                          self.draggedShape->parentChunkXCoord, self.draggedShape->parentChunkYCoord,
                          currentGlobalTile.x, currentGlobalTile.y,
                          newGlobalTile.x, newGlobalTile.y);
                    
                    // Use the moveShape method that handles chunk transitions
                    [mapView moveShape:self.draggedShape toGlobalTileLocation:newGlobalTile];
                    
                    // Update drag start for next delta
                    self.dragStartLocation = CGPointMake(
                        self.dragStartLocation.x + (tileDeltaX * tileSize),
                        self.dragStartLocation.y + (tileDeltaY * tileSize)
                    );
                    
                    // Redraw
                    [mapView dirtyMap];
                    [mapView setNeedsDisplay];
                }
            }
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            if (self.isDraggingShape) {
                NSLog(@"Finished dragging shape %ld to (%d, %d)", 
                      (long)self.draggedShape->shapeID,
                      self.draggedShape->parentChunkXCoord,
                      self.draggedShape->parentChunkYCoord);
                
                // Re-enable scroll view scrolling
                scrollView.scrollEnabled = YES;
                
                self.isDraggingShape = NO;
                self.draggedShape = nil;
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - Timer Callbacks

- (void)refresh {
    [mapView setNeedsDisplay];
    
    // Smooth scroll to follow actor if enabled
    if (self.followActor && self.userActor) {
        [self centerOnActor:NO];
    }
}

- (void)centerOnActor:(BOOL)animated {
    if (!self.userActor) return;
    
    CGFloat chunkPixels = CHUNKSIZE * TILESIZE * TILEPIXELSCALE;
    CGFloat zoomScale = scrollView.zoomScale;
    
    // Get actor's global tile position and convert to content coordinates
    CGPoint actorTile = self.userActor->globalLocation;
    CGFloat actorContentX = actorTile.x * TILESIZE * TILEPIXELSCALE;
    CGFloat actorContentY = actorTile.y * TILESIZE * TILEPIXELSCALE;
    
    // Calculate the content offset needed to center the actor in the view
    CGFloat viewWidth = scrollView.bounds.size.width;
    CGFloat viewHeight = scrollView.bounds.size.height;
    
    // Target offset centers the actor (accounting for zoom)
    CGFloat targetOffsetX = (actorContentX * zoomScale) - (viewWidth / 2.0);
    CGFloat targetOffsetY = (actorContentY * zoomScale) - (viewHeight / 2.0);
    
    // Clamp to valid scroll bounds
    CGFloat maxOffsetX = scrollView.contentSize.width * zoomScale - viewWidth;
    CGFloat maxOffsetY = scrollView.contentSize.height * zoomScale - viewHeight;
    targetOffsetX = MAX(0, MIN(targetOffsetX, maxOffsetX));
    targetOffsetY = MAX(0, MIN(targetOffsetY, maxOffsetY));
    
    CGPoint targetOffset = CGPointMake(targetOffsetX, targetOffsetY);
    
    if (animated) {
        // Immediate animated scroll when toggling on
        [UIView animateWithDuration:0.3 animations:^{
            self->scrollView.contentOffset = targetOffset;
        }];
    } else {
        // Smooth interpolation for continuous following
        CGPoint currentOffset = scrollView.contentOffset;
        CGFloat smoothFactor = 0.15; // Adjust for smoother/snappier following
        
        CGFloat newOffsetX = currentOffset.x + (targetOffset.x - currentOffset.x) * smoothFactor;
        CGFloat newOffsetY = currentOffset.y + (targetOffset.y - currentOffset.y) * smoothFactor;
        
        // Only update if we've moved enough to matter (avoid micro-jitter)
        CGFloat deltaX = fabs(newOffsetX - currentOffset.x);
        CGFloat deltaY = fabs(newOffsetY - currentOffset.y);
        
        if (deltaX > 0.5 || deltaY > 0.5) {
            scrollView.contentOffset = CGPointMake(newOffsetX, newOffsetY);
        }
    }
}

- (void)cyclePallet {
    palletCycle++;
    [mapView setPalletCycle:palletCycle];
}

@end
