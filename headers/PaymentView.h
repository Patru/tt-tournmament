//
//  PaymentView.h
//  Tournament
//
//  Created by Paul Trunz on Wed Feb 06 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class TournamentPlayer;

@interface PaymentView : NSView {
   NSMutableArray<TournamentPlayer *> *playersInTournament2;
   TournamentPlayer *sumOfAllPlayers2;
}

- (long) maxPlayersOnPage;
- (void) fetchAllPlayersAndSeries;
- (long) totalPages;
- (BOOL)knowsPageRange:(NSRangePointer)range;

@end
