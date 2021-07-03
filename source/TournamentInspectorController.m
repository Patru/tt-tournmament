#import "TournamentInspectorController.h"
#import "InspectorController.h"

@implementation TournamentInspectorController

- init;
{
	[self checkNib];
	_inspectorController=nil;
	return self;
}

- (void)checkNib;
{
	if (window == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"Inspector" owner:self topLevelObjects:nil];
	}
}


- (void) determineController: (id) object  {
  if ([object respondsToSelector:@selector(inspectorController)]) {
		_inspectorController = [object inspectorController];
	} else {
		_inspectorController = nil;
	}
}

- (void) fillView;
{
  NSView *thisView=[_inspectorController filledViewForOption:[[popup selectedCell] tag]];
	
	if (thisView != nil) {
		[self setInspectorView:thisView];
	} else {
		[self setInspectorView:defaultView];
	}
}

- (void)inspectNotKey:(id)object;
{
	[self determineController: object];
	[self fillView];	
	[window orderFront:self];
}

- (void)inspect:(id)object;
{
	[self determineController: object];
	[self updateView:self];
}

- (IBAction)ok:(id)sender
{
	[_inspectorController updateFromView];
}

- (IBAction)revert:(id)sender
{
	[self updateView:self];
}

- (void)setInspectorView:(NSView *)aView;
{
	[self checkNib];
	[contentsBox setContentView:aView];
}

- (IBAction)showMatchInspector:(id)sender
{
	[self setInspectorView:view];
	if (![window isKeyWindow]) [window makeKeyAndOrderFront:self];
}

- (IBAction)showPlayerInspector:(id)sender
{
	[self checkNib];
	if (![window isKeyWindow]) [window makeKeyAndOrderFront:self];
   [popup selectItemWithTag:0];
   [self updateView:self];
}

- (IBAction)updateView:(id)sender;
{
	[self fillView];

	if (![window isKeyWindow]) [window makeKeyAndOrderFront:self];
}

- (NSWindow *) window;
{
   return window;
}

@end
