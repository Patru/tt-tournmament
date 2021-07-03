/*****************************************************************************
     Use: Control a table tennis tournament.
          Stores the player(s) who form a team for in a series.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 14.5.1994, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "Group.h"
#import "RaiseGroupSeries.h"
#import "SinglePlayer.h"

@interface SeriesPlayer:NSObject <NSCoding>
{
   id<Player>    player;		// player
   long  setNumber;	// set as Number
}

// standardmethods

- init;
- initPlayer:(id<Player> )aPlayer setNumber:(long)aLong;
- initDouble:(id<Player> )firstPlayer partner:(id<Player> )secondPlayer setNumber:(long)aLong;
- initGroup:(Group *)aGroup position:(long)aPosition;
- initRaise:(RaiseGroupSeries *)aSeries position:(long)aPosition setNumber:(long)aSetNumber;
- (id<Player>)player;
- (long)setNumber;
- (BOOL)isStronger:(SeriesPlayer *)aSerPlayer sender:sender;
// sender must respondTo rankSel and return the selector for ranking
- setPlayer:(id<Player>)aPlayer;
- setSetNumber:(long)aLong;

- (void)appendAsHTMLRowTo:(NSMutableString *)html position:(long)position forSeries:(Series *)series;
- (void)appendAsXmlTo:(NSMutableString *)text forSeries:(Series *)series;

@end
