/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls play, tableDraw and display of the series.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 2.1.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "SeriesController.h"
#import "ClubResult.h"
#import "ConsolationGroupSeries.h"
#import "ConsolationGroupedSeries.h"
#import "DoubleSeries.h"
#import "DoubleGroupSeries.h"
#import "GroupSeries.h"
#import "MixedSeries.h"
#import "MixedGroupSeries.h"
#import "PlaySeries.h"
#import "RaiseGroupSeries.h"
#import "Series.h"
#import "SeriesPlayer.h"
#import "SinglePlayer.h"
#import "RLQualiSeries.h"
#import "RLQualiDamenSeries.h"
#import "SeriesBrowserCell.h"
#import "SimpleGroupSeries.h"
#import "SmallTextController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"
#import "TournamentInspectorController.h"
#import "TournamentView.h"
#import "TournamentViewController.h"
#import <PGSQLKit/PGSQLKit.h>

@implementation SeriesController

- init;
{
   self=[super init];
	seriesList = [[NSMutableArray alloc] init];
	seriesMap = [[NSMutableDictionary alloc] init];
	// to be deleted
	seriesWithGroups = [[NSMutableArray alloc] init];
	return self;
} // init


- (void) nichtAusgelost;
{
   Series *ser = [(SeriesBrowserCell *)[seriesBrowser selectedCell] series];
   NSAlert *alert = [[NSAlert alloc] init];

   alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Serie noch nicht ausgelost", @"Tournament", null), [ser fullName]];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Fortlaufend auslosen", @"Tournament", nil)];
   [alert beginSheetModalForWindow:seriesWindow completionHandler:^(NSModalResponse returnCode) {
      
      if (NSAlertFirstButtonReturn == returnCode) {
         // this is cancel actually, so do nothing
      } else if (NSAlertSecondButtonReturn == returnCode) {
         [ser startSeries];
         [seriesBrowser display];
      }

   }];
}

- (void) keineSerieGewaehlt;
{
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
   alert.informativeText = NSLocalizedStringFromTable(@"Keine Serie gewaehlt", @"Tournament", nil);
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
   [alert beginSheetModalForWindow:seriesWindow completionHandler:nil];
}

- (void)doTableDrawAll:(NSWindow *)sheet returnCode:(int) returnCode contextInfo:(void *)contextInfo;
{
	if (returnCode == NSAlertFirstButtonReturn) {
		NSArray *allSeries = [[seriesBrowser matrixInColumn:0] cells];
		long i, max = [allSeries count];
		for (i=0; i<max; i++) {
			[[(SeriesBrowserCell *)[allSeries objectAtIndex:i] series] doDraw];
		}
		[seriesBrowser display];
	}
}

- doTableDraw:sender
{
	SeriesBrowserCell *selected = [seriesBrowser selectedCell];
	if (selected == nil) {
      NSAlert *alert = [[NSAlert alloc] init];
      alert.messageText = NSLocalizedStringFromTable(@"Alle Serien auslosen", @"Tournament", nil);
		alert.informativeText = NSLocalizedStringFromTable(@"Sollen jetzt alle Serien ausgelost werden?",
																					@"Tournament", nil);
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ja", @"Tournament", nil)];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Nein", @"Tournament", nil)];
      
      [alert beginSheetModalForWindow:seriesWindow completionHandler:^(NSModalResponse returnCode) {
         if (returnCode == NSAlertFirstButtonReturn) {
            dispatch_async(dispatch_get_main_queue(), ^{
               NSArray *allSeries = [[seriesBrowser matrixInColumn:0] cells];
               long i, max = [allSeries count];
               for (i=0; i<max; i++) {
                  [[(SeriesBrowserCell *)[allSeries objectAtIndex:i] series] doDraw];
               }
               [seriesBrowser loadColumnZero];
            });
         }
      }];
   } else {
      NSInteger selectedIndex = [seriesBrowser selectedRowInColumn:0];
      [[selected series] doDraw];
      dispatch_async(dispatch_get_main_queue(), ^{
         [seriesBrowser loadColumnZero];
         [seriesBrowser selectRow:selectedIndex inColumn:0];
      });
   }
   return self;
}

