//
//  TrounamentWindow.m
//  Tournament
//
//  Created by Paul Trunz on Mon Mar 31 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "TournamentWindow.h"
#import "TournamentController.h"
#import "PlayingMatchesController.h"
#import "Tournament-Swift.h"

@implementation TournamentWindow

- (void)becomeKeyWindow;
{
   [self enableCursorRects];
   [self makeFirstResponder:[[TournamentDelegate.shared.matchController playingMatchesController] numberField]];
}

@end
