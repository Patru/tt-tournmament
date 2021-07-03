//
//  Series+DoubleLogger.h
//  Tournament
//
//  Created by Paul Trunz on 11.09.17.
//
//

#import "Series.h"

@interface Series (DoubleLogger)
// This should actually be a protocol extension with implementation for these methods, but that will only work in Swift.

- (void)logDouble:(SinglePlayer *)first with:(SinglePlayer *)second;
- (void)logSameClubForced;
- (void)logSeries:(NSString *)name;
- (void)logCouldNotAssign:(SinglePlayer *)player;
- (void)logCouldNotAssignMan:(SinglePlayer *)player;
- (void)logCouldNotAssignWoman:(SinglePlayer *)player;

@end
