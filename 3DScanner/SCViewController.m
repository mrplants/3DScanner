//
//  SCViewController.m
//  3DScanner
//
//  Created by Sean Fitzgerald on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCViewController.h"
@import AVFoundation;
#import "SCBitmapData.h"
#import "ScannerGLKViewController.h"
#import "SCTriangleStripCreator.h"
@import GLKit;
@import OpenGLES;

@interface SCViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *videoCaptureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (nonatomic) BOOL isProcessingSampleFrame;
//@property (nonatomic, strong) SCBitmapData *bitmapAnalyzer;

@property (nonatomic, assign) int ** triangles;
@property (nonatomic, assign) int currentDataFrame;
@property (nonatomic, assign) int numDataFrames;

@property (weak, nonatomic) IBOutlet UIImageView *testImageView;

@end

@implementation SCViewController

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupVideoCamera];
//    self.bitmapAnalyzer = [[SCBitmapData alloc] init];
    [self.videoCaptureSession startRunning];
    
    self.currentDataFrame = 0;
    self.numDataFrames = 15;
    self.triangles = malloc(sizeof(int *) * self.numDataFrames);
    
}

- (void) setupVideoCamera
{
	self.videoCaptureSession = [[AVCaptureSession alloc] init];
	self.videoCaptureSession.sessionPreset = AVCaptureSessionPresetHigh;
	//instantiate the capture session
	
	self.videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	//instantiate the capture device
	
	NSError *error = nil;
	
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.videoCaptureDevice
                                                                        error:&error];
	if (!input) {
		NSLog(@"Error with camera: %@", error);
		return;
	}
	
	[self.videoCaptureSession addInput:input];
	//hook up the session and input
	
	AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
	output.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: kCVPixelFormatType_32BGRA]
                                                       forKey: (id)kCVPixelBufferPixelFormatTypeKey];
	[self.videoCaptureSession addOutput:output];
	
	dispatch_queue_t sampleBufferQueue = dispatch_queue_create("sampleBufferQueue", NULL);
	
	//If the camera is not put on the main queue, the app silently crashes with memory warnings when calling the main
	//Queue from the SampleBuffer delegate method.
	//
	//For now, if we want UI changes from analyzing the camera data, the SampleBuffer must be dispatched to the main queue.
	
	[output setSampleBufferDelegate:self queue: sampleBufferQueue];
	
	AVCaptureConnection *videoConnection = [output connectionWithMediaType:AVMediaTypeVideo];
	if ([videoConnection isVideoOrientationSupported])
	{
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	}
    
	
	AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.videoCaptureSession];
	
	[captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
	[captureVideoPreviewLayer setFrame:self.videoPreviewView.bounds];
	
	CALayer *rootLayer = [self.videoPreviewView layer];
	[rootLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[rootLayer addSublayer:captureVideoPreviewLayer];
	
	[self.videoCaptureSession setSessionPreset:AVCaptureSessionPresetHigh];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.videoCaptureSession startRunning];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.videoCaptureSession stopRunning];
}

#pragma mark -
#pragma mark AVCaptureDevice Delegate Method

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
	//get sample buffer frame
    
	if (!self.isProcessingSampleFrame)
	{
		NSLog(@"Time stamp: Before image analysis");
		self.isProcessingSampleFrame = YES;
		
		// get pixel buffer reference
        CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
		
        // extract needed informations from image buffer
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
		//extracts only the luminance buffer plane
        
        uint8_t *data = malloc(CVPixelBufferGetDataSize(pixelBuffer));
        
        memcpy(data, CVPixelBufferGetBaseAddress(pixelBuffer), CVPixelBufferGetDataSize(pixelBuffer));        
        
        CGSize resolution = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer),
                                     CVPixelBufferGetHeight(pixelBuffer));

        self.triangles[self.currentDataFrame] = getRedHeightsFromPixelBuffer(data, resolution);

        
		//unlock the pixel buffer - Good practice
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        // Get the number of bytes per row for the pixel buffer
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
        
        // Create a device-dependent RGB color space
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        
        
        // Create a bitmap graphics context with the sample buffer data
        CGContextRef context = CGBitmapContextCreate(data, resolution.width, resolution.height, 8,
                                                     bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        // Create a Quartz image from the pixel data in the bitmap graphics context
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        // Unlock the pixel buffer
        
        // Free up the context and color space
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        // Create an image object from the Quartz image
        UIImage *image = [UIImage imageWithCGImage:quartzImage];
        
        // Release the Quartz image
        CGImageRelease(quartzImage);

        
        if (self.triangles[self.currentDataFrame] != NULL) {
            self.currentDataFrame++;
        }
        
        if (self.currentDataFrame == self.numDataFrames) {
            [self.videoCaptureSession stopRunning];
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self renderButtonPressed:nil];
            });
        }
		        free(data);
        dispatch_async(dispatch_get_main_queue(), ^(void){
            self.testImageView.Image = image;
        });

		self.isProcessingSampleFrame = NO;
		//allow other frame analyses
		
		NSLog(@"Time stamp: after Image Analysis");
	}
}

