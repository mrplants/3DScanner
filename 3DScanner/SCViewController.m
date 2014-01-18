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
@property (nonatomic, strong) SCBitmapData *bitmapAnalyzer;

@property (nonatomic, assign) CGPoint3D ** triangles;

@end

@implementation SCViewController

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self setupVideoCamera];
    self.bitmapAnalyzer = [[SCBitmapData alloc] init];
    [self.videoCaptureSession startRunning];
    
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
		
        [self.bitmapAnalyzer loadWithPixelBuffer:pixelBuffer];
        [self.bitmapAnalyzer extractRedValueHeightDifferences];
		
		CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
		//unlock the pixel buffer - Good practice
        
        if (self.bitmapAnalyzer.imageCount == 15) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                [self renderButtonPressed:nil];
            });
        }
		
		self.isProcessingSampleFrame = NO;
		//allow other frame analyses
		
		NSLog(@"Time stamp: after Image Analysis");
	}
}

- (IBAction)renderButtonPressed:(UIButton *)sender {
    self.triangles = [self.bitmapAnalyzer generateTriangleData];
    [self performSegueWithIdentifier:@"renderSegue" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"renderSegue"]) {
        ScannerGLKViewController * vc = (ScannerGLKViewController*)segue.destinationViewController;
        vc.triangleData = [[SCTriangleStripCreator alloc] init];
        vc.triangleData.numberOfLinesGiven = self.bitmapAnalyzer.imageCount;
        vc.triangleData.lengthOfPointsOnLine = self.bitmapAnalyzer.imageWidth;
        vc.triangleData.pointsArrayOfLines = self.triangles;
    }
    [super prepareForSegue:segue sender:sender];
}


@end
