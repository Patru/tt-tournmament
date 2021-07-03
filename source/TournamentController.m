/*****************************************************************************
     Use: Control a table tennis tournament.
          Main controller object.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 2.1.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "TournamentController.h"
#import "Tournament-Swift.h"
#import "Group.h"
//#import "GroupMakerController.h"
#import "MatchBrowser.h"
#import "NotPresentController.h"
#import "PlayerController.h"
#import "PWController.h"
#import "SeriesController.h"
#import "UmpireController.h"
#import <regex.h>
#import <ctype.h>
#include <stdio.h>
#include <stdlib.h>

@implementation TournamentController

- init
{
   // TODO: replace with keyed coders
   [Group setVersion:1];
   [Match setVersion:4];
   [Series setVersion:7];
   [WinnerPlayer setVersion:1];
	
	return self;
} // init

- (MatchBrowser *) matchBrowser;
{
   return matchBrowser;
} // matchBrowser

- (PlayingMatchesController *) playingMatchesController;
{
   return playingMatchesController;
}

- (IBAction)saveDocument:(id)sender;
{
	NSMutableArray *rootList;
	
	if ([[self.matchWindow representedFilename] length] == 0) {
		[self saveDocumentAs:sender];
      return;
	} // if
	
	rootList=[NSMutableArray array];
   [rootList addObjectsFromArray:[TournamentDelegate.shared rootList]];

   if ([NSArchiver archiveRootObject:rootList toFile:[self.matchWindow representedFilename]]) {
		[self.matchWindow setDocumentEdited:NO];
	} else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", null);
      alert.informativeText = NSLocalizedStringFromTable(@"Datei kann nicht gespeichert werden", @"Tournament", null);
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Ok", @"Tournament", null)];
      [alert beginSheetModalForWindow:[TournamentDelegate.shared.matchController matchWindow] completionHandler:nil];
	}
}

- (void)appendXmlHeader:(NSMutableString *)text;
{
	Tournament *tournament = TournamentDelegate.shared.tournament;
   NSString *dateFromString = [TournamentDelegate.shared.clickTtFormat stringFromDate:tournament.dateFrom];
   NSString *dateToString = [TournamentDelegate.shared.clickTtFormat stringFromDate:tournament.dateTo];
	[text appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
	[text appendString:@"<!DOCTYPE tournament SYSTEM \"https://liga.nu/dtd/TournamentPortalSTT.dtd\">\n"];
	[text appendFormat:@"<tournament start-date=\"%@\" end-date=\"%@\" region=\"%@\" type=\"%@\"\n",
	 dateFromString, dateToString, tournament.region, tournament.type];
	[text appendFormat:@" name=\"%@\"\n", tournament.title];
	[text appendFormat:@" tournament-id=\"%@\">\n", tournament.clickTtId];
}

- (void)appendXmlFooter:(NSMutableString *)text;
{
	[text appendString:@"</tournament>\n"];
}

- (void)storeMatchResultsToFile:(NSString *)path;
{
	NSDictionary *attributes = [[NSDictionary alloc] init];
	NSMutableString *text = [NSMutableString string];
	[self appendXmlHeader:text];
	[TournamentDelegate.shared.seriesController appendFinishedSeriesTo:text];
	[self appendXmlFooter:text];
	NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
	
	[[NSFileManager defaultManager] createFileAtPath:path contents:textData attributes:attributes];
	
}

- (IBAction)exportXmlResults:(id)sender;
{
	NSSavePanel *savePanel = [NSSavePanel savePanel];
   savePanel.allowedFileTypes=[NSArray arrayWithObject:@"xml"];
   savePanel.message = @"store the match results as click-TT compatible XML";
   savePanel.nameFieldStringValue = @"Click-TT-Export.xml";
	savePanel.directoryURL = [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
	
   [savePanel beginSheetModalForWindow:self.matchWindow completionHandler:^(NSInteger result) {
      if (result == NSModalResponseOK) {
         [self storeMatchResultsToFile:[[savePanel URL] path]];
      }
   }];
}

- (IBAction)saveDocumentAs:(id)sender;
{  NSSavePanel *savePanel = [NSSavePanel savePanel];
	NSString *directory;

   if ([[self.matchWindow representedFilename] length] != 0) {
		directory=[[self.matchWindow representedFilename] stringByDeletingLastPathComponent];
	} else {
      directory = NSHomeDirectory();
   }

   savePanel.directoryURL = [NSURL fileURLWithPath:directory isDirectory:YES];
   [savePanel setAllowedFileTypes:[NSArray<NSString *> arrayWithObjects:@"match", nil]];
   [savePanel beginSheetModalForWindow:self.matchWindow completionHandler:^(NSInteger result) {
      if (result == NSModalResponseOK) {
         [matchesWin setRepresentedURL:[savePanel URL]];
         NSString *name = [matchesWin representedFilename];
         [matchesWin setTitleWithRepresentedFilename: name];

         [self saveDocument:sender];
      }
   }];
   
} // saveAs

- (IBAction)loadPlayersFromClickTt:(id)sender {
   NSWindow *matchWindow = [TournamentDelegate.shared.matchController matchWindow];
   NSWindow *importWin = TournamentDelegate.shared.matchController->importWindow;
   NSProgressIndicator *progress = TournamentDelegate.shared.matchController->importProgress;
   NSTextField *activity = TournamentDelegate.shared.matchController->importActivity;
   [matchWindow beginSheet:importWin completionHandler:nil];
   [ClickTtLoader downloadPlayersFromClickTt: importWin progress:progress activity:activity];
}

- (IBAction)dismissLoadInfoDialog:(id)sender;
{
   NSWindow *importWin = TournamentDelegate.shared.matchController->importWindow;
   [importWin.sheetParent endSheet:importWin];
}

- (PlayingTableController *)playingTableController;
{
   return playingTableController;
}

- (UmpireController *) umpireController;
{
   return umpireController;
} // umpireController

// clumsy workaround to cover up our single window nature
- (SearchController *)searchController;
{
   return searchController;
}


- (BOOL) openFile:(NSString *)filename;
{
   NSMutableArray *rootList=[NSUnarchiver unarchiveObjectWithFile:filename];
   
/*   [TournamentDelegate.shared.playerController setValue:[rootList objectAtIndex:0]
                              forKey:@"playersInTournament"];
   SeriesController *seriesController = TournamentDelegate.shared.seriesController;
   [seriesController setValue:[rootList objectAtIndex:1] forKey:@"seriesList"];
   [seriesController rebuildMap];
   [TournamentDelegate.shared setAllMatches:[rootList objectAtIndex:2]];
   [TournamentDelegate.shared set_lastNumberedMatch:[[rootList objectAtIndex:3] intValue]];
   if ([rootList count] > 4) {
      [[self matchBrowser] setMatches:[rootList objectAtIndex:4]];
   }
   if ([rootList count] > 5) {
      [TournamentDelegate.shared.seriesController setSeriesGrouping:[rootList objectAtIndex:5]];
   }
   
   if ([rootList count] > 6) {
      [TournamentDelegate.shared.groupMakerController setConfirmationState:[rootList objectAtIndex:6]];
   } */
   [TournamentDelegate.shared resetFrom: rootList];
   
   if ([[self matchBrowser] hasBackup]
       || [[self playingMatchesController] hasBackup]
       || [[self umpireController] hasBackup]
       || [TournamentDelegate.shared.notPresentController hasBackup]
       || [[self playingTableController] hasBackup]) {
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:NSLocalizedStringFromTable(@"Vorsicht!", @"Tournament", null)];
      [alert setInformativeText:NSLocalizedStringFromTable(@"Recovery-Daten vorhanden!", @"Tournament", null)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"loeschen", @"Tournament", null)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"benutzen", @"Tournament", null)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
      [alert beginSheetModalForWindow:matchesWin completionHandler:^(NSModalResponse returnCode) {
         if (returnCode == NSAlertSecondButtonReturn) {
            [[self umpireController] useBackup:YES];
            [[self umpireController] setRestoreInProgress:YES];
            [TournamentDelegate.shared.notPresentController useBackup:YES];
            [[self matchBrowser] useBackup:YES];
            [[self playingMatchesController] useBackup:YES];
            [[self playingTableController] readFromDatabase:self];
            [[self umpireController] setRestoreInProgress:NO];
         } else if (returnCode == NSAlertFirstButtonReturn) {
            if ([TournamentDelegate.shared.passwordController checkPasswordFor:matchesWin] == 1) {
               [[self umpireController] useBackup:NO];
               [TournamentDelegate.shared.notPresentController useBackup:NO];
               [[self playingMatchesController] useBackup:NO];
               [[self matchBrowser] useBackup:NO];
               [[self playingTableController] readEmptiedTables];
            }
         }

      }];
