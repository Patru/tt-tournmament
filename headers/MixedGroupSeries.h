/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "GroupSeries.h"

@interface MixedGroupSeries:GroupSeries
{
   NSMutableDictionary *doublePartner;	// the partner of a player
   NSMutableArray *menSingles;		// a List of single male players registered
   NSMutableArray *womenSingles;		// a list of singel female players registered
}

- (instancetype)initFromRecord:(PGSQLRecord *)record;
- (BOOL)doGroupDraw;

@end
