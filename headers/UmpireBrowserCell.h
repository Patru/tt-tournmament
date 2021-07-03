/*****************************************************************************
     Use: Control a table tennis tournament.
          Display an umpires name in a BrowserCell.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 11.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "SinglePlayer.h"

@interface UmpireBrowserCell:NSBrowserCell
{
   SinglePlayer *umpire;
}

- (instancetype)init;
- (instancetype)initTextCell:(const char *)aString;
- (instancetype)initUmpire:(SinglePlayer *)aPlayer;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (SinglePlayer *)umpire;
- (void)setUmpire:(SinglePlayer *)aPlayer;

@end

