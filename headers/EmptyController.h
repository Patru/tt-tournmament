/*****************************************************************************
     Use: Control a table tennis tournament.
          Print empty match sheets and tables.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 27.8.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>

@interface EmptyController:NSObject
{
    id  seriesTitle;
    id  numPlayers;
    id  numGroupPlayers;
    id  numEmpty;
    id  maxGroups;
    id  window;
@private    
    id  series;
    
    int lastNumberOfMatches;
}

- (IBAction) allMatchSheets:(id)sender;
- emptyGroups:sender;
- emptyMatchSheets:sender;
- emptyMatchTable:sender;
- makeSeries:sender;
- (IBAction)show:sender;

@end
