/*****************************************************************************
     Use: Control a table tennis tournament.
          Two Players to form a double.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 14.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import "DoublePlayer.h"
#import "DoublePlayerInspector.h"
#import "TournamentController.h"
#import "UmpireController.h"
#import "Series.h"

#define shortNameHeight 9.0
#define longNameHeight 12.0

DoublePlayerInspector *_doublePlayerInspector=nil;

@implementation DoublePlayer

- init;
// all default initialization
{
   player = nil;
   partner = nil;
   longName = NULL;
   clubName = NULL;
   return self;
} // init

- initDouble:(SinglePlayer *)firstPlayer partner:(SinglePlayer *)secondPlayer;
{
   player = firstPlayer;
   partner = secondPlayer;
   longName = NULL;
   clubName = NULL;
   return self;
} // initPlayer

- setPlayer:(SinglePlayer *)aPlayer;
{
   player = aPlayer;
   longName = NULL;
   clubName = NULL;
   return self;
} // setPlayer

- setPartner:(SinglePlayer *)aPlayer;
{
   partner = aPlayer;
   longName = NULL;
   clubName = NULL;
   return self;
} // setPartner

- (BOOL)contains:(id <Player>)aPlayer;
{
   return (aPlayer == self) || (partner == aPlayer) || (player == aPlayer);
} // contains

- (SinglePlayer *)player;
{
   return player;
} //  player

- (SinglePlayer *)partner;
{
   return partner;
} // partner

- (NSString *)pName;
// returns the name of player
{
   if(player)
   {
      return [player pName];
   } // if
   return @"";
} // pName

- (NSString *)firstName;
// returns the first name of player
{
   if(player)
   {
      return [player firstName];
   }
   else
   {
      return @"";
   } // if
} // firstName

- (NSString *)club;
// returns the club or the combination of the two clubs
{
	NSString *club1=nil;
	NSString *club2=nil;

   if(clubName != nil) {
      return clubName;
   } else {
      if ((player != nil) && (partner != nil)) {
         if ([[player club] isEqualToString:[partner club]]) {
				clubName = [player club];
			} else {
				if ([[player club] length] < 7) {
					club1 = [player club];
				} else {
					club1 = [[player club] substringToIndex:7];
				} // if
				if ([[partner club] length] <7) {
					club2 = [partner club];
				} else {
					club2=[[partner club] substringToIndex:7];
				} // if
				
				clubName=[[NSString alloc] initWithFormat:@"%@/%@",  club1, club2];
			} // if
			return clubName;
      } // if
   } // if
   return @"";
} // club

- (NSString *)drawClub;
// return the club of the stronger player (according to ranking),
// this in accordance to international drawing procedures
{
   if ((int)[player ranking] < (int)[partner ranking])
   {
      return [partner club];
   }
   else
   {
      return [player club];
   } // if
} // club

- (NSString *)category;
// returns the category player if definded, empty String otherwise.
{
   if(player)
   {
      return [player category];
   }
   else
   {
      return @"";
   } // if
} // category

- (long)licence;
{
	return [[self licenceNumber] intValue];
}

- (NSNumber *)licenceNumber;
// returns a players licence if defined, 0 otherwise
{
   if(player) {
      return [player licenceNumber];
   } else {
      return 0;
   } // if
} // licence

- (long)rankingInSeries:(id <drawableSeries>)aSeries;
{
	return [self performWithLongResult:[aSeries rankSel]];
}

- (long)ranking;
// returns the combined ranking of player and partner (id! need selector)
{
   if((player) && (partner))
   {
      return [player ranking] + [partner ranking];
   }
   else
   {
      return 0;
   } // if
} // ranking

- (long)mixedRanking;
// returns the combined ranking of player and partner (id! need selector)
// needed only in mixed
{
   if((player) && (partner)) {
      if ([player womanRanking] != 0)
         return ([player womanRanking] + [partner ranking]);
      else if ([partner womanRanking] != 0)
         return [player ranking] + [partner womanRanking];
      else
         return 0l;		// should not happen!
      // if
   } else {
      return 0l;		// nonset: 0 ranking!
   } // if
} // ranking

- (float)dayRanking;
// returns the combined dayRanking of player and Partner
{
   if((player) && (partner)) {
      return [player dayRanking] + [partner dayRanking];
   } else {
      return 0.0;		// nonset: 0 ranking!
   } // if
} // dayRanking

- (long)womanRanking;
// returns the combined womanRanking of player and partner (id!, need selector)
{
   if((player) && (partner)) {
      return [player womanRanking] + [partner womanRanking];
   } else {
      return 0l;		// nonset: 0 ranking!
   } // if
} // womanRanking

- (float) tourPriority;
// returns the combined tourPriority of player and partner
{
   if((player) && (partner)) {
      return [player tourPriority] + [partner tourPriority];
   } else {
      return 0.0;		// nonset: 0 Priority!
   } // if
} // tourPriority

- (BOOL)ready;
// returns the combined ready-stte of player and partner, NO if not set
{
   if((player) && (partner)) {
      return [player ready] && [partner ready];
   } else {
      return NO;		// nonset: not Ready!
   } // if
} // ready

- (NSString *)longName;
// similar to pName, but for longName
{
   if(longName != nil)   {
      return longName;
   } else {
		NSString *name1;
		NSString *name2;
      if ((player != nil) && (partner != nil)) {
         if ([[player shortName] length] < 9) {
				name1 = [player shortName];
			} else	{
            name1 = [[player shortName] substringToIndex:9];
			}

			if ([[partner shortName] length] <9) {
				name2 = [partner shortName];
			} else {
				name2 = [[partner shortName] substringToIndex:9];
			} // if
			longName = [[NSString alloc] initWithFormat:@"%@/%@", name1, name2];
			return longName;
      } // if
   } // if
   return @"";
} // longName

- (NSString *)shortName;
// similar to pName, but a shorter string is returned
{
   if (player != nil)
   {
      return [player shortName];
   } // if
   return @"";
} // shortName

- (void)showAt:(float)x yPos:(float)y clPos:(float)clubPos;
// draws the name into the currently lockFocus'ed view at x, y
{
	[[player longName] drawAtPoint:NSMakePoint(x, y) withAttributes:[self longNameAttributes]];
   // if ([player longName]) PSshow([player longName]);
	[[player club] drawAtPoint:NSMakePoint(clubPos, y) withAttributes:[self longNameAttributes]];
	[[partner longName] drawAtPoint:NSMakePoint(x, y - 15.0) withAttributes:[self longNameAttributes]];
	[[partner club] drawAtPoint:NSMakePoint(clubPos, y - 15.0) withAttributes:[self longNameAttributes]];
} // showAt

- (void)drawInMatchTableOf:sender x:(float)x y:(float)y
{
   const float namePos = 15.0;
   const float clubPos = 115.0;
	NSDictionary *attributes=[self shortNameAttributes];

	[[NSString stringWithFormat:@"%ld", [self rankingInSeries:[sender series]]]
		drawAtPoint:NSMakePoint(x, y) withAttributes:attributes];

	[[self longName] drawAtPoint:NSMakePoint(x + namePos, y) withAttributes:attributes];
  	[[self club] drawAtPoint:NSMakePoint(x + clubPos, y) withAttributes:attributes];
} // drawInMatchTableOf

- (void)adjustDayRanking:(float)adjustRanking;
// adjust dayRanking of individuals, only half the difference
{  float old;
   
   old = [player dayRanking];
   [player adjustDayRanking:adjustRanking/2.0];			// half adjust
   [player setDayRanking:(old + [player dayRanking]) / 2.0];	// half valid
   
   old = [partner dayRanking];
   [partner adjustDayRanking:adjustRanking/2.0];		// half adjust
   [partner setDayRanking:(old + [player dayRanking]) / 2.0];	// half valid
} // adjustDayRanking
   
- (void)setPersPriority:(float)aFloat;
// changes the personal priority to add for the player by aFloat/2.0.
{
   if (player != nil)
   {
      [player setPersPriority:aFloat/2.0];
   } // if
   if (partner != nil)
   {
      [partner setPersPriority:aFloat/2.0];
   } // if
} // setPersPriority

- (void)putAsUmpire;
// put both players as umpire
{
   [partner putAsUmpire];
   [player putAsUmpire];
} // putAsUmpire

- (void)removeFromUmpireList;
   // remove both players from the list of umpires
{
   [partner removeFromUmpireList];
   [player removeFromUmpireList];
}

/******************** alternatively only lower priority *******************/

