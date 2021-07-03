//
//  RLQualiSeries.m
//  Tournament
//
//  Created by Paul Trunz on 11.11.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "RLQualiDamenSeries.h"
#import "RLGroup.h"
#import "RLGroupPlayer.h"
#import "Series.h"
#import "SeriesPlayer.h"
#import "SmallTextController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

void extern printAllMatches(NSMutableArray *matches);		// forward declaration

@implementation RLQualiDamenSeries

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
} // initFromStruct

- (BOOL)useAllGroupsForSecondStage;
{
	return isupper(sMode);
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:matchTables];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	matchTables=[decoder decodeObject];
	
	return self;
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
			groupIndex = numberOfGroups - groupIndex - 1;
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

- (void)secondStageDraw1From:(long)firstStageGroups rank:(long)rank;
{
	int i;
	NSMutableArray *playerList = [NSMutableArray arrayWithCapacity:4];
	
	Group *finalGroup = [[Group alloc] initSeries:self number:[groups count]+1];
	for(i = 0; i < firstStageGroups; i++) {
		Group * group = [groups objectAtIndex:i];
		if ([[group players] count] >= rank) {
			RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc] initGroup:group position:rank];
			[groupPlayer addMatch:finalGroup];
			[playerList addObject:groupPlayer];
		}
	}
	[finalGroup setPlayers:playerList];
	[groups addObject:finalGroup];
}

- (void)thirdStageMatchesForLastTwoGroups;
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
		
		[self numberMatchesInTable:thirdStage];
		[matchTables addObject:thirdStage];
	}
}

-(Group *)groupOfTopPlayers; {
   Group* topGroup = [[RLGroup alloc] initSeries:self number:4];
   NSMutableArray<id<Player>> *playerList = [NSMutableArray arrayWithCapacity:4];
   
   for(int i = 0; i < 3; i++) {
      Group * group = [groups objectAtIndex:i];
      RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc] initGroup:group position:1];
      [groupPlayer addMatch:topGroup];
      [playerList addObject:groupPlayer];
   }
   Group *firstGroup = [groups objectAtIndex:0];
   if ([[firstGroup players] count] > 3) {
      RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc] initGroup:firstGroup position:2];
      [groupPlayer addMatch:topGroup];
      [playerList addObject:groupPlayer];
   }
   
   [topGroup setPlayers:playerList];
   
   return topGroup;
}

int FIRST_LOW_GROUPS[] = {1, 2, 0, 1};
int FIRST_LOW_RANKS[] =  {2, 3, 3, 4};

-(Group *)firstLowGroup;
{
   Group* flGroup = [[RLGroup alloc] initSeries:self number:4];
   NSMutableArray<id<Player>> *playerList = [NSMutableArray arrayWithCapacity:4];
   
   for(int i = 0; i < 4; i++) {
      Group * group = [groups objectAtIndex:FIRST_LOW_GROUPS[i]];
      int rank = FIRST_LOW_RANKS[i];
      if ([[group players] count] >= rank ) {
         RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc] initGroup:group position:rank];
         [groupPlayer addMatch:flGroup];
         [playerList addObject:groupPlayer];
      }
   }
   [flGroup setPlayers:playerList];
   
   return flGroup;
}

int SECOND_LOW_GROUPS[] = {2, 1, 0, 2};
int SECOND_LOW_RANKS[] =  {2, 3, 4, 4};

-(Group *)secondLowGroup;
{
   Group* slGroup = [[RLGroup alloc] initSeries:self number:5];
   NSMutableArray<id<Player>> *playerList = [NSMutableArray arrayWithCapacity:4];
   
   for(int i = 0; i < 4; i++) {
      Group * group = [groups objectAtIndex:SECOND_LOW_GROUPS[i]];
      int rank = SECOND_LOW_RANKS[i];
      if ([[group players] count] >= rank ) {
         RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc] initGroup:group position:rank];
         [groupPlayer addMatch:slGroup];
         [playerList addObject:groupPlayer];
      }
   }
   
   [slGroup setPlayers:playerList];
   
   return slGroup;
}

