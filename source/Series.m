/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a single series of a tournament.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 2.1.94, Patru: first written
          3.3.94, Patru: completed doSimpleDraw
	  4.3.94, Patru: doSophDraw started
	  5.3.94, Patru: doSophDraw completed
	  6.3.94, Patru: doGroupDraw
	  8.11.94, Patru: redone doSophDraw, temporarily invalid!
	  9.2.95, Patru: corrected doSophDraw again (better than ever ...)
	  18.2.95, Patru: created subclasses of Series, a bit lighter,
	                  new drawing scheme
	  19.2.95, Patru: allMatchSheets created, for manual tournaments
	  14.7.97, Patru: updated doKODraw for new rules
	  15.7.97, Patru: updated doSophDraw, now simpler
    Bugs: -not very well documented
 *****************************************************************************/

//#import "DBHashTable.h"
#import "Series.h"
#import <PGSQLKit/PGSQLKit.h>
#import "ClubResult.h"
#import "DoublePlayer.h"
#import "SeriesPlayer.h"
#import "Group.h"
#import "GroupPlayer.h"
#import "GroupSeries.h"
#import "Match.h"
#import "MatchBrowser.h"
#import "Player.h"
#import "PlaySeries.h"
#import "PlayerController.h"
#import "SeriesInspector.h"
#import "SmallTextController.h"
#import "SeriesController.h"
#import "SeriesDataController.h"
#import "TournamentController.h"
#import "TournamentView.h"
#import <ctype.h>
#import "Tournament-Swift.h"

const struct SerFieldsStruct SerFields={
   .SeriesName    =@"SeriesName",
   .FullName      =@"FullName",
   .SetPlayers    =@"SetPlayers",
   .Type          =@"Type",
   .StartTime     =@"StartTime",
   .Grouping      =@"Grouping",
   .MinRanking    =@"MinRanking",
   .MaxRanking    =@"MaxRanking",
   .Promotees     =@"Promotees",
   .BestOfSeven   =@"BestOfSeven",
   .Age           =@"Age",
   .SerCoefficient=@"SerCoefficient",
   .Sex           =@"Sex",
   .SmallFinal    =@"SmallFinal",
   .TournamentID  =@"TournamentID",
   .PriceAdult    =@"PriceAdult",
   .PriceYoung    =@"PriceYoung"
};

void numberAllMatches(NSMutableArray *matches)
/* in: matches: a list of matches to be numbered, there may be more
  out: the list numbered
  wid: recursively finds matches, numbers them and then numbers given matches
*/
{
   long i, max=[matches count];
   NSMutableArray *newMatches = [NSMutableArray arrayWithCapacity:max*2];

   for(i=0; i<max; i++) {
      Match *m = (Match *)[matches objectAtIndex:i];
      Match *u = [m upperMatch];
      Match *l = [m lowerMatch];

      if (([m upperIsWinner]) && ([u upperMatch] != nil) && ([u lowerMatch] != nil)) {
         [newMatches addObject:u];     // do not propagate numbering through loser matches!
      }
      if (([m lowerIsWinner]) && ([l upperMatch] != nil) && ([l lowerMatch] != nil)) {
         [newMatches addObject:l];
      }
   }

   if ([newMatches count] != 0) {
      numberAllMatches(newMatches);
   }

   for(i=0; i<max; i++) {
      [TournamentDelegate.shared number:[matches objectAtIndex:i]];
   }

   [newMatches removeAllObjects];			// cleanup

} // numberAllMatches

NSMutableArray * allMatchesPreceedingTour(NSMutableArray *matches) {
   long i, max=[matches count];
   NSMutableArray *newMatches = [[NSMutableArray alloc] initWithCapacity:max*2];
   
   for(i=0; i<max; i++) {
      Match *match = (Match *)[matches objectAtIndex:i];
      Match *u = [match upperMatch];
      Match *l = [match lowerMatch];
      
      if (([u upperMatch] != nil) && ([u lowerMatch] != nil))
         [newMatches addObject:u];
      if (([l upperMatch] != nil) && ([l lowerMatch] != nil))
         [newMatches addObject:l];
   }
   
   return newMatches;
}

void printAllMatches(NSMutableArray *matches)
/* in: matches: a list of matches to be printed, there may be more
  out: the printed matchSheets
  wid: finds matches and prints them
*/
{
   NSMutableArray *tours = [NSMutableArray array];
   [tours addObject:matches];
   NSMutableArray *tourMatches = matches;
   
   while ([tourMatches count] > 0) {
      tourMatches = allMatchesPreceedingTour(tourMatches);
      [tours insertObject:tourMatches atIndex:0];
   }
   
   long i, max=[tours count];
   NSMutableArray *allMatches = [NSMutableArray array];
   for (i=0; i<max; i++) {
      [allMatches addObjectsFromArray:[tours objectAtIndex:i]];
   }

   max = [allMatches count];
   for(i=0; i<max; i++) {
      Match *match = [allMatches objectAtIndex:i];
      if (![match finished]) {
         [match print:nil];
      }
   }
} // printAllMatches

BOOL onlyRaisePlayers(NSMutableArray *players)
/* in: players: a list of players
 what: checks if all the players in the list are raisePlayers
*/
{  /*int i = 0, max = [players count];
   
   while((i<max)
         && ([[[players objectAtIndex:i] player] isKindOfClassNamed:"RaisePlayer"]))
   {
      i++;
   } // while
   
   return i == max;
   */
   return NO;
} // onlyRaisePlayers

static SeriesInspector *_seriesInspector;

static NSString * allFields = nil;
@implementation Series
/* Controls a series in the tournament, especially the drawing process
   for the table and the drawing of the table in PostScript */

+ (instancetype)fromRecord:(PGSQLRecord *)record;
{
   Series *aSeries=[[Series alloc] initFromRecord:record];

   return aSeries;
}

static NSCharacterSet *uoSet=nil;

+ (NSCharacterSet *)uoSet;
{
   if (uoSet == nil) {
      uoSet = [NSCharacterSet characterSetWithCharactersInString:@"UO"];
   }
   return uoSet;
}

+ (NSString *) allFields;
{
   if (allFields == nil) {
      NSArray *fields = [NSArray arrayWithObjects:SerFields.SeriesName, SerFields.FullName, SerFields.StartTime, SerFields.Grouping, SerFields.MinRanking, SerFields.MaxRanking, SerFields.Promotees, SerFields.Type, SerFields.BestOfSeven, SerFields.Age, SerFields.SerCoefficient, SerFields.SetPlayers, SerFields.Sex, SerFields.SmallFinal, SerFields.PriceAdult, SerFields.PriceYoung, nil];
      allFields = [fields componentsJoinedByString:@", "];
   }
   return allFields;
}

- (id <InspectorControllerProtocol>) inspectorController;
{
   if (_seriesInspector == nil) {
      _seriesInspector=[[SeriesInspector alloc] init];
   }
   [_seriesInspector setSeries:self];
   
   return _seriesInspector;
}

- init
{
   self = [super init];
   seriesName = @"";
   fullName = @"";
   grouping = @"";
   positions = [[NSMutableArray alloc] init];
   players = [[NSMutableArray alloc] init];
   matchTable = nil;
   setPlayers = 0;
   priority = 1.0;
   RankSel = @selector(ranking);
   started = NO;
   minRound = 1024;
   maxRanking = 0;
   maxDayRanking = 0;
   serCoefficient = 3.0;	// later this will be overwritten from the database
   alreadyDrawn = NO;
   tablePages = [[NSMutableArray alloc] init];
   master = nil;
   _isNew=YES;
   _isEdited=NO;
   drawingErrors = [NSMutableArray array];
   return self;
}

- (instancetype)initFromRecord:(PGSQLRecord *)record;
{
   self=[super init];
   seriesName=[[record fieldByName:SerFields.SeriesName] asString];
   fullName=[[record fieldByName:SerFields.FullName] asString];
   startTime=[[record fieldByName:SerFields.StartTime] asString];
   grouping=[[record fieldByName:SerFields.Grouping] asString];
   minRanking=[[record fieldByName:SerFields.MinRanking] asLong];
   maxRanking=[[record fieldByName:SerFields.MaxRanking] asLong];
   promotees=[[record fieldByName:SerFields.Promotees] asLong];
   type=[[record fieldByName:SerFields.Type] asString];
   sMode=[type characterAtIndex:0];
   bestOfSeven=[[record fieldByName:SerFields.BestOfSeven] asLong];
   age=[[record fieldByName:SerFields.Age] asString];
   [self setCoefficient:[[[record fieldByName:SerFields.SerCoefficient] asNumber] floatValue]];
   setPlayers=[[record fieldByName:SerFields.SetPlayers] asLong];
   sex=[[record fieldByName:SerFields.Sex] asString];
   priceAdult = [[[record fieldByName:SerFields.PriceAdult] asNumber] doubleValue];
   priceYoung = [[[record fieldByName:SerFields.PriceYoung] asNumber] doubleValue];
   NSString *smallFinal = [[record fieldByName:SerFields.SmallFinal] asString];
   // Shriek: [[record fieldByName:SerFields.SmallFinal] asBoolean] does not work here! TODO FixMe
   _smallFinal=[@"1" isEqualToString:smallFinal];
   _isNew=NO;
   _isEdited=NO;
   positions = [[NSMutableArray alloc] init];
   players = [[NSMutableArray alloc] init];
   alreadyDrawn = NO;
   tablePages = [[NSMutableArray alloc] init];
   master = nil;
   if ([self isWomanSeries]) {
      RankSel = @selector(womanRanking);
   } else {
      RankSel = @selector(ranking);
   }
   matchTable = nil;
   minRound = 1024;
   maxDayRanking = 0;
   drawingErrors = [NSMutableArray array];

   return self;
}

- (BOOL) isEqual:anObject;
{
   if ([anObject respondsToSelector:@selector(seriesName)])
      return ([anObject seriesName] == seriesName);
   else
      return NO;
} // isEqual

