//
//  TournamentPlayer.h
//  Tournament
//
//  Created by Paul Trunz on Wed Feb 06 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SinglePlayer.h"

// deprecated
@interface TournamentPlayer1 : NSObject {
   SinglePlayer *_player;
   NSString *_longName;
   NSMutableString *_menSeries;
   double _menPayment;
   NSMutableString *_womenSeries;
   double _womenPayment;
   NSMutableString *_ageSeries;
   double _agePayment;
   NSMutableString *_doubleSeries;
   double _doublePayment;
   double _sttvPayment;
   double _startingNumberDepot;
}


+ (instancetype)playerWithLicence:(long)licence;
- (instancetype)initWithPlayer:(SinglePlayer *)player;
- (void)addSeries:(NSString *)series;
- (void)drawAt:(NSPoint)aPoint;
- (void)drawPayment:(float)payment forSeries:(NSString *)series
 	     ofType:(NSString *)type at:(NSPoint)aPoint
     withAttributes:(NSDictionary *)attributes;
- (double)totalPayment;
- (NSString *)club;
- (NSString *)longName;
- (void)addPayments:(TournamentPlayer1 *)aTournamentPlayer;
- (NSDictionary *)boldAttributes;
- (NSDictionary *)textAttributes;
- (long)price:(NSString *)series;

@end
