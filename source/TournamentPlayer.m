//
//  TournamentPlayer.m
//  Tournament
//
//  Created by Paul Trunz on Wed Feb 06 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "TournamentPlayer.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

// deprecated
@implementation TournamentPlayer1

static NSSet *sundaySeries = nil;

- initWithPlayer:(SinglePlayer *)player;
{
   _player=player;
   _longName = nil;
   _menSeries=[[NSMutableString alloc] init];
   _womenSeries=[[NSMutableString alloc] init];
   _ageSeries=[[NSMutableString alloc] init];
   _doubleSeries=[[NSMutableString alloc] init];
   _menPayment=0.0;
   _womenPayment=0.0;
   _doublePayment=0.0;
   _agePayment=0.0;

   return self;
}

- (void)addSeries:(NSString *)seriesName;
{
   long price = [self price:seriesName];
   long size=[seriesName length];
   char serChar=[seriesName characterAtIndex:size-1];
   char firstChar=[seriesName characterAtIndex:0];
   
   if ([seriesName rangeOfString:@"Do"].location != NSNotFound) {
      if (firstChar == 'W') {
         [_doubleSeries appendString:@"Da "];
      } else if (firstChar == 'X') {
         [_doubleSeries appendString:@"Mix "];
      }
      
      if (isdigit(serChar)) {
         NSString *category = [seriesName substringFromIndex:size-3];     // we expect this to be an age category
         [_doubleSeries appendFormat:@"%@ ", category];
      } else if (serChar < 'D') {
         [_doubleSeries appendFormat:@"%c%c ", serChar, serChar+1];
      } else {
         [_doubleSeries appendFormat:@"D "];
      }
      _doublePayment = _doublePayment+price;
   } else if ((firstChar == 'U') || (firstChar == 'O') || ([seriesName hasPrefix:@"Elite"])) {
      [_ageSeries appendFormat:@"%@ ", seriesName];
      _agePayment = _agePayment + price;
   } else if (firstChar == 'W') {
      [_womenSeries appendFormat:@"%@ ",[seriesName substringFromIndex:1]];
      _womenPayment = _womenPayment + price;
   } else {
      if (firstChar == 'M') {
         [_menSeries appendFormat:@"%@ ",[seriesName substringFromIndex:1]];
      } else {
         [_menSeries appendFormat:@"%@ ",seriesName];
      }
      _menPayment = _menPayment + price;
   }
   _sttvPayment = 4 + TournamentDelegate.shared.tournament.depotStartingNumber;
}

const float lineDelta  =  11.0;

- (void)drawAt:(NSPoint)aPoint;
{
   NSPoint line=aPoint;
   NSPoint point;
   long womanRanking;
   NSDictionary *textAttributes = [self textAttributes];
   NSDictionary *boldAttributes = [self boldAttributes];

   line.y-= 2*lineDelta;
   [[_player club] drawAtPoint:line withAttributes:boldAttributes];
   line.y-= lineDelta;
   [[_player longName] drawAtPoint:line withAttributes:textAttributes];
   line.y-= lineDelta;
   point = line;
   if (_player != nil) {
      [[NSString stringWithFormat:@"%ld", [_player ranking]] drawAtPoint:point
							 withAttributes:textAttributes];
      if ((womanRanking = (int)[_player womanRanking]) > 0) {
	 point.x+= 30;
	 [[NSString stringWithFormat:@"%ld", womanRanking] drawAtPoint:point
						       withAttributes:textAttributes];
      }
   }
   point.x+= 50;
   [[_player category] drawAtPoint:point withAttributes:textAttributes];
   line.y-= lineDelta;
   [[NSString stringWithFormat:@"Total %6.2f",[self totalPayment]]
        drawAtPoint:line withAttributes:boldAttributes];

   line=aPoint;
   line.y-= lineDelta;
   line.x+= 200;
   [TournamentDelegate.shared.tournament.title
	 drawAtPoint:line withAttributes:boldAttributes];
   line.y-= lineDelta;
   point = line;
   [[_player club] drawAtPoint:line withAttributes:boldAttributes];
   point.x+= 150;
   [[self longName] drawAtPoint:point withAttributes:textAttributes];
   line.y-= lineDelta;
	NSString *menSingles = NSLocalizedStringFromTable(@"Herren Einzel", @"Tournament", @"Herren Einzel fŸr Zahlung");
   [self drawPayment:_menPayment forSeries:_menSeries ofType:menSingles at:line withAttributes:textAttributes];
   line.y-= lineDelta;
	NSString *womenSingles = NSLocalizedStringFromTable(@"Damen Einzel", @"Tournament", @"Damen Einzel fŸr Zahlung");
   [self drawPayment:_womenPayment forSeries:_womenSeries ofType:womenSingles at:line withAttributes:textAttributes];
   line.y-= lineDelta;
	NSString *doubles = NSLocalizedStringFromTable(@"Doppel", @"Tournament", @"Doppel fŸr Zahlung");
   [self drawPayment:_doublePayment forSeries:_doubleSeries ofType:doubles at:line withAttributes:textAttributes];
   line.y-= lineDelta;
	NSString *ageSeries = NSLocalizedStringFromTable(@"Altersserie", @"Tournament", @"Altersserie fŸr Zahlung");
   [self drawPayment:_agePayment forSeries:_ageSeries ofType:ageSeries at:line withAttributes:textAttributes];
   line.y-= lineDelta;
	NSString *tourCard = NSLocalizedStringFromTable(@"Turnierkarte STT", @"Tournament", @"Turnierkarte STT fŸr Zahlung");
   [self drawPayment:_sttvPayment forSeries:@"" ofType:tourCard at:line withAttributes:textAttributes];
   line.y-= lineDelta;
	NSString *total = NSLocalizedStringFromTable(@"Totalbetrag", @"Tournament", @"Totalbetrag fŸr Zahlung");
   [self drawPayment:[self totalPayment] forSeries:@"" ofType:total at:line withAttributes:boldAttributes];
}

