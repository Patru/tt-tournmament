
#import <Cocoa/Cocoa.h>
#import "InspectorController.h"
#import "SinglePlayer.h"

@interface PlayerInspector:InspectorController <InspectorControllerProtocol>
{
   IBOutlet NSTextField *activity;
   IBOutlet NSTextField *currentMatch;
   IBOutlet NSForm *infoForm;
   IBOutlet NSBrowser *matches;
   IBOutlet NSView *matchView;
   IBOutlet NSTextField *numberOfMatches;
   IBOutlet NSView *playerView;
   IBOutlet NSButton *present;
   IBOutlet NSButton *ready;
   IBOutlet NSTextField *tourPriority;
   IBOutlet NSButton *wo;
   @private
      SinglePlayer *_player;
}

- (void)browser:(NSBrowser *)sender createRowsForColumn:(int)column inMatrix:(NSMatrix *)matrix;

- (NSView *)filledViewForOption:(long) option;
- (void)fillMatchView;
- (void)fillPlayerView;
- (IBAction)inspectMatch:(id)sender;
- (IBAction)selectMatch:(id)sender;
- (void)setPlayer:(SinglePlayer *)player;
- (void)updateFromPlayerView;
- (void)updateFromView;
@end
