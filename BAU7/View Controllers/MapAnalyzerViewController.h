//
//  MapAnalyzerViewController.h
//  BAU7
//
//  Created by Tom on 2/16/26.
//

#import <UIKit/UIKit.h>
#import "Includes.h"

@interface MapAnalyzerViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) UIScrollView *heatMapScrollView;
@property (nonatomic, strong) UIImageView *heatMapImageView;
@property (nonatomic, strong) UITextView *resultsTextView;
@property (nonatomic, strong) UIButton *analyzeButton;
@property (nonatomic, strong) UIButton *exportButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSDictionary *analysisResults;

@end
