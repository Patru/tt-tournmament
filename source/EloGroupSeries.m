//
//  EloGroupSeries.m
//  Tournament
//
//  Created by Paul Trunz on 27.08.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "EloGroupSeries.h"
#import "EloGroup.h"
#import "GroupMatch.h"
#import "GroupPlayer.h"
#import "RLGroupPlayer.h"
#import "SmallTextController.h"
#import "Tournament-Swift.h"

@implementation EloGroupSeries
- init;
{
	self=[super init];
	RankSel = @selector(elo);
	matchTables = [[NSMutableArray alloc] init];
	return self;
}

+ (EloGroupSeries *) seriesfor:(EloSeries *)mother index:(long)idx players:(NSArray *)plsForSer;
{
	EloGroupSeries *ser = [[EloGroupSeries alloc] init];
	[ser setFullName: [NSString stringWithFormat:@"%@ Serie %ld", [mother fullName], idx]];
	[ser setSeriesName: [NSString stringWithFormat:@"%@-%ld", [mother seriesName], idx]];
	[ser setSex: [mother sex]];
	[ser setBestOfSeven:[mother bestOfSeven]];
	[ser setGrouping:[mother grouping]];
	ser->startTime = [mother startTime];
	[ser setSMode:[mother sMode]];
	long i, max=[plsForSer count];
	for(i=0; i<max; i++) {
		[ser addSeriesPlayer:[plsForSer objectAtIndex:i]];
	}
	[ser setCoefficient:(float)(([plsForSer count]+1)/2)];
	return ser;
}

- (NSArray *)lastThreeFrom:(Group *)first and:(Group *)second;
{
	long firstMax=[[first players] count];
	NSMutableArray *plyrs = [NSMutableArray array];
	
	[plyrs addObject:[[RLGroupPlayer alloc] initGroup:first  position:firstMax]];
	[plyrs addObject:[[RLGroupPlayer alloc] initGroup:second position:firstMax]];
	[plyrs addObject:[[RLGroupPlayer alloc] initGroup:second position:firstMax+1]];
	
	return plyrs;
}

- (void)groupOfLastThreeFrom:(Group *)first and:(Group *)second;
{
	Group *group = [EloGroup groupWithSeries:self number:3];
	
	[group setPlayers:[self lastThreeFrom:first and:second]];
	[group finishedDrawing];
	[groups addObject:group];
}

- (void)simpleOfLastThreeFrom:(Group *)first and:(Group *)second;
{
	NSMutableArray *posLst = [NSMutableArray array];
	Match *secStage = [[Match alloc] initUpTo:3 current:1 total:1 next:nil
																		 series:self posList:posLst];
	NSArray *plyrs =[self lastThreeFrom:first and:second];
	
	[[posLst objectAtIndex:0] setWinner:[plyrs objectAtIndex:1]];
	[[posLst objectAtIndex:1] setWinner:[plyrs objectAtIndex:2]];
	[[posLst objectAtIndex:2] setWinner:[plyrs objectAtIndex:0]];
	// matches are added to GroupPlayers through setWinner
	
	[matchTables addObject:secStage];
}

- (void)matchOfLastFrom:(Group *)first and:(Group *)second;
{
	long max=[[first players] count];
	NSMutableArray *pts = [NSMutableArray array];
	Match *lastMatch = [[Match alloc] initUpTo:2 current:1 total:1 next:nil
																			series:self posList:pts];
	GroupPlayer *pl1 = [[GroupPlayer alloc] initGroup:first position:max];
	GroupPlayer *pl2 = [[GroupPlayer alloc] initGroup:second position:max];
	
	[[pts objectAtIndex:0] setWinner:pl1];
	[[pts objectAtIndex:1] setWinner:pl2];
	[matchTables addObject:lastMatch];
}

// TODO: allMatchSheets, currently we print a few matches too much, probably because of loser matches.

