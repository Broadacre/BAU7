//
//  BAImageUpscaler.m
//  BAU7
//
//  FSR (FidelityFX Super Resolution) style upscaling using Metal
//

#import "BAImageUpscaler.h"

// Global variable definition
BOOL useFSRUpscaling = NO;

// Define float4 for use in Objective-C (matches Metal's simd type)
typedef struct {
    float x, y, z, w;
} float4;

// Metal shader source for improved FSR-style EASU (Edge Adaptive Spatial Upsampling)
static NSString *const kFSRShaderSource = @"\
#include <metal_stdlib>\n\
using namespace metal;\n\
\n\
// Compute Lanczos weight for sharper upscaling\n\
float lanczos2(float x) {\n\
    if (x == 0.0) return 1.0;\n\
    if (abs(x) >= 2.0) return 0.0;\n\
    float pi_x = x * 3.14159265359;\n\
    return (sin(pi_x) / pi_x) * (sin(pi_x * 0.5) / (pi_x * 0.5));\n\
}\n\
\n\
// Improved FSR EASU - Edge Adaptive Spatial Upsampling with Lanczos\n\
kernel void fsrEASU(\n\
    texture2d<float, access::sample> inputTexture [[texture(0)]],\n\
    texture2d<float, access::write> outputTexture [[texture(1)]],\n\
    constant float4 &con0 [[buffer(0)]],\n\
    constant float4 &con1 [[buffer(1)]],\n\
    constant float4 &con2 [[buffer(2)]],\n\
    constant float4 &con3 [[buffer(3)]],\n\
    uint2 gid [[thread_position_in_grid]])\n\
{\n\
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) return;\n\
    \n\
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_edge);\n\
    \n\
    float2 outputSize = float2(outputTexture.get_width(), outputTexture.get_height());\n\
    float2 inputSize = float2(inputTexture.get_width(), inputTexture.get_height());\n\
    float2 scale = inputSize / outputSize;\n\
    \n\
    // Calculate input position with sub-pixel precision\n\
    float2 pos = (float2(gid) + 0.5) * scale - 0.5;\n\
    float2 fp = fract(pos);\n\
    int2 ip = int2(floor(pos));\n\
    \n\
    // Sample a 4x4 neighborhood for Lanczos filtering\n\
    float4 result = float4(0.0);\n\
    float weightSum = 0.0;\n\
    \n\
    // Luma weights for edge detection\n\
    float3 lumaWeights = float3(0.299, 0.587, 0.114);\n\
    \n\
    // Gather samples and compute edge information\n\
    float4 samples[4][4];\n\
    float lumas[4][4];\n\
    \n\
    for (int y = -1; y <= 2; y++) {\n\
        for (int x = -1; x <= 2; x++) {\n\
            int2 coord = ip + int2(x, y);\n\
            coord = clamp(coord, int2(0), int2(inputSize) - 1);\n\
            float2 uv = (float2(coord) + 0.5) / inputSize;\n\
            float4 s = inputTexture.sample(textureSampler, uv);\n\
            samples[y + 1][x + 1] = s;\n\
            lumas[y + 1][x + 1] = dot(s.rgb, lumaWeights);\n\
        }\n\
    }\n\
    \n\
    // Compute directional gradients using Sobel for edge detection\n\
    float gx = -lumas[0][0] + lumas[0][2] - 2.0*lumas[1][0] + 2.0*lumas[1][2] - lumas[2][0] + lumas[2][2];\n\
    float gy = -lumas[0][0] - 2.0*lumas[0][1] - lumas[0][2] + lumas[2][0] + 2.0*lumas[2][1] + lumas[2][2];\n\
    float gradientMag = sqrt(gx*gx + gy*gy);\n\
    \n\
    // Determine edge direction\n\
    float2 gradDir = float2(gx, gy);\n\
    if (length(gradDir) > 0.001) {\n\
        gradDir = normalize(gradDir);\n\
    }\n\
    \n\
    // Apply directional Lanczos filtering\n\
    for (int y = -1; y <= 2; y++) {\n\
        for (int x = -1; x <= 2; x++) {\n\
            float2 offset = float2(x, y) - fp;\n\
            \n\
            // Apply directional stretching based on edge strength\n\
            float edgeStretch = 1.0 + gradientMag * 3.0;\n\
            float perpComponent = abs(dot(offset, gradDir));\n\
            float paraComponent = abs(dot(offset, float2(-gradDir.y, gradDir.x)));\n\
            \n\
            // Weight: compress perpendicular to edge, stretch along edge\n\
            float dist = sqrt(perpComponent * perpComponent * edgeStretch + paraComponent * paraComponent / edgeStretch);\n\
            \n\
            // Use Lanczos-2 kernel for sharp results\n\
            float weight = lanczos2(dist);\n\
            \n\
            result += samples[y + 1][x + 1] * weight;\n\
            weightSum += weight;\n\
        }\n\
    }\n\
    \n\
    if (weightSum > 0.0) {\n\
        result /= weightSum;\n\
    }\n\
    \n\
    // Anti-ringing: clamp to local neighborhood bounds with slight overshoot allowed\n\
    float4 minColor = samples[1][1];\n\
    float4 maxColor = samples[1][1];\n\
    for (int y = 0; y <= 2; y++) {\n\
        for (int x = 0; x <= 2; x++) {\n\
            minColor = min(minColor, samples[y][x]);\n\
            maxColor = max(maxColor, samples[y][x]);\n\
        }\n\
    }\n\
    \n\
    // Allow slight overshoot for sharpening\n\
    float4 range = maxColor - minColor;\n\
    minColor -= range * 0.1;\n\
    maxColor += range * 0.1;\n\
    result = clamp(result, minColor, maxColor);\n\
    \n\
    outputTexture.write(result, gid);\n\
}\n\
\n\
// Improved FSR RCAS - Robust Contrast Adaptive Sharpening\n\
kernel void fsrRCAS(\n\
    texture2d<float, access::sample> inputTexture [[texture(0)]],\n\
    texture2d<float, access::write> outputTexture [[texture(1)]],\n\
    constant float &sharpness [[buffer(0)]],\n\
    uint2 gid [[thread_position_in_grid]])\n\
{\n\
    if (gid.x >= outputTexture.get_width() || gid.y >= outputTexture.get_height()) return;\n\
    \n\
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest, address::clamp_to_edge);\n\
    \n\
    float2 texSize = float2(inputTexture.get_width(), inputTexture.get_height());\n\
    float2 tc = (float2(gid) + 0.5) / texSize;\n\
    float2 texelSize = 1.0 / texSize;\n\
    \n\
    // Sample center and 8 neighbors (3x3 kernel)\n\
    float4 e = inputTexture.sample(textureSampler, tc);\n\
    float4 a = inputTexture.sample(textureSampler, tc + float2(-1, -1) * texelSize);\n\
    float4 b = inputTexture.sample(textureSampler, tc + float2( 0, -1) * texelSize);\n\
    float4 c = inputTexture.sample(textureSampler, tc + float2( 1, -1) * texelSize);\n\
    float4 d = inputTexture.sample(textureSampler, tc + float2(-1,  0) * texelSize);\n\
    float4 f = inputTexture.sample(textureSampler, tc + float2( 1,  0) * texelSize);\n\
    float4 g = inputTexture.sample(textureSampler, tc + float2(-1,  1) * texelSize);\n\
    float4 h = inputTexture.sample(textureSampler, tc + float2( 0,  1) * texelSize);\n\
    float4 i = inputTexture.sample(textureSampler, tc + float2( 1,  1) * texelSize);\n\
    \n\
    // Luma for sharpening calculation\n\
    float3 lumaWeights = float3(0.299, 0.587, 0.114);\n\
    float la = dot(a.rgb, lumaWeights);\n\
    float lb = dot(b.rgb, lumaWeights);\n\
    float lc = dot(c.rgb, lumaWeights);\n\
    float ld = dot(d.rgb, lumaWeights);\n\
    float le = dot(e.rgb, lumaWeights);\n\
    float lf = dot(f.rgb, lumaWeights);\n\
    float lg = dot(g.rgb, lumaWeights);\n\
    float lh = dot(h.rgb, lumaWeights);\n\
    float li = dot(i.rgb, lumaWeights);\n\
    \n\
    // Min and max of all neighbors\n\
    float mn = min(min(min(min(la, lb), min(lc, ld)), min(min(le, lf), min(lg, lh))), li);\n\
    float mx = max(max(max(max(la, lb), max(lc, ld)), max(max(le, lf), max(lg, lh))), li);\n\
    \n\
    // Compute local contrast\n\
    float contrast = mx - mn;\n\
    \n\
    // Compute sharpening amount - less sharpening in high contrast areas\n\
    float contrastFactor = 1.0 - saturate(contrast * 2.0);\n\
    float sharpAmt = sharpness * contrastFactor;\n\
    \n\
    // Unsharp mask: center - (neighbors average)\n\
    float4 neighbors = (a + b + c + d + f + g + h + i) / 8.0;\n\
    float4 detail = e - neighbors;\n\
    \n\
    // Apply sharpening\n\
    float4 sharpened = e + detail * sharpAmt;\n\
    \n\
    // Anti-ringing: clamp to local neighborhood bounds\n\
    float4 minNeighbor = min(min(min(min(a, b), min(c, d)), min(min(f, g), min(h, i))), e);\n\
    float4 maxNeighbor = max(max(max(max(a, b), max(c, d)), max(max(f, g), max(h, i))), e);\n\
    \n\
    // Allow slight overshoot for natural sharpness\n\
    float4 rangeN = maxNeighbor - minNeighbor;\n\
    minNeighbor -= rangeN * 0.05;\n\
    maxNeighbor += rangeN * 0.05;\n\
    \n\
    sharpened = clamp(sharpened, minNeighbor, maxNeighbor);\n\
    \n\
    outputTexture.write(float4(sharpened.rgb, e.a), gid);\n\
}\n\
";

