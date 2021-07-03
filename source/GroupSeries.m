/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a group series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
          18.2.95, Patru: improved checking, new drawing scheme
    Bugs: -not very well documented
 *****************************************************************************/

#import "GroupSeries.h"

#import "GroupPlayer.h"
#import <PGSQLKit/PGSQLKit.h>
#import "GroupPosition.h"
#import "MatchBrowser.h"
#import "PreferencesController.h"
#import "SeriesPlayer.h"
#import "SeriesController.h"
#import "SeriesDataController.h"
#import "SmallTextController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"
#import "TournamentView.h"

@implementation GroupSeries
/* Controls a group series of a tournament. This includes mainly table-
   and group generation. */

- (instancetype)init;
{
   self = [super init];
   groups = [[NSMutableArray alloc] init];
   usualGroupSize = 0;
   pageGroupStarts = [[NSMutableArray alloc] init];
   groupPlayers = [[NSMutableArray alloc] init];
   return self;
} // init

- (instancetype)initFromRecord:(PGSQLRecord *)record;
{
   self=[super initFromRecord:record];
   // get the common fields via super
   groups = [[NSMutableArray alloc] init];
//   usualGroupSize = [[record fieldByName:SerFields.SerCoefficient] asLong];
   if (usualGroupSize == 0)
   {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", nil);
      alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"GruppenGroesse", @"Tournament", null), [self fullName]];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ok", @"Tournament", nil)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"IWouldLikeToCorrectThis", @"Tournament", nil)];
      [alert beginSheetModalForWindow:TournamentDelegate.shared.seriesController.seriesWindow completionHandler:^(NSModalResponse retCode) {
         if (retCode == NSAlertSecondButtonReturn) {
            [TournamentDelegate.shared.seriesDataController showWindow:self];
         }
      }];
      usualGroupSize = 3;		// some sensible default in order to not crash
   } // if
   pageGroupStarts = [NSMutableArray array];
   groupPlayers = [NSMutableArray array];
   
   return self;
} // initFromStruct

- (float)coefficient;
// operates on usualGroupSize here
{
   return (float)usualGroupSize;
}

- setCoefficient:(float)aFloat;
// operates on usualGroupSize here
{
   usualGroupSize = (int)(aFloat+0.01);
   [super setCoefficient:aFloat];
   
   return self;
} // setSetMult


/*- write: (NXTypedStream *) s;
{
   [super write:s];
   NXWriteTypes(s, "@i", &groups, &usualGroupSize);
   return self;
} // write

- read:(NXTypedStream *) s;
{ 
   [super read:s];
   NXReadTypes(s, "@i", &groups, &usualGroupSize);
      pageGroupStarts = [[NSMutableArray alloc] init];
   return self;
} // read
*/

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeValueOfObjCType:@encode(int) at:&usualGroupSize];
	[encoder encodeObject:groups];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	[decoder decodeValueOfObjCType:@encode(int) at:&usualGroupSize];
	groups=[decoder decodeObject];
   pageGroupStarts = [NSMutableArray array];
   groupPlayers = [[NSMutableArray alloc] init];
   
   if ((groups != nil) && ([groups count] > 0)) {
   //   [[TournamentDelegate.shared seriesController] storeSeriesWithGroups:self];
   }

	return self;
}

- (NSMutableArray *)groups;
{
   return groups;
} // groups

- (void)add:(Group *)group;
{
   if (groups == nil) {
      groups = [[NSMutableArray alloc] init];
   }
   [groups addObject:group];
}

void notTheSameClub(NSMutableArray * __strong plcs[4])
/* in: plcs: 4 NSMutableArrays with the players for first, second third and forth rank
             of the respective groups. The players in the same group must have
	     the same distance from the end of the list, not from the start
	     (especially significant for plcs[4]
 what: tries to rearrange players such that no two players from the same club
       are playing in the same group. The arrangement is not perfect, manual
       adjustment may be necessary.
*/
{
   long i, j, k, l, max;
   
   for(i=1; i<4; i++)			// rearrange all but the first places
   {
      max = [plcs[i] count];
      for(j=1; j<=max; j++)		// through all groups
      {
         for(k=0; k<i; k++)		// all the previous places
	 {
	    if ([[plcs[k] objectAtIndex:[plcs[k] count]-j] club]
	        == [[plcs[i] objectAtIndex:max-j] club])
	    {				// same club, try to improve
	       l=j+1;			// search for a replacement
	       while ((l<=max)
	             && ([[plcs[i] objectAtIndex:max-l] club]
		     == [[plcs[i] objectAtIndex:max-j] club]))
	       {	
		  l++;
	       } // while
	       if (l <= max)		// l will be larger than j
	       {
	          id pl = [plcs[i] objectAtIndex:max-j];
	          [plcs[i] removeObjectAtIndex:max-j];
		  
		  [plcs[i] insertObject:[plcs[i] objectAtIndex:max-l] atIndex:max-j];
		  [plcs[i] removeObjectAtIndex:max-l];
		  [plcs[i] insertObject:pl atIndex:max-l];
	       } // if
	    } // if
	 } // for
      } // for
   } // for
} // notTheSameClub

