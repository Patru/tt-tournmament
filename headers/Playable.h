/*****************************************************************************
Use: Control a table tennis tournament.
Protocol for all "Playable" things (such as Matches and Groups)
Language: Objective-C                 System: Mac OS X (10.1)
Author: Paul Trunz, Copyright 1993
Version: 0.1, first try
History: 21.11.93, Patru: project started
15.4.95,  Patru: winners and loosers as incoming
Bugs: -not very well documented
*****************************************************************************/

#import <Cocoa/Cocoa.h>
@protocol Player;
@class SinglePlayer;

@protocol Playable <NSObject,NSCoding>
- matchSheet:sender :(const NSRect)rect;
	// draw the sheet for use at the table
- result:(BOOL)show;
	// read the result of the player from the user
- drawAsOpen:(const NSRect)cellFrame inView:aView withAttributes:(NSDictionary *)attributes;
	// draw the browser-entry for the open-browser
- drawAsPlaying:(const NSRect)cellFrame inView:aView;
	// draw the browser-entry for the playint-browser
- (id<drawableSeries>)series;
	// the series in which the Playable should be played
- (long)rNumber;
	// running number of the match for the day
- (NSString *)tableString;
	// table to play the match, currently not implemented
- (BOOL)contains:(id<Player> )aPlayer;
	// YES if aPlayer is in the Playable-entity
- (BOOL)inBrowser;
	// YES if self is already displayed by the browser
- (BOOL)ready;
	// returns YES if all players are available currently
- (float) tourPriority;
	// compute tourPriority and return its value
- (float) tp;
	// return last computed tourPriority (used for sorting)
- (float) simpleTourPriority:(float)playerDayRanking;
- (float)numRoundPriority;
- (NSString *)time;
- (BOOL)isCurrentlyPlayed;
- (void)print:(id)sender;

- (void)setInBrowser:(BOOL)aFlag;
- (void)setTime:(NSString *)aString;
- (void)setReady:(BOOL)aFlag;
- (void)setRNumber:(long)rn;
- (void)setTableString:(NSString *)aString;
- (void)addTable:(long)tableNumber;
- (long)round;
- (BOOL)finished;
- (BOOL)wo;
- (void)putUmpire;
- (void)removeUmpire;
- (void)takeUmpire;
- (bool)playersShouldUmpire;
- (void)removeAllPlayersFromUmpireList;
- (void)withdraw;
- (float)textGray;
- (long)desiredTablePriority;
- (long)numberOfTables;
- (SinglePlayer *)umpire;
- (BOOL)replacePlayer:(id<Player>)player by:(id<Player>)replacement;
- (void)checkForWO;
- (void)gatherPlayersIn:(NSMutableSet *)allPlayers;
- (NSString *)shouldStart;
- (NSComparisonResult)prioCompare:(id<Playable>)otherPlayable;
- (NSString *)textRepresentation;
@end
