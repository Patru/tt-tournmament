/*****************************************************************************
     Use: Control a table tennis tournament.
          Linking object from a place in a group to a place in the table.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 10.4.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "Player.h"
#import "Group.h"
#import "Match.h"

@interface GroupPlayer:NSObject <Player>
{
   Group  *group;		// the group of the player
   id <Playable>  match;		// the match in which someone will play
   long     position;		// the position of the someone
   NSNumber *identifier;
}

- (instancetype)init;
- (instancetype)initGroup:(Group *)aGroup position:(long)aPosition;
- group;
- player;
- (long)mixedRanking;
- (long)elo;
- (void)setFinished;
- (float)numRoundPriority;
+ (NSDictionary*)textAttributes;
@end