- draw:sender
{
   Series *ser = [(SeriesBrowserCell *)[seriesBrowser selectedCell] series];
   if (ser == nil)
   {
		[self keineSerieGewaehlt];
		return self;
   } // if
   if ([ser alreadyDrawn]) {
      [TournamentDelegate.shared.tournamentViewController setSeries:ser];
   } else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", null);
      alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Serie noch nicht ausgelost", @"Tournament", null), [ser fullName]];
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Oohh", @"Tournament", null)];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Trotzdem darstellen", @"Tournament", null)];
      if ([alert synchronousModalSheetForWindow:seriesWindow] == NSAlertFirstButtonReturn) {
         return self;
      } // if
   } // if
   return self;
}

- (void)loadWindow;
{
   if (seriesWindow == nil)
   {
      if ([[NSBundle mainBundle] loadNibNamed:@"Series" owner:self topLevelObjects:nil]) {
         [seriesBrowser setCellClass:[SeriesBrowserCell class]];
      } else {
         printf("could not load series Nib");
      }
   } // if
}

- (IBAction)show:sender
{
	[self loadWindow];
   [seriesWindow makeKeyAndOrderFront:self];
   if ([seriesList count] == 0) {
      [self loadSeriesData];
   }
	[seriesBrowser loadColumnZero];
} //

