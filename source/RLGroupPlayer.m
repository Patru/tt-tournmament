//
//  RLGroupPlayer.m
//  Tournament
//
//  Created by Paul Trunz on 28.10.07.
//  Copyright 2007- Soft-Werker GmbH. All rights reserved.
//

#import "RLGroupPlayer.h"


@implementation RLGroupPlayer

- (NSString *)club;
{
	return @"";
}

- (long)ranking;
{
	return 0l;
}

- (NSString *)longName;
{
	return [NSString stringWithFormat:@"Gruppe %ld Platz %ld", [group number], position + 1];
}

@end
