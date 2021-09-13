
//
//  AttendenceController.swift
//  Tournament
//
//  Created by Paul Trunz on 20.02.20.
//

import Foundation

class AttendanceController : NSViewController {
   @IBOutlet var registeredBrowser: NSBrowser!
   @IBOutlet var presentBrowser: NSBrowser!
   @IBOutlet var waitingListBrowser: NSBrowser!
   @IBOutlet var registeredCount: NSTextField!
   @IBOutlet var presentCount: NSTextField!
   @IBOutlet var maxCounters: NSTextField!
   @IBOutlet var nextCounter: NSTextField!
   @IBOutlet var searchField: NSSearchField!
   @IBOutlet var moveToPresentButton: NSButton!
   @IBOutlet var moveToRegisteredButton: NSButton!
   @IBOutlet var deleteRegistrationButton: NSButton!
   @IBOutlet var moveWaitingToPresentButton: NSButton!
   @IBOutlet var deleteWaitingButton: NSButton!

   private var _series : Series? = nil
   var series : Series {
      get {
         return _series!
      }
      set(newSeries) {
         if _series != newSeries {
            _series = newSeries
            if newSeries.players().count == 0 {
               newSeries.loadPlayersFromDatabase()
            }
            attendingPlayers = []
            registeredPlayers = tourPlayers(for: newSeries.players() as! [SeriesPlayer])
            shownPlayers = Array(registeredPlayers.values)
         }
         reloadBrowsers()
      }
   }
   var registeredPlayers  = [Int: TournamentPlayer]()
   var attendingPlayers : [TournamentPlayer] = []
   lazy var waitingListEntries : [WaitingListEntry] = {
      let entries = WaitingListEntry.all(series: self.series.seriesName())
      return entries
   }()
   var shownPlayers : [TournamentPlayer] = []
   var attendingMap = [Int: PresentEntry]()
   
   private(set) lazy var paymentReceiptWindowController : NSWindowController = {
      TournamentDelegate.shared.seriesStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Payment Receipt Window Controller")) as! NSWindowController
   }()
   
   private(set) lazy var paymentReceiptController : PaymentReceiptViewController = {
      if let content = paymentReceiptWindowController.window?.contentViewController {
         if let receiptController = content as? PaymentReceiptViewController {
            return receiptController
         }
      }
      return paymentReceiptWindowController.window?.contentViewController as! PaymentReceiptViewController
   }()
   
   private func tourPlayers(for players: [SeriesPlayer]) -> [Int: TournamentPlayer] {
      var tourPlayersMap = [Int: TournamentPlayer]()
      
      for player in players {
         let licence = player.player().licence()
         if let singlePlayer = player.player() as? SinglePlayer {
            tourPlayersMap[licence] = TournamentPlayer(player: singlePlayer)
         }
      }
      
      return tourPlayersMap
   }
   
   private func tourPlayers(for waiting: [WaitingListEntry]) -> [TournamentPlayer] {
      var players = [TournamentPlayer]()
      for entry in waitingListEntries {
         if let player = TournamentPlayer.player(licence: entry.licence) {
            players.append(player)
         }
      }
      return players
   }
   
