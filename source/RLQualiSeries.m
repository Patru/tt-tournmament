//
//  RLQualiSeries.m
//  Tournament
//
//  Created by Paul Trunz on 11.11.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "RLQualiSeries.h"
#import "GroupPosition.h"
#import "RLGroup.h"
#import "RLGroupPlayer.h"
#import "Series.h"
#import "SeriesPlayer.h"
#import "SmallTextController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

void extern printAllMatches(NSMutableArray *matches);		// forward declaration

@implementation RLQualiSeries

-(instancetype)init
{
   self=[super init];
   RankSel = @selector(elo);
	matchTables = [[NSMutableArray alloc] init];
   return self;
} // init

- (instancetype)initFromRecord:(PGSQLRecord *)record;
{
   self=[super initFromRecord:record];
   matchTables = [[NSMutableArray alloc] init];
   RankSel = @selector(elo);
   return self;
}

- (BOOL)useAllGroupsForSecondStage;
{
	return isupper(sMode);
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:matchTables];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	matchTables=[decoder decodeObject];
	
	return self;
}

- (NSMutableArray *) matchTables;
{
	return matchTables;
}

- (BOOL)newGroupDraw
{
   long i, max = [players count];
   NSMutableArray *playerLists = [NSMutableArray array];
	
   groups = [[NSMutableArray alloc] init];		// there will be groups
	groupPlayers = players;
	
   long numberOfGroups = [self numberOfGroups];
	
   for(i = 0; i < numberOfGroups; i++) {
      [groups addObject:[[Group alloc] initSeries:self number:i+1]];
      [playerLists addObject:[NSMutableArray array]];
   }
	
	for (i=0; i < max; i++) {
		long groupIndex = i%numberOfGroups;
		long groupPosition = i/numberOfGroups;
		if (groupPosition%2 == 1) {
			groupIndex = numberOfGroups - groupIndex -1;
		}
		[[playerLists objectAtIndex:groupIndex] addObject:[[players objectAtIndex:i] player]];
	}
   
   [self optimizeClubsInLists:playerLists];
	
	for (i=0; i<numberOfGroups; i++) {
		[[groups objectAtIndex:i] setPlayers:[playerLists objectAtIndex:i]];
		[[groups objectAtIndex:i] finishedDrawing];
	}
	
	return [self secondStageDraw];
}

- (void)semiFinalLoosers:(Match *)final;
{
	NSMutableArray *pstns = [NSMutableArray array];
	Match *looserFinal = [[Match alloc] initUpTo:2 current:1 total:1 next:nil series:self
													 posList:pstns];
	[[final upperMatch] setLoserMatch:[looserFinal upperMatch]];
	[looserFinal setUpperIsWinner:NO];
	[[final lowerMatch] setLoserMatch:[looserFinal lowerMatch]];
	[looserFinal setLowerIsWinner:NO];
	
	[matchTables addObject:looserFinal];
	}

- (void)quaterFinalLoosers:(Match *)final;
{
	NSMutableArray *pstns = [NSMutableArray array];
	Match *looserFinal = [[Match alloc] initUpTo:4 current:1 total:1 next:nil series:self
													 posList:pstns];
	[[[final upperMatch] upperMatch] setLoserMatch:[[looserFinal upperMatch] upperMatch]];
	[[looserFinal upperMatch] setUpperIsWinner:NO];
	[[[final upperMatch] lowerMatch] setLoserMatch:[[looserFinal upperMatch] lowerMatch]];
	[[looserFinal upperMatch] setLowerIsWinner:NO];
	[[[final lowerMatch] upperMatch] setLoserMatch:[[looserFinal lowerMatch] upperMatch]];
	[[looserFinal lowerMatch] setUpperIsWinner:NO];
	[[[final lowerMatch] lowerMatch] setLoserMatch:[[looserFinal lowerMatch] lowerMatch]];
	[[looserFinal lowerMatch] setLowerIsWinner:NO];
	
	[matchTables addObject:looserFinal];

	[self semiFinalLoosers:looserFinal];
}

