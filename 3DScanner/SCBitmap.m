//
//  SCBitmap.m
//  Serim Explosives Analyzer
//
//  Created by Sean Fitzgerald on 4/4/13.
//  Copyright (c) 2013 Serim Research. All rights reserved.
//

#import "SCBitmap.h"

@implementation SCBitmap

-(void)dealloc
{
	if (self.context) CGContextRelease(self.context);
	if (self.data) free(self.data);
}

//-(void) loadBitmapWithCIImage:(CIImage *) newImage
//{
//	CIContext * conversionContext = [CIContext contextWithOptions:nil];
//	CGImageRef newImageCG = [conversionContext createCGImage:newImage fromRect:[newImage extent]];
//	self.context = createARGBBitmapContext(newImageCG);
//	
//	//get width and height
//	self.resolution = CGSizeMake(CGImageGetWidth(newImageCG), CGImageGetHeight(newImageCG));
//	
//	CGRect rect = CGRectMake(0, 0, self.resolution.width, self.resolution.height);
//	
//	// Draw the image to the bitmap context. Once we draw, the memory
//	// allocated for the context for rendering will then contain the
//	// raw image data in the specified color space.
//	CGContextDrawImage(self.context, rect, newImageCG);
//	
//	// Now we can get a pointer to the image data associated with the bitmap
//	// context.
//	self.data = CGBitmapContextGetData(self.context);
//	
//	self.bytesPerPixel = CGBitmapContextGetBitsPerPixel(self.context) / 8;
//
//}
//
//-(void) loadBitmapWithCGImage:(CGImageRef)newImageCG
//{
//	self.context = createARGBBitmapContext(newImageCG);
//	
//	//get width and height
//	self.resolution = CGSizeMake(CGImageGetWidth(newImageCG), CGImageGetHeight(newImageCG));
//	
//	CGRect rect = CGRectMake(0, 0, self.resolution.width, self.resolution.height);
//	
//	// Draw the image to the bitmap context. Once we draw, the memory
//	// allocated for the context for rendering will then contain the
//	// raw image data in the specified color space.
//	CGContextDrawImage(self.context, rect, newImageCG);
//	
//	// Now we can get a pointer to the image data associated with the bitmap
//	// context.
//	self.data = CGBitmapContextGetData(self.context);
//	
//	self.bytesPerPixel = CGBitmapContextGetBitsPerPixel(self.context) / 8;
//}

-(void) loadBitmapWithPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
    free(self.data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
	CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
	CGImageRef newImageCG = [[CIContext contextWithOptions:nil] createCGImage:ciImage
                                                                     fromRect:CGRectMake(0, 0,
                                                                                         CVPixelBufferGetWidth(pixelBuffer),
                                                                                         CVPixelBufferGetHeight(pixelBuffer))
                                                                       format:kCIFormatARGB8
                                                                   colorSpace:colorSpace];
    
    @autoreleasepool {
        ManipulateImagePixelData(newImageCG);
    }
//    ciImage = nil;
//	// Create the bitmap context. We want pre-multiplied ARGB, 8-bits
//	// per component. Regardless of what the source image format is
//	// (CMYK, Grayscale, and so on) it will be converted over to the format
//	// specified here by CGBitmapContextCreate.
//	CGContextRef myContext = CGBitmapContextCreate (CFDataGetBytePtr(CGDataProviderCopyData(CGImageGetDataProvider(newImageCG))),
//                                                    CGImageGetWidth(newImageCG),
//                                                    CGImageGetHeight(newImageCG),
//                                                    8,      // bits per component
//                                                    CGImageGetWidth(newImageCG) * 4,
//                                                    colorSpace,
//                                                    kCGImageAlphaPremultipliedFirst);
//	//get width and height
//	self.resolution = CGSizeMake(CGImageGetWidth(newImageCG), CGImageGetHeight(newImageCG));
//
//	CGRect rect = CGRectMake(0, 0, self.resolution.width, self.resolution.height);
////	CGContextDrawImage(myContext, rect, newImageCG);
    CGImageRelease(newImageCG);
//	if (myContext == NULL)
//	{
//		fprintf (stderr, "Context not created!");
//	}
//	// Make sure and release colorspace before returning
	CGColorSpaceRelease( colorSpace );
//
//	//create a UIImage->CGImage->CGContext
//	
//	// Draw the image to the bitmap context. Once we draw, the memory
//	// allocated for the context for rendering will then contain the
//	// raw image data in the specified color space.
//    
//	// Now we can get a pointer to the image data associated with the bitmap
//	// context.
////	self.data = CGBitmapContextGetData(myContext);
//
////	self.bytesPerPixel = CGBitmapContextGetBitsPerPixel(myContext) / 8;
//    CGContextRelease(myContext);
}

void ManipulateImagePixelData(CGImageRef inImage)
{
    // Create the bitmap context
    CGContextRef cgctx = CreateARGBBitmapContext(inImage);
//    free(CGBitmapContextGetData(cgctx));
    if (cgctx == NULL)
    {
        // error creating context
        return;
    }
    
    // Get image width, height. We'll use the entire image.
    size_t w = CGImageGetWidth(inImage);
    size_t h = CGImageGetHeight(inImage);
    CGRect rect = {{0,0},{w,h}};
    
    // Draw the image to the bitmap context. Once we draw, the memory
    // allocated for the context for rendering will then contain the
    // raw image data in the specified color space.
    CGContextDrawImage(cgctx, rect, inImage);
    
    // Now we can get a pointer to the image data associated with the bitmap
    // context.
    void *data = CGBitmapContextGetData (cgctx);
    if (data != NULL)
    {
        
        // **** You have a pointer to the image data ****
        
        // **** Do stuff with the data here ****
        
    }
    
    // When finished, release the context
    CGContextRelease(cgctx);
    // Free image data memory for the context
    if (data)
    {
        free(data);
    }
    
}

