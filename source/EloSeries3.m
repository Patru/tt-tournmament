//
//  EloSeries.m
//  Tournament
//
//  Created by Paul Trunz on 27.08.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "EloSeries3.h"
#import "EloGroupSeries.h"
#import "SeriesPlayer.h"
#import "SeriesController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation EloSeries3

- (instancetype)initFromRecord:(PGSQLRecord *)record;
{
	self=[super initFromRecord:record];
	// get the common fields via super
	RankSel = @selector(elo);

	return self;
}

- (void)makeGroupSeries:(long)idx withPlayers:(NSArray *)playersForSeries;
{
	EloGroupSeries *groupSeries = [EloGroupSeries seriesfor:self index:idx players:playersForSeries];
	[[TournamentDelegate.shared seriesController] addWithSeries:groupSeries];
	[[TournamentDelegate.shared seriesController] show:self];
}

- (BOOL)makeTable;
/* ret: YES if the series was drawn correctly (or has already been so)
 what: draws the series according to its sMode (seriesMode)
 */
{
	if (alreadyDrawn) return NO; // we cannot do anything anymore
	
	long all = [players count];
	long groupSize=12;
	long numGroups = all/groupSize;
	if (all%groupSize > 0) {
		numGroups = numGroups+1;
	}
	long numLess, maxPlayers, fullGroups, i, j;
	do {
		maxPlayers = numGroups*groupSize;
		numLess=maxPlayers-all;
		if (numLess > numGroups) {
			groupSize = groupSize - 1;
		}
	} while (numLess > numGroups);
	fullGroups = numGroups-numLess;
	
	int plIndex = 0;
	for (i=0; i<numGroups; i++) {
		long currentSize = groupSize;
		if (i >= fullGroups) {
			currentSize = currentSize-1;
		}
		NSMutableArray *playersForSeries = [NSMutableArray arrayWithCapacity:currentSize];
		for (j=0; j<currentSize; j++) {
			[playersForSeries addObject:[players objectAtIndex:plIndex]];
			plIndex = plIndex+1;
		}
		[self makeGroupSeries:i+1 withPlayers:playersForSeries];
	}
   [[TournamentDelegate.shared seriesController] removeWithSeries:self];
	
	alreadyDrawn=YES;
	
	return alreadyDrawn;
}

@end
