/*****************************************************************************
 Use: Control a table tennis tournament.
 Display a match in a BrowserCell, but with printing time
 Language: Objective-C                 System: Mac OS X 10.4
 Author: Paul Trunz, Copyright 2013
 Version: 0.1, first try
 History: 26.01.2013, Patru: first started
 Bugs: -not very well documented
 *****************************************************************************/

#import "CategoryBrowserCell.h"
#import "Series.h"

@implementation CategoryBrowserCell


- initSeries:(Series *)aSeries;
{
	series = aSeries;
	self=[super initTextCell:[self fullNameWithGroupsAndPlayers:0]];

	return self;
}

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
}

- (NSString *)fullNameWithGroupsAndPlayers:(long)plCount;
{
	NSString *titl = [NSString stringWithFormat:@"%@ (%ld/%ld)", [series fullName], [series numberOfGroupsDrawn], plCount];
	NSLog(@"%@", titl);
	
  return titl; 
}

- setSeries:(Series *)aSeries withConfirmed:(NSArray *)players;
{
	series = aSeries;
	confirmedPlayers = players;
	
	[self setTitle:[self fullNameWithGroupsAndPlayers:[players count]]];
	
	return self;
}

- (Series *)series;
{
	return series;
} 
@end

