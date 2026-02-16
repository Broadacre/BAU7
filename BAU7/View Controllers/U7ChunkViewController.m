//
//  u7ChunkViewController.m
//  u7ChunkViewController
//
//  Created by Dan Brooker on 8/29/21.
//
#import "BAU7Objects.h"
#import "BABitmap.h"
#import "Globals.h"
#import "U7ChunkViewController.h"

@interface U7ChunkViewController ()
@property (nonatomic, strong) UILabel *chunkInfoLabel;
@property (nonatomic, strong) UIView *controlsContainerView;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicator;
@end

@implementation U7ChunkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupAppearance];
}

- (void)setupAppearance {
    // Set a nice dark background for the retro game aesthetic
    self.view.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:1.0];
    
    // Style the scroll view
    scrollview.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.08 alpha:1.0];
    scrollview.layer.cornerRadius = 12.0;
    scrollview.layer.borderWidth = 2.0;
    scrollview.layer.borderColor = [UIColor colorWithRed:0.3 green:0.3 blue:0.4 alpha:1.0].CGColor;
    scrollview.clipsToBounds = YES;
    
    // Add subtle shadow to scroll view
    scrollview.layer.shadowColor = [UIColor blackColor].CGColor;
    scrollview.layer.shadowOffset = CGSizeMake(0, 4);
    scrollview.layer.shadowOpacity = 0.5;
    scrollview.layer.shadowRadius = 8;
    scrollview.layer.masksToBounds = NO;
    
    // Style the slider
    [self styleSlider:slider];
    
    // Style the search bar
    [self styleSearchBar:searchbar];
    
    // Add chunk info label
    [self setupChunkInfoLabel];
    
    // Style navigation buttons if they exist
    [self styleNavigationButtons];
}

- (void)styleSlider:(UISlider *)theSlider {
    if (!theSlider) return;
    
    theSlider.minimumTrackTintColor = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0];
    theSlider.maximumTrackTintColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
    theSlider.thumbTintColor = [UIColor colorWithRed:0.5 green:0.7 blue:1.0 alpha:1.0];
}

- (void)styleSearchBar:(UISearchBar *)theSearchBar {
    if (!theSearchBar) return;
    
    theSearchBar.searchBarStyle = UISearchBarStyleMinimal;
    theSearchBar.barTintColor = [UIColor clearColor];
    theSearchBar.tintColor = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0];
    
    // Style the text field inside search bar
    UITextField *searchTextField = theSearchBar.searchTextField;
    searchTextField.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.2 alpha:1.0];
    searchTextField.textColor = [UIColor whiteColor];
    searchTextField.attributedPlaceholder = [[NSAttributedString alloc] 
        initWithString:@"Chunk ID" 
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:0.5 alpha:1.0]}];
    searchTextField.layer.cornerRadius = 8.0;
    searchTextField.layer.masksToBounds = YES;
    searchTextField.keyboardAppearance = UIKeyboardAppearanceDark;
}

- (void)setupChunkInfoLabel {
    self.chunkInfoLabel = [[UILabel alloc] init];
    self.chunkInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.chunkInfoLabel.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightMedium];
    self.chunkInfoLabel.textColor = [UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0];
    self.chunkInfoLabel.textAlignment = NSTextAlignmentCenter;
    self.chunkInfoLabel.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.15 alpha:0.9];
    self.chunkInfoLabel.layer.cornerRadius = 6.0;
    self.chunkInfoLabel.clipsToBounds = YES;
    
    [self.view addSubview:self.chunkInfoLabel];
    
    // Position at bottom of scroll view
    [NSLayoutConstraint activateConstraints:@[
        [self.chunkInfoLabel.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.chunkInfoLabel.bottomAnchor constraintEqualToAnchor:scrollview.bottomAnchor constant:-8],
        [self.chunkInfoLabel.widthAnchor constraintGreaterThanOrEqualToConstant:120],
        [self.chunkInfoLabel.heightAnchor constraintEqualToConstant:28]
    ]];
}

- (void)styleNavigationButtons {
    // Find and style any buttons in the view
    for (UIView *subview in self.view.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [self styleButton:button];
        }
    }
}

- (void)styleButton:(UIButton *)button {
    button.backgroundColor = [UIColor colorWithRed:0.2 green:0.2 blue:0.3 alpha:1.0];
    button.layer.cornerRadius = 8.0;
    button.layer.borderWidth = 1.0;
    button.layer.borderColor = [UIColor colorWithRed:0.3 green:0.4 blue:0.6 alpha:1.0].CGColor;
    [button setTitleColor:[UIColor colorWithRed:0.6 green:0.8 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithRed:0.8 green:0.9 blue:1.0 alpha:1.0] forState:UIControlStateHighlighted];
}

- (void)updateChunkInfoLabel {
    if (self.chunkInfoLabel && u7Env) {
        self.chunkInfoLabel.text = [NSString stringWithFormat:@" Chunk %d / %ld ", 
                                    chunkID, 
                                    (long)[u7Env numberOfRawChunks] - 1];
    }
}


