/*****************************************************************************
     Use: Control a table tennis tournament.
          delegate for the browser with matches.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 31.12.93, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Match.h"

@interface MatchBrowser:NSObject
{
   IBOutlet NSTextField *countField;
   IBOutlet NSBrowser *matchBrowser;
@private
   NSMutableArray *matches;		// list of currently playable matches
   bool            batchUpdateInProgres;
}

- (instancetype)init;
- (void)updateMatrix;
- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
// fills the matches in the fields of the browser `sender`
- fill:sender;
// initial fill-method
- (IBAction)selectMatch:(id)sender;
- (void)printPlayableWithUmpire:(bool)needsUmpire;
// action message for the browser, simple selection
- (IBAction)printMatchWOUmpire:(id)sender;
- (IBAction)printMatchWithUmpire:(id)sender;
- (long)selectedDesiredPriority;

- (bool)addMatchInBatch:(id <Playable>)aMatch;
- (void)addMatch:(id <Playable>)aMatch;
- (void)removeMatch:(id <Playable>)aMatch;
- (bool)hasBackup;
- (void)useBackup:(bool)useIt;
- (void)startBatchUpdate;
- (void)finishBatchUpdate;
// only intended for backup:
- (NSMutableArray *) matches;
- (void)setMatches:(NSMutableArray *)someMatches;

@end
