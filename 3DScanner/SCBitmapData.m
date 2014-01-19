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

//void colorAtlocation(int row, int col, uint8_t* data, int width, int* red, int* green, int*blue)
//{
//    *red = data[col + row * width+1];
//    *green = data[col + row * width+2];
//    *blue = data[col + row * width+3];
//}
//
//int * getRedHeightsFromPixelBuffer(CVPixelBufferRef pixelBuffer) {
//    uint8_t *data = malloc(CVPixelBufferGetDataSize(pixelBuffer));
//    memcpy(data, CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetDataSize(pixelBuffer));
//    CGSize resolution = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
//                                   CVPixelBufferGetHeight(pixelBuffer));
//    
//    int red, green, blue, maxRed, maxRedIndex;
//
//    int *heights = malloc(sizeof(int) * resolution.height);
//    for (int row = 0; row < resolution.height; row++) {
//        maxRed = 0;
//        for (int col = 0; col < resolution.width; col++) {
//            colorAtlocation(row,
//                            col,
//                            data,
//                            resolution.width,
//                            &red,
//                            &green,
//                            &blue);
//            if (maxRed < red) {
//                maxRed = red;
//                maxRedIndex = (col + row * resolution.width);
//            }
//        }
//        heights[row] = maxRedIndex;
//    }
//    return heights;
//}

-(NSArray *)extractRedValueHeightDifferences
{
    NSMutableArray *heights = [[NSMutableArray alloc] init];
    int maxRed = 0;
    float minHeight = self.resolution.width, currentHeight;
    self.imageWidth = self.resolution.height;
    int red, green, blue;
    
    // Finds pixel with max red in each row and the overall minimun x value for a max red
    for (int i = 0; i < self.resolution.height; i++) // for each row
    {
        maxRed = 0;
        for (int j = 0; j < self.resolution.width; j++) // for each pixel in that row
        {
            colorAtlocation(i,
                            j,
                            self.imageData,
                            self.resolution.width,
                            &red,
                            &green,
                            &blue);
            if (red > maxRed)
            {
                maxRed = red; // Worry about =?
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
