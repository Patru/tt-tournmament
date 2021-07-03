/*****************************************************************************
     Use: Control a table tennis tournament.
          Checks for a (fixed) password.
Language: Objective-C                 System: NeXTSTEP 3.3
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 10.4.1995, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import "PWController.h"
#import "TournamentController.h"

NSString *_password = @"Akribisch";

@implementation PWController
/* Controls a window to enter a password as protection for critical actions 
   (as a modal window it can show even atop a sheet (which is likely to occur)) 
 */

- (NSInteger)checkPw:sender;
// show a pannel to ask for the password
{
   NSInteger ret;
   
   if (window == nil)
   {
      [[NSBundle mainBundle] loadNibNamed:@"Password" owner:self topLevelObjects:nil];
   } // if
   ret = [NSApp runModalForWindow:window];
   [window orderOut:self];
   return ret;
} // checkPw

- (IBAction)checkPassword:(NSSecureTextField *)sender;
// check if the password is correct and remove the panel
{
   if ([[sender stringValue] isEqualToString:_password])
   {
      [NSApp stopModalWithCode:1];
   }
   else
   {
      NSAlert *alert = [[NSAlert alloc] init];
      alert.informativeText = NSLocalizedStringFromTable(@"In diesem Fall kann ich das leider nicht tun.", @"Tournament", null);
      [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Ok", @"Tournament", null)];
      alert.alertStyle = NSAlertStyleCritical;
      [alert synchronousModalSheetForWindow:window];
      [NSApp stopModalWithCode:0];
   }
}


@end