- (void)encodeWithCoder:(NSCoder *)encoder
{
   [encoder encodeObject:seriesName];
   [encoder encodeObject:fullName];
   [encoder encodeObject:positions];
   [encoder encodeObject:players];
   [encoder encodeObject:matchTable];
   [encoder encodeValueOfObjCType:@encode(int) at:&setPlayers];
   [encoder encodeValueOfObjCType:@encode(char) at:&sMode];
   [encoder encodeValueOfObjCType:@encode(int) at:&bestOfSeven];
   [encoder encodeObject:startTime];
   [encoder encodeObject:sex];
   [encoder encodeValueOfObjCType:@encode(SEL) at:&RankSel];
   [encoder encodeValueOfObjCType:@encode(BOOL) at:&started];
   [encoder encodeValueOfObjCType:@encode(int) at:&minRound];
   [encoder encodeValueOfObjCType:@encode(int) at:&minRanking];
   [encoder encodeValueOfObjCType:@encode(int) at:&maxRanking];
   [encoder encodeValueOfObjCType:@encode(int) at:&promotees];
   [encoder encodeObject:grouping];
   [encoder encodeValueOfObjCType:@encode(float) at:&maxDayRanking];
   [encoder encodeValueOfObjCType:@encode(BOOL) at:&alreadyDrawn];
   [encoder encodeValueOfObjCType:@encode(float) at:&serCoefficient];
   [encoder encodeValueOfObjCType:@encode(BOOL) at:&_smallFinal];
   [encoder encodeObject:smallFinalTable];
   [encoder encodeObject:age];
   [encoder encodeValueOfObjCType:@encode(double) at:&priceAdult];
   [encoder encodeValueOfObjCType:@encode(double) at:&priceYoung];
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self=[super init];
   seriesName=[decoder decodeObject];
   fullName=[decoder decodeObject];
   positions=[decoder decodeObject];
   players=[decoder decodeObject];
   matchTable=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(int) at:&setPlayers];
   [decoder decodeValueOfObjCType:@encode(char) at:&sMode];
   [decoder decodeValueOfObjCType:@encode(int) at:&bestOfSeven];
   startTime=[decoder decodeObject];
   sex=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(SEL) at:&RankSel];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&started];
   [decoder decodeValueOfObjCType:@encode(int) at:&minRound];
   [decoder decodeValueOfObjCType:@encode(int) at:&minRanking];
   [decoder decodeValueOfObjCType:@encode(int) at:&maxRanking];
   NSInteger seriesVersion = [decoder versionForClassName:@"Series"];
   if (seriesVersion >= 2) {
      [decoder decodeValueOfObjCType:@encode(int) at:&promotees];
   } else {
      promotees=2;
   }
   if (seriesVersion >= 3) {
      grouping = [decoder decodeObject];
   } else {
      grouping=@"";
   }
   [decoder decodeValueOfObjCType:@encode(float) at:&maxDayRanking];
   [decoder decodeValueOfObjCType:@encode(BOOL) at:&alreadyDrawn];
   [decoder decodeValueOfObjCType:@encode(float) at:&serCoefficient];
   tablePages = [[NSMutableArray alloc] init];
   if (seriesVersion >= 4) {
      [decoder decodeValueOfObjCType:@encode(BOOL) at:&_smallFinal];
   } else {
      _smallFinal=NO;
   }
   if (seriesVersion >= 5) {
      smallFinalTable=[decoder decodeObject];
      if ((smallFinalTable != nil) && ([seriesName characterAtIndex:0] == 'O')) {
         smallFinalTable = nil;
         _smallFinal=NO;
      }
   }
   if (seriesVersion >= 6) {
      age=[decoder decodeObject];
   }
   if (seriesVersion >= 7) {
      [decoder decodeValueOfObjCType:@encode(double) at:&priceAdult];
      [decoder decodeValueOfObjCType:@encode(double) at:&priceYoung];
   } else {
      priceAdult = 8.0;
      priceYoung = 5.0;
   }

   return self;
}

- (BOOL) appliesFor:(SinglePlayer *)player;
{
   int relevantRanking=0;

   if ([sex length] > 0) {
      if (![sex isEqualToString:[player sex]]) {
         return NO;
      }
   }

   if ([age length] > 0) {
      if (![age isEqualToString:[player category]]) {
         return NO;
      }
   }

   relevantRanking=(int)[player ranking];

   if (([self isWomanSeries])
       || ([type rangeOfString:@"x" options:NSCaseInsensitiveSearch].location != NSNotFound)) {
      if ([[player sex] isEqualToString:@"W"]) {
         relevantRanking=(int)[player womanRanking];
      }
   }

   if ((relevantRanking < minRanking) || (relevantRanking > maxRanking)) {
      return NO;
   }

   return YES;
}

-(BOOL) isWomanSeries;
{
   return [sex isEqualToString:@"W"];
}

- (long) minRanking;
{
   return minRanking;
}

- (long) maxRanking;
{
   return maxRanking;
}

- (long) numberOfMatches;
{
   NSArray *mtchTables = [self matchTables];
   long i, max=[mtchTables count], sum=0;
   
   for (i=0; i<max; i++) {
      sum = sum + [[mtchTables objectAtIndex:i] pMatches];
   }
   return sum;
}

- (long) numberOfUnplayedMatches;
{
   return 12;
}
- (long) numberOfUnplayedGroups;
{
   return 0;
}

- (long) furthestRound;
{
   return minRound;
}

- (long) sternmostRound;
{
   NSArray *mtchTables = [self matchTables];
   long i, max=[mtchTables count], sternmost=0;
   
   for (i=0; i<max; i++) {
      long tableSternmost = [[mtchTables objectAtIndex:i] sternmostRoundUnplayed];
      if (tableSternmost > sternmost) {
         sternmost = tableSternmost;
      }
   }
   
   return sternmost;
}


- (void)setSeriesName:(NSString *)newName
{
   seriesName = newName;
} // setSeriesName

- (void)setFullName:(NSString *)newName
{
   fullName = newName;
} // setFullName

- (long)numberOfGroupsDrawn;
{
   return 0L;
}

- (void)setTourPriority:(float)newPriority;
{
   priority = newPriority;
} // setTourPriority

- (void)setSMode:(char)aChar;
{
   sMode = aChar;
}

- (void)setBestOfSeven:(long)aInt;
{
   bestOfSeven = aInt;
}

- (void)setMatchTable:(Match *)aMatch;
{
   if (matchTable == nil) {
      matchTable = aMatch;
      alreadyDrawn = YES;
   } else if (aMatch != nil) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
      alert.informativeText = NSLocalizedStringFromTable(@"Die Serie hat bereits ein Tableau", @"Tournament", nil);
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
      [alert beginSheetModalForWindow:[TournamentDelegate.shared.seriesController seriesWindow] completionHandler:nil];
   } else {
      matchTable = nil;
   }
} // setMatchTable

- (Match *)smallFinalTable;
{
   return smallFinalTable;
}

- (NSString *)finalString:(Match *) match;
{
   if (match != [self smallFinalTable]) {
      return NSLocalizedStringFromTable(@"Final", @"Matchblatt", @"Final auf Matchblatt");
   } else {
      return NSLocalizedStringFromTable(@"kleiner Final", @"Matchblatt", @"kleiner Final auf Matchblatt");
   }	
}

- (long) smallFinalPage;
{
   return [tablePages count];
}

- (void)checkMinRound:(long)aInt;
{
   if ((aInt > 0) && (aInt < minRound))
   {
      minRound = aInt;
   } // if
} // minRound

- (void)checkMaxRanking:(id <Player>)pl;
{
   if ([pl dayRanking] > maxDayRanking)
   {
      maxDayRanking = [pl dayRanking];
   } // if
} // checkMaxRanking

- (void) removePlayer:(id)pl;
{  long i=0, max=[players count];

   while((i<max) && ([(SeriesPlayer *)[players objectAtIndex:i] player] != pl))
   {
      i++;
   } // while
   if (i<max)
   {
      [players removeObjectAtIndex:i];
   } // if
} // removePlayer

- (NSString *)seriesName
{
   return seriesName;
} // seriesName

- (NSString *)fullName
{
   return fullName;
} // fullName

- (NSString *)fullNameNoSpace;
{
   NSMutableString *noSpace = [NSMutableString stringWithString:fullName];
   [noSpace replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range: NSMakeRange(0, [noSpace length])];
   [noSpace replaceOccurrencesOfString:@"/" withString:@"" options:NSLiteralSearch range: NSMakeRange(0, [noSpace length])];
   [noSpace replaceOccurrencesOfString:@"ä" withString:@"ae" options:NSLiteralSearch range: NSMakeRange(0, [noSpace length])];
   [noSpace replaceOccurrencesOfString:@"ö" withString:@"oe" options:NSLiteralSearch range: NSMakeRange(0, [noSpace length])];
   [noSpace replaceOccurrencesOfString:@"ü" withString:@"ue" options:NSLiteralSearch range: NSMakeRange(0, [noSpace length])];
   return noSpace;
}

//* used to represent the series in a payment view
- (NSString *) paymentName;
{
   if ([self isAgeSeries]) {
      if ([seriesName hasPrefix:@"W"]) {
         return [NSString stringWithFormat:@"Da %@", [seriesName substringFromIndex:1]];
      } else if ([seriesName hasPrefix:@"M"]) {
         return [seriesName substringFromIndex:1];
      }
      return seriesName;
   }
   return [seriesName substringFromIndex:1];
}

// This is a somewhat terrible hunch to determine what to put to describing a double series since they usually
// span two ranking groups (e.g. AB for the top double series)
- (NSString *) doubleCategoryString;
{
   unichar lastChar = [seriesName characterAtIndex:[seriesName length] - 1];
   if ([self isAgeSeries])  {
      return [seriesName substringFromIndex:[seriesName length] - 3];
   } else if (lastChar < 'D') {
      return [NSString stringWithFormat: @"%c%c", lastChar, lastChar+1];
   } else {
      return [NSString stringWithFormat: @"%c", lastChar];
   }
}

- (Boolean) isAgeSeries;
{
   return age != nil
         && age.length > 0;
}

- (Match *)matchTable
{
   return matchTable;
} // matchTable

- (float) tourPriority;
{
   return priority;
} // tourPriority

- (char) sMode;
{
   return sMode;
} // sMode

- (long) bestOfSeven;
{
   return bestOfSeven;
} // bestOfSeven

- (NSString *)sex;
{
   return sex;
} // sex