- (void) splitGroupPlayersFromPlayers;
{
   long i, max = [players count];
   long set = 0;

   if (setPlayers > 0) {		// setPlayers == 0 indicates no players in ko directly!
      while ((set < max) &&
             (([[players objectAtIndex:set] setNumber] > 0)
              || ([[[players objectAtIndex:set] player] rankingInSeries:self] >= setPlayers))) {
         set++;
      }
   }   

   for (i=set; i < max; i++) {
      [groupPlayers addObject:[players objectAtIndex:i]];
   }

   for (i=set; i < max; i++) {
      [players removeLastObject];
   }
}

- (BOOL)useLargerGroupToCompensate;
{
   if (usualGroupSize < serCoefficient) {
      return YES;
   } else if (usualGroupSize > serCoefficient) {
      return NO;
   } else {
      return usualGroupSize%2 == 1;
   }
}

- (long)  numberOfGroups;
   // this number will only be meaningful after splitGroupPlayersFromPlayers has been run
{
   if ([groups count] > 0) {
      return [groups count];
   } else {
      long playersInGroups = [groupPlayers count];

      if (playersInGroups < usualGroupSize) {
         return 1;
      } else if ([self useLargerGroupToCompensate]) {
         long natural = playersInGroups/usualGroupSize;

         if (natural * (usualGroupSize+1) < playersInGroups) {
            return natural+1;
         } else {
            return natural;
         }
            // as little times usual+1 as possible
      } else {
         return (playersInGroups + usualGroupSize - 1)/usualGroupSize;
            // as much usualGroupSize as possible
      }
   }
}

- (BOOL)makeGroups;
{
   long i, max = [players count];
   long numberOfGroups;
   NSMutableArray *playerLists = [NSMutableArray array];
   
   
   groups = [[NSMutableArray alloc] init];		// there will be groups
   
   [self splitGroupPlayersFromPlayers];
   numberOfGroups = [self numberOfGroups];
   
   for(i = 0; i < numberOfGroups; i++) {
      [groups addObject:[[Group alloc] initSeries:self number:i+1]];
      [playerLists addObject:[NSMutableArray array]];
   }
   
   /*********************   distribute players in groups   **************/
   
   max = [groupPlayers count];
   for (i=0; i < max; i++) {
      long groupIndex = i%numberOfGroups;
      long distributionRound = i/numberOfGroups;
      
      if (distributionRound%2 == 1) {		// reverse for every second round
         groupIndex = numberOfGroups-1-groupIndex;
      }
      [[playerLists objectAtIndex:groupIndex] addObject:[[groupPlayers objectAtIndex:i] player]];
   }
   
   
   [self optimizeClubsInLists:playerLists];
   
   
   //   [players removeAllObjects];
   
   for(i = 0; i < numberOfGroups; i++) {
      [[groups objectAtIndex:i] setPlayers:(NSMutableArray *)[playerLists objectAtIndex:i]];
      [players addObject:[[SeriesPlayer alloc] initGroup:[groups objectAtIndex:i]
                                                position:1]];
   }
   if (promotees > 1) {
      for(i=numberOfGroups-1; i>= 0; i--) {
         // reverse order, second place is best at the end.
         [players addObject:[[SeriesPlayer alloc] initGroup:[groups objectAtIndex:i]
                                                   position:2]];
      } // for
   }
   return YES;
}

- (void)addGroupForPlayers:(NSArray *)pls;
{
   Group *group = [[Group alloc] initSeries:self number:[groups count]+1];
   [self add:group];
   [group setPlayers:pls];
   if (started) {
      id<Player> player;
      
      [group finishedDrawing];
      for (player in [group players]) {
         [player addMatch:group];
      }
   }
}

- (BOOL)newGroupDraw
{
   long i, numberOfGroups;

   if (![self makeGroups]) {
      return NO;
   }
   numberOfGroups = [groups count];
   /*********************   init GroupPlayers   ****************************/
   [super doSimpleDraw];		// now simple Draw will be good

   for(i=0; i<numberOfGroups; i++) {
      [[groups objectAtIndex:i] finishedDrawing];
   } // for

   return YES;
}

