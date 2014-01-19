//
//  SCMeasurementErrorCanceller.m
//  3DScanner
//
//  Created by Shuyang Li on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCMeasurementErrorCanceller.h"
#import "SCBitmapData.h"
#import "SCTriangleStripCreator.h"
@import GLKit;

@interface SCMeasurementErrorCanceller ()

@end

@implementation SCMeasurementErrorCanceller

- (void)cancelErrorWithHeightsArray:(int **)heights withNumOfColumns:(int)col andRows:(int)row {
    
    GLKVector3 vectorArray[row * col];
    
    for (int currentRow = 0; currentRow < row; currentRow++) {
        
        double sAlpha = self.yawAlpha[currentRow], sBeta = self.pitchAlpha[currentRow], sGamma = self.rollAlpha[currentRow];
        
        GLKMatrix3 transformationMatrix = GLKMatrix3Make(cos(sAlpha)*cos(sBeta), cos(sBeta)*sin(sAlpha), -sin(sBeta),
                                                         -cos(sGamma)*sin(sAlpha) + cos(sAlpha)*sin(sBeta)*sin(sGamma), cos(sAlpha)*cos(sGamma) + sin(sAlpha)*sin(sBeta)*sin(sGamma), cos(sBeta)*sin(sGamma),
                                                         cos(sAlpha)*cos(sGamma)*sin(sBeta) + sin(sAlpha)*sin(sGamma), cos(sGamma)*sin(sAlpha)*sin(sBeta) - cos(sAlpha)*sin(sGamma), cos(sBeta)*cos(sGamma));
        
        GLKVector3 shiftVector = GLKVector3Make(self.deltaX[currentRow], self.deltaY[currentRow], self.deltaZ[currentRow]);
        
        GLKVector3 localVectorArray[col];
        
        int counter = 0;
        for (int localCol = 0; localCol < col; localCol++) {
            for (int localRow = 0; localRow < row; localRow++) {
                localVectorArray[counter++] = GLKVector3Make(localCol, localRow, heights[localCol][localRow]);
            }
        }
        
        GLKMatrix3MultiplyVector3Array(transformationMatrix, localVectorArray, col);
        
        for (int local = 0; local < counter; local++) {
            localVectorArray[local] = GLKVector3Subtract(localVectorArray[local], shiftVector);
            vectorArray[local + currentRow * col] = localVectorArray[local];
        }
    }
    
    // yet to handle output    
    // vectorArray [row * col] consists of all vectors
}

@end
