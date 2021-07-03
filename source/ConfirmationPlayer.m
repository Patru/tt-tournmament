//
//  ConfirmationPlayer.m
//  Tournament
//
//  Created by Paul Trunz on 13.12.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "ConfirmationPlayer.h"


@implementation ConfirmationPlayer

- initWithSeries:(GroupSeries *)aSeries player:(SeriesPlayer *)aSeriesPlayer;
{
	series = aSeries;
	player = aSeriesPlayer;
	
	return self;
}

- (GroupSeries *)series;
{
	return series;
}

- (void)setSeries:(GroupSeries *)aSeries;
{
	series = aSeries;
}

- (SeriesPlayer *)seriesPlayer;
{
	return player;
}

- (NSComparisonResult)compare:(ConfirmationPlayer *)otherObject;
{
	NSComparisonResult res = [[[player player] longName] compare: [[[otherObject seriesPlayer] player] longName]];
	
	if (res != NSOrderedSame) {
		return res;
	} else {
		return [[series fullName] compare: [[otherObject series] fullName]];
	}
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:series];
	[encoder encodeObject:player];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super init];
	series=[decoder decodeObject];
	player=[decoder decodeObject];
	
	return self;
}

@end
