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
#import <PGSQLKit/PGSQLKit.h>
#import "GroupSeries.h"

@interface DoubleGroupSeries:GroupSeries
{
   NSMutableDictionary *doublePartner;	// the partner of a player
   NSMutableArray *singles;		// a List of single players registered
}

- (instancetype)init;
- (instancetype)initFromRecord:(PGSQLRecord *)record;
- (BOOL)doGroupDraw;

@end