- (void)setReady:(BOOL)flag;
// sets players and partners ready-state to flag
{
   [player setReady:flag];
   [partner setReady:flag];
} // setReady

- (void)setWONotPresentPlayer:(SinglePlayer *)aPlayer;
{
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"WO", @"Tournament", null);
	alert.informativeText = [NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ ist", @"Tournament", null), [aPlayer longName]];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"nicht da", @"Tournament", null)];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"abgemeldet", @"Tournament", null)];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"hier", @"Tournament", null)];
	long ret = [alert synchronousModalSheetForWindow:[NSApp mainWindow]];
	switch(ret) {
      case NSAlertFirstButtonReturn:
         [aPlayer setWO:YES];
         break;
      case NSAlertSecondButtonReturn:
         [aPlayer setPresent:NO];
         break;
      case NSAlertThirdButtonReturn:
         // hier ist nichts zu tun
         break;
	} // switch
}

- (void)setPresent:(BOOL)aFlag;
// set the present state of both players to aFlag, ask when NO
{
   if (aFlag) {
      [player setPresent:YES];
      [partner setPresent:YES];
   } else {
		[self setWONotPresentPlayer:player];
		[self setWONotPresentPlayer:partner];
   } // if
} // setPresent

- (void)setWO:(BOOL)aFlag;
// set the present state of both players to aFlag, ask when YES
{
   if (!aFlag) {
      [player setWO:NO];
      [partner setWO:NO];
   } else {
		[self setWONotPresentPlayer:player];
		[self setWONotPresentPlayer:partner];
   } // if
} // setWO

