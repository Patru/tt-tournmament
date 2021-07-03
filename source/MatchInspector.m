/*****************************************************************************
     Use: Control a table tennis tournament.
          Inspector controller for single Match.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 7.8.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "MatchInspector.h"
#import "Match.h"
#import "Player.h"
#import "PlayerController.h"
#import "Series.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"
#import "TournamentInspectorController.h"
#import "UmpireController.h"

void setReadyAndAskIfPresent(id <Playable> aMatch, id <Player> aPlayer)
// sets the ready state of aPlayable to YES if aMatch is currently playing
// (its just going to be replaced) and asks if aPlayable is present
{   long ret;

   if (aPlayer == nil) {
      return;
   }
   if ([aMatch isCurrentlyPlayed])
   {
      [aPlayer setReady:YES];		// thats the easy part
   } // if
   
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"WO", @"Tournament", null);
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ wurde ersetzt, er ist", @"Tournament", null), [aPlayer longName]];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"nicht da", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"abgemeldet", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"hier", @"Tournament", null)];
   ret = [alert synchronousModalSheetForWindow:TournamentDelegate.shared.tournamentInspector.window];
   switch(ret)
   {
      case NSAlertFirstButtonReturn:
	 [aPlayer setPresent:NO];
	 break;
      case NSAlertSecondButtonReturn:
	 [aPlayer setWO:YES];
	 break;
      case NSAlertThirdButtonReturn:
	 // nothing to be done here.
	 break;
   }
} // setReadyAndAskIfPresent


@implementation MatchInspector

- init;
{
   self=[super init];
   [[NSBundle mainBundle] loadNibNamed:@"MatchInspector" owner:self topLevelObjects:nil];
   _match=nil;
   _option=0;

   return self;
}

- (NSView *)filledViewForOption:(long) option;
{
   _option=option;
   switch(_option) {
      case 0: {
	 [self fillPlayerView];
	 return playerView;
      }
      case 1: {
	 [self fillMatchView];
	 return matchView;
      }
   }
   return nil;
}

- (void)fillMatchView;
{
	int i;
	
	if ([_match winner] != nil) {
		[winnerLicence setIntValue:(int)[[_match winner] licence]];
		[winnerName setStringValue:[[_match winner] longName]];
	} else {
		[winnerLicence setStringValue:@""];
		[winnerName setStringValue:@""];
	}
	
	if ([_match series] != nil) {
		[series setStringValue:[[_match series] fullName]];
	} else {
		[series setStringValue:@""];
	}
	
	for (i=0; i<7; i++) {
		[[setsForm cellAtIndex:i] setStringValue:[_match winnerLoserShortStringSet:i]];
	}
	[[infoForm cellAtIndex:0] setStringValue: [_match tableString]];
	[[infoForm cellAtIndex:1] setIntValue:(int)[_match round]];
	[[infoForm cellAtIndex:2] setStringValue: [_match shouldStart]];
   if ([_match wo]) {
      [woButton setIntValue:1];
   } else {
      [woButton setIntValue:0];
   } // if
   if ([_match isBestOfSeven]) {
      [bestOfSeven setIntValue:1];
   } else {
      [bestOfSeven setIntValue:0];
   } // if
}

- (void)fillPlayerView;
{
   id  up     = [_match upperPlayer];
   id  low    = [_match lowerPlayer];

   if (up != nil) {
      [[upperInfoForm cellAtIndex:0] setIntValue:(int)[up licence]];
      [[upperInfoForm cellAtIndex:1] setStringValue:[up longName]];
      [[upperInfoForm cellAtIndex:2] setStringValue:[up club]];
      [upperRanking setIntValue:(int)[up rankingInSeries:[_match series]]];
      [upperPriority setFloatValue:[up tourPriority]];
   } else {
      [[upperInfoForm cellAtIndex:0] setStringValue:@""];
      [[upperInfoForm cellAtIndex:1] setStringValue:@""];
      [[upperInfoForm cellAtIndex:2] setStringValue:@""];
      [upperRanking setStringValue:@""];
      [upperPriority setStringValue:@""];
   } // if

   if (low != nil) {
      [[lowerInfoForm cellAtIndex:0] setIntValue:(int)[low licence]];
      [[lowerInfoForm cellAtIndex:1] setStringValue:[low longName]];
      [[lowerInfoForm cellAtIndex:2] setStringValue:[low club]];
      [lowerRanking setIntValue:(int)[low rankingInSeries:[_match series]]];
      [lowerPriority setFloatValue:[low tourPriority]];
   } else {
      [[lowerInfoForm cellAtIndex:0] setStringValue:@""];
      [[lowerInfoForm cellAtIndex:1] setStringValue:@""];
      [[lowerInfoForm cellAtIndex:2] setStringValue:@""];
      [lowerRanking setStringValue:@""];
      [lowerPriority setStringValue:@""];
   } // if
}

- (IBAction)inspectPlayer:sender;
	// inspect the player, upper has tag 0, lower is tag 1.
{
   if ([sender tag] == 0) {
      if ([_match upperPlayer] != nil) {
         [[TournamentDelegate.shared tournamentInspector] inspect:[_match upperPlayer]];
      } // if
   } else if ([sender tag] == 1) {
      if ([_match lowerPlayer] != nil) {
         [[TournamentDelegate.shared tournamentInspector] inspect:[_match lowerPlayer]];
      } // if
   } // if
} // inspectPlayer

- (IBAction)insertMatch:sender;
	// inserts a true match, upper for tag 2, lower for tag 3.
{
   if ([sender tag] == 2) {
      [(Series *)[_match series] doubleMatch:[_match upperMatch]];
      [[TournamentDelegate.shared tournamentInspector] inspect:[_match upperMatch]];
   } else if ([sender tag] == 3) {
      [(Series *)[_match series] doubleMatch:[_match lowerMatch]];
      [[TournamentDelegate.shared tournamentInspector] inspect:[_match lowerMatch]];
   } // if
}

- (void)setMatch:(Match *)aMatch;
{
   _match=aMatch;
}

- (void)updateFromView;
{
   switch(_option) {
      case 0: {
	 [self updateFromPlayerView];
      }
      case 1: {
	 [self updateFromMatchView];
      }
   }
}

- (void)updateFromPlayerView;
{
   NSNumberFormatter *intFormatter = [NSNumberFormatter new];
   [intFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
   NSInteger upLicence = [[intFormatter numberFromString:[[upperInfoForm cellAtIndex:0] stringValue]] integerValue];
   NSInteger lowLicence = [[intFormatter numberFromString:[[lowerInfoForm cellAtIndex:0] stringValue]] integerValue];

   if (upLicence != [[_match upperPlayer] licence])
   {		// player replaced, update datastructure
      [[_match upperPlayer] removeMatch:_match];	// remove match from former winner
      setReadyAndAskIfPresent(_match, [_match upperPlayer]);
      [[_match upperMatch] updateWinnerTo:
	 [[TournamentDelegate.shared playerController] playerWithLicence:upLicence]];
   } // if
   if (lowLicence != [[_match lowerPlayer] licence])
   {
      [[_match lowerPlayer] removeMatch:_match];
      setReadyAndAskIfPresent(_match, [_match lowerPlayer]);
      [[_match lowerMatch] updateWinnerTo:
	 [[TournamentDelegate.shared playerController] playerWithLicence:lowLicence]];
   } // if

   [self fillPlayerView];
}

- (void)updateFromMatchView;
{
	long i, max = [_match numberOfSets];
	
	for(i=0; i<max; i++) {
		[_match setWinnerLoserSet:i to:[[setsForm cellAtIndex:i] stringValue]];
	} // for
	
	if ([winnerLicence intValue] != [[_match winner] licence]) {
		if (([winnerLicence intValue] == 0) && ([_match winner] != nil)) {
			[self changeWinnerBackToNil];
		} else {
			[self updateWinnerFromInspector];
		}
	} // if
	
	[_match setTableString:[[infoForm cellAtIndex:0] stringValue]];
	[_match setPlannedStart:[[infoForm cellAtIndex:2] stringValue]];
	/*   [[[manager okButton] cell] setEnabled:NO];
   [[[manager revertButton] cell] setEnabled:NO];
   [[manager window] setDocEdited:NO]; */
	[_match setWO:([woButton intValue] != 0)];
	
	[_match storeInDB];
	
	[self fillMatchView];
} // ok

