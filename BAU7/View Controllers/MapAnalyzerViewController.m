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
    
    // Initialize chunk classification dictionaries
    _chunkClassifications = [NSMutableDictionary dictionary];
    _masterChunkHistogram = [NSMutableDictionary dictionary];
    _sortedMasterChunkIDs = @[];
    _currentChunkIndex = 0;
    
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
    
    // RIGHT SIDE PANEL (classifier + results)
    _classifierPanel = [[UIView alloc] initWithFrame:CGRectZero];
    _classifierPanel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_classifierPanel];
    
    // Chunk preview (shows 16×16 tiles)
    _chunkPreviewView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _chunkPreviewView.backgroundColor = [UIColor blackColor];
    _chunkPreviewView.contentMode = UIViewContentModeScaleAspectFit;
    _chunkPreviewView.translatesAutoresizingMaskIntoConstraints = NO;
    [_classifierPanel addSubview:_chunkPreviewView];
    
    // 3×3 chunk grid (context view)
    _chunkGridView = [[UIImageView alloc] initWithFrame:CGRectZero];
    _chunkGridView.backgroundColor = [UIColor darkGrayColor];
    _chunkGridView.contentMode = UIViewContentModeScaleAspectFit;
    _chunkGridView.layer.borderColor = [UIColor whiteColor].CGColor;
    _chunkGridView.layer.borderWidth = 2.0;
    _chunkGridView.translatesAutoresizingMaskIntoConstraints = NO;
    [_classifierPanel addSubview:_chunkGridView];
    
    // Chunk info label
    _chunkInfoLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _chunkInfoLabel.font = [UIFont boldSystemFontOfSize:14];
    _chunkInfoLabel.numberOfLines = 0;
    _chunkInfoLabel.text = @"Awaiting analysis...";
    _chunkInfoLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_classifierPanel addSubview:_chunkInfoLabel];
    
    // Progress label
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    _progressLabel.font = [UIFont systemFontOfSize:12];
    _progressLabel.textColor = [UIColor secondaryLabelColor];
    _progressLabel.text = @"";
    _progressLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [_classifierPanel addSubview:_progressLabel];
    
    // Chunk classification buttons (3 rows of 3)
    NSArray *chunkTypes = @[@"Water", @"Grass", @"Mountain", 
                            @"Forest", @"Swamp", @"Sand", 
                            @"Dirt", @"Mixed", @"Other"];
    CGFloat buttonWidth = 80;
    CGFloat buttonHeight = 40;
    CGFloat spacing = 10;
    
    for (int i = 0; i < 9; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:chunkTypes[i] forState:UIControlStateNormal];
        btn.tag = i + 1; // Category index
        [btn addTarget:self action:@selector(classifyChunk:) forControlEvents:UIControlEventTouchUpInside];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [_classifierPanel addSubview:btn];
        
        int row = i / 3;
        int col = i % 3;
        
        [NSLayoutConstraint activateConstraints:@[
            [btn.widthAnchor constraintEqualToConstant:buttonWidth],
            [btn.heightAnchor constraintEqualToConstant:buttonHeight],
            [btn.leadingAnchor constraintEqualToAnchor:_classifierPanel.leadingAnchor 
                                              constant:(10 + col * (buttonWidth + spacing))],
            [btn.topAnchor constraintEqualToAnchor:_progressLabel.bottomAnchor 
                                           constant:(10 + row * (buttonHeight + spacing))]
        ]];
    }
    
    // Results text view (below classifier)
    _resultsTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    _resultsTextView.editable = NO;
    _resultsTextView.font = [UIFont fontWithName:@"Menlo" size:11];
    _resultsTextView.text = @"Tap 'Analyze Map' to scan the Ultima VII world and generate a heat map...\n";
    _resultsTextView.translatesAutoresizingMaskIntoConstraints = NO;
    [_classifierPanel addSubview:_resultsTextView];
    
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
    
    // Export Mappings button
    _exportMappingsButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_exportMappingsButton setTitle:@"Export Mappings" forState:UIControlStateNormal];
    [_exportMappingsButton addTarget:self action:@selector(exportMappings:) forControlEvents:UIControlEventTouchUpInside];
    _exportMappingsButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_exportMappingsButton];
    
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
        
        [_exportMappingsButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [_exportMappingsButton.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        
        [_exportButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:10],
        [_exportButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        // Heat map on left half
        [_heatMapScrollView.topAnchor constraintEqualToAnchor:_analyzeButton.bottomAnchor constant:10],
        [_heatMapScrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_heatMapScrollView.widthAnchor constraintEqualToAnchor:self.view.widthAnchor multiplier:0.5],
        [_heatMapScrollView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
        
        // Classifier panel on right half
        [_classifierPanel.topAnchor constraintEqualToAnchor:_analyzeButton.bottomAnchor constant:10],
        [_classifierPanel.leadingAnchor constraintEqualToAnchor:_heatMapScrollView.trailingAnchor constant:10],
        [_classifierPanel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-10],
        [_classifierPanel.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-10],
        
        // Chunk preview at top of classifier panel
        [_chunkPreviewView.topAnchor constraintEqualToAnchor:_classifierPanel.topAnchor],
        [_chunkPreviewView.leadingAnchor constraintEqualToAnchor:_classifierPanel.leadingAnchor],
        [_chunkPreviewView.widthAnchor constraintEqualToConstant:256], // 16 tiles * 16 pixels
        [_chunkPreviewView.heightAnchor constraintEqualToConstant:256],
        
        // 3×3 chunk grid below chunk preview
        [_chunkGridView.topAnchor constraintEqualToAnchor:_chunkPreviewView.bottomAnchor constant:10],
        [_chunkGridView.leadingAnchor constraintEqualToAnchor:_classifierPanel.leadingAnchor],
        [_chunkGridView.widthAnchor constraintEqualToConstant:144], // 3 chunks × 16 tiles × 3px
        [_chunkGridView.heightAnchor constraintEqualToConstant:144],
        
        // Chunk info below grid
        [_chunkInfoLabel.topAnchor constraintEqualToAnchor:_chunkGridView.bottomAnchor constant:10],
        [_chunkInfoLabel.leadingAnchor constraintEqualToAnchor:_classifierPanel.leadingAnchor],
        [_chunkInfoLabel.trailingAnchor constraintEqualToAnchor:_classifierPanel.trailingAnchor],
        
        // Progress label below chunk info
        [_progressLabel.topAnchor constraintEqualToAnchor:_chunkInfoLabel.bottomAnchor constant:5],
        [_progressLabel.leadingAnchor constraintEqualToAnchor:_classifierPanel.leadingAnchor],
        [_progressLabel.trailingAnchor constraintEqualToAnchor:_classifierPanel.trailingAnchor],
        
        // Results text at bottom (buttons are positioned relative to progressLabel in loop above)
        [_resultsTextView.topAnchor constraintEqualToAnchor:_progressLabel.bottomAnchor constant:120], // Space for 2 rows of buttons
        [_resultsTextView.leadingAnchor constraintEqualToAnchor:_classifierPanel.leadingAnchor],
        [_resultsTextView.trailingAnchor constraintEqualToAnchor:_classifierPanel.trailingAnchor],
        [_resultsTextView.bottomAnchor constraintEqualToAnchor:_classifierPanel.bottomAnchor],
        
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
    _resultsTextView.text = @"Scanning chunks...\n";
    
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
        
        // Build masterChunkID histogram
        NSMutableDictionary *histogram = [NSMutableDictionary dictionary];
        
        for (int y = 0; y < 192; y++) {
            for (int x = 0; x < 192; x++) {
                // Use proper U7Map methods from BAU7Objects.h
                long chunkIndex = [map chunkIDForChunkCoordinate:CGPointMake(x, y)];
                U7MapChunk *chunk = [map mapChunkAtIndex:chunkIndex];
                
                if (chunk && chunk->masterChunk) {
                    NSNumber *chunkID = @(chunk->masterChunkID);
                    
                    NSMutableDictionary *entry = histogram[chunkID];
                    if (!entry) {
                        entry = [@{
                            @"count": @(0),
                            @"exampleX": @(x),
                            @"exampleY": @(y)
                        } mutableCopy];
                        histogram[chunkID] = entry;
                    }
                    
                    entry[@"count"] = @([entry[@"count"] intValue] + 1);
                }
            }
        }
        
        // Sort by occurrence count (descending)
        NSArray *sortedIDs = [histogram keysSortedByValueUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            int count1 = [obj1[@"count"] intValue];
            int count2 = [obj2[@"count"] intValue];
            return count2 - count1;
        }];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_masterChunkHistogram = histogram;
            self->_sortedMasterChunkIDs = sortedIDs;
            self->_currentChunkIndex = 0;
            
            NSString *stats = [NSString stringWithFormat:
                @"Found %lu unique masterChunk patterns\n"
                @"Most common: ID %@ (%@ occurrences)\n\n"
                @"Ready to classify!",
                (unsigned long)[sortedIDs count],
                sortedIDs[0],
                histogram[sortedIDs[0]][@"count"]
            ];
            
            self.resultsTextView.text = stats;
            [self displayCurrentChunk];
            [self updateHeatMapWithClassifications];
            [self->_activityIndicator stopAnimating];
            self->_analyzeButton.enabled = YES;
        });
    });
}

