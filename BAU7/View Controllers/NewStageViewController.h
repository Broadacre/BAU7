//
//  NewStageViewController.h
//  BAU7
//
//  Created by Dan Brooker on 3/25/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NewStageViewController : UIViewController <UIScrollViewDelegate>
{
    BAMapView * stageMap;
    CGPoint mapLocation;
    NSMutableArray * rectArray;  // for dungeon generation
    IBOutlet UILabel * spritesLabel;
    
    IBOutlet UIScrollView * scrollView;
    NSArray* triggeredSpawns;
    
    BOOL isDraggingShape;  // Track if we're currently dragging a selected shape
}
-(IBAction)toggleDrawPassability:(id)sender;
-(IBAction)toggleDrawChunkHighlite:(id)sender;
-(IBAction)toggleDrawEnvironmentMap:(id)sender;
-(IBAction)reset:(id)sender;
-(void)updateActorsLabel;
-(void)handlesSpawns;
@end

NS_ASSUME_NONNULL_END
