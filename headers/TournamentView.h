/*****************************************************************************
     Use: Control a table tennis tournament.
          This view displays the tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 21.11.93, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/
 
#import <appkit/appkit.h>
#import "drawableSeries.h"

@interface TournamentView:NSView
{
    id	delegate;
    id <NSObject, drawableSeries> series;
    char    format;
    float   pageWidth;
    float   pageHeight;
    long maxMatchOnPage;
    long maxGroupsOnPage;
}

+ (NSDictionary*)smallAttributes;
+ (NSDictionary*)titleAttributes;
+ (NSDictionary*)largeAttributes;

- drawTournament:sender;
- setOrientation:(const char)form;
- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
- pageHeaderYouth:(float *)top page:(int *)num;
- (NSInteger) maxMatchOnPage;
- (NSInteger) maxGroupsOnPage;
- (double) pageWidth;
- (double) pageHeight;
- (void)determineDimensions;

@end