- (void)displayCurrentChunk
{
    if (_currentChunkIndex >= [_sortedMasterChunkIDs count]) {
        _chunkInfoLabel.text = @"✅ All chunks classified!";
        _progressLabel.text = @"";
        _chunkGridView.image = nil;
        return;
    }
    
    NSNumber *masterChunkID = _sortedMasterChunkIDs[_currentChunkIndex];
    NSDictionary *entry = _masterChunkHistogram[masterChunkID];
    int exampleX = [entry[@"exampleX"] intValue];
    int exampleY = [entry[@"exampleY"] intValue];
    int count = [entry[@"count"] intValue];
    
    // Update labels
    _chunkInfoLabel.text = [NSString stringWithFormat:@"MasterChunk %@ (%d occurrences)", masterChunkID, count];
    _progressLabel.text = [NSString stringWithFormat:@"%ld of %lu unique patterns", 
                           (long)(_currentChunkIndex + 1),
                           (unsigned long)[_sortedMasterChunkIDs count]];
    
    // Render single chunk preview (full size with all shapes/objects)
    UIImage *chunkImage = [self renderChunkAtX:exampleX y:exampleY highlightTile:-1];
    _chunkPreviewView.image = chunkImage;
    
    // Draw 3×3 chunk grid
    UIImage *gridImage = [self draw3x3ChunkGridAtX:exampleX Y:exampleY];
    _chunkGridView.image = gridImage;
}
// Add this method after displayCurrentChunk

