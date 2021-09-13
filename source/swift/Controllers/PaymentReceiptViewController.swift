//
//  PaymentReceiptViewController.swift
//  Tournament
//
//  Created by Paul Trunz on 27.06.20.
//

import Foundation
import Cocoa

class PaymentReceiptViewController : NSViewController {
    @IBOutlet var receiptView: PaymentReceiptView!
    
    func printReceipt(for player: TournamentPlayer, at counter: Int32) {
        NSLog("setze Spieler %@ für recipt view", player.longName)
        if receiptView != nil {
            receiptView.counter = counter
            receiptView.player = player
        } else {
            NSLog("something wrong with your wiring, check out https://developer.apple.com/forums/thread/122947 maybe?")
        }
    }
   
   @IBAction func print(_ sender: Any) {
      let tDelegate = TournamentDelegate.shared
      let smallLandscape = tDelegate.preferences().smallPaperLandscape
      let printtOperation = NSPrintOperation(view: receiptView, printInfo: smallLandscape)
      printtOperation.showsPrintPanel = !tDelegate.preferences().printImmediately
      printtOperation.run()
   }
}