- (void)makePlayersFromGroupsRank:(long)from to:(long)to;
{
   NSMutableArray *rankPlayers = [NSMutableArray array];
   long i, j, k, numberOfGroups = [groups count];
   
   for (i=from; i <= to; i++) {
      for(j = 0; j < numberOfGroups; j++) {
         Group *group = [groups objectAtIndex:j];
         if (i <= [[group players] count]) {
            [rankPlayers addObject:[[SeriesPlayer alloc] initGroup:group position:i]];
         }
      }      
      if (i%2 == 1) {
         [players addObjectsFromArray:rankPlayers];
      } else {    // reverse the even ranks
         long max=[rankPlayers count];
         for(k=max-1; k>= 0; k--) {
            [players addObject:[rankPlayers objectAtIndex:k]];
         }
      }
      [rankPlayers removeAllObjects];
   }
}

// override this, numbering needs to come later
- (BOOL)drawTablesFromGroups;
{
   if ([groups count] > 1) {
      [self splitGroupPlayersFromPlayers];
      [self makePlayersFromGroupsRank:1 to:promotees];
      alreadyDrawn = [super doSimpleDraw];		// now simple Draw will be enough
      [self addSmallFinalIfDesired];
   } else {
      [self splitGroupPlayersFromPlayers];
      if ([positions count] > 0) {
         [self makePlayersFromGroupsRank:1 to:promotees];
      } else {
         promotees=1;
         [self makePlayersFromGroupsRank:1 to:promotees];
      }
      alreadyDrawn = [super doSimpleDraw];		// only 1 player, no final, no small final
   }
   
   return alreadyDrawn;
}

- (BOOL)drawFromGroups;
{
   [self drawTablesFromGroups];
   [self numberKoMatches];   
   
   return alreadyDrawn;
}

int countIntraClubMatches(NSArray *players)
{
   long max = [players count];
   int i, j, sameClub=0;

   for(i=0; i < max; i++) {
      NSString *firstClub = [[players objectAtIndex:i] club];

      for (j = i+1; j < max; j++) {
         if ([firstClub isEqualToString:[[players objectAtIndex:j] club]]) {
            sameClub++;
         }
      }
   }
   return sameClub;
}

long countIntraClubMatchesWithSwitch(NSArray *players, NSString *club, long at)
   // count the same club matches if club were at position at
{
   long max = [players count];
   int i, j, sameClub=0;

   for(i=0; i < max; i++) {
      NSString *firstClub = [[players objectAtIndex:i] club];
      if (i == at) {
         firstClub = club;
      }

      for (j = i+1; j < max; j++) {
         if ( (j == at) && ([firstClub isEqualToString:club]) ) {
            sameClub++;
         } else if ([firstClub isEqualToString:[[players objectAtIndex:j] club]]) {
            sameClub++;
         }
      }
   }
   return sameClub;
}

- (long) maxGroupPlayerRanking:(NSArray *)playerLists;
{
   long i, max = [playerLists count];
   long maxGroupPlayerRanking = 0;

   for (i=0; i < max; i++) {
      NSArray *plys = [playerLists objectAtIndex:i];
      long j, lmax = [plys count];

      for (j=0; j<lmax; j++) {
         if ([[plys objectAtIndex:j] rankingInSeries:self] > maxGroupPlayerRanking) {
            maxGroupPlayerRanking = [[plys objectAtIndex:j] rankingInSeries:self];
         }
      }
   }
   
   return maxGroupPlayerRanking;
}

- (NSMutableArray *)groupPositionClasses:(NSMutableArray *)playerLists;
{
   long maxGroupPlayerRanking = [self maxGroupPlayerRanking:playerLists];
   long i, max = [playerLists count];
   NSMutableArray *classes = [NSMutableArray array];

   for (i=0; i < maxGroupPlayerRanking; i++) {
      [classes addObject:[NSMutableArray array]];
   }

   for (i=0; i < max; i++) {
      NSArray *plys = [playerLists objectAtIndex:i];
      long j, lmax = [plys count];

      for (j=0; j<lmax; j++) {
         long classIndex = [[plys objectAtIndex:j] rankingInSeries:self]-1;
         
         [[classes objectAtIndex:classIndex] addObject:[GroupPosition forGroup:i position:j]];
      }
   }
   
   return classes;
}

