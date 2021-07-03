/*****************************************************************************
     Use: Control a table tennis tournament.
          Inspector controller for Players.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 7.8.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "PlayerInspector.h"
#import "TournamentController.h"
#import "MatchBrowserCell.h"
#import "PlayingMatchesController.h"
#import "TournamentInspectorController.h"
#import "Tournament-Swift.h"

@implementation PlayerInspector

- init;
{
   self=[super init];
   [[NSBundle mainBundle] loadNibNamed:@"PlayerInspectors" owner:self topLevelObjects:nil];
   _player=nil;
   _option=0;

   return self;
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
	// fills the matches in the fields of the browser `sender`
{
   NSArray *playerMatches = [_player openMatches];
   long i, max = [playerMatches count];
   id cell;

   if(!([matrix prototype] == [MatchBrowserCell class])) {
      cell = [[MatchBrowserCell alloc] init];
      [sender setCellPrototype:cell];		// set prototype to MatchBC
      [matrix setPrototype:cell];
		NSString *browserTitle = NSLocalizedStringFromTable(@"spielt noch", @"Tournament", null);
		[sender setTitle:browserTitle ofColumn:0];		
   } // if

   for(i=0; i<max; i++) {
      [matrix addRow];
      cell = [matrix cellAtRow:i column:0];
      [cell setPlayable:(Match *)[playerMatches objectAtIndex:i]];
      [cell setLoaded:YES];
      [cell setLeaf:YES];
   } // for
	[numberOfMatches setIntValue:(int)max];
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

- (void)fillPlayerView;
{
   [[infoForm cellAtIndex:0] setStringValue:[_player pName]];
   [[infoForm cellAtIndex:1] setStringValue:[_player firstName]];
   [[infoForm cellAtIndex:2] setStringValue:[_player club]];
   [[infoForm cellAtIndex:3] setIntValue: (int)[_player licence]];
   [[infoForm cellAtIndex:4] setIntValue: (int)[_player ranking]];
   [[infoForm cellAtIndex:5] setIntValue: (int)[_player womanRanking]];
   [[infoForm cellAtIndex:6] setFloatValue: [_player dayRanking]];
   [[infoForm cellAtIndex:7] setFloatValue: [_player persPriority]];
   if ([_player umpiresMatch] != nil) {
		NSString *zaehltMatch = NSLocalizedStringFromTable(@"zaehlt Match", @"Tournament", null);
      [activity setStringValue:zaehltMatch];
		NSString *matchOnTableFormat = NSLocalizedStringFromTable(@"MatchAufTischFormat", @"Tournament", null);
		NSString *matchOnTableString = [NSString stringWithFormat:matchOnTableFormat,
												  [[_player umpiresMatch] rNumber], [[_player umpiresMatch] tableString]];
      [currentMatch setStringValue:matchOnTableString];
   } else {
      id match = [[TournamentDelegate.shared.matchController playingMatchesController] matchPlayedBy:_player];
		
      if (match != nil) {
			NSString *spieltMatch = NSLocalizedStringFromTable(@"spielt Match", @"Tournament", null);
			[activity setStringValue:spieltMatch];
			NSString *matchOnTableFormat = NSLocalizedStringFromTable(@"MatchAufTischFormat", @"Tournament", null);
			NSString *matchOnTableString = [NSString stringWithFormat:matchOnTableFormat,
													  [match rNumber], [match tableString]];
			[currentMatch setStringValue:matchOnTableString];
      } else {
			NSString *kannZaehlen = NSLocalizedStringFromTable(@"kann zaehlen", @"Tournament", null);
			[activity setStringValue:kannZaehlen];
			[currentMatch setStringValue:@""];
      }
   } // if

   if ([_player present])   {
      [present setIntValue:1];
   } else {
      [present setIntValue:0];
   } // if

   if ([_player wo]) {
      [wo setIntValue:1];
   } else {
      [wo setIntValue:0];
   } // if

   if ([_player ready]) {
      [ready setIntValue:1];
   } else {
      [ready setIntValue:0];
   } // if
}

- (void)fillMatchView;
{
   [tourPriority setFloatValue:[_player tourPriority]];
   [matches loadColumnZero];
}

- (IBAction)selectMatch:(id)sender;
{
   if ([[sender selectedCell] respondsToSelector:@selector(match)]) {
      id match = [[sender selectedCell] match];

      [[TournamentDelegate.shared tournamentInspector] inspect:match];
   }
}

- (IBAction)inspectMatch:sender;
{
   int matchNumber = [currentMatch intValue];
   
   if (matchNumber != 0) {
      id match = [TournamentDelegate.shared playableWithNumber:matchNumber];

      [[TournamentDelegate.shared tournamentInspector] inspect:match];
   }
}

- (void)setPlayer:(SinglePlayer *)aPlayer;
{
   _player=aPlayer;
}

- (void)updateFromView;
{
   switch(_option) {
      case 0: {
	 [self updateFromPlayerView];
      }
      case 1: {
	 // just for viewing, no editing possible
      }
   }
}

- (void)updateFromPlayerView;
{
   BOOL readyChg = NO;

   [_player setPName:[[infoForm cellAtIndex:0] stringValue]];
   [_player setFirstName:[[infoForm cellAtIndex:1] stringValue]];
   [_player createShortName];
   [_player createLongName];
   [_player setClub:[[infoForm cellAtIndex:2] stringValue]];
   // TODO: get rid of this after the redesign of PlayerInspector
   if ([_player licence] != [[infoForm cellAtIndex:3] intValue]) {
		NSString *lizenzAendern = NSLocalizedStringFromTable(@"Lizenz aendern", @"Tournament", null);
		NSString *halt = NSLocalizedStringFromTable(@"Halt!", @"Tournament", null);
		NSString *ok = NSLocalizedStringFromTable(@"Ok", @"Tournament", null);
      NSRunAlertPanel(halt, lizenzAendern, ok, nil, nil);
   } // if

   [_player setRanking:[[infoForm cellAtIndex:4] integerValue]];
   [_player setWomanRanking:[[infoForm cellAtIndex:5] integerValue]];
   [_player setDayRanking:[[infoForm cellAtIndex:6] floatValue]];
   [_player setPersPriority:[[infoForm cellAtIndex:7] floatValue]];
      // tourPriority not editable
   if ([[infoForm cellAtIndex:8] intValue] != [[_player umpiresMatch] rNumber]) {
            // umpires new match!
      if ([[_player umpiresMatch] rNumber] != 0) {
			NSString *achtung = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
			NSString *zaehlenVorFertig = NSLocalizedStringFromTable(@"zaehlen vor fertig", @"Tournament", null);
			NSString *ok = NSLocalizedStringFromTable(@"Ok", @"Tournament", null);
         NSRunAlertPanel(achtung, zaehlenVorFertig, ok, nil, nil);
      } else {
	 id<Playable> playable =
	     [TournamentDelegate.shared playableWithNumber:[[infoForm cellAtIndex:9] intValue]];
	     
	 if ( (playable != nil) && ([playable respondsToSelector:@selector(setUmpire:)]) ) {
	    [(Match *)playable setUmpire:_player];
	    [_player removeFromUmpireList];
	    if ([playable isCurrentlyPlayed]) {
	       [_player setReady:NO];
	       readyChg = YES;
	    }
	 }	
      } // if
   } // if
   [_player setPresent:([present intValue] != 0)];
   [_player setWO:([wo intValue] != 0)];
   if ( (!readyChg) && (([ready intValue] != 0) != [_player ready]) ) {
      [_player setReady:([ready intValue] != 0)];
      [[TournamentDelegate.shared.matchController matchBrowser] updateMatrix];
   } // if

   [self fillPlayerView];
}

@end
