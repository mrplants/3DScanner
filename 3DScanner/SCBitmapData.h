//
//  SCBitmapData.h
//  3DScanner
//
//  Created by Sean Fitzgerald on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef struct Color {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
} Color;

typedef struct CGPoint3D {
    float x;
    float y;
    float z;
} CGPoint3D;

@interface SCBitmapData : NSObject

@property (nonatomic) NSMutableArray *heightValues;
@property (nonatomic) int imageCount;
@property (nonatomic) int imageWidth;

@property (nonatomic) uint8_t *imageData;
@property (nonatomic) CGSize resolution;

-(void)loadWithPixelBuffer:(CVPixelBufferRef)pixelBuffer;
-(CGPoint3D **)generateTriangleData;
-(NSArray *)extractRedValueHeightDifferences;
Color colorAtlocation(CGPoint point, uint8_t* data, CGSize resolution);

@end