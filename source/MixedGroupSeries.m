/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
          18.2.95, Patru: improved checking, new drawing scheme
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "MixedGroupSeries.h"
#import "DoublePlayer.h"
#import "DoubleSeries.h"
#import "SeriesPlayer.h"
#import "Series+DoubleLogger.h"
#import "Tournament-Swift.h"

@implementation MixedGroupSeries

-(instancetype)init
{
   self=[super init];
   doublePartner = [[NSMutableDictionary alloc] init];
   menSingles = [[NSMutableArray alloc] init];
   womenSingles = [[NSMutableArray alloc] init];
   return self;
} // init

- (instancetype)initFromRecord:(PGSQLRecord *)record;
	/* in: recList; a DBRecordList to init from
       source;  entity to init from
       i;       position in Recordlist
 what: initializes the player from a Database
  ret: YES if everything could be read, NO if something went wrong.
*/
{
   self=[super initFromRecord:record];
   	// get the common fields via super
   doublePartner = [[NSMutableDictionary alloc] init];
   menSingles = [[NSMutableArray alloc] init];
   womenSingles = [[NSMutableArray alloc] init];
   RankSel = @selector(mixedRanking);
   return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:doublePartner];
	[encoder encodeObject:menSingles];
	[encoder encodeObject:womenSingles];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self = [super initWithCoder:decoder];
	doublePartner=[decoder decodeObject];
	menSingles=[decoder decodeObject];
	womenSingles=[decoder decodeObject];

	return self;
}

- addSingle:(SinglePlayer *)pl;
// add the player pl to the singles list in sorted order (only for doubles)
{
   long i=0, plRank;

   if ([[pl sex] isEqualToString:@"W"]) {		// female single
      plRank  = (int)[pl womanRanking];
      i  = [womenSingles count];

      while ((i > 0) && ((int)[[womenSingles objectAtIndex:i-1] womanRanking]
                         < plRank)) {
			i--;
      }
      [womenSingles insertObject:pl atIndex:i];
   } else {						// uhm, well, probably male
      plRank  = (int)[pl ranking];
      i  = [menSingles count];

      while ((i > 0) && ((int)[[menSingles objectAtIndex:i-1] ranking] < plRank)) {
			i--;
      }
      [menSingles insertObject:pl atIndex:i];
   }
   [doublePartner setObject:[DoubleSeries single] forKey:[pl licenceNumber]];

   return self;
} // addSingle

- (void)addPlayer:(SinglePlayer *)pl set:(long)setNum partner:(SinglePlayer *) partnerPlayer;
// adds a player to the list of players in sorted order,
// if setNum is present it takes precedent
{  id serPl = nil;
   long i = [players count];
   id doubPartner;

   if (pl == partnerPlayer) {
		[self notWithHimself:pl];
      return;
   } // if
	
   if ((doubPartner = [doublePartner objectForKey:[pl licenceNumber]])) {
      if (partnerPlayer == nil) {
         id falsePartner;
	 
			if ([(SeriesPlayer *)[doubPartner player] player] == pl) {
				falsePartner = [[doubPartner player] partner];
			} else {
				falsePartner = [(SeriesPlayer *)[doubPartner player] player];
			}
			[self inscriptionWithoutPartner:pl notPartner:falsePartner];
			return;
      } else if (pl == [(DoublePlayer *)[doubPartner player] player]) {
         if (partnerPlayer != [(DoublePlayer *)[doubPartner player] partner])	{
				[self alreadyHasPartner:pl existingPartner:[(DoublePlayer *)[doubPartner player] partner]
								 newPartner:partnerPlayer];
				return;
			} // if
      } else if (pl == [(DoublePlayer *)[doubPartner player] partner]) {
			if (partnerPlayer != [(DoublePlayer *)[doubPartner player] player]) {
				[self alreadyHasPartner:pl existingPartner:[(DoublePlayer *)[doubPartner player] player]
								 newPartner:partnerPlayer];
				return;
			} // if
      } // if
   } else if (partnerPlayer != nil) {
      if ((doubPartner = [doublePartner objectForKey:[partnerPlayer licenceNumber]])
				== [DoubleSeries single]) {
			[self inscriptionWithoutPartner:partnerPlayer notPartner:pl];
			return;
      } else if (doubPartner != nil) {  
         id otherPlayer;
			
			if ([(SeriesPlayer *)[doubPartner player] player] == partnerPlayer) {
				otherPlayer = [[doubPartner player] partner];
			} else {
				otherPlayer = [(SeriesPlayer *)[doubPartner player] player];
			} // if
			[self alreadyHasPartner:partnerPlayer existingPartner:otherPlayer newPartner:pl];
			return;
      } else {
			serPl = [[SeriesPlayer alloc] initDouble:pl partner:partnerPlayer
				setNumber:setNum];
			[doublePartner setObject:serPl forKey:[pl licenceNumber]];
			[doublePartner setObject:serPl forKey:[partnerPlayer licenceNumber]];
      } // if
   } else {
      [self addSingle:pl];
   } // if
	
   if (serPl != nil) {
      while((i>0) && ([serPl isStronger:[players objectAtIndex:i-1] sender:self])) {
			i--;
      } // while
      
      [players insertObject:serPl atIndex:i];
   } // if
} // addPlayer

