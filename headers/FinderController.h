/*****************************************************************************
     Use: Control a table tennis tournament.
          Object to find players and matches in the Inspector.
Language: Objective-C                 System: NeXTSTEP 3.2
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 18.4.94, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>

@interface FinderController:NSObject
{
	IBOutlet NSWindow *window;
	IBOutlet NSTextField *playerField;
}

- (IBAction)findPlayer:sender;
- (IBAction)findMatch:sender;
- (IBAction)showFinder:sender;

@end
