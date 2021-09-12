//
//  TournamentPlayer.swift
//  Tournament
//
//  Created by Paul Trunz on 30.03.20.
//

import Cocoa

class TournamentPlayer : NSObject {
   let player:SinglePlayer
   var menSeries = [Series]()
   var womenSeries = [Series]()
   var ageSeries = [Series]()
   var doubleSeries = [Series]()
   var tourPayment : TourPayment?
   var hasPaidForTournament : Bool {
      get {
         return tourPayment != nil
      }
   }
   var present : PresentEntry?
   var isAttending : Bool {
      return present != nil
   }
   private(set) lazy var menPayment : Double = {sum(of: menSeries)}()
   private(set) lazy var womenPayment : Double =  {sum(of: womenSeries)}()
   private(set) lazy var agePayment : Double =  {sum(of: ageSeries)}()
   private(set) lazy var doublePayment : Double = {sum(of: doubleSeries)}()
   private(set) var sttPayment : Double = 0.0
   @objc let longName : String
   @objc let club : String
   let nameClubPoints : String

   @objc init(player:SinglePlayer) {
      self.player = player
      longName = player.longName()
      if let tournament = TournamentDelegate.shared.tournament() {
         sttPayment = 4.0 + tournament.depotStartingNumber
      } else if player.firstName().count > 0 {        // if this is a real player, not just the total object
         sttPayment = 4.0
      }
      club = player.club()
      nameClubPoints = "\(player.pName()!), \(player.firstName()!): \(player.club()!); \(player.elo())"

   }
   
   @objc static func player(licence:Int) -> TournamentPlayer? {
      if let plyr = TournamentDelegate.shared.playerController.player(withLicence: licence) {
         return TournamentPlayer(player: plyr)
      } else {
         return nil
      }
   }
   
   func fetchSeries() {
      let tDel = TournamentDelegate.shared
      guard let db = tDel.database(), let tourId = tDel.tournament()?.id else { return }
      let licence = player.licence()
      let seriesQuery = String(format:"SELECT series FROM PlaySeries WHERE  TournamentID = '%@' AND Licence = %d", tourId, licence)
         if let rs = db.open(seriesQuery) as? PGSQLRecordset {
            var rec = rs.moveFirst()
            while let record = rec {
               if let serName = record.field(byName: "series").asString() {
                  if let series = tDel.seriesController.seriesWith(name: serName) {
                     add(series)
                  }
               }
               rec = rs.moveNext()
            }

      }
   }
   
   func sum(of list: [Series]) -> Double {
      return list.reduce(0.0) { (res, ser) in
         res + price(series:ser)
      }
   }
   
   func price(series:Series) -> Double {
      if let cat = player.category(), cat.starts(with: "U") {
         return series.priceYoung()
      } else {
         return series.priceAdult()
      }
   }
   
   @objc func add(_ series:Series?) {
      if let series = series {
         if series.isKind(of: DoubleSeries.self) || series.isKind(of: MixedSeries.self)
               || series.isKind(of: DoubleGroupSeries.self) {
            // this is unfortunate, Mixed cannot derive from Double currently ...
            doubleSeries.append(series)
         } else if let age = series.age(), age.count > 0, Series.uoSet().contains(age.unicodeScalars.first!) {
            ageSeries.append(series)
         } else if series.isWomanSeries() {
            womenSeries.append(series)
         } else {
            menSeries.append(series)
         }
      }
   }
   
   @objc func add(paymentsOf player: TournamentPlayer) {
      menPayment += player.menPayment
      womenPayment += player.womenPayment
      doublePayment += player.doublePayment
      agePayment += player.agePayment
      sttPayment += player.sttPayment
   }

   func totalPayment() -> Double {
      return menPayment+womenPayment+agePayment+doublePayment+sttPayment;
   }

   let textAttributes : [NSAttributedStringKey:Any] = [.font: NSFont(name: "Helvetica", size: 9.0)!]
   let boldAttributes : [NSAttributedStringKey:Any] = [.font: NSFont(name: "Helvetica-Bold", size: 9.0)!]
   let lineDelta = CGFloat(11.0)
   
   @objc func draw(at point:NSPoint) {
      drawReminder(at: point)
      drawDetails(at: NSPoint(x: point.x+200, y:point.y))
   }
   
   func drawReminder(at point: NSPoint) {
      var line = point
      line.y -= 2*lineDelta
      player.club().draw(at:line, withAttributes: boldAttributes)
      line.y -= lineDelta
      player.longName().draw(at:line, withAttributes: textAttributes)
      line.y -= lineDelta
      if player.ranking() > 0 {
         var pt = line
         String(format: "%ld", player.ranking()).draw(at: pt, withAttributes: textAttributes)
         if player.womanRanking() > 0 {
            pt.x += 30.0
            String(format: "%ld", player.womanRanking()).draw(at: pt, withAttributes: textAttributes)
         }
         pt.x += 50.0
         player.category().draw(at:pt, withAttributes:textAttributes)
         line.y -= lineDelta
         String(format:"Total %6.2f", totalPayment()).draw(at:line, withAttributes:boldAttributes)
      }
   }
   
