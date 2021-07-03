/*****************************************************************************
     Use: Control a table tennis tournament.
          Storage and display of a single goup match.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 19.6.1994, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/
 
#import "Group.h"
#import "GroupMatch.h"
#import "GroupResult.h"
#import "PlayingMatchesController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"
#import "MatchConstants.h"

@implementation GroupMatch

// init a match from the players given in the series sender
- (instancetype)initFrom:(char)c1 andPlayer:(char)c2 of:(Group *)grp;
{
   id ser = [grp series];
   NSArray * players = [grp players];
   id pl1 = [players objectAtIndex:(long)c1-'a'];
   id pl2 = [players objectAtIndex:(long)c2-'a'];

   self=[super init];
   upper = [[Match alloc] init];
   [upper setSeries:ser];
   [upper setWinner:pl1];
   lower = [[Match alloc] init];
   [lower setSeries:ser];
   [lower setWinner:pl2];
   series = ser;
   group = grp;
   matchupString = [NSString stringWithFormat:@"%c:%c", c1, c2];
   return self;
} // initForPlayers

- (NSString *)matchupString;
{
   return matchupString;
} // matchupString

- (NSString *)stringWinner;
// returns a (group unique) string of length 1 with the index of the winner
{
   if (winner == [self upperPlayer]) {
      return [NSString stringWithFormat:@"%c", [[self matchupString] characterAtIndex:0]];
   }
   else if (winner == [self lowerPlayer]) {
      return [NSString stringWithFormat:@"%c", [[self matchupString] characterAtIndex:2]];
   }
   
   return @"";
} // stringWinner

- group;
{
   return group;
} // group

- (NSString *)time;
{
	NSString *tim = [super time];
	if ((tim != nil) && ([tim length] > 0)) {
		return tim;
	} else {
		return [group time];
	}
}

- (void)drawForMatchSheetAt:(float)top;
{  float winLeft = MATCH_RIGHT - MATCH_WIN_WIDTH*[[group players] count];
   float setsLeft = winLeft - 5*MATCH_SET_WIDTH;
   float firstPlayerX  = MATCH_LEFT + MATCH_MATCHUP_WIDTH + MATCH_XS;
   float secondPlayerX = firstPlayerX + (setsLeft - firstPlayerX - MATCH_XS)/2.0;
   float y = top - MATCH_HEIGHT + MATCH_YS;
   NSBezierPath *aPath=[NSBezierPath bezierPath];
   char firstPlayer  = [matchupString characterAtIndex:0],
        secondPlayer = [matchupString characterAtIndex:2];

   NSDictionary *attributes=[GroupMatch smallAttributes];
   [matchupString drawAtPoint:NSMakePoint(MATCH_LEFT + MATCH_XS, y) withAttributes:attributes];
   [[[self upperPlayer] shortName] drawAtPoint:NSMakePoint(firstPlayerX, y)  withAttributes:attributes];
   [[[self lowerPlayer] shortName] drawAtPoint:NSMakePoint(secondPlayerX, y) withAttributes:attributes];

   [[NSColor lightGrayColor] set];
   if (firstPlayer != 'a') {
      [NSBezierPath fillRect:NSMakeRect(winLeft, top - MATCH_HEIGHT,
					(firstPlayer - 'a')*MATCH_WIN_WIDTH, MATCH_HEIGHT)];
   } // if

   if (secondPlayer - firstPlayer != 1) {
      [NSBezierPath fillRect:NSMakeRect(winLeft + (firstPlayer - 'a' + 1)*MATCH_WIN_WIDTH,
					top - MATCH_HEIGHT,
					(secondPlayer - firstPlayer - 1)*MATCH_WIN_WIDTH, MATCH_HEIGHT)];
   } // if

   if ((int)secondPlayer != 'a' + [[group players] count] - 1) {
      [NSBezierPath fillRect:NSMakeRect(winLeft + (secondPlayer - 'a' + 1)*MATCH_WIN_WIDTH,
					top - MATCH_HEIGHT,
					('a' + [[group players] count] - 1 - secondPlayer)*MATCH_WIN_WIDTH,
					MATCH_HEIGHT)];
   } // if

   [[NSColor blackColor] set];
   [aPath moveToPoint:NSMakePoint(MATCH_LEFT, top)];
   [aPath lineToPoint:NSMakePoint(MATCH_RIGHT, top)];
   [aPath stroke];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
   [super encodeWithCoder:encoder];
   [encoder encodeObject:group];
   [encoder encodeObject:matchupString];
}

- (id)initWithCoder:(NSCoder *)decoder
{
   self = [super initWithCoder:decoder];
   group=[decoder decodeObject];
   matchupString=[decoder decodeObject];

   return self;
}

- (void)drawResultInto:(NSRect) area;
// draw a result into a group list
{
	long setCount = [self numberOfSets];
   float setsLeft=NSMaxX(area)-setCount*24;
   float top=NSMaxY(area);
   float bottom=NSMinY(area);
   float left=NSMinX(area);
   float base=bottom+1;
   float firstPlayerLeft, secondPlayerLeft;
   NSDictionary *attributes=[GroupMatch textAttributes];
   long i;
   NSString *name=nil;

   if ([TournamentDelegate.shared.preferences tourNumbers]) {
      [[NSString stringWithFormat:@"%ld", rNumber] drawAtPoint:NSMakePoint(left, base)
					       withAttributes:attributes];
      left=left+20.0;
   }

   [NSBezierPath strokeLineFromPoint:NSMakePoint(left, top)
			     toPoint:NSMakePoint(left, bottom)];
   [matchupString drawAtPoint:NSMakePoint(left+2, base) withAttributes:attributes];
   firstPlayerLeft=left+20.0;
   [NSBezierPath strokeLineFromPoint:NSMakePoint(firstPlayerLeft, top)
			     toPoint:NSMakePoint(firstPlayerLeft, bottom)];
   secondPlayerLeft=(firstPlayerLeft+setsLeft)/2.0;
   name=[[self upperPlayer] longName];
   if ([name length] > 15) {
      name=[name substringToIndex:15];
   }
   [name drawAtPoint:NSMakePoint(firstPlayerLeft+2, base) withAttributes:attributes];

   name=[[self lowerPlayer] longName];
   if ([name length] > 15) {
      name=[name substringToIndex:15];
   }
   [name drawAtPoint:NSMakePoint(secondPlayerLeft+2, base) withAttributes:attributes];
   [NSBezierPath strokeLineFromPoint:NSMakePoint(left, bottom)
			     toPoint:NSMakePoint(NSMaxX(area), bottom)];

   for(i=0; i<setCount; i++) {
      [NSBezierPath strokeLineFromPoint:NSMakePoint(setsLeft+i*24, top)
				toPoint:NSMakePoint(setsLeft+i*24, bottom)];
      [[self stringSet:i] drawAtPoint:NSMakePoint(setsLeft+i*24+2, base)
		       withAttributes:[GroupMatch smallAttributes]];
   }
}

+ (NSDictionary *)textAttributes; {
   return [NSMutableDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:10.0]
					     forKey:NSFontAttributeName];
}

+ (NSDictionary *)smallAttributes; {
	return [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Helvetica" size:8.0]
					   forKey:NSFontAttributeName];
}

- (void)putUmpire;
// GroupMatches do not yield umpires (yet)
{
}

- (void)removeUmpire;
{
}

- (void)takeUmpire;
// they never do take umpires
{
}

- (void)setReady:(BOOL)aFlag;
{
   if ([[TournamentDelegate.shared.matchController playingMatchesController] containsPlayable:group]) {
      return;	// leave player state untouched as long as Group is open
   } else {
      [super setReady:aFlag];
   }
}

- (void)setWinner:(id <Player>)win;
{
   [super setWinner:win];
   if (![group finished] && ![[TournamentDelegate.shared groupResult] currentlyEvaluates:group]) {
      [group checkMatches];
   }
}

- matchSheet:sender :(const NSRect)rect;
{
   [super matchSheet:sender :rect];

   [[group description] drawAtPoint:NSMakePoint(120.0, 144.0)
		     withAttributes:[Match textAttributes]];
   
   return self;
}

- (NSString *)roundString;
{
	NSString *gruppenspiel = NSLocalizedStringFromTable(@"Gruppenspiel", @"Matchblatt", 
																		 @"Gruppenspiel auf Matchblatt");
   return gruppenspiel;
}

- (NSString *)description;
{
   return [NSString stringWithFormat:@"Gruppenspiel %ld", rNumber];
}

- (long)desiredTablePriority;
{
   return 4;
}

- (NSString *)nextMatchId;
{
   return [NSString stringWithFormat:@"Gruppe %ld", [group number]];
}

- (NSString *)resultSeriesName;
{
    return [NSString stringWithFormat:@"%@_G", [series seriesName]];
}

- (NSString *)matchResultString;
{
	return [self resultString];
}

- (float) tourPriority;
{
   tourPrioCache = ([[self lowerPlayer] tourPriority] 
		+ [[self upperPlayer] tourPriority])/[group unfinishedMatches];
	return tourPrioCache;
}

- (NSString *)matchGroup;
{
	return [NSString stringWithFormat:@"Gruppe %ld", [group number]];
}

- (NSString *)defaultSetsResXml;
{
	long upperSets=0, lowerSets=0;
	if (winner == [self upperPlayer]) {
		upperSets=3;
	} else {
		lowerSets=3;
	}
	
	return [NSString stringWithFormat:@"     sets-a=\"%ld\" sets-b=\"%ld\"", upperSets, lowerSets];
}

- (NSString *)defaultPointsResXml;
{
	NSMutableString *result = [NSMutableString string];
	long i, pointsA=24, pointsB=24;
	if ([self upperPlayer] == winner) {
		[result appendString:[self setResultXml:1 a:11 b:9]];
		[result appendString:[self setResultXml:2 a:11 b:8]];
		[result appendString:[self setResultXml:3 a:11 b:7]];
		pointsA = 33;
	} else {
		[result appendString:[self setResultXml:1 a:9 b:11]];
		[result appendString:[self setResultXml:2 a:8 b:11]];
		[result appendString:[self setResultXml:3 a:7 b:11]];
		pointsB = 33;
	}
	for (i=4; i<=7; i++) {
		[result appendString:[self setResultXml:i a:0 b:0]];
	}

	[result appendFormat:@"     games-a=\"%ld\" games-b=\"%ld\"", pointsA, pointsB];
	
	return result;
}

- (bool)hasDetails;
{
	return ![self wo] && (([self upperSetPoints:2] != 0) || ([self lowerSetPoints:2] != 0));
			// its not been a "walk over" and has at least 3 set results
}

- (NSString *)resultDetailsXml;
{
	if ([self hasDetails]) {
		return [super resultDetailsXml];
	} else {
		return [NSString stringWithFormat:@"%@\n%@\n%@", [self matchResXml], 
						[self defaultSetsResXml], [self defaultPointsResXml]];
	}
}
@end
