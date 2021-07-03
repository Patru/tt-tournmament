//
//  TournamentTableCell.h
//  Tournament
//
//  Created by Paul Trunz on Wed May 14 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TournamentTable.h"


@interface TournamentTableCell : NSBrowserCell {
   TournamentTable *table;
}

- init;
- initTextCell:(const char *)aString;
- initWithTable:(TournamentTable *)aTable;

- (void)drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView;
- (TournamentTable *)tournamentTable;
- setTournamentTable:(TournamentTable *)aTable;

@end
