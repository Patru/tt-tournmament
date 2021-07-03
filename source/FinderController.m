/*****************************************************************************
     Use: Control a table tennis tournament.
          Object to find players and matches in the Inspector.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 18.4.94, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import "FinderController.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "TournamentInspectorController.h"
#import "Tournament-Swift.h"

@implementation FinderController

- init;
{
   return self;
}

- (IBAction)showFinder:sender;
{
   if (window == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"Finder" owner:self topLevelObjects:nil];
	}
   // [playerField selectText:self];
   [TournamentDelegate.shared.matchController.matchWindow beginSheet:window completionHandler:nil];
//   [window makeKeyAndOrderFront:self];
}

- (IBAction)findPlayer:sender;
// find the player with a licence
{
   [[TournamentDelegate.shared tournamentInspector]
		inspect:[[TournamentDelegate.shared playerController] playerWithLicence:[sender intValue]]];
   [TournamentDelegate.shared.matchController.matchWindow endSheet:window];
//   [window orderOut:self];
}

- (IBAction)findMatch:sender;
// find the player with licence [sender intValue]
{
   [[TournamentDelegate.shared tournamentInspector]
      inspect:[TournamentDelegate.shared playableWithNumber:[sender intValue]]];
   [TournamentDelegate.shared.matchController.matchWindow endSheet:window];
}

@end
