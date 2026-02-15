//
//  BAImageUpscaler.h
//  BAU7
//
//  FSR (FidelityFX Super Resolution) style upscaling using Metal
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BAFSRQualityMode) {
    BAFSRQualityModeUltraQuality = 0,  // 1.3x scale
    BAFSRQualityModeQuality,            // 1.5x scale
    BAFSRQualityModeBalanced,           // 1.7x scale
    BAFSRQualityModePerformance,        // 2.0x scale
    BAFSRQualityModeUltraPerformance    // 3.0x scale
};

@interface BAImageUpscaler : NSObject

@property (nonatomic, strong, nullable) id<MTLDevice> device;
@property (nonatomic, strong, nullable) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong, nullable) id<MTLComputePipelineState> easuPipeline;
@property (nonatomic, strong, nullable) id<MTLComputePipelineState> rcasPipeline;
@property (nonatomic, strong) NSCache *upscaleCache;
@property (nonatomic, assign) BAFSRQualityMode qualityMode;
@property (nonatomic, assign) float sharpness; // 0.0 to 2.0, default 0.2

+ (instancetype)sharedUpscaler;

// Initialize the Metal-based FSR upscaler
- (BOOL)initializeFSR;

// Upscale a CGImage using FSR
- (nullable CGImageRef)upscaleCGImage:(CGImageRef)inputImage;

// Upscale a UIImage using FSR
- (nullable UIImage *)upscaleUIImage:(UIImage *)inputImage;

// Check if the upscaler is ready
- (BOOL)isReady;

// Clear the upscale cache
- (void)clearCache;

// Get scale factor for current quality mode
- (float)currentScaleFactor;

@end

NS_ASSUME_NONNULL_END