void colorAtlocation(int row, int col, uint8_t* data, int width, int* red, int* green, int*blue)
{
    int index = (col + row * (8+width))*4;
    *blue = data[index];
    *green = data[index+1];
    *red = data[index+2];
    return;
}

int * getRedHeightsFromPixelBuffer(uint8_t * data, CGSize resolution) {

    int red, green, blue, maxRed, maxRedIndex, numSuccessfulLines = 0;
    
#define beforeState 0
#define stateFirstRed 1
#define statewhite 2
#define stateSecondRed 3
    
#define RED (red > 130 && green < 80 && blue < 80)
#define WHITE (red > 120 && green > 120 && blue > 120)
    
    int lineState = beforeState;
    int pixelCount = 0;
    int pixelsThatDontCount = 0;
    BOOL passedStateMachine = NO;
    
    int *heights = malloc(sizeof(int) * resolution.width);
    for (int col = 0; col < resolution.width; col++) {
        maxRed = maxRedIndex = 0;
        pixelCount = 0;
        pixelsThatDontCount = 0;
        lineState = beforeState;
        passedStateMachine = NO;
        for (int row = 0; row < resolution.height; row++) {
            colorAtlocation(row,
                            col,
                            data,
                            resolution.width,
                            &red,
                            &green,
                            &blue);
            
            
            
            if (lineState == beforeState) { //initial state of the Automota machine
                if (RED) { //red pixel found
                    pixelCount++;
                    lineState = stateFirstRed;
                }
            } else if (lineState == stateFirstRed) {//found a line of red pixels
                if (RED) {
                    pixelCount++;
                } else if (WHITE && pixelCount > 5) {
                    pixelCount = 1;
                    pixelsThatDontCount = 0;
                    lineState = statewhite;
                }else if(pixelsThatDontCount > 10) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            } else if (lineState == statewhite) {
                if (WHITE) {
                    pixelCount++;
                } else if (RED && pixelCount <= 350) {
                    pixelCount = 1;
                    pixelsThatDontCount = 0;
                    lineState = stateSecondRed;
                }else if(pixelsThatDontCount > 10) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            } else if (lineState == stateSecondRed) {
                if (RED) {
                    pixelCount++;
                } else if (pixelCount > 2) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                    passedStateMachine = YES;
                }else if(pixelsThatDontCount > 20) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            }
            if (passedStateMachine) {
//                NSLog(@"Passed!");
                numSuccessfulLines++;
                for (int i = -20; i < 20; i++) {
                    if ((row+i) > resolution.height) {
                        continue;
                    }
//                    NSLog(@"width float: %f, width int: %d", resolution.width, (int)resolution.width);
//                    NSLog(@"col: %d, row: %d, row+i:%d", col, row, row+i);
//                    NSLog(@"index:%d", col, row, row+i);
                    data[(col + (row+i) * ((int)resolution.width + 8))*4] = 0;
                    data[(col + (row+i) * ((int)resolution.width + 8))*4+1] = 255;
                    data[(col + (row+i) * ((int)resolution.width + 8))*4+2] = 255;
                    heights[col] = row;

                }
                break;
            }
        }
//        heights[col] = maxRedIndex;
//        for (int i = 0; i < 300; i++) {
//            if (maxRedIndex > resolution.height) {
//                continue;
//            }
//            maxRedIndex++;
//            data[(col + maxRedIndex * (int)resolution.width)*4] = 0;
//            data[(col + maxRedIndex * (int)resolution.width)*4+1] = 0;
//            data[(col + maxRedIndex * (int)resolution.width)*4+2] = 0;
//        }
    }
    if (numSuccessfulLines <= resolution.width / 3) {
        return NULL;
    } else {
        //need to take out the zeroes
//        for (int i = 0; i < resolution.width; i++) {
//            if (heights[i] == 0) {
//                int leftIndex, rightIndex;
//                
//                // j and k are nearest left and right indices with non-zero values
//                for (leftIndex = i; heights[leftIndex] == 0 && leftIndex >= 0; leftIndex--) {}
//                for (rightIndex = i; heights[rightIndex] == 0 && rightIndex <= resolution.width-1; rightIndex++) {}
//                
//                if (leftIndex == 0) { // zero value on left edge
//                    heights[i] = heights[rightIndex];
//                } else if (rightIndex == resolution.width-1) { // zero value on right edge
//                    heights[i] = heights[leftIndex];
//                } else { // average nearest left and right non-zero values
//                    heights[i] = heights[leftIndex] + heights[rightIndex] / 2;
//                }
//            }
//        }
        NSMutableArray * tempHeight = [[NSMutableArray alloc] init];
        for (int i = 0; i < resolution.width; i++) {
            [tempHeight addObject:[NSNumber numberWithInt:heights[i]]];
        }
        //
        return heights;
    }
}

