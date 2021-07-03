//
//  TourTableFormatter.m
//  Tournament
//
//  Created by Paul Trunz on Wed Apr 02 2003.
//  Copyright (c) 2003 My own Software Inc. All rights reserved.
//

#import "TourTableFormatter.h"


@implementation TourTableFormatter

- (NSString *)stringForObjectValue:(id)anObject;
{
   int number = [anObject intValue];

   if (number < 10) {
      return [NSString stringWithFormat:@"%d    :   1", [anObject intValue]];
   } else {
      return [NSString stringWithFormat:@"%d  :   1", [anObject intValue]];
   }
}

@end
