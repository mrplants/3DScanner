//
//  SCTriangleStripCreator.h
//  3DScanner
//
//  Created by Shuyang Li on 1/18/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SCBitmapData.h"

@interface SCTriangleStripCreator : NSObject

// array of points - input
@property (nonatomic, assign) CGPoint3D ** pointsArrayOfLines;
@property (nonatomic, assign) int ** heightData;
@property (nonatomic, assign) int numberOfLinesGiven;
@property (nonatomic, assign) int lengthOfPointsOnLine;

// output
@property (nonatomic, assign) GLfloat * vertexArray;
@property (nonatomic, assign) int lengthOfVertexArray;
@property (nonatomic, assign) GLuint * indexArray;
@property (nonatomic, assign) int lengthOfIndexArray;

- (void)calculate;

@end
