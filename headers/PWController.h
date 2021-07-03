/*****************************************************************************
     Use: Control a table tennis tournament.
          Checks for a (fixed) password.
Language: Objective-C                 System: NeXTSTEP 3.3
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 10.4.1995, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>

@interface PWController:NSObject
{
   IBOutlet NSWindow *window;		// window which displays the password
}

- (NSInteger)checkPw:sender;
- (IBAction)checkPassword:(NSSecureTextField *)sender;

@end
