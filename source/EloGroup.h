//
//  EloGroup.h
//  Tournament
//
//  Created by Paul Trunz on 28.08.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "Series.h"


@interface EloGroup : Group {

}
+ (instancetype)groupWithSeries:(Series *)series number:(long)idx;
@end
