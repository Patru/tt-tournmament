/*****************************************************************************
     Use: Control a table tennis tournament.
          Display a match in a BrowserCell, but with printing time
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 9.5.1994, Patru: first started
    Bugs: -not very well documented NSFormatter
 *****************************************************************************/

#import "OMBrowserCell.h"
#import "Player.h"
#import "Match.h"
#import "Series.h"

@implementation OMBrowserCell

//#define myhighlight
#ifdef myhighlight
- highlight:(const NSRect *)cellFrame inView:aView lit:(BOOL)lit
// Try to implement correct highlighting behaviour, unhighlight especially
{
   if (!(cFlags1.highlighted && cFlags1.state)) {
      PScompositerect(NX_X(cellFrame), NX_Y(cellFrame),
		      NX_WIDTH(cellFrame), NX_HEIGHT(cellFrame), NX_HIGHLIGHT);
   } // if
   return self;
} // higlight
#endif

- (instancetype)initTextCell:(const char *)aString;
/* this seems to be the standard initializer of NXBrowserCell,
   just init with nil and discard the stringvalue which is passed to it. */
{
   return [self initMatch:nil];
} // initTextCell

- (instancetype)initMatch:(Match *)aMatch;
/* in: aMatch: the match which should be displayed in the BrowserCell
 what: sets the match to aMatch and performs all other necessary
       initializations.
*/
{
   self=[super initTextCell:@""];
   match = aMatch;

   return self;
} // initMatch

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
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

   [match drawAsPlaying:cellFrame inView:controlView];
} // drawInside

- setPlayable:(Match *)aMatch;
{
   match = aMatch;

   return self;
} // setPlayable

- (Match *)match;
{
   return match;
} // match
@end

