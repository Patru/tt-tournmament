//
//  SeriesDataController.m
//  Tournament
//
//  Created by Paul Trunz on Wed Dec 26 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "SeriesDataController.h"
#import <PGSQLKit/PGSQLKit.h>
#import "PlaySeriesController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation SeriesDataController

- init;
{
	series = [[NSMutableArray alloc] init];
	
	return self;
}

- (IBAction)newSeries:(NSButton *)sender;
{
   Series *new=[[Series alloc] init];

   [series addObject:new];
   [table reloadData];
}

- (void) showWindow:sender;
{
   [self getAllSeries:self];
	[window makeKeyAndOrderFront:self];
}

- (void) checkSeriesFor:(SinglePlayer *)player;
{
	long i, max;
	
   if ([series count] < 1) {
      [self getAllSeries:self];
   }
   max=[series count];

	for(i=0; i<max; i++) {
		Series *aSeries=[series objectAtIndex:i];

		if ([aSeries appliesFor:player]) {
			[playSeriesController newPlaySeriesWithPass:[player licence] series:[aSeries seriesName]];
		}
	}
}

- (void) getAllSeries:sender;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
	
   [series removeAllObjects];
   NSString *selectSeries = [NSString stringWithFormat:@"SELECT %@ FROM Series WHERE TournamentID ='%@'", [Series allFields], TournamentDelegate.shared.preferences.tournamentId];
	
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectSeries];
   PGSQLRecord *rec = [rs moveFirst];
   while (rec != nil) {
      [series addObject:[Series fromRecord:rec]];
      rec = [rs moveNext];
   }
   [table reloadData];
}

	/********    delegate methods for a table view    ********/

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
{
	return [series count];
}

- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;
{
	return [[series objectAtIndex:rowIndex] objectFor:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView
		 setObjectValue:(id)anObject
		 forTableColumn:(NSTableColumn *)aTableColumn
		 row:(int)rowIndex;
{
	[[series objectAtIndex:rowIndex] setObject:anObject
					for:[aTableColumn identifier]];
}

- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
{
	long selectedRow=[table selectedRow];
	
	// printf("Series selection will change from row %d\n", selectedRow);
	if (selectedRow >= 0) {
		Series *aSeries = [series objectAtIndex:selectedRow];
		if ([[aSeries seriesName] length ] > 0) {
			if ([aSeries validate]) {
				[aSeries storeInDatabase];
			} else {
				return NO;
			}
		}
	}

	return YES;
}

- (void) deleteSelected:sender;
{
	NSInteger selectedRow=[table selectedRow];

	[[series objectAtIndex:selectedRow] deleteFromDatabase];
	[series removeObjectAtIndex:selectedRow];

	[table reloadData];
}

- (void) showAlert:(NSAlert *)alert;
{
   [alert beginSheetModalForWindow:window completionHandler:nil];
}

@end