//      [alert beginSheetModalForWindow:matchesWin modalDelegate:self didEndSelector:@selector(recoveryDidEnd:returnCode:contextInfo:) contextInfo:nil];
   }
   [matchesWin setTitleWithRepresentedFilename:filename];
   return YES;
}

// TODO: remove
- (void)recoveryDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
   if (returnCode == NSAlertSecondButtonReturn) {
      [[self umpireController] useBackup:YES];
      [[self umpireController] setRestoreInProgress:YES];
      [TournamentDelegate.shared.notPresentController useBackup:YES];
      [[self matchBrowser] useBackup:YES];
      [[self playingMatchesController] useBackup:YES];
      [[self playingTableController] readFromDatabase:self];
      [[self umpireController] setRestoreInProgress:NO];
   } else if (returnCode == NSAlertFirstButtonReturn) {
      PWController *password = [[PWController alloc] init];
      
      if ([password checkPw:self] == 1) {
         [[self umpireController] useBackup:NO];
         [TournamentDelegate.shared.notPresentController useBackup:NO];
         [[self playingMatchesController] useBackup:NO];
         [[self matchBrowser] useBackup:NO];
         [[self playingTableController] readEmptiedTables];
      }
   }

}

- (IBAction)openDocument:(id)sender;
{
   NSOpenPanel *panel = [NSOpenPanel openPanel];
   NSString *name = [matchesWin representedFilename];
   panel.allowedFileTypes=[NSArray arrayWithObject:@"match"];

   if ([name length] > 0) {
      panel.representedFilename=[name lastPathComponent];
      panel.directoryURL=[NSURL fileURLWithPath:[name stringByDeletingLastPathComponent] isDirectory:YES];
   } else {
      panel.representedFilename=@"";
      panel.directoryURL=[NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
   }

   [panel beginSheetModalForWindow:self.matchWindow completionHandler:^(NSInteger result) {
      if (result == NSModalResponseOK) {
         // this should really be `self`, maybe st some point it will be ...
         [TournamentDelegate.shared.matchController openFile:panel.URL.path];
      }
   }];
}

- (void)importCsvTablesTimes:(NSURL *)filename;
// it is surprisingly difficult to safely read one single line in Unix!
{
	FILE *file = fopen([[filename path] UTF8String], "r");
	char *line = NULL;
	size_t len = 0;

	line = fgetln(file, &len);
	if ((line == NULL) || (len <= 0)) {
		return;
	} // else: discard the header
	while ((line = fgetln(file, &len)) != NULL) {
		if (line[len-1] == '\n') {		// discard terminating newline if there is one
			len = len-1;
		}
		if (line[len-1] == '\r') {		// this is winodows (or old MacOS for that matter) bullshit, just to be sure
			len = len-1;
		}
    NSString* row = [[NSString alloc] initWithBytes:line length:len encoding:NSUTF8StringEncoding];
		NSArray* columns = [row componentsSeparatedByString:@";"];
		if ([columns count] == 3) {
			NSString *matchStr = [[columns objectAtIndex:0] stringByTrimmingCharactersInSet:
																 [NSCharacterSet whitespaceCharacterSet]];
			int matchNumber = [matchStr intValue];
			Match * match = [TournamentDelegate.shared playableWithNumber:matchNumber];
			if (match != nil) {
				NSString *tableStr = [[columns objectAtIndex:1] stringByTrimmingCharactersInSet:
												 [NSCharacterSet whitespaceCharacterSet]];
				[match setTableString:tableStr];
				NSString *timeStr = [[columns objectAtIndex:2] stringByTrimmingCharactersInSet:
														 [NSCharacterSet whitespaceCharacterSet]];
				[match setPlannedStart:timeStr];
			} else {
				NSLog(@"Match %d not found", matchNumber);
			}
		} else {
			NSLog(@"illegal file format for importing tables&times, %ld columns instead of 3", [columns count]);
		}
	}
   fclose(file);
}

- (IBAction)importTablesTimes:(id)sender;
{
   NSOpenPanel *panel = [NSOpenPanel openPanel];
   panel.directoryURL=[NSURL fileURLWithPath:NSHomeDirectory()];
   panel.allowedFileTypes=[NSArray arrayWithObject:@"csv"];
   
   [panel beginSheetModalForWindow:self.matchWindow completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSFileHandlingPanelOKButton) {
         [self importCsvTablesTimes:panel.URL];
      }
   }];
}

