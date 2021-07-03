/*****************************************************************************
     Use: Control a table tennis tournament.
          Inspector controller for DoublePlayers.
Language: Objective-C                 System: MacOS X
  Author: Paul Trunz, Copyright 2017
 Version: 0.1, first try
 History: 14.3.2017, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "InspectorController.h"
#import "Series.h"

@interface SeriesInspector:InspectorController <InspectorControllerProtocol>
{
	IBOutlet NSForm *details;
	IBOutlet NSForm *statistik;
	IBOutlet NSView *playerView;	 
	IBOutlet NSView *matchView;	 
@private
	Series *_series;
}

- (NSView *)filledViewForOption:(long) option;
- (void)fillMatchView;
- (void)fillPlayerView;
- (void)setSeries:(Series *)aSeries;
- (IBAction)playSingleMatchesForAllOpenGroups:sender;

@end
