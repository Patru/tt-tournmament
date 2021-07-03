//
//  EloGroupSeries.h
//  Tournament
//
//  Created by Paul Trunz on 27.08.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GroupSeries.h"
#import "Group.h"

@class EloSeries;

@interface EloGroupSeries : GroupSeries {
	NSMutableArray *matchTables;
}

- init;
+ (EloGroupSeries *) seriesfor:(EloSeries *)mother index:(long)idx players:(NSArray *)plsForSer;
- (void)drawGroupsAndTables:(const NSRect)rect page:(NSRect *)page;
- (long)countClubs:(NSMutableArray *)playerLists;
- (void)optimizeClubs:(NSMutableArray *)playerLists;
- (void)groupStage;
- (BOOL)secondStage;
- (void)groupOfLastThreeFrom:(Group *)first and:(Group *) second;
- (bool)secondStageLooserMatch:(long)fours;
- (NSArray *) rankingList;
- (void)fixRankingForClickTT;
- (long)countPlayers;

@end
