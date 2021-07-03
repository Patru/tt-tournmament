//
//  PlayerResult.m
//  Tournament
//
//  Created by Paul Trunz on 19.04.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "PlayerResult.h"
#import "SmallTextController.h"


@implementation PlayerResult

- (PlayerResult *)initFor:(NSString *)plSer points:(long)serPoints;
{
	playerInSeries = plSer;
	points = serPoints;
	
	return self;
}

+ (PlayerResult *)for:(NSString *)plSer points:(long)serPoints;
{
	return [[PlayerResult alloc] initFor:plSer points:serPoints];
}

- (void)appendAsLineTo:(id)text;
{
	[text appendText:[NSString stringWithFormat:@"\t\t%@\t%ld\n", playerInSeries, points]];
}
@end
