
#import "Tournament-Swift.h"
#import "NotPresentController.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "TournamentInspectorController.h"
#import <PGSQLKit/PGSQLKit.h>

@implementation NotPresentController

- init;
{
   self=[super init];
   notPresentDict    = [[NSMutableDictionary alloc] init];
   notPresentList    = [[NSMutableArray alloc] init];
   woDict            = [[NSMutableDictionary alloc] init];
   woList            = [[NSMutableArray alloc] init];
	window		  	   = nil;
	notPresentBrowser = nil;
	woBrowser	      = nil;
   return self;
} // init

- (IBAction)removeNotPresent:(id)sender;
// remove the currently selected Player from the not-present list
{  
	SinglePlayer *pl=[[notPresentBrowser selectedCell] representedObject];
	[pl setPresent:YES];
} // removeNotPresent

- (IBAction)removeWO:(id)sender;
// remove the currently selected Player from the WO list
{
	SinglePlayer *pl=[[woBrowser selectedCell] representedObject];
	[pl setWO:NO];
} // removeNotPresent

- (void)remove:(SinglePlayer *)aPlayer fromTable:(NSString *)tab;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   
   NSString *deleteFromWalkOver = [NSString stringWithFormat:@"DELETE FROM %@ WHERE Licence=%ld AND TournamentID ='%@'", tab, [aPlayer licence], TournamentDelegate.shared.preferences.tournamentId];
   
   [database execCommand:deleteFromWalkOver];
}

- (void)removeNotPresentPlayer:(SinglePlayer *)aPlayer;
// removes aPlayer from the notPresent list if it is there
{
   if ([notPresentDict objectForKey:[aPlayer licenceNumber]] != nil) {
      [notPresentDict removeObjectForKey:[aPlayer licenceNumber]];
      [notPresentList removeObject:aPlayer];
      [self remove:aPlayer fromTable:@"NotPresent"];
      [notPresentBrowser loadColumnZero];
   }
} // removeNotPresentPlayer

- (void)removeWOPlayer:(SinglePlayer *)aPlayer;
// removes aPlayer from the WO list if it is there
{
   if ([woDict objectForKey:[aPlayer licenceNumber]] != nil) {
      [woDict removeObjectForKey:[aPlayer licenceNumber]];
      [woList removeObject:aPlayer];
      [self remove:aPlayer fromTable:@"WalkOver"];
      [woBrowser loadColumnZero];
   }

}

- (IBAction)makeWONotPresent:(id)sender;
// move the currently selected Player from the WO list to the not-present list.
{
   SinglePlayer *pl=[[woBrowser selectedCell] representedObject];
   [pl setPresent:NO];
} // makeWONotPresent

- (void)display;
{
   [notPresentBrowser loadColumnZero];
   [woBrowser loadColumnZero];
   [window makeKeyAndOrderFront:self];
} // display

- (BOOL) isNotPresent:(SinglePlayer *)aPlayer;
// returns YES if aPlayer is in the not-present list
{
   return ([notPresentDict objectForKey:[aPlayer licenceNumber]] != nil);
} // isNotPresent

- (BOOL) isWO:(SinglePlayer *)aPlayer;
// returns YES if aPlayer is in the not-present list
{
   return ([woDict objectForKey:[aPlayer licenceNumber]] != nil);
} // isWO

- (void)insertLicenceOf:(SinglePlayer *)aPlayer into:(NSString *)tab
{
  PGSQLConnection *database = TournamentDelegate.shared.database;
      NSString *insertPlayer = [NSString stringWithFormat:@"INSERT INTO %@ (Licence, TournamentID) VALUES (%ld, '%@')", tab, [aPlayer licence], TournamentDelegate.shared.preferences.tournamentId];
		[database execCommand:insertPlayer];
}

- (void)addNotPresent:(SinglePlayer *)aPlayer;
// adds aPlayer to not-present and saves to database
{
   if ([notPresentDict objectForKey:[aPlayer licenceNumber]] == nil)
   {
      [notPresentDict setObject:aPlayer forKey:[aPlayer licenceNumber]]; // adjusting HashTable
      [notPresentList addObject:aPlayer];
		[aPlayer setReady:YES];		// looks paradoxical, but not-present-Players should never block a match

      [self insertLicenceOf:aPlayer into:@"NotPresent"];

		[notPresentBrowser loadColumnZero];
   }
}

- (void)addWO:(SinglePlayer *)aPlayer;
// adds aPlayer to wo and saves to database
{
   if ([woDict objectForKey:[aPlayer licenceNumber]] == nil)
   {
      [woDict setObject:aPlayer forKey:[aPlayer licenceNumber]];	// adjusting HashTable
		[woList addObject:aPlayer];
		[aPlayer setReady:YES];		// again paradoxical, but WO-Players should never block a match
      
      [self insertLicenceOf:aPlayer into:@"WalkOver"];

		[woBrowser loadColumnZero];
   }
}

