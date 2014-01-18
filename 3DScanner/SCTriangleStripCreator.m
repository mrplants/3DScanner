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

- (void)calculate {
    
    self.vertexArray = malloc(self.numberOfLinesGiven * self.lengthOfPointsOnLine * 6 * sizeof(GLfloat));

    self.indexArray = malloc((self.numberOfLinesGiven - 1) * (self.lengthOfPointsOnLine - 1) * 6 * sizeof(GLuint));
    
    for (int x = 0; x < self.numberOfLinesGiven; x++) {
        // doubling up the first point
        for (int y = 0; y < self.lengthOfPointsOnLine; y++) {
            
        }
        // doubling up the last point
    }
}

@end
