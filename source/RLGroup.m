//
//  RLGroup.m
//  Tournament
//
//  Created by Paul Trunz on 28.10.07.
//  Copyright 2007- Soft-Werker GmbH. All rights reserved.
//

#import "RLGroup.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation RLGroup

- (void)replacePlayedMatches;
{
	long i, max = [matches count];
	
	for (i=0; i<max; i++) {
		Match *match = (Match *)[matches objectAtIndex:i];
		Match *alreadyPlayedMatch = [TournamentDelegate.shared findMatchWithSamePlayersAs:match];
		
		if (alreadyPlayedMatch != nil) {
			[match takeResultFrom:alreadyPlayedMatch];
		}
	}
}

- makeMatches;
{
	[super makeMatches];
	[self replacePlayedMatches];
   return self;
}

@end
