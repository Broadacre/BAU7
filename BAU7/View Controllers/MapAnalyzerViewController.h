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
@property (nonatomic, strong) UIButton *exportMappingsButton;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) NSDictionary *analysisResults;

// Terrain classifier UI
@property (nonatomic, strong) UIView *classifierPanel;
@property (nonatomic, strong) UIImageView *chunkPreviewView;
@property (nonatomic, strong) UIImageView *enlargedTileView;
@property (nonatomic, strong) UILabel *shapeInfoLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) NSMutableDictionary *terrainMappings;
@property (nonatomic, strong) NSArray *unknownCombos;
@property (nonatomic, assign) NSInteger currentComboIndex;

@end
