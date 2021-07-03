/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
          18.2.95, Patru: improved checking, new drawing scheme
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "SimpleGroupSeries.h"
#import "DoublePlayer.h"
#import "DoubleSeries.h"
#import "SeriesPlayer.h"

@implementation SimpleGroupSeries

- (BOOL)newGroupDraw;
	/* performs a drawing for groups. All players play in groups of up
   to usualGroupSize players (no more than 3 groups will have 3 players).
   They are just distributed in order.
	*/
{
   long i, max = [players count];
	long numberOfGroups = (max + usualGroupSize - 1)/usualGroupSize;
   NSMutableArray *matches = [NSMutableArray array];		// for numbering
	NSMutableArray *playerLists[numberOfGroups];

   groups = [[NSMutableArray alloc] init];		// there will be groups
	
	for(i = 0; i < numberOfGroups; i++)
	{
		[groups addObject:[[Group alloc] initSeries:self number:i+1]];
		playerLists[i] = [NSMutableArray array];
	}
		
   /*********************   distribute players in groups   **************/

	for (i=0; i < max; i++) {
		long index = i%numberOfGroups;

		if ((i/numberOfGroups)%2 == 1) {		// reverse for every second round
			index = numberOfGroups-1-index;
		}
		[playerLists[index] addObject:[[players objectAtIndex:i] player]];
	}

	[players removeAllObjects];
	
	for(i = 0; i < numberOfGroups; i++)
	{
		[[groups objectAtIndex:i] setPlayers:playerLists[i]];
      [players addObject:[[SeriesPlayer alloc] initGroup:[groups objectAtIndex:i]
																position:1]];
	}
   for(i=numberOfGroups-1; i>= 0; i--)
		// reverse order, second place is best at the end.
   {
      [players addObject: [[SeriesPlayer alloc] initGroup:[groups objectAtIndex:i]
																 position:2]];
   } // for
	
   /*********************   init GroupPlayers   ****************************/

   [super doSimpleDraw];		// now simple Draw will be good

   for(i=0; i<numberOfGroups; i++)
   {
      [[groups objectAtIndex:i] finishedDrawing];
   } // for

   [matches addObject:matchTable];		// insert match to start from
   numberAllMatches(matches);
	[matches removeAllObjects];

   return YES;
} // doGroupDraw

@end

