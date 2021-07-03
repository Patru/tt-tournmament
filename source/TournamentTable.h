//
//  TournamentTable.h
//  Tournament
//
//  Created by Paul Trunz on Tue May 13 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Match.h"


@interface TournamentTable : NSObject {
   NSNumber *number;
   long  priority;
   bool nextToFollowing;
   id<Playable> occupiedBy;
}

+ (TournamentTable *)tableWithNumber:(long)aNumber priority:(long)aPriority
		     nextToFollowing:(bool)isNextToFollowing
			  occupiedBy:(id<Playable>)aPlayable;

- (TournamentTable *)initWithNumber:(long)aNumber priority:(long)aPriority
		    nextToFollowing:(bool)isNextToFollowing
			 occupiedBy:(id<Playable>)aPlayable;
- (long)number;
- (NSNumber *)NSNumber;
- (long)priority;
- (bool)isNextToFollowing;
- (id<Playable>)occupiedBy;

- (void)setPriority:(int)aPriority;
- (void)setNextToFollowing:(bool)isNextToFollowing;
- (void)setOccupiedBy:(id<Playable>)aPlayable;

- (void)storeInDatabase;

@end
