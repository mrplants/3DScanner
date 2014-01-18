//
//  SCHeightMapTranslator.h
//  3DScanner
//
//  Created by Shuyang Li on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SCHeightMapTranslator : NSObject

// designated initializer
- (id)initWithArrayOfLength:(NSArray *)arrayOfLength;

// retrieving height data
- (float)getHeightAtIndex:(int)index;

@end
