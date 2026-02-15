//
//  PalletViewController.h
//  BAU7
//
//  Created by Dan Brooker on 1/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PalletViewController : UIViewController
{
    int currentPalletID;
    
    BAU7PalletView * palletView;
    
    IBOutlet UISlider * slider;
    IBOutlet UIButton * incrementButton;
    IBOutlet UIButton * decrementButton;
    IBOutlet UILabel * IDLabel;
}

-(IBAction)incrementID:(id)sender;
-(IBAction)decrementID:(id)sender;
-(IBAction)setPalletID:(id)sender;
@end

NS_ASSUME_NONNULL_END
