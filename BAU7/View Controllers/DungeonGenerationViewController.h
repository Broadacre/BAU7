//
//  DungeonGenerationViewController.h
//  BAU7
//
//  Created by Dan Brooker on 7/14/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DungeonGenerationViewController : UIViewController <UIScrollViewDelegate>

{
    BADungeonGenerationView * dungeonGenView;
    IBOutlet UIScrollView * scrollView;
    IBOutlet UIStackView * statusStack;
    IBOutlet UIStackView * optionsStack;
    IBOutlet UISlider * thresholdSlider;
    IBOutlet UISlider * numberOfRectsSlider;
    
    IBOutlet UILabel *thresholdLabel;
    IBOutlet UILabel *numberOfRectsLabel;
}
-(IBAction)setDrawDiscards:(id)sender;
-(IBAction)setDrawMidpoints:(id)sender;
-(IBAction)setDrawPassageLines:(id)sender;
-(IBAction)updateThreshold:(id)sender;
-(IBAction)updateNumberOfRects:(id)sender;
-(IBAction)reset:(id)sender;
-(IBAction)setLiveUpdate:(id)sender;
@end

NS_ASSUME_NONNULL_END
