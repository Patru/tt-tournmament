//
//  GroupMakerController.m
//  Tournament
//
//  Created by Paul Trunz on 24.01.13.
//  Copyright 2013 __MyCompanyName__. All rights reserved.
//

#import "GroupMakerController.h"
#import <PGSQLKit/PGSQLKit.h>
#import "CategoryBrowserCell.h"
#import "ClubPlayers.h"
#import "ConsolationGroupedSeries.h"
#import "ConfirmationPlayer.h"
#import "PlaySeries.h"
#import "Series.h"
#import "SeriesController.h"
#import "SeriesPlayerBrowserCell.h"
#import "SinglePlayer.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation GroupMakerController

-(void)emptyPlayerForm;
{
	[firstNameField setStringValue:@""];
	[nameField setStringValue:@""];
	[clubField setStringValue:@""];
	[seriesField setStringValue:@""];
	
	NSDate *today = [NSDate date];
	NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
	NSDateComponents *components = [gregorian components:NSCalendarUnitYear fromDate:today];
	[components setDay:1];
	[components setMonth:1];
	[components setYear:[components year]-15];
	NSDate *fifteenYearsAgo = [gregorian dateFromComponents:components];
	
	[dateOfBirthField setDateValue:fifteenYearsAgo];
}

-init;
{
	self=[super init];
	players = [[NSMutableArray alloc] init];
	categories = [[NSMutableArray alloc] init];
	confirmedPlayers = [[NSMutableDictionary alloc] init];
	maxLicence = 0;
	dateFormatter = nil;
	contextMenu = [[NSMenu alloc] initWithTitle:@"Verschieben"];
	[contextMenu setDelegate:self];

	return self;
}

-(void) determineSeriesFieldChoices;
{
	long i, max=[categories count];
	
	for(i=0; i<max; i++) {
		Series *ser = [categories objectAtIndex:i];
		
		[seriesField addItemWithObjectValue:[ser fullName]];
	}
}

- (IBAction) show:(id)sender;
{
	if (window == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"GroupMaker" owner:self topLevelObjects:nil];

		[self emptyPlayerForm];
		[categoryBrowser setMenu:contextMenu];
		[self determineSeriesFieldChoices];
	}
	[window makeKeyAndOrderFront:self];
}

// TODO: there would be a removeAllItems method, but it only starts with 10.6, elimintate when updating
- (void)clearContextMenu;
{
	long i, max=[contextMenu numberOfItems]-1;
	
	for(i=max; i>= 0; i--) {
		[contextMenu removeItemAtIndex:i];
	}
}

- (void)addMoveTargetsFor:(GroupSeries *)series;
{
	NSString *start = [[series fullName] substringToIndex:3];
	long i, max=[categories count];
	NSMutableArray *lessSuitable = [NSMutableArray arrayWithCapacity:8];
	
	for(i=0; i<max; i++) {
		GroupSeries *category = [categories objectAtIndex:i];
		if (([[category fullName] hasPrefix:start]) && [category olderThan:series]) {
			NSMenuItem *item = [contextMenu addItemWithTitle:[category fullName] action:@selector(move:) keyEquivalent:@""];			
			[item setTarget:self];			
		} else {
			[lessSuitable addObject:[category fullName]];
		}
	}
	[contextMenu addItem: [NSMenuItem separatorItem]];
	max=[lessSuitable count];
	for (i=0; i<max; i++) {
		NSMenuItem *item = [contextMenu addItemWithTitle:[lessSuitable objectAtIndex:i] action:@selector(move:) keyEquivalent:@""];			
		[item setTarget:self];			
	}
}

