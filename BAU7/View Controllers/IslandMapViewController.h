//
//  RandoMapViewController.h
//  BAU7
//
//  Created by Dan Brooker on 10/3/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface IslandMapViewController : BAMapViewController
{
    
    float zoomScale;
    
    //GCController * controller;
    BOOL pressed;
    BAActor * mainCharacter;
}
@property (nonatomic, strong) GCController *controller;

-(IBAction)reset:(id)sender;
@end

NS_ASSUME_NONNULL_END
