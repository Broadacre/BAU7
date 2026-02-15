//
//  BAU7PalletView.h
//  BAU7
//
//  Created by Dan Brooker on 1/8/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BAU7PalletView : UIView
{
    int palletID;
    U7Environment * environment;
    UIColor * palletColor;
    CGRect palletRect;
}

-(void)setPalletID:(int)thePalletID;
-(void)setEnvironment:(U7Environment*)theEnvironment;
@end

NS_ASSUME_NONNULL_END