- (void)menuNeedsUpdate:(NSMenu *)menu
{
	long catRow = [categoryBrowser selectedRowInColumn:0];
	if (catRow >= 0) {
		GroupSeries *series = [categories objectAtIndex:catRow];
		NSMutableArray *pls = [confirmedPlayers objectForKey:[series seriesName]];
		long plRow = [categoryBrowser selectedRowInColumn:1];
		if (plRow >= 0) {
			ConfirmationPlayer *confPl = [pls objectAtIndex:plRow];
			[self clearContextMenu];
			[self addMoveTargetsFor:[confPl series]];
		} else {
			[self clearContextMenu];
			[contextMenu addItemWithTitle:@"Spieler auswählen um zu verschieben" action:nil keyEquivalent:@""];
		}
	} else {
		[self clearContextMenu];
		[contextMenu addItemWithTitle:@"Kategorie auswählen" action:nil keyEquivalent:@""];
	}
}

- (GroupSeries *)seriesForName:(NSString *)name;
{
	long i, max=[categories count];
	
	for (i=0; i<max; i++) {
		if ([[[categories objectAtIndex:i] fullName] isEqualToString:name]) {
			return [categories objectAtIndex:i];
		}
	}
	return nil;
}

- (long) catRowOf:(Series *)series;
{
	return [categories indexOfObject:series];
}

- (IBAction) move:(id)sender;
{
	long catRow = [categoryBrowser selectedRowInColumn:0];
	if (catRow >= 0) {
		GroupSeries *source = [categories objectAtIndex:catRow];
		NSMutableArray *sourcePlayers = [confirmedPlayers objectForKey:[source seriesName]];
		long plRow = [categoryBrowser selectedRowInColumn:1];
		if (plRow >= 0) {
			ConfirmationPlayer *playr = [sourcePlayers objectAtIndex:plRow];
			[sourcePlayers removeObjectAtIndex:plRow];
			GroupSeries *target = [self seriesForName:[sender title]];
			[playr setSeries:target];
			NSMutableArray *targetPlayers = [confirmedPlayers objectForKey:[target seriesName]];
			
			[targetPlayers addObject:playr];
			[categoryBrowser loadColumnZero];
			[categoryBrowser selectRow:[self catRowOf:[playr series]] inColumn:0];
			// TODO: shift the players series in the DB, just in case the program would crash without notice
		}
	}
}

- (NSArray *) draw:(long)count fromAvailableClubs:(NSDictionary *)clubs fromPlayers:(NSMutableArray *)playrs;
{
	NSArray *descendingClubs = [[clubs allValues] sortedArrayUsingSelector:@selector(compareNumberOfPlayers:)];
	long i, max = [descendingClubs count];
	long remaining=count, total=[playrs count];
	ClubPlayers *firstClub = [descendingClubs objectAtIndex:0];
	long firstCount = [[firstClub players] count];
	
	NSMutableArray *groupPlayers = [NSMutableArray array];
	
	if ((firstCount > 1) && (firstCount >= (total*4/10))) {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Vorsicht", @"Tournament", null);
		NSString *msgFormat = NSLocalizedStringFromTable(@"%@ stellt aktuell %d von %d Spielern", @"Tournament", null);
      alert.informativeText = [NSString stringWithFormat:msgFormat, [firstClub club], firstCount, total];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Zwei ziehen", @"Tournament", null)];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Mit einem fortfahren", @"Tournament", null)];
		if ([alert synchronousModalSheetForWindow:window] == NSAlertFirstButtonReturn) {
			ConfirmationPlayer *pl = [[descendingClubs objectAtIndex:0] gimmeOne];
			
			[groupPlayers addObject:[[pl seriesPlayer] player]];
			[playrs removeObject:pl];
			remaining = remaining-1;
		} // if
	}
	for (i=0; i<remaining; i++) {
		ConfirmationPlayer *pl = [[descendingClubs objectAtIndex:i%max] gimmeOne];

		[groupPlayers addObject:[[pl seriesPlayer] player]];
		[playrs removeObject:pl];
	}
	
	return groupPlayers;
}

