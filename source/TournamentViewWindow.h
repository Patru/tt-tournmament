//
//  TournamentViewWindow.h
//  Tournament
//
//  Created by Paul Trunz on Mon Jan 07 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TournamentViewWindow : NSWindow {
	id controller;
}

- (IBAction)print:(id)sender;

@end
