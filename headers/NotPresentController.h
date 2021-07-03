
#import <Cocoa/Cocoa.h>
#import "SinglePlayer.h"

@interface NotPresentController:NSObject
{
   id  window;
	id  notPresentBrowser;
	id  woBrowser;
@protected
   NSMutableDictionary *notPresentDict;
   NSMutableArray *notPresentList;
   NSMutableDictionary *woDict;
   NSMutableArray *woList;
}

- (void)display;
- (IBAction)removeNotPresent:(id)sender;
- (IBAction)removeWO:(id)sender;
- (void)removeNotPresentPlayer:(SinglePlayer *)aPlayer;
- (void)removeWOPlayer:(SinglePlayer *)aPlayer;
- (IBAction)makeWONotPresent:sender;
- (BOOL) isNotPresent:(SinglePlayer *)aPlayer;
- (BOOL) isWO:(SinglePlayer *)aPlayer;
- (void)addNotPresent:(SinglePlayer *)aPlayer;
- (void)addWO:(SinglePlayer *)aPlayer;
- (IBAction)selectPlayer:(id)sender;
- (NSInteger)browser:(NSBrowser *)sender numberOfRowsInColumn:(NSInteger)column;
- (BOOL)browser:(NSBrowser *)sender selectRow:(NSInteger)row inColumn:(NSInteger)column;
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(NSInteger)row column:(NSInteger)column;

- (bool)hasBackup;
- (void)useBackup:(bool)useIt;
- (void)setBrowserTitles;
@end