- makeDoubles;
// take all the players from the singles-list and make doubles players
// from them. Possibly, one player is left open. Equal matches are tried.
{
   long i, max;
   id  next;				// next player to match
   
   [self logSeries: fullName];

   while(([womenSingles count] > 0) && ([menSingles count] > 0))
   {
      max = [menSingles count];
      
      next = [womenSingles objectAtIndex:0];	// match this woman player
      i = 0;				// start at 0 in mens list
      while((i < max) && ([next club] == [[menSingles objectAtIndex:i] club]))
      {
         i++;
      } // while
      if (i==max)
      {
         i=0;				// second best player from same club,
         // obviously only one club remains
         [self logSameClubForced];
      } // if
      [self logDouble:next with:[menSingles objectAtIndex:i]];
      [doublePartner removeObjectForKey:[next licenceNumber]];
      [doublePartner removeObjectForKey:[[menSingles objectAtIndex:i] licenceNumber]];
      [self addPlayer:next set:0 partner:[menSingles objectAtIndex:i]];
      [menSingles removeObjectAtIndex:i];			// order not important
      [womenSingles removeObjectAtIndex:0];			// in mixed case.
   } // while
   while ([menSingles count] > 0)
   {
      [self logCouldNotAssignMan:[menSingles objectAtIndex:0]];
      [doublePartner removeObjectForKey:[[menSingles objectAtIndex:0] licenceNumber]];
      [menSingles removeObjectAtIndex:0];
   } // while
   while ([womenSingles count] > 0)
   {
      [self logCouldNotAssignWoman:[womenSingles objectAtIndex:0]];
      [doublePartner removeObjectForKey:[[womenSingles objectAtIndex:0] licenceNumber]];
      [womenSingles removeObjectAtIndex:0];
   } // while
   return self;
} // makeDoubles

- (void)cleanup;
// do some cleanup before newly loading players
// (remove all partners and serPlayers)
{
	[super cleanup];
   [doublePartner removeAllObjects];
   [menSingles removeAllObjects];
   [womenSingles removeAllObjects];
} // cleanup

- (BOOL)makeTable
/* ret: YES if the series was drawn correctly (or has aleready been so)
  what: draws the series according to its sMode (seriesMode)
        (overrides standard method to add makeDoubles)
*/
{
   [self makeDoubles];
   return [super makeTable];
} // makeTable

- (float)basePriority;
{
   return 2.0;
}

- (NSString *)numString;
{
	NSString *anzahlPaareFormat = NSLocalizedStringFromTable(@"Anzahl Paare: %d", @"Tournament",
																				@"Format für Anzahl Paare");
	return [NSString stringWithFormat:anzahlPaareFormat, [self countPlayers]];
}


- (BOOL)doGroupDraw;
	/* performs a drawing for groups. All players play in groups of up
   to usualGroupSize players (no more than 3 groups will have 3 players).
   They are just distributed in order.
	*/
{
   long i, max = [players count];
   long numberOfGroups = (max + usualGroupSize - 1)/usualGroupSize;
   NSMutableArray *matches = [NSMutableArray array];		// for numbering
   NSMutableArray *playerLists[numberOfGroups];

   groups = [[NSMutableArray alloc] init];		// there will be groups

   for(i = 0; i < numberOfGroups; i++) {
      [groups addObject:[[Group alloc] initSeries:self number:i+1]];
      playerLists[i] = [NSMutableArray array];
   }

   /*********************   distribute players in groups   **************/

   for (i=0; i < max; i++) {
      long index = i%numberOfGroups;

      if ((i/numberOfGroups)%2 == 1) {		// reverse for every second round
	 index = numberOfGroups-1-index;
      }
      [playerLists[index] addObject:[[players objectAtIndex:i] player]];
   }

   [players removeAllObjects];

   for(i = 0; i < numberOfGroups; i++) {
      [[groups objectAtIndex:i] setPlayers:playerLists[i]];
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
		
   /*********************   init GroupPlayers   ****************************/

   [super doSimpleDraw];		// now simple Draw will be good

   for(i=0; i<numberOfGroups; i++) {
      [[groups objectAtIndex:i] finishedDrawing];
   } // for

   [matches addObject:matchTable];		// insert match to start from
   numberAllMatches(matches);
   [matches removeAllObjects];

   return YES;
} // doGroupDraw


- (NSString *)type;
{
	return @"Mixed";
}

- (void)gatherPointsIn:(NSMutableDictionary *)clubResults;
{
	[self doublePointsIn:clubResults];
}
@end

