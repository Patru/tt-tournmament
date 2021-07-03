//
//  TournamentTableCell.m
//  Tournament
//
//  Created by Paul Trunz on Wed May 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "TournamentTableCell.h"

#import "MatchBrowser.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"


@implementation TournamentTableCell

- (instancetype)init;
{
   return [self initWithTable:nil];
} // init

- (instancetype)initTextCell:(const char *)aString;
   /* this seems to be the standard initializer of NSBrowserCell,
   just init with nil and discard the stringvalue which is passed to it. */
{
   return [self initWithTable:nil];
}

- (instancetype)initWithTable:(TournamentTable *)aTable;
{
   self=[super initTextCell:@"Tisch"];
   table = aTable;
   [self setLeaf:YES];
   
   return self;
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
{
   const float texty = NSMinY(cellFrame) + 1;
   const float number  = NSMinX(cellFrame) + 50;
   const float prio  = NSMaxX(cellFrame) - 30;
   long desiredPriority = [[TournamentDelegate.shared.matchController matchBrowser] selectedDesiredPriority];
   NSSize size;
   NSColor *backgroundColor;
   NSColor *foregroundColor = [NSColor blackColor];
   NSMutableDictionary * textAttributes =
   [NSMutableDictionary dictionaryWithObject:[NSFont systemFontOfSize:12.0]
                                      forKey:NSFontAttributeName];
   
   if ([self isHighlighted]) {
      backgroundColor = [[self highlightColorWithFrame:cellFrame inView:controlView] highlightWithLevel:0.4];
      if ( (desiredPriority > 0)
          && ( (desiredPriority < [table priority]) || (desiredPriority-[table priority] > 1) ) ) {
         backgroundColor = [backgroundColor blendedColorWithFraction:0.4 ofColor:[NSColor yellowColor]];
      }
   } else {
      backgroundColor = [NSColor whiteColor];
   }
   [backgroundColor setFill];
   [textAttributes setObject:foregroundColor forKey:NSForegroundColorAttributeName];
   [NSBezierPath fillRect:cellFrame];
   size = [[[table NSNumber] stringValue] sizeWithAttributes:textAttributes];
   
   [[[table NSNumber] stringValue] drawAtPoint:NSMakePoint(number-size.width, texty)
                                withAttributes:textAttributes];
   NSColor *priorityColor = nil;
   if ( (desiredPriority == 0) || ([table priority] < desiredPriority) ) {
      priorityColor = [NSColor blueColor];
   } else if ([table priority] > desiredPriority) {
      priorityColor = [NSColor redColor];
   } else {
      priorityColor = [NSColor greenColor];
   }
   priorityColor = [backgroundColor blendedColorWithFraction:0.7 ofColor:foregroundColor];
   [textAttributes setObject:priorityColor forKey:NSForegroundColorAttributeName];
   [[NSString stringWithFormat:@"%ld", [table priority]]
    drawAtPoint:NSMakePoint(prio, texty) withAttributes:textAttributes];
}

- setTournamentTable:(TournamentTable *)aTable;
{
   table = aTable;
   
   return self;
}

- (TournamentTable *)tournamentTable;
{
   return table;
}

@end
