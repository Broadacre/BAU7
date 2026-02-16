//
//  BAMapAnalyzer.h
//  BAU7
//
//  Created by Tom on 2/16/26.
//

#import <Foundation/Foundation.h>
#import "Includes.h"

@interface BAMapAnalyzer : NSObject

- (instancetype)initWithMap:(U7Map *)map;
- (void)analyze;
- (NSString *)getResultsText;
- (NSDictionary *)exportPatterns;
- (NSDictionary *)exportPatternsForVisualization:(BOOL)includeTerrainGrid;

@end
