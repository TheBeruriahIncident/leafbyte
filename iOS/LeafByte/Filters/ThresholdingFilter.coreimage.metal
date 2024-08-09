//
//  ThresholdingFilter.coreimage.metal
//  LeafByte
//
//  Created by Abigail Getman-Pickering on 8/9/24.
//  Copyright © 2024 Abigail Getman-Pickering. All rights reserved.
//

// Using https://ikyle.me/blog/2022/creating-a-coreimage-filter-with-a-metal-kernel for setting up a Metal filter
#include <metal_stdlib>
using namespace metal;
#include <CoreImage/CoreImage.h>

// This vector transforms RGB to luma, or intensity ( https://en.wikipedia.org/wiki/YUV#Conversion_to/from_RGB ).
constant float3 rgbToLuma = float3(0.299, 0.587, 0.114);
// 0 for alpha ( https://en.wikipedia.org/wiki/Alpha_compositing ) makes it invisible.
constant float4 invisiblePixel = float4(0.0);

/*
 These kernels are applied to each pixel individually.
 If the pixel is more/less intense (based on the background color), return invisible; otherwise, return a pixel of the actual (saturated) image.
 Note that we've copied-pasted the function for the two different background colors. This is to avoid unnecessary branching inside a kernel, for performance reasons.
 */

extern "C" float4 thresholdWhiteBackground(coreimage::sample_t originalPixel, coreimage::sample_t saturatedPixel, float threshold, coreimage::destination destination) {
    float luma = dot(originalPixel.rgb, rgbToLuma);
    return luma < threshold ? float4(saturatedPixel.rgb, 1) : invisiblePixel;
}

extern "C" float4 thresholdBlackBackground(coreimage::sample_t originalPixel, coreimage::sample_t saturatedPixel, float threshold, coreimage::destination destination) {
    float luma = dot(originalPixel.rgb, rgbToLuma);
    return luma > threshold ? float4(saturatedPixel.rgb, 1) : invisiblePixel;
}
