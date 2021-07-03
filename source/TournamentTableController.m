
#import "TournamentTableController.h"
#import "TournamentController.h"
#import "TournamentTableCell.h"
#import "Tournament-Swift.h"
#import <PGSQLKit/PGSQLKit.h>

@implementation TournamentTableController

- init;
{
   self=[super init];
   priorityTables = [NSMutableArray new];
   tableOnDisplay = nil;
   
   return self;
} // init

- (void)updateMatrix;
{
   [tournamentTableBrowser loadColumnZero];
   [tournamentTableBrowser setNeedsDisplay:YES];
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix
// fills the matches in the fields of the browser `sender`
{
   long i, j, maxPriorities = [priorityTables count], numberOfTables = 0;
   id cell;
   
   if(![[sender cellPrototype] isKindOfClass:[TournamentTableCell class]]) {
      [sender setCellClass:[TournamentTableCell class]];
      NSString *browserTitle = NSLocalizedStringFromTable(@"Leere Tische", @"Tournament", null);
      [sender setTitle:browserTitle ofColumn:0];
   } // if
   
   for(i=0; i<maxPriorities; i++) {
      NSArray *priority = [priorityTables objectAtIndex:i];
      long max = [priority count];
      
      for (j=0; j<max; j++) {
         TournamentTable *table = (TournamentTable *)[priority objectAtIndex:j];
         
         if ([table occupiedBy] == nil) {
            [matrix addRow];
            cell = [matrix cellAtRow:numberOfTables column:0];
            [cell setTournamentTable:table];
            [cell setLoaded:YES];
            [cell setLeaf:YES];
            numberOfTables++;
         }
      }
   }
   [countField setIntValue:(int)numberOfTables];
}

- (IBAction)addTable:(id)sender;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *maxTable = [NSString stringWithFormat:@"SELECT MAX(Number) FROM TourTable WHERE TournamentID ='%@'", TournamentDelegate.shared.preferences.tournamentId];
   long maxTableNumber=0;
   TournamentTable *newTable;
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:maxTable];
   if ((rs != nil) && (![rs isEOF])) {
      maxTableNumber = [[rs fieldByIndex:0] asLong];
   }

   newTable = [TournamentTable tableWithNumber:maxTableNumber+1 priority:0
			       nextToFollowing:YES occupiedBy:nil];
   [self displayTable:newTable];
}

- (IBAction)removeTable:(id)sender;
{
   TournamentTable *table = [[tournamentTableBrowser selectedCell] tournamentTable];

   NSAlert *alert = [NSAlert new];
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Tisch loeschen", @"Tournament", null), [table number]];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"nur jetzt", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Aus der Datenbank", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
   [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSAlertFirstButtonReturn) {
         [[priorityTables objectAtIndex:[table priority]-1] removeObject:table];
      } else if (returnCode == NSAlertSecondButtonReturn) {
         PGSQLConnection *database=TournamentDelegate.shared.database;
         NSString *deleteTable = [NSString stringWithFormat:@"DELETE FROM TourTable WHERE TournamentID ='%@' AND Number = %ld", TournamentDelegate.shared.preferences.tournamentId, [table number]];
         
         [database execCommand:deleteTable];
         [[priorityTables objectAtIndex:[table priority]-1] removeObject:table];    // TODO: centralize?
      }
      [self updateMatrix];
   }];
}

