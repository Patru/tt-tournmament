/*****************************************************************************
     Use: Control a table tennis tournament.
          Display a match in a BrowserCell, but with printing time
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 9.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Match.h"

@interface OMBrowserCell:NSBrowserCell
{
   Match *match;
}

- initTextCell:(const char *)aString;
- initMatch:(Match *)aMatch;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (Match *)match;
- setPlayable:(Match *)aMatch;

@end

