/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a group of a YCI-series.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 6.3.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Group.h"

#define INT_GROUP_PLAYERS 6
// standardmethods

@interface IntGroup:Group <Playable>
{
/*   NSString * wins[INT_GROUP_PLAYERS];		// indexed by originalPlayers
   NSString * sets[INT_GROUP_PLAYERS];
   NSString * points[INT_GROUP_PLAYERS];
   NSString * rank[INT_GROUP_PLAYERS];
*/
   NSMutableArray *originalPlayers;
}

- drawGroupIn:(NSRect)aFrame playerHeight:(float)playerHeight
  matchHeight:(float)matchHeight;
- matchSheet:sender :(const NSRect *)rects :(int)rectCount;
   // draw the sheet for use at the table
- keepResultOf:(id<Player>)pl rank:(int)aRank wins:(int)aWins
      setsPlus:(int)setsp minus:(int)setsm pointsPlus:(int)pointsp minus:(int)pointsm;

@end
