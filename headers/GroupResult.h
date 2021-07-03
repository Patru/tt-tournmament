
#import <Cocoa/Cocoa.h>
#import "Group.h"

@interface GroupResult:NSObject
{
	Group *thisGroup;			// working group
	NSMutableArray *matchList;	// groups matches, only present
	NSMutableArray<id<Player>> *plList;
	NSMutableDictionary *playersInGroup;
	id	positions;
	id	matches;
	id	players;
	NSPanel *oneMatch;
	id	playerPos;
	id  resultList;
	id  resultText;
	id  matchMatrix;
	id  eightTable;
	id  setResult;
	id  upperTitle;
	id  lowerTitle;
	id  upperName;
	id  lowerName;
}

+ (NSMutableParagraphStyle *)paragraphStyle;
+ (NSDictionary *)tabbedAttributes;

- (bool)setGroupForEvaluation:(Group *)aGroup;
- (bool)currentlyEvaluates:(Group *)aGroup;
- posAbort:sender;
- matchAbort:sender;
- rankAbort:sender;
- oneMatchAbort:sender;
- results:(Group *)sender;
- oneMatchOk:sender;
- play:sender;
- rankDecided:sender;
- rank:sender;
- saveMatches:sender;
- selectWinner:sender;
- (bool) singleMatchExact:(Match *)aMatch winner:(id <Player>)aPlayer for:(NSWindow *)window;
- (BOOL)textShouldEndEditing:(NSText *)textObject;
- (NSWindow *) oneMatch;

@end
