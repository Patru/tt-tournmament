//
//  ConfirmationPlayer.h
//  Tournament
//
//  Created by Paul Trunz on 13.12.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "GroupSeries.h"
#import "SeriesPlayer.h"


@interface ConfirmationPlayer : NSObject {
	GroupSeries* series;
	SeriesPlayer* player;
}

- (GroupSeries *)series;
- (SeriesPlayer *)seriesPlayer;
- initWithSeries:(GroupSeries *)aSeries player:(SeriesPlayer *)aSeriesPlayer;
- (NSComparisonResult)compare:(ConfirmationPlayer *)otherObject;
- (void)setSeries:(GroupSeries *)series;
@end
