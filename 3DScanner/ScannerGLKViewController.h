//
//  ScannerGLKViewController.h
//  3DScanner
//
//  Created by Sean Fitzgerald on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <GLKit/GLKit.h>
#import "SCTriangleStripCreator.h"

@interface ScannerGLKViewController : GLKViewController

@property (nonatomic, strong) SCTriangleStripCreator *triangleData;

-(void)setupGL;
@end