- (IBAction)importPlayersExternalSource:(id)sender;
{
   NSOpenPanel *panel = [NSOpenPanel openPanel];
   panel.directoryURL=[NSURL fileURLWithPath:NSHomeDirectory()];
   panel.allowedFileTypes=[NSArray arrayWithObject:@"csv"];
   
   [panel beginSheetModalForWindow:self.matchWindow completionHandler:^(NSModalResponse returnCode) {
      if (returnCode == NSFileHandlingPanelOKButton) {
         [TournamentDelegate.shared importCsvPlayersWithExternalSource:panel.URL];
      }
   }];
}

- (NSWindow *) matchWindow;
{
   if (matchesWin != nil) {
      return matchesWin;
   } else {
      NSArray<NSWindow *> *windws = [NSApplication.sharedApplication windows];
      for (NSWindow *windw in windws) {
         NSLog(@"Window %@", [windw title]);
         if ([windw.windowController.contentViewController isKindOfClass:[TournamentController class]]) {
            matchesWin = windw;
         }
      }
   }
   return matchesWin;
}

- (void)viewDidAppear;
{
   NSLog(@"view was loaded, deterimine window");
   matchesWin = [[self view] window];
   TournamentDelegate.shared.matchController = self;
   self.view.window.frameAutosaveName = @"TournamentMain";
}

- (IBAction)loadAdditionalSeries:(id)sender;
{
   [[TournamentDelegate.shared seriesController] loadAdditionalSeries:sender];
}

// The way we connect this MainViewController to the app is not quite correct, so this clumsy piece of glue is required
- (IBAction)updateSearch:(NSSearchField *)sender;
{
   [[TournamentDelegate.shared.matchController searchController] updateSearch:sender];
}



@end
