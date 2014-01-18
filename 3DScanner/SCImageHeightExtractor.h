//
//  SCImageHeightExtractor.h
//  3DScanner
//
//  Created by Maribeth Rauh on 1/17/14.
//  Copyright (c) 2014 Sean T Fitzgerald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>
#import "SCBitmap.h"

@interface SCImageHeightExtractor : NSObject

-(NSArray *)extractRedValueHeightDifferencesFromBitmap:(SCBitmap *)bitmap;

@end
