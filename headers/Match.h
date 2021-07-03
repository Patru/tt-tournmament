/*****************************************************************************
     Use: Control a table tennis tournament.
          Storage and display of a single match.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 21.11.93, Patru: project started
 	  15.4.95,  Patru: winners and loosers as incoming
    Bugs: -not very well documented
 *****************************************************************************/
 
#import <Cocoa/Cocoa.h>
#import "drawableSeries.h"
//#import "SinglePlayer.h"
#import "Player.h"
#import "InspectorController.h"
// #import "SmallTextController.h"

@class SinglePlayer;
@protocol VictoryNotification;

#define INT_MATCH_HEIGHT 25.0

@class SinglePlayer;		// forward declaration, no need to know

@interface Match:NSObject <Playable>
{
	BOOL         inBrowser;				// YES if possible and in Browser
	Match        *lower;					// the lower match in the previous round
	BOOL         lowerIsWinner;		// YES if lower is winner in previous round
	NSString     *lowerPrefix;		// prefix lower position
	Match        *upper;					// the upper match in the previous round
	BOOL         upperIsWinner;		// YES if upper is winner in previos round
	NSString     *upperPrefix;		// prefix for upper match
	Match        *next;						// the following match in the next round
	Match        *loserNext;			// the following match for the loser
	SinglePlayer *umpire;					// umpire for a specific match
	id <Player>  winner;					// pointer to the record of the winner
	NSString     *tableString;		// table where the match is played
	long         pMatches;				// number of matches before this one
	long         tNumber;					// number of a player in the series
	long         rNumber;					// running number of the match for the day
	long         round;						// round as number of matches
	float        tourPrioCache;		// caches tourPriority for efficiency
	id           series;					// the series in which the match is played
	NSString     *shouldStart;		// time when a match should start
	NSString     *startTime;			// effective starting time of a match
	long         sets[7];					// for the result
	BOOL         wo;							// not actually played
   long         duration;              // duration of the match, statistical purposes
   NSMutableArray<VictoryNotification> *notifiees;
}

+ (NSString *)stringForSetResult:(long)result;
+ (long)numberForSetString:(NSString *)result;

- initUpTo:(long)max current:(long)cur total:(long)tot
           next:(Match *)nxt series:(id)ser posList:(NSMutableArray *)pts;

/*****************************************************************************
 *                          Output-methods                                   *
 *****************************************************************************/

+ (NSMutableDictionary*)textAttributes;
+ (NSDictionary*)smallAttributes;
- (float)draw:(float *)top at:(float)left max:(long)maxMatches;
- (float)drawMaster:(float *)top at:(float)left max:(long)maxMatches
             page:(long*)page;
- (float)drawIntAt:(float)x y:(float)y width:(float)w max:(long)maxMatches
           toptext:(NSString *)toptext;
- (void)rankingList:(NSMutableArray *)players upTo:(long)max;
- (void)drawRankingList:(float)left at:(float *)top upTo:(long)max withOffset:(long)offset;
- textRankingListIn:text upTo:(long)max;
- (void)appendRankingToText:text upTo:(long)max withOffset:(long) offset;
- matchSheet:sender :(const NSRect)rects;
- (void)appendResultsAsTextTo:(NSMutableString *)text;
- (NSString *)resultString;
- (long) upperSetPoints:(long) i;
- (long) lowerSetPoints:(long) i;
- (NSString *)resultDetailsXml;
- (NSString *)matchResXml;
- (NSString *)setResultXml:(long)setNo a:(long) aPoints b:(long) bPoints;
- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;

/*****************************************************************************
 *                         Get-methods                                       *
 *****************************************************************************/

