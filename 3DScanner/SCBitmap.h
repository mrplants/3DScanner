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

-(UIColor *) getAverageColorInRect:(CGRect) rect;

-(CIImage *) getCIImage;
-(CGImageRef) getCGImage;
-(UIImage *) getUIImage;

+(UIImage *) imageFromCIImage:(CIImage *) image;
+(UIImage *) imageFromCGImage:(CGImageRef) image;

@end