@implementation BAImageUpscaler

// Synthesize properties to create instance variables with underscore prefix
@synthesize device = _device;
@synthesize commandQueue = _commandQueue;
@synthesize easuPipeline = _easuPipeline;
@synthesize rcasPipeline = _rcasPipeline;
@synthesize upscaleCache = _upscaleCache;
@synthesize qualityMode = _qualityMode;
@synthesize sharpness = _sharpness;

+ (instancetype)sharedUpscaler {
    static BAImageUpscaler *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[BAImageUpscaler alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _upscaleCache = [[NSCache alloc] init];
        _upscaleCache.countLimit = 500;
        _qualityMode = BAFSRQualityModeQuality;
        _sharpness = 1.0f; // Higher sharpness for pixel art
    }
    return self;
}

- (float)currentScaleFactor {
    switch (_qualityMode) {
        case BAFSRQualityModeUltraQuality:     return 1.3f;
        case BAFSRQualityModeQuality:          return 1.5f;
        case BAFSRQualityModeBalanced:         return 1.7f;
        case BAFSRQualityModePerformance:      return 2.0f;
        case BAFSRQualityModeUltraPerformance: return 3.0f;
        default:                               return 1.5f;
    }
}

- (BOOL)initializeFSR {
    // Get Metal device
    _device = MTLCreateSystemDefaultDevice();
    if (!_device) {
        NSLog(@"BAImageUpscaler: Metal is not supported on this device");
        return NO;
    }
    
    // Create command queue
    _commandQueue = [_device newCommandQueue];
    if (!_commandQueue) {
        NSLog(@"BAImageUpscaler: Failed to create command queue");
        return NO;
    }
    
    // Compile shaders
    NSError *error = nil;
    id<MTLLibrary> library = [_device newLibraryWithSource:kFSRShaderSource
                                                   options:nil
                                                     error:&error];
    if (error) {
        NSLog(@"BAImageUpscaler: Failed to compile shaders: %@", error);
        return NO;
    }
    
    // Create EASU pipeline
    id<MTLFunction> easuFunction = [library newFunctionWithName:@"fsrEASU"];
    if (!easuFunction) {
        NSLog(@"BAImageUpscaler: Failed to find fsrEASU function");
        return NO;
    }
    
    _easuPipeline = [_device newComputePipelineStateWithFunction:easuFunction error:&error];
    if (error) {
        NSLog(@"BAImageUpscaler: Failed to create EASU pipeline: %@", error);
        return NO;
    }
    
    // Create RCAS pipeline
    id<MTLFunction> rcasFunction = [library newFunctionWithName:@"fsrRCAS"];
    if (!rcasFunction) {
        NSLog(@"BAImageUpscaler: Failed to find fsrRCAS function");
        return NO;
    }
    
    _rcasPipeline = [_device newComputePipelineStateWithFunction:rcasFunction error:&error];
    if (error) {
        NSLog(@"BAImageUpscaler: Failed to create RCAS pipeline: %@", error);
        return NO;
    }
    
    NSLog(@"BAImageUpscaler: FSR initialized successfully with Metal");
    return YES;
}

