//
//  PlayerController.h
//  Tournament
//
//  Created by Paul Trunz on Wed Dec 26 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PlaySeries.h"

@interface PlaySeriesController : NSObject<NSTableViewDataSource> {
	id table;
	
	NSMutableArray *playSeries;
}

- init;
- (void) newPlaySeriesWithSamePass:sender;
- (void) newPlaySeriesWithPass:(long)pass series:(NSString *)series;
- (void) deleteSelected:sender;
- (void) deleteWholeDatabase:sender;
-(IBAction)replaceAssignments:(id)sender;
- (void) saveAll:sender;

- (void) getPlaySeriesWithPass:(long)pass;
- (void)fixNumberFormats;
- (NSArray *) shownSeries;

/********    datasource methods for a table view    ********/
- (long)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(long)rowIndex;
- (void)tableView:(NSTableView *)aTableView
		setObjectValue:(id)anObject
		forTableColumn:(NSTableColumn *)aTableColumn
		row:(long)rowIndex;

/********    delegate methods for a table view    ********/
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;

@end
