//
//  PalletViewController.m
//  BAU7
//
//  Created by Dan Brooker on 1/8/23.
//

#import "BAU7Objects.h"
#import "BABitmap.h"
#import "Globals.h"
#import "BAU7PalletView.h"
#import "PalletViewController.h"

@interface PalletViewController ()

@end

@implementation PalletViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    currentPalletID=0;
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    
    if(!u7Env)
    {
       
        UIAlertController *alertController = [UIAlertController
                                                          alertControllerWithTitle:@"Loading U7 Environment"
                                                          message:@"This may take a while"
                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController)
            {
            topController = topController.presentedViewController;
            }
        [topController presentViewController:alertController animated:YES completion:^{
        u7Env=[[U7Environment alloc]init];
        [self setupView];
        [alertController dismissViewControllerAnimated:YES completion:nil];
        }];
    }
    else
        [self setupView];
    
    
}

-(void)setupView
{
    palletView=[[BAU7PalletView alloc]init];
    [palletView setEnvironment:u7Env];
    CGRect rect=self.view.frame;
    //CGSize size=contentView.frame.size;
    palletView.frame=rect;
    
    [self.view addSubview:palletView];
    [self.view bringSubviewToFront:palletView];
    
    [self.view bringSubviewToFront:incrementButton];
    [self.view bringSubviewToFront:decrementButton];
    [self.view bringSubviewToFront:slider];
    [self.view bringSubviewToFront:IDLabel];
    
    
    [self update];
    
}

-(void)update
{
    
    NSLog(@"currentPalletID:%i",currentPalletID);
    [IDLabel setText:[NSString stringWithFormat:@"%i",currentPalletID]];
    [palletView setPalletID:currentPalletID];
    [palletView setNeedsDisplay];
}

-(IBAction)incrementID:(id)sender
{
    if(currentPalletID<255)
        currentPalletID++;
    [self update];
}

-(IBAction)decrementID:(id)sender
{
    if(currentPalletID>0)
        currentPalletID--;
    [self update];
}


-(IBAction)setPalletID:(id)sender
{
    currentPalletID=slider.value;
    //searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    //frameNumber=0;
    //[shapeView setShapeID:shapeID];
    [self update];
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