- showPositions:sender;
{
   Series *ser = [(SeriesBrowserCell *)[seriesBrowser selectedCell] series];
   if (ser != nil) {
		if ([ser alreadyDrawn]) {
			if (![ser started]) {
				[posA selectText:self];
				[posWindow makeKeyAndOrderFront:self];
			} else {
            NSAlert *alert = [NSAlert new];
            alert.messageText = NSLocalizedStringFromTable(@"Achtung!", @"Tournament", nil);
            alert.informativeText = NSLocalizedStringFromTable(@"Serie bereits begonnen,\nkeine weiteren Wechsel möglich.", @"Tournament", nil);
            [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Ok", @"Tournament", nil)];
            [alert beginSheetModalForWindow:seriesWindow completionHandler:nil];
			}
		} else {
			[self nichtAusgelost];
		}
	} else {
		[self keineSerieGewaehlt];
	}
   return self;
} // showPositions
   
- (IBAction)start:(NSButton *)sender;
{
   Series *ser = [(SeriesBrowserCell *)[seriesBrowser selectedCell] series];
   if (ser == nil)
   {
		[self keineSerieGewaehlt];
      return;
   } // if
   if ([ser alreadyDrawn]) {
      if (![ser started]) {
			[ser printWONPPlayersInto:TournamentDelegate.shared.smallTextController];
			[TournamentDelegate.shared showSmallText];
         NSAlert *alert = [NSAlert new];
         alert.informativeText = NSLocalizedStringFromTable(@"Alle WO Spieler ueberprueft?", @"Tournament", nil);
         [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ja, anfangen", @"Tournament", nil)];
         [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Nein! Warte noch", @"Tournament", nil)];
         [alert beginSheetModalForWindow:seriesWindow completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSAlertFirstButtonReturn) {
               [ser startSeries];
               [TournamentDelegate.shared.matchController saveDocument:self];
               [seriesBrowser display];
            }
         }];
      } else {
         NSAlert *alert = [[NSAlert alloc] init];
			alert.informativeText = NSLocalizedStringFromTable(@"Serie bereits gestartet", @"Tournament", nil);
         [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
         [alert beginSheetModalForWindow:seriesWindow completionHandler:nil];
      } // if
   } else {
		[self nichtAusgelost];
   } // if
}

- (NSString *) seriesGrouping;
{
	if ([seriesGroup indexOfSelectedItem] == 0) {
		return @"";
	} else {
		return [seriesGroup titleOfSelectedItem];
	}
}

- (void)setSeriesGrouping:(NSString *)grouping;
{
	if ([grouping length] == 0) {
		[seriesGroup selectItemAtIndex:0];
	} else {
		[seriesGroup selectItemWithTitle:grouping];
	}
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
// method implemented to serve as a delegate
{
   id cell;
   long i, max = [seriesList count];

   if(![[sender cellPrototype] isKindOfClass:[SeriesBrowserCell class]])
   {
      cell = [[SeriesBrowserCell alloc] init];
      [matrix setPrototype:cell];
   } // if
   
	NSString *grouping = [self seriesGrouping];
	int loadedCells = 0;
	
   for(i=0; i<max; i++)
   {
		Series *series = [seriesList objectAtIndex:i];
		if ([series matches:grouping]) {
			[matrix addRow];
			cell = [matrix cellAtRow:loadedCells column:0];
			[cell setSeries:[seriesList objectAtIndex:i]];
			[cell setLoaded:YES];
			[cell setLeaf:YES];
			loadedCells++;
		}
   } // for
}

- addSeries:(Series *)aSeries;
{  long i, max = [seriesList count];
   i = max;
   while ((i > 0) && ([[[seriesList objectAtIndex:i-1] startTime]
								compare:[aSeries startTime]] == NSOrderedDescending))
   {
      i--;
   } // while
   [seriesList insertObject:aSeries atIndex:i];
	[seriesMap setObject:aSeries forKey:[aSeries seriesName]];
  
   return self;
} // addSeries

- (IBAction)posOk:(id)sender;
{
   Series *ser = [(SeriesBrowserCell *)[seriesBrowser selectedCell] series];
   if ( (ser != nil) && ([ser alreadyDrawn]) && (![ser started]) ) {
      [ser switchPos:[posA intValue] with:[posB intValue]];
   } // if
  
   [posWindow orderOut:self];
   [TournamentDelegate.shared.tournamentViewController setSeries:ser];
} // posOk

- (IBAction) allMatchSheets:(id)sender;
// print all matches in a Sheet
{
   Series *ser = (Series *)[[seriesBrowser selectedCell] series];
   if (ser != nil) {
      if ([ser alreadyDrawn]) {
         [ser allMatchSheets:sender];
      } else {
         [self nichtAusgelost];
      }
   } else {
      [self keineSerieGewaehlt];
   }
}

- testSeriesForWO:sender;
// Tests if all the players are here. Displays the WO-players of the
// series in the small text Window
{
   Series *ser = (Series *)[[seriesBrowser selectedCell] series];
   
   [ser printWONPPlayersInto:TournamentDelegate.shared.smallTextController];
   [TournamentDelegate.shared showSmallText];
   
   return self;
} // testSeries

- (IBAction) rankingList:sender;
// displays the ranking list of the current series in the small text window
{
   Series *ser = [(SeriesBrowserCell *)[seriesBrowser selectedCell] series];
	if (ser != nil) {
		if ([ser finished]) {
			[ser textRankingListIn:TournamentDelegate.shared.smallTextController];
			[TournamentDelegate.shared showSmallText];
		} else {
         NSAlert *alert = [NSAlert new];
         alert.messageText = NSLocalizedStringFromTable(@"Fehler!", @"Tournament", nil);
         alert.informativeText = NSLocalizedStringFromTable(@"Serie noch nicht fertig", @"Tournament", nil);
         [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
         [alert beginSheetModalForWindow:seriesWindow completionHandler:nil];
		} // if
	} else {
		[self keineSerieGewaehlt];
	}
} // rankingList

-(void) gatherPointsIn:(NSMutableDictionary *)clubResults;
{
	long i, max=[seriesList count];
	for (i=0; i<max; i++) {
		[[seriesList objectAtIndex:i] gatherPointsIn:clubResults];
	}
}

- (IBAction) clubScoreIn:(id)text;
{
	[text clearText];
	[text setTitleText:[NSString stringWithFormat:@"Clubwertung %@\n",
											TournamentDelegate.shared.tournament.title]];
	NSMutableDictionary *clubResults = [NSMutableDictionary dictionaryWithCapacity:20];
	[self gatherPointsIn:clubResults];
	 NSArray *sortedClubs;
	
	sortedClubs = [[clubResults allValues] sortedArrayUsingSelector:@selector(compare:)];
	
	long i, max=[sortedClubs count];
	BOOL showDetails = [TournamentDelegate.shared.preferences groupDetails];
	
	for (i=0; i<max; i++) {
		ClubResult *clubRes = [sortedClubs objectAtIndex:i];
		[clubRes appendAsLineTo:text];
		if (showDetails) {
			NSArray *results = [clubRes results];
			long j, rMax = [results count];
			for (j=0; j<rMax; j++) {
				[[results objectAtIndex:j] appendAsLineTo:text];
			}
		}
	}
}

- (void) evaluateAllSeriesWith:(id<ClubEvaluator>) evaluator;
{
   for (Series *series in seriesList) {
      [evaluator evaluateFor:series];
   }
}
	 
- (IBAction) clubScore:(id)sender;
{
   NSPopUpButton *button = (NSPopUpButton *)sender;
   
   SmallTextController *text = TournamentDelegate.shared.smallTextController;
   if ([button selectedTag] == 0) {
      WinnerPointsEvaluator * evaluator = [[ZkmClubsEvaluator alloc] init];
      [self evaluateAllSeriesWith:evaluator];
      [evaluator showResultIn:text withDetails:TournamentDelegate.shared.preferences.groupDetails];
   } else if ([button selectedTag] == 1) {
      WinnerPointsEvaluator * evaluator = [[BerbierPokalEvaluator alloc] init];
      [self evaluateAllSeriesWith:evaluator];
      [evaluator showResultIn:text withDetails:TournamentDelegate.shared.preferences.groupDetails];
   } else {
      [self clubScoreIn:text];
   }
   [TournamentDelegate.shared showSmallText];
}
	 
- (void)posCancel:sender;
{
   [posWindow orderOut:self];
}

- (void)reloadSeriesData;
// just for tests
{
   [seriesList removeAllObjects];
   [self loadSeriesData];
}

- (bool)alreadyHas:(Series *)series;
{
   Series *ser;
   
   for (ser in seriesList) {
      if ([[ser seriesName] isEqualToString:[series seriesName]]) {
         return true;
      }
   }
   return false;
}

- (IBAction)loadAdditionalSeries:(id)sender;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *selectAllForTournmaent = [NSString stringWithFormat:@"SELECT %@ FROM Series WHERE TournamentID = '%@' ORDER BY FullName", [Series allFields], TournamentDelegate.shared.preferences.tournamentId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectAllForTournmaent];
   
   PGSQLRecord *record = [rs moveFirst];
   while (record != nil) {
      Series *ser = [self makeSeriesFrom:record];
      if (![self alreadyHas:ser]) {
         [self addSeries:ser];
      }
      record = [rs moveNext];
   }
   [self fixGroupings];
}

- (Series *)makeSeriesFrom:(PGSQLRecord *)record;
{
   Series *ser;
   NSString *type = [[record fieldByName:SerFields.Type] asString];

   switch (toupper([type characterAtIndex:0])) {
      case 'D':
         ser = [DoubleSeries alloc];
         break;
      case 'E':
         ser = [EloSeries alloc];
         break;
      case 'F':
         ser = [Elo18Series alloc];
         break;
      case 'G':
         ser = [GroupSeries alloc];
         break;
      case 'L':
         ser = [DoubleGroupSeries alloc];
         break;
      case 'M':
         ser = [MixedGroupSeries alloc];
         break;
      case 'O':
         ser = [Series alloc];
         break;
      case 'P':
         ser = [Elo12PlusSeries alloc];
         break;
      case 'Q':
         ser = [RLQualiSeries alloc];
         break;
      case 'R':
         ser = [RaiseGroupSeries alloc];
         break;
      case 'S':
         ser = [SimpleGroupSeries alloc];
         break;
      case 'T':
         ser = [ConsolationGroupSeries alloc];
         break;
      case 'U':
         ser = [ConsolationGroupedSeries alloc];
         break;
      case 'V':
         ser = [Elo14Series alloc];
         break;
      case 'W':
         ser = [RLQualiDamenSeries alloc];
         break;
      case 'X':
         ser = [MixedSeries alloc];
         break;
      default:
         ser = [Series alloc];
         break;
   }
   
   return [ser initFromRecord:record];
}

- (void)loadSeriesData;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *selectAllForTournmaent = [NSString stringWithFormat:@"SELECT %@ FROM Series WHERE TournamentID = '%@' ORDER BY StartTime", [Series allFields], TournamentDelegate.shared.preferences.tournamentId];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectAllForTournmaent];
   
   PGSQLRecord *record = [rs moveFirst];
   while (record != nil) {
      [self addSeries:[self makeSeriesFrom:record]];
      record = [rs moveNext];
   }
   [self fixGroupings];
} // loadSeriesData

- (IBAction) selectSeries:sender;
// select series in inspector
{
   [[TournamentDelegate.shared tournamentInspector] inspect:[[sender selectedCell] series]];
} // selectSeries

- (void) storeSeriesWithGroups:(Series *)aSeries;
{
	[seriesWithGroups addObject: aSeries];
}

- (void)rebuildMap;
{
	long i, max=[seriesList count];

	for (i=0; i<max; i++) {
		Series *aSeries=[seriesList objectAtIndex:i];
		[seriesMap setObject:aSeries forKey:[aSeries seriesName]];
	}
	[self fixGroupings];
}

- (Series *)seriesWithName:(NSString *)name;
{
	return [seriesMap objectForKey:name];
}

- (NSMutableArray *)allContinuouslyDrawableSeries;
{
	long i, max = [seriesList count];
	NSMutableArray *drawables = [NSMutableArray arrayWithCapacity:max];
	for (i=0; i<max; i++) {
		Series *seri = [seriesList objectAtIndex:i];
		if ([seri respondsToSelector:@selector(addGroupForPlayers:)] && [seri respondsToSelector:@selector(drawFromGroups)]) {
			[drawables addObject:seri];
		}
	}
	return drawables;
}

- (IBAction) publishInscriptions:(id)sender;
{
	NSString *directory = @"/tmp";
	NSString *filename = @"Anmeldungen.html";
	NSMutableString *command = [NSMutableString stringWithFormat:@"cd %@; ", directory];
	NSString *pathName = [NSString stringWithFormat:@"%@/%@", directory, filename];
	
	[self storeAllInscriptionsAsHTMLToFile:pathName];
	[command appendString:TournamentDelegate.shared.tournament.upload];
	[command appendFormat:@" %@", filename];
	system([command UTF8String]);
}

- (void)appendHeader;
{
	[html appendString:@"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01 TRANSITIONAL//EN\">\n"];
	[html appendString:@"<head>\n"];
	[html appendString:@"<meta content=\"text/html; charset=UTF-8\" http-equiv=\"Content-Type\" />"];
	[html appendFormat:@"<title>%@ %@</title>\n", TournamentDelegate.shared.tournament.title,
	 NSLocalizedStringFromTable(@"Anmeldungen", @"Tournament", null)];
	[html appendString:@"</head>\n"];
}

- (long)totalAnmeldungen;
{
   PGSQLConnection *db = TournamentDelegate.shared.database;
   NSString *selectDistinctLicences = [NSString stringWithFormat:@"SELECT COUNT(*) FROM (SELECT Distinct %@ from PlaySeries WHERE %@='%@')", PSFields.Pass, PSFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId];
   id<GenDBRecordset> rs = [db open:selectDistinctLicences];
   if (![rs isEOF]) {
      return [[rs fieldByIndex:0] asLong];
   } else {
      return 0l;
   }
}

- (long)playersFor:(NSString *)group;
{
	PGSQLConnection *db = [TournamentDelegate.shared database];
   NSString *countAllPlayersInGroup = [NSString stringWithFormat:@"SELECT COUNT(*) FROM (SELECT Distinct %@ FROM PlaySeries WHERE %@='%@' AND %@ IN (SELECT %@ FROM Series WHERE %@ = '%@')", PSFields.Pass, PSFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId, PSFields.Series, SerFields.SeriesName, SerFields.Grouping, group];
   id<GenDBRecordset> rs = [db open:countAllPlayersInGroup];
   if (![rs isEOF]) {
      return [[rs fieldByIndex:0] asLong];
   } else {
      return 0l;
   }
}

- (long)anmeldungenFor:(NSString *)group;
{
	PGSQLConnection *db = [TournamentDelegate.shared database];
   NSString *countAllInscriptionsInGroup = [NSString stringWithFormat:@"SELECT COUNT(*) FROM PlaySeries WHERE %@='%@' AND %@ IN (SELECT %@ FROM Series WHERE %@ = '%@')", PSFields.TournamentID, TournamentDelegate.shared.preferences.tournamentId, PSFields.Series, SerFields.SeriesName, SerFields.Grouping, group];
   id<GenDBRecordset> rs = [db open:countAllInscriptionsInGroup];
   
   if (![rs isEOF]) {
      return [[rs fieldByIndex:0] asLong];
   } else {
      return 0l;
   }
}

- (NSString *)emailChars;
{
	NSString *emailAddress = @"";
	NSMutableString *chars = [NSMutableString string];
	int i;
	
	for (i=0; i<[emailAddress length]; i++) {
		if (i > 0) {
			[chars appendString:@","];
		}
		[chars appendFormat:@"%i", [emailAddress characterAtIndex:i]];
	}
	return chars;
}

- (NSString *)riddledEmailLink;
{
	NSString *subject = @"subject=Web%20Anmeldung";
	NSString *body = @"body=Club:%20%0D%0AName:%20%0D%0ALizenz:%20%0D%0ASerien:%20%0D%0A%0D%0A"
		@"Name:%20%0D%0ALizenz:%20%0D%0ASerien:%20%0D%0A";
	NSString *eaVar = [NSString stringWithFormat:@"eax%u", arc4random_uniform(1000)];
	NSString *scriptFormat = @"<script type=\"text/javascript\">\n"
		@"/*<![CDATA[*/\n\n"
		@"var eCharsArray=[%@]\n"
		@"var %@=''\n"
		@"for (var i=0; i<eCharsArray.length; i++)\n"
		@"%@+=String.fromCharCode(eCharsArray[i])\n\n"
		@"document.write('<a href=\"mailto:'+%@+'?%@&%@\">'+%@+'</a>')\n\n"
		@"/*]]>*/\n"
		@"</script>";
	return [NSString stringWithFormat:scriptFormat, [self emailChars], eaVar, eaVar, eaVar, subject, body, eaVar];
}

- (void)appendErrorsHint;
{
   [html appendString:@"<p>"];
   [html appendFormat:@"%@ <br>", NSLocalizedStringFromTable(@"Anmeldungsdaten automatisch", @"Tournament", null)];
//   [html appendFormat:NSLocalizedStringFromTable(@"Fehler melden", @"Tournament", null), [self riddledEmailLink]];
   [html appendFormat:@"<span style=\"color:#EE0033\">%@</span>", 
		NSLocalizedStringFromTable(@"nur aufgefuehrt ausgelost", @"Tournament", nil)];
   [html appendString:@"</p>\n"];
}

- (void)appendTotalAnmeldungen;
{
	if ([seriesGroup numberOfItems] <= 1) {
		NSString *totalAnmeldungen = NSLocalizedStringFromTable(@", total %d Anmeldungen", @"Tournament", nil);
		[html appendFormat:totalAnmeldungen, [self totalAnmeldungen]];
	} else {
		[html appendFormat:@", %@ ", NSLocalizedStringFromTable(@"total", @"Tournament", nil)];
		NSArray *items = [seriesGroup itemArray];
		long i, max=[items count];
		NSString *anmeldungenTag = NSLocalizedStringFromTable(@"%d Spieler und %d Anmeldungen am %@",
																				@"Tournament", nil);
		
		for (i=1; i<max; i++) {
			if (i > 1) {
				[html appendString:@", "];
			}
			NSString *group = [[items objectAtIndex:i] title];
			[html appendFormat:anmeldungenTag, [self playersFor:group], [self anmeldungenFor:group], group];
		}
	}
}

- (void)appendBodyTitle;
{
   [html appendFormat:@"<h1>%@ %@</h1>\n", TournamentDelegate.shared.tournament.title,
		NSLocalizedStringFromTable(@"Anmeldungen", @"Tournament", nil)];
   [html appendFormat:@"%@: ", NSLocalizedStringFromTable(@"Stand", @"Tournament", nil)];
   NSDate *today = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
   [html appendString:[dateFormatter stringFromDate:today]];
	[self appendTotalAnmeldungen];
	[self appendErrorsHint];
}

- (void)appendBodyFooter;
{
	[self appendErrorsHint];
}

- (void)appendSeries;
{
   long i, max=[seriesList count];

   [html appendFormat:@"<a name=\"top\"><h2>%@</h2></a>\n",
		NSLocalizedStringFromTable(@"Serien", @"Tournament", nil)];
   for(i=0; i<max; i++) {
      Series *series = [seriesList objectAtIndex:i];

      [html appendString:@"<a href=\"#"];
      [html appendString:[series seriesName]];
      [html appendString:@"\">"];
      [html appendString:[series fullName]];
      [html appendString:@"</a><br>\n"];
   }
   
   for(i=0; i<max; i++) {
      Series *series = [seriesList objectAtIndex:i];

      [series appendAsHTMLTo:html];
      [html appendFormat:@"<a href=\"#top\">%@</a>\n", NSLocalizedStringFromTable(@"Serien", @"Tournament", nil)];
   }   
}

- (void)appendBody;
{
   [html appendString:@"<body>"];
   [self appendBodyTitle];
   [self appendSeries];
   [self appendBodyFooter];
   [html appendString:@"</body>"];
}

- (void)storeAllInscriptionsAsHTMLToFile:(NSString *)path;
{
   NSDictionary *attributes = [[NSDictionary alloc] init];
   html = [NSMutableString stringWithString:@"<html>\n"];
   [self appendHeader];
   [self appendBody];
   [html appendString:@"</html>"];
   NSData *htmlData = [html dataUsingEncoding:NSUTF8StringEncoding];
   
   [[NSFileManager defaultManager] createFileAtPath:path contents:htmlData attributes:attributes];

}

- (void)appendHeaderText:(NSMutableString *)text;
{
   [text appendString:@"UpperLicence\tupperRanking\tLowerLicence\tlowerRanking\tWinnerLicence"
      @"\tSeriescode\tWO\tMatchId\tNextMatchId\n"];
}

- (void)appendFinishedSeriesTo:(NSMutableString *)text;
{
	long i, max=[seriesList count];
	
	for(i=0; i<max; i++) {
		Series *series = [seriesList objectAtIndex:i];
		
		if ([series finished]) {
			[series appendAsXmlTo:text];
		}
	}
}

- (void)appendSeriesResultsAsTextTo:(NSMutableString *)text;
{
   long i, max=[seriesList count];

   for(i=0; i<max; i++) {
      Series *series = [seriesList objectAtIndex:i];

      [series appendSingleResultsAsTextTo:text];
   }
}

- (void)storeAllSingleResultsAsTextToFile:(NSURL *)path;
{
   NSMutableString *text = [NSMutableString string];
   [self appendHeaderText:text];
   [self appendSeriesResultsAsTextTo:text];
   NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
   
   [textData writeToURL:path atomically:YES];

// TODO: remove if above works [[NSFileManager defaultManager] createFileAtPath:path contents:textData attributes:attributes];
}

- (NSAttributedString *) listsForDraw;
{
   NSArray *tabStops = [NSMutableArray arrayWithObjects:
                        [[NSTextTab alloc] initWithType:NSLeftTabStopType location:153.0],
                        [[NSTextTab alloc] initWithType:NSRightTabStopType location:303.0],
                        [[NSTextTab alloc] initWithType:NSRightTabStopType location:333.0],
                        [[NSTextTab alloc] initWithType:NSRightTabStopType location:383.0],
                        [[NSTextTab alloc] initWithType:NSRightTabStopType location:423.0],
                        nil];
   NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle alloc] init];
   [textStyle setTabStops:tabStops];
   
   NSDictionary *textAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSFont fontWithName:@"Helvetica" size:12.0], NSFontAttributeName,
                                   textStyle, NSParagraphStyleAttributeName, nil];
   NSDictionary *titleAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSFont fontWithName:@"Helvetica-Bold" size:12.0], NSFontAttributeName, nil];
   
   NSMutableAttributedString *buf = [[NSMutableAttributedString alloc] init];
   [buf beginEditing];
   long i, max=[seriesList count];
   for (i=0; i<max; i++) {
      Series *ser = [seriesList objectAtIndex:i];
      NSString *serLine = [NSString stringWithFormat:@"%@\n", [ser fullName]];
      NSAttributedString *seriesLine = [[NSAttributedString alloc] initWithString: serLine
                                                                        attributes: titleAttributes];
      [buf appendAttributedString:seriesLine];
      [ser loadPlayersFromDatabase];
      NSArray *pls = [ser players];
      long j, plMax = [pls count];
      for (j=0; j<plMax; j++) {
         SeriesPlayer *serPl = [pls objectAtIndex:j];
         id<Player> player = [serPl player];
         long elo = 0;
         if ([player respondsToSelector:@selector(elo)]) {     // TODO: This looks even more fishy now, do in protocol
            elo = [(SinglePlayer *)player elo];
         }
         NSString *line = [NSString stringWithFormat:@"%@\t%@\t%ld\t%ld\t%ld\n", [player longName], [player club],
                           [player rankingInSeries:ser], [serPl setNumber], elo];
         NSAttributedString *attrLine = [[NSAttributedString alloc] initWithString:line attributes: textAttributes];
         [buf appendAttributedString:attrLine];
      }
   }
   [buf endEditing];
   
   return buf;
}

