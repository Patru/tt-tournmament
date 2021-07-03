/*****************************************************************************
     Use: Control a table tennis tournament.
          Inspector controller for DoublePlayers.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 10.8.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "InspectorController.h"
#import "DoublePlayer.h"

@interface DoublePlayerInspector:InspectorController <InspectorControllerProtocol>
{
    IBOutlet NSForm *infoFormA;
    IBOutlet NSForm *infoFormB;
    IBOutlet NSView *playerView;	 
@private
	DoublePlayer *_double;
}

- (void)fillPlayerView;
- (IBAction)inspect:sender;
- (void)setDouble:(DoublePlayer *)aDouble;
- (void)updateFromPlayerView;

@end
