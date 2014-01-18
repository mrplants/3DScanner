//
//  SCImageHeightExtractor.m
//  3DScanner
//
//  Created by Maribeth Rauh on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCImageHeightExtractor.h"

@implementation SCImageHeightExtractor


-(NSArray *)extractRedValueHeightDifferencesFromBitmap:(SCBitmapData *)bitmap
{
    NSMutableArray *heights;
    CGPoint point;
    int maxRed = 0;
    float minHeight = bitmap.resolution.width, currentHeight;
    self.imageWidth = bitmap.resolution.height;
    
    // Finds pixel with max red in each row and the overall minimun x value for a max red
    for (int i = 0; i <= bitmap.resolution.height; i++) // for each row
    {
        for (int j = 0; j <= bitmap.resolution.width; j++) // for each pixel in that row
        {
            // Find max red in that row, store its height
            point.x = j;
            point.y = i;
            Color currentColors = colorAtlocation(point, bitmap.imageData, bitmap.resolution); //[bitmap getColorAtPoint:point];
            if (currentColors.red > maxRed)
            {
                maxRed = currentColors.red; // Worry about =?
                currentHeight = (float)j; // Save in case it's the minimun height overall
                heights[i] = [NSNumber numberWithFloat:currentHeight]; // Also store in array for later
            }
        }
        // check for new minimun x value for a max red value
        if (currentHeight < minHeight) minHeight = currentHeight;
    }
    
    // Find the relative height value of each
    for (int i = 0; i <= bitmap.resolution.width; i++) // TODO should this be < ?
    {
        heights[i] = [NSNumber numberWithFloat:[heights[i] floatValue] - minHeight];
    }
    [self.heightValues addObject:[heights copy]];
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
            point.x = (float)j; // Image number
            point.y = [self.heightValues[j] floatValue]; // "Height" value of the reddest point in that row
            point.z = (float)i; // Point in line from that image
            triangles[i][j] = point;
        }
    }
    return triangles;
}

@end
