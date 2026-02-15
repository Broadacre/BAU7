//
//  InfiniteMapViewController.h
//  BAU7
//
//  Created by Dan Brooker on 11/12/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@interface MapScrollView : UIScrollView <UIScrollViewDelegate>
{
    @public
    BAMapView *mapView;
}
@end

@interface InfiniteMapViewController : UIViewController
{
    IBOutlet MapScrollView * scrollView;
}
@end

NS_ASSUME_NONNULL_END
