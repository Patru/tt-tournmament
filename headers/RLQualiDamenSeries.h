//
//  RLQualiSeries.h
//  Tournament
//
//  Created by Paul Trunz on 11.11.06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GroupSeries.h"


@interface RLQualiDamenSeries : GroupSeries {
	NSMutableArray *matchTables;
}

- (BOOL)secondStageDraw;
- (NSArray *) rankingList;
- (BOOL)useAllGroupsForSecondStage;
- (NSMutableArray *)groupPositionClasses:(NSMutableArray *)playerLists;

@end