- (void)addMatch:(id <Playable>)aMatch;
{
   if (![aMatch finished]) {
      [player addMatch:aMatch];		// otherwise append to players
      [partner addMatch:aMatch];	// and to partners List
   }
}

- (void)removeMatch:(id <Playable>)aMatch;
/* in: aMatch: match to remove from openMatches-list
*/
{
   [player removeMatch:aMatch];
   [partner removeMatch:aMatch];
} // removeMatch

- (void)finishMatch:(id <Playable>)aMatch;
/*
 Removes the match from the list if present and readies the player if removed. Especially useful for groups.
 */
{
   [player finishMatch:aMatch];
   [partner finishMatch:aMatch];
}

- (float) seriesPriority:series;
// value is used to set gray-level, should be smaller than NX_LTGRAY
{
   float prio1 = [player seriesPriority:series];
   float prio2 = [partner seriesPriority:series];
   
   if (prio1 < prio2)
   {
      return prio2;
   }
   else
   {
      return prio1;
   } // if
} // seriesPriority

- (long)performWithLongResult:(SEL)aSelector;
{
   NSMethodSignature *signature = [[self class] instanceMethodSignatureForSelector:aSelector];
   NSInvocation *longInvocation = [NSInvocation invocationWithMethodSignature:signature];
   [longInvocation setTarget:self];
   [longInvocation setSelector:aSelector];
   [longInvocation invoke];
   long result;
   [longInvocation getReturnValue:&result];
   
   return result;
} // performWithLongResult

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:player];
	[encoder encodeObject:partner];
	[encoder encodeObject:longName];
	[encoder encodeObject:clubName];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self=[super init];
	player=[decoder decodeObject];
	partner=[decoder decodeObject];
	longName=[decoder decodeObject];
	clubName=[decoder decodeObject];

	return self;
}

- (BOOL)present;
// returns YES if both players are present, NO otherwise
{
   return (([player present]) && ([partner present]));
} // present
      
- (BOOL)wo;
// returns YES if neither player gave walk over, NO otherwise
{
   return (([player wo]) || ([partner wo]));
} // present

- (bool)attendant;
{
	return [player attendant] && [partner attendant];
}

- (NSDictionary*)longNameAttributes;
{
	return [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Times-Roman" size:longNameHeight] forKey:NSFontAttributeName];
}

- (NSDictionary*)shortNameAttributes;
{
	return [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Helvetica" size:shortNameHeight] forKey:NSFontAttributeName];
}

- (id <InspectorControllerProtocol>) inspectorController;
{
	if (_doublePlayerInspector == nil) {
		_doublePlayerInspector=[[DoublePlayerInspector alloc] init];
	}
	[_doublePlayerInspector setDouble:self];

	return _doublePlayerInspector;
}

- (bool)shouldUmpire;
{
   return [player shouldUmpire] || [partner shouldUmpire];
}

- (bool)canContinue;
{		// DoublePlayers may always continue
   return YES;
}

- (long)numberOfDependentMatches;
{
   return [player numberOfDependentMatches] + [partner numberOfDependentMatches];
}

- (bool)hasRealPlayers;
{
	return true;
}

- (NSString *)clickId:(id <drawableSeries>)series;
{
	return [NSString stringWithFormat:@"%@_%ld_%ld", [series seriesName], [player licence], [partner licence]];
}

- (void)appendPlayerXmlTo:(NSMutableString *)text forSeries:(id <drawableSeries>)series;
{
	[text appendFormat:@"   <player type=\"double\" id=\"%@\" >\n", [self clickId:series]];
	[player appendPersonXmlTo:text];
	[partner appendPersonXmlTo:text];
	[text appendString:@"   </player>\n"];
	
}

- (NSString *)rankingListLines:(NSString *)rankStr;
{
	return [NSString stringWithFormat:@"%@%@", [player rankingListLines:rankStr], [partner rankingListLines:@""]];
}
@end
