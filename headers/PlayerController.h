//
//  PlayerController.h
//  Tournament
//
//  Created by Paul Trunz on Wed Dec 26 2001.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SinglePlayer.h"
#import "PlaySeriesController.h"

@interface PlayerController : NSObject<NSTableViewDataSource> {
	id table;
	id playerWindow;
	IBOutlet PlaySeriesController *playSeriesController;
	id seriesController;
	long rows;
	
	NSMutableArray *players;
	NSMutableDictionary *playersInTournament;
	NSMutableString *filterClub;
	NSMutableString *filterName;
	long currentLicence;
@private
	BOOL selectionWasEdited;
}

- init;
- (IBAction)getPlayersInClub:(id)sender;
- (IBAction)getPlayersWithLastName:(id)sender;
- (IBAction)getPlayerWithPass:(id)sender;
- newPlayerWithSameClub:sender;
- checkSeriesForSelectedPlayer:sender;
- (void) showWindow:sender;

- (void) getPlayersWithClub:(NSString *)club;
- (void) getPlayersWithName:(NSString *)name;
- (void) getPlayerWithLicence:(int)pass;
- (void) retrievePlayersWithClub:(NSString *)club;
- (void) retrievePlayersWithName:(NSString *)name;
- (void)fixNumberFormats;
- (NSDictionary *)allPlayers;
- (SinglePlayer *)playerWithLicence:(long)licence;
- (SinglePlayer *)playerForLicence:(long)licence;
- (NSWindow *) playerWindow;
- (PlaySeriesController *) participationController;
- (NSArray<SinglePlayer *>*)playersMatching:(NSString *)fragment;

/********    datasource methods for a table view    ********/
- (long)numberOfRowsInTableView:(NSTableView *)aTableView;
- (id)tableView:(NSTableView *)aTableView
      objectValueForTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;
- (void)tableView:(NSTableView *)aTableView
		setObjectValue:(id)anObject
		forTableColumn:(NSTableColumn *)aTableColumn
		row:(int)rowIndex;

/********    delegate methods for a table view    ********/
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView;
- (void)tableViewSelectionDidChange:(NSNotification *)aNotification;
@end
