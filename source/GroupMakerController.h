//
//  GroupMakerController.h
//  Tournament
//
//  Created by Paul Trunz on 24.01.13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GroupSeries.h"

@interface GroupMakerController : NSObject<NSMenuDelegate> {
	IBOutlet NSBrowser *categoryBrowser;
	IBOutlet NSBrowser *playerBrowser;
	IBOutlet NSWindow *window;
	IBOutlet NSTextField *firstNameField;
	IBOutlet NSTextField *nameField;
	IBOutlet NSTextField *clubField;
	IBOutlet NSDatePicker *dateOfBirthField;
	IBOutlet NSComboBox *seriesField;
@private
	NSMutableArray *players;
	NSMutableArray *categories;
	NSMutableDictionary *confirmedPlayers;
	NSMutableArray *dummyCategoriesList;
	int maxLicence;
	NSDateFormatter *dateFormatter;
	NSMenu *contextMenu;
}
- init;
- (IBAction)confirmPlayer:(id)sender;
- (void)createPlayerName: (NSString *)name first:(NSString *)firstName club: (NSString *)club dateOfBirth: (NSDate *) dateOfBirth seriesName: (NSString *) seriesName;
- (IBAction)finishCategory:(id)sender;
- (IBAction)loadPlayers:(id)sender;
- (IBAction)newPlayer:(id)sender;

- (IBAction) show:(id)sender;
- (IBAction) move:(id)sender;
-(void)emptyPlayerForm;
- (NSArray *)confirmationState;
-(void)setConfirmationState:(NSArray *)objects;

- (NSArray *)players;
- (GroupSeries *)seriesForName:(NSString *)name;
- (NSArray *)confirmedPlayers:(NSString *)serName;
- (void)selectPlayerAtIndex:(long)index;
- (void)selectSeriesAtIndex:(long)index;
@end
