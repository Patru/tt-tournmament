
#import "MatchViewController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

#import "SinglePlayer.h"

@implementation MatchViewController

NSPrintInfo* landscapeA6() {
	return [TournamentDelegate.shared.preferences smallPaperLandscape];

}

NSPrintInfo* portraitA6() {
	return [TournamentDelegate.shared.preferences smallPaperPortrait];
}

- (void)print:(id)sender
{
   NSPrintOperation *printOperation=nil;

   printOperation=[NSPrintOperation printOperationWithView:matchView printInfo:landscapeA6()];
   [printOperation setShowsPrintPanel:![TournamentDelegate.shared.preferences printImmediately]];
   [printOperation runOperation];
}

- setPlayable:(id <Playable>)aMatch;
{
   [matchView setPlayable:aMatch];
   [window orderFront:self];
   [self print:self];
   [window orderBack:self];
   return self;
}

- (void)printPortrait:(id)sender
{
   NSPrintOperation *printOperation=nil;

   printOperation=[NSPrintOperation printOperationWithView:portraitView printInfo:portraitA6()];
   [printOperation setShowsPrintPanel:![TournamentDelegate.shared.preferences printImmediately]];
   [printOperation runOperation];
}

- setPortraitMatch:(id <Playable>)aMatch;
{
   [portraitView setPlayable:aMatch];
   [portraitWindow orderFront:self];
   [self printPortrait:self];
   [portraitWindow orderBack:self];

   return self;
}

- (BOOL)shouldRunPrintPanel:aView;
// returns NO so printing is not delayed
{
   return ![TournamentDelegate.shared.preferences printImmediately];
} // shouldRunPrintPanel

@end
/* 8.263889	4.131944
11.694445	5.847222
8.263889	297.499968

11.694445	420.999984
*/
