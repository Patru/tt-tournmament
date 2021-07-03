
#import <Cocoa/Cocoa.h>
#import "InspectorController.h"
#import "Group.h"

@interface GroupInspector:InspectorController <InspectorControllerProtocol>
{
	IBOutlet NSForm *infoForm;
	IBOutlet NSView *matchView;
	IBOutlet NSBrowser *matches;
	IBOutlet NSMatrix *players;
	IBOutlet NSView *playerView;
	IBOutlet NSMatrix *licences;
	IBOutlet NSTextField *tableField;
@private
	Group *_group;
}

- (IBAction)addPlayer:(id)sender;
- (NSView *)fillMatchView;
- (NSView *)fillPlayerView;
- removeLastPlayer:sender;
- playSingleMatches:sender;
- (IBAction)recomputeRanking:(id)sender;
- (void)setGroup:(Group *)group;
- (void)updateFromPlayerView;
- (void) sizeLicencesAndPlayersTo:(long)numberOfPlayers;
- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;

@end
