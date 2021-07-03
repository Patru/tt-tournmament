/*****************************************************************************
     Use: Control a table tennis tournament.
          Inspector controller for single Match.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 7.8.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Match.h"
#import "InspectorController.h"

@interface MatchInspector:InspectorController <InspectorControllerProtocol>
{
   IBOutlet NSForm *infoForm;
   IBOutlet NSTextField *lowerRanking;
   IBOutlet NSTextField *lowerPriority;
   IBOutlet NSForm *lowerInfoForm;
	IBOutlet NSView *matchView;
	IBOutlet NSView *playerView;
	IBOutlet NSTextField *series;
   IBOutlet NSForm *upperInfoForm;
   IBOutlet NSTextField *upperRanking;
   IBOutlet NSTextField *upperPriority;
	IBOutlet NSTextField *winnerLicence;
   IBOutlet NSTextField *winnerName;
   IBOutlet NSForm *setsForm;
   IBOutlet NSButton *woButton;
   IBOutlet NSButton *bestOfSeven;
@private
	Match *_match;
}

- (void)changeWinnerBackToNil;
- (void)fillMatchView;
- (void)fillPlayerView;
- (IBAction)inspectPlayer:sender;
- (IBAction)insertMatch:sender;
- (void)setMatch:(Match *)aMatch;
- (void)updateFromView;
- (void)updateFromMatchView;
- (void)updateFromPlayerView;
- (void)updateWinnerFromInspector;

@end
