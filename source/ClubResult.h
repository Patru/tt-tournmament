//
//  ClubResult.h
//  Tournament
//
//  Created by Paul Trunz on 18.04.15.
//  Copyright 2015 Soft-Werker GmbH. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Series.h"
#import "SinglePlayer.h"


@interface ClubResult : NSObject {
	NSString *name;
	NSMutableArray *results;
	long total;
}

+ (ClubResult *) with:(NSString *)aName;
- (ClubResult *) initWithName:(NSString *)aName;

- (NSComparisonResult)compare:(ClubResult *)otherClub;
- (void) add:(SinglePlayer *)player series:(Series *)ser points:(long)points;
- (long) total;
- (void) appendAsLineTo:(id)text;
- (NSArray *) results;
- (NSString *) name;
@end
