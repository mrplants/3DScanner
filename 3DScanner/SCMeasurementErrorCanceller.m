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
    
    double sAlpha = self.yawAlpha, sBeta = self.pitchAlpha, sGamma = self.rollAlpha;
    
    GLKMatrix3 transformationMatrix = GLKMatrix3Make(cos(sAlpha)*cos(sBeta), cos(sBeta)*sin(sAlpha), -sin(sBeta),
                                                     -cos(sGamma)*sin(sAlpha) + cos(sAlpha)*sin(sBeta)*sin(sGamma), cos(sAlpha)*cos(sGamma) + sin(sAlpha)*sin(sBeta)*sin(sGamma), cos(sBeta)*sin(sGamma),
                                                     cos(sAlpha)*cos(sGamma)*sin(sBeta) + sin(sAlpha)*sin(sGamma), cos(sGamma)*sin(sAlpha)*sin(sBeta) - cos(sAlpha)*sin(sGamma), cos(sBeta)*cos(sGamma));
    GLKVector3 shiftVector = GLKVector3Make(self.deltaX, self.deltaY, self.deltaZ);
    
    int vArraySize = col * row;
    GLKVector3 vectorArray[vArraySize];
    
    int counter = 0;
    for (int localCol = 0; localCol < col; localCol++) {
        for (int localRow = 0; localRow < row; localRow++) {
            vectorArray[counter++] = GLKVector3Make(localCol, localRow, heights[localCol][localRow]);
        }
    }
    
    GLKMatrix3MultiplyVector3Array(transformationMatrix, vectorArray, vArraySize);
    
    for (int local = 0; local < counter; local++) {
        vectorArray[counter] = GLKVector3Subtract(vectorArray[counter], shiftVector);
    }
    
    // yet to handle output
    
    self.lengthOfVertexArray = (self.lengthOfPointsOnLine * 2 - 2) * self.numberOfLinesGiven * 6;
    self.lengthOfIndexArray = (self.lengthOfPointsOnLine * 2 - 2) * self.numberOfLinesGiven;
    self.vertexArray = malloc(self.lengthOfVertexArray * sizeof(GLfloat));
    self.indexArray = malloc(self.lengthOfIndexArray * sizeof(GLuint));

    // vectorArray: array of GLKVector3 that's the final vectors of transformation
    for (int local = 0; local < counter; local++) {
        vectorArray[counter]
    }
    
    
}

@end
