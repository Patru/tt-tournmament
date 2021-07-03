//
//  EloGroup.m
//  Tournament
//
//  Created by Paul Trunz on 28.08.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "EloGroup.h"


@implementation EloGroup
+ (instancetype)groupWithSeries:(Series *)series number:(long)idx;
{
	EloGroup * group = [[EloGroup alloc] initSeries:series number:idx];
	
	return group;
}

- (long) umpiresFrom;
{
	return [players count]/2;
}
@end
