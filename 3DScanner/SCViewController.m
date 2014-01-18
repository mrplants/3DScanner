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
@import GLKit;
@import OpenGLES;

@interface SCViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, GLKViewDelegate> {
    float _curRed;
    BOOL _increasing;
}

@property (nonatomic, strong) AVCaptureSession *videoCaptureSession;
@property (nonatomic, strong) AVCaptureDevice *videoCaptureDevice;
@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (nonatomic) BOOL isProcessingSampleFrame;
@property (nonatomic, strong) SCBitmapData *bitmapAnalyzer;

@property (weak, nonatomic) IBOutlet GLKView *threeDimView;

@end

@implementation SCViewController

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupVideoCamera];
    self.bitmapAnalyzer = [[SCBitmapData alloc] init];
    [self.videoCaptureSession startRunning];
    
    EAGLContext * context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]; // 1
    self.threeDimView.context = context; // 3
    _increasing = YES;
    _curRed = 0.0;
    self.threeDimView.delegate = self; // 4
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    if (_increasing) {
        _curRed += 0.01;
    } else {
        _curRed -= 0.01;
    }
    if (_curRed >= 1.0) {
        _curRed = 1.0;
        _increasing = NO;
    }
    if (_curRed <= 0.0) {
        _curRed = 0.0;
        _increasing = YES;
    }
    
    glClearColor(_curRed, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
//    [self.threeDimView setNeedsDisplay];
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
		
        [self.bitmapAnalyzer loadWithPixelBuffer:pixelBuffer];
//		CGSize bufferResolution = CGSizeMake(CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
//        uint8_t * baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
//        		
//		if (baseAddress)
//			self.recognizedFinderMarkArray = [self.QRPatternFinder getFinderMarkBoxesFromLuminanceBuffer:(uint8_t *)grayBaseAddress
//                                                                                          WithResolution:bufferResolution];
//		free(grayBaseAddress);
//		
//		NSLog(@"Found %d finder pattern marks.", [self.recognizedFinderMarkArray count]);
//        
//		dispatch_async(dispatch_get_main_queue(), ^(void){
//			[self updateFinderPatternBoxesOnDisplay];
//		});
//		//puts the boxes found on the main display
//		
//		self.recognizedFinderMarkArray = [self.QRPatternFinder rectsInRecognizedFinderPatternRectArray:self.recognizedFinderMarkArray
//                                                               MatchRectsInIdealFinderPatternRectArray:self.idealFinderMarkArray];
//		
//		
//		if ([self.recognizedFinderMarkArray count] >= [self.idealFinderMarkArray count])
//			//see if the finder pattern marks match
//		{
//			// all of the finder marks match
//			
//			self.recognizedImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//			
//			dispatch_async(dispatch_get_main_queue(), ^(void){
//				//jump back on the main queue for changing the UI
//				
//				[self performSegueWithIdentifier:@"Image Locked" sender:self];
//                
//			});
//			
//			[self.videoCaptureSession stopRunning];
//			CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
//			return;
//			//stop the current capture session. We've found our image.
//			//If it doesn't stop, it might recognize another image and trigger the segue twice.
//			
//		}
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
		//unlock the pixel buffer - Good practice
		
		self.isProcessingSampleFrame = NO;
		//allow other frame analyses
		
		NSLog(@"Time stamp: after Image Analysis");
	}
}



@end
