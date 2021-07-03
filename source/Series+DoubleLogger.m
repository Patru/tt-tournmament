//
//  Series+DoubleLogger.m
//  Tournament
//
//  Created by Paul Trunz on 11.09.17.
//
//

#import "Series+DoubleLogger.h"
#import "SinglePlayer.h"
#import "Tournament-Swift.h"

@implementation Series (DoubleLogger)

- (void)logDouble:(SinglePlayer *)first with:(SinglePlayer *)second {
   NSString *doubleFormat = NSLocalizedStringFromTable(@"DoubleFormat", @"Tournament",
                                                       @"Format for logging auto matched doubles");

   NSString *doubleDescription = [NSString stringWithFormat:doubleFormat,
                                 [first longName], [first club], [first rankingInSeries:self],
                                 [second longName], [second club], [second rankingInSeries:self]];
   [[TournamentDelegate shared] logLine:doubleDescription];
}

- (void)logSameClubForced;
{
   NSString *sameClubForced = NSLocalizedStringFromTable(@"SameClubForced", @"Tournament",
                                                         @"Log text if the same club was forced when building doubles");
   [[TournamentDelegate shared] logLine:sameClubForced];
}

- (void)logSeries:(NSString *)name;
{
   NSString *seriesFormat = NSLocalizedStringFromTable(@"SeriesFormat", @"Tournament",
                                                       @"Format for logging the name of the series to draw");
   NSString *serName = [NSString stringWithFormat:seriesFormat, name];
   
   [[TournamentDelegate shared] logLine:serName];
}

- (void)logCouldNotAssign:(SinglePlayer *)player;
{
   NSString *couldNotAssignFormat = NSLocalizedStringFromTable(@"CouldNotAssignFormat", @"Tournament",
                                                       @"Format for logging a player who did not get a partner");
   
   NSString *couldNotAssignPlayer = [NSString stringWithFormat:couldNotAssignFormat,
                                  [player longName], [player club], [player rankingInSeries:self]];
   [[TournamentDelegate shared] logLine:couldNotAssignPlayer];
}

- (void)logCouldNotAssignMan:(SinglePlayer *)player;
{
   NSString *couldNotAssignFormat = NSLocalizedStringFromTable(@"CouldNotAssignManFormat", @"Tournament",
                                                               @"Format for logging a man who did not get a partner");
   
   NSString *couldNotAssignMan = [NSString stringWithFormat:couldNotAssignFormat,
                                     [player longName], [player club], [player rankingInSeries:self]];
   [[TournamentDelegate shared] logLine:couldNotAssignMan];
}

- (void)logCouldNotAssignWoman:(SinglePlayer *)player;
{
   NSString *couldNotAssignFormat = NSLocalizedStringFromTable(@"CouldNotAssignWomanFormat", @"Tournament",
                                                               @"Format for logging a woman who did not get a partner");
   
   NSString *couldNotAssignWoman = [NSString stringWithFormat:couldNotAssignFormat,
                                     [player longName], [player club], [player rankingInSeries:self]];
   [[TournamentDelegate shared] logLine:couldNotAssignWoman];
}
@end
