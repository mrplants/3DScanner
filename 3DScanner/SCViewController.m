//
//  SCViewController.m
//  3DScanner
//
//  Created by Sean Fitzgerald on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCViewController.h"
@import AVFoundation;
@import CoreMotion;
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

@property (strong, nonatomic) CMMotionManager *motionManager;

@property (strong, nonatomic) NSMutableArray * motionData;

@property (nonatomic, assign) float refPitch;
@property (nonatomic, assign) float refRoll;
@property (nonatomic, assign) float refYaw;

@end

@implementation SCViewController

- (CMMotionManager *)motionManager {
    if (!_motionManager) _motionManager = [[CMMotionManager alloc] init];
//    [_motionManager startAccelerometerUpdates];
//    [_motionManager startGyroUpdates];
    return _motionManager;
}

-(NSMutableArray *)motionData
{
    if (!_motionData) {
        _motionData = [[NSMutableArray alloc] init];
    }
    return _motionData;
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupVideoCamera];
//    self.bitmapAnalyzer = [[SCBitmapData alloc] init];
    [self.videoCaptureSession startRunning];
    
    self.currentDataFrame = 0;
    self.numDataFrames = 2;
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
	
	AVCaptureVideoDataOutput *outputRGB = [[AVCaptureVideoDataOutput alloc] init];
	outputRGB.videoSettings = [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: kCVPixelFormatType_32BGRA]
                                                       forKey: (id)kCVPixelBufferPixelFormatTypeKey];
	[self.videoCaptureSession addOutput:outputRGB];
	
	dispatch_queue_t sampleBufferQueueRGB = dispatch_queue_create("sampleBufferQueueRGB", NULL);
	
	//If the camera is not put on the main queue, the app silently crashes with memory warnings when calling the main
	
	//Queue from the SampleBuffer delegate method.
	//
	//For now, if we want UI changes from analyzing the camera data, the SampleBuffer must be dispatched to the main queue.
	
	[outputRGB setSampleBufferDelegate:self queue: sampleBufferQueueRGB];
	
	AVCaptureConnection *videoConnection = [outputRGB connectionWithMediaType:AVMediaTypeVideo];
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
        
        // get accelerometer and gyro data
//        CMAcceleration acceleration = [self.motionManager accelerometerData].acceleration;
//        CMRotationRate gyroRotationRate = [self.motionManager gyroData].rotationRate;
        
		
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
            if (self.currentDataFrame == 1) {
//                self.refPitch = [self.motionManager gyroData].rotationRate.x;
//                self.refYaw = [self.motionManager gyroData].rotationRate.y;
//                self.refRoll = [self.motionManager gyroData].rotationRate.z;
//                
//                [self.motionManager accelerometerData].acceleration;

            }
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

void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v )
{
    r/=255;
    b/=255;
    g/=255;
	float min, max, delta;
	min = MIN(MIN( r, g), b );
	max = MAX(MAX( r, g), b );
	*v = max;				// v
	delta = max - min;
	if( max != 0 )
		*s = delta / max;		// s
	else {
		// r = g = b = 0		// s = 0, v is undefined
		*s = 0;
		*h = -1;
		return;
	}
	if( r == max )
		*h = ( g - b ) / delta;		// between yellow & magenta
	else if( g == max )
		*h = 2 + ( b - r ) / delta;	// between cyan & yellow
	else
		*h = 4 + ( r - g ) / delta;	// between magenta & cyan
	*h *= 60;				// degrees
	if( *h < 0 )
		*h += 360;
}

int * getRedHeightsFromPixelBuffer(uint8_t * data, CGSize resolution) {

    int red, green, blue, numSuccessfulLines = 0;
    
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

    // finite state machine in RGB
    for (int col = 0; col < resolution.width; col++) {
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
                }
                heights[col] = row;
                break;
            }
        }
////        heights[col] = maxRedIndex;
////        for (int i = 0; i < 300; i++) {
////            if (maxRedIndex > resolution.height) {
////                continue;
////            }
//            maxRedIndex++;
//            data[(col + maxRedIndex * (int)resolution.width)*4] = 0;
//            data[(col + maxRedIndex * (int)resolution.width)*4+1] = 0;
//            data[(col + maxRedIndex * (int)resolution.width)*4+2] = 0;
     //   }
    }
    
    float hue, saturation, brightness;
