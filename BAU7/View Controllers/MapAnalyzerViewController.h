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

// Chunk classifier UI
@property (nonatomic, strong) UIView *classifierPanel;
@property (nonatomic, strong) UIImageView *chunkPreviewView; // Single chunk preview
@property (nonatomic, strong) UIImageView *chunkGridView;  // 3×3 chunk context grid
@property (nonatomic, strong) UILabel *chunkInfoLabel;
@property (nonatomic, strong) UILabel *progressLabel;
@property (nonatomic, strong) NSMutableDictionary *chunkClassifications; // masterChunkID → terrain category
@property (nonatomic, strong) NSMutableDictionary *masterChunkHistogram; // masterChunkID → {count, exampleX, exampleY}
@property (nonatomic, strong) NSArray *sortedMasterChunkIDs; // sorted by occurrence count
@property (nonatomic, assign) NSInteger currentChunkIndex;

// Old terrain mapping system (still used by export/load methods)
@property (nonatomic, strong) NSMutableDictionary *terrainMappings;
@property (nonatomic, strong) NSArray *unknownCombos;
@property (nonatomic, assign) NSInteger currentComboIndex;

@end
