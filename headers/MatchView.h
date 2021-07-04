
#import <appkit/appkit.h>
#import "Match.h"

@interface MatchView:NSView
{
    id <Playable> thisMatch;
}

- setPlayable:(id <Playable> )aMatch;
- (void)print:sender;
- (NSDictionary*)largeAttributes;
- (NSDictionary*)largeBoldAttributes;
- (NSDictionary*)textAttributes;

@end
