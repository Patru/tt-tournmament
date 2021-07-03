/*****************************************************************************
     Use: Control a table tennis tournament.
          Display a match in a BrowserCell.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
History: 1.5.1994, Patru: first started
         29.4.2002, Patru: integrated into CVS
    Bugs: -not very well documented
 *****************************************************************************/

#import "MatchBrowserCell.h"
#import "Player.h"
#import "Match.h"
#import "Series.h"

@implementation MatchBrowserCell

- (instancetype)init;
{
   return [self initMatch:nil];
} // init

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

- drawInteriorWithFrame:(const NSRect)cellFrame inView:aView;
// draws the background and propagates to the match
{
  NSColor *background;
  float textGray = [match textGray];
  NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:
                                     [NSFont fontWithName:@"Helvetica" size:12.0] forKey:NSFontAttributeName];
  
  if ([self state] == NSOnState) {
    // we assume the standard highligting-color to be somewhat "dark", but do not want too much of it
    background = [[self  highlightColorWithFrame:cellFrame inView:aView] highlightWithLevel:0.4];
    if (textGray > 0.0) {
      background = [background blendedColorWithFraction:0.2 ofColor:[NSColor yellowColor]];
      textGray = 0.0;
    }
  } else {
    background = [NSColor whiteColor];
    if (textGray > 0.0) {
      background = [background blendedColorWithFraction:0.3 ofColor:[NSColor yellowColor]];
    }
  }
  
  [background set];
  [NSBezierPath fillRect:cellFrame];
  
  [attributes setObject:[NSColor colorWithCalibratedWhite:textGray alpha:1.0]
                 forKey:NSForegroundColorAttributeName];
  
  return [match drawAsOpen:cellFrame inView:aView withAttributes:attributes];
}

- setPlayable:(id <Playable>)aMatch;
{
   match = aMatch;

   return self;
} // setPlayable

- (id <Playable>)match;
{
   return match;
} // match
@end

