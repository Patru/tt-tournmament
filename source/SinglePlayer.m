/*****************************************************************************
     Use: Control a table tennis tournament.
          Stores a single player, the basic resource of TT.
Language: Objective-C                 System: MacOS X
  Author: Paul Trunz, Copyright 2001
 History: 16.9.2001, Patru: started port from NeXTStep
    Bugs: -not very well documented
 *****************************************************************************/

#import "SinglePlayer.h"
#import <AppKit/AppKit.h>
#import <PGSQLKit/PGSQLKit.h>
#import "Match.h"
//#import <ctype.h>
#import "PlayerInspector.h"
#import "NotPresentController.h"
#import "TournamentController.h"
#import "Series.h"
#import "UmpireController.h"
#import "Tournament-Swift.h"

#define shortNameHeight 9.0
		// height of short strings
#define longNameHeight 12.0
		// height of short strings
#define maxWidth 60.0
		// max width for short names

PlayerInspector *_singlePlayerInspector;

@class Series;
NSString *RANKING_LINE_FORMAT = @"\t%@\t%@\t%@\n";

const struct SPFieldsStruct SPFields={
   .Licence      =@"Licence",
   .Name         =@"Name",
   .FirstName    =@"FirstName",
   .Category     =@"Category",
   .Club         =@"Club",
   .DateOfBirth  =@"DateOfBirth",
   .Ranking      =@"Ranking",
   .WomanRanking =@"WomanRanking",
   .EloPoints    =@"EloPoints",
};

static NSString * allFields = nil;
@implementation SinglePlayer
/* Stores the data of a single table tennis player, includes a list of matches
   which should still be played to compute priority.
*/

+ (SinglePlayer *) fromRecord:(PGSQLRecord *)record;
{
	SinglePlayer *player=[[SinglePlayer alloc] init];

   player->_licence=[[record fieldByName:SPFields.Licence] asNumber];
	player->name=[[record fieldByName:SPFields.Name] asString];
	player->firstName=[[record fieldByName:SPFields.FirstName] asString];
	player->ranking=[[record fieldByName:SPFields.Ranking] asLong];
	player->dayRanking=(float)player.ranking;
	player->womanRanking=[[record fieldByName:SPFields.WomanRanking] asLong];
	player->club=[[record fieldByName:SPFields.Club] asString];
	player->category=[[record fieldByName:SPFields.Category] asString];
	player->dateOfBirth=[[record fieldByName:SPFields.DateOfBirth] asString];     // TODO: use date (or remove?)
	player->validLicence=YES;
	player->ready=YES;
	player->elo=[[record fieldByName:SPFields.EloPoints] asLong];
		
	return player;
}

- init
{
    self=[super init];
    name = nil;
    firstName = nil;
    longName = nil;
    shortName = nil;
    category = @"AKT";
    club = nil;
    _licence = nil;
	 validLicence=NO;
    ranking = 0;
    womanRanking = 0;
    persPriority = 0.0;
    openMatches = [[NSMutableArray alloc] init];
    ready = NO;

    return self;
}


//- finishUnarchiving;
//{
//   return [self setReady:YES];
//} // finishUnarchiving

- (BOOL) isEqual:anObject;
// return YES if self is equal to anObject, NO otherwise
{
   return ([[anObject licenceNumber] isEqualToNumber:_licence]);
} // isEqual

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:name];
	[encoder encodeObject:firstName];
	[encoder encodeObject:category];
	[encoder encodeObject:club];
	[encoder encodeObject:longName];
	[encoder encodeObject:shortName];
	[encoder encodeObject:_licence];
	[encoder encodeValueOfObjCType:@encode(int) at:&ranking];
	[encoder encodeValueOfObjCType:@encode(float) at:&dayRanking];
	[encoder encodeValueOfObjCType:@encode(int) at:&womanRanking];
	[encoder encodeValueOfObjCType:@encode(int) at:&elo];
	[encoder encodeObject:openMatches];
	[encoder encodeValueOfObjCType:@encode(BOOL) at:&ready];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self=[super init];
	name=[decoder decodeObject];
	firstName=[decoder decodeObject];
	category=[decoder decodeObject];
	club=[decoder decodeObject];
	longName=[decoder decodeObject];
	shortName=[decoder decodeObject];
	_licence=[decoder decodeObject];
	[decoder decodeValueOfObjCType:@encode(int) at:&ranking];
	[decoder decodeValueOfObjCType:@encode(float) at:&dayRanking];
	[decoder decodeValueOfObjCType:@encode(int) at:&womanRanking];
   [decoder decodeValueOfObjCType:@encode(int) at:&elo];
	openMatches=[decoder decodeObject];
	[decoder decodeValueOfObjCType:@encode(BOOL) at:&ready];
	umpiresMatch=nil;
	
	return self;
}

