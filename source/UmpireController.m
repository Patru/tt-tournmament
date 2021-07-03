
#import "TournamentController.h"
#import "PlayerController.h"
#import "TournamentInspectorController.h"
#import "UmpireController.h"
#import "UmpireBrowserCell.h"
#import "Tournament-Swift.h"
#import <PGSQLKit/PGSQLKit.h>

@implementation UmpireController

- init;
{
   self=[super init];
   umpires = [NSMutableArray array];

   return self;
} // init

- (IBAction)selectUmpire:(id)sender;
// action message for the browser, simple selection
{
   [[TournamentDelegate.shared tournamentInspector] inspect:[[sender selectedCell] umpire]];
} // selectMatch   

- (void)updateMatrix;
{
   [umpireBrowser loadColumnZero];
   [umpireBrowser setNeedsDisplay:YES];
} // updateMatrix

- (BOOL) isUmpire:(SinglePlayer *)aPlayer;
// returns YES if aPlayer is in umpireList
{
   return [umpires indexOfObject:aPlayer] != NSNotFound;
} // isUmpire

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
// fills the umpires in the fields of the browser `sender`
{
   long i, max = [umpires count];
   id cell;

   if(![[sender cellPrototype] isKindOfClass:[UmpireBrowserCell class]]) {
      cell = [[UmpireBrowserCell alloc] init];
      [sender setCellPrototype:cell];		// set prototype to UmpireBC
		NSString *browserTitle = NSLocalizedStringFromTable(@"verfuegbare Schiedsrichter", @"Tournament", null);
		[sender setTitle:browserTitle ofColumn:0];
   } // if

   for(i=0; i<max; i++) {
      [matrix addRow];
      cell = [matrix cellAtRow:i column:0];
      [cell setUmpire:[umpires objectAtIndex:i]];
      [cell setLoaded:YES];
      [cell setLeaf:YES];
   } // for
   [countField setIntValue:(int)max];
} // fillMatrix

- addUmpire:(SinglePlayer *)aPlayer;
// adds aPlayer, registers its time and redisplays, 
{
   if (![[umpireBrowser cellPrototype] isKindOfClass:[UmpireBrowserCell class]])
   {
      id cell = [[UmpireBrowserCell alloc] init];
      [umpireBrowser setCellPrototype:cell];
   } // if
   if ((![self isUmpire: aPlayer]) && (!restoreInProgress)) {
      PGSQLConnection *database=TournamentDelegate.shared.database;
      
      [umpires addObject:aPlayer];
      
      NSString *insertUmpire = [NSString stringWithFormat:@"INSERT INTO Umpire (Licence, TournamentID) VALUES (%ld, '%@')", [aPlayer licence], TournamentDelegate.shared.preferences.tournamentId];
      [database execCommand:insertUmpire];
      [self updateMatrix];
   } // if
   
   return self;
} // addUmpire

- (SinglePlayer *)removeUmpire:(SinglePlayer *)aPlayer;
// remove aPlayer from Browser and returns it when done, otherwise return nil
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   
   NSUInteger index = [umpires indexOfObject:aPlayer];
   if (index != NSNotFound) {
      [umpires removeObjectAtIndex:index];
      NSString *deleteUmpire = [NSString stringWithFormat:@"DELETE FROM Umpires WHERE Licence = %ld AND TournamentID ='%@'", [aPlayer licence], TournamentDelegate.shared.preferences.tournamentId];
      [database execCommand:deleteUmpire];
      [self updateMatrix];
      return aPlayer;
   } else {
      return nil;
   } // if
} // removeUmpire

- (SinglePlayer *) removeAndReturnSelectedUmpire;
{
   UmpireBrowserCell *selectedCell = [umpireBrowser selectedCell];
   
   if (selectedCell != nil)
   {
      SinglePlayer *umpire = [self removeUmpire:[selectedCell umpire]];
      
      dispatch_async(dispatch_get_main_queue(), ^{
         [umpireBrowser selectRow:0 inColumn:0];
      });
      
      return umpire;
   } // if
   return nil;
}
- (IBAction)removeSelectedUmpire:(id)sender;
// remove selected from Browser and returns it when done, otherwise return nil
{
   [self removeAndReturnSelectedUmpire];
} // removeSelectedUmpire

- (SinglePlayer *)selectedUmpire;
{
   return [[umpireBrowser selectedCell] umpire];
}

- (void)selectSpecificUmpire:(SinglePlayer *)umpire;
{
   long index = [umpires indexOfObject:umpire];

   if (index != NSNotFound) {
      [umpireBrowser selectRow:index inColumn:0];
   } else {
      [umpireBrowser selectRow:0 inColumn:0];
   }
}

- (SinglePlayer *) getUmpire;
// return an umpire if there is one and nil if there is none
{
   if ([umpireBrowser selectedCell] != nil)   {
      return [self removeAndReturnSelectedUmpire];
   } else {
      if ([umpires count] != 0) {
         return [self removeUmpire:[umpires objectAtIndex:0]];
      }  else {
         return nil;
      } // if
   } // if
} // getUmpire

- (bool)hasBackup;
// get the backup and return YES if present
{
	PGSQLConnection *database=[TournamentDelegate.shared database];
   NSString *countUmpires = [NSString stringWithFormat:@"SELECT COUNT(*) FROM Umpire WHERE TournamentID ='%@'", TournamentDelegate.shared.preferences.tournamentId];
   id<GenDBRecordset> rs = [database open:countUmpires];
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
}

- setRestoreInProgress:(bool)aFlag;
{
   restoreInProgress = aFlag;
   if (!restoreInProgress) {
      [self updateMatrix];
   }
   
   return self;
} // setBackup

- (bool)restoreInProgress;
{
   return restoreInProgress;
}

- (void)useBackup:(bool)useIt;
// after recovery used to restore umpires
// precondition: all the umpires have been restored already
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   
   if (useIt) {
      NSString *umpireLicences = [NSString stringWithFormat:@"SELECT DISTINCT Licence FROM Umpire WHERE TournamentID ='%@'", TournamentDelegate.shared.preferences.tournamentId];
      PGSQLRecordset *rs = (PGSQLRecordset *)[database open:umpireLicences];
      if (rs != nil) {
         while(![rs isEOF]) {
            long licence = [[rs fieldByName:@"Licence"] asLong];
            SinglePlayer *umpire=[[TournamentDelegate.shared playerController] playerWithLicence:licence];
            
            [umpires addObject:umpire];
            [rs moveNext];
         }
      } else {
         [TournamentDelegate.shared reportDbError:[database errorDescription]];
      }
      [umpireBrowser loadColumnZero];
   } else {
      [umpires removeAllObjects];
      NSString *deleteUmpires = [NSString stringWithFormat:@"DELETE FROM Umpire WHERE TournamentID ='%@'", TournamentDelegate.shared.preferences.tournamentId];
      if (![database execCommand:deleteUmpires]) {
         [TournamentDelegate.shared reportDbError:[database errorDescription]];
      }
   } // if
} // useBackup

@end
