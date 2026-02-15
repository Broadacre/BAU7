//
//  U7ShapeViewController.m
//  U7ShapeViewController
//
//  Created by Dan Brooker on 9/6/21.
//
#import "BAU7Objects.h"
#import "BABitmap.h"
#import "Globals.h"
#import "BAU7ShapeView.h"
#import "U7ShapeViewController.h"

@interface U7ShapeViewController ()

@end

@implementation U7ShapeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

       UIMenuItem *menuItem = [[UIMenuItem alloc] initWithTitle:@"Change Color" action:@selector(changeColor:)];
       //[shapeSelectMenu setMenuItems:[NSArray arrayWithObject:menuItem]];
    //[shapeSelectMenu insertChild];

    //[shapeView setNeedsDisplay];
}


-(IBAction)displayU7Shapes:(id)sender
{
    NSLog(@"displayU7Shapes");
    currentShapeLibrary=u7Env->U7Shapes;
    [self setupView];
}

-(IBAction)displayU7Sprites:(id)sender
{
    NSLog(@"displayU7Sprites");
    currentShapeLibrary=u7Env->U7SpriteShapes;
    [self setupView];
}

-(IBAction)displayU7Faces:(id)sender
{
    NSLog(@"displayU7Faces");
    currentShapeLibrary=u7Env->U7FaceShapes;
    [self setupView];
}

-(IBAction)displayU7Gumps:(id)sender
{
    NSLog(@"displayU7Gumps");
    currentShapeLibrary=u7Env->U7GumpShapes;
    [self setupView];
}

-(IBAction)displayU7Fonts:(id)sender
{
    NSLog(@"displayU7Fonts");
    currentShapeLibrary=u7Env->U7FontShapes;
    [self setupView];
}


-(void)viewDidAppear:(BOOL)animated
{
    //[u7view drawRect:CGRectMake(0, 0, 10, 10)];x
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
                        
                        self->currentShapeLibrary=u7Env->U7Shapes;
                        [self setupView];
                        
                        
                        [alertController dismissViewControllerAnimated:YES completion:nil];
                        
                    }];
                    

    }
    else
        [self setupView];
   
}

-(void)setupView
{ 
    shapeID=0;
    //shapeID=AVATARIMAGE;
    //currentShapeLibrary=u7Env->U7SpriteShapes;
    //currentShapeLibrary=u7Env->U7FontShapes;
    frameNumber=0;
    showOrigin=NO;
    NSUInteger shapeCount = [currentShapeLibrary count];
    [slider setMaximumValue:(shapeCount > 0) ? (float)(shapeCount - 1) : 0];
    [slider setMinimumValue:0];
    [slider setValue:0];
    [frameSlider setMinimumValue:0];
    
    [scrollview setMinimumZoomScale:1];
    [scrollview setZoomScale:6];
    [scrollview setMaximumZoomScale:20];
    
    searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    
    [self update];
}

-(void)update
{
    CGFloat currentZoom=[scrollview zoomScale];
    [shapeView removeFromSuperview];
    shapeView=[[BAU7ShapeView alloc]init];
    [shapeView setEnvironment:u7Env];
    [shapeView setShapeLibrary:currentShapeLibrary];
    [shapeView setShapeID:shapeID];
    if([shapeView numberOfFrames])
    {
        shapeView->showOrigin=showOrigin;
        [frameSlider setMaximumValue:[shapeView numberOfFrames]-1];
        [frameSlider setValue:frameNumber];
        NSLog(@"Frames: %li",[shapeView numberOfFrames]);
        [shapeView setFrameNumber:frameNumber];
        
        CGSize size=[shapeView sizeForFrame:frameNumber];
        shapeView.frame=CGRectMake(200, 200, size.width, size.height);
        
        [shapeView setNeedsDisplay];
         //NSLog(@"Rect: %f,%f,%f,%f",shapeView.frame.size.width,shapeView.frame.size.height,shapeView.frame.origin.x,shapeView.frame.origin.y);
        [scrollview addSubview:shapeView];
        [scrollview bringSubviewToFront:shapeView];
        scrollview.contentSize =size;
        [scrollview setZoomScale:currentZoom];
        [self updateLabels];
    }
    
    
}

