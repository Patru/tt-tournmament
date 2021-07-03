/*****************************************************************************
 Use: Control a table tennis tournament (as part of Tournament.app)
 Controls a single group series with consolation round and readily made groups.
 Language: Objective-C                 System: Mac OS X
 Author: Paul Trunz, Copyright 2013, Soft-Werker GmbH
 Version: 0.2, first try
 History: 24.1.2013, Patru: first written
 Bugs: -not very well documented :-)
 *****************************************************************************/

#import "ConsolationGroupedSeries.h"


@implementation ConsolationGroupedSeries

- init;
{
	confirmedPlayers = [[NSMutableArray alloc] initWithCapacity:11];
	return self;
}

- (BOOL)makeGroups;
{		// we do nothing, but only succeed if there are groups at all
	return [groups count] > 0;
}

- (void)encodeWithCoder:(NSCoder *)encoder;
{
	[super encodeWithCoder:encoder];
	[encoder encodeObject:confirmedPlayers];
}

- (id)initWithCoder:(NSCoder *)decoder;
{
	self = [super initWithCoder:decoder];
	confirmedPlayers=[decoder decodeObject];
	
	return self;
}

- (void)confirmPlayer:(SeriesPlayer *)serPlayer;
{
	if ([players containsObject:serPlayer]) {
		[confirmedPlayers addObject:serPlayer];
		[players removeObject:serPlayer];
	}
}

- (NSMutableArray *)confirmedPlayers;
{
	return confirmedPlayers;
}

@end
