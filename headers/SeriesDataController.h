//
//  SeriesDataController.h
//  Tournament
//
//  Created by Paul Trunz on Wed Dec 26 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Series.h"
#import "SinglePlayer.h"
#import "PlaySeriesController.h"

@interface SeriesDataController : NSObject {
	id table;
	id window;
	IBOutlet PlaySeriesController *playSeriesController;
	
	NSMutableArray *series;
@private
}

- init;
- (IBAction)newSeries:(NSButton *)sender;
- (void) showWindow:sender;
- (void) deleteSelected:sender;
- (void) checkSeriesFor:(SinglePlayer *)player;
- (void) showAlert:(NSAlert *)alert;

- (void) getAllSeries:sender;

/********    datasource methods for a table view    ********/
- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView
		setObjectValue:(id)anObject
		forTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;

/********    delegate methods for a table view    ********/
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;

@end
