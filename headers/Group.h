/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a group of a series that is played with groups.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 6.3.94, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import "GroupMatch.h"
#import "Player.h"
#import "Series.h"

@class GroupPlayer;

// standardmethods

@interface Group:NSObject <Playable,Inspectable>
{
   BOOL    	        inBrowser;		// YES if possible and in Browser
   NSMutableArray   *players;		// up to 10 players currently
   NSArray	        *_ranking;		// the ranking after the group is finished
   NSMutableArray   *matches;		// all the matches necessary
   NSMutableArray   *positions;		// positions in the matchTable where top players go
	
   NSMutableDictionary *_wins;		// indexed by licence number
   NSMutableDictionary *_sets;
   NSMutableDictionary *_points;
   NSMutableDictionary *_rank;
	
   long       number;			// number of this group
   long       rNumber;			// running number for group
   float     tourPrioCache;		// caches tourPriority for efficiency
   id <drawableSeries>   series;			// series of the group
   BOOL      finished;			// YES if all Matches are played
   NSString *startTime;			// string for starting time
   NSString *tableString;		// table where the group is played
   long 	    _detailPages; 		// number of pages the group details will take up
}

-init;
-initSeries:(id <NSObject, drawableSeries>)ser number:(long)num;
-initFromPositions:(NSArray *)pls series:(id <drawableSeries>)ser number:(long)num;

// set- und get-methods

- (id <NSObject, drawableSeries>)series;
- (NSArray *)players;
- (NSArray *)matches;
- (NSArray *)rankingList;
- (NSMutableArray *)positions;
- (long)number;
- (long)rNumber;
- (BOOL)finished;
- (long)detailPages;
- (NSString *)identifier;
- (NSString *)textRepresentation;

- (void)setSeries:(id <NSObject, drawableSeries>)aSeries;
- (void)setPlayers:(NSArray *)plys;
- (void)setRankingList:(NSArray *)ranking;
- (void)addPosition:(GroupPlayer *)aPosition;
- (void)setNumber:(long)num;
- (void)setFinished:(BOOL)aFlag;
- (void)setTime:(NSString *)aString;
- (bool)hasBeenStarted;

// special methods

- printGroup;
- drawGroupLeft:(long)left top:(float *)top;
- (void)drawDetails:(float *)top firstPageBottom:(float)firstPageBottom;
- (void)drawGroupTitleBelow:(float *)top;
- (void)drawMatchesDetailsBelow:(float *)top firstPageBottom:(float)firstPageBottom;
- (void)drawMatchesTitleBelow:(float *)top;
- (void)drawMatch:(long) i below:(float *)top;
- (void)drawPlayersDetails:(float *)top;
- (void)drawPlayersTitle:(float *)top;
- (void)drawPlayer:(long) i below:(float *)top;
- (void)drawWinnerOfMatch:(GroupMatch *)match into:(NSRect) area;
- (void)drawWinsBelow:(float *)top;
- finishedDrawing;
// enter the group into players matches list and the ready matches into
// the matchBrowser
- makeMatches;
// inserts the necessary matches into the list matches
- checkMatches;
// checks if all matches are played and displays the result.
- (long)printWOPlayersInto:text;
- (long)printNPPlayersInto:text;
- keepResultOf:(id<Player>)pl rank:(long)rank wins:(long)wins
          setsPlus:(long)setsp minus:(long)setsm pointsPlus:(long)pointsp minus:(long)pointsm;

- (IBAction) allMatchSheets:(id)sender;
- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;

- (NSDictionary *)textAttributes;
- (NSMutableDictionary *)browserAttributes;
- (NSDictionary *)largeAttributes;
- (NSDictionary *)largeBoldAttributes;
- (NSDictionary *)smallAttributes;
- (NSDictionary *)tinyAttributes;
- (NSDictionary *)titleAttributes;
- (NSDictionary *)otherMatchesAttributes;
- (NSDictionary*)playerAttributes;
- (NSDictionary*)playerBoldAttributes;
- (BOOL)replacePlayer:(id<Player>)player by:(id<Player>)replacement;
- (long)unfinishedMatches;
- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
- (long)umpiresFrom;
- (NSComparisonResult)prioCompare:(id<Playable>)otherPlayable;
- (void)playSingleMatches;

@end
