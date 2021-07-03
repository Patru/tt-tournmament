//
//  PreferencesViewController.swift
//  Tournament
//
//  Created by Paul Trunz on 08.08.17.
//
//

import Foundation

class PreferencesViewController : NSViewController {
   
   @objc @IBOutlet weak var smallPaperLandscapeButton : NSButton!
   @objc @IBOutlet weak var smallPaperPortaitButton : NSButton!
   @IBOutlet var tournamentList: NSArrayController!
   
   let longPageSize = 792.0;
   let shortPageSize = 520.0;

   @objc lazy private(set) var smallPaperLandscape : NSPrintInfo = {
      if let data = UserDefaults.standard.data(forKey: "TourMatchPaperLandscape"),
      let dict = NSUnarchiver.unarchiveObject(with: data) as? [NSPrintInfo.AttributeKey : Any] {
         return NSPrintInfo.init(dictionary: dict)
      } else {
         let smallPaper = NSPrintInfo.shared.copy() as! NSPrintInfo
         smallPaper.orientation = .landscape
         return smallPaper
      }
   }()
   
   @objc lazy private(set) var smallPaperPortrait : NSPrintInfo = {
      if let data = UserDefaults.standard.data(forKey: "TourMatchPaperPortrait"),
         let dict = NSUnarchiver.unarchiveObject(with: data) as? [NSPrintInfo.AttributeKey : Any] {
         return NSPrintInfo.init(dictionary: dict)
      } else {
         let smallPaper = NSPrintInfo.shared.copy() as! NSPrintInfo
         smallPaper.orientation = .portrait
         return smallPaper
      }
   }()

   @objc var matchWidth : Double { get {
      if landscape {
         return UserDefaults.standard.double(forKey: "TourMatchWidthLandscape")
      } else {
         return UserDefaults.standard.double(forKey: "TourMatchWidthPortrait")
      }
      } }

   @objc internal(set) var tournamentId : String { get {
      if let id = UserDefaults.standard.string(forKey: "TournamentID") {
         return id
      } else {
         if let tournaments = tournamentList.arrangedObjects as? [Tournament], tournaments.count > 0 {
            let tourId = tournaments[0].id
            UserDefaults.standard.set(tourId, forKey: "TournamentID")
            
            return tourId
         } else {
            return "none"
         }
      }
      }
      set{ UserDefaults.standard.set(newValue, forKey: "TournamentID") }}
   
