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

- (void)setVertexArray:(GLfloat *)vertexArray {
    if (_vertexArray) free(_vertexArray);
    _vertexArray = vertexArray;
}

- (void)setIndexArray:(GLuint *)indexArray {
    if (_indexArray) free(_indexArray);
    _indexArray = indexArray;
}

CGPoint3D shiftPointInXDirection(CGPoint3D pt) {
    CGPoint3D newPt;
    newPt.x = pt.x;
    newPt.y = pt.y;
    newPt.z = pt.z + 0.4;
    return newPt;
}

CGPoint3D crossProductWithThreePoints(CGPoint3D root, CGPoint3D right, CGPoint3D left) {
    GLKVector3 rightVector = GLKVector3Make(right.x - root.x, right.y - root.y, right.z - root.z);
    GLKVector3 leftVector = GLKVector3Make(left.x - root.x, left.y - root.y, left.z - root.z);
    
    return CGPoint3DMakeWithVector(GLKVector3Normalize(GLKVector3CrossProduct(leftVector, rightVector)));
}

- (void)cancelErrorWithHeightsArray:(int **)heights withNumOfColumns:(int)col andRows:(int)row {
    
    GLKVector3 * vectorArray[row];
    
    for (int currentRow = 0; currentRow < row; currentRow++) {
        
        double sAlpha = self.yawAlpha[currentRow], sBeta = self.pitchAlpha[currentRow], sGamma = self.rollAlpha[currentRow];
        
        GLKMatrix3 transformationMatrix = GLKMatrix3Make(cos(sAlpha)*cos(sBeta), cos(sBeta)*sin(sAlpha), -sin(sBeta),
                                                         -cos(sGamma)*sin(sAlpha) + cos(sAlpha)*sin(sBeta)*sin(sGamma), cos(sAlpha)*cos(sGamma) + sin(sAlpha)*sin(sBeta)*sin(sGamma), cos(sBeta)*sin(sGamma),
                                                         cos(sAlpha)*cos(sGamma)*sin(sBeta) + sin(sAlpha)*sin(sGamma), cos(sGamma)*sin(sAlpha)*sin(sBeta) - cos(sAlpha)*sin(sGamma), cos(sBeta)*cos(sGamma));
        
        GLKVector3 shiftVector = GLKVector3Make(self.deltaX[currentRow], self.deltaY[currentRow], self.deltaZ[currentRow]);
        
        GLKVector3 * localVectorArray = malloc(col * sizeof(GLKVector3));
        
        int counter = 0;
        for (int localCol = 0; localCol < col; localCol++) {
            for (int localRow = 0; localRow < row; localRow++) {
                localVectorArray[counter++] = GLKVector3Make(localCol, localRow, heights[localCol][localRow]);
            }
        }
        
        GLKMatrix3MultiplyVector3Array(transformationMatrix, localVectorArray, col);
        
        for (int local = 0; local < counter; local++) {
            localVectorArray[local] = GLKVector3Subtract(localVectorArray[local], shiftVector);
        }
        
        vectorArray[currentRow] = localVectorArray;
    }
    
    // yet to handle output    
    // vectorArray [row * col] consists of all vectors
    // generate mesh
    self.lengthOfVertexArray = (col * 2 - 2) * row * 6;
    self.lengthOfIndexArray = (col * 2 - 2) * row;
    self.vertexArray = malloc(self.lengthOfVertexArray * sizeof(GLfloat));
    self.indexArray = malloc(self.lengthOfIndexArray * sizeof(GLuint));
    
    
    // one line at a time approach
    for (int frame = 0; frame < row; frame++) {
        
        for (int currentColumn = 0; currentColumn < col - 1; currentColumn += 6) {
            
            CGPoint3D rootPoint, rightPoint, leftPoint;
            
            rootPoint.y = vectorArray[frame][currentColumn].y;
            rootPoint.x = vectorArray[frame][currentColumn].x;
            rootPoint.z = vectorArray[frame][currentColumn].z;
            
            rightPoint.y = vectorArray[frame][currentColumn].y;
            rightPoint.x = vectorArray[frame][currentColumn].x;
            rightPoint.z = vectorArray[frame][currentColumn].z;
            rightPoint.z += 0.4;
            
            leftPoint.y = vectorArray[frame][currentColumn + 1].y;
            leftPoint.x = vectorArray[frame][currentColumn + 1].x;
            leftPoint.z = vectorArray[frame][currentColumn + 1].z;
            
            //calculate normal
            CGPoint3D normal = crossProductWithThreePoints(rootPoint, rightPoint, leftPoint);
            
            NSLog(@"index of first point: %d", (frame*6) * col + (row*6));
            
            self.vertexArray[(frame*6) * col + (row*6)] = rootPoint.x;
            self.vertexArray[(frame*6) * col + (row*6) + 1] = rootPoint.y;
            self.vertexArray[(frame*6) * col + (row*6) + 2] = rootPoint.z;
            
            self.vertexArray[(frame*6) * col + (row*6) + 3] = normal.x;
            self.vertexArray[(frame*6) * col + (row*6) + 4] = normal.y;
            self.vertexArray[(frame*6) * col + (row*6) + 5] = normal.z;
            
            self.vertexArray[(frame*6) * col + (row*6) + 6] = rightPoint.x;
            self.vertexArray[(frame*6) * col + (row*6) + 7] = rightPoint.y;
            self.vertexArray[(frame*6) * col + (row*6) + 8] = rightPoint.z;
            
            self.vertexArray[(frame*6) * col + (row*6) + 9] = normal.x;
            self.vertexArray[(frame*6) * col + (row*6) + 10] = normal.y;
            self.vertexArray[(frame*6) * col + (row*6) + 11] = normal.z;
            
            self.vertexArray[(frame*6) * col + (row*6) + 12] = leftPoint.x;
            self.vertexArray[(frame*6) * col + (row*6) + 13] = leftPoint.y;
            self.vertexArray[(frame*6) * col + (row*6) + 14] = leftPoint.z;
            
            self.vertexArray[(frame*6) * col + (row*6) + 15] = normal.x;
            self.vertexArray[(frame*6) * col + (row*6) + 16] = normal.y;
            self.vertexArray[(frame*6) * col + (row*6) + 17] = normal.z;
            
            rootPoint = shiftPointInXDirection(rootPoint);
            leftPoint = leftPoint;
            rightPoint = shiftPointInXDirection(leftPoint);
            //calculate normal
            normal = crossProductWithThreePoints(rootPoint, rightPoint, leftPoint);
            
            NSLog(@"index of second point: %d", (frame*6) * col + ((row+3)*6));
            
            self.vertexArray[(frame*6) * col + ((row+3)*6)] = rootPoint.x;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 1] = rootPoint.y;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 2] = rootPoint.z;
            
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 3] = normal.x;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 4] = normal.y;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 5] = normal.z;
            
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 6] = rightPoint.x;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 7] = rightPoint.y;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 8] = rightPoint.z;
            
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 9] = normal.x;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 10] = normal.y;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 11] = normal.z;
            
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 12] = leftPoint.x;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 13] = leftPoint.y;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 14] = leftPoint.z;
            
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 15] = normal.x;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 16] = normal.y;
            self.vertexArray[(frame*6) * col + ((row+3)*6) + 17] = normal.z;
        }
    }
    
    for (int i = 0; i < self.lengthOfIndexArray; i++) {
        self.indexArray[i] = i;
    }
    [self scalePoints];
}