- (NSMutableArray *)groupRankClasses:(NSMutableArray *)playerLists;
{
   long i, max = [playerLists count];
   long firstCount = [playerLists.firstObject count], lastCount = [playerLists.lastObject count], maxCount;
   if (firstCount > lastCount) {
      maxCount = firstCount;
   } else {
      maxCount = lastCount;
   }
   NSMutableArray *classes = [NSMutableArray array];
   for (i=maxCount; i>0; i--) {       // we do not move the heads of groups
      NSMutableArray *gpClass = [NSMutableArray array];
      
      for (long j = 0; j<max; j++) {
         NSArray *players = [playerLists objectAtIndex:j];
         if (players.count > i) {
            [gpClass addObject:[GroupPosition forGroup:j position:i]];
         }
      }
      [classes addObject:gpClass];
   }

   return classes;
}


- (void)optimizeClubsInLists:(NSMutableArray *)playerLists;
{
   long i, max = [playerLists count];
   NSMutableArray *classes = nil;
   bool switchPerformed = true;
   int  level = 50;

   classes = [self groupPositionClasses:playerLists];

   max = [classes count];
   while ( (switchPerformed) || (level > 0) ) {
      switchPerformed = false;
      if (level > 0) {
         level = level - 10;
      }
      
      for (i=max-1; i >= 0; i--) {
         NSArray *groupPositions = [classes objectAtIndex:i];

         switchPerformed |= [self optimizeClubsInLists:playerLists
                                        usingPositions:groupPositions
                                                 level:level];
      }
   }
}

bool shouldPerformGroupSwitch(NSMutableArray *playerLists,
                              GroupPosition *pos1, GroupPosition *pos2,
                              long level)
{
   if ([pos1 groupNo] != [pos2 groupNo]) {
      NSMutableArray *group1 = [playerLists objectAtIndex:[pos1 groupNo]];
      NSMutableArray *group2 = [playerLists objectAtIndex:[pos2 groupNo]];
      NSString *club1  = [[group1 objectAtIndex:[pos1 position]] club];
      NSString *club2  = [[group2 objectAtIndex:[pos2 position]] club];
      long intraClubMatchesBefore1 = countIntraClubMatches(group1);
      long intraClubMatchesBefore2 = countIntraClubMatches(group2);
      long intraClubMatchesAfter1  = countIntraClubMatchesWithSwitch(group1, club2, [pos1 position]);
      long intraClubMatchesAfter2  = countIntraClubMatchesWithSwitch(group2, club1, [pos2 position]);

      if ( (intraClubMatchesBefore1 + intraClubMatchesBefore2)
           > (intraClubMatchesAfter1 + intraClubMatchesAfter2) ) {
            // improve total number of intra club matches
         return true;
      }

      if ( ([group1 count] < [group2 count])
           && (intraClubMatchesBefore1 > intraClubMatchesAfter1)
           && ( (intraClubMatchesBefore1 + intraClubMatchesBefore2)
                == (intraClubMatchesAfter1 + intraClubMatchesAfter2) ) ) {
                // maintain same number of intra club matches, but in a larger group
         return true;
      }

      if ( ([group2 count] < [group1 count])
           && (intraClubMatchesBefore2 > intraClubMatchesAfter2)
           && ( (intraClubMatchesBefore1 + intraClubMatchesBefore2)
                == (intraClubMatchesAfter1 + intraClubMatchesAfter2) ) ) {
                // maintain same number of intra club matches, but in a larger group
         return true;
      }
   }
   
   return arc4random_uniform(100) < level;
      // level will steadily decrease, once it is zero only improvements will be made
}

void switchGroupPositions(NSMutableArray *playerLists,
                          GroupPosition *pos1, GroupPosition *pos2)
{
   NSMutableArray *group1 = [playerLists objectAtIndex:[pos1 groupNo]];
   NSMutableArray *group2 = [playerLists objectAtIndex:[pos2 groupNo]];
   id player1  = [group1 objectAtIndex:[pos1 position]];
   id player2  = [group2 objectAtIndex:[pos2 position]];
   
   [group2 removeObjectAtIndex:[pos2 position]];
   [group1 removeObjectAtIndex:[pos1 position]];
   // the order is important here if group1 == group2!
   [group1 insertObject:player2 atIndex:[pos1 position]];
   [group2 insertObject:player1 atIndex:[pos2 position]];
}

- (bool)optimizeClubsInLists:(NSMutableArray *)playerLists
              usingPositions:(NSArray *)groupPositions
                       level:(long)level;
{
   long i, max = [groupPositions count];
   bool switchPerformed = false;

   for (i=0; i < max; i++) {
      long j;

      for (j=i+1; j < max; j++) {
         GroupPosition *pos1 = [groupPositions objectAtIndex:i];
         GroupPosition *pos2 = [groupPositions objectAtIndex:j];

         if (shouldPerformGroupSwitch(playerLists, pos1, pos2, level)) {
            switchGroupPositions(playerLists, pos1, pos2);
            switchPerformed = true;
         }
      }
   }
   
   return switchPerformed;
}

