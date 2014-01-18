//
//  SCTriangleStripCreator.m
//  3DScanner
//
//  Created by Shuyang Li on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCTriangleStripCreator.h"
@import GLKit;

@interface SCTriangleStripCreator ()

CGPoint3D crossProductWithThreePoints(CGPoint3D pt1, CGPoint3D pt2, CGPoint3D pt3);

@end

@implementation SCTriangleStripCreator

- (void)setVertexArray:(GLfloat *)vertexArray {
    if (_vertexArray) free(_vertexArray);
    _vertexArray = vertexArray;
}

- (void)setIndexArray:(GLuint *)indexArray {
    if (_indexArray) free(_indexArray);
    _indexArray = indexArray;
}

-(void)setPointsArrayOfLines:(CGPoint3D **)pointsArrayOfLines {
    if(_pointsArrayOfLines) {
        for (int i = 0; i < self.numberOfLinesGiven; i++) {
            free(_pointsArrayOfLines[i]);
        }
        free(_pointsArrayOfLines);
    }

    for (int i = 0; i < self.numberOfLinesGiven; i++) {
        free(pointsArrayOfLines[i]);
    }
    free(pointsArrayOfLines);

    //TESTTESTTESTTESTTEST
    CGPoint3D pointA;
    CGPoint3D pointB;
    CGPoint3D pointC;
    CGPoint3D pointD;
    pointA.x = 0;
    pointA.y = 0;
    pointA.z = 0;
    pointB.x = 0.5;
    pointB.y = 0;
    pointB.z = 0;
    pointC.x = 0;
    pointC.y = 0.5;
    pointC.z = 0.5;
    pointD.x = 0.5;
    pointD.y = 0;
    pointD.z = 0.5;
    
    pointsArrayOfLines = malloc(sizeof(CGPoint3D *) * 2);
    for (int i = 0; i < 2; i++) {
        pointsArrayOfLines[i] = malloc(sizeof(CGPoint3D) * 2);
    }
    
    self.numberOfLinesGiven = 2;
    self.lengthOfPointsOnLine = 2;
    
    pointsArrayOfLines[0][0] = pointA;
    pointsArrayOfLines[0][1] = pointC;
    pointsArrayOfLines[1][0] = pointB;
    pointsArrayOfLines[1][1] = pointD;
    
    _pointsArrayOfLines = pointsArrayOfLines;
    [self calculate];
}

- (void)dealloc {
    free(_vertexArray);
    free(_indexArray);
}

-(void)scalePoints {
    //find max and create proportion
    float max = 0;
    for (int i = 0; i < self.numberOfLinesGiven; i++) {
        for (int j = 0; j < self.lengthOfPointsOnLine; j++) {
            if (max < ABS(self.pointsArrayOfLines[i][j].x)) {
                max = self.pointsArrayOfLines[i][j].x;
            }
            if (max < ABS(self.pointsArrayOfLines[i][j].y)) {
                max = self.pointsArrayOfLines[i][j].y;
            }
            if (max < ABS(self.pointsArrayOfLines[i][j].z)) {
                max = self.pointsArrayOfLines[i][j].z;
            }
        }
    }
    float proportion = ABS(0.5/max);
    for (int i = 0; i < self.numberOfLinesGiven; i++) {
        for (int j = 0; j < self.lengthOfPointsOnLine; j++) {
            self.pointsArrayOfLines[i][j].x *= proportion;
            self.pointsArrayOfLines[i][j].y *= proportion;
            self.pointsArrayOfLines[i][j].z *= proportion;
        }
    }
}

- (void)calculate {
    [self scalePoints];
    self.lengthOfVertexArray = self.numberOfLinesGiven * 3 * (self.lengthOfPointsOnLine - 2);
    self.lengthOfIndexArray = self.lengthOfVertexArray - 2 * self.numberOfLinesGiven;
    self.vertexArray = malloc(self.lengthOfVertexArray * sizeof(GLfloat) * 6);
    self.indexArray = malloc(self.lengthOfIndexArray * sizeof(GLuint));
    
    
    // one line at a time approach
    for (int x = 0; x < self.numberOfLinesGiven; x++) {
        
        for (int y = 0; y < self.lengthOfPointsOnLine - 1; y+=2) {
            CGPoint3D rootPoint, rightPoint, leftPoint;
            rootPoint = self.pointsArrayOfLines[x][y];
            rightPoint = self.pointsArrayOfLines[x][y+1];
            leftPoint = self.pointsArrayOfLines[x][y+2];
            //calculate normal
            CGPoint3D normal = crossProductWithThreePoints(rootPoint, rightPoint, leftPoint);

            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6)] = rootPoint.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 1] = rootPoint.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 2] = rootPoint.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 3] = normal.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 4] = normal.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 5] = normal.z;

            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 6] = rightPoint.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 7] = rightPoint.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 8] = rightPoint.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 9] = normal.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 10] = normal.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 11] = normal.z;

            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 12] = leftPoint.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 13] = leftPoint.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 14] = leftPoint.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 15] = normal.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 16] = normal.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + (y*6) + 17] = normal.z;
            
            self.indexArray[(x) * self.numberOfLinesGiven + (y*3)] = (x) * self.numberOfLinesGiven + (y*3);
            self.indexArray[(x) * self.numberOfLinesGiven + (y*3)+1] = (x) * self.numberOfLinesGiven + (y*3)+1;
            self.indexArray[(x) * self.numberOfLinesGiven + (y*3)+2] = (x) * self.numberOfLinesGiven + (y*3)+2;

            
            rootPoint = self.pointsArrayOfLines[x][y+1];
            leftPoint = self.pointsArrayOfLines[x][y+2];
            rightPoint = self.pointsArrayOfLines[x][y+3];
            //calculate normal
            normal = crossProductWithThreePoints(rootPoint, rightPoint, leftPoint);
            
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6)] = rootPoint.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 1] = rootPoint.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 2] = rootPoint.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 3] = normal.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 4] = normal.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 5] = normal.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 6] = rightPoint.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 7] = rightPoint.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 8] = rightPoint.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 9] = normal.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 10] = normal.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 11] = normal.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 12] = leftPoint.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 13] = leftPoint.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 14] = leftPoint.z;
            
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 15] = normal.x;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 16] = normal.y;
            self.vertexArray[(x) * self.numberOfLinesGiven + ((y+1)*6) + 17] = normal.z;

            self.indexArray[(x) * self.numberOfLinesGiven + (y*3)+4] = (x) * self.numberOfLinesGiven + (y*3)+4;
            self.indexArray[(x) * self.numberOfLinesGiven + (y*3)+5] = (x) * self.numberOfLinesGiven + (y*3)+5;
            self.indexArray[(x) * self.numberOfLinesGiven + (y*3)+6] = (x) * self.numberOfLinesGiven + (y*3)+6;
            
        }
    }
