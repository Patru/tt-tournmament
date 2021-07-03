/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a group series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
          18.2.95, Patru: improved checking, new drawing scheme
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "GroupPlayer.h"
#import "RaiseGroupSeries.h"
#import "Match.h"
#import "RaisePlayer.h"
#import "SeriesController.h"
#import "SeriesPlayer.h"
#import "TournamentController.h"
#import "TournamentView.h"
#import "Tournament-Swift.h"

@implementation RaiseGroupSeries
/* Controls a group series of a tournament. This includes mainly table-
   and group generation. */

-(instancetype)init
{
   self=[super init];
   raiseIntoSeriesName = @"";
   raisingPlayers = [[NSMutableArray alloc] init];
   numRaising = 0;
   firstSetPos = 0;
   raised = NO;
   return self;
} // init

- (instancetype)initFromRecord:(PGSQLRecord *)record;
{
   char ser[10], buf[40];
   
   self=[super initFromRecord:record];
   sscanf([fullName UTF8String], "%ld %s %ld %[^\n]", &numRaising, ser, &firstSetPos, buf);
   raiseIntoSeriesName = [[NSString alloc] initWithUTF8String:ser];
   // TODO: verify that this series exists (after loading all of them)
   raisingPlayers = [[NSMutableArray alloc] init];
   [self setFullName:[NSString stringWithUTF8String:buf]];
   
   return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeObject:raiseIntoSeriesName];
   [encoder encodeObject:raisingPlayers];
   [encoder encodeValueOfObjCType:@encode(int)  at:&numRaising];
   [encoder encodeValueOfObjCType:@encode(int)  at:&firstSetPos];
   [encoder encodeValueOfObjCType:@encode(char) at:&raised];
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super initWithCoder:decoder];
   raiseIntoSeriesName=[decoder decodeObject];
   raisingPlayers=[decoder decodeObject];
   [decoder decodeValueOfObjCType:@encode(int)  at:&numRaising];
   [decoder decodeValueOfObjCType:@encode(int)  at:&firstSetPos];
   [decoder decodeValueOfObjCType:@encode(char) at:&raised];
   
   return self;
}

- (void)cleanup;
// do some cleanup before newly loading players
// (should we really remove the positions here?)
{
   [super cleanup];
   [positions removeAllObjects];
} // cleanup

- (BOOL)makeTable
/* ret: YES if the series was drawn correctly (or has aleready been so)
  what: draws the series according using the group draw defined in here
        (CAUTION: that one uses doSimpleDraw)
*/
{  int i;
   RaiseGroupSeries *ser = (RaiseGroupSeries *)[[TournamentDelegate.shared seriesController]
                                              seriesWithName:raiseIntoSeriesName];

   alreadyDrawn = [self newGroupDraw];
   [self numberKoMatches];   
   for(i=0; i<numRaising; i++)
   {
      [ser addSeriesPlayer:[[SeriesPlayer alloc] initRaise:self
			 position:i+1 setNumber:i+firstSetPos]];

   } // for
   
   return alreadyDrawn;
} // makeTable

- (void)endSeriesProcessing:sender;
/* processing to be done when the series is finished, here the designated
   players advance to the next serise.
*/
{
   NSMutableArray *seek   = [[NSMutableArray alloc] init];	// lists of matches
   NSMutableArray *first  = [[NSMutableArray alloc] init];	// first half is clear
   NSMutableArray *second = [[NSMutableArray alloc] init];	// second half is new
   NSMutableArray *rankingList = [[NSMutableArray alloc] init];	// list of players
   long i, max = [raisingPlayers count];			// number of players to raise
   
   [rankingList addObject:[[self matchTable] winner]];
   [seek addObject:[self matchTable]];
   
   while (([rankingList count] < max) && ([seek count] > 0))
   {
      long smax = [seek count];
      
      for(i=0; i<smax; i++)
      {  id seekAti = [seek objectAtIndex:i];
         
         if([rankingList indexOfObject:[seekAti upperPlayer]] == NSNotFound) {	// I am in lowerMatch
            if ([seekAti upperMatch] != nil) {
               [rankingList addObject:[seekAti upperPlayer]];
               [second addObject:[seekAti upperMatch]];
            } // if
            if ([seekAti lowerMatch] != nil) {
               [first addObject:[seekAti lowerMatch]];
            } // if
         } else	{			// I am in upperMatch
            if ([seekAti lowerMatch] != nil) {
               [rankingList addObject:[seekAti lowerPlayer]];
               [second addObject:[seekAti lowerMatch]];
            } // if
            if ([seekAti upperMatch] != nil) {
               [first addObject:[seekAti upperMatch]];
            } // if
         } // if
      } // for
      [seek removeAllObjects];			// all sought
      [seek addObjectsFromArray:first];		// first half
      [seek addObjectsFromArray:second];	// second half
      [first removeAllObjects];
      [second removeAllObjects];
   } // while
   
   for (i=0; i<max; i++) {
      [[raisingPlayers objectAtIndex:i] fillWithPlayer:[rankingList objectAtIndex:i]];
   } // for
} // endSeriesProcessing

- (void)addRaisingPlayer:(RaisePlayer *)aPlayer;
{
   [raisingPlayers addObject:aPlayer];
}

- (NSMutableArray *)positions;
{
   return positions;
}

@end

