//
//  U7ShapeViewController.h
//  U7ShapeViewController
//
//  Created by Dan Brooker on 9/6/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface U7ShapeViewController : UIViewController <UIScrollViewDelegate,UISearchBarDelegate>
{
    @public
    int shapeID;
    int frameNumber;
    BOOL showOrigin;
    BAU7ShapeView * shapeView;
    IBOutlet UIScrollView * scrollview;
    IBOutlet UISlider * slider;
    IBOutlet UISlider * frameSlider;
    IBOutlet UISearchBar * searchbar;
    
    IBOutlet UILabel* widthLabel;
    IBOutlet UILabel* heightLabel;
    
    IBOutlet UILabel* rightXLabel;
    IBOutlet UILabel* leftXLabel;
    IBOutlet UILabel* leftYLabel;
    IBOutlet UILabel* rightYLabel;
    IBOutlet UILabel* animatesLabel;
    IBOutlet UILabel* zHeightLabel;
    IBOutlet UILabel* walkableLabel;
    IBOutlet UILabel* rotatableLabel;
    IBOutlet UILabel* waterLabel;
    IBOutlet UILabel* frameLabel;
    
    
    IBOutlet UILabel* ShapeTypeLabel;
    IBOutlet UILabel* TrapLabel;
    IBOutlet UILabel* DoorLabel;
    IBOutlet UILabel* VehiclePartLabel;
    IBOutlet UILabel* NotSelectableLabel;
    IBOutlet UILabel* TileSizeXMinus1Label;
    IBOutlet UILabel* TileSizeYMinus1Label;
    IBOutlet UILabel* LightSourceLabel;
    IBOutlet UILabel* TranslucentLabel;
    
    NSMutableArray * currentShapeLibrary;
    
    
}
-(IBAction)setFrameNumber:(id)sender;
-(IBAction)setShapeID:(id)sender;
-(IBAction)incrementID:(id)sender;
-(IBAction)decrementID:(id)sender;
-(IBAction)toggleShowOrigin:(id)sender;
-(IBAction)displayU7Shapes:(id)sender;
-(IBAction)displayU7Sprites:(id)sender;
-(IBAction)displayU7Faces:(id)sender;
-(IBAction)displayU7Gumps:(id)sender;
-(IBAction)displayU7Fonts:(id)sender;
@end

NS_ASSUME_NONNULL_END
