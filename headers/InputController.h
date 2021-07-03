/*****************************************************************************
     Use: Control a table tennis tournament.
          Input of player- and series-data.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 9.1.94, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "PlayerController.h"
#import "SeriesDataController.h"

@interface InputController:NSObject
{
   PlayerController *playerController;
   SeriesDataController *seriesController;
}

-init;
- (IBAction)showPlayerWindow:sender;
- (IBAction)showSeriesWindow:sender;
- (PlayerController *)playerController;
- (SeriesDataController *)seriesController;

@end
