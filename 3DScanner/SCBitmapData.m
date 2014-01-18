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

-(NSArray *)extractRedValueHeightDifferences
{
    NSMutableArray *heights = [[NSMutableArray alloc] init];
    CGPoint point;
    int maxRed = 0;
    float minHeight = self.resolution.width, currentHeight;
    self.imageWidth = self.resolution.height;
    
    // Finds pixel with max red in each row and the overall minimun x value for a max red
    for (int i = 0; i < self.resolution.height; i++) // for each row
    {
        maxRed = 0;
        for (int j = 0; j < self.resolution.width; j++) // for each pixel in that row
        {
            // Find max red in that row, store its height
            point.x = j;
            point.y = i;
            Color currentColors = colorAtlocation(point, self.imageData, self.resolution); //[bitmap getColorAtPoint:point];
            if (currentColors.red > maxRed)
            {
                maxRed = currentColors.red; // Worry about =?
                currentHeight = (float)j; // Save in case it's the minimun height overall
            }
        }
        [heights addObject:[NSNumber numberWithFloat:currentHeight]]; // Also store in array for later
        // check for new minimun x value for a max red value
        if (currentHeight < minHeight) minHeight = currentHeight;
    }
    
    // Find the relative height value of each
    for (int i = 0; i < self.resolution.width; i++)
    {
        heights[i] = [NSNumber numberWithFloat:[heights[i] floatValue] - minHeight];
    }
    self.heightValues = [heights copy];
    self.imageCount++;
    return [heights copy];
}

-(CGPoint3D **)generateTriangleData
{
    CGPoint3D **triangles = malloc(sizeof(CGPoint3D *)*self.imageCount);
    CGPoint3D point;
    
    for (int i = 0; i < self.imageCount; i++)
    {
        triangles[i] = malloc(sizeof(CGPoint3D)*self.imageWidth);
    }
    
    // for each image taken (each "line")
    for (int i = 0; i < self.imageCount; i++)
    {
        // for each point in the line
        for (int j = 0; j < self.imageWidth; j++) // TODO should this be <= ?
        {
            point.x = j; // Image number
            point.y = [self.heightValues[j] floatValue]; // "Height" value of the reddest point in that row
            point.z = i; // Point in line from that image
            triangles[i][j] = point;
        }
    }

    NSMutableArray * tempX = [[NSMutableArray alloc] init];
    NSMutableArray * tempY = [[NSMutableArray alloc] init];
    NSMutableArray * tempZ = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.imageCount; i++) {
        for (int j = 0; j < self.imageWidth; j++) {
            [tempX  addObject:[NSNumber numberWithFloat:triangles[i][j].x]];
            [tempY  addObject:[NSNumber numberWithFloat:triangles[i][j].y]];
            [tempZ  addObject:[NSNumber numberWithFloat:triangles[i][j].z]];
        }
    }
    return triangles;
}


@end