- (void)thirdStage;
{
	long numGroups = [groups count];
	Group *first = [groups objectAtIndex:numGroups-2];
	Group *second = [groups objectAtIndex:numGroups-1];
	long i, numPlayers = [[first players] count];
	NSMutableArray *pts = [NSMutableArray array];
	
	for (i=0; i<numPlayers; i++) {
		[pts removeAllObjects];
		Match *thirdStage = [[Match alloc] initUpTo:2 current:1 total:1 next:nil
														 series:self posList:pts];
		RLGroupPlayer *firstPlayer = [[RLGroupPlayer alloc] initGroup:first position:i+1];
		RLGroupPlayer *secondPlayer = [[RLGroupPlayer alloc] initGroup:second position:i+1];
		[firstPlayer addMatch:thirdStage];
		[secondPlayer addMatch:thirdStage];
		[[pts objectAtIndex:0] setWinner:firstPlayer];
		[[pts objectAtIndex:1] setWinner:secondPlayer];
		
		[matchTables addObject:thirdStage];
	}
}

- (void)secondStageDraw1RankFrom:(long)firstStageGroups startWithRank:(long)rank;
{
	int i;
	NSMutableArray *playerList = [NSMutableArray arrayWithCapacity:4];
	
	Group* group = [[Group alloc] initSeries:self number:[groups count]+1];
	for(i = 0; i < firstStageGroups; i++) {
		RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc]
						initGroup:[groups objectAtIndex:i] position:rank];
		[groupPlayer addMatch:group];
		[playerList addObject:groupPlayer];
	}
	[group setPlayers:playerList];
      [groups addObject:group];
}

- (void)secondStageDraw2RanksFrom:(long)firstStageGroups startWithRank:(long)fromRank;
{
	long i, rank;
   for(i = 0; i < firstStageGroups/2; i++) {
		NSMutableArray *playerList = [NSMutableArray arrayWithCapacity:4];
		Group* group = [[RLGroup alloc] initSeries:self number:[groups count]+1];
		
		for (rank = fromRank; rank <= fromRank+1; rank++) {
			RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc]
					initGroup:[groups objectAtIndex:i] position:rank];
			[groupPlayer addMatch:group];
			[playerList addObject:groupPlayer];
			groupPlayer = [[RLGroupPlayer alloc]
					initGroup:[groups objectAtIndex:firstStageGroups-i-1] position:rank];
			[groupPlayer addMatch:group];
			[playerList addObject:groupPlayer];
		}
		[group setPlayers:playerList];
		[groups addObject:group];
	}
	
	[self thirdStage];
}

- (void)secondStageDraw2RanksFromAll:(long)firstStageGroups startWithRank:(long)fromRank;
{
	long i, grp, rank, fg;
	for(i = 0; i < firstStageGroups/2; i++) {
		NSMutableArray *playerList = [NSMutableArray arrayWithCapacity:4];
		Group* group = [[RLGroup alloc] initSeries:self number:[groups count]+1];
		
		for (rank = fromRank; rank <= fromRank+1; rank++) {
			for (fg=0; fg<2; fg++) {
				if (i==0) {
					grp=fg*(firstStageGroups/2)+(rank-fromRank);
				} else {
					grp=fg*(firstStageGroups/2)+(1+fromRank-rank);
				}
				RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc]
														initGroup:[groups objectAtIndex:grp] position:rank];
				[groupPlayer addMatch:group];
				[playerList addObject:groupPlayer];
			}
		}
		[group setPlayers:playerList];
		[groups addObject:group];
	}
	[self thirdStage];
}

- (BOOL)secondStageDraw;
{
	long firstStageGroups = [groups count];
	
	[self secondStageDraw1RankFrom:firstStageGroups startWithRank:1];
	if ([self useAllGroupsForSecondStage]) {
		[self secondStageDraw2RanksFromAll:firstStageGroups startWithRank:2];
		[self secondStageDraw2RanksFromAll:firstStageGroups startWithRank:4];
	} else {
		[self secondStageDraw2RanksFrom:firstStageGroups startWithRank:2];
		[self secondStageDraw2RanksFrom:firstStageGroups startWithRank:4];
	}
	[self secondStageDraw1RankFrom:firstStageGroups startWithRank:6];
	
	return YES;
}

