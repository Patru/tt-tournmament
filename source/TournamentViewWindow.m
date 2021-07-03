//
//  TournamentViewWindow.m
//  Tournament
//
//  Created by Paul Trunz on Mon Jan 07 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "TournamentViewWindow.h"


@implementation TournamentViewWindow

- (IBAction)print:(id)sender;
{
	if ([controller respondsToSelector:@selector(print:)]) {
		[controller print:sender];
	}
}

@end
