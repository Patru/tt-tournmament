/*****************************************************************************
     Use: Control a table tennis tournament.
          Display a match in a BrowserCell, but with printing time
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 9.5.1994, Patru: first started
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "Series.h"
#import "drawableSeries.h"

@interface SeriesBrowserCell:NSBrowserCell
{
   id <NSObject, drawableSeries> series;
}

- (instancetype)initTextCell:(NSString *)aString;
- (instancetype)initSeries:(Series *)aSeries;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (Series *)series;
- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
+ (NSMutableDictionary*)textAttributes;

@end

