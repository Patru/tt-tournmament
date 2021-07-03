/*****************************************************************************
     Use: Control a table tennis tournament.
          Display an umpires name in a BrowserCell.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 11.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import "UmpireBrowserCell.h"

@implementation UmpireBrowserCell

- (instancetype)init;
{
   return [self initUmpire:nil];
} // init

- (instancetype)initTextCell:(const char *)aString;
/* this seems to be the standard initializer of NSBrowserCell,
   just init with nil and discard the stringvalue which is passed to it. */
{
   return [self initUmpire:nil];
} // initTextCell

- (instancetype)initUmpire:(SinglePlayer *)aPlayer;
/* in: aPlayer: the Player which should be displayed in the BrowserCell
 what: sets the Player to aPlayer and performs all other necessary
       initializations.
*/
{
   self=[super initTextCell:@"Schiedsrichter"];
   umpire = aPlayer;
   // as of yet, no other initialization is neccessary
   [self setLeaf:YES];
   return self;
} // initPlayer

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
/* in: cellFrame:   the frame to fit in
       controlView: the View in which drawing takes place (assume: lockFocus'es)
 what: draws the information of Player into cellFrame
return:self
*/
{
   const int texty = NSMinY(cellFrame) + 1;
   const int name  = NSMinX(cellFrame) + 1;
   const int prio  = NSMaxX(cellFrame) - 30;
   NSColor *backgroundColor, *txtColor;
   NSMutableDictionary * textAttributes =
      [NSMutableDictionary dictionaryWithObject:[NSFont systemFontOfSize:12.0]
				         forKey:NSFontAttributeName];

   if ([self state] == NSOnState) {
      backgroundColor = [[self  highlightColorWithFrame:cellFrame inView:controlView] highlightWithLevel:0.4];
      // this stupid bugger will usually be dark when focused and light gray when not, need to meddle with this
      txtColor = [NSColor blackColor];
   } else {
      backgroundColor = [NSColor whiteColor];
      txtColor = [NSColor blackColor];
   }
   [backgroundColor set];
   [NSBezierPath fillRect:cellFrame];
   [textAttributes setObject:txtColor forKey:NSForegroundColorAttributeName];

   [[umpire longName] drawAtPoint:NSMakePoint(name, texty)
		   withAttributes:textAttributes];
   [[NSString stringWithFormat:@"%4.2f", [umpire tourPriority]]
          drawAtPoint:NSMakePoint(prio, texty) withAttributes:textAttributes];
}

- (void)setUmpire:(SinglePlayer *)aPlayer;
{
   umpire = aPlayer;
} // setPlayer

- (SinglePlayer *)umpire;
{
   return umpire;
} // Player
@end