- (BOOL)doGroupDraw
/* performs a drawing for groups. The players with a ranking greater or equal
   to setPlayers advance directly to the ko, the rest plays in groups of up
   to 4 players (no more than 3 groups will have 3 players).
*/
{
   long i, set, unset, grps, max, last;
   NSMutableArray *place[4];				// places in groups
   NSMutableArray *matches = [[NSMutableArray alloc] init];		// for numbering
      
   groups = [[NSMutableArray alloc] init];		// there will be groups
   for(i=0; i<4; i++)				// allocate the lists
   {
      place[i] = [[NSMutableArray alloc] init];
   } // for
   max = [players count];
   set = 0;
   while ((set < max) &&
        (([[players objectAtIndex:set] setNumber] > 0)
	|| ([[[players objectAtIndex:set] player] rankingInSeries:self] >= setPlayers)))
   {
      set++;
   } // while
   unset = max - set;
   if (unset <= 5)
   {
		NSMutableArray *grpPlayers = [NSMutableArray array];
		
      grps = 1;
      [groups addObject:[[Group alloc] initSeries:self number:1]];
      
      /******************* all players in the single group ******************/
      
      for(i=0; i<unset; i++)
      {
         [grpPlayers addObject:[[players objectAtIndex:set + i] player]];
      }
		[[groups objectAtIndex:0] setPlayers:grpPlayers];
   } // if
   else
   {
      grps = [self numberOfGroups];
      
      /*********************   distribute players in groups   **************/
   
      for(i = 0; i < grps; i++)
      {
			[place[0] addObject:[[players objectAtIndex:set + i] player]];
			[place[1] addObject:[[players objectAtIndex:set + 2*grps - i - 1] player]];
			[place[2] addObject:[[players objectAtIndex:set + 2*grps + i] player]];
			if (set + 4*grps - i - 1 < max)
			{
				[place[3] addObject:
						[[players objectAtIndex:set + 4*grps - i - 1] player]];
			} // if
			
			/*******************   allocate the groups   ***********************/
			[groups addObject:[[Group alloc] initSeries:self number:i+1]];
      } // for
      
      notTheSameClub(place);
      last = [place[3] count];
      
      for(i = 0; i < grps; i++)
      {
			NSMutableArray *grpPlayers = [NSMutableArray array];
			
			[grpPlayers addObject:[place[0] objectAtIndex:i]];
			[grpPlayers addObject:[place[1] objectAtIndex:i]];
			[grpPlayers addObject:[place[2] objectAtIndex:i]];
			if (last > (grps - 1 - i))			{
				[grpPlayers addObject:[place[3] objectAtIndex:last - (grps - i)]];
			}
			
			[[groups objectAtIndex:i] setPlayers:grpPlayers];
      } // for
   } // if
   
   /*********************   init GroupPlayers   ****************************/
   
   for(i=set; i<max; i++)
   {
      [players removeLastObject];
   } // for
   
   for(i=0; i<grps; i++)
   {
      [players addObject:[[SeriesPlayer alloc] initGroup:[groups objectAtIndex:i]
                                                position:1]];
   } // for
   
   if (promotees > 1) {
      for(i=grps-1; i>= 0; i--)
         // reverse order, second place is best at the end.
      {
         [players addObject: [[SeriesPlayer alloc] initGroup:[groups objectAtIndex:i]
                                                    position:2]];
      } // for
   }
   
   [super doSimpleDraw];		// now simple Draw will be good
   
   for(i=0; i<grps; i++)
   {
      [[groups objectAtIndex:i] finishedDrawing];
   } // for
   
   [matches addObject:matchTable];		// insert match to start from
   numberAllMatches(matches);

   return YES;
} // doGroupDraw

 void printAllMatches(NSMutableArray *matches);		// forward declaration

- (IBAction) allMatchSheets:(id)sender;
// print out all match sheets of this Series in increasing order
// (Final comes last)
// plus the group-sheets in decreasing order
{
   long i, max = [groups count];
	bool printDetails=[TournamentDelegate.shared.preferences groupDetails];
   
   printAllMatches([self matchTables]);
   
   for (i=max-1; i>=0; i--)
   {
      Group *g=(Group *)[groups objectAtIndex:i];
      
      if (![g finished]) {
			if (printDetails) {
				[g allMatchSheets:sender];
			} else {
				[g print:nil];
			}
      } // if
   } // for
} // allMatchSheets

- (void)cleanup;
// do some cleanup before newly loading players
// (remove group Players)
{
	[super cleanup];
   [groups removeAllObjects];
   [groupPlayers  removeAllObjects];
} // cleanup