- setSex:(NSString *)aString;
{
   sex = aString;
   
   return self;
} // setSex

- (NSString *)grouping;
{
   return grouping;
}

- (void)setGrouping:(NSString *)aString;
{
   grouping = aString;
}

- (SEL)rankSel;
// return the selector which gives the correct ranking for this series
{
   return RankSel;
} // rankSek

- (void)setRankSel:(SEL) aSelector;
{
   RankSel = aSelector;
}

- (long)minRound;
{
   if (minRound > 0) {		// may occur during read
      return minRound;
   } else {
      return 1024L;
   } // if
} // minRound

- (NSString *)classificationLetter:(long)classification;
{
   if (classification <= 5) {
      return @"D";
   } else if (classification <= 10) {
      return @"C";
   } else if (classification <= 15) {
      return @"B";
   } else if (classification <= 20) {
      return @"A";
   } else {
      return @"Z";
   }
}

- (NSString *)clickTTMin;
{
   return [NSString stringWithFormat:@"%@%ld", [self classificationLetter:minRanking], minRanking];
}

- (NSString *)clickTTMax;
{
   return [NSString stringWithFormat:@"%@%ld", [self classificationLetter:maxRanking], maxRanking];
}

- (long)promotees;
{
   return promotees;
}

- (long)maxRankingPresent;
{
   long i, max = [players count], maxRankingPresent = 0;
   
   for(i=0; i<max; i++) {
      id pl = [players objectAtIndex:i];
   
      if ([[pl player] rankingInSeries:self] > maxRankingPresent)
      {
            maxRankingPresent = [[pl player] rankingInSeries:self];
      } // if
   } // for

   return maxRankingPresent;
} // maxRanking

- (float)maxDayRanking;
{
   return maxDayRanking;
} // maxDayRanking

- (NSString *)startTime;
{
   return startTime;
} // startTime

- (void)setStartTime:(NSString *)time;
{
   startTime = time;
}

- addSingle:(SinglePlayer *)pl;
// add the player pl to the singles list in sorted order (only for doubles)
// dummy for singles, but should be there (i think)
{
   return self;
} // addSingle

- (void)addPlayer:(SinglePlayer *)pl set:(long)setNum partner:(SinglePlayer *) partnerPlayer;
// adds a player to the list of players in sorted order,
// if setNum is present it takes precedent
{  id serPl = nil;
   long i = [players count];
  
   serPl = [[SeriesPlayer alloc] initPlayer:pl setNumber:setNum];
   if (serPl != nil) {
      while((i>0) && ([serPl isStronger:[players objectAtIndex:i-1] sender:self])) {
         i--;
      } // while
      
      [players insertObject:serPl atIndex:i];
   } // if
} // addPlayer

- addSeriesPlayer:(SeriesPlayer *)aSeriesPlayer
// adds initialized series player to the list of players in sorted order,
{  long i = [players count];
  
   while((i>0) && ([aSeriesPlayer isStronger:[players objectAtIndex:i-1] sender:self])) {
      i--;
   } // while
      
   [players insertObject:aSeriesPlayer atIndex:i];
   return self;
}

- (Series *)loadPlayersFromDatabase;
// load the series data from the database
{
//   PGSQLConnection *database=[TournamentDelegate.shared database];      used to require a second connection, lets see if this is necessary here too
   TournamentDelegate *tDel = TournamentDelegate.shared;
   NSWindow *seriesWindow = [tDel.seriesController seriesWindow];
   PGSQLConnection *database=tDel.database;
   SinglePlayer *player=nil, *partner=nil;
   NSString *playSeriesSQL = [NSString stringWithFormat:@"SELECT %@ FROM PlaySeries WHERE Series='%@' AND TournamentID='%@'", [PlaySeries allFields], seriesName, TournamentDelegate.shared.preferences.tournamentId];
   
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:playSeriesSQL];
   PGSQLRecord *rec = [rs moveFirst];
   
   while (rec != nil) {
      long licence = [[rec fieldByName:PSFields.Pass] asLong];
      player = [[TournamentDelegate.shared playerController] playerWithLicence:licence];
      NSString *fehler = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
      NSString *ok = NSLocalizedStringFromTable(@"Ok", @"Tournament", nil);
      if (player != nil) {
         long partnerLicence = [[rec fieldByName:PSFields.PartnerPass] asLong];
         long setNumber = [[rec fieldByName:PSFields.SetNumber] asLong];
         if (partnerLicence != 0) {
            partner = [[TournamentDelegate.shared playerController]
                       playerWithLicence:partnerLicence];
            if (partner != nil) {
               [self addPlayer:player set:setNumber partner:partner];
            } else {
               NSAlert *alert = [NSAlert new];
               alert.messageText = fehler;
               NSString *info = [NSString stringWithFormat: NSLocalizedStringFromTable(@"Partner %d nicht gefunden\nSpieler %d", @"Tournament", nil), partnerLicence, licence];
               alert.informativeText = info;
               [drawingErrors addObject:info];
               [alert addButtonWithTitle:ok];
               [alert beginSheetModalForWindow:seriesWindow completionHandler:nil];
            }
         } else {
            [self addPlayer:player set:setNumber partner:nil];
         }
      } else {
         [drawingErrors addObject:[NSString stringWithFormat:NSLocalizedStringFromTable(@"Lizenznummer %d nicht gefunden", @"Tournament", nil), licence]];
      }
      rec = [rs moveNext];
   }
   return self;
}

- (long)countPlayers;
{
   return [matchTable pMatches] + 1;
} // countPlayers

- (float)coefficient;
{
   return serCoefficient;
} // coefficient

- setCoefficient:(float)aFloat;
{
   serCoefficient = aFloat;
   
   return self;
} // setCoefficient

- (long)setPlayers;
{
   return setPlayers;
} // setPlayers

- setSetPlayers:(long)aInt;
{
   setPlayers = aInt;
   
   return self;
} // setSetPlayers

- (double) priceAdult;
{
   return priceAdult;
}

- (void) setPriceAdult:(double)aDouble;
{
   priceAdult = aDouble;
}

- (double) priceYoung;
{
   return priceYoung;
}

- (void) setPriceYoung:(double)aDouble;
{
   priceYoung = aDouble;
}

- (long)numSetPlayers
{
   long i, max = [players count], cnt = 0;
   
   for(i=0; i<max; i++)
   {
      id pl = [players objectAtIndex:i];
      
      if (([pl setNumber] != 0)
          || ([[pl player] rankingInSeries:self] >= setPlayers))
      {
         cnt++;
      } // if
   } // for
   
   return cnt;
} // numSetPlayers

- (void)numberMatchesInTable:(Match *)finalMatch;
{
   NSMutableArray *matches = [NSMutableArray arrayWithCapacity:64];
   
   [matches addObject:finalMatch];		// insert match to start from
   numberAllMatches(matches);   
}

- (long)numberKoMatches;
   // ret: number of matches numbered
   // wid: numbers all the matches in the table of the series columnwise
{
   long lastMatchBeforeMe = [TournamentDelegate.shared lastNumberedMatch];

   NSArray *tables = [self matchTables];
   long i, max=[tables count];
   
   for (i=0; i<max; i++) {
      [self numberMatchesInTable:[tables objectAtIndex:i]];
   }

   return [TournamentDelegate.shared lastNumberedMatch] - lastMatchBeforeMe;
   
} // numberKoMatches

-(void)positionExistiertNicht:(long)pos;
{
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
   alert.informativeText =  [NSString stringWithFormat: NSLocalizedStringFromTable(@"Position Nummer %d existiert nicht", @"Tournament", nil), pos];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ok", @"Tournament", nil)];
   [alert beginSheetModalForWindow:[TournamentDelegate.shared.seriesController seriesWindow] completionHandler:nil];
}

- (void)switchPos:(long)pos1 with:(long)pos2;
// switches to positions in the matchTable, only first round
{
   id p1 = nil, p2 = nil;
   long i, max = [positions count];
   
   i = 0;
   while ((i<max) && (p1 == nil))
   {
      if ([[positions objectAtIndex:i] tNumber] == pos1) {
         p1 = [positions objectAtIndex:i];
      } // if
      i++;
   } // while
   if (p1 == nil) {
      [self positionExistiertNicht:pos1];
   } // if
   
   i = 0;
   while ((i<max) && (p2 == nil)) {
      if ([[positions objectAtIndex:i] tNumber] == pos2) {
         p2 = [positions objectAtIndex:i];
      } // if
      i++;
   } // while
   if (p2 == nil) {
      [self positionExistiertNicht:pos2];
   }
   
   if (((p1 != nil) && ([p1 upperMatch] == nil) && ([p1 lowerMatch] == nil))
       &&((p2 != nil) && ([p2 upperMatch] == nil) && ([p2 lowerMatch] == nil)))
   {
      id temp = [p1 winner];
      
      [[p1 winner] removeMatch:[p1 nextMatch]];
      [[p2 winner] removeMatch:[p2 nextMatch]];
      
      [p1 sWinner:[p2 winner]];
      [p2 sWinner:temp];
      
      [[p1 winner] addMatch:[p1 nextMatch]];
      [[p2 winner] addMatch:[p2 nextMatch]];
   } // if
} // switchPos

- (long)maxPositionNumber;
{
   long max = 0;
   for (Match* pos in positions) {
      if ([pos tNumber] > max) {
         max = [pos tNumber];
      }
   }
   return max;
}

/***************************************************************************
                        helping functions for the draw
 ***************************************************************************/
#define MAXTAB 1024

long meet(long i, long j)
/* in: i, j numbers of places which will meet
  ret: the round in a matchTable of MAXTAB players where i and j meet
 what: if the matchTable is not initialized it is initialized, otherwise just
       compute the meeting point using the matchTable value and bitwise xor
*/
{
   static int maxtab[MAXTAB];
   int k, r;
   
   if (maxtab[1] != 1023)
   {
      int totround = 1;		// the round with only 1 player is inited
      
      maxtab[0] = 0;
      while (totround < MAXTAB) // init the array up to MAXTAB
      {
         for(k=totround/2; k>=0; k--)
	 {
	    if (maxtab[k]%2 == 0)
	    {
	       maxtab[2*k] = maxtab[k];
	       maxtab[2*k + 1] = totround - maxtab[k];
	    } 
	    else
	    {
	       maxtab[2*k] = totround-maxtab[k];
	       maxtab[2*k + 1] = maxtab[k];
	    } // if
	 } // for
	 totround = 2*totround + 1;	// should be 2^k-1
      } // while
   } // if
   
   r = maxtab[i-1]^maxtab[j-1];		// xor
   k = 0;				// the round to meet is 0
   while (r>0)				// meet in the k-th round ?
   {
      k++;				// obviously not, next round
      r = r/2;
   } // while
   return k;				// in the k-th round they could meet
} // meet