- (void) makeGroupOf: (long)groupSize for:(GroupSeries *)series fromPlayers:(NSMutableArray *)pls;
{
	long i, max=[pls count];
	NSMutableDictionary *clubPlayers = [NSMutableDictionary dictionary];
	
	for(i=0; i<max; i++) {
		ConfirmationPlayer *confPl = [pls objectAtIndex:i];
		NSString *club = [[[confPl seriesPlayer] player] club];
		ClubPlayers *clubPls = [clubPlayers objectForKey:club];
		
		if (clubPls == nil) {
			clubPls = [ClubPlayers clubPlayers];
			[clubPlayers setObject: clubPls forKey:club];
		}
		[clubPls add:confPl];
	}
	long clubCount = [clubPlayers count];
	
	if (clubCount >= groupSize) {
		[series addGroupForPlayers:[self draw:groupSize fromAvailableClubs:clubPlayers fromPlayers:pls]];
	} else {
      NSAlert *alert = [NSAlert new];
      alert.messageText = NSLocalizedStringFromTable(@"Vorsicht", @"Tournament", null);
		NSString *msgFormat = NSLocalizedStringFromTable(@"Nur noch %d Clubs für eine Gruppe von %d Spielern", @"Tournament", null);
      alert.informativeText = [NSString stringWithFormat:msgFormat, clubCount, groupSize];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Gruppe trotzdem bilden", @"Tournament", null)];
      [alert addButtonWithTitle: NSLocalizedStringFromTable(@"Warte noch", @"Tournament", null)];
		if ([alert synchronousModalSheetForWindow:window] == NSAlertFirstButtonReturn) {
			[series addGroupForPlayers:[self draw:groupSize fromAvailableClubs:clubPlayers fromPlayers:pls]];
		}
	}
}
	 
- (void) confirm:(ConfirmationPlayer *)player;
{
	NSMutableArray *pls = [confirmedPlayers objectForKey:[[player series] seriesName]];
	[pls addObject:player];
	if ([pls count] >= 10) {
		[self makeGroupOf:4 for:[player series] fromPlayers:pls];
		[TournamentDelegate.shared.matchController saveDocument:self];
	}
	[categoryBrowser loadColumnZero];
	[categoryBrowser selectRow:[self catRowOf:[player series]] inColumn:0];
}

- (IBAction)confirmPlayer:(id)sender {
	long selRow = [playerBrowser selectedRowInColumn:0];
	ConfirmationPlayer *selectedPlayer = [players objectAtIndex:selRow];
	[players removeObjectAtIndex:selRow];
	[playerBrowser loadColumnZero];
	[self confirm:selectedPlayer];
	
	[self selectPlayerAtIndex:MIN(selRow, [players count]-1)];
}

/// we only expose this for tests
- (void)selectPlayerAtIndex:(long)index;
{
   [playerBrowser selectRow:index inColumn:0];
}

- (void)selectSeriesAtIndex:(long)index;
{
   [categoryBrowser selectRow:index inColumn:0];
}

- (IBAction)finishCategory:(id)sender {
	long row = [categoryBrowser selectedRowInColumn:0];
   if (row == -1) {
      return;
   }
	GroupSeries *series = [categories objectAtIndex:row];
	NSMutableArray *pls = [confirmedPlayers objectForKey:[series seriesName]];

	while ([pls count] >= 10) {
		[self makeGroupOf:4 for:series fromPlayers:pls];
	}
	if ([pls count] == 9) {
		[self makeGroupOf:3 for:series fromPlayers:pls];
		[self makeGroupOf:3 for:series fromPlayers:pls];
		[self makeGroupOf:3 for:series fromPlayers:pls];
	} else if ([pls count] == 8) {
		[self makeGroupOf:4 for:series fromPlayers:pls];
		[self makeGroupOf:4 for:series fromPlayers:pls];
	} else if ([pls count] == 7) {
		[self makeGroupOf:4 for:series fromPlayers:pls];
		[self makeGroupOf:3 for:series fromPlayers:pls];
	} else if ([pls count] == 6) {
		[self makeGroupOf:3 for:series fromPlayers:pls];
		[self makeGroupOf:3 for:series fromPlayers:pls];
	} else {
		[self makeGroupOf:[pls count] for:series fromPlayers:pls];
	}
	[categoryBrowser loadColumnZero];
	[series drawFromGroups];
	[TournamentDelegate.shared.matchController saveDocument:self];
}

