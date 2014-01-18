//
//  SCTriangleStripCreator.m
//  3DScanner
//
//  Created by Shuyang Li on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import "SCTriangleStripCreator.h"

@implementation SCTriangleStripCreator

- (void)setVertexArray:(GLfloat *)vertexArray {
    free(_vertexArray);
    _vertexArray = vertexArray;
}

- (void)setIndexArray:(GLuint *)indexArray {
    free(_indexArray);
    _indexArray = indexArray;
}

- (void)dealloc {
    free(_vertexArray);
}

- (void)calculate {
    for (int x = 0; x < self.numberOfLinesGiven; x++) {
        
        for (int y = 0; y < self.lengthOfPointsOnLine; y++) {
            
        }
    }
}

@end