- (BOOL)makeTable
/* ret: YES if the series was drawn correctly (or has aleeady been so)
  what: draws the series according using the group draw defined in here
        (CAUTION: that one uses doSimpleDraw)
*/
{
   alreadyDrawn = [self newGroupDraw];
   [self addSmallFinalIfDesired];
   [self numberKoMatches];   

   return alreadyDrawn;
} // makeTable

- (float)basePriority;
{
   return 1.0;
}

- (long)countPlayers;
{
   long sum = 0, i, max = [groups count];
   
   for(i=0; i<max; i++) {
      sum = sum + [[[groups objectAtIndex:i] players] count];
   } // for
   i = 0;
   max = [players count];
   while ((i < max)
	 && (![[[players objectAtIndex:i] player] isKindOfClass:[GroupPlayer class]])) {
      sum++;
      i++;
   } // while
   return sum;
} // countPlayers

- (void)startSeries;
/* start the series and enter the ready matches into the matchBrowser
*/
{
   long maxPos = [positions count], i;
   [self setStarted:YES]; 		// now the series starts.

   for(i=0; i<maxPos; i++)
   {
      [[[positions objectAtIndex:i] winner]
        addMatch:[[positions objectAtIndex:i] nextMatch]];
      [self checkMaxRanking:[[positions objectAtIndex:i] winner]];
   } // for
   
   for(Group *group in groups) {
      for(id<Player> player in [group players]) {
         [player addMatch:group];
      }
   }

   [[TournamentDelegate.shared.matchController matchBrowser] updateMatrix];
} // startSeries

- (NSString *)numString;
{
	if ([[self sex] isEqualToString:@"W"]) {
      NSString *anzahlSpielerinnenFormat = NSLocalizedStringFromTable(@"Anzahl Spielerinnen: %d", @"Tournament",
                                                                      @"Format für Anzahl Spielerinnen");
		return [NSString stringWithFormat:anzahlSpielerinnenFormat, [self countPlayers]];
	} else {
      NSString *anzahlSpielerFormat = NSLocalizedStringFromTable(@"Anzahl Spieler: %d", @"Tournament",
                                                                 @"Format für Anzahl Spielerinnen");
		return [NSString stringWithFormat:anzahlSpielerFormat, [self countPlayers]];
	}
}

- (long)totalPages;
{  
   return [tablePages count] + [pageGroupStarts count] + [self detailPages];
} // totalPages

- (long)lastInterestingPage;
{
   long pages = [self totalPages];
   
   if (![self finished]) {
      pages = pages - 1;
   }
   
   return pages;
}


- paginateGroups:aView;
// first groups on pages, the last group is at the end
{  long i, max = [groups count];

   for(i = 1; i <= max; i = i + [aView maxGroupsOnPage])
   {
      [pageGroupStarts addObject:[NSNumber numberWithLong:i]];
   } // for
   [pageGroupStarts addObject:[NSNumber numberWithLong:max+1]];
   
   return self;
} // paginateGroups

- paginate:sender;
// paginate table and groups of a series
{
	float top;
	
   [tablePages removeAllObjects];
   [pageGroupStarts removeAllObjects];

   if ([matchTable pMatches] > [sender maxMatchOnPage])
   {
      master = matchTable;
   }
   else
   {
      master = nil;
   } // if
   [super paginateTable:matchTable in:sender];
   [self paginateGroups:sender];
	
	top = [self totalPages] * (int)[sender pageHeight];
	[sender setFrameSize:NSMakeSize([sender pageWidth],top)];
   
   return self;
} // paginate

- drawGroups:(float *)top from:(long)first to:(long)last;
// draw groups first to last-1, last goes to next page
{
	long i;
   
   for(i=first-1; i<last-1; i=i+2)
   {  float tmptop;
   
      *top = *top-15.0;
      tmptop = *top;
      [[groups objectAtIndex:i] drawGroupLeft:20 top:top];
      
      if(i+1 < last-1)
      {
			[[groups objectAtIndex:i+1] drawGroupLeft:280 top:&tmptop];
      } // if
      if (tmptop < *top) *top = tmptop;
   } // for
   
   return self;
} // drawGroups

- (void)drawGroupNames:(const NSRect)rect page:(NSRect *)page;
{
   long i, max = [pageGroupStarts count];
   for(i=1; i<max; i++) {
      float top;
      
		if (NSIntersectsRect(*page, rect)) {
         top = [self pageHeader:page];
         
			[self drawGroups:&top from:[[pageGroupStarts objectAtIndex:i-1] intValue]
                       to:[[pageGroupStarts objectAtIndex:i] intValue]];
		} else {
			_currentPage++;
		}
      page->origin.y -= page->size.height;
   } // for
}

