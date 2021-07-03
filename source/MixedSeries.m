/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a mixed double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 16.2.95, Patru: first written
          18.2.95, Patru: improved checking, new drawing scheme
    Bugs: -not very well documented
 *****************************************************************************/

#import "MixedSeries.h"
#import "DoubleSeries.h"
#import "DoublePlayer.h"
#import "SeriesPlayer.h"
#import "SinglePlayer.h"
#import "SeriesController.h"
#import "Series+DoubleLogger.h"
#import "Tournament-Swift.h"

@implementation MixedSeries

-(instancetype)init
{
   self=[super init];
   doublePartner = [[NSMutableDictionary alloc] init];
   menSingles = [[NSMutableArray alloc] init];
   womenSingles = [[NSMutableArray alloc] init];
   RankSel = @selector(mixedRanking);
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
//   DBValue *aValue = [[DBValue alloc] init];

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

/*- write: (NXTypedStream *) s;
{
   [super write:s];
   NXWriteTypes(s, "@@@", &doublePartner, &menSingles, &womenSingles);
   return self;
} // write

- read:(NXTypedStream *) s;
{ 
   [super read:s];
   NXReadTypes(s, "@@@", &doublePartner, &menSingles, &womenSingles);
   return self;
} // read
*/

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
	
   if (pl == partnerPlayer)
   {
      [drawingErrors addObject: [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ kann nicht mit sich selber Mixed spielen.", @"Tournament", nil), [pl longName]]];
      return;
   } // if
   
   if ([pl sex] == [partnerPlayer sex]) {
      NSString *homogenesMixed = NSLocalizedStringFromTable(@"homogenes Mixed", @"Tournament", nil);
      [drawingErrors addObject: [NSString stringWithFormat:homogenesMixed, [pl longName], [partnerPlayer longName]]];
      return;
   }
   
   if ((doubPartner = [doublePartner objectForKey:[pl licenceNumber]])) {
      if (partnerPlayer == nil) {
         id falsePartner;
			
			if ([(SeriesPlayer *)[doubPartner player] player] == pl)	{
				falsePartner = [[doubPartner player] partner];
			} else {
				falsePartner = [(SeriesPlayer *)[doubPartner player] player];
			}
			[self inscriptionWithoutPartner:pl notPartner:falsePartner];
			return;
      }
      else if (pl == [(DoublePlayer *)[doubPartner player] player]) {
         if (partnerPlayer != [(DoublePlayer *)[doubPartner player] partner])	{
				[self alreadyHasPartner:pl	existingPartner:[(DoublePlayer *)[doubPartner player] partner]
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
      } else if ([[pl sex] isEqualToString:@"W"]) {
			serPl = [[SeriesPlayer alloc] initDouble:pl partner:partnerPlayer
													 setNumber:setNum];
      } else {
			serPl = [[SeriesPlayer alloc] initDouble:partnerPlayer partner:pl
													 setNumber:setNum];
      } // if
      [doublePartner setObject:serPl forKey:[pl licenceNumber]];
      [doublePartner setObject:serPl forKey:[partnerPlayer licenceNumber]];
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
// take all the players from the menSingles- and the womenSingles-list and
// make doubles players from them. Possibly, some players in one list
// are left open. Strong players are matched first, try to avoid doubles
// from the same club
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
} // numString

- (void)appendTableFooterTo:(NSMutableString *)html;
{
   [html appendString:@"<tr><td colspan=\"5\"><b>Offen gemeldete Damen</b> "
      @"(werden bei der Auslosung von oben herab zugelost)</td></tr>\n"];
   [self appendPlayers:womenSingles asRowsTo:html];
   [html appendString:@"<tr><td colspan=\"5\"><b>Offen gemeldete Herren</b></td></tr>\n"];
   [self appendPlayers:menSingles asRowsTo:html];
}

- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
{	// mixed series yields no single results!
}

- (void)appendSingleSeriesInfoAsTextTo:(NSMutableString *)text;
{ // mixed series has no single series info
}

- (NSString *)type;
{
	return @"Mixed";
}

- (void)gatherPointsIn:(NSMutableDictionary *)clubResults;
{
	[self doublePointsIn:clubResults];
}

- (NSString *) paymentName;
{
   return [NSString stringWithFormat:@"Mix %@", [self doubleCategoryString]];
}
@end