   override func viewDidAppear() {
      registeredBrowser.setWidth(200.0, ofColumn: 0)
      presentBrowser.setWidth(300.0, ofColumn: 0)
      presentBrowser.setDefaultColumnWidth(300.0)
      presentBrowser.columnResizingType = .noColumnResizing
      maxCounters.intValue = 2
      nextCounter.intValue = 1
      
      // weird that this will work reliably, but _only_ if the name set is _differentt_ from IB.
      view.window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "Attendence Window"))
      paymentReceiptWindowController.window?.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "Payment Receipt Window"))
      readPaymentAndAttending()
   }
   
   func readPaymentAndAttending() {
      let paymentMap = TourPayment.all()
      if paymentMap.count > 0 {
         let alert=NSAlert()
         alert.informativeText = §.paymentsAvailable
         alert.addButton(withTitle: §.use)
         alert.addButton(withTitle: §.delete)
         alert.beginSheetModal(for: view.window!) { returnCode in
            if returnCode == .alertFirstButtonReturn {
               paymentMap.forEach { (licence, payment) in
                  if let tourPlayer = self.registeredPlayers[licence] {
                     tourPlayer.tourPayment = payment
                     alert.messageText = §.caution
                  }
               }
            } else {
               TourPayment.deleteAll()
            }
            self.readAttending()
         }
      }
   }
   
   func readAttending() {
      attendingMap = PresentEntry.all(for: series)
      if attendingMap.count > 0 {
         let alert = NSAlert()
         alert.messageText = §.caution
         alert.informativeText = §.attendingPlayersAvailable
         alert.addButton(withTitle: §.use)
         alert.addButton(withTitle: §.delete)
         alert.beginSheetModal(for: view.window!) { returnCode in
            if returnCode == .alertFirstButtonReturn {
               self.moveAllPlayers(from: self.attendingMap)
            } else {
               PresentEntry.deleteAll(for: self.series)
            }
         }
      }
   }
   
   func moveAllPlayers(from presentMap: [Int:PresentEntry]) {
      for (licence, entry) in presentMap {
         if let tourPlayer = registeredPlayers.removeValue(forKey: licence) {
            tourPlayer.present = entry
            attendingPlayers.append(tourPlayer)
         }
      }
      
      shownPlayers = Array(registeredPlayers.values)
      reloadBrowsers()
   }
   
   @IBAction func search(_ sender:NSSearchField) {
      shownPlayers = filterRegisteredPlayers(matching: sender.stringValue)
      reloadBrowsers()
   }
   
   func filterRegisteredPlayers(matching namePattern: String) -> [TournamentPlayer] {
      if namePattern.count > 0 {
         let pattern = ".*\(namePattern).*"
         let regex = try! NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
         var filteredPlayers = [TournamentPlayer]()
         for regPlayer in registeredPlayers.values {
            let fullName = regPlayer.nameClubPoints
            let nameRange = NSRange(fullName.startIndex..<fullName.endIndex, in: fullName)
            if (regex.firstMatch(in: fullName, options: [], range: nameRange) != nil) {
               filteredPlayers.append(regPlayer)
            }
         }
         return filteredPlayers
      } else {
         return Array(registeredPlayers.values)
      }
   }
   
   func reloadBrowsers() {
      shownPlayers.sort{pl1, pl2 -> Bool in pl1.nameClubPoints < pl2.nameClubPoints}
      attendingPlayers.sort{pl1, pl2 -> Bool in pl1.nameClubPoints < pl2.nameClubPoints}
      waitingListEntries.sort{we1, we2 -> Bool in we1.createdAt < we2.createdAt}
      registeredBrowser.loadColumnZero()
      presentBrowser.loadColumnZero()
      waitingListBrowser.loadColumnZero()
      registeredCount.stringValue = "\(shownPlayers.count)/\(registeredPlayers.count)"
      presentCount.integerValue = attendingPlayers.count
      
      // after a reload there will be no selection
      fixAvailableActionsRegistered(registeredBrowser)
      fixAvailableActionsPresent(presentBrowser)
      fixAvailableActionsWaiting(waitingListBrowser)
   }
   
   @IBAction func moveToPresent(_ sender: Any) {
      let selRow = registeredBrowser.selectedRow(inColumn: 0)
      if selRow >= 0 {
         let selPlayer = shownPlayers[selRow]
         if let playerToMove = registeredPlayers.removeValue(forKey: selPlayer.player.licence()) {
            addAttendingWithReceipt(playerToMove)
         }
         search(searchField)
      }
   }
   
   @IBAction func moveToRegistered(_ sender: Any) {
      let selRow = presentBrowser.selectedRow(inColumn: 0)
      let player = attendingPlayers.remove(at: selRow)
      player.present?.remove()
      registeredPlayers[player.player.licence()] = player
      
      search(searchField)
   }
   
   @IBAction func moveWaitingToPresent(_ sender: Any) {
      let selRow = waitingListBrowser.selectedRow(inColumn: 0)
      if selRow >= 0 {
         let waitingEntry = waitingListEntries.remove(at: selRow)
         if let singlPlayer = waitingEntry.player {
            let playSer = PlaySeries()!
            playSer.setPass(singlPlayer.licence())
            playSer.setSeries(series.seriesName())
            playSer.storeInDatabase()
            waitingEntry.remove()
            addAttendingWithReceipt(TournamentPlayer(player: singlPlayer))
         }
         reloadBrowsers()
      }
   }
   
   func addAttendingWithReceipt(_ playerToMove: TournamentPlayer) {
      attendingPlayers.append(playerToMove)
      if !playerToMove.hasPaidForTournament {
         playerToMove.fetchSeries()
         printReceipt(for: playerToMove)
         let attendingEntry = PresentEntry()
         attendingEntry.licence = playerToMove.player.licence()
         attendingEntry.tournamentId = TournamentDelegate.shared.tournament()!.id
         attendingEntry.series = series.seriesName()!
         attendingEntry.add()
      }
      
   }
   
   @IBAction func deleteWaitingEntry(_ sender: Any) {
      let selRow = waitingListBrowser.selectedRow(inColumn: 0)
      let idx : Int
      if selRow >= 0 {
         idx = selRow
      } else {
         idx = 0
      }
      let waitingEntry = waitingListEntries.remove(at: idx)
      waitingEntry.remove()
      reloadBrowsers()
   }
   
   @IBAction func deleteRegistration(_ sender: Any) {
      let selRow = registeredBrowser.selectedRow(inColumn: 0)
      if selRow >= 0 {
         let player = shownPlayers[selRow]
         registeredPlayers.removeValue(forKey: player.player.licence())
         if let playSer = PlaySeries() {
            playSer.setSeries(series.seriesName())
            playSer.setPass(player.player.licence())
            playSer.forceDelete()
         }
      }
      search(searchField)
   }
   
   //* cycle through the counters for payment
   func printReceipt(for player: TournamentPlayer) {
      NSLog("printing for %@", player.longName)
      paymentReceiptController.printReceipt(for: player, at: nextCounter.intValue)
      advanceCounter()
      paymentReceiptWindowController.showWindow(self)
      paymentReceiptController.print(self)
      let payment = TourPayment(player: player.player)
      payment.add()
      player.tourPayment = payment
      self.view.window?.makeKeyAndOrderFront(self)
      searchField.becomeFirstResponder()
   }
   
   func advanceCounter() {
      let max = maxCounters.intValue
      let next = nextCounter.intValue%max + 1
      
      nextCounter.intValue = next
   }
}