-(void)addAllFromSeries:(GroupSeries *) aSeries;
{
	NSArray *pls = [aSeries players];
	long i, max=[pls count];
	
	for (i=0; i<max; i++) {
		SeriesPlayer *playr = [pls objectAtIndex:i];
		
		if ([playr setNumber] == 0) {
					// do not include set players for confirmation (and groups), they proceed directly to the final round
			[players addObject:[[ConfirmationPlayer alloc] initWithSeries:aSeries player:playr]];
		}
      if ([[playr player] licence] > maxLicence) {
         maxLicence = (int)[[playr player] licence];
      }
	}
	PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *selectMaxUnlicenced = [NSString stringWithFormat:@"SELECT MAX(Licence) FROM Player WHERE Licence < 9000"];
   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectMaxUnlicenced];
   if ((rs != nil) && (![rs isEOF])) {
      [rs fieldByIndex:0];
      [rs close];
   }
}

- (void)loadAllPlayersOf:(NSArray *)series;
{
	GroupSeries *seri;

	[players removeAllObjects];

	for(seri in series) {
		[seri loadPlayersFromDatabase];
		[self addAllFromSeries:seri];
	}
	[players sortUsingSelector: @selector(compare:)];
}

- (void) loadCategories {
	NSArray *sers = [[TournamentDelegate.shared seriesController] allContinuouslyDrawableSeries];
	
	[categories removeAllObjects];
  if ([sers count] > 0) {
		long i, max=[sers count];
		
		for(i=0; i<max; i++) {
			Series *ser = [sers objectAtIndex:i];
			if ([ser drawContinuosly]) {
				[categories addObject:ser];
				[confirmedPlayers setObject:[NSMutableArray array] forKey:[ser seriesName]];
			}
		}
	}
	[self determineSeriesFieldChoices];
}

- (IBAction)loadPlayers:(id)sender {
	[self loadCategories];

	[self loadAllPlayersOf:categories];
	
	[categoryBrowser loadColumnZero];
	[playerBrowser loadColumnZero];
}

- (void)createCategoriesInMatrix:(NSMatrix *)matrix;
{
	long i, max=[categories count];
	id cell;

	[matrix setPrototype:[[CategoryBrowserCell alloc] init]];
	
	for(i=0; i<max; i++) {
		Series *ser = [categories objectAtIndex:i];
		NSMutableArray *confPlayers = [confirmedPlayers objectForKey:[ser seriesName]];

		[matrix addRow];
		cell = [matrix cellAtRow:i column:0];
		[cell setSeries:ser withConfirmed:confPlayers];
		[cell setLoaded:YES];
		[cell setLeaf:NO];
	} // for	
}

- (void)createPlayersOf:(Series *)series inMatrix:(NSMatrix *)matrix;
{
	NSArray *confPlayers = [confirmedPlayers objectForKey:[series seriesName]];
	long i, max=[confPlayers count];
	
	[matrix setPrototype:[[SeriesPlayerBrowserCell alloc] init]];
	
	for(i=0; i<max; i++) {
		ConfirmationPlayer *confPlayer = [confPlayers objectAtIndex:i];
		id cell;
		
		[matrix addRow];
		cell = [matrix cellAtRow:i column:0];
		[cell setConfirmationPlayer:confPlayer];
		[cell setLoaded:YES];
		[cell setLeaf:YES];		
	}
}

