
#import <Cocoa/Cocoa.h>
#import "Match.h"

@interface MatchResultController:NSObject
{
   IBOutlet NSTextField	*numberField;
   id upperButton;
   id	lowerButton;
   id	seriesField;
   id  window;
   id  wo;
@private
   id  match;
}

- (IBAction)cancel:(id)sender;
- (IBAction) ok:(id)sender;
- (IBAction)show:(id)sender;
// the sender of this message is the match to be shown !!

@end