extension AttendanceController : NSBrowserDelegate {
   public func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
      if browser == registeredBrowser {
         return shownPlayers.count
      } else if browser == presentBrowser {
         return attendingPlayers.count
      } else if browser == waitingListBrowser {
         return waitingListEntries.count
      } else {
         return 0
      }
   }
   
   func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
      if item == nil {
         if browser == registeredBrowser {
            if index < shownPlayers.count {
               return shownPlayers[index]
            }
         } else if browser == presentBrowser {
            if index < attendingPlayers.count {
               return attendingPlayers[index]
            }
         } else if browser == waitingListBrowser {
            if index < waitingListEntries.count {
               return waitingListEntries[index]
            }
         }
      }
      return "unknown \(index)"
   }
   
   public func browser(_ sender: NSBrowser, numberOfRowsInColumn column: Int) -> Int {
      if column == 0 {
         return 11
      } else {
         return 0
      }
   }
   
   func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
      return item != nil;
   }
   
   static let greenAttributes : [NSAttributedStringKey : Any] = [.foregroundColor: NSColor.green]
   
   func browser(_ browser:NSBrowser, objectValueForItem item:Any?) -> Any? {
      if let player = item as? TournamentPlayer {
         if player.hasPaidForTournament {
            return NSAttributedString(string: player.nameClubPoints, attributes:AttendanceController.greenAttributes)
         } else {
            return player.nameClubPoints
         }
      } else if let entry = item as? WaitingListEntry {
         return entry.representation
      }
      return "something   ";
   }
   
   func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
      if let cell = cell as? NSBrowserCell {
         cell.stringValue = "hello"
      }
   }
   
   @IBAction func fixAvailableActionsRegistered(_ sender: NSBrowser) {
      let isRowSelected = sender.selectedRow(inColumn: 0) >= 0
      moveToPresentButton.isEnabled = isRowSelected
      deleteRegistrationButton.isEnabled = isRowSelected
   }
   
   @IBAction func fixAvailableActionsPresent(_ sender: NSBrowser) {
      let isRowSelected = sender.selectedRow(inColumn: 0) >= 0
      moveToRegisteredButton.isEnabled = isRowSelected
   }
   
   @IBAction func fixAvailableActionsWaiting(_ sender: NSBrowser) {
      let isRowSelected = sender.selectedRow(inColumn: 0) >= 0
      moveWaitingToPresentButton.isEnabled = isRowSelected
      deleteWaitingButton.isEnabled = isRowSelected
   }
}