- (IBAction)readFromDatabase:(id)sender;
{
   long maxPriority=0;
   NSString *tourId = TournamentDelegate.shared.preferences.tournamentId;
   PGSQLConnection *database=[TournamentDelegate.shared database];
   NSString *selectMaxPriority = [NSString stringWithFormat:@"SELECT MAX(Priority) FROM TourTable WHERE TournamentID ='%@'", tourId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectMaxPriority];
   if ((rs != nil) &&(![rs isEOF])) {
      maxPriority = [[rs fieldByIndex:0] asLong];
   }
   [rs close];
   [priorityTables removeAllObjects];
   while ([priorityTables count] < maxPriority) {
      [priorityTables addObject:[NSMutableArray array]];
   }

   NSString *selectTables = [NSString stringWithFormat:@"SELECT Number, Priority, NextToFollowing, OccupiedBy FROM TourTable WHERE TournamentID ='%@'", tourId];
   rs = (PGSQLRecordset *)[database open:selectTables];
   while (![rs isEOF]) {
      long number, priority, occupiedBy;
      BOOL nextToFollowing;
      number=[[rs fieldByName:@"Number"] asLong];
      priority=[[rs fieldByName:@"Priority"] asLong];
      occupiedBy=[[rs fieldByName:@"OccupiedBy"] asLong];
      nextToFollowing=[[rs fieldByName:@"NextToFollowing"] asBoolean];
      id<Playable> occupyingPlayable = [TournamentDelegate.shared playableWithNumber:occupiedBy];

      TournamentTable *table = [TournamentTable tableWithNumber:number
                                                       priority:priority  nextToFollowing:nextToFollowing
                                                     occupiedBy:occupyingPlayable];
      NSMutableArray *thisPriorityTables = (NSMutableArray *)[priorityTables objectAtIndex:priority-1];
      
      if (occupyingPlayable == nil) {
         [freeTables addObject:table];
      } else {
         [occupyingPlayable addTable:number];
      }
      
      if ([thisPriorityTables indexOfObject:table] == NSNotFound) {
         [[priorityTables objectAtIndex:priority-1] addObject:table];
      }
      [rs moveNext];
   }
   [rs close];
   [self updateMatrix];
}

- (void)displayTable:(TournamentTable *)table;
{
   [tableNumber setIntValue: (int)[table number]];
   [tablePriority setIntValue: (int)[table priority]];
   [tableNextToFollowing setIntValue: [table isNextToFollowing]];
   tableOnDisplay = table;
   
   [window makeKeyAndOrderFront:self];
}

- (IBAction)updateTable:(id)sender;
{
   TournamentTable *table = [[tournamentTableBrowser selectedCell] tournamentTable];

   [self displayTable:table];
}

- (IBAction)storeTable:(id)sender;
{
   if ( ([tableOnDisplay priority] != [tablePriority intValue])
        || ([tableOnDisplay isNextToFollowing] != [tableNextToFollowing intValue]) ) {
      while ([priorityTables count] < [tablePriority intValue]) {
         [priorityTables addObject:[NSMutableArray array]];
      }
      if ([tableOnDisplay priority] > 0) {
         [[priorityTables objectAtIndex:[tableOnDisplay priority]-1] removeObject:tableOnDisplay];
      }
      [tableOnDisplay setPriority:[tablePriority intValue]];
      [tableOnDisplay setNextToFollowing:[tableNextToFollowing intValue]];
      [[priorityTables objectAtIndex:[tableOnDisplay priority]-1] addObject:tableOnDisplay];

      [tableOnDisplay storeInDatabase];
      [self updateMatrix];
   }
   [window orderOut:self];
}

- (void)selectAppropriateTableFor:(id<Playable>) aPlayable;
{
	NSMatrix *tableMatrix = [tournamentTableBrowser matrixInColumn:0];
	NSString *tableStr = [aPlayable tableString];
	long selectRow = -1;
	if ([tableStr length] > 0) {
		int preDeterminedTable = [tableStr intValue];
		long i=0, max=[tableMatrix numberOfRows];
		while ((i<max) && ([[[tableMatrix cellAtRow:i column:0] tournamentTable] number] != preDeterminedTable)) {
			i++;
		}
		if (i<max) {
			selectRow = i;
		}
	}
	if (selectRow < 0) {
		long desiredPriority = [aPlayable desiredTablePriority], selectedPriority;
		long i, max = [tableMatrix numberOfRows];
		
		i = max-1;
		while ( (i>0) && ([[[tableMatrix cellAtRow:i column:0] tournamentTable] priority] > desiredPriority) ) {
			i--;
		}
		selectedPriority = [[[tableMatrix cellAtRow:i column:0] tournamentTable] priority];
		
		selectRow = i;
		if (selectedPriority < desiredPriority) {
			if ((i < max-1)
					&& ([[[tableMatrix cellAtRow:i column:0] tournamentTable] priority] <= desiredPriority+1)) {
				selectRow+=1;
			}
		}
	}
	
	[tournamentTableBrowser selectRow:selectRow inColumn:0];
	[tournamentTableBrowser setNeedsDisplay:YES];
}

