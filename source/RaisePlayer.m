/*****************************************************************************
     Use: Control a table tennis tournament.
          Linking object from a place in one Series to a place in another.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 10.4.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import "RaisePlayer.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

#define shortNameHeight 9.0

@implementation RaisePlayer
/* Intermediate object to model the place where a player will go once
   all matches of a group are finished */

- (instancetype)init;
// all default initialization
{
   self=[super init];
   series = nil;
   position = 0;
   return self;
} // init

- (instancetype)initSeries:(RaiseGroupSeries *)aSeries position:(long)aPosition;
// init for aSeries and aPosition, no Match yet
{
   self=[super init];
   series = aSeries;
   position = aPosition - 1;		// List starts at 0
   [aSeries addRaisingPlayer:self];
   return self;
} // initGroup

- (void)setSeries:(RaiseGroupSeries *)aSeries position:(long)aPosition;
// sets group and position of self, not the match
{
   if(series != nil)
   {
      [[series positions] removeObject:self];
   } // if
   series = aSeries;
   position = aPosition - 1;
   [aSeries addRaisingPlayer:self];
} // setGroup

- (Series *)series;
// return the group of self.
{
   return series;
} // group

- (id<Player>)player;
// no useful player to return, always returns nil
{
   return nil;
} // player

- (NSString *)pName;
// returns a players name if the group is played, Group and position otherwise
{
   if(series)
   {
      return [NSString stringWithFormat:@"%@ Rang %ld", [series fullName], position + 1];
   } // if
   return @"";
} // pName

- (NSString *)firstName;
// always the empty string
{
   return @"";
} // firstName

- (NSString *)club;
// always the empty string
{
   return @"";
} // club

- (NSString *)drawClub;
// always uses the empty string for raising players, set by hand anyway.
{
   return @"";
} // club

- (NSString *)category;
// always the empty string
{
   return @"";
} // category

- (long)licence;
// nothing useful possible, always 0
{
   return 0;
} // licence

- (long)ranking;
// nothing useful possible, always 0
{
   return 0;
} // ranking

- (float)dayRanking;
// nothing useful possible, always 0
{
   return 0.0;
} // dayRanking

- (long)womanRanking;
// nothing useful possible, always 0
{
   return 0l;
} // womanRanking

- (float) tourPriority;
// nothing useful possible, always 0
{
   return 0.0;
} // tourPriority

- (BOOL)ready;
// RaisePlayers are never ready, always NO
{
   return NO;
} // ready

- (NSString *)longName;
// similar to pName, but for longName
{
   if(series) {
      if ([TournamentDelegate.shared.preferences tourNumbers]) {
	 return [NSString stringWithFormat:@"%@ R %ld", [series seriesName], position + 1];
      } else {
	 return [NSString stringWithFormat:@"%@ Rang %ld", [series fullName], position + 1];
      }
   } // if
   return @"";
} // longName

- (NSString *)shortName;
// similar to pName, but a shorter string is returned
{
   if(series)
   {
      return [NSString stringWithFormat:@"%@%ld", [series fullName], position + 1];
   } // if
   return @"";
} // shortName

- (void)setReady:(BOOL)flag;
// dummy, RaisePlayers are never ready
{
} // setReady

- (BOOL)contains:(id <Player>)aPlayer;
// RaisePlayers do not (yet) contain anybody, always NO
{
   return NO;
} // contains
   
- (void)addMatch:(id <Playable>)aMatch;
/* Stores the Match in which the player at position will play.
   When the group is finished, the RaisePlayer will become obsolete after
   putting its player in aMatch.
*/
{
   match = (Match *)aMatch;
} // addMatch

- (void)putAsUmpire;
   // dummy, does nothing, not possible for RaisePlayer, protocol.
{
}

- (void)removeFromUmpireList;
   // dummy, RaisePlayer cannot umpire.
{
}

- (void)setPersPriority:(float)aFloat;
// dummy, makes no sense for RaisePlayer, just for protocol.
{
} // setPersPriority

- (void)showAt:(float)x yPos:(float)y clPos:(float)clubPos;
// draws the name into the currently lockFocus'ed view at x, y
{
   if ([self longName]) {
      [[self longName] drawAtPoint:NSMakePoint(x, y)
         withAttributes:[self shortNameAttributes]];
   }
} // showAt

- (void)drawInMatchTableOf:sender x:(float)x y:(float)y 
/* in: x, y: coordinates in which to draw in currently lockFocused view
 what: draws the name of the GroupPlayer at x,y in the current view.
 */
{
   const float namePos = 15.0;
   
   if ([self longName]) {
      [[self longName] drawAtPoint:NSMakePoint(x + namePos, y)
         withAttributes:[self shortNameAttributes]];
   }
} // drawInMatchTableOf

- (void)fillWithPlayer:(SinglePlayer *)aPlayer;
/* what: sent by the series when its finished. This is the point for the
         RaisePlayer to cease to exist. This is performed here, after the
	 player is put in the match.
*/
{
   if([match upperPlayer] == self) {
      [[match upperMatch] setWinner:aPlayer];
   }
   else if ([match lowerPlayer] == self) {	// just for security
      [[match lowerMatch] setWinner:aPlayer];
   } // if
   else fprintf(stderr, "Falscher Match!"); // hopefully not necessary
} // fillWithPlayer

- (void)removeMatch:(id <Playable>)aMatch;
// dummy, should not be used on RaisePlayers
{
} // removeMatch

- (void)finishMatch:(id <Playable>)aMatch;
/*
   Dummy, RaisePlayers should never actually play groups, must be replaced before
 */
{
}

- (float) seriesPriority:(id <drawableSeries>)series;
// value is used to set gray-level, should be smaller than NX_LTGRAY
// always 0 for RaisePlayer
{
   return 0;
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
   [encoder encodeObject:series];
   [encoder encodeObject:match];
   [encoder encodeValueOfObjCType:@encode(int) at:&position];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
   self=[super init];
   series=[decoder decodeObject];
   match=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(int) at:&position];
   
   return self;
}

- (BOOL)present;
// returns YES, RaisePlayers are always there
{
   return YES;
} // present

- (void)setWO:(BOOL)aFlag;
// does nothing since it should not be called
{
} // setWO

- (void)setPresent:(BOOL)aFlag;
// does nothing since it should not be called
{
} // setPresent

- (BOOL)wo;
// always returns NO, never walk over a RaisePlayer!
{
   return NO;
} // wo

// this actually means "not known to be absent and not having lost his last match in a walk over"
- (bool)attendant;
{
   return [self present] && ![self wo];
}

- (long)rankingInSeries:(id <drawableSeries>)aSeries;
{
	return [self performWithLongResult:[aSeries rankSel]];
}

- (bool)shouldUmpire;
{		// raise players never umpire
   return false;
}

- (NSNumber *)licenceNumber;
{
   // must be unique within series, well, this is unique within process
   return [NSNumber numberWithLong:(long)self];
}

- (NSDictionary*)shortNameAttributes;
{
	return [NSDictionary dictionaryWithObject: [NSFont fontWithName:@"Helvetica" size:shortNameHeight] forKey:NSFontAttributeName];
}

- (bool)canContinue;
{		// RaisePlayers may continue once the series is finished
   return (series != nil) && [series finished];
}

- (long) numberOfDependentMatches;
{
   return 0L;
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

- (void)adjustDayRanking:(float)adjustRanking;
{
   // strange things have to happen for this to be called, safely ignored
}

@end