- (IBAction)renderButtonPressed:(UIButton *)sender {
//    self.triangles = [self.bitmapAnalyzer generateTriangleData];
    [self performSegueWithIdentifier:@"renderSegue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"renderSegue"]) {
        ScannerGLKViewController * vc = (ScannerGLKViewController*)segue.destinationViewController;
        vc.triangleData = [[SCTriangleStripCreator alloc] init];
        vc.triangleData.numberOfLinesGiven = self.numDataFrames;//self.bitmapAnalyzer.imageCount;
        vc.triangleData.lengthOfPointsOnLine = 1080; //self.bitmapAnalyzer.imageWidth;
        vc.triangleData.heightData = self.triangles;
//        [vc setupGL];
    }
    [super prepareForSegue:segue sender:sender];
}

UIImage * convert(unsigned char * buffer, int width, int height) {

	size_t bufferLength = width * height * 4;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
	size_t bitsPerComponent = 8;
	size_t bitsPerPixel = 32;
	size_t bytesPerRow = 4 * width;
	
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
	if(colorSpaceRef == NULL) {
		NSLog(@"Error allocating color space");
		CGDataProviderRelease(provider);
		return nil;
	}
	
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedLast;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	CGImageRef iref = CGImageCreate(width,
                                    height,
                                    bitsPerComponent,
                                    bitsPerPixel,
                                    bytesPerRow,
                                    colorSpaceRef,
                                    bitmapInfo,
                                    provider,	// data provider
                                    NULL,		// decode
                                    YES,			// should interpolate
                                    renderingIntent);
    
	uint32_t* pixels = (uint32_t*)malloc(bufferLength);
	
	if(pixels == NULL) {
		NSLog(@"Error: Memory not allocated for bitmap");
		CGDataProviderRelease(provider);
		CGColorSpaceRelease(colorSpaceRef);
		CGImageRelease(iref);
		return nil;
	}
	
	CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 bitmapInfo);
	
	if(context == NULL) {
		NSLog(@"Error context not created");
		free(pixels);
	}
	
	UIImage *image = nil;
	if(context) {
		
		CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);
		
		CGImageRef imageRef = CGBitmapContextCreateImage(context);
		
		// Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
		if([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
			float scale = [[UIScreen mainScreen] scale];
			image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
		} else {
			image = [UIImage imageWithCGImage:imageRef];
		}
		
		CGImageRelease(imageRef);
		CGContextRelease(context);
	}
	
	CGColorSpaceRelease(colorSpaceRef);
	CGImageRelease(iref);
	CGDataProviderRelease(provider);
	
	if(pixels) {
		free(pixels);
	}
	return image;
}

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
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


@end
