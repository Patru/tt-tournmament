/*****************************************************************************
     Use: Control a table tennis tournament.
          Defines a formal protocol for a drawable series.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.4.1995, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#define stringsize    9.0
#define maxPageHeight 792
#define maxPageWidth  520
@class Match;

#import <Foundation/NSString.h>

@protocol drawableSeries <NSObject, NSCoding>
- (long)totalPages;
- (long)lastInterestingPage;
- (long)maxRanking;
- paginate:sender;
- (void) drawPages:(const NSRect)rect page:(NSRect *)page
                          maxMatchesOnPage:(long)maxMatchesOnPage;
- (NSString *)numString;

- (NSString *)fullName;
- (NSString *)fullNameNoSpace;
- (NSString *)seriesName;
- (void) removePlayer:(id)pl;
- (float)maxDayRanking;
- (void)startSeries;
- (BOOL)started;
- (long)promotees;

- (SEL)rankSel;
- (float)tourPriorityFor:(float)dayRanking;
- (NSString *)rankingStringFor:(id)player;
- (void)matchNotPlayed:(Match*)match;
- (void)playSingleMatchesForAllOpenGroups;
- (void)endSeriesProcessing:sender;
- (NSString *)nextMatchIdFor:(Match *)match;
- (NSString *)roundStringFor:(Match *)match;
- (Match *)smallFinalTable;
- (BOOL)finished;
- (NSString *)startTime;
@end