- (void) drawKOTable:(const NSRect)rect page:(NSRect *)page
                  maxMatchesOnPage:(long)maxMatchesOnPage;
{
   [super drawSelf:rect page:page maxMatchesOnPage:maxMatchesOnPage];
   page->origin.y -= page->size.height;
}

- drawSelf:(const NSRect)rect page:(NSRect *)page
                  maxMatchesOnPage:(long)maxMatchesOnPage;
{
   [[NSColor blackColor] set];

   [self drawGroupNames:rect page:page];
   
   [self drawKOTable:rect page:page maxMatchesOnPage:maxMatchesOnPage];

   [self drawGroupDetails:rect page:page];
   
   [self drawRankingListPage:rect page:page maxMatchesOnPage:maxMatchesOnPage];

   return self;
} // drawSelf

- (void) drawRankingListBelow:(float) top at:(float)ranklistleft;
{
   if ( ([groups count] > 1) || ([matchTable winner] != nil) ) {
      if ([matchTable winner] != nil) {
         [matchTable drawRankingList:ranklistleft at:&top upTo:16 withOffset:0];
         [self drawGroupRankingFrom:[self promotees] doneUpTo:[matchTable pMatches]+1 at:ranklistleft below:top];
      }
   } else {
      if ([[groups objectAtIndex:0] finished]) {
         [self drawGroupRankingFrom:0 doneUpTo:0 at:ranklistleft below:top];
      }
   }
}

- (NSMutableArray *) addGroupResultsTo:(NSMutableArray *)list from:(long) offset upTo:(long)max lastGroup:(long) last;
{
   long currentRank = offset, gMax = [groups count];
   while (([list count] < max) && (currentRank < [[[groups objectAtIndex:last-1] rankingList] count])) {
      long i=0;
      while (([list count] < max) && (i<gMax)) {
         NSArray * rankingList = [[groups objectAtIndex:i] rankingList];
         
         if (currentRank < [rankingList count]) {
            [list addObject:[rankingList objectAtIndex:currentRank]];
         }
         i++;
      }
      currentRank++;
      i=gMax-1;
      
      while (([list count] < max) && (i>= 0)) {
         NSArray * rankingList = [[groups objectAtIndex:i] rankingList];
         
         if (currentRank < [rankingList count]) {
            [list addObject:[rankingList objectAtIndex:currentRank]];
         }
         i--;
      }
      currentRank++;
   }
   return list;
}

- (NSMutableArray*) rankingListUpTo:(long) max;
{
   NSMutableArray* list = [super rankingListUpTo: max];
   if ([list count] == 0) {
      return list;
   } else if ([list count] < max) {
      [self addGroupResultsTo:list from:[self promotees] upTo: max lastGroup:[groups count]];
   }
   return list;
}

- textRankingListIn:text;
{
	long finalRankings=[matchTable pMatches]+1;
	[matchTable textRankingListIn:text upTo:finalRankings];
   [self appendGroupRanksAfterPromoteesTo:text withOffset:finalRankings];
   
   return self;
}

-(void) appendGroupRanksAfterPromoteesTo:(id)text withOffset:(long)initialOffset;
{
   long i, j, maxGroups=[groups count], maxRank = [[[groups objectAtIndex:maxGroups-1] players] count];
   long offset = initialOffset+1, countRanks;
   
   for (i=[self promotees]; i<maxRank; i++) {
      countRanks=0;
      for (j=0; j<maxGroups; j++) {
         Group *group = [groups objectAtIndex:j];
         NSArray *rankingList = [group rankingList];
         if ([rankingList count] > i) {
            id<Player> player = [rankingList objectAtIndex:i];
            NSString *line=nil;
            if ((countRanks == 0) && (player != nil)) {
               line=[NSString stringWithFormat:@"\t%ld.\t%@\t%@\n", offset, [player longName], [player club]];
            } else {
               line=[NSString stringWithFormat:@"\t\t%@\t%@\n", [player longName], [player club]];
            }
            countRanks++;
            [text appendText: line];
         }
         offset=offset+countRanks;
      }
   }
}