- (void)updateHeatMapWithClassifications
{
    U7Environment *env = u7Env;
    U7Map *map = env->Map;
    
    if (!map) return;
    
    int mapSize = 192; // 192 chunks
    int pixelScale = 4; // 4 pixels per chunk
    int imageSize = mapSize * pixelScale;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize, imageSize), YES, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Color mapping for terrain types
    NSDictionary *colorMap = @{
        @"Water":    [UIColor colorWithRed:0.15 green:0.35 blue:0.75 alpha:1.0],
        @"Grass":    [UIColor colorWithRed:0.2 green:0.7 blue:0.2 alpha:1.0],
        @"Mountain": [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0],
        @"Forest":   [UIColor colorWithRed:0.20 green:0.50 blue:0.25 alpha:1.0],
        @"Swamp":    [UIColor colorWithRed:0.6 green:0.8 blue:0.6 alpha:1.0],
        @"Sand":     [UIColor colorWithRed:0.82 green:0.71 blue:0.55 alpha:1.0],
        @"Dirt":     [UIColor colorWithRed:0.55 green:0.35 blue:0.20 alpha:1.0],
        @"Mixed":    [UIColor colorWithRed:0.5 green:0.5 blue:0.3 alpha:1.0],
        @"Other":    [UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:1.0]
    };
    
    UIColor *unclassifiedColor = [UIColor darkGrayColor];
    
    // Render each chunk
    for (int y = 0; y < mapSize; y++) {
        for (int x = 0; x < mapSize; x++) {
            long chunkIndex = [map chunkIDForChunkCoordinate:CGPointMake(x, y)];
            U7MapChunk *chunk = [map mapChunkAtIndex:chunkIndex];
            
            UIColor *color = unclassifiedColor;
            
            if (chunk && chunk->masterChunk) {
                NSNumber *masterChunkID = @(chunk->masterChunkID);
                NSString *category = _chunkClassifications[masterChunkID];
                
                if (category && colorMap[category]) {
                    color = colorMap[category];
                }
            }
            
            [color setFill];
            CGRect pixelRect = CGRectMake(x * pixelScale, y * pixelScale, pixelScale, pixelScale);
            CGContextFillRect(ctx, pixelRect);
        }
    }
    
    UIImage *heatMap = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Update heat map view
    _heatMapImageView.image = heatMap;
    _heatMapImageView.frame = CGRectMake(0, 0, heatMap.size.width, heatMap.size.height);
    _heatMapScrollView.contentSize = heatMap.size;
}


