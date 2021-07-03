
#import "GroupMatch.h"
#import "GroupResult.h"
#import "MatchResultController.h"
#import "PlayingMatchesController.h"
#import "TournamentController.h"
#import "SeriesController.h"
#import "Tournament-Swift.h"
#import "UmpireController.h"
#import "Match.h"
#import "Player.h"
#import "Series.h"

@implementation MatchResultController

- init;
{
   match = nil;
   
   return self;
} // init

- (IBAction)cancel:(id)sender;
{
   [window orderOut:self];
   [[TournamentDelegate.shared.matchController playingMatchesController] selectNumber:[match rNumber]];
   [[NSApp mainWindow] makeKeyAndOrderFront:self];
}

- (IBAction) ok:(id)sender;
{  id <Player> winner, looser;
   GroupResult *groupResult=TournamentDelegate.shared.groupResult;
	
   if (sender == upperButton) {	// first player won
      winner = [match upperPlayer];
      looser = [match lowerPlayer];
   } else {						// second player won
      winner = [match lowerPlayer];
      looser = [match upperPlayer];
   } // if
   if ([wo intValue] == 0) {
      if ([TournamentDelegate.shared.preferences exactResults]) {
         if (![groupResult singleMatchExact:match winner:winner for:window]) {
				// something wrong
				[window orderOut:self];
				[[TournamentDelegate.shared.matchController playingMatchesController] selectNumber:[match rNumber]];
				
				return;
			}
      }
   } else {
      [match setWO:YES];
      NSAlert *alert = [NSAlert new];
      
		alert.messageText = NSLocalizedStringFromTable(@"WO", @"Tournament", null);
		alert.informativeText = [NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ ist", @"Tournament", null), [looser longName]];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"nicht da", @"Tournament", null)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"abgemeldet", @"Tournament", null)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"hier", @"Tournament", null)];
      
      long ret = [alert synchronousModalSheetForWindow:window];
		
      if (ret == NSAlertFirstButtonReturn) {
			[looser setWO:YES];
      } else if (ret == NSAlertSecondButtonReturn) {
			[looser setPresent:NO];
      }
   }
   
   [match setWinner:winner];		// enters new match in winner
   [match setReady:YES];
	
   [[TournamentDelegate.shared.matchController playingMatchesController] removePlayable:match];
   [match putUmpire];
   [match storeInDB];
	
   [window orderOut:self];
	
   [[TournamentDelegate.shared.matchController playingMatchesController] unselect];
   [[NSApp mainWindow] makeKeyAndOrderFront:self];
   
   [TournamentDelegate.shared.seriesController checkFinishedWithSeries: (Series *)[match series]];
}

- (IBAction)show:sender
{
   match = sender;
   [numberField setIntValue:(int)[match rNumber]];
   [seriesField setStringValue:[[match series] fullName]];
   [wo setIntValue:0];
	[wo setNeedsDisplay:YES];
   // [players selectCellAtRow:-1 column:-1];
   [upperButton setTitle:[[match upperPlayer] longName]];
   [lowerButton setTitle:[[match lowerPlayer] longName]];
   [window makeKeyAndOrderFront:self];
}

@end
