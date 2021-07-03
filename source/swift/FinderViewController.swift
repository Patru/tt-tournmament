//
//  FinderViewController.swift
//  Tournament
//
//  Created by Paul Trunz on 04.08.17.
//

import Foundation

class FinderViewController : NSViewController {
   
   @IBAction func findMatch(_ sender: NSTextField) {
    let tDel = TournamentDelegate.shared
    guard let matchWindow = tDel.matchController?.matchWindow() else { return }
      
      tDel.tournamentInspector.inspect(tDel.playable(withNumber:sender.integerValue))
      matchWindow.endSheet(self.view.window!);
   }
   
   @IBAction func findPlayer(_ sender: NSTextField) {
      let tDel = TournamentDelegate.shared
      guard let matchWindow = tDel.matchController?.matchWindow() else { return }
      
      tDel.tournamentInspector.inspect(tDel.playerController.player(withLicence: sender.integerValue))
      matchWindow.endSheet(self.view.window!);
   }
   
   @IBAction func dismiss(_ sender: NSButton) {
      let tDel = TournamentDelegate.shared
      guard let matchWindow = tDel.matchController?.matchWindow() else { return }
      
      matchWindow.endSheet(self.view.window!);
   }
}
