/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a single series of a tournament.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.5, with small final
 History: 21.11.93, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Player.h"
#import "InspectorController.h"
#import "SinglePlayer.h"
#import "Match.h"
#import "drawableSeries.h"

@class SeriesPlayer;		// tons of problems when importing
@class PGSQLRecord;

long meetClub(long num, id <Player> pl, NSMutableArray *club, NSMutableDictionary *tableNum);

void numberAllMatches(NSMutableArray *matches);

extern const struct SerFieldsStruct {
   __unsafe_unretained NSString *SeriesName;
   __unsafe_unretained NSString *FullName;
   __unsafe_unretained NSString *SetPlayers;
   __unsafe_unretained NSString *BestOfSeven;
   __unsafe_unretained NSString *StartTime;
   __unsafe_unretained NSString *Age;
   __unsafe_unretained NSString *Sex;
   __unsafe_unretained NSString *Type;
   __unsafe_unretained NSString *Grouping;
   __unsafe_unretained NSString *MinRanking;
   __unsafe_unretained NSString *MaxRanking;
   __unsafe_unretained NSString *Promotees;
   __unsafe_unretained NSString *SerCoefficient;
   __unsafe_unretained NSString *SmallFinal;
   __unsafe_unretained NSString *TournamentID;
   __unsafe_unretained NSString *PriceAdult;
   __unsafe_unretained NSString *PriceYoung;
} SerFields;


@interface Series:NSObject <drawableSeries, NSCoding, Inspectable>
{
   NSString * seriesName;
   NSString * fullName;
   NSMutableArray  *positions;		// positions for players in the tournament
   NSMutableArray  *players;		// players in this series, sorted by ranking
   Match *matchTable;		// tournament table
   long   setPlayers;		// lowest ranking of players who will be set
   char   sMode;			// draw-mode N(ormal), S(pecial), G(roup) ...
   long   bestOfSeven;		// 16 indicates best of 7 matches after the round of 16
   float priority;		// priority of this series
   NSString * startTime;		// time to start this series
   NSString * age;
   NSString * type;
   NSString * sex;			// W for women's series, M for men, nothing for mixed
   NSString * grouping;		// freeform grouping for series, intended for "Samstag" and "Sonntag"
   SEL    RankSel;		// selector for ranking (for women)
   BOOL   started;		// has the series started already?
   long   minRound;		// the farthest round played
   long   minRanking;		// the highest ranked and
   long   maxRanking;		// the highest ranked and
   long   promotees;		// number of players to promote to single eliminiation
   float  maxDayRanking;		// the highest Player (today) in the series
   double serCoefficient;		// factor to reduce til meet setPlayers
   double priceAdult;
   double priceYoung;
   NSMutableArray   *tablePages;		// for paginating
   id	    master;		// master table for paginating
   BOOL   alreadyDrawn;		// has the draw been done for the series?
   BOOL   _isNew;
   BOOL   _isEdited;
   long   _currentPage;		// the current page during drawing (for header)
   BOOL	 _smallFinal;
   Match  *smallFinalTable;		// table for the small final (of loosers in Semis), optional
   NSMutableArray<NSString *> *drawingErrors;
}

+ (NSString *) allFields;
+ (instancetype)fromRecord:(PGSQLRecord *)record;
+ (NSCharacterSet *)uoSet;

// standardmethods

- (instancetype)init;
- (instancetype)initFromRecord:(PGSQLRecord *)record;
- (BOOL) isEqual:anObject;
- (BOOL) appliesFor:(SinglePlayer *)player;

// set- und get-methods

- (void) setSeriesName:(NSString *)newName;
- (void) setFullName:(NSString *)newName;
- (void) setTourPriority:(float)newPriority;
- (void) setSMode:(char)aChar;
- (void) setBestOfSeven:(long)aLong;
- (void) setMatchTable:(Match *)aMatch;
- (void) checkMinRound:(long)aLong;
- (void) checkMaxRanking:(id <Player>)pl;
- (void) removePlayer:(id)pl;
- (BOOL) hasSmallFinal;
- (void) setSmallFinal: (BOOL)aSmallFinal;
- (Match *)smallFinalTable;
- (long) smallFinalPage;
- (BOOL) isWomanSeries;
- (long) minRanking;
- (long) maxRanking;
- (long) numberOfMatches;
- (long) numberOfUnplayedMatches;
- (long) numberOfUnplayedGroups;
- (long) furthestRound;
- (long) sternmostRound;
- (void) setAlreadyDrawn:(BOOL)drawn;
- (double) priceAdult;
- (void) setPriceAdult:(double)aDouble;
- (double) priceYoung;
- (void) setPriceYoung:(double)aDouble;

- drawSelf:(const NSRect)rect page:(NSRect *)page
                  maxMatchesOnPage:(long)maxMatchesOnPage;