- (UIImage *)draw3x3ChunkGridAtX:(int)centerX Y:(int)centerY
{
    NSLog(@"🎨 Drawing 3×3 grid centered at (%d, %d)", centerX, centerY);
    
    int gridSize = 3;
    int chunkPixelSize = 48; // 16 tiles × 3px each
    int totalSize = gridSize * chunkPixelSize;
    
    UIGraphicsBeginImageContext(CGSizeMake(totalSize, totalSize));
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Black background
    [[UIColor blackColor] setFill];
    CGContextFillRect(ctx, CGRectMake(0, 0, totalSize, totalSize));
    
    int chunksRendered = 0;
    
    for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
            int x = centerX + dx;
            int y = centerY + dy;
            
            if (x < 0 || x >= 192 || y < 0 || y >= 192) {
                NSLog(@"  ⚠️ Chunk (%d, %d) out of bounds", x, y);
                continue;
            }
            
            // Render chunk at full size (256x256), then scale down to 48x48
            UIImage *fullChunk = [self renderChunkAtX:x y:y highlightTile:-1];
            
            if (fullChunk) {
                CGRect destRect = CGRectMake((dx + 1) * chunkPixelSize,
                                            (dy + 1) * chunkPixelSize,
                                            chunkPixelSize,
                                            chunkPixelSize);
                [fullChunk drawInRect:destRect];
                chunksRendered++;
                
                // Red border on center chunk
                if (dx == 0 && dy == 0) {
                    [[UIColor redColor] setStroke];
                    CGContextSetLineWidth(ctx, 2.0);
                    CGContextStrokeRect(ctx, destRect);
                }
            } else {
                NSLog(@"  ❌ Failed to render chunk at (%d, %d)", x, y);
            }
        }
    }
    
    NSLog(@"  ✅ Rendered %d/9 chunks", chunksRendered);
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
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
    NSLog(@"  Chunk (14,87): terrainGrid value = %d (water→dirt)", terrainGrid[87 * 192 + 14]);
    NSLog(@"  Chunk (78,89): terrainGrid value = %d (water→grass)", terrainGrid[89 * 192 + 78]);
    NSLog(@"  Chunk (129,79): terrainGrid value = %d (water→sand)", terrainGrid[79 * 192 + 129]);
    NSLog(@"  Chunk (129,54): terrainGrid value = %d (sand→grass)", terrainGrid[54 * 192 + 129]);
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
    for (int y = 0; y < gridSize; y++) {
        for (int x = 0; x < gridSize; x++) {
            int terrainType = terrainGrid[y * gridSize + x];
            
            UIColor *color;
            switch (terrainType) {
                case 1: // Water - blue
                    color = [UIColor colorWithRed:0.15 green:0.35 blue:0.75 alpha:1.0];
                    break;
                case 2: // Grass - green
                    color = [UIColor colorWithRed:0.2 green:0.7 blue:0.2 alpha:1.0];
                    break;
                case 3: // Mountains - grey
                    color = [UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0];
                    break;
                case 4: // Forest - dark green
                    color = [UIColor colorWithRed:0.20 green:0.50 blue:0.25 alpha:1.0];
                    break;
                case 5: // Swamp - light green
                    color = [UIColor colorWithRed:0.6 green:0.8 blue:0.6 alpha:1.0];
                    break;
                case 6: // Sand - tan
                    color = [UIColor colorWithRed:0.82 green:0.71 blue:0.55 alpha:1.0];
                    break;
                case 7: // Dirt - brown
                    color = [UIColor colorWithRed:0.55 green:0.35 blue:0.20 alpha:1.0];
                    break;
                case 0: // Other - purple
                    color = [UIColor colorWithRed:0.6 green:0.2 blue:0.8 alpha:1.0];
                    break;
                default: // Unknown - black
                    color = [UIColor blackColor];
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

- (void)exportMappings:(id)sender
{
    if ([_terrainMappings count] == 0) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No Mappings"
                                                                       message:@"No terrain mappings to export yet. Classify some tiles first!"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    // Create temp file with MERGED mappings (bundle + Documents)
    NSString *tempDir = NSTemporaryDirectory();
    NSString *tempPath = [tempDir stringByAppendingPathComponent:@"TerrainMapping.json"];
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_terrainMappings
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error || ![jsonData writeToFile:tempPath atomically:YES]) {
        NSLog(@"❌ Failed to create temp export file");
        return;
    }
    
    // Share using activity controller (AirDrop, Files, etc.)
    NSURL *fileURL = [NSURL fileURLWithPath:tempPath];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL]
                                                                             applicationActivities:nil];
    
    // For iPad - set popover presentation
    if (activityVC.popoverPresentationController) {
        activityVC.popoverPresentationController.sourceView = sender;
    }
    
    [self presentViewController:activityVC animated:YES completion:^{
        NSLog(@"📤 Exported TerrainMapping.json with %lu total mappings", (unsigned long)[self.terrainMappings count]);
        NSLog(@"   Save to: /Users/danbrooker/Documents/BAU7/BAU7/TerrainMapping.json");
        NSLog(@"   Then: git add BAU7/TerrainMapping.json && git commit && git push");
    }];
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

#pragma mark - Terrain Classifier

- (void)loadTerrainMappings
{
    _terrainMappings = [NSMutableDictionary dictionary];
    
    // Load from bundle first (git-tracked mappings from other machines)
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"TerrainMapping" ofType:@"json"];
    if (bundlePath) {
        NSData *data = [NSData dataWithContentsOfFile:bundlePath];
        NSError *error = nil;
        NSDictionary *loaded = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && loaded) {
            [_terrainMappings addEntriesFromDictionary:loaded];
            NSLog(@"📦 Loaded %lu terrain mappings from bundle (git)", (unsigned long)[_terrainMappings count]);
        }
    }
    
    // Then load from Documents (your new classifications since last export)
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *docsFile = [docsPath stringByAppendingPathComponent:@"TerrainMapping.json"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:docsFile]) {
        NSData *data = [NSData dataWithContentsOfFile:docsFile];
        NSError *error = nil;
        NSDictionary *loaded = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && loaded) {
            NSUInteger beforeCount = [_terrainMappings count];
            [_terrainMappings addEntriesFromDictionary:loaded];
            NSUInteger newCount = [_terrainMappings count] - beforeCount;
            if (newCount > 0) {
                NSLog(@"📝 Loaded %lu NEW mappings from Documents (local work)", (unsigned long)newCount);
            }
        }
    }
    
    NSLog(@"✅ Total mappings loaded: %lu", (unsigned long)[_terrainMappings count]);
}