-(void)scalePoints {
    //find max and create proportion
    float max = 0;
    for (int i = 0; i < self.lengthOfVertexArray; i+=6) {
        if (max < ABS(self.vertexArray[i])) {
            max = self.vertexArray[i];
        }
    }
    float proportion = ABS(1.2/max);
    for (int i = 0; i < self.lengthOfVertexArray; i+=6) {
        self.vertexArray[i] *= proportion;
    }
    
    max = 0;
    for (int i = 0; i < self.lengthOfVertexArray; i+=6) {
        if (max < ABS(self.vertexArray[i+1])) {
            max = self.vertexArray[i+1];
        }
    }
    proportion = ABS(1.2/max);
    for (int i = 0; i < self.lengthOfVertexArray; i+=6) {
        self.vertexArray[i+1] *= proportion;
    }
    
    max = 0;
    for (int i = 0; i < self.lengthOfVertexArray; i+=6) {
        if (max < ABS(self.vertexArray[i+2])) {
            max = self.vertexArray[i+2];
        }
    }
    proportion = ABS(1.2/max);
    for (int i = 0; i < self.lengthOfVertexArray; i+=6) {
        self.vertexArray[i+2] *= proportion;
    }
}

CGPoint3D CGPoint3DMake(float x, float y, float z) {
    CGPoint3D returnPoint;
    returnPoint.x = x;
    returnPoint.y = y;
    returnPoint.z = z;
    return returnPoint;
}

CGPoint3D CGPoint3DMakeWithVector(GLKVector3 vector) {
    CGPoint3D returnPoint;
    returnPoint.x = vector.x;
    returnPoint.y = vector.y;
    returnPoint.z = vector.z;
    return returnPoint;
}


@end
