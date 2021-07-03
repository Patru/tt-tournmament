/*****************************************************************************
     Use: Control a table tennis tournament.
          Inspector controller for DoublePlayers.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 10.8.94, Patru: first written
          17,3,96, Patru: replaceInDouble
    Bugs: -not very well documented
 *****************************************************************************/

#import "DoublePlayerInspector.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "TournamentInspectorController.h"
#import "SinglePlayer.h"
#import "Tournament-Swift.h"

@implementation DoublePlayerInspector

void willPlayerContinue(SinglePlayer *replacedPlayer)
{
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"WO", @"Tournament", null);
	alert.informativeText = [NSString stringWithFormat: NSLocalizedStringFromTable(@"%@ wurde im Doppel ersetzt, er ist", @"Tournament", null), [replacedPlayer longName]];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"nicht da", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"abgemeldet", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"hier", @"Tournament", null)];
	long response = [alert synchronousModalSheetForWindow:[TournamentDelegate.shared.tournamentInspector window]];
	switch(response) {
		case NSAlertFirstButtonReturn:
			[replacedPlayer setWO:YES];
			return;
		case NSAlertSecondButtonReturn:
			[replacedPlayer setPresent:NO];
		case NSAlertThirdButtonReturn:
			// nothing to be done here.
			return;
	}	
}

void replaceInDouble(DoublePlayer *pl, SinglePlayer *original, SinglePlayer *replacement)
/* In:   pl: DoublePlayer to replace in
   original: the player who was there
replacement: the player who replaces the old one
 What: replaces a player (player or partner) in a double-pair.
       The match is removed from the openMatches list of original and added
       to the one of replacement
*/
{
	NSArray *matches = [original openMatches];
	long i, max = [matches count];
	NSMutableArray *affectedDoubleMatches = [NSMutableArray array];
	
	if ([pl player] == original) {	// exchange the players
		[pl setPlayer:replacement];
	} else if ([pl partner] == original) {
		[pl setPartner:replacement];
	} else {
		fprintf(stderr, "Doppelspieler konnte nicht ausgetauscht werden\n");
		return;
	} // if
	
	willPlayerContinue(original);
	
	for (i=0; i<max; i++) {
		Match *aMatch = (Match *)[matches objectAtIndex:i];
		if ([aMatch contains:pl]) {
			[affectedDoubleMatches addObject:aMatch];
		}
	}
	
	max=[affectedDoubleMatches count];
	for (i=0; i<max; i++) {
		Match *aMatch = (Match *)[affectedDoubleMatches objectAtIndex:i];
		[original removeMatch:aMatch];	// remove match from original
		if ([aMatch isCurrentlyPlayed]) {
			[original setReady:YES];
			[replacement setReady:NO];
		}
		[replacement addMatch:aMatch];	// add match to replacement
		
	}
} // replaceInDouble

- init;
{
	self=[super init];
   [[NSBundle mainBundle] loadNibNamed:@"DoublePlayerInspector" owner:self topLevelObjects:nil];
	_double=nil;
	_option=0;

	return self;
}

- (void)fillPlayerView;
{  id  play  = [_double player];
   id  part  = [_double partner];
		
   [[infoFormA cellAtIndex:0] setIntValue:(int)[play licence]];
   [[infoFormA cellAtIndex:1] setStringValue:[play longName]];
   [[infoFormA cellAtIndex:2] setStringValue:[play club]];
   [[infoFormA cellAtIndex:3] setIntValue: (int)[play ranking]];
   [[infoFormB cellAtIndex:0] setIntValue:(int)[part licence]];
   [[infoFormB cellAtIndex:1] setStringValue:[part longName]];
   [[infoFormB cellAtIndex:2] setStringValue:[part club]];
   [[infoFormB cellAtIndex:3] setIntValue: (int)[part ranking]];
}

- (NSView *)filledViewForOption:(long)option;
{
	_option=option;
	switch(_option) {
		case 0: {
			[self fillPlayerView];
			return playerView;
		}
		case 1: {
		}
	}
	return nil;
}

- (IBAction)inspect:sender;
// inspect player if [sender tag] == 0, partner for 1
{
   if ([sender tag] == 0)
   {
      [TournamentDelegate.shared.tournamentInspector inspect:[_double player]];
   }
   else if ([sender tag] == 1)
   {
      [TournamentDelegate.shared.tournamentInspector inspect:[_double partner]];
   } // if
} // inspect

- (void)setDouble:(DoublePlayer *)aDouble;
{
	_double=aDouble;
}

- (void)updateFromPlayerView;
{
  SinglePlayer *play  = [_double player];
	SinglePlayer *part  = [_double partner];
	
	if ([play licence] != [[infoFormA cellAtIndex:0] intValue]) {
		replaceInDouble(_double, play,
										[[TournamentDelegate.shared playerController] playerWithLicence:[[infoFormA cellAtIndex:0] intValue]]);
	} // if
	
	if ([part licence] != [[infoFormB cellAtIndex:0] intValue]) {
		replaceInDouble(_double, part,
										[[TournamentDelegate.shared playerController] playerWithLicence:[[infoFormB cellAtIndex:0] intValue]]);
	}	
	[self fillPlayerView];
}

- (void)updateFromView;
{
	switch(_option) {
		case 0: {
			[self updateFromPlayerView];
		}
		case 1: {
			// not available
		}
	}
}

@end