- (void)assign:(long)count tablesTo:(id<Playable>) aPlayable;
{
   int i;
   NSArray *selectedTables = [tournamentTableBrowser selectedCells];

   for(i=0; i<count; i++) {
      TournamentTable *table = [[selectedTables objectAtIndex:i] tournamentTable];
      [aPlayable addTable:[table number]];
      [table setOccupiedBy:aPlayable];
   }
   
   [self updateMatrix];
}

- (bool)assignTablesTo:(id<Playable>) aPlayable;
{
	NSArray *selectedTables = [tournamentTableBrowser selectedCells];
	
	if ([aPlayable numberOfTables] <= [selectedTables count]) {
		if ([selectedTables count] == 1) {
			long preDetTable = [[aPlayable tableString] integerValue];
			long selectedTable = [[[selectedTables objectAtIndex:0] tournamentTable] number];
			if ((preDetTable > 0) && (preDetTable != selectedTable)) {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = NSLocalizedStringFromTable(@"Vorbestimmter Tisch", @"Tournament", nil);
            alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Passt nicht zu", @"Tournament", nil), preDetTable, selectedTable];
            [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
            [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Neu zuweisen", @"Tournament", nil)];
            if ([alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn) {
               return false;
            }
			}
		}
		[self assign:[aPlayable numberOfTables] tablesTo:aPlayable];
		
		return true;
	} else {
		NSString *zuWenigTische = NSLocalizedStringFromTable(@"Zu wenige Tische", @"Tournament", nil);
		NSString *fordert = NSLocalizedStringFromTable(@"%@ fordert %d Tische an\nes sind aber nur %d selektiert",
																									 @"Tournament", nil);
		NSString *abbrechen = NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil);
		NSString *wenigerSpielen = NSLocalizedStringFromTable(@"mit weniger Tischen spielen", @"Tournament", nil);
      NSAlert *alert = [[NSAlert alloc] init];
      alert.messageText = zuWenigTische;
      alert.informativeText = [NSString stringWithFormat:fordert, [aPlayable description], [aPlayable numberOfTables], [selectedTables count]];
      [alert addButtonWithTitle:abbrechen];
      [alert addButtonWithTitle:wenigerSpielen];
      if ([alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn) {
         return false;
      } else {
         [self assign:[selectedTables count] tablesTo:aPlayable];
         return true;
      }
	}
}

- (void)freeTablesOf:(id<Playable>) aPlayable;
{
   long i, j, maxPriorities = [priorityTables count];
   
   for(i=0; i<maxPriorities; i++) {
      NSArray *priority = [priorityTables objectAtIndex:i];
      long max = [priority count];
      
      for (j=0; j<max; j++) {
         TournamentTable *table = (TournamentTable *)[priority objectAtIndex:j];
         
         if ([table occupiedBy] == aPlayable) {
            [table setOccupiedBy:nil];
         }
      }
   }
   
   [self updateMatrix];
}

- (IBAction)freeAllTables:(id)sender;
{

   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
   alert.informativeText = NSLocalizedStringFromTable(@"Wirklich alle Tische freigeben?!", @"Tournament", null);
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ja", @"Tournament", null)];
   [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSAlertSecondButtonReturn) {
         long i, j, maxPriorities = [priorityTables count];
         for(i=0; i<maxPriorities; i++) {
            NSArray *priority = [priorityTables objectAtIndex:i];
            long max = [priority count];
            
            for (j=0; j<max; j++) {
               TournamentTable *table = (TournamentTable *)[priority objectAtIndex:j];
               
               if ([table occupiedBy] != nil) {
                  [table setOccupiedBy:nil];
                  [table storeInDatabase];
               }
            }
         }
         
         [self updateMatrix];
      }
   }];
}

@end

@implementation NSAlert (Cat)

-(NSModalResponse) synchronousModalSheetForWindow:(NSWindow *)aWindow
{
   [self beginSheetModalForWindow:aWindow completionHandler:^(NSModalResponse returnCode) {
      [NSApp stopModalWithCode:returnCode];
   } ];
   return [NSApp runModalForWindow:[self window]];
}

@end
