/*****************************************************************************
     Use: Control a table tennis tournament.
          interface for all players.
Language: Objective-C                 System: MacOS X
  Author: Paul Trunz, Copyright 2001
 History: 16.9.2001, Patru: started port from NeXTStep
    Bugs: -not very well documented
 *****************************************************************************/

#import <Foundation/Foundation.h>
#import <Foundation/NSObject.h>
#import "drawableSeries.h"
#import "Playable.h"

extern NSString *RANKING_LINE_FORMAT;

@protocol Player <NSObject, NSCoding>
- (NSString *)pName;
- (NSString *)firstName;
- (NSString *)club;
- (NSString *)drawClub;
- (NSString *)category;
- (NSNumber *)licenceNumber;
- (long)licence;
- (long)ranking;		// returns an id since it will be used with perform
- (long)rankingInSeries:(id <drawableSeries>)aSeries;
- (float)dayRanking;
- (long)womanRanking;	// same as ranking
- (long)performWithLongResult:(SEL)aSelector;
- (float) tourPriority;
- (BOOL)ready;
- (NSString *)longName;
- (NSString *)shortName;
- (BOOL)present;
- (BOOL)wo;
- (bool)attendant;
- (bool)canContinue;
- (void)setReady:(BOOL)flag;
- (void)setPresent:(BOOL)aFlag;
- (void)setWO:(BOOL)aFlag;
- (BOOL)contains:(id <Player>)aPlayer;
- (void)showAt:(float)x yPos:(float)y clPos:(float)club;
- (void)drawInMatchTableOf:sender x:(float)x y:(float)y;
- (void)setPersPriority:(float)aFloat;
      // TODO: decide if we should make use of this properly or remove it altogether
- (float) seriesPriority:(id <drawableSeries>)series;
   // value is used to set gray-level, should be smaller than NX_LTGRAY
- (void)putAsUmpire;
- (void)removeFromUmpireList;
- (bool)shouldUmpire;
- (long)numberOfDependentMatches;

- (void)addMatch:(id <Playable>)aMatch;
- (void)removeMatch:(id <Playable>)aMatch;
- (void)finishMatch:(id <Playable>)aMatch;
- (bool)hasRealPlayers;
- (NSString *)clickId:(id <drawableSeries>)series;
- (void)appendPlayerXmlTo:(NSMutableString *)text forSeries:(id <drawableSeries>)series;
- (NSString *)rankingListLines:(NSString *)rankStr;
- (void)adjustDayRanking:(float)adjustRanking;
@end