- (void) drawGroupRankingFrom:(long)from doneUpTo:(long)done at:(float) left below:(float) top;
{
	long currentRank=done;
	long i, max=[groups count];
	int playersPrinted=1;		// virtual to start it off
	float playerBase=top-4;
	NSDictionary *attributes=[NSDictionary dictionaryWithObject:
				  [NSFont fontWithName:@"Helvetica" size:9.0] forKey:NSFontAttributeName];

	long rankIndex=from;
	while ((playersPrinted>0) && (currentRank < 20)) {
		float rankBase=playerBase;
		
		currentRank=currentRank+playersPrinted;
		playersPrinted=0;
		for (i=0; i<max; i++) {
			Group *group=[groups objectAtIndex:i];
			NSArray *ranking=[group rankingList];
			if (rankIndex < [ranking count]) {
				[[ranking objectAtIndex:rankIndex] drawInMatchTableOf:group
							x:left+20 y:playerBase];
				playersPrinted++;
				playerBase=playerBase-10.0;
			}
		}
		if (playersPrinted > 0) {
			[[NSMutableString stringWithFormat:@"%ld", currentRank]
					drawAtPoint:NSMakePoint(left, rankBase)
				withAttributes:attributes];
			rankIndex++;
		}
	}
}

- (void)drawGroupDetails:(const NSRect)rect page:(NSRect *)page;
{
   long i, max = [groups count];
	NSRect groupRect;

	for(i=0; i<max; i++) {
		Group *group=(Group *)[groups objectAtIndex:i];
      groupRect = *page;
      groupRect.size.height = page->size.height * [group detailPages];
				
		groupRect.origin.y=page->origin.y - ([group detailPages]-1)*page->size.height;
		
		if (NSIntersectsRect(groupRect, rect)) {
         float top = [self pageHeader:page];
			[group drawDetails:&top firstPageBottom:page->origin.y];
			_currentPage = _currentPage+[group detailPages]-1;
		} else {
			_currentPage = _currentPage+[group detailPages];
		}
      page->origin.y = page->origin.y - [group detailPages]*page->size.height;
   } // for
}

- (long)printWOPlayersInto:text;
/* in: text: The SmallTextController which controlls the text to print in
 what: prints just the WO players without bells and whistles,
       but also in the groups
 overrides method from series since groups are otherwise not covered
*/
{  long max = [groups count], i, count;
   
   count=[super printWOPlayersInto:text];
   
   // also print the players from the groups
   for(i=0; i<max; i++)
   {
      count = count + [[groups objectAtIndex:i] printWOPlayersInto:text];
   } // for
   
   return count;
   
} // printWOPlayersIn

- (long)printNPPlayersInto:text;
/* in: text: The SmallTextController which controlls the text to print in
 what: prints just the not present players without bells and whistles,
       but also in the groups
 overrides method from series since groups are otherwise not covered
*/
{  long max = [groups count], i, count;
   
   count=[super printNPPlayersInto:text];
   
   // also print the players from the groups
   for(i=0; i<max; i++)
   {
      count = count + [[groups objectAtIndex:i] printNPPlayersInto:text];
   } // for
   
   return count;
   
} // printWOPlayersIn

- (long)detailPages;
{
	if ([TournamentDelegate.shared.preferences groupDetails]) {
		long pages=0;

		for (Group *group in groups) {
			pages = pages+[group detailPages];
		}
		return pages;
	} else {
		return 0;
	}
}

- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
{
   long i, max=[groups count];

   for (i=0; i < max; i++) {
      Group *group = (Group *)[groups objectAtIndex:i];

      [group appendSingleResultsAsTextTo:text];
   }

   [super appendSingleResultsAsTextTo:text];
}

- (long)  numberOfGroupsDrawn;
{
   return [groups count];
}

- (long) numberOfUnplayedGroups;
{
   long i, max=[groups count], count=0;
   
   for (i=0; i<max; i++) {
      if (![[groups objectAtIndex:i] hasBeenStarted]) {
         count+=1;
      }
   }
   return count;
}

- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
{
   long i, max=[groups count];
   
   for (i=0; i < max; i++) {
      Group *group = (Group *)[groups objectAtIndex:i];
      [group gatherPlayersIn:allPlayers];
   }
   
   [super gatherPlayersIn:allPlayers];
}

- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
{
   [super appendMatchResultsAsXmlTo:text];

   long i=0, max=[groups count];
   
   for (i=0; i<max; i++) {
      [[groups objectAtIndex:i] appendMatchResultsAsXmlTo:text];
   }
}

- (long)numberOfSetsFor:(Match *)match;
{
   if ([match isKindOfClass:[GroupMatch class]]) {
      if ([self countPlayers]*4 < [self bestOfSeven]) {
         return 7;
      } else {
         return 5;
      }   
   } else {
      return [super numberOfSetsFor:match];
   }
}

- (void)playSingleMatchesForAllOpenGroups;
{
   long i, max=[groups count];
   
   for (i=0; i<max; i++) {
      if (![[groups objectAtIndex:i] hasBeenStarted]) {
         [[groups objectAtIndex:i] playSingleMatches];
      }
   }
   [TournamentDelegate.shared.matchController saveDocument:self];
}

@end

