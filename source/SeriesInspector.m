//
//  SeriesInspector.m
//  Tournament
//
//  Created by Paul Trunz on 14.03.17.
//  Copyright 2017 __MyCompanyName__. All rights reserved.
//

#import "SeriesInspector.h"


@implementation SeriesInspector

- init;
{
	self=[super init];
	[[NSBundle mainBundle] loadNibNamed:@"SeriesInspectors" owner:self topLevelObjects:nil];
	_series=nil;
	_option=0;
	
	return self;
}

- (NSView *)filledViewForOption:(long) option;
{
	_option=option;
	switch(_option) {
		case 0: {
			[self fillPlayerView];
			return playerView;
		}
		case 1: {
			[self fillMatchView];
			return matchView;
		}
	}
	return nil;
}

- (void)fillMatchView;
{
	[[statistik cellAtIndex:0] setIntValue:(int)[_series numberOfMatches]];
	[[statistik cellAtIndex:1] setIntValue:(int)[_series numberOfUnplayedMatches]];
	[[statistik cellAtIndex:2] setIntValue:(int)[_series numberOfGroupsDrawn]];
	[[statistik cellAtIndex:3] setIntValue:(int)[_series numberOfUnplayedGroups]];
	[[statistik cellAtIndex:4] setIntValue:(int)[_series furthestRound]];
	[[statistik cellAtIndex:5] setIntValue:(int)[_series sternmostRound]];
   [[statistik cellAtIndex:6] setIntValue:(int)[[_series players] count]];
}

- (void)fillPlayerView;
{	
	[[details cellAtIndex:0] setStringValue:[_series fullName]];
	[[details cellAtIndex:1] setStringValue:[_series seriesName]];
	[[details cellAtIndex:2] setStringValue:[_series sex]];
	[[details cellAtIndex:3] setIntValue:(int)[_series minRanking]];
   [[details cellAtIndex:4] setIntValue:(int)[_series maxRanking]];
   [[details cellAtIndex:5] setIntValue:(int)[_series bestOfSeven]];
   [[details cellAtIndex:6] setStringValue:[_series startTime]];
   [[details cellAtIndex:7] setFloatValue:[_series coefficient]];
}

- (void)setSeries:(Series *)aSeries;
{
	_series = aSeries;
}

- (void)updateFromView;
{
   switch(_option) {
      case 0: {
         [self updateFromPlayerView];
      }
      case 1: {
         // not available
      }
   }
}

- (void)updateFromPlayerView;
{
   [_series setStartTime:[[details cellAtIndex:6] stringValue]];
   [_series setCoefficient:[[details cellAtIndex:7] floatValue]];
}

- (IBAction)playSingleMatchesForAllOpenGroups:sender;
{
	[_series playSingleMatchesForAllOpenGroups];
}
@end
