//
//  FinderController.swift
//  Tournament
//
//  Created by Paul Trunz on 04.08.17.
//
//

import Foundation

class FinderController : NSWindowController {
   @IBAction func showFinder(_ sender: Any) {
   if window == nil {
      let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Finder"), bundle: nil)
      let controller = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Finder Controller")) as! FinderController
      window = controller.window
 //     Bundle.main.loadNibNamed("Finder", owner: self, topLevelObjects: nil);
   }
   // [playerField selectText:self];
      if let matchWindow = TournamentDelegate.shared.matchController?.matchWindow() {
         matchWindow.beginSheet(window!, completionHandler:nil);
      }
   }
}
