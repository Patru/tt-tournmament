/*****************************************************************************
     Use: Control a table tennis tournament.
          Print empty match sheets and tables.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 27.8.1994, Patru: first started
 	  19.2.1995, Patru: improved to print numbered groups
    Bugs: -not very well documented
 *****************************************************************************/

#import "EmptyController.h"
#import "Tournament-Swift.h"
#import "Group.h"
#import "Match.h"
#import "Series.h"
#import "TournamentViewController.h"

@implementation EmptyController

- init;
{
   series = nil;
	window = nil;
   return self;
} // init

-free;
{
   [series free];
   return self;
} // free

- (IBAction)show:sender;
{
   if (window == nil) {
      [[NSBundle mainBundle] loadNibNamed:@"Empty" owner:self topLevelObjects:nil];
   } // if
   [seriesTitle selectText:self];
   [window makeKeyAndOrderFront:self];
} // show

- makeSeries:sender;
// initialize the series for the tables, matches and groups
{
   if (series == nil) {
      NSMutableArray   *positions = [[NSMutableArray alloc] init];
      Match  *table;
      
      series = [[Series alloc] init];
      [series setFullName:[seriesTitle stringValue]];
      lastNumberOfMatches = [numPlayers intValue];
      table = [[Match alloc] initUpTo:[numPlayers intValue]
                   current:1 total:1 next:nil series:series posList:positions];
      [series setMatchTable:table];
      [series numberKoMatches];
   } else if ((lastNumberOfMatches != [numPlayers intValue])
            || (![[series fullName] isEqualToString:[seriesTitle stringValue]])) {
      NSMutableArray   *positions = [[NSMutableArray alloc] init];
      Match  *table;
      
      [series setMatchTable:nil];
      [series setFullName:[seriesTitle stringValue]];
      lastNumberOfMatches = [numPlayers intValue];
      table = [[Match alloc] initUpTo:[numPlayers intValue]
                   current:1 total:1 next:nil series:series posList:positions];
      [series setMatchTable:table];
      [series numberKoMatches];
   } // if
   
   return self;
} // makeSeries

- (IBAction) allMatchSheets:(id)sender;
// print all the match sheets in the series
{
   [self makeSeries:self];
   [series allMatchSheets:self];
}

- emptyGroups:sender
{
   NSMutableArray  *pls=[NSMutableArray arrayWithCapacity:4];
   int i, max = [numGroupPlayers intValue];
   
   [self makeSeries:self];
   Group *g = [[Group alloc] initSeries:series number:0];
   
   for(i=0; i<max; i++) {
      SinglePlayer *pl = [[SinglePlayer alloc] init];
		NSString *name=[NSString stringWithFormat:@"%c", 'a' + i];
      
      [pl setPName:name];
		[pl setFirstName:@""];
      [pls addObject:pl];
   } // for
	[g setPlayers:pls];
   [g makeMatches];
      
   for(i=0; i<[maxGroups intValue]; i++) {
      [g setNumber:i+1];
      [g print:self];
   } // for
   
    return self;
}

- emptyMatchSheets:sender
{
   Match *m;
   int i;
   
   [self makeSeries:self];
   m = [[Match alloc] init];
   [m setSeries:series];
   
   for(i=0; i<[numEmpty intValue]; i++) {
      [m print:self];
   } // for
   
   return self;
}

- emptyMatchTable:sender
{
   [self makeSeries:self];
	[TournamentDelegate.shared.tournamentViewController setSeries:series];
   
   return self;
}

@end
