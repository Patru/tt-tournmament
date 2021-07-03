
#import <Cocoa/Cocoa.h>
#import "Match.h"

@interface PlayingMatchesController:NSObject
{
    IBOutlet NSTextField *numberField;
    IBOutlet NSTextField *countField;
    IBOutlet NSBrowser *playingMatchesBrowser;
@private
    NSMutableArray *matches;
}

- (void)updateMatrix;
- (IBAction)selectMatchWithNumber:(id)sender;
- (IBAction)selectMatchDirectly:(id)sender;
- numberField;
- (IBAction)withdrawPlayable:(id)sender;
- (Match *)matchPlayedBy:(SinglePlayer *)aPlayer;
+ (void)fixCurrentTimeFor:(id <Playable>)aPlayable;
- (void)addPlayable:(id <Playable>)aPlayable;
// adds aMatch, registers its time and redisplays, 
- (void)removePlayable:(id <Playable>)aPlayable;
// remove aMatch from Browser
- unselect;
// unselect player in Browser
- (BOOL) containsPlayable:aPlayable;
- selectNumber:(long)number;
- (bool)hasBackup;
- (void)useBackup:(bool)useIt;
- (void)dbDeletePlayable:(id <Playable>)aPlayable;
- (void)dbInsertPlayable:(id <Playable>)aPlayable;

@end
