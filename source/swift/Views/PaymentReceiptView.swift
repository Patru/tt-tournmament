//
//  PaymentReceiptView.swift
//  Tournament
//
//  Created by Paul Trunz on 27.06.20.
//

import Foundation
import AVFoundation
import Cocoa

class PaymentReceiptView : NSView {
   private static let textAttrs : [NSAttributedStringKey:Any] = [.font: NSFont(name: "Helvetica", size: 15.0)!]
   private static let boldAttrs : [NSAttributedStringKey:Any] = [.font: NSFont(name: "Helvetica-Bold", size: 15.0)!]
   private static let largeAttrs : [NSAttributedStringKey:Any] = [.font: NSFont(name: "Helvetica-Bold", size: 30.0)!]
   
   var counter : Int32 = 0
   var player : TournamentPlayer? {
      didSet {
         self.needsDisplay = true
      }
   }
   
   override func draw(_ dirtyRect: NSRect) {
      guard let tournament = TournamentDelegate.shared.tournament() else {return}
      
      NSColor.white.setFill()
      dirtyRect.fill()
      NSColor.black.setFill()
      let payAtDe = "Bezahlen am Tisch"
      payAtDe.draw(at: NSPoint(x: 20, y: 230), withAttributes: PaymentReceiptView.textAttrs)
      let payAtFr = "Payer à la table"
      payAtFr.draw(at: NSPoint(x: 20, y: 210), withAttributes: PaymentReceiptView.textAttrs)
      let table = NSString(format:"%d", counter)
      table.draw(at: NSPoint(x: 180, y: 210), withAttributes: PaymentReceiptView.largeAttrs)
      NSBezierPath(rect: CGRect(x: 300, y: 210, width: 35, height: 35)).stroke()
      tournament.title.draw(at: NSPoint(x:20, y:180), withAttributes: PaymentReceiptView.boldAttrs)
      
      if let player = self.player {
         let clubSize = player.club.size(withAttributes: PaymentReceiptView.textAttrs)
         var clubAttrs = PaymentReceiptView.textAttrs
         if clubSize.width > 190 {
            let fontSize = 15.0/clubSize.width*190
            clubAttrs[.font] = NSFont(name: "Helvetica", size: fontSize)!
         }
         player.club.draw(at: NSPoint(x:20, y: 160), withAttributes: clubAttrs)
         player.longName.draw(at: NSPoint(x:220, y: 160), withAttributes: PaymentReceiptView.textAttrs)
         draw(payment: player.menPayment, for: paymentNames(of: player.menSeries), of: §.menSeries, line: 140, with: PaymentReceiptView.textAttrs)
         draw(payment: player.womenPayment, for: paymentNames(of: player.womenSeries), of: §.womenSeries, line: 120, with: PaymentReceiptView.textAttrs)
         draw(payment: player.doublePayment, for: paymentNames(of: player.doubleSeries), of: §.doubleSeries, line: 100, with: PaymentReceiptView.textAttrs)
         draw(payment: player.agePayment, for: paymentNames(of: player.ageSeries), of: §.ageSeries, line: 80, with: PaymentReceiptView.textAttrs)
         draw(payment:player.sttPayment, for:"", of: §.tourCard, line: 50, with:PaymentReceiptView.textAttrs)
         draw(payment:player.totalPayment(), for:"", of: §.total, line: 30, with:PaymentReceiptView.boldAttrs)
      }
      
      let image = tournament.commercialImage
      let scaledRect = AVMakeRect(aspectRatio: image.size,
                                  insideRect: NSRect(x: 400, y: 200, width: 50, height: 50))
      image.draw(in: scaledRect)
      
   }
   
   func draw(payment: Double, for series:String, of type: String, line y:Double, with attributes: [NSAttributedStringKey:Any]) {
      if payment != 0.0 {
         var pt = NSPoint(x:20, y:y)
         type.draw(at: pt, withAttributes: attributes)
         pt.x += 200
         series.draw(at: pt, withAttributes: attributes)
         pt.x += 220
         let amountStr = NSString(format: "%6.2f", payment)
         let amountSize = amountStr.size(withAttributes: attributes)
         pt.x -= amountSize.width
         amountStr.draw(at: pt, withAttributes: attributes)
      }
   }
   
   func paymentNames(of series : [Series]) -> String {
      return series.map{ser in
         if ser.seriesName() == nil {
            return "unknown"
         }
         return ser.paymentName()}.joined(separator: ", ")
   }

}

