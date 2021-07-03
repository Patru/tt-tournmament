/*****************************************************************************
     Use: Control a table tennis tournament.
          delegate for the browser with matches.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 31.12.93, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import "MatchBrowser.h"
#import <PGSQLKit/PGSQLKit.h>
#import "Group.h"
#import "GroupMatch.h"
#import "Match.h"
#import "MatchView.h"
#import "MatchBrowserCell.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "PlayingMatchesController.h"
#import "TournamentInspectorController.h"
#import "Tournament-Swift.h"
#import "UmpireController.h"
#import "SinglePlayer.h"
#import "Series.h"

@implementation MatchBrowser

- (instancetype)init;
{
   matches = [[NSMutableArray alloc] init];
   batchUpdateInProgres = false;
   
   return self;
}

- (void)awakeFromNib;
{
   [matchBrowser setCellClass:[MatchBrowserCell class]];
   [matchBrowser setTitle:NSLocalizedStringFromTable(@"availableMatches", @"Tournament", null) ofColumn:0];
   [matchBrowser tile];    // this makes the title show, even if it does not redraw right away.
}

- (BOOL)browser:sender columnIsValid:(int)column
{
   return column=0;
}

- (void)sortMatches;
{
	long i, max = [matches count];
	for(i=0; i<max; i++) {			// exact insertion-sort
		long j = i;
		float prio = [[matches objectAtIndex:i] tourPriority];	// calculate exact
		
		while ((j > 0) && (prio > [[matches objectAtIndex:j-1] tp])) {
			// search for the correct place
			j--;
		} // while
		if (j < i) {
			id aMatch = [matches objectAtIndex:i];
			[matches removeObjectAtIndex:i];
			[matches insertObject:aMatch atIndex:j];
		} // if
	} // for
}

-(void)sortMatchesNew;
{
	long i, max = [matches count];
	for(i=0; i<max; i++) {
		[[matches objectAtIndex:i] tourPriority];	// calculate priority exactly, comparison will use tp-cache
	}
		
	[matches sortUsingSelector: @selector(prioCompare:)];
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
// fills the matches in the fields of the browser `sender`
{
	long i, max = [matches count];
	id cell;
	
	for(i=max-1; i>=0; i--) {		// first scan to eliminate
		id thisMatch = [matches objectAtIndex:i];
		
		if (!([thisMatch ready])) {
			[[matches objectAtIndex:i] setInBrowser:NO];
			[matches removeObjectAtIndex:i] ;
		} // if
	} // for
	
	[self sortMatchesNew];
	
	max = [matches count];		// some may have been removed!
	
	for(i=0; i<max; i++) {
		[matrix addRow];
		cell = [matrix cellAtRow:i column:0];
		[cell setPlayable:(Match *)[matches objectAtIndex:i]];
		[cell setLoaded:YES];
		[cell setLeaf:YES];
	} // for
	[countField setIntValue:(int)max];
} // fillMatrix

- (void)updateMatrix;
{
   if (!batchUpdateInProgres) {
      [matchBrowser loadColumnZero];
      [matchBrowser setNeedsDisplay:YES];
      [matchBrowser selectRow:0 inColumn:0];
      [[TournamentDelegate.shared.matchController playingTableController]
         selectAppropriateTableFor:[[matchBrowser selectedCell] match]];
   }
}

- fill:sender;
// initial fill-method
{
   return self;
} // fill

- (IBAction)selectMatch:(id)sender;
// action message for the browser, simple selection
{
   [[TournamentDelegate.shared tournamentInspector] inspect:[[sender selectedCell] match]];
   [[TournamentDelegate.shared.matchController playingTableController]
      selectAppropriateTableFor:[[sender selectedCell] match]];
} // selectMatch

- (bool)addMatchInBatch:(id <Playable>)aMatch;
// adds aMatch, but does not redisplay, even if autodisplay is set
// returns YES if match was really added
{
	if ((!([aMatch inBrowser])) && ([aMatch ready])) {   // both ready not in MatchBrowser
		long i = [matches count];
		float prio = [aMatch tourPriority];		// fast presort
		
		while ((i > 0) && (prio > [[matches objectAtIndex:i-1] tp])) { // search for the correct place
			i--;
		} // while
		[matches insertObject:aMatch atIndex:i];
		[aMatch setInBrowser:YES];
		
		return YES;
	}
	return NO;
}

- (void)addMatch:(id <Playable>)aMatch;
{
   if ([self addMatchInBatch:aMatch]) {
      [self updateMatrix];
   }
}
   
- (void)removeMatch:(id <Playable>)aMatch;
// removal of a Match, should not be necessary usually, but for backup
{
   long countBefore = [matches count];

   [matches removeObject:aMatch];
   if (countBefore > [matches count]) {
      [self updateMatrix];
   }
   [aMatch setInBrowser:NO];
}
- (id <Playable>)getMatch;
// return the selected or the first possible match
{  id matchCell = [matchBrowser selectedCell];
   
   if((matchCell != nil) && ([[matchCell match] ready]))
   {
      return [matchCell match];
   }
   else
   {  long i = 0, max = [matches count];
      
      while ((i<max) && (!([[matches objectAtIndex:i] ready])))
      {
         i++;
      } // while
      if (i < max)
      {
         return [matches objectAtIndex:i];
      }
      else
      {
         return nil;
      } // if
   } // if
} // getMatch

- (void)printPlayableWithUmpire:(bool)needsUmpire;
   // print the current match (selected or first) without umpire
{
	id<Playable> playable = [self getMatch];
	
   if (playable != nil) {
      if (![playable playersShouldUmpire]) {
			if ([[TournamentDelegate.shared.matchController playingTableController] assignTablesTo:playable]) {
				[playable removeAllPlayersFromUmpireList];
				if (needsUmpire) {
					[playable takeUmpire];
				}
				[playable print:self];
				[playable setReady:NO];
				[self removeMatch:playable];
				[[TournamentDelegate.shared.matchController playingMatchesController] addPlayable:playable];
			}
      }
   }
}

- (IBAction)printMatchWOUmpire:(id)sender;
   // print the current match (selected or first) without umpire
{
   [self printPlayableWithUmpire:NO];
}

- (IBAction)printMatchWithUmpire:(id)sender;
{
   [self printPlayableWithUmpire:YES];
}

- (bool)hasBackup;
// get the backup and return YES if present
{
	PGSQLConnection *database=[TournamentDelegate.shared database];
   long count=0;
   NSString *selectCountMatches = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PlayedMatch WHERE TournamentID ='%@'", TournamentDelegate.shared.preferences.tournamentId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectCountMatches];
   if (rs != nil) {
      if (![rs isEOF]) {
         count = [[rs fieldByIndex:0] asLong];
      }
      [rs close];
      
      return count > 0;
   } else {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
      return false;
   }
}

/// @return NO if replaying should not continue
- (BOOL)continueDespiteUnkonwnWinner:(id<Playable>)mat win:(id<Player>)win {
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Spieler %@\nnicht im Match %ld", @"Tournament", null), [win longName], [mat rNumber]];
   alert.alertStyle = NSAlertStyleCritical;     // this happens while an alert is still active, so Critical is critical :-)
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ok", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
   
   return [alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn;
}

/// @return NO if replaying should not continue
- (BOOL)continueDespiteMissingMatch:(long)number {
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Match %ld fehlt in der Auslosung!", @"Tournament", null), number];
   alert.alertStyle = NSAlertStyleCritical;
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ok", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
   
   return [alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn;
}

/** replays match from a database record
 @return NO if replaying should *not* continue due to user decision */
