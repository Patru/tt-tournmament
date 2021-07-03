/*****************************************************************************
 Use: Control a table tennis tournament (as part of Tournament.app)
 Controls a single group series with consolation round and readily made groups.
 Language: Objective-C                 System: Mac OS X
 Author: Paul Trunz, Copyright 2013, Soft-Werker GmbH
 Version: 0.2, first try
 History: 24.1.2013, Patru: first written
          12.5.2013, Patru: added player confirmation
 Bugs: -not very well documented :-)
 *****************************************************************************/
#import <Cocoa/Cocoa.h>
#import "ConsolationGroupSeries.h"

@interface ConsolationGroupedSeries : ConsolationGroupSeries {
	NSMutableArray *confirmedPlayers;
}

- (BOOL)makeGroups;
// assume all the groups to already have been made (Schüeli-style)
- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;
- (void)confirmPlayer:(SeriesPlayer *)serPlayer;
- (NSMutableArray *)confirmedPlayers;

@end
