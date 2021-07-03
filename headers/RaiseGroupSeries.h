/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 4.2.96, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "GroupSeries.h"

@class RaisePlayer;		// importing does not work (circular)

@interface RaiseGroupSeries:GroupSeries
{
   NSString *raiseIntoSeriesName;	// Best players will raise into this series
   NSMutableArray  *raisingPlayers;	// List of RaisingPlayers, where will they go
   long    numRaising;		// This many players will raise
   long    firstSetPos;		// players will be set starting here
   BOOL   raised;		// YES if the players have been raised
} 

- (void)endSeriesProcessing:sender;
- (void)addRaisingPlayer:(RaisePlayer *)aPlayer;
- (NSMutableArray *)positions;

@end