- (BOOL)secondStage;
{
	if ([groups count] < 2) {		// there is no second stage for just one group
		return YES;
	}
	Group *first = [groups objectAtIndex:0];
	Group *second = [groups objectAtIndex:1];
	long totalPlayers=[[first players] count]+[[second players] count];
	long i, groupsOf4 = totalPlayers/4, remainingPlayers=totalPlayers%4;
	NSMutableArray *pts = [NSMutableArray array];
	
	for (i=0; i<groupsOf4; i++) {
		[pts removeAllObjects];
		Match *secStage = [[Match alloc] initUpTo:4 current:1 total:1 next:nil
																				 series:self posList:pts];
		GroupPlayer *pl1 = [[GroupPlayer alloc] initGroup:first position:i*2+1];
		GroupPlayer *pl2 = [[GroupPlayer alloc] initGroup:second position:i*2+1];
		GroupPlayer *pl3 = [[GroupPlayer alloc] initGroup:first position:i*2+2];
		GroupPlayer *pl4 = [[GroupPlayer alloc] initGroup:second position:i*2+2];
		[[pts objectAtIndex:0] setWinner:pl1];
		[[pts objectAtIndex:1] setWinner:pl4];
		[[pts objectAtIndex:2] setWinner:pl3];
		[[pts objectAtIndex:3] setWinner:pl2];
		// matches are added to GroupPlayers through setWinner
		
		[matchTables addObject:secStage];
		if ([self secondStageLooserMatch:i]) {
			[matchTables addObject:[secStage makeLoserMatch]];
		}
	}
	if (remainingPlayers == 3) {
		if ([self secondStageLooserMatch:i]) {
			[self groupOfLastThreeFrom:first and:second];
		} else {
			[self simpleOfLastThreeFrom:first and:second];
		}
	} else if (remainingPlayers == 2) {
		[self matchOfLastFrom:first and:second];
	}
	return YES;
}

- (NSMutableArray *)matchTables;
{
	return matchTables;
}

- (NSString *)finalString:(Match *) match;
{
	long firstRank = [matchTables indexOfObject:match]*2 + 1;
	
	if (firstRank == NSNotFound) {
		return @"unknown Final";
	} else if (firstRank == 1) {
		return NSLocalizedStringFromTable(@"Final", @"Matchblatt", @"Final auf Matchblatt");
	} else {
		NSString *rankString = NSLocalizedStringFromTable(@"%d./%d. Rang", @"Matchblatt", @"Rang-Spiel auf Matchblatt");
		return [NSString stringWithFormat:rankString, firstRank, firstRank + 1];
	}
}

// TODO: implement roundStringFor: in order to display "1.-4. Rang" correctly

- (BOOL)makeTable
{
	[self groupStage];
	[self secondStage];
	[self numberKoMatches];
	alreadyDrawn=YES;
	
	return alreadyDrawn;
}

// TODO: make this a float and relate to number of players in group
- (long)countClubs:(NSMutableArray *)playerLists;
{
	long i, max=[playerLists count], total=0;
	
	for (i=0; i<max; i++) {
		NSMutableArray *pls=[playerLists objectAtIndex:i];
		long j, k, pMax=[pls count];
		
		for (j=0; j<pMax; j++) {
			for (k=j+1; k<pMax; k++) {
				if ([[[pls objectAtIndex:j] club] isEqualToString:[[pls objectAtIndex:k] club]]) {
					total++;
				}
			}
		}
	}
	
	return total;
}

- (void)switchPl:(NSMutableArray *)playerLists at:(long)idx from:(long)left to:(long)right;
{
	id pl0 = [(NSMutableArray *)[playerLists objectAtIndex:left] objectAtIndex:idx];
	id pl1 = [(NSMutableArray *)[playerLists objectAtIndex:right] objectAtIndex:idx];
	
   [[playerLists objectAtIndex:left] replaceObjectAtIndex:idx withObject:pl1];
	[[playerLists objectAtIndex:right] replaceObjectAtIndex:idx withObject:pl0];
}

// optimize the number of clubs in the same group
- (void)optimizeClubs:(NSMutableArray *)playerLists;
{
   long i, min=[[playerLists objectAtIndex:0] count], groupCount = [playerLists count];
	BOOL hasSwitched=YES;
	
   for (NSArray *list in playerLists) {
      if ([list count] < min) {
         min = [list count];
      }
   }
	
	while (hasSwitched) {
		hasSwitched=NO;
		
		for (i=min-1; i>=0; i--) {
			long before=[self countClubs:playerLists];
         for(long left=0; left < groupCount-1; left++) {
            for (long right = left+1; right < groupCount; right++) {
               [self switchPl:playerLists at:i from:left to:right];
               long after=[self countClubs:playerLists];
               if (after >= before) {
                  [self switchPl:playerLists at:i from:left to:right];      // no improvement, undo
               } else if (before > after) {
                  hasSwitched=YES;
               }
            }
         }
		}
	}
}

- (void)fixRankingForClickTT;
{
   maxRanking = (int)[[[players objectAtIndex:0] player] ranking];      // cheat for click-tt
   minRanking = (int)[[[players objectAtIndex:[players count]-1] player] ranking];
}

