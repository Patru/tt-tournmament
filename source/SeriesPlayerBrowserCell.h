/*****************************************************************************
 Use: Control a table tennis tournament.
 Display a match in a BrowserCell, but with printing time
 Language: Objective-C                 System: Mac OS X 10.4
 Author: Paul Trunz, Copyright 2013
 Version: 0.1, first try
 History: 10.05.2013, Patru: first started
 Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "ConfirmationPlayer.h"

@interface SeriesPlayerBrowserCell:NSBrowserCell
{
	ConfirmationPlayer *player;
}

//- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
//- (Series *)series;
- (ConfirmationPlayer *)player;
- setConfirmationPlayer:(ConfirmationPlayer *)aPlayer;

@end