- (void)createFreePlayersOfAllSeriesIn:(NSMatrix *)matrix;
{
	long i, max=[players count];
	
	[matrix setPrototype:[[SeriesPlayerBrowserCell alloc] init]];
	
	for(i=0; i<max; i++) {
		ConfirmationPlayer *confPlayer = [players objectAtIndex:i];
		id cell;
		
		[matrix addRow];
		cell = [matrix cellAtRow:i column:0];
		[cell setConfirmationPlayer:confPlayer];
		[cell setLoaded:YES];
		[cell setLeaf:YES];		
	}
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;
// fills the matches in the fields of the browser `sender`
{
	if (sender == categoryBrowser) {
		if (column==0) {
			[self createCategoriesInMatrix:matrix];
		} else {
			long catIndex = [sender selectedRowInColumn:0];
			Series *ser = [categories objectAtIndex:catIndex];
			if (ser != nil) {
				[self createPlayersOf:ser inMatrix:matrix];
			}
		}
	} else if (sender == playerBrowser) {
		if (column == 0) {
			[self createFreePlayersOfAllSeriesIn:matrix];
		}
	}
}

- (int)nextLicence;
{
	return ++maxLicence;
}

-(NSDateFormatter *)dateFormat;
{
	if (dateFormatter == nil) {
// TODO		NSString *dateForm = [NSDateFormatter dateFormatFromTemplate:@"dMy" options:0 locale:[NSLocale currentLocale]]
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
		[dateFormatter setDateFormat:@"d.M.yyyy"];
	}
	
	return dateFormatter;
}

-(void)storeInDB:(SinglePlayer *)player withConfirmation:(ConfirmationPlayer *)confPlayer;
{
	[player insertIntoDatabase];
	PlaySeries *plSer = [[PlaySeries alloc] init];
	[plSer setPass:[[[confPlayer seriesPlayer] player] licence]];
	[plSer setSeries:[[confPlayer series] seriesName]];
	[plSer insertIntoDatabase];
}

- (IBAction)newPlayer:(id)sender;
{
   [self createPlayerName:[nameField stringValue] first:[firstNameField stringValue] club:[clubField stringValue] dateOfBirth:[dateOfBirthField dateValue] seriesName:[seriesField stringValue]];

   [self emptyPlayerForm];
	[TournamentDelegate.shared.matchController saveDocument:self];
}

- (void)createPlayerName: (NSString *)name first:(NSString *)firstName club: (NSString *)club dateOfBirth: (NSDate *) dateOfBirth seriesName: (NSString *) seriesName;
{
   SinglePlayer *player = [[SinglePlayer alloc] init];
   GroupSeries *series = [self seriesForName:seriesName];
   SeriesPlayer *sPlayer = [[SeriesPlayer alloc] initPlayer:player setNumber:0];
   
   [player setFirstName:firstName];
   [player setPName:name];
   [player setClub:club];
   [player setDateOfBirth:[[self dateFormat] stringFromDate:dateOfBirth]];
   [player setRanking:1];
   [player setCategory:[series age]];
   if ([series isWomanSeries]) {
      [player setWomanRanking:1];
   }
   [player setLicence:[self nextLicence]];
   [player setReady:YES];

   ConfirmationPlayer *confPlayer = [[ConfirmationPlayer alloc] initWithSeries:series player:sPlayer];
   [self confirm:confPlayer];
   [self storeInDB:player withConfirmation:confPlayer];
}

- (NSArray *)confirmationState;
{
	NSNumber *maxLic = [NSNumber numberWithInt:maxLicence];
	return [NSArray arrayWithObjects:players, categories, confirmedPlayers, maxLic, nil];
}

-(void)setConfirmationState:(NSArray *)objects;
{
	players=[objects objectAtIndex:0];
	categories=[objects objectAtIndex:1];
	confirmedPlayers=[objects objectAtIndex:2];
	maxLicence=[[objects objectAtIndex:3] intValue];	
}

- (NSArray *)players;
{
   return players;
}

- (NSArray *)confirmedPlayers:(NSString *)serName;
{
   return [confirmedPlayers objectForKey:serName];
}
@end
