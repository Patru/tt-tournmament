//
//  TournamentViewController.m
//  Tournament
//
//  Created by Paul Trunz on Sun Jan 06 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "TournamentViewController.h"
#import "TournamentController.h"
#import "TournamentView.h"
#import "Tournament-Swift.h"

@implementation TournamentViewController

- (instancetype)init;
{
   self=[super init];
	tournamentViewWindow=nil;
	scrollView=nil;
	_tournamentView=[[TournamentView alloc] init];
	return self;
}

- (void)setSeries:(id <NSObject, drawableSeries>)series;
{
	[_tournamentView setSeries:series];
	[_tournamentView setNeedsDisplay:YES];
	[self show:self];
}

- (void)show:sender;
{
	if (tournamentViewWindow == nil) {
      NSArray *objs;
      [[NSBundle mainBundle] loadNibNamed:@"TournamentView" owner:self topLevelObjects:&objs];
		[scrollView setHasVerticalScroller:YES];
		[scrollView setDocumentView:_tournamentView];
	}
	[tournamentViewWindow makeKeyAndOrderFront:sender];
}

- (IBAction)print:(id)sender;
{
	[_tournamentView print:sender];
}

- (void)saveSeries:(id <NSObject, drawableSeries>)series asPDFToDirectory:(NSURL *)directory;
{
   NSPrintInfo *printInfo=[[NSPrintInfo sharedPrintInfo] copy];
	[printInfo setJobDisposition:NSPrintSaveJob];
   //[NSString stringWithFormat:@"%@/%@.pdf", directory, [series fullNameNoSpace]]
   [[printInfo dictionary] setObject:[directory URLByAppendingPathComponent: [NSString stringWithFormat:@"%@.pdf",
                                                                              [series fullNameNoSpace]]]
										forKey:NSPrintJobSavingURL];
	[[printInfo dictionary] setObject:@1 forKey:NSPrintFirstPage];
	[[printInfo dictionary] setObject:[NSNumber numberWithLong:[series totalPages]] forKey:NSPrintLastPage];
	if ([TournamentDelegate.shared.preferences landscape]) {
		[printInfo setOrientation:NSPaperOrientationLandscape];
	} else {
		[printInfo setOrientation:NSPaperOrientationPortrait];
	}
	
	[self setSeries:series];
   NSPrintOperation *printOperation=[NSPrintOperation printOperationWithView:_tournamentView printInfo:printInfo];
   [printOperation setShowsPrintPanel:NO];
   [printOperation runOperation];
}

- (void)printSensiblePagesOf:(Series *)series;
{
   NSPrintInfo *printInfo=[[NSPrintInfo sharedPrintInfo] copy];
	[printInfo setJobDisposition:NSPrintPreviewJob]; // NSPrintSpoolJob
	[[printInfo dictionary] setObject:[NSNumber numberWithInt:1] forKey:NSPrintFirstPage];
	[series paginate:_tournamentView];
	long maxPrintablePage = [series lastInterestingPage];
	[[printInfo dictionary] setObject:[NSNumber numberWithLong:maxPrintablePage] forKey:NSPrintLastPage];
	if ([TournamentDelegate.shared.preferences landscape]) {
		[printInfo setOrientation:NSPaperOrientationLandscape];
	} else {
		[printInfo setOrientation:NSPaperOrientationPortrait];
	}
	
	[self setSeries:series];
   NSPrintOperation *printOperation=[NSPrintOperation printOperationWithView:_tournamentView printInfo:printInfo];
   [printOperation setShowsPrintPanel:NO];
   [printOperation runOperation];
}

- (BOOL)acceptsFirstResponder;
{
	return YES;
}

@end