- (void)changeWinnerBackToNil;
{
   int i;

   [[_match winner] removeMatch:[_match nextMatch]];
   [[TournamentDelegate.shared.matchController matchBrowser] removeMatch:[_match nextMatch]];
   [_match setWO:NO];
   [woButton setIntValue:0];
   [_match updateWinnerTo:nil];

   if ([[_match upperPlayer] present]) {	// add the match if present
      [[_match upperPlayer] addMatch:_match];
   }
   
   if ([[_match lowerPlayer] present]) {
      [[_match lowerPlayer] addMatch:_match];
   }
   
   for(i=0; i<5; i++) {
      [_match setSet:i directlyTo:0];
   } // for
}

- (void)updateWinnerFromInspector;
// winner is changed, get the datastructure right
{
   NSNumberFormatter *intFormatter = [NSNumberFormatter new];
   [intFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
   NSInteger winLicence = [[intFormatter numberFromString:[winnerLicence stringValue]] integerValue];

   SinglePlayer *pl = [[TournamentDelegate.shared playerController] playerWithLicence:winLicence];
   id<Player> newWinner;

   if (pl == nil) {
      return;
   }
   
   if ([[_match upperPlayer] contains:pl]) {
      newWinner = [_match upperPlayer];
   } else if ([[_match lowerPlayer] contains:pl]){
      newWinner = [_match lowerPlayer];
   } else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", null);
      alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"%@ nicht in diesem Match", @"Tournament", null), [pl longName]];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Oohh", @"Tournament", null)];
      [alert beginSheetModalForWindow:TournamentDelegate.shared.tournamentInspector.window completionHandler:nil];

      return;
   }

   [_match updateWinnerTo:newWinner];
}

@end