- (void)saveTerrainMappings
{
    NSLog(@"💾 Attempting to save %lu terrain mappings...", (unsigned long)[_terrainMappings count]);
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:_terrainMappings
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        NSLog(@"❌ JSON serialization error: %@", error.localizedDescription);
        return;
    }
    
    // Save to app's Documents directory (inside sandbox - always works)
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [docsPath stringByAppendingPathComponent:@"TerrainMapping.json"];
    
    BOOL success = [jsonData writeToFile:filePath atomically:YES];
    
    if (success) {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
        NSLog(@"✅ Saved %lu terrain mappings to app Documents:", (unsigned long)[_terrainMappings count]);
        NSLog(@"   %@", filePath);
        NSLog(@"   File size: %@ bytes", attrs[NSFileSize]);
        NSLog(@"   📤 Use 'Export Mappings' button to save to project folder");
    } else {
        NSLog(@"❌ Failed to save to Documents folder");
    }
}

- (void)classifyChunk:(UIButton *)sender
{
    if (_currentChunkIndex >= [_sortedMasterChunkIDs count]) {
        NSLog(@"✅ All chunks classified!");
        return;
    }
    
    NSArray *categories = @[@"Water", @"Grass", @"Mountain", @"Forest", 
                           @"Swamp", @"Sand", @"Dirt", @"Mixed", @"Other"];
    
    if (sender.tag < 1 || sender.tag > [categories count]) {
        NSLog(@"❌ Invalid button tag %ld", (long)sender.tag);
        return;
    }
    
    NSString *category = categories[sender.tag - 1];
    NSNumber *masterChunkID = _sortedMasterChunkIDs[_currentChunkIndex];
    int count = [_masterChunkHistogram[masterChunkID][@"count"] intValue];
    
    // Save classification
    _chunkClassifications[masterChunkID] = category;
    
    NSLog(@"✅ Classified masterChunk %@ (%d occurrences) as '%@'", masterChunkID, count, category);
    
    // Move to next chunk
    _currentChunkIndex++;
    [self displayCurrentChunk];
    
    [self updateHeatMapWithClassifications];
}
- (void)loadNextCombo
{
    // LEGACY METHOD - Not used in chunk-based classification workflow
    // Kept for compatibility with old terrain mapping export/import
    
    if (_currentComboIndex >= [_unknownCombos count]) {
        _chunkInfoLabel.text = [NSString stringWithFormat:@"✅ All combos classified!\n%lu total mappings saved", 
                                (unsigned long)[_terrainMappings count]];
        _progressLabel.text = @"TerrainMapping.json is ready to use";
        _chunkPreviewView.image = nil;
        _chunkGridView.image = nil;
        return;
    }
    
    NSDictionary *combo = _unknownCombos[_currentComboIndex];
    long shapeID = [combo[@"shape"] longValue];
    int frameID = [combo[@"frame"] intValue];
    int count = [combo[@"count"] intValue];
    
    _chunkInfoLabel.text = [NSString stringWithFormat:@"Shape %ld : Frame %d\n%d occurrences", 
                            shapeID, frameID, count];
    _progressLabel.text = [NSString stringWithFormat:@"Classifying %ld of %lu unclassified combos\n(%lu already saved)", 
                          _currentComboIndex + 1, (unsigned long)[_unknownCombos count],
                          (unsigned long)[_terrainMappings count]];
    
    // Render chunk preview with highlighted tile
    NSDictionary *exampleChunk = combo[@"exampleChunk"];
    int chunkX = [exampleChunk[@"x"] intValue];
    int chunkY = [exampleChunk[@"y"] intValue];
    int tileIndex = [exampleChunk[@"tileIndex"] intValue];
    
    UIImage *preview = [self renderChunkAtX:chunkX y:chunkY highlightTile:tileIndex];
    _chunkPreviewView.image = preview;
    
    // Note: Old enlarged tile view removed, using grid view placeholder
    _chunkGridView.image = nil;
}

