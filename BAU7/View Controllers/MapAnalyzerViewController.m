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
        
        // Get patterns WITH terrain grid for visualization
        NSDictionary *patternsWithGrid = [analyzer exportPatternsForVisualization:YES];
        
        // Get patterns WITHOUT terrain grid for JSON export
        NSDictionary *patternsForJSON = [analyzer exportPatternsForVisualization:NO];
        
        // Generate heat map
        UIImage *heatMap = [self generateHeatMapFromPatterns:patternsWithGrid];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultsTextView.text = results;
            self.analysisResults = patternsForJSON;
            self->_exportButton.enabled = YES;
            [self->_activityIndicator stopAnimating];
            self->_analyzeButton.enabled = YES;
            
            // Display heat map
            self.heatMapImageView.image = heatMap;
            self.heatMapImageView.frame = CGRectMake(0, 0, heatMap.size.width, heatMap.size.height);
            self.heatMapScrollView.contentSize = heatMap.size;
            self.heatMapScrollView.zoomScale = 1.0;
            
            self.resultsTextView.accessibilityValue = [self JSONStringFromDictionary:self.analysisResults];
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
    
    // DIAGNOSTIC: Check the same mountain chunks we logged during analysis
    NSLog(@"HEATMAP DIAGNOSTIC: Checking mountain chunks from analysis:");
    NSLog(@"  Chunk (28,4): terrainGrid value = %d (should be 3)", terrainGrid[4 * 192 + 28]);
    NSLog(@"  Chunk (29,5): terrainGrid value = %d (should be 3)", terrainGrid[5 * 192 + 29]);
    NSLog(@"  Chunk (28,6): terrainGrid value = %d (should be 3)", terrainGrid[6 * 192 + 28]);
    NSLog(@"  Chunk (29,6): terrainGrid value = %d (should be 3)", terrainGrid[6 * 192 + 29]);
    NSLog(@"  Chunk (39,6): terrainGrid value = %d (should be 3)", terrainGrid[6 * 192 + 39]);
    NSLog(@"  Chunk (53,60): terrainGrid value = %d (USER'S TEST CHUNK - should be 3)", terrainGrid[60 * 192 + 53]);
    NSLog(@"TRANSITION CHUNKS:");
    NSLog(@"  Chunk (41,66): terrainGrid value = %d (water→mountain)", terrainGrid[66 * 192 + 41]);
    NSLog(@"  Chunk (39,67): terrainGrid value = %d (water→grass)", terrainGrid[67 * 192 + 39]);
    NSLog(@"  Chunk (14,87): terrainGrid value = %d (water→barren)", terrainGrid[87 * 192 + 14]);
    NSLog(@"  Chunk (78,89): terrainGrid value = %d (water→grass)", terrainGrid[89 * 192 + 78]);
    NSLog(@"  Chunk (129,79): terrainGrid value = %d (water→desert)", terrainGrid[79 * 192 + 129]);
    NSLog(@"  Chunk (129,54): terrainGrid value = %d (desert→grass)", terrainGrid[54 * 192 + 129]);
    NSLog(@"  Chunk (128,56): terrainGrid value = %d (grass→mountain)", terrainGrid[56 * 192 + 128]);
    NSLog(@"  Chunk (124,49): terrainGrid value = %d (swamp→grass)", terrainGrid[49 * 192 + 124]);
    NSLog(@"STILL SHOWING GREEN:");
    NSLog(@"  Chunk (19,68): terrainGrid value = %d", terrainGrid[68 * 192 + 19]);
    NSLog(@"  Chunk (17,67): terrainGrid value = %d", terrainGrid[67 * 192 + 17]);
    NSLog(@"  Chunk (10,82): terrainGrid value = %d", terrainGrid[82 * 192 + 10]);
    
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
    int mountainRenders = 0;
    for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
            int terrainType = terrainGrid[y * gridSize + x];
            
            // DIAGNOSTIC: Log when rendering our known mountain chunks + user's test chunk
            if ((x == 28 && y == 4) || (x == 29 && y == 5) || (x == 53 && y == 60)) {
                NSLog(@"RENDERING chunk (%d,%d): terrainType=%d", x, y, terrainType);
            }
            
            UIColor *color;
            switch (terrainType) {
                case 1: // Water - deep blue
                    color = [UIColor colorWithRed:0.15 green:0.35 blue:0.75 alpha:1.0];
                    if (x == 53 && y == 60) {
                        NSLog(@"  -> Assigned WATER color (blue) RGB=(0.15, 0.35, 0.75) - THIS IS WRONG!");
                    }
                    break;
                case 2: // Grass - light green
                    color = [UIColor colorWithRed:0.45 green:0.65 blue:0.35 alpha:1.0];
                    break;
                case 3: // Mountains - brown/gray
                    color = [UIColor colorWithRed:0.55 green:0.50 blue:0.45 alpha:1.0];
                    mountainRenders++;
                    if ((x == 28 && y == 4) || (x == 29 && y == 5) || (x == 53 && y == 60)) {
                        NSLog(@"  -> Assigned MOUNTAIN color (brown/gray) RGB=(0.55, 0.50, 0.45)");
                    }
                    break;
                case 4: // Forest - dark green
                    color = [UIColor colorWithRed:0.20 green:0.50 blue:0.25 alpha:1.0];
                    break;
                case 5: // Swamp - muddy green
                    color = [UIColor colorWithRed:0.35 green:0.45 blue:0.35 alpha:1.0];
                    break;
                case 6: // Desert - sandy yellow
                    color = [UIColor colorWithRed:0.85 green:0.75 blue:0.50 alpha:1.0];
                    break;
                case 7: // Barren - tan/light brown
                    color = [UIColor colorWithRed:0.70 green:0.60 blue:0.45 alpha:1.0];
                    if ((x == 21 && y == 98) || (x == 20 && y == 99)) {
                        NSLog(@"  -> Assigned BARREN color (tan) RGB=(0.70, 0.60, 0.45)");
                    }
                    break;
                default: // Other - dark gray
                    color = [UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0];
                    break;
            }
            
            [color setFill];
            CGContextFillRect(ctx, CGRectMake(x * pixelScale, y * pixelScale, pixelScale, pixelScale));
        }
    }
    NSLog(@"Total mountain chunks rendered: %d (expected ~3313)", mountainRenders);
    
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
