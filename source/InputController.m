/*****************************************************************************
     Use: Control a table tennis tournament.
          Input of player- and series-data.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 9.1.94, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import "InputController.h"
#import "SeriesDataController.h"
#import "PlayerController.h"

@implementation InputController:NSObject

-init
{
	self=[super init];
   playerController = nil;
   seriesController = nil;
   return self;
} // init

- (IBAction)showPlayerWindow:sender
// display the window with players
{      
   [[self playerController] showWindow:self];
} // showPlayerWindow

- (IBAction)showSeriesWindow:sender
// display the window with series
{
   [[self seriesController] showWindow:self];
} // showPlayerWindow

- (PlayerController *)playerController;
{
	if (playerController == nil) {
		[[NSBundle mainBundle] loadNibNamed:@"DBInput" owner:self topLevelObjects:nil];
	} // if
   [playerController fixNumberFormats];
	return playerController;
}

- (SeriesDataController *)seriesController;
{
   if(seriesController == nil)
   {
      [[NSBundle mainBundle] loadNibNamed:@"DBInput" owner:self topLevelObjects:nil];
   } // if
	return seriesController;
}
@end