-(void)threeGroupsFromThreeGroups; {
   [groups addObject:[self groupOfTopPlayers]];
   [groups addObject:[self firstLowGroup]];
   [groups addObject:[self secondLowGroup]];
   [self thirdStageMatchesForLastTwoGroups];
}

-(void)twoGroupsFromTwoGroups;
{
   Group* three = [[RLGroup alloc] initSeries:self number:3];
   Group* four = [[RLGroup alloc] initSeries:self number:4];
   
   NSMutableArray<id<Player>> *playerList = [NSMutableArray arrayWithCapacity:4];
   
   for (int rank=1; rank <= 2; rank++) {
      for (int grp = 0; grp <= 1; grp++) {
         RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc]
                                       initGroup:[groups objectAtIndex:grp] position:rank];
         [groupPlayer addMatch:three];
         [playerList addObject:groupPlayer];
      }
   }
   [three setPlayers:playerList];
   
   playerList = [NSMutableArray arrayWithCapacity:4];
   
   for (int rank=3; rank <= 4; rank++) {
      for (int grp = 0; grp <= 1; grp++) {
         if ([[[groups objectAtIndex:grp] players] count] >= rank) {
            RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc]
                                          initGroup:[groups objectAtIndex:grp] position:rank];
            [groupPlayer addMatch:four];
            [playerList addObject:groupPlayer];
         }
      }
   }
   [four setPlayers:playerList];
   
   [groups addObject:three];
   [groups addObject:four];
}

