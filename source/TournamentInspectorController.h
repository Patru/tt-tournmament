/* TournamentInspectorController */

#import <Cocoa/Cocoa.h>
#import "InspectorController.h"

@interface TournamentInspectorController : NSObject
{
    IBOutlet NSBox *contentsBox;
    IBOutlet NSView *defaultView;
    IBOutlet NSView *view;
    IBOutlet NSWindow *window;
    IBOutlet NSPopUpButton *popup;
@private
	id<InspectorControllerProtocol> _inspectorController;
}
- (void)checkNib;
- (void)inspectNotKey:(id)object;
- (void)inspect:(id)object;
- (IBAction)ok:(id)sender;
- (IBAction)revert:(id)sender;
- (void)setInspectorView:(NSView *)aView;
- (IBAction)showMatchInspector:(id)sender;
- (IBAction)showPlayerInspector:(id)sender;
- (IBAction)updateView:(id)sender;
- (NSWindow *) window;
@end