- (BOOL)ready;
// returns YES if both players are available currently
- (BOOL)wo;
- (Match *)lowerMatch;
- (NSString *)lowerPrefix;
- (BOOL)lowerIsWinner;
- (Match *)upperMatch;
- (NSString *)upperPrefix;
- (BOOL)upperIsWinner;
- (id <Player>)upperPlayer;
- (id <Player>)lowerPlayer;
- (id <Player>)opponentOf:(id <Player>)aPlayer;
- (Match *)nextMatch;
- (Match *)loserMatch;
- (id <Player>)winner;
- (SinglePlayer *)umpire;
- (long)pMatches;
- (long)tNumber;
- (long)rNumber;
- (long)round;
- (long)sternmostRoundUnplayed;
- (id<drawableSeries>)series;
- (long)upperPlayerPointsInSet:(long)setIndex;
- (long)lowerPlayerPointsInSet:(long)setIndex;
- (long)set:(long)setIndex;
- (long)numSet:(long)setIndex;
- (NSString *)upperLowerShortStringSet:(long)setIndex;
- (NSString *)winnerLoserShortStringSet:(long)setIndex;
- (id<Player>)winning;
- (id<Player>)losing;
- (BOOL)finished;
- (NSString *)stringSet:(long)aSet;
- (BOOL)isBestOfSeven;
- (NSString *)roundString;
- (long)numberOfSets;
- (long)upperPlayerSets;
- (long)lowerPlayerSets;
- (long)upperPlayerPoints;
- (long)lowerPlayerPoints;
- (NSString *)matchId;
- (NSString *)nextMatchId;
- (NSString *)resultSeriesName;
- (NSString *)seriesName;
- (NSString *)matchResultString;
- (Match *) seriesSmallFinal;
- (long)duration;
- (NSString *)textRepresentation;

/*****************************************************************************
 *                         Set-methods                                       *
 *****************************************************************************/

- (void)setLower:(Match *)low;
- (void)setLowerIsWinner:(BOOL)aFlag;
- (void)setLowerPrefix:(const char *)aString;
- (void)setUpper:(Match *)up;
- (void)setUpperIsWinner:(BOOL)aFlag;
- (void)setUpperPrefix:(const char *)aString;
- (void)setNext:(Match *)nx;
- (void)setLoserMatch:(Match *)aMatch;
- (void)sWinner:(id <Player>)win;
- (void)setWinner:(id <Player>)aPlayer;
- (void)setWO:(BOOL)aFlag;
- (void)setUmpire:(SinglePlayer *)ump;
- (void)setPMatches:(long)pm;
- (void)setTNumber:(long)tn;
- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
- (void)setInBrowser:(BOOL)aFlag;
- (void)setSet:(long)setIndex directlyTo:(long)result;
- (void)setWinnerLoserSet:(long)setIndex to:(NSString *)result;
- (void)setUpperLowerSet:(long)setIndex to:(NSString *)result;
- (void)setRound:(long)aInt;
- (void)setShouldStart:(const char *)aString;
- (void)setPlannedStart:(NSString *)timeString;

- (void)endMatchProcessing;
- (float)roundPriority;
- (float)minRoundPriority;
- (long)deltaRound:(long)toRound;
- (BOOL)hasSamePlayersAs:(Match *)match;
- (void)takeResultFrom:(Match *)match;
- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
- (Match *)makeLoserMatch;
- (NSComparisonResult)prioCompare:(id<Playable>)otherObject;
- (void)fixDuration;

   /*****************************************************************************
   *                        modification methods for inspector                  *
   *****************************************************************************/

- (void)invalidateFollowingResults:(id<Player>)previousWinner;
- (void)replaceWinnerInRunningMatchWith:(id <Player>)aPlayer;
- (void)updateWinnerTo:(id <Player>)aPlayer;

- (void) storeInDB;
- releaseAll;
    // recursively releases all matches decending from this one
- (id <InspectorControllerProtocol>) inspectorController;
- (BOOL)replacePlayer:(id<Player>)player by:(id<Player>)replacement;
- (bool)neitherPlayerAbsent;
- (void)handleWoOf:(id<Player>)woPlayer potentialWinner:(id<Player>)winPlayer;
- (void)addNotification:(id<VictoryNotification>)notifiee;


+ (float) lineDelta;
+ (void) fixDimensions;
@end
