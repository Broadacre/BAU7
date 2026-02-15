//
//  DungeonGenerationViewController.m
//  BAU7
//
//  Created by Dan Brooker on 7/14/22.
//
#import "Includes.h"
#import "BADungeonGenerationView.h"
#import "DungeonGenerationViewController.h"

#define REFRESHRATE .01
@interface DungeonGenerationViewController ()

@end

@implementation DungeonGenerationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dungeonGenView=[[BADungeonGenerationView alloc]init];
    
    CGRect newRect=self.view.frame;
    dungeonGenView.frame=newRect;
    dungeonGenView.backgroundColor=[UIColor blackColor];
   // [self.view addSubview:dungeonGenView];
    //[self.view sendSubviewToBack:dungeonGenView];
    
    [scrollView addSubview:dungeonGenView];
    //[scrollView bringSubviewToFront:dungeonGenView];
    scrollView.contentSize = dungeonGenView.frame.size;
    
    [scrollView setMinimumZoomScale:.1];
    [scrollView setZoomScale:3];
    [scrollView setMaximumZoomScale:10];
    
    [self.view bringSubviewToFront:statusStack];
    [self.view bringSubviewToFront:optionsStack];
    
    /**/
    NSTimer* timer=NULL;
    timer= [NSTimer scheduledTimerWithTimeInterval:REFRESHRATE
      target:self
      selector:@selector(update)
      userInfo:nil
      repeats:YES];
     
    [self reset:self];
    [self updateLabels];
    
}

- (UIView*)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    // Return the view that you want to zoom
    return dungeonGenView;
}

-(void)updateLabels
{
    NSString* numberOfRectsString;
    NSString* thresholdString;
    
    numberOfRectsString=[NSString stringWithFormat:@"Number Of Rects: %i",dungeonGenView->dg->numberOfRects ];
    thresholdString=[NSString stringWithFormat:@"Room Threshold: %.1f",dungeonGenView->dg->discardThreshold];
    
    [thresholdLabel setText:thresholdString];
    [numberOfRectsLabel setText:numberOfRectsString];
}

-(IBAction)updateNumberOfRects:(id)sender;
{
    int value=numberOfRectsSlider.value;
    dungeonGenView->dg->numberOfRects=value;
    [dungeonGenView generate];
    [self updateLabels];
    [self reset:self];
    //NSLog(@"value:%i",value);
    //[self update];
}
-(IBAction)updateThreshold:(id)sender
{
    float value=thresholdSlider.value;
    [dungeonGenView->dg setDiscardThreshold:value];
    [dungeonGenView setNeedsDisplay];
    [self updateLabels];
    //[self update];
}

-(IBAction)setDrawDiscards:(id)sender
{
    dungeonGenView->drawDiscards=!dungeonGenView->drawDiscards;
    [self updateLabels];
    [dungeonGenView setNeedsDisplay];
    //[self update];
}

-(IBAction)setDrawMidpoints:(id)sender
{
    dungeonGenView->drawMidPoints=!dungeonGenView->drawMidPoints;
    [dungeonGenView setNeedsDisplay];
    //[self update];
}

-(IBAction)setDrawPassageLines:(id)sender
{
    dungeonGenView->drawPassages=!dungeonGenView->drawPassages;
    [dungeonGenView setNeedsDisplay];
    //[self update];
}

-(IBAction)reset:(id)sender
{
    [dungeonGenView generate];
    [dungeonGenView setNeedsDisplay];
}

-(IBAction)setLiveUpdate:(id)sender
{
    dungeonGenView->live=!dungeonGenView->live;
}

-(void)update
{
    //if(dungeonGenView->dg->generated)
    //NSLog(@"a");
        [dungeonGenView setNeedsDisplay];
    [self updateLabels];
    }


@end
