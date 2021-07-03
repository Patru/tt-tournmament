
#import <appkit/appkit.h>
#import "SinglePlayer.h"

@interface UmpireController:NSObject
{
    IBOutlet NSTextField *countField;
    IBOutlet NSBrowser *umpireBrowser;
//@protected
    NSMutableArray *umpires;
    BOOL	  restoreInProgress;	// YES during restore
}

- (void)updateMatrix;
- (IBAction)removeSelectedUmpire:(id)sender;
- (IBAction)selectUmpire:(id)sender;
- (BOOL) isUmpire:(SinglePlayer *)aPlayer;
- addUmpire:(SinglePlayer *)aPlayer;
// adds aPlayer and redisplays, 
- (SinglePlayer *)removeUmpire:(SinglePlayer *)aPlayer;
// remove aPlayer from Browser
- (SinglePlayer *) getUmpire;
// return an umpire if there is one and nil if there is none
- (SinglePlayer *)selectedUmpire;
- (void)selectSpecificUmpire:(SinglePlayer *)umpire;

- (bool)hasBackup;
- setRestoreInProgress:(bool)restoreInProgress;
- (bool)restoreInProgress;
- (void)useBackup:(bool)useIt;

@end
