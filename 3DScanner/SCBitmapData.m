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
    if (self.imageData) {
        free(self.imageData);
    }
    self.imageData = malloc(CVPixelBufferGetDataSize(pixelBuffer));
    memcpy(self.imageData, CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetDataSize(pixelBuffer));
    self.resolution = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                 CVPixelBufferGetHeight(pixelBuffer));
}

Color colorAtlocation(CGPoint point, uint8_t* data, CGSize resolution)
{
    int index;
    Color pixelColor;
    
    // TODO should handle erroneous input better
    pixelColor.red = -1;
    pixelColor.green = -1;
    pixelColor.blue = -1;
    
    if (data != NULL)
    {
        // Check that the given coordinates are within the image
        if (point.x <= resolution.width && point.x >= 0 && point.y >= 0 && point.y <= resolution.height)
        {
            index = (point.x + point.y * resolution.width) * 4;
            pixelColor.red = data[index+1];
            pixelColor.green = data[index+2];
            pixelColor.blue = data[index+3];
        }
        
    }
    return pixelColor;
}

@end
