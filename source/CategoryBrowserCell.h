/*****************************************************************************
 Use: Control a table tennis tournament.
 Display a match in a BrowserCell, but with printing time
 Language: Objective-C                 System: Mac OS X 10.4
 Author: Paul Trunz, Copyright 2013
 Version: 0.1, first try
 History: 26.01.2013, Patru: first started
 Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Series.h"

@interface CategoryBrowserCell:NSBrowserCell
{
	Series *series;
	NSArray *confirmedPlayers;
}

- initSeries:(Series *)aSeries;

//- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (Series *)series;
- setSeries:(Series *)aSeries withConfirmed:(NSArray *)players;
- (NSString *)fullNameWithGroupsAndPlayers:(long)plCount;

@end

