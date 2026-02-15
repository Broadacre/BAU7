//
//  NewMapViewController.h
//  BAU7
//
//  Created by Dan Brooker on 11/18/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewMapViewController : UIViewController
{
@public
IBOutlet BAMapView *mapView;
    NSMutableArray *visibleLabels;
    CGPoint mapLocation;
    CGPoint oldPoint;
    CGPoint globalLocation;
    CGPoint oldShift;
    CGPoint shift;
    CGPoint maxOffScreenShift;
    CGPoint mapOrigin;
    BOOL firstLayout;
    int chunksToDraw;
    int chunksHigh;
    int chunksWide;
}
-(IBAction) test;
@end

NS_ASSUME_NONNULL_END
