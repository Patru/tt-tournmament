/*****************************************************************************
     Use: Control a table tennis tournament.
          Linking object from a place in one Series to a place in another.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1996
 Version: 0.1, first try
 History: 4.2.1996, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Match.h"
#import "SinglePlayer.h"
#import "RaiseGroupSeries.h"
#import "Series.h"

@interface RaisePlayer:NSObject <Player>
{
   RaiseGroupSeries *series;	// the series from which the player will come
   Match  *match;		// the match in which someone will play
   long     position;		// the position of the someone in his series
}

- (instancetype)init;
- (instancetype)initSeries:(RaiseGroupSeries *)aSeries position:(long)aPosition;
- (void)setSeries:(RaiseGroupSeries *)aSeries position:(long)aPosition;
- (Series *)series;
- (id<Player>)player;
- (void)fillWithPlayer:(SinglePlayer *)aPlayer;
- (NSDictionary*)shortNameAttributes;

//- write: (NXTypedStream *) s;
//- read: (NXTypedStream *) s;

@end
