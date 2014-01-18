//
//  SCBitmapData.m
//  3DScanner
//
//  Created by Sean Fitzgerald on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCBitmapData.h"

@implementation SCBitmapData

-(void)loadWithPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    self.imageData = malloc(CVPixelBufferGetDataSize(pixelBuffer));
    memcpy(self.imageData, CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetDataSize(pixelBuffer));
    self.resolution = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                 CVPixelBufferGetHeight(pixelBuffer));
}

Color colorAtlocation(CGPoint point, uint8_t* data, CGSize resolution)
{
    
}

@end