-(BOOL)replayMatchFrom:(PGSQLRecord *)record;
{
   long number, winner, looser;
   NSString *result, *startTime;
   BOOL wo;

   number = [[record fieldByName:@"Number"] asLong];
   winner = [[record fieldByName:@"Winner"] asLong];
   looser = [[record fieldByName:@"Looser"] asLong];
   result = [[record fieldByName:@"Result"] asString];
   startTime = [[record fieldByName:@"StartTime"] asString];
   wo = [[record fieldByName:@"wo"] asBoolean];
   
   id<Playable> mat = [TournamentDelegate.shared playableWithNumber:number];
   if (mat != nil) {
      if ([mat isKindOfClass:[Match class]]) {     // Groups will be replayed through the individual matches
         Match *mtch = (Match *)mat;
         if ([mtch winner] == nil) {   // not played in save, redo from DB
            long j, assignedSets;
            long sets[7];
            
            id <Player>win = [[TournamentDelegate.shared playerController] playerWithLicence:winner];
            if ([[mtch upperPlayer] contains:win]) {   // contains because of doubles
               // set the winner as before
               [mtch sWinner:[mtch upperPlayer]];
               // free umpires handled in separate table
            } else if ([[mtch lowerPlayer] contains:win]) {
               [mtch sWinner:[mtch lowerPlayer]];
            } else {
               return [self continueDespiteUnkonwnWinner:mat win:win];
            }
            
            assignedSets=sscanf([result UTF8String], "%ld,%ld,%ld,%ld,%ld,%ld,%ld",
                                &sets[0], &sets[1], &sets[2], &sets[3], &sets[4], &sets[5], &sets[6]);
            for (j=assignedSets; j < 7; j++) {
               sets[j]=0;
            }
            for(j=0; j<7; j++) {
               [mtch setSet:j directlyTo:sets[j]];
            }
            
            if (wo) {
               [mtch setWO:YES];
            } // if
            [mtch setTime:startTime];
            [mtch setWinner:[mtch winner]];
            // you got the whole result now, continue as regular
            [mtch setReady:YES];
            [[TournamentDelegate.shared.matchController matchBrowser] removeMatch:mat];
         }
      }
      return YES;
   } else {
      return [self continueDespiteMissingMatch:number];
   }
}