//            // first triangle: (1, 0), (1, 1), (2, 0)
//            CGPoint3D currentPoint = self.pointsArrayOfLines[x][y];
//            self.vertexArray[counterForVertexArray++] = currentPoint.x;
//            self.vertexArray[counterForVertexArray++] = currentPoint.y;
//            self.vertexArray[counterForVertexArray++] = currentPoint.z;
//            
//            // calculate normal
//            CGPoint3D normal =
//            crossProductWithThreePoints(currentPoint,
//                                        (y < self.lengthOfPointsOnLine-1) ? self.pointsArrayOfLines[x][y+1] : self.pointsArrayOfLines[x+1][y],
//                                        (x < self.numberOfLinesGiven-1) ? self.pointsArrayOfLines[x+1][y] : self.pointsArrayOfLines[x][y-1]);
//            self.vertexArray[counterForVertexArray++] = normal.x;
//            self.vertexArray[counterForVertexArray++] = normal.y;
//            self.vertexArray[counterForVertexArray++] = normal.z;
//            
//
//        }
//    }
    
//    int counterForIndexArray = 0;
//    for (uint x = 0; x < self.numberOfLinesGiven - 1; x++) {
//        for (uint y = 0; y < self.lengthOfPointsOnLine - 1; y++) {
//            self.indexArray[counterForIndexArray] = counterForIndexArray;
//            counterForIndexArray++;
//            // first triangle: '1_0, 1_1, 2_0'
//            self.indexArray[counterForIndexArray++] = x * self.lengthOfPointsOnLine + y;
//            self.indexArray[counterForIndexArray++] = x * self.lengthOfPointsOnLine + y + 1;
//            self.indexArray[counterForIndexArray++] = (x + 1) * self.lengthOfPointsOnLine + y;
//            
//            // second triangle: '1_1, 2_1, 2_0'
//            self.indexArray[counterForIndexArray++] = x * self.lengthOfPointsOnLine + y + 1;
//            self.indexArray[counterForIndexArray++] = (x + 1) * self.lengthOfPointsOnLine + y + 1;
//            self.indexArray[counterForIndexArray++] = (x + 1) * self.lengthOfPointsOnLine + y;
//        }
//    }
    
    NSMutableArray *tempIndexArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.lengthOfIndexArray; i++) {
        [tempIndexArray addObject:[NSNumber numberWithFloat:self.indexArray[i]]];
    }
    NSMutableArray *tempVertexArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < self.lengthOfVertexArray; i++) {
        [tempVertexArray addObject:[NSNumber numberWithFloat:self.vertexArray[i]]];
    }
    
    
//    free(self.vertexArray);
//    free(self.indexArray);
    self.vertexArray = malloc(sizeof(float) * 3 * 6);
    self.lengthOfVertexArray = 3 * 6;
    self.indexArray = malloc(sizeof(uint) *3);
    self.lengthOfIndexArray = 3;
    self.vertexArray[0] = 0.0f;
    self.vertexArray[1] = 0.0f;
    self.vertexArray[2] = 0.0f;
    
    self.vertexArray[3] = 1.0f;
    self.vertexArray[4] = 0.0f;
    self.vertexArray[5] = 0.0f;
    
    self.vertexArray[6] = 0.0f;
    self.vertexArray[7] = 0.5f;
    self.vertexArray[8] = 0.0f;
    
    self.vertexArray[9] = 1.0f;
    self.vertexArray[10] = 0.0f;
    self.vertexArray[11] = 0.0f;
    
    self.vertexArray[12] = 0.0f;
    self.vertexArray[13] = 0.0f;
    self.vertexArray[14] = 0.5f;
    
    self.vertexArray[15] = 1.0f;
    self.vertexArray[16] = 0.0f;
    self.vertexArray[17] = 0.0f;
    
    self.indexArray[0] = 0;
    self.indexArray[1] = 1;
    self.indexArray[2] = 2;
}

CGPoint3D crossProductWithThreePoints(CGPoint3D root, CGPoint3D right, CGPoint3D left) {
    GLKVector3 rightVector = GLKVector3Make(right.x - root.x, right.y - root.y, right.z - root.z);
    GLKVector3 leftVector = GLKVector3Make(left.x - root.x, left.y - root.y, left.z - root.z);
    
    return CGPoint3DMakeWithVector(GLKVector3Normalize(GLKVector3CrossProduct(leftVector, rightVector)));
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
