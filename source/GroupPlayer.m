/*****************************************************************************
     Use: Control a table tennis tournament.
          Linking object from a place in a group to a place in the table.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 10.4.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import "GroupPlayer.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

int groupPlayerID=0;

@implementation GroupPlayer
/* Intermediate object to model the place where a player will go once
   all matches of a group are finished */

- (instancetype)init;
// all default initialization
{
   self=[super init];
   group = NULL;
   position = 0;
   identifier = [[NSNumber alloc] initWithInt:++groupPlayerID];
   return self;
} // init

- (instancetype)initGroup:(Group *)aGroup position:(long)aPosition;
// init for aGroup and aPosition, no Match yet
{
   self=[super init];
   group = aGroup;
   position = aPosition - 1;		// List starts at 0, but the show will be 1
   [aGroup addPosition:self];
   identifier = [[NSNumber alloc] initWithInt:++groupPlayerID];
   return self;
} // initGroup

- group;
// return the group of self.
{
   return group;
} // group

- player;
// return the represented player
{
	if ((group != nil) && ([[group players] count] > position)) {
		id<Player> player = [[group players] objectAtIndex:position];
		
		if (![group finished] || [player attendant]) {
			return player;
		}
	}
	
	return nil;
} // player

- (NSString *)pName;
// returns a players name if the group is played, Group and position otherwise
{
	if(group) {
		if([group finished]) {
			id<Player> player = [self player];
			
			if (player != nil) {
				return [player pName];
			} else {
				return @"abwesend";
			}
		} else {
			return [NSString stringWithFormat:@"%@ Platz %ld", [group description], position + 1];
		} // if
	} // if
	return @"";
} // pName

- (NSString *)firstName;
// returns a players first name if the group is played, empty string otherwise
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] firstName];
   } else {
      return @"";
   } // if
} // firstName

- (NSString *)club;
// returns the club of the player in group at position (group is played or
// nonplayed). Empty string otherwise. Used for drawing the table
{
   id<Player> player = [self player];

   if (player != nil) {
      return [player club];
   } else {
      return @"";
   } // if
} // club

- (NSString *)drawClub;
// returns the drawClub of the player in group at position (group is played or
// nonplayed). Empty string otherwise. Used for drawing the table
{
   if((group) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] drawClub];
   } else {
      return @"";
   } // if
} // drawClub

- (NSString *)category;
/* returns the category of the player in group at position (group is played or
 nonplayed). Empty String otherwise. */
{
   if((group) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] category];
   } else  {
      return @"";
   } // if
} // category

- (NSNumber *)licenceNumber;
// uniquely identifies the groupPlayer for ranking
{
   return identifier;
} // licence

- (long)licence;
{
   return [[self licenceNumber] intValue];
}

- (long)rankingInSeries:(id <drawableSeries>)aSeries;
{
   return [self performWithLongResult:[aSeries rankSel]];
}

- (long)ranking;
// returns a players ranking if the group there is a player at position,
// 0 otherwise
{
   if((group) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] ranking];
   } else {
      return (long)position;	// nonplayed: position as ranking!
   } // if
} // ranking

- (float)dayRanking;
// returns a players dayRanking if the group there is a player at position,
// 0 otherwise
{
   if((group) && ([[group players] count] > position)) {
      return (float)[[[group players] objectAtIndex:position] dayRanking]
             + (10.0 - position) / 100;		// correction for place, small
   } else {
      return (float)position;	// nonplayed: position as ranking!
   } // if
} // dayRanking

- (long)womanRanking;
// returns a players womanRanking if the group is played, 0 otherwise
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] womanRanking];
   } else {
      return 0;
   } // if
} // womanRanking

- (long)mixedRanking;
	// returns a players womanRanking if the group is played, 0 otherwise
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] mixedRanking];
   } else {
      return 0;
   } // if
}

- (long)elo;
// returns a players Elo points if the group is played, 0 otherwise
{
	if((group) && ([group finished]) && ([[group players] count] > position)) {
		return [[[group players] objectAtIndex:position] elo];
	} else {
		return 0l;
	} // if
}

- (float) tourPriority;
// returns a players tourPriority if the group is played, 0.0 otherwise
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] tourPriority];
   } else {
      return 0.0;
   } // if
} // tourPriority

- (BOOL)ready;
// returns the players ready-state if the group is played, NO otherwise
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] ready];
   } else {
      return 0;
   } // if
} // ready

- (NSString *)longName;
{
	if(group) {
		if ([group finished]) {
			id<Player> player = [self player];
			
			if (player != nil) {
				return [player longName];
			} else {
				return @"abwesend";
			}
		} else {
			if ([TournamentDelegate.shared.preferences tourNumbers]) {
				return [self shortName];
			} else {
				if ([TournamentDelegate.shared.preferences groupLetters]) {
					return [NSString stringWithFormat:@"%ld. Platz Gruppe %c", position + 1, (char)('A' + [group number] - 1)];
				} else {
					return [NSString stringWithFormat:@"Gruppe %ld Platz %ld", [group number], position + 1];
				} // if
			}
		}
	}
	
	return @"";
} // longName

- (NSString *)shortName;
// similar to pName, but a shorter string is returned
{
	if(group) {
		if([group finished]){
			id<Player> player = [self player];
			
			if (player != nil) {
				return [player shortName];
			} else {
				return @"abwesend";
			}
		} else {
			if ([TournamentDelegate.shared.preferences groupLetters]) {
				// if we use letters to indicate groups then we use an especially short string
				return [NSString stringWithFormat:@"%ld%c", position + 1, (char)('A' + [group number] - 1)];
			} else {
				return [NSString stringWithFormat:@"G %ld P %ld", [group number], position + 1];
			} // if
		} // if
	} // if
	return @"";
} // shortName

