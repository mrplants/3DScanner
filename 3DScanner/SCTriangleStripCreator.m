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

GLKVector3 crossProductWithThreePoints(CGPoint3D pt1, CGPoint3D pt2, CGPoint3D pt3);

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

- (void)dealloc {
    free(_vertexArray);
    free(_indexArray);
}

- (void)calculate {
    
    self.vertexArray = malloc(self.numberOfLinesGiven * self.lengthOfPointsOnLine * 6 * sizeof(GLfloat));
    self.indexArray = malloc((self.numberOfLinesGiven - 1) * (self.lengthOfPointsOnLine - 1) * 2 * 3 * sizeof(GLuint));
    
    for (int x = 0; x < self.numberOfLinesGiven; x++) {
        // doubling up the first point
        for (int y = 0; y < self.lengthOfPointsOnLine; y++) {
            
        }
        // doubling up the last point
    }
}

GLKVector3 crossProductWithThreePoints(CGPoint3D root, CGPoint3D right, CGPoint3D left) {
    GLKVector3 rightVector = GLKVector3Make(right.x - root.x, right.y - root.y, right.z - root.z);
    GLKVector3 leftVector = GLKVector3Make(left.x - root.x, left.y - root.y, left.z - root.z);
    
    return GLKVector3CrossProduct(leftVector, rightVector);
}

@end