long meetClub(long num, id <Player> pl, NSMutableArray *club, NSMutableDictionary *tableNum)
/* in: num; a position in the matchTable where a player should be placed
        pl; player to be placed (necessary for group players)
       club; list of players of the same club as the player in question
       tableNum; NSMutableDictionary with player licenceNubers as key and their
					  position in the current matchTable as value
  ret: the first round in which a player on place 'num' meets a player from
       the list 'club' or 11 if the list is empty
 what: tries to meet all the players in 'club' and computes the minimum
*/
{
   long i, aMeet, max=[club count];
	NSNumber *aNum;
   long minMeet = 10;		// ultimate round to meet a player from 'club'
   
   for(i=0; i<max; i++)
   {
      aNum = [tableNum objectForKey:[[club objectAtIndex:i] licenceNumber]];
      
      if ([aNum longValue] != num)
      {
         aMeet = meet(num, [aNum longValue]);
         if (aMeet < minMeet)
         {
            minMeet = aMeet;
         } // if
      } // if
   } // for
   
   aNum = [NSNumber numberWithLong:0];
   // for groups also check other player (players in the future?)
   if ([pl isKindOfClass:[GroupPlayer class]])
   {
      Group *group = (Group *)[(GroupPlayer *)pl group];
      if ([[group series] promotees] > 1) {
         NSArray *pos = [[(GroupPlayer *)pl group] positions];
         
         if (pl == [pos objectAtIndex:0]) {
            aNum = [tableNum objectForKey:[[pos objectAtIndex:1] licenceNumber]];
         } else if (pl == [pos objectAtIndex:1]) {
            aNum = [tableNum objectForKey:[[pos objectAtIndex:0] licenceNumber]];
         } // if
         
         if ([aNum longValue] != 0) {
            aMeet = meet(num, [aNum longValue]) - 3;	// same group worse than same club
            if (aMeet < minMeet) {
               minMeet = aMeet;
            } // if
         } // if
      }
   } // if
      
   return minMeet;
} // meetClub

BOOL switchPlayers(id<Player> player1, id<Player> player2, NSMutableDictionary *clubs, NSMutableDictionary *tableNum, int margin)
/* in: pl1, pl2; players who might be switched
       clubs; NSMutableDictionary with the name of a club as key and a list of players
              from the same club as the value
       tableNum; NSMutableDictionary with player licence numbers as key and their
					  position in the current matchTable as value
       margin; a value which indicates how probable it should be for a
               change to occur if it makes the matchTable worse. A value of
	       0 indicates such a change is impossible. 
	       Should not be more than 10.
  out: YES if players where switched, NO otherwise
 what: checks when both players meet the next player from their club and
       switches them if the matchTable can be improved
*/
{
   NSNumber *pl1=[player1 licenceNumber];
   NSNumber *pl2=[player2 licenceNumber];
   NSNumber *pos1 = [tableNum objectForKey:pl1];
   NSNumber *pos2 = [tableNum objectForKey:pl2];
   id cl1 = [clubs objectForKey:[player1 drawClub]];
   id cl2 = [clubs objectForKey:[player2 drawClub]];
   long min11 = meetClub([pos1 intValue], player1, cl1, tableNum);
   long min22 = meetClub([pos2 intValue], player2, cl2, tableNum);
   long min12 = meetClub([pos1 intValue], player2, cl2, tableNum);
   long min21 = meetClub([pos2 intValue], player1, cl1, tableNum);
   long minbefore = min11 < min22 ? min11 : min22;
   long minafter  = min12 < min21 ? min12 : min21;
   long localmargin = margin * (10 + minafter - minbefore);
   
   if (((min11 < min12) && (min22 < min21))		// improve both
      || ((min12 + min21 - min11 - min22 >= 0)
           // min meeting sum is larger after (later meets)
        && (minbefore < minafter))			// improve minimum
      || ((min12 + min21 - min11 - min22 > 0)		// improve worst
        && (minbefore == minafter))			// but min not worse
      || (arc4random_uniform(100) < localmargin))			// otherwise random
   {
      [tableNum setObject:pos2 forKey:pl1];	// perform the switch
      [tableNum setObject:pos1 forKey:pl2];
      return YES;
   }
   else
   {
      return NO;
   } // if
} // switchPlayers

void twoOpt(NSMutableArray *players, NSMutableDictionary *clubs, NSMutableDictionary *tableNum)
{
   BOOL switched = YES;		// not done yet, but assume
   long i, j, max = [players count];
   int margin = 4;		// margin for switches (change later)
   
   while((margin > 0) || switched)
   {
      switched = NO;
      for(i=0; i < max; i++)
      {
         for(j=i+1; j < max; j++) {
            if(switchPlayers([players objectAtIndex:i], [players objectAtIndex:j],
                             clubs, tableNum, margin))
            {
               switched = YES;
            } // if
         } // for
      } // for
      if (margin > 0) margin--;
   } // while
} // twoOpt

- doKODraw;
/* does the draw procedure on an initialized table
   updated for the new drawing rules
*/
{
   long i, lmax;
   NSNumber *tnum=nil;
   NSNumber *currentNumber=nil;
   long current = 0;	// current player in the list
   long curpos  = 0;	// current position to set
   NSMutableDictionary *tableNum = [NSMutableDictionary dictionaryWithCapacity:100];
   NSMutableDictionary *placePos = [NSMutableDictionary dictionaryWithCapacity:100];
   NSMutableDictionary *clubs = [NSMutableDictionary dictionaryWithCapacity:100];
   NSMutableArray *class = [NSMutableArray array];	// players with the same ranking
   long maxClass = 1;		// first class just first player
   long max = [players count];

   while (current < max) {
      while ((current < max)
             && ([[positions objectAtIndex:current] tNumber] <= maxClass)) {
             			// compute next class
         id pl = [[players objectAtIndex:current] player];
         NSMutableArray *club = [clubs objectForKey:[pl drawClub]];

         if (club == nil) {	// new club for collisions
            club = [NSMutableArray array];
            [clubs setObject:club forKey:[pl drawClub]];
         } // if
         [class addObject:pl];
         [club addObject:pl];
         tnum = [NSNumber numberWithLong:[[positions objectAtIndex:current] tNumber]];
         currentNumber=[NSNumber numberWithLong:current];
         [tableNum setObject:tnum forKey:[pl licenceNumber]];
         [placePos setObject:currentNumber forKey:tnum];
         current++;
      } // while

      if (toupper(sMode) != 'O') {
         twoOpt(class, clubs, tableNum);	// optimally drawn at random
      }
      lmax = [class count];
      for(i=0; i<lmax; i++) {
         tnum = [tableNum objectForKey:[[class objectAtIndex:i] licenceNumber]];
         [[positions objectAtIndex:[[placePos objectForKey:tnum] intValue]]
                                setWinner:[class objectAtIndex:i]];
         curpos++;
      } // for
      [class removeAllObjects];
      maxClass = 2*maxClass;		// next class up to double
   } // while
   [tableNum removeAllObjects];
   [placePos removeAllObjects];
   [clubs removeAllObjects];
   [class removeAllObjects];

   return self;
} // doKODraw

- (void)bucketSortPositions:(NSMutableArray *)sortPos;
{
   int i;
   id __strong *pos;
   long max = [sortPos count];
   pos = (id __strong *)calloc(max, sizeof(id));

   for(i=0; i<max; i++)			// bucketsort positions
   {
      id aPos = [sortPos objectAtIndex:i];
      pos[[aPos tNumber]-1] = aPos;
   } // for
   
   [sortPos removeAllObjects];
   for(i=0; i<max; i++)
   {
      [sortPos addObject:pos[i]];
      pos[i]=nil;    // this is to please ARC ..., one of the few instances that were easier before
   } // for
   free(pos);
}

- (BOOL)doSimpleDraw;
/* does the draw for the whole series from the players in the list.
   Simple version for an ordinary ko. series
*/
{
   matchTable = [[Match alloc] initUpTo:[players count] current:1 total:1 next:nil
                          series:self posList:positions];
   [self bucketSortPositions:positions];
   [self doKODraw];
   
   return YES;
} // doSimpleDraw

long makeMatch(Match *pos, NSMutableArray *positions)
/* in: pos: a position to issue a new Match in a series
       positions; a list where the new positions should go
  ret: the number of the newly created position in the matchTable
 what: initializes positions for lower and upper of a match at position pos
       and appends the newly created positions to the list of positions.
*/
{
   Match *next = [pos nextMatch];
   long high = [[next upperMatch] tNumber] + [[next lowerMatch] tNumber];
   Match *up = [[Match alloc] init];
   Match *low = [[Match alloc] init];
   
   if (next == nil)
   {
      high = 2;
   } // if
   [up  setNext:pos];
   [low setNext:pos];
   [up  setSeries:[pos series]];
   [low setSeries:[pos series]];
   if ([pos tNumber] %2 == 0) {		// propagates position downwards
      [low setTNumber:[pos tNumber]];
      [up setTNumber:2*high-1-[pos tNumber]];
   }
   else	{				// propagates position upwards
      [low setTNumber:2*high-1-[pos tNumber]];
      [up setTNumber:[pos tNumber]];
   } // if
   [pos setUpper:up];
   [pos setLower:low];
   [pos setRound:2*[[pos nextMatch] round]];
   [positions addObject:up];
   [positions addObject:low];
   [positions removeObject:pos];
   
   return 2*high-1-[pos tNumber];
   
} // makeMatch

