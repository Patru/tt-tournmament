/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <Cocoa/Cocoa.h>
#import "Group.h"
#import "Series.h"

@interface GroupSeries:Series
{
   NSMutableArray *groups;					// a NSMutablearray of groups
   NSMutableArray *pageGroupStarts;	// start of pages
   NSMutableArray *groupPlayers;		// an Array of players to be in groups
																		// note that these will be empty except during draw!
   long   usualGroupSize;	/* maximum size of the group, this and one less
													   will be used if even, one more if odd.
													   Recommended sizes are 3 and 4*/
   long numberOfDetailPages;
} 

- (instancetype)initFromRecord:(PGSQLRecord *)record;
- (IBAction) allMatchSheets:(id)sender;
- (NSArray *)groups;
- (void)add:(Group *)group;

//protected, not enforced, please adhere
- (BOOL)doGroupDraw;
- (BOOL)makeGroups;
- (void)addGroupForPlayers:(NSArray *)pls;
- (BOOL)newGroupDraw;
- (BOOL)drawTablesFromGroups;
- (BOOL)drawFromGroups;
- (void)drawGroupNames:(const NSRect)rect page:(NSRect *)page;
- (void) drawKOTable:(const NSRect)rect page:(NSRect *)page
    maxMatchesOnPage:(long)maxMatchesOnPage;
- drawGroups:(float *)top from:(long)first to:(long)last;
- (void)makePlayersFromGroupsRank:(long)from to:(long)to;
- (void)optimizeClubsInLists:(NSMutableArray *)playerLists;
- (bool)optimizeClubsInLists:(NSMutableArray *)playerLists
              usingPositions:(NSArray *)groupPositions
                       level:(long)level;
- (long) maxGroupPlayerRanking:(NSArray *)playerLists;
- (NSMutableArray *)groupPositionClasses:(NSMutableArray *)playerLists;
- (NSMutableArray *)groupRankClasses:(NSMutableArray *)playerLists;
- (void)drawGroupDetails:(const NSRect)rect page:(NSRect *)page;
- (void) drawGroupRankingFrom:(long)from doneUpTo:(long)done at:(float)left below:(float)top;
- (void) splitGroupPlayersFromPlayers;
- (long)  numberOfGroupsDrawn;
- (long)  numberOfGroups;
- (void)startSeries;

- paginate:sender;
- paginateGroups:aView;
- (long)detailPages;
- textRankingListIn:text;
-(void) appendGroupRanksAfterPromoteesTo:(id)text withOffset:(long)initialOffset;
- (NSMutableArray *) addGroupResultsTo:(NSMutableArray *)list from:(long) offset upTo:(long)max lastGroup:(long) last;

@end