- (id <InspectorControllerProtocol>) inspectorController;
{
	if (_singlePlayerInspector == nil) {
		_singlePlayerInspector=[[PlayerInspector alloc] init];
	}
	[_singlePlayerInspector setPlayer:self];
	
	return _singlePlayerInspector;
}

- (void)setPName:(NSString *)newName;
{
   name = newName;
} // setPName

- (void)setFirstName:(NSString *)newFirstName;
{
   firstName = newFirstName;
} // setFirstName

- (void)setClub:(NSString *)newClub;
{
   club = newClub;
} // setClub

- (void)setUmpiresMatch:(Match *)aMatch;
{
   umpiresMatch = aMatch;
} // setUmpiresMatch

- (void)setCategory:(NSString *)newCategory;
{
	category = newCategory;
} // setCategory

- (void)setLicence:(long)licence;
// set licence
{
   _licence=[NSNumber numberWithLong:licence];
} // setLicence

- (void)setRanking:(long)newRanking;
{
   ranking=newRanking;
} // setRanking

- (void)setElo:(long)newElo;
{
	elo=newElo;
}

- (void)setDayRanking:(float)newDayRanking;
// set dayRanking
{
   dayRanking=newDayRanking;
} // setDayRanking

- (void)adjustDayRanking:(float)adjustRanking;
/* in: adjustRanking:	the dayRanking of the player against whom this player
                      won/lost (positive: won, negative: lost)
 what: adjusts using the following (continuous, non differentiable) functions:
.         max player wins:   + 1/(10 + max - min)
.         max player looses: - 0.5 * (max - min) - 0.1
.         min player wins:   + 0.6 * (max - min) + 0.1
.         min player looses: - 1/(10 + max - min), 1 is minimum
. attention: adjustRanking is known to be negative in certain branches.
*/
{
   if (dayRanking > fabsf(adjustRanking))	{	// I am max
      if (adjustRanking < 0) {			// Gee, lost anyways
         dayRanking = dayRanking - 0.5*(dayRanking + adjustRanking) - 0.1;
         if (dayRanking < 1.0) {
            dayRanking = 1.0;
         } // if
      } else {					// hey, I won
         dayRanking = dayRanking + 1/(10 + dayRanking - adjustRanking);
      } // if
   } else {						// I am min
      if (adjustRanking < 0) {			// pity, I lost
         dayRanking = dayRanking - 1/(10 - adjustRanking - dayRanking);
         if (dayRanking < 1.0) {
            dayRanking = 1.0;
         } // if
      } else {					// Yippie, I won
         dayRanking = dayRanking + 0.6*(adjustRanking - dayRanking) + 0.1;
      }
   } // if
} // adjustDayRanking
       
- (void)setWomanRanking:(long)newWomanRanking;
{
   womanRanking=newWomanRanking;
}

- (void)setPersPriority:(float)aFloat;
// changes the personal priority to add for the player by aFloat.
{
   persPriority = aFloat;
} // setPersPriority

- (void)setDateOfBirth:(NSString *)date;
{
	dateOfBirth=date;
}

- (void)putAsUmpire;
   // put yourself as umpire if umpires are needed
{
   if ([TournamentDelegate.shared.preferences umpires]) {
      [[TournamentDelegate.shared.matchController umpireController] addUmpire:self];
   } // if
}

- (void)removeFromUmpireList;
   // remove yourself from the list of umpires
{
   [[TournamentDelegate.shared.matchController umpireController] removeUmpire:self];
}