- (void)secondStageDraw2RanksFromAll:(long)firstStageGroups startWithRank:(long)fromRank;
{
	long i, grp, rank, fg;
	for(i = 0; i < firstStageGroups/2; i++) {
		NSMutableArray *playerList = [NSMutableArray arrayWithCapacity:4];
		Group* group = [[RLGroup alloc] initSeries:self number:[groups count]+1];
		
		for (rank = fromRank; rank <= fromRank+1; rank++) {
			for (fg=0; fg<2; fg++) {
				grp=(1+fromRank-rank)*(firstStageGroups/2);
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
	[self thirdStageMatchesForLastTwoGroups];
}

- (RLGroup*) groupWithMorePlayersThan: (int) rank
{
   long i, max=[groups count];
   for (i=0; i<max; i++) {
      if ([[[groups objectAtIndex:i] players] count] >= rank) {
         return [groups objectAtIndex:i];
      }
   }
   return nil;
}

- (int) countGroupsUpTo:(long)firstStageGroups withMorePlayersThan: (long) rank
{
   int i, count=0;
   for (i=0; i<firstStageGroups; i++) {
      if ([[[groups objectAtIndex:i] players] count] >= rank) {
         count++;
      }
   }
   return count;
}

- (BOOL)hasMoreThanOnePlayerIn:(int)firstStageGroups withRank:(int)rank;
{
	return [self countGroupsUpTo:firstStageGroups withMorePlayersThan: rank] > 1;
}

-(void)addToLastGroupFrom:(long)firstStageGroups playerWithRank:(long)lastRank;
{
	int i;
	RLGroup *lastGroup = [groups lastObject];
	NSMutableArray *playerList = [NSMutableArray arrayWithArray:[lastGroup players]];
	for (i=0; i<firstStageGroups; i++) {
		if ([[[groups objectAtIndex:i] players] count] == lastRank) {
			RLGroupPlayer *groupPlayer = [[RLGroupPlayer alloc]
																		initGroup:[groups objectAtIndex:i] position:lastRank];
			[groupPlayer addMatch:lastGroup];
			[playerList addObject:groupPlayer];
			[lastGroup setPlayers:playerList];
		}
	}
}

- (void)handleLastRankInGroups:(long)firstStageGroups rank:(long)lastRank;
{
	int countLast = [self countGroupsUpTo:firstStageGroups withMorePlayersThan: lastRank];
	if (countLast > 1) {
		[self secondStageDraw1From:firstStageGroups rank:lastRank];
	} else if (countLast == 1) {
		[self addToLastGroupFrom:firstStageGroups playerWithRank:lastRank];
	}
   
   int countOver = [self countGroupsUpTo:firstStageGroups withMorePlayersThan: lastRank+1];
   if (countOver > 0) {
      [self addToLastGroupFrom:firstStageGroups playerWithRank:lastRank+1];
   }
}

- (BOOL)secondStageDraw;
{
	long firstStageGroups = [groups count];
	if (firstStageGroups == 4) {
		[self secondStageDraw1From:firstStageGroups rank:1];
		[self secondStageDraw2RanksFromAll:firstStageGroups startWithRank:2];
		[self handleLastRankInGroups:firstStageGroups rank:4];
   } else if (firstStageGroups == 3) {
      [self threeGroupsFromThreeGroups];
   } else {
      [self twoGroupsFromTwoGroups];
	}
		
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
	long i, max;
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

- (void) drawKOTable:(const NSRect)rect page:(NSRect *)page
    maxMatchesOnPage:(long)maxMatchesOnPage;
{
	
	if (NSIntersectsRect(*page, rect)) {
		float top = [self pageHeader:page];
		long i, max=[matchTables count];
		
		for (i=0; i < max; i++) {
			Match *table = [matchTables objectAtIndex:i];
			[table draw:&top at:page->size.width - 30.0
					  max:[[matchTables objectAtIndex:0] pMatches]];
			top = top-12;
		}
	} else {
		_currentPage++;
	}
	page->origin.y -= page->size.height;
}

- (BOOL)finished;
	// return YES if all matches are finished and the ranking list can be determined completely
{
   if (!alreadyDrawn) {
      return NO;
   }
	long i, max = [groups count];
	for(i=0; i<max; i++) {
		if (![[groups objectAtIndex:i] finished]) {
			return NO;
		}
	}
	max = [matchTables count];
	for (i=0; i<max; i++) {
		if (![[matchTables objectAtIndex:i] finished]) {
			return NO;
		}
	}
	return YES;
}

- (void)ranksFromThirdStage:(NSMutableArray *)list {
   NSMutableArray *matchList = [NSMutableArray array];
   for (Match *match in matchTables) {
      [matchList addObject:[match winner]];
      [match rankingList:matchList upTo:2];
      [list addObjectsFromArray:matchList];
      
      [matchList removeAllObjects];
   }
}

- (NSArray *) rankingList;
{
	NSMutableArray *list = [NSMutableArray array];
	
	if ([self finished]) {
      NSUInteger plCount = [players count];
      if (plCount > 12) {
			[list addObjectsFromArray:[[groups objectAtIndex:4] rankingList]];  // winners group
			
         [self ranksFromThirdStage:list];
			
			if ([groups count] > 7) {		// there is a group of first stage losers
				[list addObjectsFromArray:[[groups lastObject] rankingList]];
			} else if ([[[groups lastObject] rankingList] count] > 4) {
				[list addObject:[[[groups lastObject] rankingList] lastObject]]; // no match for the last one
			}
		} else if (plCount > 8) {     // in this case we run three groups, winners fourth, the rest plays third stage
         [list addObjectsFromArray:[[groups objectAtIndex:3] rankingList]];  // winners group
         [self ranksFromThirdStage:list];
      } else {    // we run (a maximum of) two groups, the last half determines the final ranking
         long groupCount = [groups count];
         for (long i=groupCount/2; i<groupCount; i++) {
            [list addObjectsFromArray:[[groups objectAtIndex:i] rankingList]];
               // should list the second half of the groups (the only one if there is only one?
         }
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

- (void)matchNotPlayed:(Match*)match;
{
	[matchTables removeObject:match];
}

- (NSMutableArray *) matchTables;
{
	return matchTables;
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
