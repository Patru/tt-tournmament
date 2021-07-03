/*****************************************************************************
     Use: Control a table tennis tournament.
          Two Players to form a double.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 14.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "SinglePlayer.h"

@interface DoublePlayer:NSObject <Player>
{
   SinglePlayer  *player;		// first player
   SinglePlayer  *partner;		// second player
   NSString *longName;		// combine two short names
   NSString *clubName;		// combine if necessary
}

- init;
- initDouble:(SinglePlayer *)firstPlayer partner:(SinglePlayer *)secondPlayer;
- setPlayer:(SinglePlayer *)aPlayer;
- setPartner:(SinglePlayer *)aPlayer;
- (BOOL) contains:(id <Player>)aPlayer;
- (void)adjustDayRanking:(float)adjustRanking;
- (SinglePlayer *)player;
- (SinglePlayer *)partner;
- (float) seriesPriority:series;
- (id <InspectorControllerProtocol>) inspectorController;

- (NSDictionary*)shortNameAttributes;
- (NSDictionary*)longNameAttributes;

@end
