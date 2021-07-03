/*****************************************************************************
     Use: Control a table tennis tournament.
          Stores the player(s) who form a team for in a series.
Language: Objective-C                 System: Mac OS X (10.1)
  Author: Paul Trunz, Copyright 1994
 Version: 0.1, first try
 History: 14.5.1994, Patru: project started
    Bugs: -not very well documented
 *****************************************************************************/

#import "SeriesPlayer.h"
#import "GroupPlayer.h"
#import "DoublePlayer.h"
#import "RaisePlayer.h"
#import "Series.h"

@implementation SeriesPlayer

// standardmethods

- init;
{
   return [self initPlayer:nil setNumber:0];
} // init

- initPlayer:(id<Player> )aPlayer setNumber:(long)aLong;
{
   self=[super init];
   player = aPlayer;
   setNumber = aLong;
   return self;
} // initPlayer

- initDouble:(id<Player>)firstPlayer partner:(id<Player>)secondPlayer
            setNumber:(long)aLong;
{
   self=[super init];
   player = [[DoublePlayer alloc] initDouble:(SinglePlayer*)firstPlayer partner:(SinglePlayer*)secondPlayer];
   setNumber = aLong;
   return self;
} // initDouble

- initGroup:(Group *)aGroup position:(long)aPosition;
{
   player = [[GroupPlayer alloc] initGroup:aGroup position:aPosition];
   setNumber = aPosition;
   return self;
} // initGroup


- initRaise:(RaiseGroupSeries *)aSeries position:(long)aPosition
  setNumber:(long)aSetNumber;
{
   player = [[RaisePlayer alloc] initSeries:aSeries position:aPosition];
   setNumber = aSetNumber;
   return self;
} // initGroup


- (id<Player>)player;
{
   return player;
} // player

- (long)setNumber;
{
   return setNumber;
} // setNumber

- (BOOL)isStronger:(SeriesPlayer *)aSerPlayer sender:sender;
// sender must respondTo rankSel and return the selector for ranking
{
   if (setNumber == 0) {
      long me = [player rankingInSeries:(Series *)sender];
      long he = [[aSerPlayer player] rankingInSeries:(Series *)sender];
      
      return (([aSerPlayer setNumber] == 0) && ((me > he)
                                                || ((me == he) &&([player dayRanking]>[[aSerPlayer player] dayRanking]))));
   } else {
      return ( ([aSerPlayer setNumber] == 0) || (setNumber < [aSerPlayer setNumber])
              || ( (setNumber == [aSerPlayer setNumber])
                  && ([player dayRanking]>[[aSerPlayer player] dayRanking])));
   } // if
} // isStronger

- setPlayer:(id<Player> )aPlayer;
{
   player = aPlayer;
   return self;
} // setPlayer

- setSetNumber:(long)aLong;
{
   setNumber = aLong;
   return self;
} // setSetNumber

- (void)encodeWithCoder:(NSCoder *)encoder
{
	[encoder encodeObject:player];
	[encoder encodeValueOfObjCType:@encode(long) at:&setNumber];
}

- (id)initWithCoder:(NSCoder *)decoder
{
	self=[super init];
	player=[decoder decodeObject];
	[decoder decodeValueOfObjCType:@encode(long) at:&setNumber];
	
	return self;
}

- (void)appendAsHTMLRowTo:(NSMutableString *)html position:(long)position forSeries:(Series *)series;
{
   [html appendString:@"<tr>"];
   [html appendString:@"<td align=\"right\">"];
   [html appendFormat:@"%ld", position];
   [html appendString:@"</td>"];
   [html appendString:@"<td>"];
   [html appendString:[player longName]];
   [html appendString:@"</td>"];
   [html appendString:@"<td>"];
   [html appendString:[player club]];
   [html appendString:@"</td>"];
   [html appendString:@"<td align=\"right\">"];
   [html appendFormat:@"%ld", [player rankingInSeries:series]];
   [html appendString:@"</td>"];
   [html appendString:@"<td align=\"right\">"];
   if (setNumber != 0) {
      [html appendFormat:@"%ld", setNumber];
   } else {
      [html appendString:@"&nbsp;"];
   }
   [html appendString:@"</td>"];
   [html appendString:@"</tr>\n"];
}

- (void)appendAsXmlTo:(NSMutableString *)text forSeries:(Series *)series;
{
	//if ([player hasRealPlayers]) {
		[player appendPlayerXmlTo:text forSeries:series];
	//}
}

@end