- (BOOL)isReady {
    return _device != nil && _easuPipeline != nil && _rcasPipeline != nil;
}

- (void)clearCache {
    [_upscaleCache removeAllObjects];
}

- (nullable CGImageRef)upscaleCGImage:(CGImageRef)inputImage {
    if (!inputImage) return NULL;
    
    // Check cache first
    NSValue *inputKey = [NSValue valueWithPointer:inputImage];
    NSValue *cachedResult = [_upscaleCache objectForKey:inputKey];
    if (cachedResult) {
        CGImageRef cachedImage;
        [cachedResult getValue:&cachedImage];
        return cachedImage;
    }
    
    // Fall back to Core Graphics if Metal not available
    if (![self isReady]) {
        CGImageRef upscaled = [self upscaleWithCoreGraphics:inputImage];
        if (upscaled) {
            NSValue *resultValue = [NSValue valueWithPointer:upscaled];
            [_upscaleCache setObject:resultValue forKey:inputKey];
        }
        return upscaled;
    }
    
    // Process with Metal FSR
    CGImageRef result = [self processWithFSR:inputImage];
    
    if (result) {
        NSValue *resultValue = [NSValue valueWithPointer:result];
        [_upscaleCache setObject:resultValue forKey:inputKey];
    }
    
    return result;
}

