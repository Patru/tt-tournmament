/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls play, tableDraw and display of the series.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 2.1.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Series.h"

@interface SeriesController:NSObject
{
   IBOutlet	NSWindow *seriesWindow;
   IBOutlet NSBrowser *seriesBrowser;
   IBOutlet NSMenuItem *loadSeriesItem;
   IBOutlet NSWindow *posWindow;
   IBOutlet NSTextField *posA;
   IBOutlet NSTextField *posB;
	IBOutlet NSPopUpButton *seriesGroup;
	
@private
   NSMutableArray *seriesList;
   NSMutableDictionary *seriesMap;
   NSMutableString *html;
	// to be deleted
	NSMutableArray *seriesWithGroups;
}

- doTableDraw:sender;
- draw:sender;
- (IBAction)show:sender;
- showPositions:sender;
- (IBAction)start:(NSButton *)sender;
- addSeries:(Series *)aSeries;
- (IBAction)posOk:(id)sender;
- (IBAction)posCancel:(id)sender;
- (IBAction) selectSeries:sender;
- (IBAction) allMatchSheets:(id)sender;
- testSeriesForWO:sender;
- (IBAction) rankingList:sender;
- (void)loadSeriesData;
- (void)reloadSeriesData;
- (IBAction)loadAdditionalSeries:(id)sender;
- (IBAction) clubScore:(id)sender;
- (IBAction) publishInscriptions:(id)sender;
- (IBAction) allSingleResultsAsText:(id)sender;
- (NSAttributedString *) listsForDraw;
- (IBAction) saveSingleSeriesInfo:(id)sender;
- (IBAction) printAllSeries:(id)sender;
- (IBAction) saveSeriesAsPDF:(id)sender;
- (IBAction) selectGroup:(id)sender;
- (IBAction) fixDrawOrderOnDb:(NSButton *)sender;
- (void)rebuildMap;
- (Series *)seriesWithName:(NSString *)name;
- (void)fixGroupings;
- (NSString *) seriesGrouping;
- (void)setSeriesGrouping:(NSString *)grouping;

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
- (void)storeAllInscriptionsAsHTMLToFile:(NSString *)filename;
- (NSMutableArray *)allContinuouslyDrawableSeries;
- (void)appendFinishedSeriesTo:(NSMutableString *)text;
- (void) storeSeriesWithGroups:(Series *)aSeries;
- (void) checkSeriesFinished:(Series *)series;
- (void) removeSeries:(Series *)series;
- (NSWindow *)seriesWindow;
- (NSMutableArray *)allSeries;

@end
