//
//  SCMeasurementErrorCanceller.m
//  3DScanner
//
//  Created by Shuyang Li on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCMeasurementErrorCanceller.h"
@import GLKit;

@interface SCMeasurementErrorCanceller ()

- (void)generateMatrix;

@end

@implementation SCMeasurementErrorCanceller

- (void)cancelErrorWithHeightsArray:(int **)heights withNumOfColumns:(int)col andRows:(int)row {
    
    double sAlpha = self.yawAlpha, sBeta = self.pitchAlpha, sGamma = self.rollAlpha;
    
    GLKMatrix3 transformationMatrix = GLKMatrix3Make(cos(sAlpha)*cos(sBeta), cos(sBeta)*sin(sAlpha), -sin(sBeta),
                                                     -cos(sGamma)*sin(sAlpha) + cos(sAlpha)*sin(sBeta)*sin(sGamma), cos(sAlpha)*cos(sGamma) + sin(sAlpha)*sin(sBeta)*sin(sGamma), cos(sBeta)*sin(sGamma),
                                                     cos(sAlpha)*cos(sGamma)*sin(sBeta) + sin(sAlpha)*sin(sGamma), cos(sGamma)*sin(sAlpha)*sin(sBeta) - cos(sAlpha)*sin(sGamma), cos(sBeta)*cos(sGamma));
    GLKVector3 shiftVector = GLKVector3Make(self.deltaX, self.deltaY, self.deltaZ);
    
    for (int localCol = 0; localCol < col; localCol++) {
        for (int localRow = 0; localRow < row; localRow++) {
            GLKVector3 currentVector = GLKVector3Make(localCol, localRow, heights[localCol][localRow]); // check order
            GLKVector3 reverseTransformedVector =
            GLKVector3Subtract(GLKMatrix3MultiplyVector3(transformationMatrix, currentVector), shiftVector);
            
            
        }
    }
    
}

- (void)generateMatrix {
    
}

@end