BOOL bucketSortPositions(NSMutableArray *positions)
/* in: positions: a list of positions to sort in increasing tnumber order
 what: performs bucketSort on the list an reassembles it
  ret: YES on success, NO otherwise
*/
{  long max, i, h, snum;
   id __strong *pos;
   
   snum = [positions count];		// number of positions at start
   max = 0;
   for(i=0; i<snum; i++) {
      if ((h = [[positions objectAtIndex:i] tNumber]) > max) {
         max = h;
      }
   }
   pos = (id __strong *)calloc(max, sizeof(id));
   for(i=0; i<max; i++)	{		// initialize
      pos[i] = nil;
   } // for
   for(i=0; i < snum; i++) {		// enter doubled and new positions
      pos[[[positions objectAtIndex:i] tNumber]-1] = [positions objectAtIndex:i];
      	// the number in the table is one larger than necessary
   } // for
   
   [positions removeAllObjects];
   for(i=0; i<max; i++) {
      if (pos[i] != nil) {
	 [positions addObject:pos[i]];
      } // if
      pos[i]=nil;    // this is to please ARC ..., one of the few instances that were easier before
   } // for
 
   free(pos);
   
   return ([positions count] == snum);
   
} // bucketSortPositions

- doubleMatch:aMatch;
// double the given first-round match, put an eventual winner in front
{
   if (([aMatch upperMatch] != nil) || ([aMatch lowerMatch] != nil)) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
      alert.informativeText = NSLocalizedStringFromTable(@"Verdoppeln nur in erster Runde\nzulässig", @"Tournament", nil);
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Ok", @"Tournament", nil)];
      [alert beginSheetModalForWindow:[TournamentDelegate.shared.seriesController seriesWindow] completionHandler:nil];
   } else {
      makeMatch(aMatch, positions);
      [TournamentDelegate.shared number:aMatch];
      
      if ([aMatch winner] != nil) {
         if ([[aMatch upperMatch] tNumber] < [[aMatch lowerMatch] tNumber]) {
            [[aMatch upperMatch] setWinner:[aMatch winner]];
         } else {
            [[aMatch lowerMatch] setWinner:[aMatch winner]];
         } // if
         [[aMatch winner] removeMatch:[aMatch nextMatch]];
         [[aMatch winner] addMatch:aMatch];
         [aMatch updateWinnerTo:nil];
      }
   }
   
   return self;
   
} // doubleMatch

- (BOOL)doSophDraw;
/* does the draw for the whole series from the players in the list.
   Sophisticated version with set players
*/
{
   long i, max, unset, unsetPosNum, h, high, realPos;
   NSMutableArray *newPos = [[NSMutableArray alloc] initWithCapacity:[players count]];
		// new positions in makeMatch
   
   max = [players count];
   if (setPlayers == 0) {		// compute standard setPlayers if not set
      setPlayers = 1;
      while (setPlayers <= max/4) {
         setPlayers = setPlayers*2;
      } // while
   } // if

   unset = max - setPlayers;
   if (serCoefficient == 0.0) {
      unsetPosNum = setPlayers;	// standard, double number of places
   } else {
      unsetPosNum = ((int) (unset + serCoefficient - 1)/serCoefficient);
      // more positions must be created, consider roundoff-error
   }
   
   realPos = 1;				// minimum
   while(realPos < setPlayers+unsetPosNum) {	// fill the table
      realPos = realPos*2;
   }
   unsetPosNum = realPos - setPlayers;		// readjust unset positions
   
   matchTable = [[Match alloc] initUpTo:realPos current:1
                total:1 next:nil series:self posList:positions];

   if (!bucketSortPositions(positions)) {
      return NO;
   }

   i = unsetPosNum;		// this many we have at the beginning
   high = [positions count] -1;	// highest of the currently init'ed positions
   while (i < unset) {		// this many we need.
      while (([positions count] > setPlayers) && (i < unset)) {
         h = makeMatch([positions lastObject], newPos);
         [positions removeLastObject];
				// the last position is doubled and removed (there is a new)
         if (h > high) {
            high = h;
         }
         i++;
      } // while
      
      if (!bucketSortPositions(newPos)) return NO;
      [positions addObjectsFromArray:newPos];
      [newPos removeAllObjects];
   } // while
   
   [self doKODraw];
   
   return YES;
} // doSophDraw

- (void)cleanup;
// for cleanup before redraw
{
   // TODO: this does not look convincing
}

- (void)semiFinalLoosers:(Match *)final;
{
   NSMutableArray *pstns = [NSMutableArray array];
   smallFinalTable = [[Match alloc] initUpTo:2 current:1 total:1 next:nil series:self
                                        posList:pstns];
   [[final upperMatch] setLoserMatch:smallFinalTable];
   [smallFinalTable setUpper:[final upperMatch]];
   [smallFinalTable setUpperIsWinner:NO];
   [[final lowerMatch] setLoserMatch:smallFinalTable];
   [smallFinalTable setLower:[final lowerMatch]];
   [smallFinalTable setLowerIsWinner:NO];
}

- (void) addSmallFinalIfDesired;
{
  if ([self hasSmallFinal]) {
      [self semiFinalLoosers:matchTable];
   }

}

- (BOOL)makeTable;
/* ret: YES if the series was drawn correctly (or has already been so)
  what: draws the series according to its sMode (seriesMode)
*/
{
   if (isupper(sMode))
   {
      alreadyDrawn = [self doSophDraw];
   }
   else
   {
      alreadyDrawn = [self doSimpleDraw];
   } // if
   [self addSmallFinalIfDesired];

   [self numberKoMatches];
   
   return alreadyDrawn;

} // makeTable

- (void)shufflePlayerRun:(long)start end:(long)end;
{
   long i, j;

   for (i=start; i<end; i++) {
      for(j=i+1; j<end; j++) {
         if (arc4random_uniform(2) < 1) {
            [players exchangeObjectAtIndex:i withObjectAtIndex:j];
         }
      }
   }
}

- (void)shufflePlayerList;
{
   long runStart = 0, max = [players count];

   while (runStart < max) {
      SeriesPlayer *current = [players objectAtIndex:runStart];
      long i=runStart+1;
      while ((i < max) && (![current isStronger: [players objectAtIndex:i] sender:self])) {
         i++;
      }
      if (i-1 > runStart) {
         [self shufflePlayerRun:runStart end:i-1];
      }
      runStart = i;
   }
}

- (BOOL)doDraw;
// checks if the players are there, loads them if necessary or desired
// and initiates drawing-process
{
   NSWindow *seriesWindow = [TournamentDelegate.shared.seriesController seriesWindow];
   if (alreadyDrawn) {				// careful, probably not twice
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Vorsicht!", @"Tournament", nil);
      alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Die Serie\n%@\n wurde bereits ausgelost", @"Tournament", nil), fullName];
      alert.alertStyle = NSAlertStyleCritical;
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Nochmal", @"Tournament", nil)];
      NSModalResponse returnCode = [alert synchronousModalSheetForWindow:seriesWindow];
      if (returnCode == NSAlertFirstButtonReturn) {
         return YES;				// not once more !
      } else {
         [positions removeAllObjects];			// reinit positions
         [matchTable releaseAll];			// and table
         [players removeAllObjects];
         [smallFinalTable releaseAll];
         smallFinalTable = nil;
      }
   } // if
   
   [self cleanup];
   if (([players count] == 0) || (onlyRaisePlayers(players))) {
   			     // this might hurt, but where?
      [self loadPlayersFromDatabase];
   } else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Vorsicht!", @"Tournament", nil);
      alert.informativeText = NSLocalizedStringFromTable(@"Spielerdaten bereits vorhanden", @"Tournament", nil);
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Wiederverwenden", @"Tournament", nil)];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Neu laden", @"Tournament", nil)];
      if ([alert synchronousModalSheetForWindow:seriesWindow] == NSAlertSecondButtonReturn) {
         [players removeAllObjects];
         [self loadPlayersFromDatabase];
      } // if
   } // if
   [self shufflePlayerList];
   Boolean retVal = [self makeTable];
   if ([drawingErrors count] > 0) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = [NSString stringWithFormat: NSLocalizedStringFromTable(@"drawingErrorsSeries", @"Tournament", nil), fullName];
      alert.informativeText = [drawingErrors componentsJoinedByString:@"\n\n"];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Ok", @"Tournament", nil)];
      [alert beginSheetModalForWindow:[TournamentDelegate.shared.seriesController seriesWindow] completionHandler:nil];
   }
   return retVal;
   
} // doDraw

- (NSString *)rankingStringFor:(id)player;
{
   long rankingInSeries=[player rankingInSeries:self];
			
   if (rankingInSeries > 0) {
      return [NSString stringWithFormat:@"%ld", rankingInSeries];
   } else {
      return nil;
   }
}

- (void)startSeries;
/* start the series and enter the ready matches into the matchBrowser
*/
{
   long max = [positions count], i;
   NSMutableSet *newMatches = [NSMutableSet setWithCapacity:10];
   NSEnumerator *matches;
   Match *match;
   
   [self setStarted:YES]; 		// now the series starts.
   [[TournamentDelegate.shared.matchController matchBrowser] startBatchUpdate];
   
   for(i=0; i<max; i++) {
      match = [positions objectAtIndex:i];
      [[match winner] addMatch:[match nextMatch]];
      [self checkMaxRanking:[match winner]];
      [newMatches addObject:[match nextMatch]];
   } // for
   
   matches = [newMatches objectEnumerator];
   while ((match = [matches nextObject])) {
      [match checkForWO];
   } 

   [[TournamentDelegate.shared.matchController matchBrowser] finishBatchUpdate];
} // startSeries

- (void)setStarted:(BOOL)flag;
{
   started=flag;
} // started

- (BOOL)started;
{
   return started;
} // started

- (float)basePriority;
{
   return 1.0;
}

- (BOOL)alreadyDrawn;
{
   return alreadyDrawn;
} // alreadyDrawn

- (BOOL)drawContinuosly;
{
   return !alreadyDrawn && started;
} // alreadyDrawn

- (IBAction) allMatchSheets:(id)sender;
// print out all match sheets of this Series in increasing order
// (Final comes last)
{
   NSMutableArray *matches = [[NSMutableArray alloc] init];
   
   [matches addObject:matchTable];		// insert match to start from
   if (smallFinalTable != nil) {
      [matches addObject:smallFinalTable];
   }
   printAllMatches(matches);
} // allMatchSheets

// methods for the drawableSeries-protocol

