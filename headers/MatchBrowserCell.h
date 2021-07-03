/*****************************************************************************
     Use: Control a table tennis tournament.
          Display a match in a BrowserCell.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 1.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Match.h"

@interface MatchBrowserCell:NSBrowserCell
{
   id <Playable> match;
}

- (instancetype)initTextCell:(const char *)aString;
- (instancetype)initMatch:(Match *)aMatch;

- drawInteriorWithFrame:(const NSRect)cellFrame inView:aView;
- (id <Playable>)match;
- setPlayable:(id <Playable>)aMatch;

@end