- (bool)shouldUmpire;
{
   if ([[TournamentDelegate.shared.matchController umpireController] isUmpire:self]) {
      NSAlert *alert = [[NSAlert alloc] init];
      alert.messageText = NSLocalizedStringFromTable(@"Konflikt!", @"Tournament", null);
		NSString *schiRiEinsatz = NSLocalizedStringFromTable(@"%@ hat noch einen\nSchiedsrichtereinsatz",
																			  @"Tournament", null);
      alert.informativeText = [NSString stringWithFormat:schiRiEinsatz, [self longName]];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Spiel", @"Tournament", null)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Schiedsrichter", @"Tournament", null)];

      return [alert synchronousModalSheetForWindow:[NSApp mainWindow]]  == NSAlertSecondButtonReturn;
   } else {
      return false;
   }
}

- (void)setReady:(BOOL)aFlag;
// set ready-state to aFlag and adjust browser accordingly
{  long i, max = [openMatches count];
	
   ready=aFlag || [self wo] || ![self present];
   if (ready) {
      umpiresMatch = nil;
   } // if
   for(i=0; i<max; i++) {
      if (ready) {
			[[TournamentDelegate.shared.matchController matchBrowser] addMatch:[openMatches objectAtIndex:i]];
      } else {
			id match = [openMatches objectAtIndex:i];
			
			[[TournamentDelegate.shared.matchController matchBrowser] removeMatch:match];
      } // if
   } // for
} // setReady

- (void)setPresent:(BOOL)aFlag;
// set present-state in notPresentController to aFlag
{
   id notPresentController = [TournamentDelegate.shared notPresentController];
   
   if (!aFlag)
   {
      if ([self wo])	// we have to remove the Player from WO if it was
      {
			[notPresentController removeWOPlayer:self];
      } // if
      [notPresentController addNotPresent:self];
   }
   else
   {
      [notPresentController removeNotPresentPlayer:self];
   } // if
} // setPresent

- (void)setWO:(BOOL)aFlag;
// set present-state in notPresentController to aFlag
{
   id notPresentController = [TournamentDelegate.shared notPresentController];
   
   if (aFlag) 
   {
      if ([self present]) // can only be WO if present
      {
         [notPresentController addWO:self];
      } // if
   }
   else
   {
      [notPresentController removeWOPlayer:self];
   } // if
} // setWO

- (NSString *)pName
{
   return name;
} // name

- (NSString *)firstName;
{
   return firstName;
} // firstName

- (NSString *)club;
{
   return club;
} // club

- (NSString *)drawClub;
// return the club used for draw, simple player just its club
{
   return club;
} // club

- (id)partner;
// return nil, no partner (obsolete)
{
   return nil;
} // partner

- (id)umpiresMatch;
// returns the match which is currently umpired (nil if none)
{
   return umpiresMatch;
} // umpiresMatch

- (NSString *)category;
// return the category
{
   return category;
} // category

- (long)licence;
{
   return [_licence longValue];
} // licence

- (NSNumber *)licenceNumber;
{
   return _licence;
}

- (long)ranking;
// return ranking
{
   return ranking;
} // ranking

- (long)rankingInSeries:(id <drawableSeries>)aSeries;
{
	return [self performWithLongResult:[aSeries rankSel]];
}

- (float)dayRanking;
// return dayRanking
{
   return dayRanking;
} // dayRanking

- (long)womanRanking;
// return womanRanking
{
   return womanRanking;
} // womanRanking

- (long)elo;
{
	return elo;
}

- (long)mixedRanking;
{
   if (womanRanking != 0)
      return [self womanRanking];
   else return [self ranking];
}

- (float) tourPriority;
// computes the priority of a player and returns it
{  long i, max = [openMatches count];
   float tp = 0.0;
   
	//printf("%d,", [self licence]);
   for(i=0; i<max; i++)
   {
		Match *match = [openMatches objectAtIndex:i];
		double divisor = 2.0;
		
		if ([[match series] started]) {
			divisor = 1.0;
		}
      tp = tp + [match simpleTourPriority:dayRanking]/divisor;
		//printf("%d, %4.2f,", i, [[openMatches objectAtIndex:i] simpleTourPriority:dayRanking]);
   }
	//printf("%4.2f\n", tp);

   return tp;
} // tourPriority

