/*****************************************************************************
     Use: Control a table tennis tournament.
          Display a match in a BrowserCell, but with printing time
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 9.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import "SeriesBrowserCell.h"
#import "Player.h"
#import "Match.h"
#import "Series.h"

NSMutableDictionary *_SBCTextAttributes=nil;

@implementation SeriesBrowserCell

static NSImage *check = nil;

//#define myhighlight
#ifdef myhighlight
- highlight:(const NXRect *)cellFrame inView:aView lit:(BOOL)lit
// Try to implement correct highlighting behaviour, unhighlight especially
{
   if (!(cFlags1.highlighted && cFlags1.state))
   {
      PScompositerect(NX_X(cellFrame), NX_Y(cellFrame),
		  NX_WIDTH(cellFrame), NX_HEIGHT(cellFrame), NX_HIGHLIGHT);
   } // if
   return self;
} // higlight
#endif

- (instancetype)initTextCell:(NSString *)aString;
/* this seems to be the standard initializer of NXBrowserCell,
   just init with nil and discard the stringvalue which is passed to it. */
{
   return [self initSeries:nil];
} // initTextCell

- (instancetype)initSeries:(Series *)aSeries;
/* in: aMatch: the match which should be displayed in the BrowserCell
 what: sets the match to aMatch and performs all other necessary
       initializations.
*/
{
   self=[super initTextCell:@""];
   series = aSeries;
   // as of yet, no other initialization is neccessary
   return self;
} // initMatch

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
/* in: cellFrame: the frame to fit in
       aView:     the View in which drawing takes place (assume: lockFocus'ed)
 what: draws the information of match into cellFrame
return:self
*/
{
	NSMutableDictionary *textAttributes=[SeriesBrowserCell textAttributes];
   NSColor *backgroundColor;
   
   if ([[self series] finished]) {
      backgroundColor = [[NSColor greenColor] colorWithAlphaComponent:0.2];
   } else {
      backgroundColor = [NSColor whiteColor];
   }
   
   if ([self isHighlighted]) {
      NSColor *highColor = [self highlightColorWithFrame:cellFrame inView:controlView];

      backgroundColor = [backgroundColor blendedColorWithFraction:0.4 ofColor:highColor];
   }
   backgroundColor = [backgroundColor colorUsingColorSpace:[NSColorSpace sRGBColorSpace]];

   [backgroundColor set];
   float bright = [backgroundColor brightnessComponent];
	[NSBezierPath fillRect:cellFrame];
	
   if ([[self series] alreadyDrawn]) {
		if ([[self series] started]) {
         NSColor *txtColor;
         if (bright > 0.5) {
            txtColor = [NSColor blackColor];
         } else {
            txtColor = [NSColor whiteColor];
         }
			[textAttributes setObject:txtColor
				forKey:NSForegroundColorAttributeName];
		} else {
			[textAttributes setObject:[NSColor redColor]
				forKey:NSForegroundColorAttributeName];
		}
   } else {
		 if ([[self series] started]) {
          NSColor *txtColor;
          if (bright > 0.5) {
             txtColor = [NSColor greenColor];
          } else {
             txtColor = [NSColor colorWithRed:0.0 green:0.6 blue:0.0 alpha:1.0];
          }
			 [textAttributes setObject:txtColor
													forKey:NSForegroundColorAttributeName];
		 } else {
          NSColor *txtColor;
          if (bright > 0.5) {
             txtColor = [NSColor darkGrayColor];
          } else {
             txtColor = [NSColor whiteColor];
          }
			 [textAttributes setObject: txtColor
			forKey:NSForegroundColorAttributeName];
		 }
   } // if

   [[[self series] fullName] drawAtPoint:NSMakePoint(NSMinX(cellFrame)+20, NSMinY(cellFrame)+1)
                          withAttributes:textAttributes];
   [[[self series] startTime] drawAtPoint:NSMakePoint(cellFrame.origin.x+cellFrame.size.width-40, cellFrame.origin.y + 1)
                          withAttributes:textAttributes];

   if ([[self series] started])
   {
      NSPoint pos;
      
      if (check == nil)
      {
			NSString *path=[[NSBundle mainBundle] pathForImageResource:@"check"];
			if (path == nil)
			{
				// fprintf(stderr, "Could not find check.tiff\n");
			} else {
	         check = [[NSImage alloc] initByReferencingFile:path];
			}
      } // if
      
      pos.x = NSMinX(cellFrame) + 2.0;
      pos.y = NSMinY(cellFrame) + 1.0;
      [check drawAtPoint:pos fromRect:NSMakeRect(0, 0, 9, 9) operation:NSCompositeSourceOver fraction:1.0];
   } // if
} // drawInside

- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
{
   series = aSeries;
   // as of yet, no other initialization is neccessary
}

- (Series *)series;
{
   return (Series *)series;
} // match

+ (NSMutableDictionary*)textAttributes;
{
	if (_SBCTextAttributes==nil) {
		_SBCTextAttributes = [NSMutableDictionary
				dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:12.0]
								  forKey:NSFontAttributeName];
	}
	return _SBCTextAttributes;
}

@end

