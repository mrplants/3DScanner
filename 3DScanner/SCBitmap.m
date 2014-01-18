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

-(void) loadBitmapWithCIImage:(CIImage *) newImage
{
	CIContext * conversionContext = [CIContext contextWithOptions:nil];
	CGImageRef newImageCG = [conversionContext createCGImage:newImage fromRect:[newImage extent]];
	self.context = createARGBBitmapContext(newImageCG);
	
	//get width and height
	self.resolution = CGSizeMake(CGImageGetWidth(newImageCG), CGImageGetHeight(newImageCG));
	
	CGRect rect = CGRectMake(0, 0, self.resolution.width, self.resolution.height);
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(self.context, rect, newImageCG);
	
	// Now we can get a pointer to the image data associated with the bitmap
	// context.
	self.data = CGBitmapContextGetData(self.context);
	
	self.bytesPerPixel = CGBitmapContextGetBitsPerPixel(self.context) / 8;

}

-(void) loadBitmapWithCGImage:(CGImageRef)newImageCG
{
	self.context = createARGBBitmapContext(newImageCG);
	
	//get width and height
	self.resolution = CGSizeMake(CGImageGetWidth(newImageCG), CGImageGetHeight(newImageCG));
	
	CGRect rect = CGRectMake(0, 0, self.resolution.width, self.resolution.height);
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(self.context, rect, newImageCG);
	
	// Now we can get a pointer to the image data associated with the bitmap
	// context.
	self.data = CGBitmapContextGetData(self.context);
	
	self.bytesPerPixel = CGBitmapContextGetBitsPerPixel(self.context) / 8;
}

-(void) loadBitmapWithPixelBuffer:(CVPixelBufferRef) pixelBuffer
{
	CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
	
	CIContext *temporaryContext = [CIContext contextWithOptions:nil];
	CGImageRef newImageCG = [temporaryContext
													 createCGImage:ciImage
													 fromRect:CGRectMake(0, 0,
																							 CVPixelBufferGetWidth(pixelBuffer),
																							 CVPixelBufferGetHeight(pixelBuffer))];
	
	self.context = createARGBBitmapContext(newImageCG);
	//create a UIImage->CGImage->CGContext

	//get width and height
	self.resolution = CGSizeMake(CGImageGetWidth(newImageCG), CGImageGetHeight(newImageCG));
	
	CGRect rect = CGRectMake(0, 0, self.resolution.width, self.resolution.height);
	
	// Draw the image to the bitmap context. Once we draw, the memory
	// allocated for the context for rendering will then contain the
	// raw image data in the specified color space.
	CGContextDrawImage(self.context, rect, newImageCG);
	
	// Now we can get a pointer to the image data associated with the bitmap
	// context.
	self.data = CGBitmapContextGetData(self.context);
	
	self.bytesPerPixel = CGBitmapContextGetBitsPerPixel(self.context) / 8;
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

-(Color) getColorAtPoint:(CGPoint)point
{
    int index;
    Color pixelColor;
    
    // TODO should handle erroneous input better
    pixelColor.red = -1;
    pixelColor.green = -1;
    pixelColor.blue = -1;
    
    if (self.data != NULL)
    {
        // Check that the given coordinates are within the image
        if (point.x <= self.resolution.width && point.x >= 0 && point.y >= 0 && point.y <= self.resolution.height)
        {
            index = (point.x + point.y * self.resolution.width) * 4;
            pixelColor.red = self.data[index+1];
            pixelColor.green = self.data[index+2];
            pixelColor.blue = self.data[index+3];
        }
        
    }
    return pixelColor;
}

+(uint8_t *) convertARGBPixelBufferToLuminanceBuffer:(CVPixelBufferRef) pixelBuffer
{
	uint8_t * returnLuminanceData = malloc(sizeof(uint8_t *) * CVPixelBufferGetWidth(pixelBuffer) * CVPixelBufferGetHeight(pixelBuffer));
	
	//run the ARM converter
	neon_asm_convert(returnLuminanceData, CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetWidth(pixelBuffer) * CVPixelBufferGetHeight(pixelBuffer));
	
	return returnLuminanceData;
}

-(uint8_t *) getLuminanceBuffer
{
	uint8_t * returnLuminanceData = malloc(sizeof(uint8_t *) * self.resolution.width * self.resolution.height);
	
	//run the ARM converter
	neon_asm_convert(returnLuminanceData, self.data, self.resolution.width * self.resolution.height);
	
	return returnLuminanceData;
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

CGContextRef createARGBBitmapContext (CGImageRef inImage)
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
		fprintf (stderr, "Context not created!");
	}
	
	// Make sure and release colorspace before returning
	CGColorSpaceRelease( colorSpace );
	
	return context;
}

//ARM NEON code to convert from BGRA to grayscale. Very interesting and fast code. This is probably a very good thing to learn.
//link here:http://computer-vision-talks.com/2011/02/a-very-fast-bgra-to-grayscale-conversion-on-iphone/#comment-298
//static void neon_asm_convert(uint8_t * __restrict dest, uint8_t * __restrict src, int numPixels)
//{
//	__asm__ volatile("lsr %2, %2, #3 \n"
//									 "# build the three constants: \n"
//									 "mov r4, #28 \n" // Blue channel multiplier
//									 "mov r5, #151 \n" // Green channel multiplier
//									 "mov r6, #77 \n" // Red channel multiplier
//									 "vdup.8 d4, r4 \n"
//									 "vdup.8 d5, r5 \n"
//									 "vdup.8 d6, r6 \n"
//									 "0: \n"
//									 "# load 8 pixels: \n"
//									 "vld4.8 {d0-d3}, [%1]! \n"
//									 "# do the weight average: \n"
//									 "vmull.u8 q7, d0, d4 \n"
//									 "vmlal.u8 q7, d1, d5 \n"
//									 "vmlal.u8 q7, d2, d6 \n"
//									 "# shift and store: \n"
//									 "vshrn.u16 d7, q7, #8 \n" // Divide q3 by 256 and store in the d7
//									 "vst1.8 {d7}, [%0]! \n"
//									 "subs %2, %2, #1 \n" // Decrement iteration count
//									 "bne 0b \n" // Repeat unil iteration count is not zero
//									 :
//									 : "r"(dest), "r"(src), "r"(numPixels)
//									 : "r4", "r5", "r6"
//									 );
//}

/*
 
 theory of computing
 programming paradigms
 algorithms

*/

@end