- (void)drawPayment:(float)payment forSeries:(NSString *)series
	     ofType:(NSString *)type at:(NSPoint)aPoint
     withAttributes:(NSDictionary *)attributes;
{
   if (payment != 0.0) {
      NSPoint point=aPoint;

      [type drawAtPoint:point withAttributes:attributes];
      point.x+= 100;
      [series drawAtPoint:point withAttributes:attributes];
      point.x+= 150;
      [[NSString stringWithFormat:@"%6.2f",payment] drawAtPoint:point
					         withAttributes:attributes];
   }
}

- (double)totalPayment;
{
   return _menPayment+_womenPayment+_agePayment+_doublePayment+_sttvPayment;
}

- (NSString *)club;
{
   if (_player != nil) {
      return [_player club];
   } else {
      return @"";
   }
}

- (NSString *)longName;
{
   if (_longName == nil) {
      if (_player != nil) {
	 _longName = [_player longName];
      } else {
	 _longName = @"";
      }
   }
   return _longName;
}

- (long) price:(NSString *)series;
{
	int price=0;
	BOOL isYoungPlayer = ([[_player category] rangeOfString:@"U1"].location != NSNotFound);
	
	if ([series rangeOfString:@"Elo"].location != NSNotFound) {
		if (isYoungPlayer) {
			price=21;
		} else {
			price=31;
		}
	} else if (isYoungPlayer) {
		price = 5;
	} else if ([series rangeOfString:@"Do"].location != NSNotFound) {
		price = 7;
	} else if ( (([series length] == 2) && ([series characterAtIndex:1] == 'A'))
						 || ([series rangeOfString:@"A20"].location != NSNotFound) ) {
		price = 10;
	} else {
		price = 8;
	}
	
	return price;
}

- (NSDictionary *) textAttributes;
{
   return [NSDictionary dictionaryWithObject:
	      [NSFont fontWithName:@"Helvetica" size:9.0] forKey:NSFontAttributeName];
}

- (NSDictionary *) boldAttributes;
{
   return [NSDictionary dictionaryWithObject:
  [NSFont fontWithName:@"Helvetica-Bold" size:9.0] forKey:NSFontAttributeName];
}

+ (instancetype)playerWithLicence:(long)licence;
{
   SinglePlayer *player = [TournamentDelegate.shared.playerController playerWithLicence:licence];

   if (player != nil) {
      return [[TournamentPlayer1 alloc] initWithPlayer:player];
   }
   return nil;
}

- (void)addPayments:(TournamentPlayer1 *)aTournamentPlayer;
{
	if (aTournamentPlayer != nil) {
		_menPayment += aTournamentPlayer->_menPayment;
		_womenPayment += aTournamentPlayer->_womenPayment;
		_doublePayment += aTournamentPlayer->_doublePayment;
		_agePayment += aTournamentPlayer->_agePayment;
		_sttvPayment += aTournamentPlayer->_sttvPayment;
	}
}

@end