-(void)updateLabels
{
    U7Shape * shape=shapeView->shape;
    U7Bitmap * bitmap=[shape->frames objectAtIndex:frameNumber];
    
    frameLabel.text=[NSString stringWithFormat:@"Frame: %i (%li total)",frameNumber, [shape numberOfFrames]];
    widthLabel.text=[NSString stringWithFormat:@"Width: %i",bitmap->width];
    heightLabel.text=[NSString stringWithFormat:@"height: %i",bitmap->height];
    rightXLabel.text=[NSString stringWithFormat:@"rightX: %i",bitmap->rightX];
    leftXLabel.text=[NSString stringWithFormat:@"leftX: %i",bitmap->leftX];
    leftYLabel.text=[NSString stringWithFormat:@"topY: %i",bitmap->topY];
    rightYLabel.text=[NSString stringWithFormat:@"bottomY: %i",bitmap->bottomY];
    animatesLabel.text=[NSString stringWithFormat:@"animated: %i",shape->animated];
    zHeightLabel.text=[NSString stringWithFormat:@"zHeight: %i",shape->tileSizeZ];
    walkableLabel.text=[NSString stringWithFormat:@"Not walkable: %i",shape->notWalkable];
    rotatableLabel.text=[NSString stringWithFormat:@"rotatable: %i",shape->rotatable];
    waterLabel.text=[NSString stringWithFormat:@"water: %i",shape->water];
    
    
    ShapeTypeLabel.text=[NSString stringWithFormat:@"shapeType: %i",shape->shapeType];
    TrapLabel.text=[NSString stringWithFormat:@"trap: %i",shape->trap];
    DoorLabel.text=[NSString stringWithFormat:@"door: %i",shape->door];
    VehiclePartLabel.text=[NSString stringWithFormat:@"vehiclePart: %i",shape->vehiclePart];
    NotSelectableLabel.text=[NSString stringWithFormat:@"selectable: %i",shape->selectable];
    TileSizeXMinus1Label.text=[NSString stringWithFormat:@"TileSizeXMinus1: %i",shape->TileSizeXMinus1];
    TileSizeYMinus1Label.text=[NSString stringWithFormat:@"TileSizeYMinus1: %i",shape->TileSizeYMinus1];
    LightSourceLabel.text=[NSString stringWithFormat:@"lightSource: %i",shape->lightSource];
    TranslucentLabel.text=[NSString stringWithFormat:@"translucent: %i",shape->translucent];
    
}


- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return shapeView;
}
-(IBAction)setFrameNumber:(id)sender
{
    frameNumber=frameSlider.value;
    //searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    NSLog(@"setFrameNumber:%i",frameNumber);
    //[shapeView set:shapeID];
    [self update];
}
-(IBAction)setShapeID:(id)sender
{
    shapeID=slider.value;
    searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    frameNumber=0;
    NSLog(@"setShapeID:%i",shapeID);
    //[shapeView setShapeID:shapeID];
    [self update];
}


-(IBAction)toggleShowOrigin:(id)sender
{
    showOrigin=!showOrigin;
    [self update];
}

-(IBAction)incrementID:(id)sender
{
    
    NSUInteger shapeCount = [currentShapeLibrary count];
    if(shapeCount == 0 || (shapeID + 1) >= (NSInteger)(shapeCount - 1))
    {
        
    }
    else
    {
    shapeID++;
        frameNumber=0;
    [slider setValue:shapeID];
    searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    //[shapeView setShapeID:shapeID];
        [self update];
    }
}

-(IBAction)decrementID:(id)sender

{
    
    if((shapeID-1)<0)
    {
        
    }
    else
    {
    shapeID--;
    frameNumber=0;
    searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    //[shapeView setShapeID:shapeID];
    [self update];
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
    
    int theShape=[searchbar.text intValue];
    NSUInteger searchShapeCount = [currentShapeLibrary count];
    if(theShape > 0 && searchShapeCount > 0 && theShape <= (NSInteger)(searchShapeCount - 1))
    {
        shapeID=theShape;
        [slider setValue:shapeID];
        [frameSlider setValue:0];
        //[shapeView setShapeID:shapeID];
        [self update];
    }
    searchbar.text=[NSString stringWithFormat:@"%i",shapeID];
    
    
    
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



@end