   func drawDetails(at point: NSPoint) {
      var line = point
      line.y -= lineDelta
      if let tourTitle = TournamentDelegate.shared.tournament()?.title as NSString? {
         tourTitle.draw(at:line, withAttributes:boldAttributes)
      }
      line.y -= lineDelta
      var pt = line
      player.club().draw(at:pt, withAttributes: textAttributes)
      pt.x += 150
      (longName as NSString).draw(at: pt, withAttributes: textAttributes)
      line.y -= lineDelta
      self.draw(payment:menPayment, for:paymentNames(of:menSeries), of: §.menSeries, at:line, with:textAttributes)
      line.y -= lineDelta
      self.draw(payment:womenPayment, for:paymentNames(of:womenSeries), of: §.womenSeries, at:line, with:textAttributes)
      line.y -= lineDelta
      self.draw(payment:doublePayment, for:paymentNames(of:doubleSeries), of: §.doubleSeries, at:line, with:textAttributes)
      line.y -= lineDelta
      self.draw(payment:agePayment, for:paymentNames(of:ageSeries), of: §.ageSeries, at:line, with:textAttributes)
      line.y -= lineDelta
      self.draw(payment:sttPayment, for:"", of: §.tourCard, at:line, with:textAttributes)
      line.y -= lineDelta
      self.draw(payment:totalPayment(), for:"", of: §.total, at:line, with:boldAttributes)
   }
   
   func paymentNames(of series : [Series]) -> String {
      return series.map{ser in
         if ser.seriesName() == nil {
            return "unknown"
         }
         return ser.paymentName()}.joined(separator: ", ")
   }
   /*
    - (void)drawAt:(NSPoint)aPoint;
    {
    NSPoint line=aPoint;
    NSPoint point;
    
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
    NSString *menSingles = NSLocalizedStringFromTable(@"Herren Einzel", @"Tournament", @"Herren Einzel für Zahlung");
    [self drawPayment:_menPayment forSeries:_menSeries ofType:menSingles at:line withAttributes:textAttributes];
    line.y-= lineDelta;
    NSString *womenSingles = NSLocalizedStringFromTable(@"Damen Einzel", @"Tournament", @"Damen Einzel für Zahlung");
    [self drawPayment:_womenPayment forSeries:_womenSeries ofType:womenSingles at:line withAttributes:textAttributes];
    line.y-= lineDelta;
    NSString *doubles = NSLocalizedStringFromTable(@"Doppel", @"Tournament", @"Doppel für Zahlung");
    [self drawPayment:_doublePayment forSeries:_doubleSeries ofType:doubles at:line withAttributes:textAttributes];
    line.y-= lineDelta;
    NSString *ageSeries = NSLocalizedStringFromTable(@"Altersserie", @"Tournament", @"Altersserie für Zahlung");
    [self drawPayment:_agePayment forSeries:_ageSeries ofType:ageSeries at:line withAttributes:textAttributes];
    line.y-= lineDelta;
    NSString *tourCard = NSLocalizedStringFromTable(@"Turnierkarte STTV", @"Tournament", @"Turnierkarte STTV für Zahlung");
    [self drawPayment:_sttvPayment forSeries:@"" ofType:tourCard at:line withAttributes:textAttributes];
    line.y-= lineDelta;
    NSString *total = NSLocalizedStringFromTable(@"Totalbetrag", @"Tournament", @"Totalbetrag für Zahlung");
    [self drawPayment:[self totalPayment] forSeries:@"" ofType:total at:line withAttributes:boldAttributes];
    }

 */
   
   func draw(payment: Double, for series:String, of type: String, at line:NSPoint, with attributes: [NSAttributedStringKey:Any]) {
      if payment != 0.0 {
         var pt = line
         (type as NSString).draw(at: pt, withAttributes: attributes)
         pt.x += 100
         (series as NSString).draw(at: pt, withAttributes: attributes)
         pt.x += 150
         NSString(format: "%6.2f", payment).draw(at: pt, withAttributes: attributes)
      }
   }
}

/*
#import "TournamentPlayer.h"
#import "PlayerController.h"
#import "TournamentController.h"
#import "Tournament-Swift.h"

@implementation TournamentPlayer

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
   NSString *menSingles = NSLocalizedStringFromTable(@"Herren Einzel", @"Tournament", @"Herren Einzel für Zahlung");
   [self drawPayment:_menPayment forSeries:_menSeries ofType:menSingles at:line withAttributes:textAttributes];
   line.y-= lineDelta;
   NSString *womenSingles = NSLocalizedStringFromTable(@"Damen Einzel", @"Tournament", @"Damen Einzel für Zahlung");
   [self drawPayment:_womenPayment forSeries:_womenSeries ofType:womenSingles at:line withAttributes:textAttributes];
   line.y-= lineDelta;
   NSString *doubles = NSLocalizedStringFromTable(@"Doppel", @"Tournament", @"Doppel für Zahlung");
   [self drawPayment:_doublePayment forSeries:_doubleSeries ofType:doubles at:line withAttributes:textAttributes];
   line.y-= lineDelta;
   NSString *ageSeries = NSLocalizedStringFromTable(@"Altersserie", @"Tournament", @"Altersserie für Zahlung");
   [self drawPayment:_agePayment forSeries:_ageSeries ofType:ageSeries at:line withAttributes:textAttributes];
   line.y-= lineDelta;
   NSString *tourCard = NSLocalizedStringFromTable(@"Turnierkarte STTV", @"Tournament", @"Turnierkarte STTV für Zahlung");
   [self drawPayment:_sttvPayment forSeries:@"" ofType:tourCard at:line withAttributes:textAttributes];
   line.y-= lineDelta;
   NSString *total = NSLocalizedStringFromTable(@"Totalbetrag", @"Tournament", @"Totalbetrag für Zahlung");
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
      return [[TournamentPlayer alloc] initWithPlayer:player];
   }
   return nil;
   }
   
   - (void)addPayments:(TournamentPlayer *)aTournamentPlayer;
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
*/