- (void)useBackup:(bool)useIt;
// if useIt == YES then use it, else destroy the backup data
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   if (useIt) {
      NSString *playedMatches = [NSString stringWithFormat:@"SELECT Number, Winner, Looser, Result, StartTime, wo FROM PlayedMatch WHERE TournamentID ='%@' ORDER BY Number", TournamentDelegate.shared.preferences.tournamentId];
      PGSQLRecordset *rs = (PGSQLRecordset *)[database open:playedMatches];
      
      if (rs != nil) {
         PGSQLRecord *record = [rs moveFirst];
         BOOL continueReplay = YES;
         while ((![rs isEOF]) && continueReplay) {
            continueReplay = [self replayMatchFrom:record];
            record = [rs moveNext];
         }
      } else {
         [TournamentDelegate.shared reportDbError:[database errorDescription]];
      }
   }
   else {
      NSString * deleteExistingMatches = [NSString stringWithFormat:@"DELETE FROM PlayedMatch WHERE TournamentID ='%@'",
		 TournamentDelegate.shared.preferences.tournamentId];
      [database execCommand:deleteExistingMatches];
   }
} // useBackup

- (long)selectedDesiredPriority;
{
   return [[[matchBrowser selectedCell] match] desiredTablePriority];
}

- (void)startBatchUpdate;
{
   batchUpdateInProgres = YES;
}

- (void)finishBatchUpdate;
{
   batchUpdateInProgres = NO;
   [self updateMatrix];
}

- (NSMutableArray *) matches;
{
   return matches;
}
- (void)setMatches:(NSMutableArray *)someMatches;
{
   matches = someMatches;
   [self updateMatrix];
}

@end