- (void) drawRankingListBelow:(float) top at:(float)rankinglistleft;
- (void) drawRankingListPage: (const NSRect) rect page: (NSRect *) page maxMatchesOnPage:(long) maxMatchesOnPage;
- (NSMutableArray*) rankingListUpTo:(long) max;
- (float)pageHeader:(NSRect *)pageRect;
- (NSString *)seriesName;
- (NSString *)fullName;
- (NSString *)fullNameNoSpace;
- (NSString *)paymentName;
- (NSString *) doubleCategoryString;
- (Match *)matchTable;
- (float) tourPriority;
- (char)sMode;
- (long)bestOfSeven;
- (NSString *)finalString:(Match *) match;

- (void)cleanup;
- (BOOL)makeTable;
- (void) addSmallFinalIfDesired;
- (BOOL)doDraw;
- (SEL)rankSel;
- (void)setRankSel:(SEL) selector;
- (NSString *)sex;
- setSex:(NSString *)aString;
- (NSString *)grouping;
- (void)setGrouping:(NSString *)aString;
- (long)minRound;
- (long)maxRankingPresent;
- (long)promotees;
- (float)maxDayRanking;
- (float)basePriority;
- (BOOL)alreadyDrawn;
- (BOOL)drawContinuosly;
- (NSString *)startTime;
- (void)setStartTime:(NSString *)time;
- (long)countPlayers;
- (float)coefficient;
- setCoefficient:(float)aFloat;
- (long)setPlayers;
- setSetPlayers:(long)aLong;
- (long)numSetPlayers;
- (long)numberKoMatches;
- (void)switchPos:(long)pos1 with:(long)pos2;

- doubleMatch:aMatch;
- (void)addPlayer:(SinglePlayer *)pl set:(long)setNum partner:(SinglePlayer *) partnerPlayer;
- addSeriesPlayer:(SeriesPlayer *)aSerPlayer;
- (void)startSeries;
- (BOOL)started;
- (void)setStarted:(BOOL)flag;
- (IBAction) allMatchSheets:(id)sender;
- (void)endSeriesProcessing:sender;
- (void)printWONPPlayersInto:text;
- (long)printWOPlayersInto:text;
- (long)printNPPlayersInto:text;

- (void)storeInDatabase;
- (void)insertIntoDatabase;
- (void)updateDatabase;
- (void)deleteFromDatabase;

- (id)objectFor:(NSString *)identifier;
- (void)setObject:(id)anObject for:(NSString *)identifier;

- (void)appendAsHTMLTo:(NSMutableString *)html;
- (void)appendTableFooterTo:(NSMutableString *)html;
- (void)appendSingleResultsAsTextTo:(NSMutableString *)text;
- (void)appendSingleSeriesInfoAsTextTo:(NSMutableString *)text;

   // protected, unfortunately not possible to declare for methods, please adhere
   //            to it anyway.
- (BOOL)doSimpleDraw;
- paginateTable:(Match *)aMatch in:aView;
- (NSDictionary*)largeAttributes;
- (void)appendPlayers:(NSArray *)pls asRowsTo:(NSMutableString *)html;
- (void)numberMatchesInTable:(Match *)finalMatch;
- (void)bucketSortPositions:(NSMutableArray *)sortPos;
- (float)tourPriorityFor:(float)dayRanking;
- (BOOL)finished;
- textRankingListIn:text;
- (bool)matches:(NSString *)selectedGroup;
- (void)alreadyHasPartner:(SinglePlayer *)player existingPartner:(SinglePlayer*)partner
					newPartner:(SinglePlayer*)newPartner;
- (void)inscriptionWithoutPartner:(SinglePlayer *)player notPartner:(SinglePlayer*)partner;
- (void)notWithHimself:(SinglePlayer *)player;
- (NSMutableArray *) matchTables;
- (long)numberOfGroupsDrawn;
- (NSArray *) players;
- (void)appendAsXmlTo:(NSMutableString *)text;
- (void)appendEachPlayerXmlTo:(NSMutableString *)text;		// override this in subclasses?
- (NSString *)type;
- (void)appendMatchResultsAsXmlTo:(NSMutableString *)text;
- (NSString *)age;
- (NSString *)ageGroup;
- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
- (void) addResult:(SinglePlayer *)player points:(long)points to:(NSMutableDictionary *)clubResults;
- (void) doublePointsIn:(NSMutableDictionary *)clubResults;
- (void) gatherPointsIn:(NSMutableDictionary *)clubResults;
- (long)numberOfSetsFor:(Match *)match;
- (BOOL)olderThan:(Series *)other;
- (BOOL)validate;
- (NSString *)postfixFor:(Match *)match;
- (NSString *)nextMatchIdFor:(Match *)match;
- (NSString *)roundStringFor:(Match *)match;
- (Series *)loadPlayersFromDatabase;
- (NSArray<NSString *> *)drawingErrors;
- (NSString *)nameFor:(Match *)match;
- (long)maxPositionNumber;

@end
