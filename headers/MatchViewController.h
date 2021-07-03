
#import <Cocoa/Cocoa.h>
#import "Match.h"

@interface MatchViewController:NSObject
{
    id	matchView;
    id	window;
    id	portraitView;
    id	portraitWindow;
}

- (void)print:(id)sender;
- setPlayable:(id <Playable>)aMatch;
- (void)printPortrait:(id)sender;
- setPortraitMatch:(id <Playable>)aMatch;

@end
