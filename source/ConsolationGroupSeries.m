/*****************************************************************************
 Use: Control a table tennis tournament (as part of Tournament.app)
 Controls a single group series with consolation round.
 Language: Objective-C                 System: Mac OS X
 Author: Paul Trunz, Copyright 2012, Soft-Werker GmbH
 Version: 0.2, first try
 History: 18.5.2012, Patru: first written
 Bugs: -not very well documented :-)
 *****************************************************************************/

#import "ConsolationGroupSeries.h"
#import "Group.h"
#import "SeriesPlayer.h"
#import "TournamentView.h"


@implementation ConsolationGroupSeries

- (long)maxGroupCount;
{
	long i, grCount = [groups count], max=0;
	
	for(i=0; i<grCount; i++) {
		long gCount = [[[groups objectAtIndex:i] players] count];
		if (max < gCount) {
			max=gCount;
		}
	}
	
	return max;
}
- (void)drawConsolationTable;
{	
	Match *finalTable = matchTable;
	
	[players removeAllObjects];
	[positions removeAllObjects];
	
	[self makePlayersFromGroupsRank:promotees+1 to:[self maxGroupCount]];
	
	[self doSimpleDraw];
	consolationTable=matchTable;
	matchTable=finalTable;
	[tablePages addObject:consolationTable];
	
	NSMutableArray *matches = [NSMutableArray array];		// for numbering consolation
	
	[matches addObject:consolationTable];		// insert match to start from
	numberAllMatches(matches);
	[matches removeAllObjects];	
}

- (BOOL)newGroupDraw;
{
	[super newGroupDraw];
	[self drawConsolationTable];
	
	return YES;
}

- (BOOL)drawTablesFromGroups;
{
	[super drawTablesFromGroups];
	if ([groups count] > 1) {
		[self drawConsolationTable];
	}
	
	return YES;
}

- (NSMutableArray *) matchTables;
{
	NSMutableArray *tables = [super matchTables];
	if (consolationTable  != nil) {
		[tables addObject:consolationTable];
	}
	
	return tables;
}

- paginate:sender;
// paginate table and groups of a series
{
	float top;
	
	[tablePages removeAllObjects];
	[pageGroupStarts removeAllObjects];
	
	if ([matchTable pMatches] > [sender maxMatchOnPage]) {
		master = matchTable;
	}	else {
		master = nil;
	} // if
	[super paginateTable:matchTable in:sender];
	[super paginateTable:consolationTable in:sender];
	// TODO? consolation master?
	[self paginateGroups:sender];
	
	top = [self totalPages] * (int)[sender pageHeight];
	[sender setFrameSize:NSMakeSize([sender pageWidth],top)];
	
	return self;
} // paginate

- (void)encodeWithCoder:(NSCoder *)encoder;
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:consolationTable];
}

- (id)initWithCoder:(NSCoder *)decoder;
{
	self = [super initWithCoder:decoder];
	consolationTable=[decoder decodeObject];
	
	return self;
}

- textRankingListIn:text;
{
	long finalRankings=[matchTable pMatches]+1;
	[matchTable textRankingListIn:text upTo:finalRankings];
	if (consolationTable != nil) {
		[consolationTable appendRankingToText:text upTo:[consolationTable pMatches]+1
															 withOffset:finalRankings];
	} else {		// the odd case of only one group (for which there is no real consolation)
		[self appendGroupRanksAfterPromoteesTo:text withOffset:finalRankings];
	}
	return self;
}

- (void) drawRankingListBelow:(float) top at:(float)ranklistleft;
{
	if ([self finished]) {
		if ([groups count] > 1) {
			long finalRanks = [matchTable pMatches]+1;
			[matchTable drawRankingList:ranklistleft at:&top upTo:finalRanks withOffset:0];
			[consolationTable drawRankingList:ranklistleft at:&top upTo:[consolationTable pMatches]+1 withOffset:finalRanks];
		} else {
			[self drawGroupRankingFrom:0 doneUpTo:0 at:ranklistleft below:top];
		}
	}
}

- (long) smallFinalPage;
{
	return [tablePages count]-1;
}

- (NSString *)postfixFor:(Match *)match;
{
   Match *finalMatch = match;
   
   while ([finalMatch nextMatch] != nil) {
      finalMatch = [finalMatch nextMatch];
   }
   
   if (finalMatch == consolationTable) {
      return NSLocalizedStringFromTable(@"Trostrunde", @"Match", @"Trostrunde für Matchblatt");
   } else {
      return @"";
   }
}

- (NSString *)nameFor:(Match *)match;
{
   return [NSString stringWithFormat:@"%@ %@", fullName, [self postfixFor:match]];
}

@end
