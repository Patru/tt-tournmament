/*****************************************************************************
     Use: Control a table tennis tournament.
          Storage and display of a single goup match.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1993
 Version: 0.1, first try
 History: 19.6.1994, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/
 
#import <appkit/appkit.h>
#import "Match.h"
@class Group;

@interface GroupMatch:Match
{
   Group *group;
   NSString *  matchupString;
}

- (instancetype)initFrom:(char)pl1 andPlayer:(char)pl2 of:(Group *)grp NS_DESIGNATED_INITIALIZER;
- (id)initWithCoder:(NSCoder *)decoder;
- group;
- (NSString *)matchupString;
- (NSString *)stringWinner;
- (void)drawForMatchSheetAt:(float)top;
- (void)drawResultInto:(NSRect) area;
- (float) tourPriority;
+ (NSDictionary *)textAttributes;
+ (NSDictionary *)smallAttributes;

@end
