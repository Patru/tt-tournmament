/*****************************************************************************
 Use: Control a table tennis tournament.
 Display a match in a BrowserCell, but with printing time
 Language: Objective-C                 System: Mac OS X 10.4
 Author: Paul Trunz, Copyright 2013
 Version: 0.1, first try
 History: 10.05.2013, Patru: first started
 Bugs: -not very well documented
 *****************************************************************************/

#import "SeriesPlayerBrowserCell.h"
#import "Series.h"

@implementation SeriesPlayerBrowserCell


- (void)_drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
/* in: cellFrame: the frame to fit in
 aView:     the View in which drawing takes place (assume: lockFocus'ed)
 what: draws the information of match into cellFrame
 */
{
	if ([self state] == NSOnState) {
		[[[self highlightColorWithFrame:cellFrame inView:controlView] highlightWithLevel:0.4] set];
	} else {
		[[NSColor whiteColor] set];
	}
	[NSBezierPath fillRect:cellFrame];
	
	//	[match drawAsPlaying:cellFrame inView:controlView];
} // drawInside

- setConfirmationPlayer:(ConfirmationPlayer *)aPlayer;
{
	player = aPlayer;

	[self setTitle:[NSString stringWithFormat:@"%@ (%@, %@)", [[[player seriesPlayer] player] longName],
									[[player series] fullName], [[[player seriesPlayer] player] club]]];
	
	return self;
}

- (ConfirmationPlayer *)player;
{
	return player;
} 
@end

