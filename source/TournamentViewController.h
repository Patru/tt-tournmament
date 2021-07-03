//
//  TournamentViewController.h
//  Tournament
//
//  Created by Paul Trunz on Sun Jan 06 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Series.h"
#import "TournamentView.h"

@interface TournamentViewController : NSObject
{
	IBOutlet NSWindow *tournamentViewWindow;
	IBOutlet NSScrollView *scrollView;
	TournamentView *_tournamentView;
}

- init;
- (void)setSeries:(id <NSObject, drawableSeries>)series;
- (void)show:sender;
- (IBAction)print:(id)sender;
- (BOOL)acceptsFirstResponder;
- (void)saveSeries:(id <NSObject, drawableSeries>)series asPDFToDirectory:(NSURL *)directory;
- (void)printSensiblePagesOf:(Series *)series;
@end
