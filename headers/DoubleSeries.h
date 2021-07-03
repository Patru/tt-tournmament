/*****************************************************************************
     Use: Control a table tennis tournament.
          Controls a double series of a tournament.
Language: Objective-C                 System: NeXTSTEP 3.1
  Author: Paul Trunz, Copyright 1995
 Version: 0.1, first try
 History: 12.2.95, Patru: first written
    Bugs: -not very well documented
 *****************************************************************************/

#import <appkit/appkit.h>
#import "Series.h"

@interface DoubleSeries:Series
{
   NSMutableDictionary *doublePartner;	// the partner of a player
   NSMutableArray *singles;		// a List of single players registered
} 

+ (SinglePlayer *)single;
- (instancetype)init;
- (instancetype)initFromRecord:(PGSQLRecord *)record;
- (void)encodeWithCoder:(NSCoder *)encoder;
- (id)initWithCoder:(NSCoder *)decoder;
- addSingle:(SinglePlayer *)pl;
- (void)addPlayer:(SinglePlayer *)pl set:(long)setNum partner:(SinglePlayer *) partnerPlayer;
- makeDoubles;
- (void)cleanup;
- (BOOL)makeTable;
- (float)basePriority;
- (NSString *)numString;
- (void)gatherPointsIn:(NSMutableDictionary *)clubResults;
+ (NSString *) doublePaymentNane: (Series *) series;

@end