- (IBAction) allSingleResultsAsText:(id)sender;
{
   NSSavePanel *savePanel = [NSSavePanel savePanel];
	
   [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
   [savePanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
   [savePanel setNameFieldStringValue:@"Einzelresultate.txt"];
	
   if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
      [self storeAllSingleResultsAsTextToFile:[savePanel URL]];
   } // if
}

- (void)appendSeriesInfoHeaderText:(NSMutableString *)text;
{
   [text appendString:@"CodeSerie\tDame\tBonus\tNeg\n"];
}

- (void)appendSingleSeriesInfoAsTextTo:(NSMutableString *)text;
{
   long i, max=[seriesList count];
	
   for(i=0; i<max; i++) {
      Series *series = [seriesList objectAtIndex:i];
		
      [series appendSingleSeriesInfoAsTextTo:text];
   }
}

- (void)storeSingleSeriesInfoToFile:(NSURL *)path;
{
   NSMutableString *text = [NSMutableString string];
   [self appendSeriesInfoHeaderText:text];
   [self appendSingleSeriesInfoAsTextTo:text];
   NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
	
   [textData writeToURL:path atomically:YES];
// TODO: remove   [[NSFileManager defaultManager] createFileAtPath:path contents:textData attributes:[NSDictionary dictionary]];
	
}

- (IBAction) saveSingleSeriesInfo:(id)sender;
{
   NSSavePanel *savePanel = [NSSavePanel savePanel];
	
   [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"txt"]];
   [savePanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
   [savePanel setNameFieldStringValue:@"SeriesInfo.txt"];

   if ([savePanel runModal] == NSFileHandlingPanelOKButton) {
      [self storeSingleSeriesInfoToFile:[savePanel URL]];
   } // if
}

- (IBAction) saveSeriesAsPDF:(id)sender;
{
	long i, max = [seriesList count];

	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
		NSURL *dir = [openPanel directoryURL];
	
		for (i=0; i<max; i++) {
			Series *ser = [seriesList objectAtIndex:i];
			
			if ([ser alreadyDrawn]) {
				[TournamentDelegate.shared.tournamentViewController saveSeries:ser
																	asPDFToDirectory:dir];
			}
		}
		NSString *uploadScript = TournamentDelegate.shared.tournament.upload;
		
		if ([uploadScript length] > 0) {
			NSMutableString *command = [NSMutableString stringWithFormat:@"cd %@; ", [dir path]];
			[command appendString:uploadScript];

			system([command UTF8String]);
		}
	}
}