#define stateDarkBeforeRed 4
#define stateRedAfterDark 5
#define stateDarkafterRed 6
    pixelCount = 0;
    pixelsThatDontCount = 0;
    passedStateMachine = NO;
    
    // finite state machine in HSV dark-bright-dark
    for (int col = 0; col < resolution.width; col++) {
        pixelCount = 0;
        pixelsThatDontCount = 0;
        lineState = beforeState;
        passedStateMachine = NO;
        for (int row = 0; row < resolution.height && heights[col] == 0; row++) {
            colorAtlocation(row, col, data, resolution.width, &red, &green, &blue);
            RGBtoHSV(red, green, blue, &hue, &saturation, &brightness);
            
#define HSVRED ((hue > 300.0  && hue <= 359.0 ) || (hue >= 0 && hue <= 35.0))
#define HSVBRIGHT (brightness >= .70 && saturation >= .50)
#define HSVDARK (brightness <= .50 && saturation <= .70)
            
            if (lineState == beforeState) {
                if (HSVDARK) {
                    pixelCount++;
                    lineState = stateDarkBeforeRed;
                }
            } else if (lineState == stateDarkBeforeRed) {
                if (HSVDARK) {
                    pixelCount++;
                } else if (HSVRED && HSVBRIGHT && pixelCount > 5) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = stateRedAfterDark;
                } else if(pixelsThatDontCount > 15) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            } else if (lineState == stateRedAfterDark) {
                if (HSVRED && HSVBRIGHT) {
                    pixelCount++;
                } else if (pixelCount <= 250 && pixelCount > 5) { //this is saying it's a thin line
                    lineState = stateDarkafterRed;
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                } else if(pixelsThatDontCount > 15) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            } else if (lineState == stateDarkafterRed) {
                if (HSVDARK) {
                    pixelCount++;
                    if (pixelCount > 5) {
                        pixelCount = 0;
                        pixelsThatDontCount = 0;
                        lineState = beforeState;
                        passedStateMachine = YES;
                    }
                } else if(pixelsThatDontCount > 15) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            }
            
            if (passedStateMachine) {
                NSLog(@"Passed!");
                for (int i = -20; i < 20; i++) {
                    if ((row+i) > resolution.height) {
                        continue;
                    }
                    //                    NSLog(@"width float: %f, width int: %d", resolution.width, (int)resolution.width);
                    //                    NSLog(@"col: %d, row: %d, row+i:%d", col, row, row+i);
                    //                    NSLog(@"index:%d", col, row, row+i);
                    data[(col + (row+i) * ((int)resolution.width + 8))*4] = 255;
                    data[(col + (row+i) * ((int)resolution.width + 8))*4+1] = 0;
                    data[(col + (row+i) * ((int)resolution.width + 8))*4+2] = 255;
                    
                }
                break;
            }
        }
    }
    
#define stateBeforeBrightRed 7
#define stateBrightRed 8
#define stateAfterBrightRed 9
    pixelCount = 0;
    pixelsThatDontCount = 0;
    passedStateMachine = NO;
    
    // finite state machine in HSV dark-bright-dark
    for (int col = 0; col < resolution.width; col++) {
        pixelCount = 0;
        pixelsThatDontCount = 0;
        lineState = beforeState;
        passedStateMachine = NO;
        for (int row = 0; row < resolution.height && heights[col] == 0; row++) {
            colorAtlocation(row, col, data, resolution.width, &red, &green, &blue);
            RGBtoHSV(red, green, blue, &hue, &saturation, &brightness);
            
            if (lineState == beforeState) {
                if (!HSVRED) {
                    pixelCount++;
                    lineState = stateBeforeBrightRed;
                }
            } else if (lineState == stateBeforeBrightRed) {
                if (!HSVRED) {
                    pixelCount++;
                } else if (HSVRED && HSVBRIGHT && pixelCount > 5) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = stateBrightRed;
                } else if(pixelsThatDontCount > 15) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            } else if (lineState == stateBrightRed) {
                if (HSVRED && HSVBRIGHT) {
                    pixelCount++;
                } else if (!HSVRED && pixelCount <= 250 && pixelCount > 5) { //this is saying it's a thin line
                    lineState = stateAfterBrightRed;
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                } else if(pixelsThatDontCount > 15) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            } else if (lineState == stateAfterBrightRed) {
                if (!HSVRED) {
                    pixelCount++;
                    if (pixelCount > 5) {
                        pixelCount = 0;
                        pixelsThatDontCount = 0;
                        lineState = beforeState;
                        passedStateMachine = YES;
                    }
                } else if(pixelsThatDontCount > 15) {
                    pixelCount = 0;
                    pixelsThatDontCount = 0;
                    lineState = beforeState;
                } else {
                    pixelsThatDontCount++;
                }
            }
            if (passedStateMachine) {
                NSLog(@"Passed!");
                for (int i = -20; i < 20; i++) {
                    if ((row+i) > resolution.height) {
                        continue;
                    }
                    //                    NSLog(@"width float: %f, width int: %d", resolution.width, (int)resolution.width);
                    //                    NSLog(@"col: %d, row: %d, row+i:%d", col, row, row+i);
                    //                    NSLog(@"index:%d", col, row, row+i);
                    data[(col + (row+i) * ((int)resolution.width + 8))*4] = 255;
                    data[(col + (row+i) * ((int)resolution.width + 8))*4+1] = 0;
                    data[(col + (row+i) * ((int)resolution.width + 8))*4+2] = 255;
                    
                }
                break;
            }
        }
    }
    
    if (numSuccessfulLines <= resolution.width / 3) {
        return NULL;
    } else {
        //need to take out the zeroes
        for (int i = 0; i < resolution.width; i++) {
            if (heights[i] == 0) {
                int leftIndex, rightIndex;
                
                // j and k are nearest left and right indices with non-zero values
                for (leftIndex = i; heights[leftIndex] == 0 && leftIndex > 0; leftIndex--) {}
                for (rightIndex = i; heights[rightIndex] == 0 && rightIndex < resolution.width - 1; rightIndex++) {}
                
                if (leftIndex == 0) { // zero value on left edge
                    heights[i] = heights[rightIndex];
                    //                    NSLog(@"%d %d", heights[leftIndex], heights[rightIndex]);
                } else if (rightIndex == resolution.width-1) { // zero value on right edge
                    heights[i] = heights[leftIndex];
                    //                    NSLog(@"%d %d", heights[leftIndex], heights[rightIndex]);
                } else { // average nearest left and right non-zero values
                    int temp = (heights[leftIndex] + heights[rightIndex]) / 2;
                    heights[i] = temp;
                }
            }
        }
        NSMutableArray * tempHeight = [[NSMutableArray alloc] init];
        for (int i = 0; i < resolution.width; i++) {
            [tempHeight addObject:[NSNumber numberWithInt:heights[i]]];
        }
        
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

@end
