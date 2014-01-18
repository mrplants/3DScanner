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
    self.lengthOfVertexArray = self.numberOfLinesGiven * self.lengthOfPointsOnLine * 6;
    self.lengthOfIndexArray = (self.numberOfLinesGiven - 1) * (self.lengthOfPointsOnLine - 1) * 2 * 3;
    self.vertexArray = malloc(self.numberOfLinesGiven * self.lengthOfPointsOnLine * 6 * sizeof(GLfloat));
    self.indexArray = malloc((self.numberOfLinesGiven - 1) * (self.lengthOfPointsOnLine - 1) * 2 * 3 * sizeof(GLuint));
    
    for (int x = 0; x < self.numberOfLinesGiven; x++) {
        for (int y = 0; y < self.lengthOfPointsOnLine; y+=6) {
            int index = x * self.lengthOfPointsOnLine + y;
            
            CGPoint3D currentPoint = self.pointsArrayOfLines[x][y];
            self.vertexArray[index] = currentPoint.x;
            self.vertexArray[index+1] = currentPoint.y;
            self.vertexArray[index+2] = currentPoint.z;
            
            //calculate normal
            CGPoint3D normal = crossProductWithThreePoints(currentPoint,
                                                           (y < self.lengthOfPointsOnLine-1) ? self.pointsArrayOfLines[x][y+1] : self.pointsArrayOfLines[x+1][y],
                                                           (x < self.numberOfLinesGiven-1) ? self.pointsArrayOfLines[x+1][y] : self.pointsArrayOfLines[x][y-1]);
            self.vertexArray[index+3] = normal.x;
            self.vertexArray[index+4] = normal.y;
            self.vertexArray[index+5] = normal.z;
        }
    }
    
    int counterForIndexArray = 0;
    for (uint x = 0; x < self.numberOfLinesGiven - 1; x++) {
        for (uint y = 0; y < self.lengthOfPointsOnLine - 1; y++) {
            self.indexArray[counterForIndexArray] = counterForIndexArray;
            counterForIndexArray++;
//            // first triangle: '1_0, 1_1, 2_0'
//            self.indexArray[counterForIndexArray++] = x * self.lengthOfPointsOnLine + y;
//            self.indexArray[counterForIndexArray++] = x * self.lengthOfPointsOnLine + y + 1;
//            self.indexArray[counterForIndexArray++] = (x + 1) * self.lengthOfPointsOnLine + y;
//            
//            // second triangle: '1_1, 2_1, 2_0'
//            self.indexArray[counterForIndexArray++] = x * self.lengthOfPointsOnLine + y + 1;
//            self.indexArray[counterForIndexArray++] = (x + 1) * self.lengthOfPointsOnLine + y + 1;
//            self.indexArray[counterForIndexArray++] = (x + 1) * self.lengthOfPointsOnLine + y;
        }
    }
    
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
//    self.vertexArray = malloc(sizeof(float) * 3 * 6);
//    self.indexArray = malloc(sizeof(float) *3);
//    self.vertexArray[0]
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
