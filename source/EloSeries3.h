//
//  EloSeries.h
//  Tournament
//
//  Created by Paul Trunz on 27.08.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Series.h"


@interface EloSeries3 : Series {

}
- (instancetype)initFromRecord:(PGSQLRecord *)record;
- (void)makeGroupSeries:(long)idx withPlayers:(NSArray *)playersForSeries;

@end
