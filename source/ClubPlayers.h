//
//  ClubPlayers.h
//  Tournament
//
//  Created by Paul Trunz on 16.12.15.
//  Copyright 2015 Soft-Werker GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ConfirmationPlayer.h"


@interface ClubPlayers : NSObject {
	NSMutableArray *players;
}

- (instancetype)init;
- (void)add:(ConfirmationPlayer *) player;
- (NSString *) club;
- (BOOL) hasPlayer;
/* removes the first player from the list and returns its SeriesPlayer */
- (ConfirmationPlayer *) gimmeOne;
- (NSComparisonResult) compareNumberOfPlayers:(ClubPlayers *)otherClub;
- (NSArray *)players;

+ (ClubPlayers *) clubPlayers;
@end
