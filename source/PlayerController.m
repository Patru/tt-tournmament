//
//  PlayerController.m
//  Tournament
//
//  Created by Paul Trunz on Wed Dec 26 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PlayerController.h"
#import <PGSQLKit/PGSQLKit.h>
#import "PlaySeriesController.h"
#import "SeriesDataController.h"
#import "TournamentController.h"
#import "TournamentInspectorController.h"
#import "Tournament-Swift.h"

@implementation PlayerController

- init;
{
	players = [[NSMutableArray alloc] init];
	playersInTournament = [[NSMutableDictionary alloc] init];
	filterClub = [[NSMutableString alloc] init];
	filterName = [[NSMutableString alloc] init];
	currentLicence = 0;
	rows=[players count];
	selectionWasEdited=NO;
	
	return self;
}

- (NSDictionary *)allPlayers;
{
	return playersInTournament;
}

- (void) getPlayersWithClub:(NSString *)club;
{
	if (![filterClub isEqualToString:club]) {
		[filterClub setString:club];
		[filterName setString:@"None really"];
		currentLicence = 0;
		[self retrievePlayersWithClub:club];
	}
}

- (void) getPlayersWithName:(NSString *)name;
{
	if (![filterName isEqualToString:name]) {
		[filterName setString:name];
		[filterClub setString:@"None really"];
		currentLicence = 0;
		[self retrievePlayersWithName:name];
	}
}

- (void) reloadTable;
{
	[table reloadData];
   long numPlayers = [players count];
	if (numPlayers == 1) {
		[table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
	}
   long selRow = [table selectedRow];
   if ((selRow >= 0) && (selRow < numPlayers)) {
      [playSeriesController getPlaySeriesWithPass:[[players objectAtIndex:[table selectedRow]] licence]];
   }
}

- (void)loadPlayersFrom:(PGSQLRecordset *)rs;
{
   PGSQLRecord *rec = [rs moveFirst];
   while (rec != nil) {
      [players addObject:[SinglePlayer fromRecord:rec]];
      rec = [rs moveNext];
   }
}
- (void) getPlayerWithLicence:(int)pass;
{
	PGSQLConnection *database=TournamentDelegate.shared.database;
	[filterName setString:@"None really"];
	[filterClub setString:@"None really"];
	[players removeAllObjects];
   NSString *selectPlayerWithLicence = [NSString stringWithFormat:@"SELECT %@ FROM Player WHERE Licence=%d ORDER BY Name, FirstName", [SinglePlayer allFields], pass];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open: selectPlayerWithLicence];
   if ((rs != nil) && (![rs isEOF])) {
      [self loadPlayersFrom:rs];
   }
	[self reloadTable];
}

- (IBAction)getPlayersInClub:(id)sender;
{
	[self getPlayersWithClub:[sender stringValue]];
}

- (IBAction)getPlayersWithLastName:(id)sender;
{
	[self getPlayersWithName:[sender stringValue]];
}

- (IBAction)getPlayerWithPass:(id)sender;
{
	[self getPlayerWithLicence:[sender intValue]];
}

- newPlayerWithSameClub:sender;
{
	SinglePlayer *newPlayer=[[SinglePlayer alloc] init];

	if ([players count] > 0) {
		SinglePlayer *lastPlayer = [players lastObject];
		[newPlayer setClub:[lastPlayer club]];
	}
	[players addObject:newPlayer];
	[self reloadTable];
	
	return self;
}

- checkSeriesForSelectedPlayer:sender;
{
	if ([table selectedRow] >= 0) {
		[seriesController checkSeriesFor:[players objectAtIndex:[table selectedRow]]];
	}
	
	return self;
}

- (SinglePlayer *)playerWithLicence:(long)licence;
{
	NSNumber *licenceNumber=[NSNumber numberWithLong:licence];
	id player = [playersInTournament objectForKey:licenceNumber];
	if (player == nil) {
		player = [self playerForLicence:licence];
		if (player != nil) {
			[playersInTournament setObject:player forKey:licenceNumber];
		}
	}
	return player;
}

- (NSWindow *) playerWindow;
{
   return playerWindow;
}

- (void) showWindow:sender;
{
	[playerWindow makeKeyAndOrderFront:self];
}

