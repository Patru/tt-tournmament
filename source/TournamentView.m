/*****************************************************************************
     Use: Control a table tennis tournament.
          This view displays the series.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 21.11.93, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/
 
#import "TournamentView.h"
#import "TournamentController.h"
#import "Match.h"
#import "Group.h"
#import "drawableSeries.h"
#import "Tournament-Swift.h"

NSDictionary *_TVSmallAttributes=nil;
NSDictionary *_TVTitleAttributes=nil;
NSDictionary *_TVLargeAttributes=nil;

@implementation TournamentView

- (instancetype)initWithFrame:(const NSRect)frameRect
{
   self=[super initWithFrame:frameRect];
   series  = (id <NSObject, drawableSeries>) nil;
   [self setOrientation:NSPortraitOrientation];
   
   return self;
} // initFrame

- setOrientation:(const char)form;
{
   format = form;
   
   if(format == NSLandscapeOrientation)
   {
      pageWidth = maxPageHeight;
      pageHeight = maxPageWidth;
      maxMatchOnPage = 36;
      maxGroupsOnPage = 14;
   }
   else
   {
      pageWidth = maxPageWidth;
      pageHeight = maxPageHeight;
      maxMatchOnPage = 58;
      maxGroupsOnPage = 22;
   } // if
   //[self sizeTo :pageWidth:pageHeight];
   return self;
} // setOrientation

- (void)determineDimensions;
{
	PreferencesViewController *preferences = TournamentDelegate.shared.preferences;

	pageWidth = preferences.pageWidth;
	pageHeight = preferences.pageHeight;
	maxMatchOnPage = preferences.maxMatchOnPage;
	maxGroupsOnPage = preferences.maxGroupsOnPage;
	[Match fixDimensions];
}

- drawTournament:sender;
{
   [self display];
   return self;
} // drawTournament

- pageHeaderYouth:(float *)top page:(int *)num;
// draws the page-header for the youth Tournament
{  // char buf[100];

   *num = *num + 1;
   
   return self;
} // pageHeaderYouth

- (void)print:(id)sender
{
   NSPrintInfo *printInfo=[[NSPrintInfo sharedPrintInfo] copy];
   NSPrintOperation *printOperation=nil;
	
   [printInfo setPaperName:@"A4"];
   [printInfo setOrientation:format];
   [printInfo setLeftMargin:24.0];
   [printInfo setRightMargin:24.0];
   [printInfo setTopMargin:24.0];
   [printInfo setBottomMargin:24.0];
   printOperation=[NSPrintOperation printOperationWithView:self printInfo:printInfo];
   [printOperation setShowsPrintPanel:YES];
   [printOperation runOperation];
}

- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
// set the series which shall be drawn
{
	[self setOrientation:(char)[TournamentDelegate.shared.preferences landscape]];
	[self determineDimensions];
	
	if ([aSeries conformsToProtocol:@protocol(drawableSeries)]) {
		series = aSeries;
		[series paginate:self];
		[self setNeedsDisplay:YES];
	} else {
		fprintf(stderr, "Please do not ignore your compile-time warnings, "
						"this series is not drawable\n");
	} // if
} // setSeries

- (void)drawRect:(NSRect)rect;
{
   float  allPagesSize = [series totalPages] * [self pageHeight];
   NSRect firstPage = NSMakeRect(0.0, allPagesSize - [self pageHeight], [self pageWidth],
				[self pageHeight]);

   [self setFrameSize:NSMakeSize([self pageWidth], allPagesSize)];
   [series drawPages:rect page:&firstPage maxMatchesOnPage:maxMatchOnPage];
} // drawSelf

- (BOOL)knowsPageRange:(NSRangePointer)range;
{
   range->location=1;
   range->length=[series totalPages];

   return YES;
}

- (NSInteger) maxMatchOnPage;
// maximal matches on a page for a regular table
{
   return maxMatchOnPage;
} // maxMatchOnPage

- (NSInteger) maxGroupsOnPage;
// maximal (normal) groups on a page for a regular table
{
   return maxGroupsOnPage;
} // maxGroupsOnPage

- (double) pageWidth;
{
   return pageWidth;
} // pageWidth

- (double) pageHeight;
{
   return pageHeight;
} // pageHeight

- (NSRect)rectForPage:(long)pageNumber
{
   long max=[series totalPages];
   return NSMakeRect(1, (max-pageNumber)*[self pageHeight], [self pageWidth], [self pageHeight]);
}

+ (NSDictionary*)smallAttributes;
{
   if (_TVSmallAttributes==nil) {
      _TVSmallAttributes = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times-Roman" size:10.0]
                                                       forKey:NSFontAttributeName];
   }
   return _TVSmallAttributes;
}

+ (NSDictionary*)titleAttributes;
{
   if (_TVTitleAttributes==nil) {
      _TVTitleAttributes = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica-Bold" size:24.0]
                                                       forKey:NSFontAttributeName];
   }
   return _TVTitleAttributes;
}

+ (NSDictionary*)largeAttributes;
{
   if (_TVLargeAttributes==nil) {
      _TVLargeAttributes = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Times-Roman" size:16.0]
                                                       forKey:NSFontAttributeName];
   }
   return _TVLargeAttributes;
}

@end