-(void)viewDidAppear:(BOOL)animated
{
    if(!u7Env)
    {
        NSLog(@"u7Env is still loading, waiting for notification...");
        
        UIAlertController *alertController = [UIAlertController
                                              alertControllerWithTitle:@"Loading U7 Environment"
                                              message:@"Please wait..."
                                              preferredStyle:UIAlertControllerStyleAlert];
        
        UIViewController *topController = [UIApplication sharedApplication].keyWindow.rootViewController;
        while (topController.presentedViewController)
        {
            topController = topController.presentedViewController;
        }
        
        [topController presentViewController:alertController animated:YES completion:nil];
        
        // Wait for environment to finish loading
        [[NSNotificationCenter defaultCenter] addObserverForName:@"U7EnvironmentReady"
                                                           object:nil
                                                            queue:[NSOperationQueue mainQueue]
                                                       usingBlock:^(NSNotification *note) {
            NSLog(@"U7 Environment ready, setting up chunk view");
            [alertController dismissViewControllerAnimated:YES completion:^{
                [self setupView];
            }];
        }];
    }
    else
    {
        [self setupView];
    }
}
-(void)setupView
{
    //[u7view drawRect:CGRectMake(0, 0, 10, 10)];
    if(!self->U7ChunkView)
    {
        chunkID=0;
        U7ChunkView=[[BAU7ChunkView alloc]init];
        U7ChunkView->environment=u7Env;
        [U7ChunkView setDrawStyle:drawRawChunkStyle];
        [U7ChunkView setChunkID:2];
        [U7ChunkView setMapLocation:CGPointMake(50, 70)];
        CGRect rect=self.view.frame;
        U7ChunkView.frame=rect;
        
        [scrollview addSubview:U7ChunkView];
        [scrollview bringSubviewToFront:U7ChunkView];
        scrollview.contentSize = CGSizeMake(CHUNKSIZE*TILESIZE*TILEPIXELSCALE,CHUNKSIZE*TILESIZE*TILEPIXELSCALE);
        
        [slider setMaximumValue:[u7Env numberOfRawChunks]-1];
        [slider setMinimumValue:0];
        [slider setValue:0];
        
        
        searchbar.text=[NSString stringWithFormat:@"%i",chunkID];
        
        
        [scrollview setMinimumZoomScale:.1];
        [scrollview setZoomScale:6];
        [scrollview setMaximumZoomScale:10];
        [U7ChunkView setNeedsDisplay];
    }
}


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return U7ChunkView;
}

-(IBAction)setChunkID:(id)sender
{
    chunkID=slider.value;
    searchbar.text=[NSString stringWithFormat:@"%i",chunkID];
    NSLog(@"setchunkId:%i",chunkID);
    
    [U7ChunkView setChunkID:chunkID];
    [U7ChunkView setNeedsDisplay];
}

-(IBAction)incrementID:(id)sender
{
    
    if((chunkID+1)>=[u7Env numberOfRawChunks]-1)
    {
        
    }
    else
    {
    chunkID++;
    [slider setValue:chunkID];
    searchbar.text=[NSString stringWithFormat:@"%i",chunkID];
    [U7ChunkView setChunkID:chunkID];
    [U7ChunkView setNeedsDisplay];
    }
}

-(IBAction)decrementID:(id)sender

{
    
    if((chunkID-1)<0)
    {
        
    }
    else
    {
    chunkID--;
    [slider setValue:chunkID];
    searchbar.text=[NSString stringWithFormat:@"%i",chunkID];
    [U7ChunkView setChunkID:chunkID];
    [U7ChunkView setNeedsDisplay];
    }
}

#pragma mark - Search



- (void) performSearch {
    NSLog(@"%s",__FUNCTION__);
    //searchResultList=NULL;
    //searchResultList=listFromName(theSearchBar.text);
    //[searchResultList dump];
    //[self performSegueWithIdentifier: @"showItemSelection" sender: self];
    
    //[autocompleteDataSource removeAllObjects];
    //autocompleteTableView.hidden = YES;
    
    int theChunk=[searchbar.text intValue];
    if(theChunk>0&&theChunk<=([u7Env numberOfRawChunks]-1))
    {
        chunkID=theChunk;
        [slider setValue:chunkID];
        [U7ChunkView setChunkID:chunkID];
        [U7ChunkView setNeedsDisplay];
    }
    searchbar.text=[NSString stringWithFormat:@"%i",chunkID];
    
    
    
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
    NSLog(@"%s",__FUNCTION__);
    [searchBar setShowsCancelButton:YES animated:YES];
    
    //autocompleteTableView.hidden = NO;
    //segmentedControl.enabled=YES;
   // lightButton.enabled=NO;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"%s",__FUNCTION__);
    searchbar.text=@"";
    
    //[autocompleteDataSource->theList removeAllObjects];
    //[autocompleteTableView reloadData];
    //autocompleteTableView.hidden = YES;
    
    //segmentedControl.enabled=NO;;
    
   // lightButton.enabled=YES;
    [searchbar setShowsCancelButton:NO animated:YES];
    [searchbar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"%s",__FUNCTION__);
    
    //NSLog(@"Number of Items: %li",(unsigned long)[autocompleteDataSource count ]);
    //if (searchBar.text.length < 3) {return;}
    //else
    {
        [searchbar setShowsCancelButton:NO animated:YES];
        [searchbar resignFirstResponder];
        
        [self performSearch];
    
    //[autocompleteDataSource removeAllObjects];
   // autocompleteTableView.hidden = YES;
   //     segmentedControl.enabled=NO;
   //     lightButton.enabled=YES;
    }
    
}
    
    -(BOOL)searchBar:(UISearchBar*)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(nonnull NSString *)text
    {
    NSLog(@"%s",__FUNCTION__);
    //autocompleteTableView.hidden = NO;
    //    segmentedControl.enabled=YES;
    //    lightButton.enabled=NO;
    
    NSString *substring = [NSString stringWithString:searchBar.text];
    substring = [substring
                 stringByReplacingCharactersInRange:range withString:text];
    //[self searchAutocompleteEntriesWithSubstring:substring];
    return YES;
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
