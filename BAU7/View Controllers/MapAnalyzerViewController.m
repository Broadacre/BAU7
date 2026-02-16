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
    
    // Results text view (scrollable)
    _resultsTextView = [[UITextView alloc] initWithFrame:CGRectZero];
    _resultsTextView.editable = NO;
    _resultsTextView.font = [UIFont fontWithName:@"Menlo" size:12];
    _resultsTextView.text = @"Tap 'Analyze Map' to scan the Ultima VII world...\n";
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
    _exportButton.enabled = NO; // Enable after analysis
    _exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_exportButton];
    
    // Activity indicator
    _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    _activityIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    _activityIndicator.hidesWhenStopped = YES;
    [self.view addSubview:_activityIndicator];
    
    // Layout constraints
    [NSLayoutConstraint activateConstraints:@[
        [_analyzeButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [_analyzeButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        
        [_exportButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [_exportButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        
        [_resultsTextView.topAnchor constraintEqualToAnchor:_analyzeButton.bottomAnchor constant:20],
        [_resultsTextView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:20],
        [_resultsTextView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [_resultsTextView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor constant:-20],
        
        [_activityIndicator.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [_activityIndicator.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor]
    ]];
}

- (void)analyzeMap:(id)sender
{
    [_activityIndicator startAnimating];
    _analyzeButton.enabled = NO;
    _resultsTextView.text = @"Loading Ultima VII map...\n";
    
    // Run analysis on background thread
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        // Load the U7 map from the environment
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
        
        // Create analyzer and run it
        BAMapAnalyzer *analyzer = [[BAMapAnalyzer alloc] initWithMap:map];
        [analyzer analyze];
        
        // Get results
        NSString *results = [analyzer getResultsText];
        NSDictionary *patterns = [analyzer exportPatterns];
        
        // Update UI on main thread
        dispatch_async(dispatch_get_main_queue(), ^{
            self.resultsTextView.text = results;
            self->_exportButton.enabled = YES;
            [self->_activityIndicator stopAnimating];
            self->_analyzeButton.enabled = YES;
            
            // Store patterns for export
            self.resultsTextView.accessibilityValue = [self JSONStringFromDictionary:patterns];
        });
    });
}

- (void)exportJSON:(id)sender
{
    NSString *json = _resultsTextView.accessibilityValue;
    if (!json) {
        return;
    }
    
    // Save to Documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths firstObject];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"u7_patterns.json"];
    
    NSError *error = nil;
    [json writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (error) {
        NSLog(@"Error saving JSON: %@", error);
        return;
    }
    
    // Show alert
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
