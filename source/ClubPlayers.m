//
//  ClubPlayers.m
//  Tournament
//
//  Created by Paul Trunz on 16.12.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "ClubPlayers.h"


@implementation ClubPlayers
- (instancetype)init;
{
	players=[[NSMutableArray alloc] init];
	
	return self;
}

- (void)add:(ConfirmationPlayer *) player;
{
	[players addObject:player];
}

- (NSString *) club;
{
	if ([self hasPlayer]) {
		return [[[[players objectAtIndex:0] seriesPlayer] player] club];
	} else {
		return @"";
	}
}

- (BOOL) hasPlayer;
{
	return [players count] > 0;
}

- (ConfirmationPlayer *) gimmeOne;
{
	if ([self hasPlayer]) {
		ConfirmationPlayer *first = [players objectAtIndex:0];
		[players removeObjectAtIndex:0];
		
		return first;
	} else {
		return nil;
	}
}

- (NSArray *)players;
{
	return players;
}

// in descending order, largest clubs to be picked first
- (NSComparisonResult) compareNumberOfPlayers:(ClubPlayers *)otherClub;
{
	if ([players count] < [[otherClub players] count]) {
		return NSOrderedDescending;
	} else if ([players count] > [[otherClub players] count]) {
		return NSOrderedAscending;
	} else {
		return NSOrderedSame;
	}
}

+ (ClubPlayers *) clubPlayers;
{
	return [[ClubPlayers alloc] init];
}
@end
