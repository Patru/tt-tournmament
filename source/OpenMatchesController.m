
#import "GroupMatch.h"
#import "Match.h"
#import "PlayingMatchesController.h"
#import "OMBrowserCell.h"
#import "Player.h"
#import "PlayerController.h"
#import "Tournament-Swift.h"
#import "TournamentController.h"
#import <time.h>
#import <PGSQLKit/PGSQLKit.h>

@implementation PlayingMatchesController

- init;
{
   self=[super init];
   matches    = [[NSMutableArray alloc] init];
   
   return self;
} // init

- (void)awakeFromNib;
{
   [playingMatchesBrowser setCellClass:[OMBrowserCell class]];
   [playingMatchesBrowser setTitle:NSLocalizedStringFromTable(@"runningMatches", @"Tournament", null) ofColumn:0];
   [playingMatchesBrowser tile];    // this makes the title show, even if it does not redraw right away.
}

- numberField;
{
   return numberField;
}

- (void)updateMatrix;
{
   [playingMatchesBrowser loadColumnZero];
   [playingMatchesBrowser setNeedsDisplay:YES];
}

- (BOOL) containsPlayable:aPlayable;
// returns YES if aPlayable is in the list of open matches, NO otherwise
// TODO: sounds crappy, refactor?
{  long num=0, i=0, max = [matches count];
	
	if ([aPlayable isKindOfClass:[GroupMatch class]]) {
		long j=0;
		num = [[aPlayable group] rNumber];	// check if the group of the match is played whole
		while ((j<max) && ([[matches objectAtIndex:j] rNumber] != num)) {
			j++;
		} // while
		
		if (j < max) {
			return true;
		}
	}
	num = [aPlayable rNumber];		// running number of aPlayable
	
	while ((i<max) && ([[matches objectAtIndex:i] rNumber] != num)) {
		i++;
	} // while
	
	return i < max;		// i is equal max if aPlayable is not present
	
} // containsMatch

- (IBAction)selectMatchWithNumber:(id)sender;
{  id match;
   int num;
	
   [self unselect];
   num = [numberField intValue];
   if (num == 0) {		// no match selected
      [self selectNumber:0];
      return;
   } // if
   match = [TournamentDelegate.shared playableWithNumber:num];
	NSString *fehler = NSLocalizedStringFromTable(@"Fehler", @"Tournament", null);
	NSString *abbrechen = NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null);
	if (match == nil) {
      NSAlert *alert = [[NSAlert alloc] init];
      alert.messageText = fehler;
      alert.informativeText = NSLocalizedStringFromTable(@"Spiel existiert nicht!", @"Tournament", null);
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ok", @"Tournament", null)];
      [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
         [self selectNumber:0];
      }];
		return;
	}
	if ( ([match respondsToSelector:@selector(winner)]) && ([match winner] != nil) ) {	// already finished !
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Vorsicht!", @"Tournament", null);
      alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Resultat bereits erfasst.", @"Tournament", null), [[match winner] longName], [match resultString]];
      [alert addButtonWithTitle:abbrechen];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Neu erfassen", @"Tournament", null)];
      if ([alert synchronousModalSheetForWindow: TournamentDelegate.shared.matchController.matchWindow] == NSAlertSecondButtonReturn) {
         [[match winner] removeMatch: [match nextMatch]];
         [[match losing] removeFromUmpireList];
         // TODO: this may result in an illegal situation if the matchresult is *not* entered later on ...
      } else {
			return;
		}
	} else if (![self isBeingPlayed:match]) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = fehler;
      alert.informativeText = NSLocalizedStringFromTable(@"Spiel wurde noch nicht gestartet", @"Tournament", null);
      [alert addButtonWithTitle:abbrechen];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Trotzdem erfassen", @"Tournament", null)];
      if ([alert synchronousModalSheetForWindow: TournamentDelegate.shared.matchController.matchWindow] == NSAlertFirstButtonReturn) {
			[self selectNumber:0];
         return;
      }
   }
   
   [match result:YES];
   [self unselect];
   [numberField setStringValue:@""];
   
   return;
} // selectMatchWithNumber

- (bool)isBeingPlayed: (id<Playable>)playable;
{
   return ([matches indexOfObject:playable] != NSNotFound)
   || ( ([playable isKindOfClass:[GroupMatch class]] && ([matches indexOfObject:[(GroupMatch *)playable group]] != NSNotFound)) );
}

- (IBAction)selectMatchDirectly:(id)sender;
{  id match = [[playingMatchesBrowser selectedCell] match];

   if (match != nil) {
      [match result:YES];
   }
} // result

- (IBAction)withdrawPlayable:(id)sender;
// withdraw a match, should not happen often
{  id<Playable> playable = [[playingMatchesBrowser selectedCell] match];
   TournamentController *matchController = TournamentDelegate.shared.matchController;
   
   if (playable != nil) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Sicher?", @"Tournament", nil);
      alert.informativeText = NSLocalizedStringFromTable(@"wirklich zurueckziehen", @"Tournament", nil);
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Nein", @"Tournament", nil)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ja", @"Tournament", nil)];
      if ([alert synchronousModalSheetForWindow:[matchController matchWindow]] == NSAlertSecondButtonReturn) {
         [playable withdraw];
         [playable setReady:YES];
         [[matchController matchBrowser] updateMatrix];
      } // if
   } // if
} // withdraw

