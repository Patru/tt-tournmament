/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a mixed double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 16.2.95, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Series.h"

@interface MixedSeries:Series
{
   NSMutableDictionary *doublePartner;	// the partner of a player
   NSMutableArray *menSingles;		// a List of single male players registered
   NSMutableArray *womenSingles;		// a list of singel female players registered
} 

@end