- (long)totalPages;
{
   return [tablePages count] + 1;
}

- (long)lastInterestingPage;
{
   if (![self finished]) {
      return [self totalPages] - 1;
   } else {
      return [self totalPages];
   }
}

- paginateTable:(Match *)aMatch in:aView;
// recursively paginate the table
{
   if (aMatch == nil) {
      return self;
   }
   if ([aMatch pMatches] < [aView maxMatchOnPage])
   {
      [tablePages addObject:aMatch];
   }
   else
   {
      [self paginateTable:[aMatch upperMatch] in:aView];
      [self paginateTable:[aMatch lowerMatch] in:aView];
   } // if
   
   return self;
   
} // paginateTable

- paginate:sender;
// paginate a series with just table
{
   float top;
   [tablePages removeAllObjects];
   
   if ([matchTable pMatches] >= [sender maxMatchOnPage])
   {
      master = matchTable;
   }
   else
   {
      master = nil;
   } // if
   [self paginateTable:matchTable in:sender];
   top = [self totalPages] * (int)[sender pageHeight];
   [sender setFrameSize:NSMakeSize([sender pageWidth],top)];
   
   return self;
} // paginate

- (float)pageHeader:(NSRect *)pageRect;
   // draws the page-header for the series and returns the top position for drawing
{
   long max=0;
   float top=pageRect->origin.y+pageRect->size.height;
   float nameLeft = 270.0;
   
   NSString *blattFormat = NSLocalizedStringFromTable(@"BlattFormat", @"Tournament", @"Format für Blattnummer");
   [[NSString stringWithFormat:blattFormat, _currentPage]
    drawAtPoint: NSMakePoint(pageRect->size.width - 50.0, top - 12.0)
    withAttributes:[TournamentView smallAttributes]];
   [TournamentDelegate.shared.tournament.title drawAtPoint:NSMakePoint(30, top-25.0)
                                            withAttributes:[TournamentView titleAttributes]];
   top = top - 50;
   
   [TournamentDelegate.shared.tournament.subtitle drawAtPoint:NSMakePoint(30, top)
                                               withAttributes:[TournamentView titleAttributes]];
   
   [fullName drawAtPoint:NSMakePoint(nameLeft, top)
          withAttributes:[TournamentView largeAttributes]];
   top = top - 18;
   NSString *dateTimeFormat = NSLocalizedStringFromTable(@"DatumZeitFormat", @"Tournament", @"Format für Datum und Zeit");
   NSString *dateTime = [NSString stringWithFormat:dateTimeFormat, TournamentDelegate.shared.tournament.dateRange, startTime];
   [dateTime drawAtPoint:NSMakePoint(nameLeft, top)
          withAttributes:[TournamentView largeAttributes]];
   
   [[self numString] drawAtPoint:NSMakePoint(30, top)
                  withAttributes:[TournamentView largeAttributes]];
   top = top - 12.0;
   max=[self maxRankingPresent];
   if (max > 0) {
      NSString *bestKlassFormat = NSLocalizedStringFromTable(@"BesteKlassierungFormat", @"Tournament", @"Format für Beste Klassierung");
      [[NSString stringWithFormat:bestKlassFormat, max]
       drawAtPoint:NSMakePoint(30, top)
       withAttributes:[TournamentView smallAttributes]];
   }
   
   NSString *osrFormat = NSLocalizedStringFromTable(@"OSRFormat", @"Tournament", @"Format für Beste Klassierung");
   [[NSString stringWithFormat:osrFormat, TournamentDelegate.shared.tournament.referee]
    drawAtPoint:NSMakePoint(150, top)
    withAttributes:[TournamentView smallAttributes]];
   
   NSString *verbaendeFormat = NSLocalizedStringFromTable(@"VerbaendeFormat", @"Tournament", @"Format für Verbände");
   [[NSString stringWithFormat:verbaendeFormat, TournamentDelegate.shared.tournament.associations]
    drawAtPoint:NSMakePoint(nameLeft, top)
    withAttributes:[TournamentView smallAttributes]];
   top = top - 16;
   _currentPage = _currentPage + 1;
   
   return top;
} // pageHeader

- (void) drawPages:(const NSRect)rect page:(NSRect *)page
                          maxMatchesOnPage:(long)maxMatchesOnPage;
{
   _currentPage = 1;
   [self drawSelf:rect page:page maxMatchesOnPage:maxMatchesOnPage];
}

- (void) drawRankingListPage: (const NSRect) rect page: (NSRect *) page maxMatchesOnPage:(long) maxMatchesOnPage;
{
  if (NSIntersectsRect(*page, rect)) {
     const float ranklistleft = 50.0;
     float top;
     NSDictionary *titleAttributes=[NSDictionary dictionaryWithObject:
                                    [NSFont fontWithName:@"Times-Bold" size:24.0] forKey:NSFontAttributeName];
     
     top = [self pageHeader:page];
     
     if (master != nil) {
        long pages = 1;
        
        [master drawMaster:&top at:page->size.width - 40.0
                       max:maxMatchesOnPage page:&pages];
     } // if
     
     top=top-40;
     [NSLocalizedStringFromTable(@"Rangliste", @"Tournament", @"Text für Rangliste")
      drawAtPoint:NSMakePoint(ranklistleft, top)
      withAttributes:titleAttributes];
     
     top = top - 30.0;
     [self drawRankingListBelow:top at:ranklistleft];     
   } else {
      _currentPage++;
   }

}
- drawSelf:(const NSRect)rect page:(NSRect *)page
                         maxMatchesOnPage:(long)maxMatchesOnPage;
{
   long i, max;

   [[NSColor blackColor] set];

   max = [tablePages count];
   for(i = 1; i <= max; i++) {
      float top;

      if (NSIntersectsRect(*page, rect)) {
         top = [self pageHeader:page];

         [[tablePages objectAtIndex:i-1] draw:&top at:page->size.width - 30.0
                                          max:[[tablePages objectAtIndex:i-1] pMatches]];
         if ((smallFinalTable != nil) && (i==[self smallFinalPage])) {
            float smallTop=page->origin.y + 50.0;
            NSDictionary *finalAttributes=[NSDictionary dictionaryWithObject:
                                           [NSFont fontWithName:@"Times-Roman" size:14.0] forKey:NSFontAttributeName];
            [@"kleiner Final" drawAtPoint:NSMakePoint(page->size.width - 130.0, smallTop+14.0)
                           withAttributes:finalAttributes];
            [smallFinalTable draw:&smallTop at:page->size.width - 30.0
                              max:[smallFinalTable pMatches]];
         }
      } else {
         _currentPage++;
      }
      page->origin.y -= page->size.height;
   } // for

   [self drawRankingListPage: rect page: page maxMatchesOnPage:maxMatchesOnPage];

   return self;
} // drawSelf

- (void) drawRankingListBelow:(float) top at:(float)ranklistleft;
{
   if ([matchTable finished]) {
      [matchTable drawRankingList:ranklistleft at:&top upTo:16 withOffset:0];
   }
}

- (NSMutableArray*) rankingListUpTo:(long) max;
{
   NSMutableArray* playerList = [NSMutableArray arrayWithCapacity:max];
   if ((matchTable != nil) && ([matchTable winner] != nil)) {
      [playerList addObject:[matchTable winner]];
      
      [matchTable rankingList:playerList upTo:max];
   }
   
   return playerList;
}

- (NSString *)numString;
{
   if ([self isWomanSeries]) {
      NSString *anzahlSpielerinnenFormat = NSLocalizedStringFromTable(@"Anzahl Spielerinnen: %d", @"Tournament",
                                                                      @"Format für Anzahl Spielerinnen");
      return [NSString stringWithFormat:anzahlSpielerinnenFormat, [self countPlayers]];
   } else {
      NSString *anzahlSpielerFormat = NSLocalizedStringFromTable(@"Anzahl Spieler: %d", @"Tournament",
                                                                 @"Format für Anzahl Spielerinnen");
      return [NSString stringWithFormat:anzahlSpielerFormat, [self countPlayers]];
   }
} // numString

- (void)endSeriesProcessing:sender;
/* in: sender: where the message comes from
 what: processing to be done at the end of a Series, nothing for regular series, hook for derived classes.
*/
{
}

- (void)printWONPPlayersInto:text;
/* in: text: The SmallTextController which controlls the text to print in
 what: prints the names of the players who lost their last match wo
       and the not present players
*/
{
	NSString *buffer=nil;
   
   [text clearText];
   buffer = [NSString stringWithFormat:@"WO Spieler: %@\n", [self fullName]];
   [text setTitleText:buffer];
   if ([self printWOPlayersInto:text] == 0)
   {
      [text appendText:@"keine!\n"];
   } // if
   [text appendText:@"\nabgemeldet\n"];
   if ([self printNPPlayersInto:text] == 0)
   {
      [text appendText:@"keine!\n"];
   } // if
} // printWONPPlayersInto

- (long)printWOPlayersInto:text;
/* in: text: The SmallTextController which controlls the text to print in
 what: prints just the WO players without bells and whistles
returns: the number of WO players
notes: it might be simpler to override this message than the above
*/
{  NSString *buffer=nil;
   long max = [positions count], i, count=0;

   for(i=0; i<max; i++) {
      id <Player> posAti = (id <Player>)[[positions objectAtIndex:i] winner];
      
      if ([posAti wo]) {
         count++;
         buffer = [NSString stringWithFormat:@"\t%ld\t%@\t%@\n", i+1,
	    [posAti longName], [posAti club]];
	 [text appendText:buffer];
      } // if
   } // for
   
   return count;
   
} // printWOPlayersInto

- (long)printNPPlayersInto:text;
/* in: text: The SmallTextController which controlls the text to print in
 what: prints just the not present players without bells and whistles
returns: the number of not present players
*/
{  NSString *buffer;
   long max = [positions count], i, count=0;

   for(i=0; i<max; i++) {
      id <Player> posAti = (id <Player>)[[positions objectAtIndex:i] winner];
      if (![posAti present]) {
	 count++;
	 buffer=[NSString stringWithFormat:@"\t%ld\t%@\t%@\n", i+1,
	    [posAti longName], [posAti club]];
	 [text appendText:buffer];
      } // if
   } // for
   return count;
} // printNPPlayersInto

