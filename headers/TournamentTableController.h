
#import <Cocoa/Cocoa.h>
#import "Match.h"
#import "TournamentTable.h"

@interface TournamentTableController:NSObject
{
    IBOutlet NSTextField *countField;
    IBOutlet NSBrowser   *tournamentTableBrowser;
    IBOutlet NSWindow    *window;
    IBOutlet NSTextField *tableNumber;
    IBOutlet NSTextField *tablePriority;
    IBOutlet NSButton    *tableNextToFollowing;
    
@private
    NSMutableArray  *priorityTables;
    NSMutableSet    *freeTables;
    TournamentTable *tableOnDisplay;
}

- (IBAction)addTable:(id)sender;
- (IBAction)removeTable:(id)sender;
- (IBAction)readFromDatabase:(id)sender;
- (IBAction)updateTable:(id)sender;
- (IBAction)storeTable:(id)sender;
- (IBAction)freeAllTables:(id)sender;
- (void)updateMatrix;
- (void)displayTable:(TournamentTable *)table;
- (void)selectAppropriateTableFor:(id<Playable>) aPlayable;
- (bool)assignTablesTo:(id<Playable>) aPlayable;
- (void)freeTablesOf:(id<Playable>) aPlayable;

@end
