//
//  TournamentDataController.swift
//  Tournament
//
//  Created by Paul Trunz on 02.07.17.
//
//

class TournamentDataController : NSViewController {
   @IBOutlet weak var Id: NSTextField!
   
   @objc dynamic var tournament : Tournament?
      // dynamic is instrumental to allow KVO to work!! (@objc is not (since Tournament derives from NSObject?)
   
   @IBAction func save(_ sender: NSButton) {
      self.view.window!.makeFirstResponder(nil)
      tournament?.save()
   }
   
   @IBAction func setCommercial(_ sender: NSButton) {
      let openPanel = NSOpenPanel()
      openPanel.allowedFileTypes = NSImage.imageTypes
      
      openPanel.beginSheetModal(for: self.view.window!) { (result) in
         if result == .OK {
            self.tournament?.commercial = openPanel.urls[0].path
         }
      }
   }
   
   func fetchConfiguredTournament() {
      let id = TournamentDelegate.shared.preferences().tournamentId
      if let tournament = Tournament.fetch(with: id) {
         self.tournament = tournament
         Id.isEnabled = false
      } else {
         let alert = NSAlert()
         alert.messageText = §.error
         alert.informativeText = String(format:§.tournamentWithIdNotFound, id)
         alert.addButton(withTitle: §.ok)
         alert.beginSheetModal(for: NSApp.mainWindow!, completionHandler: nil)
      }
   }

   override func viewDidAppear() {
      // strange that we have to do this in a view delegate, somehow the IB-settings get "overwritten"
      self.view.window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "TourDetails"))
   }
}
