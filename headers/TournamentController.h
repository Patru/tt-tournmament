/*****************************************************************************
     Use: Control a table tennis tournament.
          Main controller object.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 2.1.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Match.h"
#import "MatchBrowser.h"
#import "PlayingMatchesController.h"
#import "UmpireController.h"
#import "TournamentTableController.h"

@class SearchController;
@class PlayingTableController;

@interface TournamentController:NSViewController
{
   IBOutlet NSWindow *matchesWin;
   IBOutlet PlayingMatchesController *playingMatchesController;
   IBOutlet PlayingTableController *playingTableController;
	IBOutlet UmpireController *umpireController;
	IBOutlet MatchBrowser *matchBrowser;
   IBOutlet NSPanel *importWindow;
   IBOutlet SearchController *searchController;
   __weak IBOutlet NSProgressIndicator *importProgress;
   __weak IBOutlet NSTextField *importActivity;
	
@private
	id           emptyController;
   NSString * lastSearch;
}

- (MatchBrowser *)matchBrowser;				// controller of matches
- (IBAction)openDocument:(id)sender;
- (PlayingMatchesController *)playingMatchesController;
- (PlayingTableController *)playingTableController;
- (UmpireController *)umpireController;
- (SearchController *)searchController;

- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
- (IBAction)importTablesTimes:(id)sender;
- (IBAction)importPlayersExternalSource:(id)sender;
- (IBAction)exportXmlResults:(id)sender;
- (IBAction)loadPlayersFromClickTt:(id)sender;
- (IBAction)dismissLoadInfoDialog:(id)sender;
- (IBAction)loadAdditionalSeries:(id)sender;
- (IBAction)updateSearch:(NSSearchField *)sender;

- (BOOL) openFile:(NSString *)filename;
- (NSWindow *) matchWindow;

@end

@interface NSAlert (Cat)
-(NSModalResponse) synchronousModalSheetForWindow:(NSWindow *)aWindow;
@end