   @objc var landscape : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourLandscape")
      } }
   
   @objc var groupLetters : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourGroupLetters")
      } }
   
   @objc var printImmediately : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourPrintImmediately")
      } }
   
   @objc var tourNumbers : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourShowNumbers")
      } }
   
   @objc var exactResults : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourExactResults")
      } }
   
   @objc var otherMatches : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourOtherMatches")
      } }
   
   @objc var groupDetails : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourGroupDetails")
      } }
   
   @objc var umpires : Bool { get {
      return UserDefaults.standard.bool(forKey: "TourUmpires")
      } }
   
   @objc var pageWidth : Double { get {
      if landscape {
         return longPageSize
      } else {
         return shortPageSize
      }
      } }
   
   @objc var pageHeight : Double { get {
      if landscape {
         return shortPageSize
      } else {
         return longPageSize
      }
      } }
   
   @objc var maxMatchOnPage : Int { get {
      if landscape {
         return matchesLandscape
      } else {
         return matchesPortrait
      }
      } }
   
   @objc var maxGroupsOnPage : Int { get {
      if landscape {
         return 14
      } else {
         return 22
      }
      } }

   @objc var tableString : String { get {
      if landscape {
         return UserDefaults.standard.string(forKey: "TourTableLandscape") ?? "not set"
      } else {
         return UserDefaults.standard.string(forKey: "TourTablePortrait") ?? "not set"
      }
      }
   }
   
   @objc var lineDelta : Double { get {
      if landscape {
         return 36.0*12.0/Double(matchesLandscape)
      } else {
         return 58.0*12.0/Double(matchesPortrait)
      }
      } }
   
   var matchesLandscape : Int { get {
      let matches = UserDefaults.standard.integer(forKey: "TourNumMatchLandscape")
      if matches > 0 {
         return matches
      } else {
         return 19
      }
      } }
   
   var matchesPortrait : Int { get {
      let matches = UserDefaults.standard.integer(forKey: "TourNumMatchPortrait")
      if matches > 0 {
         return matches
      } else {
         return 19
      }
      } }
   
   @objc var firstWidth : Double { get {
      if landscape {
         return UserDefaults.standard.double(forKey: "TourFirstWidthLandscape")
      } else {
         return UserDefaults.standard.double(forKey: "TourFirstWidthPortrait")
      }
      } }
   
   @IBAction func setupSmallPaperLandscape(_ sender: Any) {
      let pageLayout = NSPageLayout()
      
      pageLayout.beginSheet(with: smallPaperLandscape, modalFor: self.view.window!, delegate: self, didEnd: #selector(landscapeDidEnd(_:returnCode:contextInfo:)), contextInfo: nil)
   }
   
   @objc func landscapeDidEnd(_ layout: NSPageLayout, returnCode: NSApplication.ModalResponse, contextInfo: UnsafeRawPointer) {
      if returnCode == .OK {
         smallPaperLandscape = layout.printInfo!;
         smallPaperLandscape.verticalPagination = .fitPagination
         smallPaperLandscape.horizontalPagination = .fitPagination
         smallPaperLandscape.isHorizontallyCentered = false
         smallPaperLandscape.isVerticallyCentered = false
         smallPaperLandscape.leftMargin = 1.0
         smallPaperLandscape.rightMargin = 22.0
         smallPaperLandscape.topMargin = 1.0
         smallPaperLandscape.bottomMargin = 1.0
         smallPaperLandscapeButton.title = visual(printInfo: smallPaperLandscape)
         let data = NSArchiver.archivedData(withRootObject: smallPaperLandscape.dictionary())
         UserDefaults.standard.set(data, forKey: "TourMatchPaperLandscape")
      }
   }
   
   @IBAction func setupSmallPaperPortrait(_ sender: Any) {
      let pageLayout = NSPageLayout()
      
      pageLayout.beginSheet(with: smallPaperPortrait, modalFor: self.view.window!, delegate: self, didEnd: #selector(portraitDidEnd(_:returnCode:contextInfo:)), contextInfo: nil)
   }
   
   @objc func portraitDidEnd(_ layout: NSPageLayout, returnCode: NSApplication.ModalResponse, contextInfo: UnsafeRawPointer) {
      if returnCode == .OK {
         smallPaperPortrait = layout.printInfo!;
         smallPaperPortrait.verticalPagination = .fitPagination
         smallPaperPortrait.horizontalPagination = .fitPagination
         smallPaperPortrait.isHorizontallyCentered = false
         smallPaperPortrait.isVerticallyCentered = false
         smallPaperPortrait.leftMargin = 5.0
         smallPaperPortrait.rightMargin = 5.0
         smallPaperPortrait.topMargin = 1.0
         smallPaperPortrait.bottomMargin = 19.0
         smallPaperPortaitButton.title = visual(printInfo: smallPaperPortrait)
         let data = NSArchiver.archivedData(withRootObject: smallPaperPortrait.dictionary())
         UserDefaults.standard.set(data, forKey: "TourMatchPaperPortrait")
      }
   }
   
   func visual(printInfo: NSPrintInfo) -> String {
      let orientation = printInfo.orientation == .landscape ? "⇔📖" : "⇕📄"
      let paperName = printInfo.paperName!
      return "\(paperName.rawValue):\(orientation) (\(printInfo.printer.name))"
   }
   
   override func viewDidAppear() {
      smallPaperLandscapeButton.title = visual(printInfo: smallPaperLandscape)
      smallPaperPortaitButton.title = visual(printInfo: smallPaperPortrait)
      
      tournamentList.add(contentsOf: Tournament.all())
      let tournamentId = UserDefaults.standard.string(forKey: "TournamentID")
      if let all = tournamentList.arrangedObjects as? [Tournament] {
         all.enumerated().forEach({ (offset: Int, tournament: Tournament) in
            if tournament.id == tournamentId {
               tournamentList.setSelectionIndex(offset)
               // I guess we have to set the selection index instead of adding to the selection because of ourch choice of bindings.
            }
         })
      }
      tournamentList.addObserver(self, forKeyPath: "selection", options: .new, context: nil)
      // TODO: Move this to an #observe-closure in Xcode 9

      // strange that we have to do this in a view delegate, somehow the IB-settings get "overwritten"
      self.view.window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "TourPreferences"))
   }
   
   override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
      // I know I should check my context, but this is just a very crude kludge anyways, move to closure!
      if let array = object as? NSArrayController {
         if let tournament = array.selectedObjects[0] as? Tournament {
            UserDefaults.standard.set(tournament.id, forKey: "TournamentID")
         }
      }
   }

}