- (IBAction) printAllSeries:(id)sender;
{
   NSAlert *alert = [NSAlert new];
   alert.messageText = NSLocalizedStringFromTable(@"Alle Serien drucken", @"Tournament", nil);
   alert.informativeText = NSLocalizedStringFromTable(@"Welche Serien drucken?",	@"Tournament", nil);
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Alle", @"Tournament", nil)];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Nur laufende", @"Tournament", nil)];
   [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
   [alert beginSheetModalForWindow:seriesWindow completionHandler:^(NSModalResponse returnCode) {
      if (returnCode != NSAlertThirdButtonReturn) {
         bool printEvery = (returnCode == NSAlertFirstButtonReturn);
         NSArray *allSeries = [[seriesBrowser matrixInColumn:0] cells];
         long i, max = [allSeries count];
         for (i=0; i<max; i++) {
            Series *ser = [(SeriesBrowserCell *)[allSeries objectAtIndex:i] series];
            if ( printEvery || ([ser started] && (![ser finished])) ) {
               [TournamentDelegate.shared.tournamentViewController printSensiblePagesOf:ser];
            }
         }
//         [seriesBrowser display];
      }
   }];
}

- (IBAction) selectGroup:(id)sender;
{
	[seriesBrowser loadColumnZero];
}

- (IBAction) fixDrawOrderOnDb:(NSButton *)sender;
{

}

