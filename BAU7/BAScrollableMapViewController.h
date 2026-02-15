//
//  BAScrollableMapViewController.h
//  BAU7
//
//  Created by Dan Brooker on 11/19/25.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class U7Environment;
@class BAMapView;

@interface BAScrollableMapViewController : UIViewController <UIScrollViewDelegate>
{
    @public
    U7Environment *u7Env;
    BAMapView *mapView;
    
    IBOutlet UIScrollView *scrollView;
    
    int maxHeight;
    unsigned int palletCycle;
}

// Height controls
- (IBAction)incrementMaxHeight:(id)sender;
- (IBAction)decrementMaxHeight:(id)sender;

// Drawing toggles
- (IBAction)toggleDrawTiles:(id)sender;
- (IBAction)toggleDrawGroundObjects:(id)sender;
- (IBAction)toggleDrawGameObjects:(id)sender;
- (IBAction)toggleDrawStaticObjects:(id)sender;
- (IBAction)toggleDrawPassability:(id)sender;

// Zoom controls
- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)resetZoom:(id)sender;

// Navigation
- (void)scrollToLocation:(CGPoint)globalTileLocation animated:(BOOL)animated;
- (void)scrollToChunk:(CGPoint)chunkCoordinate animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
