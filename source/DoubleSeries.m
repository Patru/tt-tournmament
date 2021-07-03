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
#import <PGSQLKit/PGSQLKit.h>
#import "DoubleSeries.h"
#import "DoublePlayer.h"
#import "SeriesPlayer.h"
#import "Series+DoubleLogger.h"
#import "Tournament-Swift.h"


SinglePlayer *dummyPartner=nil;
   // dummy partner for a single player

@implementation DoubleSeries

+ (SinglePlayer *)single;
{
	if (dummyPartner == nil) {
		dummyPartner=[[SinglePlayer alloc] init];
		[dummyPartner setLicence:-1];
	}

	return dummyPartner;
}

- (instancetype)init;
{
   self=[super init];
   doublePartner = [[NSMutableDictionary alloc] init];
   singles = [[NSMutableArray alloc] init];
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
   singles = [[NSMutableArray alloc] init];
   return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder;
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:doublePartner];
	[encoder encodeObject:singles];
}

- (id)initWithCoder:(NSCoder *)decoder;
{
   self = [super initWithCoder:decoder];
   doublePartner=[decoder decodeObject];
   singles=[decoder decodeObject];

   return self;
}

/*- write: (NXTypedStream *) s;
{
   [super write:s];
   NXWriteTypes(s, "@@", &doublePartner, &singles);
   return self;
} // write

- read:(NXTypedStream *) s;
{ 
   [super read:s];
   NXReadTypes(s, "@@", &doublePartner, &singles);
   return self;
} // read
*/

- addSingle:(SinglePlayer *)pl;
// add the player pl to the singles list in sorted order (only for doubles)
{
   long i  = [singles count], plRank;
   
   plRank  = [pl rankingInSeries:self];
   
   while ((i > 0) && ([[singles objectAtIndex:i-1] rankingInSeries:self] < plRank))
   {
      i--;
   }; // while
   [singles insertObject:pl atIndex:i];
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
				[self alreadyHasPartner:pl	existingPartner:[(DoublePlayer *)[doubPartner player] partner]
								 newPartner:partnerPlayer];
				return;
			} // if
      } else if (pl == [(DoublePlayer *)[doubPartner player] partner]) {
			if (partnerPlayer != [(DoublePlayer *)[doubPartner player] player]) {
				[self alreadyHasPartner:pl	existingPartner:[(DoublePlayer *)[doubPartner player] player]
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
			[self alreadyHasPartner:partnerPlayer	existingPartner:otherPlayer
							 newPartner:pl];
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
   while([singles count] > 1)
   {
      max = [singles count];
      next = [singles objectAtIndex:0];	// match this player
      i = 1;
      while((i < max) && ([next club] == [[singles objectAtIndex:i] club]))
      {
         i++;
      } // while
      if (i==max) {
         i=1;				// second best player from same club,
	 				// obviously only one club remains
         //			fprintf(stdlog, "gleicher Club forciert\n");
         [self logSameClubForced];
      } // if
      [self logDouble:next with:[singles objectAtIndex:i]];
      [doublePartner removeObjectForKey:[next licenceNumber]];
      [doublePartner removeObjectForKey:[[singles objectAtIndex:i] licenceNumber]];
      [self addPlayer:next set:0 partner:[singles objectAtIndex:i]];
      [singles removeObjectAtIndex:i];			// remove first !!
      [singles removeObjectAtIndex:0];			// otherwise false
   } // while
   if([singles count] == 1)
   {
      [self logCouldNotAssign:[singles objectAtIndex:0]];
      [doublePartner removeObjectForKey:[[singles objectAtIndex:0] licenceNumber]];
		[singles removeObjectAtIndex:0];
   } // if
   return self;
} // makeDoubles

- (void)cleanup;
// do some cleanup before newly loading players
// (remove all partners and serPlayers)
{
	[super cleanup];
	[doublePartner removeAllObjects];
	[singles removeAllObjects];
} // cleanup

- (BOOL)makeTable;
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
																				@"Format fŸr Anzahl Paare");
	return [NSString stringWithFormat:anzahlPaareFormat, [self countPlayers]];
}

- (void)appendTableFooterTo:(NSMutableString *)html;
{
	NSString *offenGemeldet = NSLocalizedStringFromTable(@"Offen gemeldet", @"Tournament", NULL);
	NSString *zusammenGelost = NSLocalizedStringFromTable(@"(werden bei der Auslosung von oben herab zusammengelost)",
																			@"Tournament", NULL);
   [html appendFormat:@"<tr><td colspan=\"5\"><b>%@</b> %@</td></tr>\n", offenGemeldet, zusammenGelost];
   [self appendPlayers:singles asRowsTo:html];
}

- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
{	// double series yields no single results!
}

- (void)appendSingleSeriesInfoAsTextTo:(NSMutableString *)text;
{ // double series has no single series info
}

- (NSString *)type;
{
	return @"Doppel";
}

- (void)gatherPointsIn:(NSMutableDictionary *)clubResults;
{
	[self doublePointsIn:clubResults];
}

- (NSString *) paymentName;
{
   return [DoubleSeries doublePaymentNane:self];
}

// artificially static method to centralize this logic despite the faulty inheritence structure
+ (NSString *) doublePaymentNane: (Series *) series;
{
   NSString *doubleFormat = @"Do %@";
   if ([series isWomanSeries]) {
      doubleFormat = @"Da Do %@";
   }
   return [NSString stringWithFormat:doubleFormat, [series doubleCategoryString]];

}
@end