- (float)persPriority;
// return persPriority
{
   return (float) persPriority;
} // persPriority

- (NSArray *)openMatches;
// return openMatches
{
   return openMatches;
}

- (BOOL)ready;
// returns YES if player is ready or WO or not present (not present players
// must not block matches), NO otherwise
{
   return ready;
} // ready

- (BOOL)present;
// returns YES if player is present at all, NO otherwise
{
   if ([[TournamentDelegate.shared notPresentController] isNotPresent:self])
   {
      return NO;
   }
   else
   {
      return YES;
   } // if
}

- (BOOL)wo;
// returns YES if player gave walk over already, NO otherwise
{
   if ([[TournamentDelegate.shared notPresentController] isWO:self])
   {
      return YES;
   }
   else
   {
      return NO;
   } // if
	return NO;
}

- (bool)attendant;
{
	return [self present] && ![self wo];
}

- (NSString *)sex;
// return sex of the player, determined by womenRanking
{
   if (womanRanking != 0)
   {
      return @"W";
   }
   else
   {
      return @"M";
   } // if
} // sex

- (BOOL)contains:(id <Player>)aPlayer;
// returns YES if self is aPlayer (Protocol method, just too trivial)
{
   return self == aPlayer;
} // contains

- (void)addMatch:(id <Playable>)aMatch;
{
	if ( (aMatch != nil) && (![aMatch finished]) ) {		// do not add finished matches!
		if (![openMatches containsObject:aMatch]) {
			[openMatches addObject:aMatch]; // otherwise append to local list
		}
		if ([[aMatch series] started]) {	// enter match of started series
			[[TournamentDelegate.shared.matchController matchBrowser] addMatch:aMatch];
		}
	}
}

- (void)removeMatch:(id <Playable>)aMatch;
/* in: aMatch:	match to remove from openMatches-list
*/
{
   [openMatches removeObject:aMatch];
} // removeMatch

- (void)finishMatch:(id <Playable>)aMatch;
/*
 Removes the match from the list if present and readies the player if removed. Especially useful for groups.
 */
{
   if ([openMatches containsObject:aMatch]) {
      [self removeMatch:aMatch];
      [self setReady:YES];
   }
}

- (unsigned long) hash
// hash code (currently licence)
{
   return [_licence unsignedLongValue];
} // hash

- (NSString *)longName;
	// long name, use if there is enough space
{
   if (longName == nil)
   {
      [self createLongName];
   } // if

   return longName;
} // longName

- (NSString *)description;
{
   return [self longName];
}