CGContextRef CreateARGBBitmapContext (CGImageRef inImage)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    void *          bitmapData;
    int             bitmapByteCount;
    int             bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow   = (pixelsWide * 4);
    bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL)
    {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL)
    {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease( colorSpace );
    
    return context;
}


-(void) changeColorAtPoint:(CGPoint)point
										 toRed:(CGFloat)red
										 green:(CGFloat)green
											blue:(CGFloat)blue
{
	if (self.data != NULL)
	{
		
		int index = (point.x + point.y * self.resolution.width) * self.bytesPerPixel;
		
		(self.data)[index] = blue;
		(self.data)[index+1] = green;
		(self.data)[index+2] = red;
		(self.data)[index+3] = 255;
	}
}

-(void) changeColorInRect:(CGRect)rect
										toRed:(CGFloat)red
										green:(CGFloat)green
										 blue:(CGFloat)blue
{
	if (self.data != NULL)
	{
		
		
		int index;
		
		for (int i = rect.origin.x ; i < (rect.origin.x + rect.size.width); i++)
		{
			for (int j = rect.origin.y; j < (rect.origin.y + rect.size.height); j++)
			{
				index = (i + j * self.resolution.width) * 4;

//				(self.data)[index] = (int)255; //alpha
				if (red != -1)
					(self.data)[index+1] = (int)red; //red
				if (green != -1)
					(self.data)[index+2] = (int)green; //green
				if (blue != -1)
					(self.data)[index+3] = (int)blue; //blue
			}
		}
	}
}

-(CIImage *) getCIImage
{
	CGImageRef cgImage = CGBitmapContextCreateImage(self.context);
	CIImage *returnImage = [CIImage imageWithCGImage:cgImage];
	return returnImage;
}

-(CGImageRef) getCGImage
{
	CGImageRef cgImage = CGBitmapContextCreateImage(self.context);
	return cgImage;
}

-(UIImage *) getUIImage
{
	return [UIImage imageWithCGImage:[self getCGImage]];
}

+(UIImage *) imageFromCIImage:(CIImage *) image
{
	CIContext * conversionContext = [CIContext contextWithOptions:nil];
	CGImageRef newImageCG = [conversionContext createCGImage:image fromRect:[image extent]];
	return [UIImage imageWithCGImage:newImageCG];
}

+(UIImage *) imageFromCGImage:(CGImageRef) image
{
	return [UIImage imageWithCGImage:image];
}

-(UIColor *) getAverageColorInRect:(CGRect) rect
{
	UIColor * returnColor = [[UIColor alloc] init];
	
	CGFloat red = 0, green = 0, blue = 0;
	
	if (self.data != NULL)
	{
		
		int index;
		
		for (int i = rect.origin.x ; i < (rect.origin.x + rect.size.width); i++)
		{
			for (int j = rect.origin.y; j < (rect.origin.y + rect.size.height); j++)
			{
				index = (i + j * self.resolution.width) * 4;
								
				red += (self.data)[index+1];
				green += (self.data)[index+2];
				blue += (self.data)[index+3];
			}
		}
		
		
		red = red / (rect.size.width * rect.size.height);
		green = green / (rect.size.width * rect.size.height);
		blue = blue / (rect.size.width * rect.size.height);
		
		
		returnColor = [UIColor colorWithRed:red / 255.0f
																	green:green / 255.0f
																	 blue:blue / 255.0f
																	alpha:1.0f];
		
	}
	
	return returnColor;
}

//CGContextRef createARGBBitmapContext (CGImageRef inImage)
//{
//	CGContextRef    context = NULL;
//	CGColorSpaceRef colorSpace;
//	void *          bitmapData;
//	int             bitmapByteCount;
//	int             bitmapBytesPerRow;
//	
//	// Get image width, height. We'll use the entire image.
//	size_t pixelsWide = CGImageGetWidth(inImage);
//	size_t pixelsHigh = CGImageGetHeight(inImage);
//	
//	// Declare the number of bytes per row. Each pixel in the bitmap in this
//	// example is represented by 4 bytes; 8 bits each of red, green, blue, and
//	// alpha.
//	bitmapBytesPerRow   = (pixelsWide * 4);
//	bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
//	
//	// Use the generic RGB color space.
//	colorSpace = CGColorSpaceCreateDeviceRGB();
//	if (colorSpace == NULL)
//	{
//		fprintf(stderr, "Error allocating color space\n");
//		return NULL;
//	}
//	
//	// Allocate memory for image data. This is the destination in memory
//	// where any drawing to the bitmap context will be rendered.
//	bitmapData = malloc( bitmapByteCount );
//	if (bitmapData == NULL)
//	{
//		fprintf (stderr, "Memory not allocated!");
//		CGColorSpaceRelease( colorSpace );
//		return NULL;
//	}
//	
//	
//	return context;
//}


@end
