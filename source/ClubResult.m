//
//  ClubResult.m
//  Tournament
//
//  Created by Paul Trunz on 18.04.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import "ClubResult.h"
#import "PlayerResult.h"
#import "SmallTextController.h"


@implementation ClubResult

- (ClubResult *) initWithName:(NSString *)aName;
{
	self = [super init];
	name = aName;
	results = [NSMutableArray array];
	
	return self;
}

+(ClubResult *) with:(NSString *)aName;
{
	ClubResult* result = [[ClubResult alloc] initWithName:aName];
	
	return result;
}

-(void)add:(SinglePlayer *)player series:(Series *)ser points:(long)points;
{
	NSString * serPlayer = [NSString stringWithFormat:@"%@: %@", [ser seriesName],
													[player longName]];
	PlayerResult *singleResult = [PlayerResult for:serPlayer points:points];
	total = total+points;
	[results addObject:singleResult];
}

- (NSComparisonResult)compare:(ClubResult *)otherClub {
	long otherTotal = [otherClub total];
	if (total < otherTotal) {
		return NSOrderedDescending;
	} else if (total > otherTotal) {
		return NSOrderedAscending;
	} else {
		return NSOrderedSame;
	}
}

- (long) total;
{
	return total;
}

- (void)appendAsLineTo:(id)text;
{
	[text appendText:[NSString stringWithFormat:@"%@\t%ld\n", name, total]];
}

- (NSArray *) results;
{
	return results;
}

- (NSString *) name;
{
   return name;
}
@end
