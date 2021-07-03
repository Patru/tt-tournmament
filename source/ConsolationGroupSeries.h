/*****************************************************************************
 Use: Control a table tennis tournament (as part of Tournament.app)
 Controls a single group series with consolation round.
 Language: Objective-C                 System: Mac OS X
 Author: Paul Trunz, Copyright 2012, Soft-Werker GmbH
 Version: 0.2, first try
 History: 18.5.2012, Patru: first written
 Bugs: -not very well documented :-)
 *****************************************************************************/
#import <Cocoa/Cocoa.h>
#import "GroupSeries.h"

@interface ConsolationGroupSeries : GroupSeries {
	Match *consolationTable;
}

- (BOOL)newGroupDraw;
- (BOOL)drawTablesFromGroups;
// adds drawing of consolation round
- (void)encodeWithCoder:(NSCoder *)encoder;
// also save consolation table
- (id)initWithCoder:(NSCoder *)decoder;
- (NSString *)postfixFor:(Match *)match;
@end
