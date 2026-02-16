//
//  BATransitionStrategyRegistry.m
//  BAU7
//
//  Created by Refactoring on 2/15/26.
//

#import "BATransitionStrategyRegistry.h"
#import "BAWoodsTransitionStrategy.h"

@implementation BATransitionStrategyRegistry
{
    NSMutableDictionary<NSNumber *, id<BATerrainTransitionStrategy>> *_strategies;
    NSDictionary *_transitionMappings; // Data-driven fallback
}

+(instancetype)sharedRegistry
{
    static BATransitionStrategyRegistry *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

-(instancetype)init
{
    self = [super init];
    if (self) {
        _strategies = [NSMutableDictionary dictionary];
        
        // Register explicit strategy implementations
        [self registerStrategy:[[BAWoodsTransitionStrategy alloc] init]];
        
        // Load data-driven transition mappings for remaining terrains
        [self loadTransitionMappings];
    }
    return self;
}

-(void)registerStrategy:(id<BATerrainTransitionStrategy>)strategy
{
    _strategies[@([strategy sourceTileType])] = strategy;
}

-(void)loadTransitionMappings
{
    // TODO: Load from JSON file for remaining terrain types
    // For now, use an empty dictionary - the main TileTypeForTransitionType
    // method will continue to handle unmapped transitions
    _transitionMappings = @{};
}

-(enum BATileType)tileTypeFrom:(enum BATileType)fromType 
                            to:(enum BATileType)toType 
                  forTransition:(enum BATransitionType)transition
{
    // Check for registered strategy first
    id<BATerrainTransitionStrategy> strategy = _strategies[@(fromType)];
    if (strategy) {
        return [strategy tileTypeForTransition:transition toTileType:toType];
    }
    
    // Fall back to data-driven lookup
    // Key format: "fromType_toType_transition"
    NSString *key = [NSString stringWithFormat:@"%d_%d_%d", fromType, toType, transition];
    NSNumber *tileType = _transitionMappings[key];
    
    if (tileType) {
        return (enum BATileType)[tileType intValue];
    }
    
    // No mapping found
    return NoTileType;
}

@end