- (NSDictionary*)longNameAttributes {
    return [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Times-Roman" size:longNameHeight] forKey:NSFontAttributeName];
}

- (NSDictionary*)shortNameAttributes {
	return [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Helvetica" size:shortNameHeight] forKey:NSFontAttributeName];
}


- (void)showAt:(float)x yPos:(float)y clPos:(float)clubPos;
// draws the name into the currently lockFocus'ed view at x, y
{
   long i, max = [openMatches count];
   
   [[self longName] drawAtPoint:NSMakePoint(x, y) withAttributes:[self longNameAttributes]];
	[[self club] drawAtPoint:NSMakePoint(x+clubPos, y-longNameHeight)
		withAttributes:[self longNameAttributes]];
   
   if ([TournamentDelegate.shared.preferences otherMatches])
   {
		NSDictionary *smallAttributes=[NSDictionary
			dictionaryWithObject:[NSFont fontWithName:@"Times-Roman" size:6.0]
			forKey:NSFontAttributeName];

      for(i=0; i<max; i++)
      {
			if ([(Series *) [[openMatches objectAtIndex:i] series] seriesName] != nil)
				[[(Series *) [[openMatches objectAtIndex:i] series] seriesName]
					drawAtPoint:NSMakePoint(x+i*20.0, y-12.0) withAttributes:smallAttributes];
      } // for
   } // if
} // showAt

- (void)drawInMatchTableOf:sender x:(float)x y:(float)y;
/* in: x, y:	coordinates in which to draw in currently lockFocused view
 what: draws the name of the Player at x,y in the current view.
*/
{
   const float namePos = 15.0;
   const float clubPos = 115.0;
	NSString *buffer;
	NSDictionary *shortNameAttributes;
	
	if ([sender respondsToSelector:@selector(series)]) {
		buffer=[NSString stringWithFormat:@"%ld", [self rankingInSeries:(Series *)[sender series]]];
	} else {
		buffer = @"";
	}
		
	shortNameAttributes=[self shortNameAttributes];
	
	[buffer drawAtPoint:NSMakePoint(x-10, y) withAttributes:shortNameAttributes];
	
	if ([self longName] != nil) {
		[longName drawAtPoint:NSMakePoint(x+namePos, y) withAttributes:shortNameAttributes];
	}
	if (club != nil) {
		[club drawAtPoint:NSMakePoint(x+clubPos, y) withAttributes:shortNameAttributes];
	}
} // drawInMatchTableOf

- (void)createLongName
{
   longName = [NSString stringWithFormat:@"%@ %@", name, firstName];
} // createLongName

- (void)setShortName:(NSString *)aString;
{
   shortName=aString;
} // setShortName

- (NSString *)shortName;
// short name, no more than 60 pt but still (hopefully) unique.
{
   if (shortName == nil)
   {
      [self createShortName];
   } // if
   
   return shortName;
} // titel

- (void)createShortName;
/* what: initial try, just use as many letters as possible from name
. change: shortName
*/
{
	NSSize stringSize;
	NSRange lastLetter;
	NSMutableString *tempShortName=[NSMutableString stringWithString:[self pName]];
	stringSize=[tempShortName sizeWithAttributes:[self shortNameAttributes]];
	
	lastLetter=NSMakeRange([tempShortName length]-2, 1);
   while(stringSize.height > maxWidth)
   {
		[tempShortName deleteCharactersInRange:lastLetter];
		lastLetter.location--;
      						// the last character != 0
		stringSize=[tempShortName sizeWithAttributes:[self shortNameAttributes]];
   } // while
   shortName = [NSString stringWithString:tempShortName];
} // createShortName

- (BOOL)uniqueShortName:(SinglePlayer *) pl;
/* in: pl:	player with the same shortName as self.
  return: NO if the the players *are* equal, YES if distinction was possible
  what: creates a shortNames for self and for pl which differ.
       The shortName�s for self and pl are set to these.
. uses: letters from firstName, club and licence if necessary.
. caution, this function does not produce globally unique names, just the
  two names in question will not be the same when YES is returned.
  If the function is called with three players alternately, a loop is possible.
*/
{
   NSMutableString *selfName=[[NSMutableString alloc] init];
	NSMutableString *plName=[[NSMutableString alloc] init];		// these strings have to differ
   char selfFirst='\0', plFirst='\0';		// at most two will be used
   char selfSecond='\0', plSecond='\0';		// at most two will be used
   int i;
	NSSize selfSize, plSize;
	NSRange lastNameCharacter;
   
   if ([self isEqual:pl]) return NO;		// the players *are* the same
   [selfName appendFormat:@"%@%@%@", firstName, club , _licence];
   [plName appendFormat:@"%@%@%@", [pl firstName], [pl club], [pl licenceNumber]];
   						// at least the licences differ
   selfFirst = [selfName characterAtIndex:0];			// first letter of firstName
   plFirst = [plName characterAtIndex:0];
   if (selfFirst == plFirst) {						// if the first letters are the same
      i=1;
      while ([selfName characterAtIndex:i] == [plName characterAtIndex:i]) {		// search the first difference
         i++;
      } // while
      selfSecond = [selfName characterAtIndex:i];
      plSecond = [plName characterAtIndex:i];
   } // if
	lastNameCharacter=NSMakeRange([shortName length]-2, 1);
	[selfName setString:shortName];
	[selfName appendFormat:@" %c", selfFirst];
	[plName setString:shortName];
	[plName appendFormat:@" %c", plFirst];
	if (selfFirst == '\0') [selfName appendFormat:@"%c", selfSecond];
	if (selfFirst == '\0') [selfName appendFormat:@"%c", selfSecond];
	selfSize=[selfName sizeWithAttributes:[self shortNameAttributes]];
	plSize=[plName sizeWithAttributes:[self shortNameAttributes]];
   while((selfSize.width > maxWidth) || (plSize.width > maxWidth))
   {
      [selfName deleteCharactersInRange:lastNameCharacter];
		[plName deleteCharactersInRange:lastNameCharacter];
		selfSize=[selfName sizeWithAttributes:[self shortNameAttributes]];
		plSize=[plName sizeWithAttributes:[self shortNameAttributes]];
   } // while
   [self setShortName:[NSString stringWithString:selfName]];
   [pl setShortName:[NSString stringWithString:plName]];
   return YES;
} // uniqueShortName

- (float) seriesPriority:(id <drawableSeries>)series;
// value is used to set gray-level, should be smaller than 0.666 if not 1.0 (black)
{
   float prio = 0.0;
   long i, max = [openMatches count];
   NSString * thisTime = [series startTime];
   
   for(i=0; i<max; i++)
   {
      id match = [openMatches objectAtIndex:i];
      id ser = [match series];
      if (([ser started]) && ([series started]) && (ser != series)
          && ([[ser startTime] compare:thisTime] < 0))
      {
	 prio = (prio + 0.8) / 2.0;
      } // if
   } // for
   
   return prio;
} // seriesProperty

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

- (id)objectFor:(NSString *)identifier;
{
	if ([identifier isEqualToString:@"passNumber"]) {
		return _licence;
	} else if ([identifier isEqualToString:@"name"]) {
		return name;
	} else if ([identifier isEqualToString:@"firstName"]) {
		return firstName;
	} else if ([identifier isEqualToString:@"ranking"]) {
		return [NSNumber numberWithLong:ranking];
	} else if ([identifier isEqualToString:@"womanRanking"]) {
		return [NSNumber numberWithLong:womanRanking];
	} else if ([identifier isEqualToString:@"elo"]) {
		return [NSNumber numberWithLong:elo];
	} else if ([identifier isEqualToString:@"sex"]) {
		return (womanRanking != 0)?@"W" :@"M";
	} else if ([identifier isEqualToString:@"club"]) {
		return club;
	} else if ([identifier isEqualToString:@"category"]) {
		return category;
	} else if ([identifier isEqualToString:@"dateOfBirth"]) {
		return dateOfBirth;
	} else {
		return @"dummy";
	}
}

- (void)setObject:(id)anObject for:(NSString *)identifier;
{
	if ([identifier isEqualToString:@"passNumber"]) {
      NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
      formatter.numberStyle = NSNumberFormatterDecimalStyle;
      _licence=[formatter numberFromString:(NSString *)anObject];
	} else if ([identifier isEqualToString:@"name"]) {
		name = (NSString *)anObject;
	} else if ([identifier isEqualToString:@"firstName"]) {
		firstName = (NSString *)anObject;
	} else if ([identifier isEqualToString:@"ranking"]) {
		ranking=[(NSString *)anObject longLongValue];
	} else if ([identifier isEqualToString:@"womanRanking"]) {
		womanRanking=[anObject longLongValue];
	} else if ([identifier isEqualToString:@"elo"]) {
		elo=[anObject longLongValue];
	} else if ([identifier isEqualToString:@"club"]) {
		club = (NSString *)anObject;
	} else if ([identifier isEqualToString:@"category"]) {
		category = (NSString *)anObject;
	} else if ([identifier isEqualToString:@"dateOfBirth"]) {
		dateOfBirth = (NSString *)anObject;
	}
}

- (void)storeInDatabase;
{
   if (validLicence) {
      [self updateDatabase];
   } else {
      [self insertIntoDatabase];
   }
}

+ (NSString *) allFields;
{
   if (allFields == nil) {
      NSArray *fields = [NSArray arrayWithObjects:SPFields.Licence, SPFields.Name, SPFields.FirstName, SPFields.Category, SPFields.Club, SPFields.DateOfBirth, SPFields.Ranking, SPFields.WomanRanking, SPFields.EloPoints, nil];
      allFields = [fields componentsJoinedByString:@", "];
   }
   return allFields;
}


- (void)insertIntoDatabase;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *insertPlayer = [NSString stringWithFormat:@"INSERT INTO Player (%@) VALUES (%@, '%@', '%@', '%@', '%@', '%@', %ld, %ld, %ld)", [SinglePlayer allFields], _licence, [name sqlEscaped], [firstName sqlEscaped], category, [club sqlEscaped], dateOfBirth, ranking, womanRanking, elo];
   _isNew=NO;
   _isEdited=NO;
   if ([database execCommand:insertPlayer]) {
      validLicence=YES;
   } else {
      NSLog(@"Insert Player error: %@ for command [%@]", [database errorDescription], insertPlayer);
   }
}

- (void)updateDatabase;
{
   NSString *updatePlayer = [NSString stringWithFormat:@"UPDATE Player SET %@='%@', %@='%@', %@='%@',%@='%@', %@='%@', %@=%ld, %@=%ld, %@=%ld WHERE %@=%@", SPFields.Name, [name sqlEscaped], SPFields.FirstName, [firstName sqlEscaped], SPFields.Category, category, SPFields.Club, [club sqlEscaped], SPFields.DateOfBirth, dateOfBirth, SPFields.Ranking, ranking, SPFields.WomanRanking, womanRanking, SPFields.EloPoints, elo, SPFields.Licence, _licence];
   PGSQLConnection *database=TournamentDelegate.shared.database;

   if ([database execCommand:updatePlayer]) {
      _isEdited=NO;
   } else {
      NSLog(@"DB command %@, somehow went wrong", updatePlayer);
   }
}

- (bool)canContinue;
{		// SinglePlayers may always continue
   return YES;
}

- (long) numberOfDependentMatches;
{
   return [openMatches count];
}

- (void)appendAsHTMLRowTo:(NSMutableString *)html forSeries:(id <drawableSeries>) series;
{
   [html appendString:@"<tr><td></td><td>"];
   [html appendFormat:@"%@ %@", [self pName], [self firstName]];
   [html appendString:@"</td>"];
   [html appendString:@"<td>"];
   [html appendString:[self club]];
   [html appendString:@"</td>"];
   [html appendString:@"<td align=\"right\">"];
   [html appendFormat:@"%ld", [self rankingInSeries:series]];
   [html appendString:@"</td>"];
   [html appendString:@"<td></td></tr>\n"];
}

- (bool)hasRealPlayers;
{
	return true;
}

-(NSString *)rv;
{
	return @"not implemented";
}

- (NSString *)clickId:(id <drawableSeries>)series;
{
	return [NSString stringWithFormat:@"%@_%ld", [series seriesName], [self licence]];
}
	 
- (void)appendPersonXmlTo:(NSMutableString *)text;
{
	[text appendFormat:@"    <person licence-nr=\"%ld\" club-federation-nickname=\"%@\"\n", [self licence], [self rv]];
	[text appendFormat:@"     club-name=\"%@\" internal-nr=\"NU?????\" nationality=\"SUI\" elo=\"%ld\"\n", [self club], [self elo]];
	[text appendFormat:@"     firstname=\"%@\" club-nr=\"????\"\n", [self firstName]];
	[text appendFormat:@"     classification=\"%ld\"\n", [self ranking]];
	[text appendFormat:@"     lastname=\"%@\" birthdate=\"1970-01-01\" />\n", [self pName]];
}

- (void)appendPlayerXmlTo:(NSMutableString *)text forSeries:(id <drawableSeries>)series;
{
	[text appendFormat:@"   <player type=\"single\" id=\"%@\" team-name=\"%@\">\n", [self clickId:series], [self longName]];
	[self appendPersonXmlTo:text];
	[text appendString:@"   </player>\n"];
	
}
- (NSString *)rankingListLines:(NSString *)rankStr;
{
	return [NSString stringWithFormat:RANKING_LINE_FORMAT, rankStr, longName, club];
}

@end
