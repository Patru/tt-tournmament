//
//  TournamentTable.m
//  Tournament
//
//  Created by Paul Trunz on Tue May 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "TournamentTable.h"
#import <PGSQLKit/PGSQLKit.h>
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation TournamentTable

+ (TournamentTable *)tableWithNumber:(long)aNumber priority:(long)aPriority
		     nextToFollowing:(bool)isNextToFollowing
			  occupiedBy:(id<Playable>)aPlayable;
{
   TournamentTable *table = [[TournamentTable alloc] initWithNumber:aNumber priority:aPriority
						    nextToFollowing:isNextToFollowing
							 occupiedBy:aPlayable];

   return table;
}

- (TournamentTable *)initWithNumber:(long)aNumber priority:(long)aPriority
		    nextToFollowing:(bool)isNextToFollowing
			 occupiedBy:(id<Playable>)aPlayable;
{
   self=[super init];
   number = [[NSNumber alloc] initWithLong:aNumber];
   priority = aPriority;
   nextToFollowing = isNextToFollowing;
   occupiedBy = aPlayable;
   
   return self;
}

- (long)number;
{
   return [number longValue];
}

- (NSNumber *)NSNumber;
{
   return number;
}

- (long)priority;
{
   return priority;
}

- (bool)isNextToFollowing;
{
   return nextToFollowing;
}

- (id<Playable>)occupiedBy;
{
   return occupiedBy;
}

- (NSUInteger)hash;
{
   return [number longValue];
}

- (BOOL)isEqual:(id)anObject;
{
   if ([anObject isKindOfClass:[TournamentTable class]]) {
      return [number intValue] == [(TournamentTable *)anObject number];
   }
   
   return false;
}

- (void)setPriority:(int)aPriority;
{
   priority = aPriority;
}

- (void)setNextToFollowing:(bool)isNextToFollowing;
{
   nextToFollowing = isNextToFollowing;
}

- (void)setOccupiedBy:(id<Playable>)aPlayable;
{
   occupiedBy = aPlayable;
   [self storeInDatabase];
}

- (void)storeInDatabase;
{
   PGSQLConnection *database=TournamentDelegate.shared.database;
   NSString *updateTable = [NSString stringWithFormat:@"UPDATE TourTable SET Priority = %ld, NextToFollowing = '%d', OccupiedBy = %ld WHERE Number = %ld AND TournamentID = '%@'", priority, nextToFollowing, [occupiedBy rNumber],
                          [number longValue], TournamentDelegate.shared.preferences.tournamentId];
   
   if ((![database execCommand:updateTable]) || ([@"UPDATE 0" isEqualToString:[database lastCmdStatus]])) {
      // if we fail to update I guess we need to insert
      // (stupid execCommand interface, no proper way to determine if any *real* updates took place
      NSString *insertTable = [NSString stringWithFormat:@"INSERT INTO TourTable (Number, Priority, NextToFollowing, OccupiedBy, TournamentId) VALUES (%ld, %ld, '%d', %ld, '%@')", [number longValue], priority, nextToFollowing, [occupiedBy rNumber], TournamentDelegate.shared.preferences.tournamentId];
      [database execCommand:insertTable];
   }
}

@end
