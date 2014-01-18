//
//  SEABitmap.h
//  Serim Explosives Analyzer
//
//  Created by Sean Fitzgerald on 4/4/13.
//  Copyright (c) 2013 Serim Research. All rights reserved.
//

@import Foundation;
@import QuartzCore;
@import CoreGraphics;
@import CoreImage;

@interface SCBitmap : NSObject

@property (nonatomic) CGContextRef context;
@property (nonatomic) CGSize resolution;
@property (nonatomic) int bytesPerPixel;

@property (nonatomic) uint8_t * data;

typedef struct Color {
    int red;
    int green;
    int blue;
} Color;

-(void) loadBitmapWithCIImage:(CIImage *) newImageCG;
-(void) loadBitmapWithCGImage:(CGImageRef)newImage;
-(void) loadBitmapWithPixelBuffer:(CVPixelBufferRef) pixelBuffer;

-(void) changeColorAtPoint:(CGPoint)point
										 toRed:(CGFloat)red
										 green:(CGFloat)green
											blue:(CGFloat)blue;

-(void) changeColorInRect:(CGRect)rect
										toRed:(CGFloat)red
										green:(CGFloat)green
										 blue:(CGFloat)blue;

-(Color) getColorAtPoint:(CGPoint)point;

-(UIColor *) getAverageColorInRect:(CGRect) rect;

-(uint8_t *) getLuminanceBuffer;

-(CIImage *) getCIImage;
-(CGImageRef) getCGImage;
-(UIImage *) getUIImage;

+(UIImage *) imageFromCIImage:(CIImage *) image;
+(UIImage *) imageFromCGImage:(CGImageRef) image;

+(uint8_t *) convertARGBPixelBufferToLuminanceBuffer:(CVPixelBufferRef) pixelBuffer;

@end