- (void)groupStage;
{
	long i, max = [players count];
	NSMutableArray *playerLists = [NSMutableArray array];
   [self fixRankingForClickTT];
	
	groups = [[NSMutableArray alloc] init];		// there will be groups
	if (max <= 9) {
		NSMutableArray *realPlayers = [NSMutableArray array];
		for (i=0; i<max; i++) {
			[realPlayers addObject:[[players objectAtIndex:i] player]];
		}
		[groups addObject:[EloGroup groupWithSeries:self number:1]];
		[[groups objectAtIndex:0] setPlayers:realPlayers];
		[[groups objectAtIndex:0] finishedDrawing];
		return;
	}
	groupPlayers = players;
		
	for(i = 0; i < 2; i++) {
		[groups addObject:[EloGroup groupWithSeries:self number:i+1]];
		[playerLists addObject:[NSMutableArray array]];
	}
	
	for (i=0; i < max; i++) {
		long groupIndex = i%2;
		long groupPosition = i/2;
		if (groupPosition%2 == 1) {		// reflect uneven rows
			groupIndex = 1 - groupIndex;
		}
		[[playerLists objectAtIndex:groupIndex] addObject:[[players objectAtIndex:i] player]];
	}
	
	[self optimizeClubs:playerLists];
	
	for (i=0; i<2; i++) {
		[[groups objectAtIndex:i] setPlayers:[playerLists objectAtIndex:i]];
		[[groups objectAtIndex:i] finishedDrawing];
	}
}

- drawSelf:(const NSRect)rect page:(NSRect *)page maxMatchesOnPage:(long)maxMatchesOnPage;
{
	[[NSColor blackColor] set];
	
	[self drawGroupsAndTables:rect page:page];
	
	[self drawGroupDetails:rect page:page];
	
	[self drawRankingListPage:rect page:page maxMatchesOnPage:maxMatchesOnPage];
	
	return self;
} // drawSelf

- (void)drawGroupsAndTables:(const NSRect)rect page:(NSRect *)page;
{
	if (NSIntersectsRect(*page, rect)) {
		float top = [self pageHeader:page];

		[self drawGroups:&top from:1 to:[groups count]+1];
		top=top-25;
		
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



- (void) drawKOTable:(const NSRect)rect page:(NSRect *)page
    maxMatchesOnPage:(long)maxMatchesOnPage;
{
	if (NSIntersectsRect(*page, rect)) {
	} else {
		_currentPage++;
	}
	page->origin.y -= page->size.height;
}

- (bool)coversFourPlayersWith:(Match *)match;
{
	return ([[match upperMatch] loserMatch] == nil) && ([[match lowerMatch] upperMatch] != nil);
}

- (NSArray *) rankingList;
{
	NSMutableArray *list = [NSMutableArray array];
	
	if (![self finished]) {
		return list;
	}
	
	long i,  max = [matchTables count];
	NSMutableArray *localList = [NSMutableArray array];
	for (i=0; i<max; i++) {
		Match *match = [matchTables objectAtIndex:i];
		
		[localList addObject:[match winner]];
		
		if ([self coversFourPlayersWith:match]) {
			[match rankingList:localList upTo:4];
		} else {
			[match rankingList:localList upTo:2];
		}
		[list addObjectsFromArray:localList];
		
		[localList removeAllObjects];
	}
	if ([groups count] != 2) {
		[list addObjectsFromArray:[[groups lastObject] rankingList]];
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

- (long)totalPages;
{  
	return 2 + [self detailPages];
}

- (void) drawRankingListBelow:(float)top at:(float)left;
{
	if ([self finished]) {
		NSArray *rankingList = [self rankingList];
		long i, max = [rankingList count];
		
		for (i=0; i<max; i++) {
			[[NSMutableString stringWithFormat:@"%ld", i+1] drawAtPoint:NSMakePoint(left, top)
																												 withAttributes:[Match smallAttributes]];
			[[rankingList objectAtIndex:i] drawInMatchTableOf:self x:left+20 y:top];
			top = top - 10;
		}
	}
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

- (BOOL)finished;
{
   return ( (([groups count] == 1) && [[groups objectAtIndex:0] finished])
           || ([super finished] && (([groups count] == 2)
                                    || (([groups count] == 3) && [[groups objectAtIndex:2] finished]))) );
}

- (long)numberOfSetsFor:(Match *)match;
{
	if ([match isKindOfClass:[GroupMatch class]]) {
		long grIndex=[groups indexOfObject:[(GroupMatch *)match group]];
		
		if (([groups count] == 3) && (grIndex == 2) && ([self bestOfSeven] > 0)) {		// we want the terminal group to be played best of 7 if the other matches are
         // We should pass this decision on to the parent series
			return 7;
		} else {
			return 5;
		}   
	} else {
		return [super numberOfSetsFor:match];
	}
}

- (bool)secondStageLooserMatch:(long)fours;
{
	if ((sMode == 'E') && (fours > 0)) {
		return NO;
	} else {
		return YES;
	}
}

- (long)countPlayers;
{
   long sum = 0, i, max = [groups count];
   if (max > 2) {
      max = 2;
   }
   
   for(i=0; i<max; i++) {
      sum = sum + [[[groups objectAtIndex:i] players] count];
   } // for
   
   return sum;
}

@end