- (Match *)matchPlayedBy:(SinglePlayer *)aPlayer;
{
   NSMatrix *matrix = [playingMatchesBrowser matrixInColumn:0];
   long i, rows=0;
   
   rows=[matrix numberOfRows];
   for(i=0; i<rows; i++) {
      if ([[[matrix cellAtRow:i column:0] match] contains:aPlayer]) {
         return [[matrix cellAtRow:i column:0] match];
      } // if
   } // for
   
   return nil;
   
} // matchPlayerdBy

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
// fills the matches in the fields of the browser `sender`
{
   long i, max=[matches count];
   id cell;
   
   for(i=0; i<max; i++) {
      [matrix addRow];
      cell = [matrix cellAtRow:i column:0];
      [cell setPlayable:(Match *)[matches objectAtIndex:i]];
      [cell setLoaded:YES];
      [cell setLeaf:YES];
   } // for
   [countField setIntValue:(int)max];
} // fillMatrix

static NSDateFormatter *timeFormat = nil;
+ (NSDateFormatter *)timeFormat;
{
   if(timeFormat == nil) {    // TODO: proper Singleton (for Swift maybe?)
      timeFormat = [[NSDateFormatter alloc] init];
      [timeFormat setDateFormat: @"HH:mm"];
   }
   return timeFormat;
}

+ (void)fixCurrentTimeFor:(id <Playable>)aPlayable;
{
	if (([aPlayable time] == nil) || ([[aPlayable time] length] == 0)) {
      NSDate *currentTime = [NSDate date];
		[aPlayable setTime:[[PlayingMatchesController timeFormat] stringFromDate:currentTime]];
	}
}

- (void)addPlayable:(id <Playable>)aPlayable;
// adds aPlayable, registers its time and redisplays, 
{  
	[PlayingMatchesController fixCurrentTimeFor:aPlayable];

	[matches addObject:aPlayable];
	[self dbInsertPlayable:aPlayable];

   [self updateMatrix];
} // aPlayable

- (void)removePlayable:(id <Playable>)aPlayable;
// remove aPlayable from Browser
{
   long i=0, max = [matches count];

   while((i<max) && ((id <Playable>)[matches objectAtIndex:i] != aPlayable)) {
      i++;
   } // while

   if (i<max) {
      [self dbDeletePlayable:[matches objectAtIndex:i]];
      [matches removeObjectAtIndex:i];
      [self updateMatrix];
   } // if
} // removePlayable

- unselect;
// unselect player in Browser
{
   [[playingMatchesBrowser matrixInColumn:0] selectCellAtRow:-1 column:-1];
   return self;
} // unselect

- selectNumber:(long)number;
{
   if (number > 0) {
      [numberField setIntValue:(int)number];
   }
   [numberField selectText:self];
   return self;
} // selectNumber

- (bool)hasBackup;
// get the backup and return YES if present
{
   PGSQLConnection *database=[TournamentDelegate.shared database];
   NSString *countOpenMatches = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PlayingMatch WHERE TournamentID ='%@'",TournamentDelegate.shared.preferences.tournamentId];
   id<GenDBRecordset> rs = [database open:countOpenMatches];
   
   if (rs != nil) {
      if (![rs isEOF]) {
         long count = [[rs fieldByIndex:0] asLong];
         [rs close];
         return count > 0;
      }
      [rs close];
   } else {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
   }
   return NO;
} // getBackup;

- (void)useBackup:(bool)useIt;
// if useIt == YES then use it, else destroy the backup data
// precondition: all the matches have been restored already
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
	
   if (useIt) {			// use the backup data
      NSString *allOpenMatches = [NSString stringWithFormat:@"SELECT Number, StartTime, Umpire FROM PlayingMatch WHERE TournamentID='%@'", TournamentDelegate.shared.preferences.tournamentId];
      id <GenDBRecordset> rs = [database open:allOpenMatches];
      if (rs != nil) {
         while (![rs isEOF]) {
            long number = [[rs fieldByName:@"Number"] asLong];
            long umpire = [[rs fieldByName:@"Umpire"] asLong];
            NSString *matchTime = [[rs fieldByName:@"StartTime"] asString];
            id<Playable> playable = [TournamentDelegate.shared playableWithNumber:number];
            if (playable != nil) {
               if (umpire != 0) {
                  [(Match *)playable setUmpire:[[TournamentDelegate.shared playerController] playerWithLicence:umpire]];
               }
               [playable setReady:NO];      // plays now
               [playable setTime:matchTime];
               [[TournamentDelegate.shared.matchController matchBrowser] removeMatch:playable];
               [matches addObject:playable];
            } // else we do not find the match (and to not try anything?)
            
            [rs moveNext];
         }
         [self updateMatrix];
      } else {
         [TournamentDelegate.shared reportDbError:[database errorDescription]];
      }
   } else {
      NSString *deleteOpenMatchesForTournament = [NSString stringWithFormat:@"DELETE FROM PlayingMatch WHERE TournamentID='%@'", TournamentDelegate.shared.preferences.tournamentId];
      [database execCommand:deleteOpenMatchesForTournament];
   }
} // useBackup

- (void)dbDeletePlayable:(id <Playable>)aPlayable;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *deleteMatchFromTournament = [NSString stringWithFormat:@"DELETE FROM PlayingMatch WHERE Number=%ld AND TournamentID='%@'", [aPlayable rNumber], TournamentDelegate.shared.preferences.tournamentId];
   [database execCommand:deleteMatchFromTournament];
}

- (void)dbInsertPlayable:(id <Playable>)aPlayable;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *insertPlayable = [NSString stringWithFormat:@"INSERT INTO PlayingMatch (Number, StartTime, Umpire, TournamentID) "
      "VALUES (%ld, '%@', %ld, '%@')",
      [aPlayable rNumber], [aPlayable time], [[aPlayable umpire] licence],
      TournamentDelegate.shared.preferences.tournamentId];
   [database execCommand:insertPlayable];
}

@end
