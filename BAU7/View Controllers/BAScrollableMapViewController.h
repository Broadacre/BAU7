//
//  BAScrollableMapViewController.h
//  BAU7
//
//  Smooth scrolling map viewer for the entire U7 world
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

@end

NS_ASSUME_NONNULL_END
