//
//  u7ChunkViewController.h
//  u7ChunkViewController
//
//  Created by Dan Brooker on 8/29/21.
//

#import <UIKit/UIKit.h>
#import "includes.h"
#import "BAU7Objects.h"
#import "BAU7ChunkView.h"
#import "BAMapView.h"
NS_ASSUME_NONNULL_BEGIN

@interface U7ChunkViewController : UIViewController <UIScrollViewDelegate,UISearchBarDelegate>
{
    @public
    int chunkID;
    BAU7ChunkView * U7ChunkView;
    IBOutlet UIScrollView * scrollview;
    IBOutlet UISlider * slider;
    IBOutlet UISearchBar * searchbar;
}
-(IBAction)setChunkID:(id)sender;
-(IBAction)incrementID:(id)sender;
-(IBAction)decrementID:(id)sender;

@end

NS_ASSUME_NONNULL_END
