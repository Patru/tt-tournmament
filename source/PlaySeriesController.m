//
//  PlaySeriesController.m
//  Tournament
//
//  Created by Paul Trunz on Wed Dec 26 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "PlaySeriesController.h"
#import <PGSQLKit/PGSQLKit.h>
#import "PlayerController.h"
#import "TournamentController.h"
#import "PWController.h"
#import "Tournament-Swift.h"

@implementation PlaySeriesController

- init;
{
   playSeries = [[NSMutableArray alloc] init];

   return self;
}

- (void) newPlaySeriesWithSamePass:sender;
{
   PlaySeries *new=[[PlaySeries alloc] init];

   if ([playSeries count] > 0) {
      PlaySeries *last = [playSeries lastObject];
      [new setPass:[last pass]];
   }
   [playSeries addObject:new];
   [table reloadData];
}

- (void) newPlaySeriesWithPass:(long)pass series:(NSString *)series;
{
   PlaySeries *new=[[PlaySeries alloc] init];

   [new setPass:pass];
   [new setSeries:series];

   [playSeries addObject:new];
   [table reloadData];
}

- (void) getPlaySeriesWithPass:(long)pass;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;

   [self saveAll:self];
   [playSeries removeAllObjects];
   
   NSString *selectSeriesForPlayer = [NSString stringWithFormat:@"SELECT %@ FROM PlaySeries WHERE Licence=%ld AND TournamentID ='%@'", [PlaySeries allFields], pass, TournamentDelegate.shared.preferences.tournamentId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectSeriesForPlayer];
   
   if (rs != nil) {
      PGSQLRecord *rec = [rs moveFirst];
      while (rec != nil) {
         [playSeries addObject:[PlaySeries fromRecord:rec]];
         rec = [rs moveNext];
      }
   }

/*   NSTableColumn *licenceColumn = [(NSTableView *)table tableColumnWithIdentifier:@"Licence"];
   NSNumberFormatter *intFormatter = [[NSNumberFormatter alloc] init];
   [intFormatter setNumberStyle:NSNumberFormatterNoStyle];
   NSTextFieldCell *proto = [[NSTextFieldCell alloc] init];
   [proto setFormatter:intFormatter];

   [licenceColumn setDataCell:proto];*/
   [table reloadData];
}

	/********    delegate methods for a table view    ********/

- (long)numberOfRowsInTableView:(NSTableView *)aTableView;
{
   return [playSeries count];
}

- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
            row:(long)rowIndex;
{
   return [[playSeries objectAtIndex:rowIndex] objectFor:[aTableColumn identifier]];
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
	      row:(long)rowIndex;
{
   NSString *identifier = [aTableColumn identifier];
   
   [[playSeries objectAtIndex:rowIndex] setObject:anObject for:identifier];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
{
   // int selectedRow=[table selectedRow];

   // printf("PlaySeries selection changed to row %d\n", selectedRow);
}

- (IBAction)deleteSelected:(id)sender;
{
   long selectedRow=[table selectedRow];

   [[playSeries objectAtIndex:selectedRow] deleteFromDatabase];
   [playSeries removeObjectAtIndex:selectedRow];

   [table reloadData];
}

- (IBAction) saveAll:(id)sender;
{
   long i, max=[playSeries count];

   for(i=0; i<max; i++) {
      [[playSeries objectAtIndex:i] storeInDatabase];
   }
}

- (IBAction)deleteWholeDatabase:(id)sender;
{
   NSWindow *playerWindow = TournamentDelegate.shared.playerController.playerWindow;
  
   if ([TournamentDelegate.shared.passwordController checkPasswordFor:playerWindow]) {
      PGSQLConnection *database=TournamentDelegate.shared.database;
      NSString *deleteAllEntries = [NSString stringWithFormat:@"DELETE FROM PlaySeries WHERE TournamentID ='%@'", TournamentDelegate.shared.preferences.tournamentId];

      [database execCommand:deleteAllEntries];
   }
}

- (void)fixNumberFormats;
{
   NSTableColumn *licenceColumn = [table tableColumnWithIdentifier:PSFields.Pass];
   NSTableColumn *partnerColumn = [table tableColumnWithIdentifier:PSFields.PartnerPass];
   NSNumberFormatter *intFormatter = [[NSNumberFormatter alloc] init];
   
   [intFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
   [[licenceColumn dataCell] setFormatter:intFormatter];
   [[partnerColumn dataCell] setFormatter:intFormatter];
}

-(IBAction)replaceAssignments:(id)sender;
{
   NSWindow *playerWindow = TournamentDelegate.shared.playerController.playerWindow;
   NSOpenPanel *panel = [NSOpenPanel openPanel];
   panel.allowedFileTypes=[NSArray arrayWithObject:@"csv"];
   
   panel.representedFilename=@"";
   panel.directoryURL=[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
   
   [panel beginSheetModalForWindow:playerWindow completionHandler:^(NSInteger result) {
      if (result == NSModalResponseOK) {
         NSError* error;
         NSString *lines = [NSString stringWithContentsOfURL:panel.URL encoding:NSUTF8StringEncoding error:&error];
         if (error == nil) {
            long before = [AssignmentManager numberOfAssignments];
            [AssignmentManager deleteAssignments];
            long newAssignments = [AssignmentManager load:lines];
            NSAlert *alert = [NSAlert new];
            alert.messageText = NSLocalizedString(@"completed", nil);
            NSString *infoFormat = NSLocalizedString(@"entryImportCompleted", nil);
            alert.informativeText = [NSString stringWithFormat:infoFormat, before, newAssignments];
            [alert beginSheetModalForWindow:playerWindow completionHandler:nil];
         } else {
            [playerWindow presentError:error];
         }

         //[TournamentDelegate.shared.matchController openFile:panel.URL.path];
      }
   }];

}

- (NSArray *) shownSeries;
{
   return playSeries;
}
@end