- (UIImage *)renderChunkAtX:(int)chunkX y:(int)chunkY highlightTile:(int)tileIndex
{
    U7Environment *env = u7Env;
    U7Map *map = env->Map;
    
    if (!map) {
        return nil;
    }
    
    long chunkIndex = [map chunkIDForChunkCoordinate:CGPointMake(chunkX, chunkY)];
    U7MapChunk *mapChunk = [map mapChunkAtIndex:chunkIndex];
    
    if (!mapChunk || !mapChunk->masterChunk) {
        return nil;
    }
    
    int tileSize = 16; // pixels per tile
    int chunkSize = 16; // tiles per chunk
    int imageSize = tileSize * chunkSize; // 256x256
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(imageSize, imageSize), YES, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    // Black background
    [[UIColor blackColor] setFill];
    CGContextFillRect(ctx, CGRectMake(0, 0, imageSize, imageSize));
    
    U7Chunk *chunk = mapChunk->masterChunk;
    
    // LAYER 1: Render base terrain tiles
    for (int tileY = 0; tileY < chunkSize; tileY++) {
        for (int tileX = 0; tileX < chunkSize; tileX++) {
            int idx = tileY * chunkSize + tileX;
            
            if (idx >= [chunk->chunkMap count]) continue;
            
            U7ChunkIndex *chunkIdx = chunk->chunkMap[idx];
            long shapeID = chunkIdx->shapeIndex;
            int frameID = chunkIdx->frameIndex;
            
            // Get tile image from U7 shapes
            UIImage *tileImage = [self getTileImageForShape:shapeID frame:frameID];
            
            if (tileImage) {
                CGRect destRect = CGRectMake(tileX * tileSize, tileY * tileSize, tileSize, tileSize);
                [tileImage drawInRect:destRect];
            }
            
            // Highlight the tile we're classifying
            if (idx == tileIndex) {
                [[UIColor redColor] setStroke];
                CGContextSetLineWidth(ctx, 2.0);
                CGRect highlightRect = CGRectMake(tileX * tileSize, tileY * tileSize, tileSize, tileSize);
                CGContextStrokeRect(ctx, highlightRect);
            }
        }
    }
    
    // LAYER 2: Render ground objects (floor items)
    if (mapChunk->groundObjects) {
        for (U7ShapeReference *shapeRef in mapChunk->groundObjects) {
            UIImage *objImage = [self getTileImageForShape:shapeRef->shapeID frame:shapeRef->frameNumber];
            if (objImage) {
                CGRect destRect = CGRectMake(shapeRef->xloc * tileSize, shapeRef->yloc * tileSize, tileSize, tileSize);
                [objImage drawInRect:destRect];
            }
        }
    }
    
    // LAYER 3: Render static objects (buildings, trees, mountains, etc.)
    if (mapChunk->staticItems) {
        for (U7ShapeReference *shapeRef in mapChunk->staticItems) {
            UIImage *objImage = [self getTileImageForShape:shapeRef->shapeID frame:shapeRef->frameNumber];
            if (objImage) {
                CGRect destRect = CGRectMake(shapeRef->xloc * tileSize, shapeRef->yloc * tileSize, tileSize, tileSize);
                [objImage drawInRect:destRect];
            }
        }
    }
    
    UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (UIImage *)getTileImageForShape:(long)shapeID frame:(int)frameID
{
    U7Environment *env = u7Env;
    
    if (!env || !env->U7Shapes) {
        return nil;
    }
    
    // Bounds check
    if (shapeID < 0 || shapeID >= [env->U7Shapes count]) {
        return nil;
    }
    
    // Get shape from U7Shapes array
    U7Shape *shape = env->U7Shapes[shapeID];
    
    if (!shape || !shape->frames || frameID >= [shape->frames count]) {
        return nil;
    }
    
    // Get frame bitmap
    U7Bitmap *frameBitmap = shape->frames[frameID];
    
    if (!frameBitmap || !frameBitmap->image) {
        return nil;
    }
    
    return frameBitmap->image;
}

@end
