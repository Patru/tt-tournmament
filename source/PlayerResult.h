//
//  PlayerResult.h
//  Tournament
//
//  Created by Paul Trunz on 19.04.15.
//  Copyright 2015 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface PlayerResult : NSObject {
	NSString *playerInSeries;
	long points;
}

+ (PlayerResult *)for:(NSString *)plSer points:(long)serPoints;
- (PlayerResult *)initFor:(NSString *)plSer points:(long)serPoints;
- (void)appendAsLineTo:(id)text;

@end