- (NSDictionary*)largeAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Times-Bold" size:24.0] forKey:NSFontAttributeName];
}

- (void)storeInDatabase;
{
   if (_isNew) {
      [self insertIntoDatabase];
   } else if (_isEdited) {
      [self updateDatabase];
   }
}

- (void)insertIntoDatabase;
{ // SerFields.SeriesName, SerFields.FullName, SerFields.StartTime, SerFields.Grouping, SerFields.MinRanking, SerFields.MaxRanking, SerFields.Promotees, SerFields.Type, SerFields.BestOfSeven, SerFields.Age, SerFields.SerCoefficient, SerFields.SetPlayers, SerFields.Sex, SerFields.SmallFinal
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO Series (%@, TournamentId) VALUES ('%@', '%@', '%@', '%@', %ld, %ld, %ld, '%@', %ld, '%@', %f, %ld, '%@', '%d', %f, %f, '%@')", [Series allFields], seriesName, fullName, startTime, grouping, minRanking, maxRanking, promotees, type, bestOfSeven, age, serCoefficient, setPlayers, sex, _smallFinal, priceAdult, priceYoung, TournamentDelegate.shared.preferences.tournamentId];
   if ([database execCommand:insertSQL]) {
      _isNew=NO;
      _isEdited=NO;
   } else {
      NSLog(@"database failure %@: %@ during insert of %@", [database lastError], [database errorDescription], insertSQL);
   }
}

- (void)updateDatabase;
{
   NSString *updateSQL = [NSString stringWithFormat:@"UPDATE Series SET %@='%@', %@='%@', %@='%@', %@=%ld, %@=%ld,  %@=%ld, %@='%@', %@=%ld, %@='%@', %@=%f, %@=%ld,  %@='%@', %@='%d', %@=%f, %@=%f WHERE %@='%@' AND %@='%@'", SerFields.FullName, fullName, SerFields.StartTime, startTime, SerFields.Grouping, grouping, SerFields.MinRanking, minRanking, SerFields.MaxRanking, maxRanking, SerFields.Promotees, promotees, SerFields.Type, type, SerFields.BestOfSeven, bestOfSeven, SerFields.Age, age, SerFields.SerCoefficient, serCoefficient, SerFields.SetPlayers, setPlayers, SerFields.Sex, sex, SerFields.SmallFinal, _smallFinal, SerFields.PriceAdult, priceAdult, SerFields.PriceYoung, priceYoung, SerFields.SeriesName, seriesName, SerFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId];
   PGSQLConnection *database=TournamentDelegate.shared.database;

   if ([database execCommand:updateSQL]) {
      _isEdited=NO;
   } else {
      NSLog(@"DB command %@, somehow went wrong", updateSQL);
   }
}

- (void)deleteFromDatabase;
{
   if (!_isNew) {
      PGSQLConnection *database=TournamentDelegate.shared.database;

      NSString * deleteSQL = [NSString stringWithFormat:@"DELETE FROM Series  WHERE %@ ='%@' AND %@ ='%@'", SerFields.SeriesName, seriesName, SerFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId];
      [database execCommand:deleteSQL];
   }
}

const char *seriesFieldList="Series, FullName, Start, MinRank, MaxRank, Type, BestOfSeven,"
"Age, setCoeff, SetPlayers, Sex, TournamentID, promotees, Grouping, SmallFinal";

- (id)objectFor:(NSString *)identifier;
{
   if ([identifier isEqualToString:@"series"]) {
      return seriesName;
   } else if ([identifier isEqualToString:@"name"]) {
      return fullName;
   } else if ([identifier isEqualToString:@"start"]) {
      return startTime;
   } else if ([identifier isEqualToString:@"min"]) {
      return [NSNumber numberWithLong:minRanking];
   } else if ([identifier isEqualToString:@"max"]) {
      return [NSNumber numberWithLong:maxRanking];
   } else if ([identifier isEqualToString:@"type"]) {
      return type;
   } else if ([identifier isEqualToString:@"bestOf7"]) {
      return [NSNumber numberWithLong:bestOfSeven];
   } else if ([identifier isEqualToString:@"age"]) {
      return age;
   } else if ([identifier isEqualToString:@"coeff"]) {
      return [NSNumber numberWithDouble:serCoefficient];
   } else if ([identifier isEqualToString:@"set"]) {
      return [NSNumber numberWithLong:setPlayers];
   } else if ([identifier isEqualToString:@"sex"]) {
      return sex;
   } else if ([identifier isEqualToString:@"promotees"]) {
      return [NSNumber numberWithLong:promotees];
   } else if ([identifier isEqualToString:@"grouping"]) {
      return grouping;
   } else if ([identifier isEqualToString:@"smallfinal"]) {
      return [NSNumber numberWithBool:_smallFinal];
   } else if ([identifier isEqualToString:@"priceAdult"]) {
      return [NSNumber numberWithDouble:priceAdult];
   } else if ([identifier isEqualToString:@"priceYoung"]) {
      return [NSNumber numberWithDouble:priceYoung];
   } else {
      return @"dummy";
   }
}

- (void)setObject:(id)anObject for:(NSString *)identifier;
{
   if ([identifier isEqualToString:@"series"]) {
      seriesName=anObject;
   } else if ([identifier isEqualToString:@"name"]) {
      fullName=anObject;
   } else if ([identifier isEqualToString:@"start"]) {
      startTime=anObject;
   } else if ([identifier isEqualToString:@"min"]) {
      minRanking=[anObject intValue];
   } else if ([identifier isEqualToString:@"max"]) {
      maxRanking=[anObject intValue];
   } else if ([identifier isEqualToString:@"type"]) {
      type=anObject;
   } else if ([identifier isEqualToString:@"bestOf7"]) {
      bestOfSeven=[anObject intValue];
   } else if ([identifier isEqualToString:@"age"]) {
      age=anObject;
   } else if ([identifier isEqualToString:@"coeff"]) {
      serCoefficient=[anObject doubleValue];
   } else if ([identifier isEqualToString:@"set"]) {
      setPlayers=[anObject intValue];
   } else if ([identifier isEqualToString:@"sex"]) {
      sex=anObject;
   } else if ([identifier isEqualToString:@"promotees"]) {
      promotees=[anObject intValue];
   } else if ([identifier isEqualToString:@"grouping"]) {
      grouping=anObject;
   } else if ([identifier isEqualToString:@"smallfinal"]) {
      _smallFinal=[anObject boolValue];
   } else if ([identifier isEqualToString:@"priceAdult"]) {
      priceAdult = [anObject doubleValue];
   } else if ([identifier isEqualToString:@"priceYoung"]) {
      priceYoung = [anObject doubleValue];
   }
   _isEdited=YES;
}

- (void)appendHeaderTo:(NSMutableString *)html;
{
   [html appendString:@"<colgroup>\n"];
   [html appendString:@"<col width=\"15%\" />"];
   [html appendString:@"<col width=\"30%\" />"];
   [html appendString:@"<col width=\"25%\" />"];
   [html appendString:@"<col width=\"15%\" />"];
   [html appendString:@"<col width=\"15%\" />"];
   [html appendString:@"</colgroup>\n"];
   [html appendString:@"<thead>"];
   [html appendFormat:@"<th align=\"right\">%@</th>\n", NSLocalizedStringFromTable(@"Position", @"Tournament", null)];
   [html appendFormat:@"<th align=\"left\">%@</th>", NSLocalizedStringFromTable(@"Name", @"Tournament", null)];
   [html appendFormat:@"<th align=\"left\">%@</th>", NSLocalizedStringFromTable(@"Club", @"Tournament", null)];
   [html appendFormat:@"<th align=\"right\">%@</th>", NSLocalizedStringFromTable(@"Klassierung", @"Tournament", null)];
   [html appendString:@"<th align=\"right\">"];
   if ([@"MA" isEqualToString:seriesName] || [@"WA" isEqualToString:seriesName]
         || [@"MA20" isEqualToString:seriesName] || [@"WA20" isEqualToString:seriesName]) {
      [html appendString:NSLocalizedStringFromTable(@"Ranking-Position", @"Tournament", null)];
   } else {
      [html appendString:NSLocalizedStringFromTable(@"gesetzt als", @"Tournament", null)];
   }
   [html appendString:@"</th>"];
   [html appendString:@"</thead>\n"];
   [html appendString:@"<tfoot>\n"];
   [html appendString:@"</tfoot>\n"];
}

- (void)appendTableFooterTo:(NSMutableString *)html;
{
}

- (void)appendInscriptionsAsTableTo:(NSMutableString *)html;
{
   [players removeAllObjects];
   [self cleanup];
   [self loadPlayersFromDatabase];
   long i, max = [players count];

   [html appendString:@"<table>\n"];
   [self appendHeaderTo:html];
   [html appendString:@"<tbody>\n"];
   for (i=0; i<max; i++) {
      SeriesPlayer *player = [players objectAtIndex:i];

      [player appendAsHTMLRowTo:html position:i+1 forSeries:self];
   }
   [self appendTableFooterTo:html];
   [html appendString:@"</tbody>\n"];
   [html appendString:@"</table>\n"];
   
}

- (void)appendAsHTMLTo:(NSMutableString *)html;
{
   [html appendString:@"<a name=\""];
   [html appendString:seriesName];
   [html appendString:@"\"></a>\n"];
   [html appendString:@"<h2>"];
   [html appendString:fullName];
   [html appendString:@"</h2>\n"];
   [self appendInscriptionsAsTableTo:html];
}

- (void)appendPlayers:(NSArray *)pls asRowsTo:(NSMutableString *)html;
{
   long i, max=[pls count];

   for (i=0; i<max; i++) {
      SinglePlayer *player = (SinglePlayer *)[pls objectAtIndex:i];

      [player appendAsHTMLRowTo:(NSMutableString *)html forSeries:self];
   }
}

- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
{
   if (matchTable != nil) {
      [matchTable appendResultsAsTextTo:text];
   }

   if (smallFinalTable != nil) {
      [smallFinalTable appendResultsAsTextTo:text];
   }
}