- (void)setReady:(BOOL)flag;
// sets the ready-state of the player to flag if the group is played
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      [[[group players] objectAtIndex:position] setReady:flag];
   }
} // setReady

- (void)setPresent:(BOOL)aFlag;
// does nothing since it should not be called
{
} // setPresent

- (void)setWO:(BOOL)aFlag;
// does nothing since it should not be called
{
} // setWO

- (BOOL)contains:(id <Player>)aPlayer;
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return ([[group players] objectAtIndex:position] == aPlayer);
   } else {
      return NO;
   } // if
} // contains
   
- (void)addMatch:(id <Playable>)aMatch;
/* Stores the Match in which the player at position will play.
   When the group is finished, the GroupPlayer will free itself(?) after
   putting its player in aMatch.
*/
{
	if (aMatch != nil) {		// we do not give up a given match reference for nothing (especially final in single group series)
		match = (Match *)aMatch;
	}
} // addMatch

- (void)putAsUmpire;
// purposefully does nothing, GroupPlayer will never umpire, just for protocol.
{
}

- (void)removeFromUmpireList;
   // dummy, GroupPlayers will never umpire
{
}

- (void)setPersPriority:(float)aFloat;
// adjust priority of the player, just forward it.
{
   [[[group players] objectAtIndex:position] setPersPriority:aFloat];
} // setPersPriority

- (void)showAt:(float)x yPos:(float)y clPos:(float)clubPos;
// draws the name into the currently lockFocus'ed view at x, y
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      [[[group players] objectAtIndex:position] showAt:x yPos:y clPos:clubPos];
   } else {
      [[self longName] drawAtPoint:NSMakePoint(x, y) withAttributes:[GroupPlayer textAttributes]];
   } // if
} // showAt

- (void)drawInMatchTableOf:sender x:(float)x y:(float)y
/* in: x, y: coordinates in which to draw in currently lockFocused view
 what: draws the name of the GroupPlayer at x,y in the current view.
 */
{
	const float namePos = 15.0;
	
	if ([group finished]) {
		[[self player] drawInMatchTableOf:sender x:x y:y];
	} else if ([self longName]) {
		[[self longName] drawAtPoint:NSMakePoint(x + namePos, y)
									withAttributes:[GroupPlayer textAttributes]];
	}
	
} // drawInMatchTableOf

- (void)setFinished;
/* what: sent by the group when its finished. This is the point for the
         GroupPlayer to cease to exist. This is performed here, after the
	 player is put in the match.
*/
{
   if((group) && ([group finished]) && ([[group rankingList] count] > position)) {
		[match replacePlayer:self by:(id<Player>)[[group rankingList] objectAtIndex:position]];
      [[group series] removePlayer:self];
   } else {
      [match checkForWO];
   }
} // setFinished

- (void)removeMatch:(id <Playable>)aMatch;
// dummy, shold not be used on GroupPlayers
{
} // removeMatch

- (void)finishMatch:(id <Playable>)aMatch;
/*
 Dummy, GroupPlayers should never actually play groups, must be replaced before
 */
{
}

- (float) seriesPriority:(id <drawableSeries>)series;
// value is used to set gray-level, should be smaller than NX_LTGRAY
{
   if((group) && ([group finished]) && ([[group players] count] > position))
   {
      return [[[group players] objectAtIndex:position] seriesPriority:series];
   } // if
   else return 0;
} // seriesPriority

- (long)performWithLongResult:(SEL)aSelector;
// uses invocation to dynamically call aSelector with the correct return type
// (this ordeal will be greatly simplified in Swift using pointers to methods.)
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
   [encoder encodeObject:group];
   [encoder encodeObject:match];
   [encoder encodeValueOfObjCType:@encode(int) at:&position];
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self=[super init];
   group = [decoder decodeObject];
   match = [decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(int) at:&position];

   return self;
}

- (void)adjustDayRanking:(float)adjustRanking;
{
   // will only end up here if someone has been missing, safely ignored
}

- (BOOL)present;
// returns YES if the player is present, NO otherwise
{
   if((group) && ([group finished])) {
      id<Player> player = [self player];

      return player != nil;
	 // after a group has been finished this is a little special!
   } else {
      return ([[group players] count] > position); 
   } // if
} // present
      
- (BOOL)wo;
// returns YES if the player has given walk over, NO otherwise
{
   if((group) && ([group finished]) && ([[group players] count] > position)) {
      return [[[group players] objectAtIndex:position] wo];
   } else {
      return NO; 
   } // if
} // wo

- (bool)attendant;
{
	return [self present] && ![self wo];
}

- (bool)shouldUmpire;
{		// group players never umpire
   return false;
}

+ (NSDictionary*)textAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Helvetica" size:stringsize] forKey:NSFontAttributeName];
}

- (bool)canContinue;
{		// GroupPlayers may continue once the group is finished
   return (group != nil) && [group finished];
}

- (long) numberOfDependentMatches;
{
   return 0;
}

- (float)numRoundPriority;
{
	return [match numRoundPriority];
}

- (bool)hasRealPlayers;
{
	return false;
}

- (NSString *)clickId:(id <drawableSeries>)series;
{
	return @"N/A";
}

- (void)appendPlayerXmlTo:(NSMutableString *)text forSeries:(id <drawableSeries>)series;
{		// do not have a player to export
}

- (NSString *)rankingListLines:(NSString *)rankStr;
{
	return @"Should never appear in a ranking list\n";
}
@end