- (SinglePlayer *)playerForLicence:(long)licence;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *selectPlayerWithLicence = [NSString stringWithFormat:@"SELECT %@ FROM Player WHERE Licence=%ld ", [SinglePlayer allFields], licence];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open: selectPlayerWithLicence];
   if ((rs != nil) && (![rs isEOF])) {
      return [SinglePlayer fromRecord:[rs moveFirst]];
   }
   
   return nil;
}

- (void) retrievePlayersWithClub:(NSString *)club;
{
	PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *sqlClub = [club sqlEscaped];
	[players removeAllObjects];
   NSString *selectClubExact = [NSString stringWithFormat:@"SELECT %@ FROM Player WHERE Club='%@' ORDER BY Name, FirstName", [SinglePlayer allFields], sqlClub];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectClubExact];
   if ((rs != nil) && (![rs isEOF])) {
      [self loadPlayersFrom:rs];
   } else {
      [rs close];
      NSString *selectClubPart = [NSString stringWithFormat:@"SELECT %@ FROM Player WHERE Club ILIKE'%%%@%%' ORDER BY Name, FirstName", [SinglePlayer allFields], sqlClub];
      rs = (PGSQLRecordset *)[database open:selectClubPart];
      if ((rs != nil) && (![rs isEOF])) {
         [self loadPlayersFrom:rs];
      }
   }
	[self reloadTable];
}

- (void)retrievePlayersWithName:(NSString *)name;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *sqlName = [name sqlEscaped];
   [players removeAllObjects];
   NSString *selectClubExact = [NSString stringWithFormat:@"SELECT %@ FROM Player WHERE Name='%@' ORDER BY Name, FirstName", [SinglePlayer allFields], sqlName];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectClubExact];
   
   if ((rs != nil) && (![rs isEOF])) {
      [self loadPlayersFrom:rs];
   } else {
      [rs close];
      NSString *selectClubPart = [NSString stringWithFormat:@"SELECT %@ FROM Player WHERE Name ILIKE'%%%@%%' ORDER BY Name, FirstName", [SinglePlayer allFields], sqlName];
      rs = (PGSQLRecordset *)[database open:selectClubPart];
      if ((rs != nil) && (![rs isEOF])) {
         [self loadPlayersFrom:rs];
      }
   }

	[self reloadTable];
}

	/********    delegate methods for a table view    ********/

- (long)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	return [players count];
}

- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;
{
	return [[players objectAtIndex:rowIndex] objectFor:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView
		 setObjectValue:(id)anObject
		 forTableColumn:(NSTableColumn *)aTableColumn
		 row:(int)rowIndex;
{
	selectionWasEdited=YES;
	[[players objectAtIndex:rowIndex] setObject:anObject
											for:[aTableColumn identifier]];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
{
	long selectedRow=[aTableView selectedRow];
	
	if (selectedRow >= 0) {
		/* printf("selection changes at row index %d, name %s, ", [aTableView selectedRow],
		 [[[players objectAtIndex:selectedRow] pName] UTF8String]);*/
		if (selectionWasEdited) {
			[[players objectAtIndex:selectedRow] storeInDatabase];
			selectionWasEdited=NO;
			// printf("edited\n");
		} else {
			// printf("unchanged\n");
		}
	}
	return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
   long index=[table selectedRow];
   
   if (index >= 0) {
      SinglePlayer *player = [players objectAtIndex:index];
      [playSeriesController getPlaySeriesWithPass:[player licence]];
      // for inspection we want the exact player already in memory
      SinglePlayer *inspectPlayer=[[TournamentDelegate.shared playerController] playerWithLicence:[player licence]];
      [[TournamentDelegate.shared tournamentInspector] inspectNotKey:inspectPlayer];
   }
   //	printf("selection changed to row %d\n", );
}
- (void)fixNumberFormats;
{
   [playSeriesController fixNumberFormats];
}

- (PlaySeriesController *) participationController;
{
   return playSeriesController;
}

- (NSArray<SinglePlayer *>*)playersMatching:(NSString *)fragment;
{
   NSMutableArray<SinglePlayer *> *results = [NSMutableArray array];
   int caseInsensitiveOptions = NSRegularExpressionSearch|NSCaseInsensitiveSearch;
   
   for (SinglePlayer *player in [playersInTournament allValues]) {
      if ([[player longName] rangeOfString:fragment options:caseInsensitiveOptions].location != NSNotFound) {
         [results addObject:player];
      }
   }
   return results;
}
@end