- (void)fixGroupings;
{
	[self loadWindow];
	while ([seriesGroup numberOfItems] > 1) {
		[seriesGroup removeItemAtIndex:1];
	}
	
	NSMutableArray *groupings = [NSMutableArray array];
	long i, max=[seriesList count];
	
	for (i=0; i<max; i++) {
		NSString *grouping = [[seriesList objectAtIndex:i] grouping];
		if (([grouping length] > 0) && ([groupings indexOfObject:grouping] == NSNotFound)) {
			[groupings addObject:grouping];
		}
	}
	[seriesGroup addItemsWithTitles:groupings];
}

- (void) checkSeriesFinished:(Series *)series;
{
   if ([series finished]) {
      NSAlert *alert = [[NSAlert alloc] init];
      alert.messageText = NSLocalizedString(@"SerieBeendet", "");
      NSString *letztesSpiel = [NSString stringWithFormat:NSLocalizedString(@"letztesSpielGespielt", ""), [series fullName]];
      alert.informativeText = letztesSpiel;
      [alert addButtonWithTitle:NSLocalizedString(@"RanglisteDrucken", "")];
      [alert addButtonWithTitle:NSLocalizedString(@"merksMirSo", "")];
      [seriesWindow makeKeyAndOrderFront:self];
      [alert beginSheetModalForWindow:seriesWindow completionHandler:^(NSModalResponse returnCode) {
         if (returnCode == NSAlertFirstButtonReturn) {
            [series textRankingListIn:TournamentDelegate.shared.smallTextController];
            [TournamentDelegate.shared showSmallText];
         }
      }];
   }
}
- (void) removeSeries:(Series *)series;
{
   [seriesList removeObject:series];
}

- (NSWindow *)seriesWindow;
{
   return seriesWindow;
}

- (NSMutableArray *)allSeries;
{
   return seriesList;
}

@end
