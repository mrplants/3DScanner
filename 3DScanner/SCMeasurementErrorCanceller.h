//
//  SCMeasurementErrorCanceller.h
//  3DScanner
//
//  Created by Shuyang Li on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCMeasurementErrorCanceller : NSObject

// input for cancellation
@property (nonatomic, assign) float * yawAlpha;
@property (nonatomic, assign) float * pitchAlpha;
@property (nonatomic, assign) float * rollAlpha;

@property (nonatomic, assign) float * deltaX;
@property (nonatomic, assign) float * deltaY;
@property (nonatomic, assign) float * deltaZ;

// method to cancel error
- (void)cancelErrorWithHeightsArray:(int **)heights withNumOfColumns:(int)col andRows:(int)row;

// output
@property (nonatomic, assign) GLfloat * vertexArray;
@property (nonatomic, assign) int lengthOfVertexArray;
@property (nonatomic, assign) GLuint * indexArray;
@property (nonatomic, assign) int lengthOfIndexArray;

@end