- (void)appendSingleSeriesInfoAsTextTo:(NSMutableString *)text;
{
   [text appendFormat:@"%@\t", seriesName];
   if ([self isWomanSeries])
   {
      [text appendString:@"D\t"];
   } else {
      [text appendString:@"\t"];
   }
   if ([age length] == 0) {      // Bonus
      [text appendString:@"B\t"];
   } else {
      [text appendString:@"\t"];
   }
   [text appendString:@"\n"];    // never negativ
}

- (float)tourPriorityFor:(float)dayRanking;
{
   float deltaDayRanking = maxDayRanking-dayRanking;
   
   if (deltaDayRanking > 0.8) {
      return 1/deltaDayRanking;
   } else {
      return 1.25;
   }
}

- (BOOL)finished;
{
   NSArray *tables = [self matchTables];
   long i, max=[tables count];
   if (max == 0) {
      return NO;
   }
   
   for (i=0; i<max; i++) {
      if (![[tables objectAtIndex:i] finished]) {
         return NO;
      }
   }
   return YES;
}

- (NSMutableArray *) matchTables;
{
   NSMutableArray *tables = [NSMutableArray arrayWithCapacity:4];
   if (matchTable != nil) {
      [tables addObject:matchTable];
   }
   if (smallFinalTable != nil) {
      [tables addObject:smallFinalTable];
   }
   
   return tables;
}

- textRankingListIn:text;
{
   [matchTable textRankingListIn:text upTo:16];
   return self;
}

- (bool)matches:(NSString *)selectedGroup;
{
   if ((selectedGroup  == nil) || ([selectedGroup length] == 0)) {
      return YES;
   } else {
      return [selectedGroup isEqualToString:grouping];
   }
}

// centralize the following 3 alert-sheets used by many double series
- (void)alreadyHasPartner:(SinglePlayer *)player existingPartner:(SinglePlayer*)partner
					newPartner:(SinglePlayer*)newPartner;
{
   [drawingErrors addObject:[NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ hat schon einen Doppelpartner\n(%@), neu: %@", @"Tournament", null), [player longName], [partner longName], [newPartner longName]]];
}

- (void)inscriptionWithoutPartner:(SinglePlayer *)player notPartner:(SinglePlayer*)partner;
{
   [drawingErrors addObject:[NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ ist offen angemeldet\n(nicht als Partner von %@)", @"Tournament", null), [player longName], [partner longName]]];
}

- (void)notWithHimself:(SinglePlayer *)player;
{
   [drawingErrors addObject:[NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ kann nicht mit sich selber Doppel spielen.", @"Tournament", null), [player longName]]];
}

- (void)matchNotPlayed:(Match*)match;
{
   // we usually ignore this
}

- (BOOL) hasSmallFinal;
{
   return _smallFinal;
}

- (void) setSmallFinal: (BOOL)aSmallFinal;
{
   _smallFinal = aSmallFinal;
}

- (NSArray *) players;
{
   return players;
}

- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
{
   NSArray *allMatchTables = [self matchTables];
   long i, max=[allMatchTables count];
   
   for (i=0; i<max; i++) {
      [[allMatchTables objectAtIndex:i] gatherPlayersIn:allPlayers];
   }
}

- (void)appendEachPlayerXmlTo:(NSMutableString *)text;
{
   NSMutableSet *allPlayers = [NSMutableSet setWithCapacity:[players count]];
   [self gatherPlayersIn:allPlayers];
   NSEnumerator *enumerator = [allPlayers objectEnumerator];
   id player;
   
   while ((player = [enumerator nextObject])) {
      [player appendPlayerXmlTo:text forSeries:self];
   }
}

- (void)appendPlayersXmlTo:(NSMutableString *)text;
{
   [text appendString:@"  <players >\n"];
   [self appendEachPlayerXmlTo: text];
   [text appendString:@"  </players>\n"];
}

- (NSString *) dateTime {
   NSString *stringDate = [TournamentDelegate.shared clickTtDateStringForExport];
   return [NSString stringWithFormat:@"%@ %@", stringDate, [self startTime]];

}
- (void)appendAsXmlTo:(NSMutableString *)text;
{
   [text appendFormat:@" <competition name=\"%@\"\n", [self fullName]];
   [text appendFormat:@"  age-group=\"%@\"", [self ageGroup]];
   [text appendFormat:@"  type=\"%@\" start-date=\"%@\"\n", [self type], [self dateTime]];
   [text appendFormat:@"  classification-from=\"%@\" classification-to=\"%@\"\n", [self clickTTMin], [self clickTTMax]];
   [text appendString:@" >\n"];
   [self appendPlayersXmlTo: text];
   [text appendString:@"  <matches>\n"];
   [self appendMatchResultsAsXmlTo:text];
   [text appendString:@"  </matches>\n"];
   [text appendString:@" </competition>\n"];
}

- (NSString *)type;
{
   return @"Einzel";
}

- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
{
   NSArray *tables = [self matchTables];
   long i, max=[tables count];
   
   for (i=0; i<max; i++) {
      [[tables objectAtIndex:i] appendMatchResultsAsXmlTo:text];
   }
}

- (NSString *)age;
{
   return age;
}

// This strange hack especially for click-tt
- (NSString *)ageGroup;
{
  if ([age length] > 0) {
     return age;
  } else { // no need to save so far, we need to trick the jungle king
    if ([[Series uoSet] characterIsMember:[seriesName characterAtIndex:0]]) {
      return seriesName;
    } else if ([seriesName characterAtIndex:0] == 'W') {
      return @"Damen";
    } else {
      return @"Herren";
    }
  }
}

long seriesPoints(long rank) {
   switch(rank) {
      case 0: return 8;
      case 1: return 6;
      case 2:
      case 3: return 4;
      case 4:
      case 5: return 2;
      case 6:
      case 7: return 1;
      default: return 0;
   }
}

long doubleSeriesPoints(long rank) {
   switch(rank) {
      case 0: return 4;
      case 1: return 3;
      case 2:
      case 3: return 2;
      default: return 0;
   }
}

- (void) addResult:(SinglePlayer *)player points:(long)points to:(NSMutableDictionary *)clubResults;
{
   ClubResult *clubResult;
   NSString *clubName = [player club];
   if ([clubResults objectForKey:clubName]) {
      clubResult = [clubResults objectForKey:clubName];
   } else {
      clubResult = [ClubResult with:clubName];
      [clubResults setObject:clubResult forKey:clubName];
   }
   [clubResult add:player series:self points:points];
}

- (void)singlePointsIn:(NSMutableDictionary *)clubResults;
{
   NSArray *rankPlayers = [self rankingListUpTo:8];
   long i, maxRanks = 8;
   if ([rankPlayers count] < maxRanks) {
      maxRanks = [rankPlayers count];
   }
   for (i=0; i<maxRanks; i++) {
      SinglePlayer *player = [rankPlayers objectAtIndex:i];
      [self addResult:player points:seriesPoints(i) to:clubResults];
   }
}

- (void)doublePointsIn:(NSMutableDictionary *)clubResults;
{
   NSArray *rankPlayers = [self rankingListUpTo:4];
   long i, maxRanks = 4;
   if ([rankPlayers count] < maxRanks) {
      maxRanks = [rankPlayers count];
   }
   for (i=0; i<maxRanks; i++) {
      DoublePlayer *dPlayer = [rankPlayers objectAtIndex:i];
      if ([dPlayer isKindOfClass:[DoublePlayer class]]) {     // sometimes GroupPlayer (wrongly)
         SinglePlayer *player = [dPlayer player];
         SinglePlayer *partner = [dPlayer partner];
         [self addResult:player points:doubleSeriesPoints(i) to:clubResults];
         [self addResult:partner points:doubleSeriesPoints(i) to:clubResults];
      }
   }
}

- (void)gatherPointsIn:(NSMutableDictionary *)clubResults;
{
   [self singlePointsIn:clubResults];
}

- (long)numberOfSetsFor:(Match *)match;
{
   long round = [match round];
   
   if ((round > 0) && (round <= [self bestOfSeven])) {
      return 7;
   } else {
      return 5;
   }
}

- (BOOL)olderThan:(Series *)other;
{
   if ([age hasPrefix:@"U"] && [[other age] hasPrefix:@"U"]) {
      int numericAge = [[age substringFromIndex:1] intValue];
      int otherAge = [[[other age] substringFromIndex:1] intValue];
      
      return numericAge > otherAge;
   } else {
      return NO;
   }
}

- (BOOL)validate;
/* Poor mans regex, only gets there (in a decent manner) in 10.7, hold off for Swift
 */
{
   if (([startTime length] == 5) && isdigit([startTime characterAtIndex:0]) && isdigit([startTime characterAtIndex:1])
       && ([startTime characterAtIndex:2] == ':')
       && isdigit([startTime characterAtIndex:3]) && isdigit([startTime characterAtIndex:4])) {
      return YES;
   } else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = @"Error";
      alert.informativeText = @"Zeit-Format muss HH:MM entsprechen";
      [alert addButtonWithTitle:@"Mach ich gleich"];
      [TournamentDelegate.shared.seriesDataController showAlert:alert];
      return NO;
   }
}

- (void)playSingleMatchesForAllOpenGroups;
{
   // most of the time we will have nothing to do
}

- (NSString *)nextMatchIdFor:(Match *)match;
{
   if (matchTable == match) {
      return @"Final";
   } else if (smallFinalTable == match) {
      return @"SmallFinal";
   } else {
      return @"unknown";
   }
}

- (NSString *)postfixFor:(Match *)match;
{
   return @"";
}

- (NSString *)roundStringFor:(Match *)match;
{
   NSString *postfix = [self postfixFor:match];
   
   if([match round] > 1){
      NSString *rundeFormat = NSLocalizedStringFromTable(@"1/%ld-Final%@", @"Matchblatt",
                                                         @"Format für normale Runde auf Matchblatt");
      return [NSString stringWithFormat:rundeFormat, [match round], postfix];
   }
   else if ([match round] == 1) {
      return [NSString stringWithFormat:@"%@%@", [self finalString:match], postfix];
   } else {
      return @"";
   }

}

- (NSArray<NSString *> *)drawingErrors;
{
   return drawingErrors;
}

- (NSString *)nameFor:(Match *)match;
{
   return fullName;
}

- (void) setAlreadyDrawn:(BOOL)drawn;
{
   alreadyDrawn = drawn;
}
@end
