
#import "GroupMatch.h"
#import "MatchView.h"
#import "Series.h"
#import "TournamentController.h"

@implementation MatchView

- setPlayable:(id <Playable>)aMatch;
{
   thisMatch = aMatch;
   [self display];
   return self;
} // setPlayable

- (void)print:sender;
{
	[super print:sender]; //??!
} // print

- (void)drawRect:(NSRect)rect;
// call the method of the current match
{
	const NSRect *rects;
	long count;
	
	[self getRectsBeingDrawn:&rects count:&count];
   [thisMatch matchSheet:self :rect];
} // drawRect

- (NSDictionary*)largeBoldAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Helvetica-Bold" size:20.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)largeAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Times-Roman" size:16.0] forKey:NSFontAttributeName];
}

- (NSDictionary*)textAttributes {
    return [NSDictionary dictionaryWithObject:
		[NSFont fontWithName:@"Times-Roman" size:12.0] forKey:NSFontAttributeName];
}

/*
- (BOOL)knowsPageRange:(NSRangePointer)range;
{
   range->location=1;
   range->length=1;

   return YES;
}

- (NSRect)rectForPage:(int)pageNumber
{
   NSRect rect = NSMakeRect(0, 0, 440, 304);
   return rect;
}
*/

@end
