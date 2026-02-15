//
//  ViewController.h
//  BAU7
//
//  Created by Dan Brooker on 8/6/21.
//

#import <UIKit/UIKit.h>

enum BAMapType
{
  BAMapTypeNormal=0,
  BAMapTypeRandom=1,
  BAMapTypeIsland=2
    
};

@interface BAMapViewController : UIViewController <UIScrollViewDelegate>

{
    int maxHeight;
    NSMutableArray * U7Tiles;
    NSMutableArray * U7Chunks;
    U7Map * Map;
    NSMutableArray * U7Shapes;
    NSMutableArray * shapeRecords;
    U7Palette * pallet;
    CGPoint mapLocation;
    //UIView * contentView;
    BAMapView * u7view;
    enum BAMapType mapType;
    IBOutlet UIMenu * menu;
    unsigned int palletCycle;
    
    IBOutlet UIScrollView * scrollView;
    
    IBOutlet UISlider * heightSlider;
    IBOutlet UISlider * ySlider;
    IBOutlet UISlider * xSlider;
}
-(IBAction)updateYPos:(id)sender;
-(IBAction)updateXPos:(id)sender;
-(IBAction)mapUp:(id)sender;
-(IBAction)mapDown:(id)sender;
-(IBAction)mapLeft:(id)sender;
-(IBAction)mapRight:(id)sender;
-(IBAction)incrementMaxHeight:(id)sender;
-(IBAction)decrementMaxHeight:(id)sender;
-(IBAction)toggleDrawTiles:(id)sender;
-(IBAction)toggleDrawGroundObjects:(id)sender;
-(IBAction)toggleDrawGameObjects:(id)sender;
-(IBAction)toggleDrawStaticObjects:(id)sender;
-(IBAction)toggleDrawPassability:(id)sender;
-(IBAction)toggleDrawEnvironmentMap:(id)sender;
-(IBAction)toggleDrawTargets:(id)sender;
-(IBAction)toggleDrawChunkHighlite:(id)sender;
-(IBAction)setDrawModeNormal:(id)sender;
-(IBAction)setDrawModeMiniMap:(id)sender;

-(void)setupView;
-(void)specialSetup;
-(void)resetScrollView;
- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer;
- (void) longTouch: (UILongPressGestureRecognizer *)recognizer;

-(CGPoint)globalToViewLocation:(CGPoint)globalLocation;

@end

