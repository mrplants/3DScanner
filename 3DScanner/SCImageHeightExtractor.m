//
//  SCImageHeightExtractor.m
//  3DScanner
//
//  Created by Maribeth Rauh on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCImageHeightExtractor.h"

@implementation SCImageHeightExtractor

-(NSArray *)extractRedValueHeightDifferencesFromBitmap:(SCBitmap *)bitmap
{
    NSMutableArray *heightValues;
    CGPoint point;
    int maxRed = 0;
    float minHeight = bitmap.resolution.width, currentHeight;
    
    // Finds pixel with max red in each row and the overall minimun x value for a max red
    for (int i = 0; i <= bitmap.resolution.height; i++) // for each row
    {
        for (int j = 0; j <= bitmap.resolution.width; j++) // for each pixel in that row
        {
            // Find max red in that row, store its height
            point.x = j;
            point.y = i;
            Color currentColors = [bitmap getColorAtPoint:point];
            if (currentColors.red > maxRed)
            {
                maxRed = currentColors.red; // Worry about =?
                currentHeight = (float)j; // Save in case it's the minimun height overall
                heightValues[i] = [NSNumber numberWithFloat:currentHeight]; // Also store in array for later
            }
        }
        // check for new minimun x value for a max red value
        if (currentHeight < minHeight) minHeight = currentHeight;
    }
    
    // Find the relative height value of each
    for (int i = 0; i <= bitmap.resolution.width; i++)
    {
        heightValues[i] = [NSNumber numberWithFloat:[heightValues[i] floatValue] - minHeight];
    }
    return [heightValues copy];
}

@end