- (CGImageRef)processWithFSR:(CGImageRef)inputImage {
    size_t inputWidth = CGImageGetWidth(inputImage);
    size_t inputHeight = CGImageGetHeight(inputImage);
    
    float scaleFactor = [self currentScaleFactor];
    size_t outputWidth = (size_t)(inputWidth * scaleFactor);
    size_t outputHeight = (size_t)(inputHeight * scaleFactor);
    
    // Create input texture
    MTLTextureDescriptor *inputDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                         width:inputWidth
                                                                                        height:inputHeight
                                                                                     mipmapped:NO];
    inputDesc.usage = MTLTextureUsageShaderRead;
    id<MTLTexture> inputTexture = [_device newTextureWithDescriptor:inputDesc];
    
    // Copy CGImage to input texture
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, inputWidth, inputHeight, 8, inputWidth * 4,
                                                  colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) return NULL;
    
    CGContextDrawImage(context, CGRectMake(0, 0, inputWidth, inputHeight), inputImage);
    void *pixels = CGBitmapContextGetData(context);
    
    [inputTexture replaceRegion:MTLRegionMake2D(0, 0, inputWidth, inputHeight)
                    mipmapLevel:0
                      withBytes:pixels
                    bytesPerRow:inputWidth * 4];
    
    CGContextRelease(context);
    
    // Create intermediate texture for EASU output
    MTLTextureDescriptor *outputDesc = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                          width:outputWidth
                                                                                         height:outputHeight
                                                                                      mipmapped:NO];
    outputDesc.usage = MTLTextureUsageShaderWrite | MTLTextureUsageShaderRead;
    id<MTLTexture> easuOutputTexture = [_device newTextureWithDescriptor:outputDesc];
    id<MTLTexture> rcasOutputTexture = [_device newTextureWithDescriptor:outputDesc];
    
    // Create command buffer
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // EASU pass
    id<MTLComputeCommandEncoder> easuEncoder = [commandBuffer computeCommandEncoder];
    [easuEncoder setComputePipelineState:_easuPipeline];
    [easuEncoder setTexture:inputTexture atIndex:0];
    [easuEncoder setTexture:easuOutputTexture atIndex:1];
    
    // FSR constants (simplified)
    float4 con0 = {(float)inputWidth, (float)inputHeight, (float)outputWidth, (float)outputHeight};
    float4 con1 = {1.0f / inputWidth, 1.0f / inputHeight, 1.0f / outputWidth, 1.0f / outputHeight};
    float4 con2 = {-0.5f / inputWidth, -0.5f / inputHeight, 0, 0};
    float4 con3 = {0, 0, 0, 0};
    
    [easuEncoder setBytes:&con0 length:sizeof(float4) atIndex:0];
    [easuEncoder setBytes:&con1 length:sizeof(float4) atIndex:1];
    [easuEncoder setBytes:&con2 length:sizeof(float4) atIndex:2];
    [easuEncoder setBytes:&con3 length:sizeof(float4) atIndex:3];
    
    MTLSize easuThreadsPerGroup = MTLSizeMake(8, 8, 1);
    MTLSize easuNumGroups = MTLSizeMake((outputWidth + 7) / 8, (outputHeight + 7) / 8, 1);
    [easuEncoder dispatchThreadgroups:easuNumGroups threadsPerThreadgroup:easuThreadsPerGroup];
    [easuEncoder endEncoding];
    
    // RCAS pass (sharpening)
    id<MTLComputeCommandEncoder> rcasEncoder = [commandBuffer computeCommandEncoder];
    [rcasEncoder setComputePipelineState:_rcasPipeline];
    [rcasEncoder setTexture:easuOutputTexture atIndex:0];
    [rcasEncoder setTexture:rcasOutputTexture atIndex:1];
    [rcasEncoder setBytes:&_sharpness length:sizeof(float) atIndex:0];
    
    MTLSize rcasThreadsPerGroup = MTLSizeMake(8, 8, 1);
    MTLSize rcasNumGroups = MTLSizeMake((outputWidth + 7) / 8, (outputHeight + 7) / 8, 1);
    [rcasEncoder dispatchThreadgroups:rcasNumGroups threadsPerThreadgroup:rcasThreadsPerGroup];
    [rcasEncoder endEncoding];
    
    // Commit and wait
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    // Read back result
    void *outputPixels = malloc(outputWidth * outputHeight * 4);
    [rcasOutputTexture getBytes:outputPixels
                    bytesPerRow:outputWidth * 4
                     fromRegion:MTLRegionMake2D(0, 0, outputWidth, outputHeight)
                    mipmapLevel:0];
    
    // Create CGImage from result
    CGColorSpaceRef outputColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef outputContext = CGBitmapContextCreate(outputPixels, outputWidth, outputHeight, 8,
                                                        outputWidth * 4, outputColorSpace,
                                                        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(outputColorSpace);
    
    CGImageRef result = CGBitmapContextCreateImage(outputContext);
    CGContextRelease(outputContext);
    free(outputPixels);
    
    return result;
}

- (CGImageRef)upscaleWithCoreGraphics:(CGImageRef)inputImage {
    if (!inputImage) return NULL;
    
    size_t width = CGImageGetWidth(inputImage);
    size_t height = CGImageGetHeight(inputImage);
    
    float scaleFactor = [self currentScaleFactor];
    size_t newWidth = (size_t)(width * scaleFactor);
    size_t newHeight = (size_t)(height * scaleFactor);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, newWidth, newHeight, 8, newWidth * 4,
                                                  colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    if (!context) return NULL;
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextDrawImage(context, CGRectMake(0, 0, newWidth, newHeight), inputImage);
    
    CGImageRef result = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    
    return result;
}

- (nullable UIImage *)upscaleUIImage:(UIImage *)inputImage {
    if (!inputImage) return nil;
    
    CGImageRef upscaledCGImage = [self upscaleCGImage:inputImage.CGImage];
    if (!upscaledCGImage) return nil;
    
    float scaleFactor = [self currentScaleFactor];
    return [UIImage imageWithCGImage:upscaledCGImage
                               scale:inputImage.scale / scaleFactor
                         orientation:inputImage.imageOrientation];
}

@end