- (BOOL)allGroupsHaveMatches;
{
	long i, max = [groups count];
	
	for (i=0; i<max; i++) {
		Group *group = (Group *)[groups objectAtIndex:i];
		if ([[group matches] count] == 0) {
			return NO;
		}
	}
	return YES;
}

- (IBAction) allMatchSheets:(id)sender;
	// print out all match sheets of this Series in increasing order
	// (Final comes last)
	// plus the group-sheets in decreasing order
{
	NSMutableArray *matches = [[NSMutableArray alloc] init];
	long i, max = [matchTables count];
	bool printDetails=[TournamentDelegate.shared.preferences groupDetails];
	
	max = [groups count];
	for (i=0; i<max; i++) {
		Group *group=(Group *)[groups objectAtIndex:i];
		
		if (![group finished]) {
			if (printDetails) {
				[group allMatchSheets:sender];
			}
		}
	}
	
	if ([self allGroupsHaveMatches]) {
		max = [matchTables count];
		for (i=0; i<max; i++) {
			[matches addObject:[matchTables objectAtIndex:i]];
		}
		printAllMatches(matches);
	}
} // allMatchSheets

- (void)drawKOTable:(const NSRect)rect page:(NSRect *)page
                  maxMatchesOnPage:(long)maxMatchesOnPage;
{
	if (NSIntersectsRect(*page, rect)) {
		float top = [self pageHeader:page];
		
		for (Match *table in matchTables) {
			[table draw:&top at:page->size.width - 30.0
					  max:[table pMatches]];
			top = top-12;
		}
	} else {
		_currentPage++;
	}
	page->origin.y -= page->size.height;
}

- (BOOL)finished;
	// return YES if there already is a winner
{
	long i, max = [groups count];
	if ((max > 4) && ([[groups objectAtIndex:4] finished]) && ([[groups objectAtIndex:max-1] finished])) {
		max = [matchTables count];
		for (i=0; i<max; i++) {
			if (![[matchTables objectAtIndex:i] finished]) {
				return NO;
			}
		}
		return YES;
	} else {
		return NO;
	}
}

- (NSArray *) rankingList;
{
	NSMutableArray *list = [NSMutableArray array];
	
	if ([self finished]) {
		[list addObjectsFromArray:[[groups objectAtIndex:4] rankingList]];
		
		long i,  max = [matchTables count];
		NSMutableArray *matchList = [NSMutableArray array];
		for (i=0; i<max; i++) {
			Match *match = [matchTables objectAtIndex:i];
			
			[matchList addObject:[match winner]];
			[match rankingList:matchList upTo:2];
			[list addObjectsFromArray:matchList];
		
			[matchList removeAllObjects];
		}
		
		if ([groups count] > 9) {
			[list addObjectsFromArray:[[groups lastObject] rankingList]];
		}
	}
	
	return list;
}

- textRankingListIn:text;
{
   [text clearText];
   [text setTitleText:[NSString stringWithFormat:@"Rangliste: %@\n", [self fullName]]];
	NSArray *rankingList = [self rankingList];
	long i, max = [rankingList count];
	
	for (i=0; i<max; i++) {
		id <Player> plAti = (id <Player>)[rankingList objectAtIndex:i];
		NSString *line=[NSString stringWithFormat:@"\t%ld.\t%@\t%@\n", i+1, [plAti longName], [plAti club]];
		[text appendText:line];
	}
	return self;
}

- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
{
   [super appendSingleResultsAsTextTo:text];
	
   long i, max=[matchTables count];
	
   for (i=0; i < max; i++) {
      Match *match = (Match *)[matchTables objectAtIndex:i];
		
      [match appendResultsAsTextTo:text];
   }
}

/*
- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
{
	[super appendMatchResultsAsXmlTo:text];
	
	int i, max=[matchTables count];
	
	for (i=0; i < max; i++) {
		Match *match = (Match *)[matchTables objectAtIndex:i];
		
		[match appendMatchResultsAsXmlTo:text];
	}
}*/

- (long)totalPages;
{
   return 1 + [pageGroupStarts count] + [self detailPages];
} // totalPages

- (NSMutableArray *)groupPositionClasses:(NSMutableArray *)playerLists;
{
   return [self groupRankClasses:playerLists];
}
@end
