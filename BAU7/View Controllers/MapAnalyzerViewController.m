//
//  MapAnalyzerViewController.m
//  BAU7
//
//  Created by Tom on 2/16/26.
//

#import "Includes.h"
#import "MapAnalyzerViewController.h"
#import "BAMapAnalyzer.h"

@implementation MapAnalyzerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.title = @"Map Analyzer";
    
    // Heat map scroll view (left side)
    _heatMapScrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    _heatMapScrollView.backgroundColor = [UIColor blackColor];
    _heatMapScrollView.minimumZoomScale = 0.5;
    _heatMapScrollView.maximumZoomScale = 4.0;
    _heatMapScrollView.delegate = self;
    _heatMapScrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_heatMapScrollView];
    
    // Heat map image view
    _heatMapImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _heatMapImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_heatMapScrollView addSubview:_heatMapImageView];
    
    // Placeholder image
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(512, 512), NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    [[UIColor darkGrayColor] setFill];
    CGContextFillRect(ctx, CGRectMake(0, 0, 512, 512));
    [[UIColor whiteColor] setStroke];
    CGContextSetLineWidth(ctx, 2.0);
    CGContextStrokeRect(ctx, CGRectMake(0, 0, 512, 512));
    UIImage *placeholder = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    _heatMapImageView.image = placeholder;
    _heatMapImageView.frame = CGRectMake(0, 0, 512, 512);
    _heatMapScrollView.contentSize = CGSizeMake(512, 512);
    
    // Results text view (right side)
    _resultsTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    _resultsTextView.editable = NO;
    _resultsTextView.font = [UIFont fontWithName:@"Menlo" size:11];
    _resultsTextView.text = @"Tap 'Analyze Map' to scan the Ultima VII world and generate a heat map...\n";
    _resultsTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_resultsTextView];
    
    // Analyze button
    _analyzeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_analyzeButton setTitle:@"Analyze Map" forState:UIControlStateNormal];
    [_analyzeButton addTarget:self action:@selector(analyzeMap:) forControlEvents:UIControlEventTouchUpInside];
    _analyzeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_analyzeButton];
    
    // Export button
    _exportButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_exportButton setTitle:@"Export JSON" forState:UIControlStateNormal];
    [_exportButton addTarget:self action:@selector(exportJSON:) forControlEvents:UIControlEventTouchUpInside];
    _exportButton.enabled = NO;
    _exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_exportButton];
    
    // Activity indicator
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicator];
    
    // Layout constraints (split view)
    [NSLayoutConstraint activateConstraints:@[
        // Buttons at top
        [_analyzeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [_analyzeButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        
        [_exportButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [_exportButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // Heat map on left half
        [_heatMapScrollView.topAnchor constraintEqualToAnchor:_analyzeButton.bottomAnchor constant:10],
        [_heatMapScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_heatMapScrollView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.5],
        [_heatMapScrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        
        // Results text on right half
        [_resultsTextView.topAnchor constraintEqualToAnchor:_analyzeButton.bottomAnchor constant:10],
        [_resultsTextView.leadingAnchor constraintEqualToAnchor:_heatMapScrollView.trailingAnchor constant:10],
        [_resultsTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
        [_resultsTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        
        [_activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return _heatMapImageView;
}

- (void)analyzeMap:(id)sender
{
    [_activityIndicator startAnimating];
    _analyzeButton.enabled = NO;
    _resultsTextView.text = @"Loading Ultima VII map...\n";
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        U7Environment *env = u7Env;
        U7Map *map = env->Map;
        
        if (!map) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.resultsTextView.text = @"ERROR: Could not load U7 map\n";
                [self->_activityIndicator stopAnimating];
                self->_analyzeButton.enabled = YES;
            });
            return;
        }
        
        BAMapAnalyzer *analyzer = [[BAMapAnalyzer alloc] initWithMap:map];
        [analyzer analyze];
        
        NSString *results = [analyzer getResultsText];
        NSDictionary *patterns = [analyzer exportPatterns];
        
        // Generate heat map
        UIImage *heatMap = [self generateHeatMapFromPatterns:patterns];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultsTextView.text = results;
            self.analysisResults = patterns;
            self->_exportButton.enabled = YES;
            [self->_activityIndicator stopAnimating];
            self->_analyzeButton.enabled = YES;
            
            // Display heat map
            self.heatMapImageView.image = heatMap;
            self.heatMapImageView.frame = CGRectMake(0, 0, heatMap.size.width, heatMap.size.height);
            self.heatMapScrollView.contentSize = heatMap.size;
            self.heatMapScrollView.zoomScale = 1.0;
            
            self.resultsTextView.accessibilityValue = [self JSONStringFromDictionary:patterns];
        });
    });
}

- (UIImage *)generateHeatMapFromPatterns:(NSDictionary *)patterns
{
    int mapSize = 192; // 192 chunks
    int pixelScale = 4; // 4 pixels per chunk
    int imageSize = mapSize * pixelScale;
    
    // Get terrain grid
    NSData *terrainGridData = patterns[@"terrainGrid"];
    const int *terrainGrid = (const int *)[terrainGridData bytes];
    
    // Create building density grid
    int gridSize = mapSize;
    int *densityGrid = calloc(gridSize * gridSize, sizeof(int));
    
    // Mark building locations
    NSArray *cities = patterns[@"cities"];
    for (NSDictionary *city in cities) {
        int x = [city[@"x"] intValue];
        int y = [city[@"y"] intValue];
        int width = [city[@"width"] intValue];
        int height = [city[@"height"] intValue];
        int buildingCount = [city[@"buildingCount"] intValue];
        
        int chunkX = x / 16;
        int chunkY = y / 16;
        int chunkW = MAX(1, width / 16);
        int chunkH = MAX(1, height / 16);
        
        for (int cy = chunkY; cy < MIN(gridSize, chunkY + chunkH); cy++) {
            for (int cx = chunkX; cx < MIN(gridSize, chunkX + chunkW); cx++) {
                if (cx >= 0 && cx < gridSize && cy >= 0 && cy < gridSize) {
                    densityGrid[cy * gridSize + cx] += buildingCount;
                }
            }
        }
    }
    
    // Find max density
    int maxDensity = 1;
    for (int i = 0; i < gridSize * gridSize; i++) {
        if (densityGrid[i] > maxDensity) {
            maxDensity = densityGrid[i];
        }
    }
    
    // Create image
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize, imageSize), NO, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Draw terrain base layer
    for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
            int terrainType = terrainGrid[y * gridSize + x];
            
            UIColor *color;
            switch (terrainType) {
                case 1: // Water
                    color = [UIColor colorWithRed:0.2 green:0.4 blue:0.8 alpha:1.0];
                    break;
                case 2: // Grass
                    color = [UIColor colorWithRed:0.4 green:0.6 blue:0.3 alpha:1.0];
                    break;
                case 3: // Mountains
                    color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
                    break;
                case 4: // Forest
                    color = [UIColor colorWithRed:0.2 green:0.5 blue:0.2 alpha:1.0];
                    break;
                case 5: // Swamp
                    color = [UIColor colorWithRed:0.3 green:0.4 blue:0.3 alpha:1.0];
                    break;
                case 6: // Desert
                    color = [UIColor colorWithRed:0.8 green:0.7 blue:0.4 alpha:1.0];
                    break;
                default: // Other
                    color = [UIColor colorWithRed:0.3 green:0.3 blue:0.3 alpha:1.0];
                    break;
            }
            
            [color setFill];
            CGContextFillRect(ctx, CGRectMake(x * pixelScale, y * pixelScale, pixelScale, pixelScale));
        }
    }
    
    // Overlay building density (semi-transparent red)
    for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
            int density = densityGrid[y * gridSize + x];
            if (density > 0) {
                float normalized = (float)density / maxDensity;
                UIColor *color = [UIColor colorWithRed:1.0 green:0.3 blue:0.2 alpha:normalized * 0.7];
                [color setFill];
                CGContextFillRect(ctx, CGRectMake(x * pixelScale, y * pixelScale, pixelScale, pixelScale));
            }
        }
    }
    
    // Draw city markers (white dots)
    [[UIColor whiteColor] setFill];
    for (NSDictionary *city in cities) {
        int x = [city[@"x"] intValue] / 16;
        int y = [city[@"y"] intValue] / 16;
        CGContextFillEllipseInRect(ctx, CGRectMake(x * pixelScale - 3, y * pixelScale - 3, 6, 6));
    }
    
    UIImage *heatMap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    free(densityGrid);
    
    return heatMap;
}

- (void)exportJSON:(id)sender
{
    NSString *json = _resultsTextView.accessibilityValue;
    if (!json) {
        return;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"u7_patterns.json"];
    
    NSError *error = nil;
    [json writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error saving JSON: %@", error);
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Exported"
                                                                   message:[NSString stringWithFormat:@"Saved to:\n%@", filePath]
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    
    NSLog(@"Exported patterns to: %@", filePath);
}

- (NSString *)JSONStringFromDictionary:(NSDictionary *)dict
{
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        return @"{}";
    }
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