- (long)countEntriesIn:(NSString *)tab
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *countEntries = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE TournamentID ='%@'", tab, TournamentDelegate.shared.preferences.tournamentId];
   id<GenDBRecordset> rs = [database open:countEntries];
   
   if (rs != nil) {
      if (![rs isEOF]) {
         long count = [[rs fieldByIndex:0] asLong];
         [rs close];
         return count;
      } else {
         [rs close];
      }
   } else {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
   }
   return 0;
}

- (bool)hasBackup;
// get the backup and return YES if present
{
   return [self countEntriesIn:@"NotPresent"] > 0 || [self countEntriesIn:@"WalkOver"] > 0;
}

- (void)fetchNotPresentFrom:(PGSQLConnection *)database for:(NSString *)tourId
{
   NSString *notPresentLicences = [NSString stringWithFormat:@"SELECT Licence FROM NotPresent WHERE TournamentId ='%@'", tourId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open: notPresentLicences];
   if (rs != nil) {
      while (![rs isEOF]) {
         long passNumber = [[rs fieldByName:@"Licence"] asLong];
         SinglePlayer *player = [[TournamentDelegate.shared playerController] playerWithLicence:passNumber];
         if (player != nil) {
            [notPresentDict setObject:player forKey:[player licenceNumber]]; // adjusting HashTable
            [notPresentList addObject:player];
         }
         [rs moveNext];
      }
      [rs close];
      [notPresentBrowser loadColumnZero];
   } else {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
   }
}

- (void)fetchWalkOverFrom:(PGSQLConnection *)database for:(NSString *)tourId
{
   NSString *notPresentLicences = [NSString stringWithFormat:@"SELECT Licence FROM WalkOver WHERE TournamentId ='%@'", tourId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open: notPresentLicences];
   if (rs != nil) {
      while (![rs isEOF]) {
         long passNumber = [[rs fieldByName:@"Licence"] asLong];
         SinglePlayer *player = [[TournamentDelegate.shared playerController] playerWithLicence:passNumber];
         if (player != nil) {
            [woDict setObject:player forKey:[player licenceNumber]]; // adjusting HashTable
            [woList addObject:player];
         }
         [rs moveNext];
      }
      [rs close];
      [woBrowser loadColumnZero];
   } else {
      [TournamentDelegate.shared reportDbError:[database errorDescription]];
   }
}

- (void)clean:(PGSQLConnection*)database table:(NSString *)table  for:(NSString *)tourId;
{
   NSString *deleteCommand = [NSString stringWithFormat:@"DELETE FROM %@ WHERE TournamentID ='%@'", table, tourId];
   [database execCommand:deleteCommand];
}

- (void)useBackup:(bool)useIt;
// after recovery used to restore notPresent and wo
// if useIt=YES the states are restored, otherwise discarded
// precondition: all the players have been restored already
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *tourId = TournamentDelegate.shared.preferences.tournamentId;
	
   if (useIt) {
      [self fetchNotPresentFrom:database for:tourId];
      [self fetchWalkOverFrom:database for:tourId];
   } else {
      [self clean:database table:@"NotPresent" for:tourId];
      [self clean:database table:@"WalkOver" for:tourId];
   }
} // useBackup

- (IBAction)selectPlayer:(id)sender;
{
   [[TournamentDelegate.shared tournamentInspector]
      inspect:[[sender selectedCell] representedObject]];
}

- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column;
{
   if (column==0) {
      if (sender == notPresentBrowser) {
         return [notPresentList count];
      } else if (sender == woBrowser) {
         return [woList count];
      }
   }
   return 0;
}

- (BOOL)browser:(NSBrowser *)sender selectRow:(NSInteger)row inColumn:(NSInteger)column;
{
   return YES;
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column;
{
   if (column==0) {
      if (sender == notPresentBrowser) {
			[cell setStringValue:[[notPresentList objectAtIndex:row] longName]];
			[cell setRepresentedObject:[notPresentList objectAtIndex:row]];
			[cell setLeaf:YES];
			[cell setLoaded:YES];
      } else if (sender == woBrowser) {
			[cell setStringValue:[[woList objectAtIndex:row] longName]];
			[cell setRepresentedObject:[woList objectAtIndex:row]];
			[cell setLeaf:YES];
			[cell setLoaded:YES];
      }
   }
}
- (void)setBrowserTitles;
{
	NSString *notPresentTitle = NSLocalizedStringFromTable(@"abgemeldete Spieler", @"Tournament", null);
	[notPresentBrowser setTitle:notPresentTitle ofColumn:0];		
	NSString *woTitle = NSLocalizedStringFromTable(@"WO Spieler", @"Tournament", null);
	[woBrowser setTitle:woTitle ofColumn:0];		
}

@end
