//
//  SCImageHeightExtractor.h
//  3DScanner
//
//  Created by Maribeth Rauh on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "SCBitmap.h"

@interface SCImageHeightExtractor : NSObject
@property (nonatomic) NSMutableArray *heightValues;
@property (nonatomic) int imageCount;
@property (nonatomic) int imageWidth;

typedef struct CGPoint3D {
    float x;
    float y;
    float z;
} CGPoint3D;

-(NSArray *)extractRedValueHeightDifferencesFromBitmap:(SCBitmap *)bitmap;

-(CGPoint3D **)generateTriangleData;

@end
