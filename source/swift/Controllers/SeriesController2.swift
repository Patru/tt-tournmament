//
//  SeriesController2.swift
//  Tournament
//
//  Created by Paul Trunz on 25.12.19.
//

import Cocoa

class SeriesController2 : NSViewController {
   @IBOutlet var seriesWindow: NSWindow!
   @IBOutlet weak var seriesBrowser: NSBrowser!
   @IBOutlet weak var seriesGroup: NSPopUpButton!
      
   var allSeries = [Series]()
   var shownSeries = [Series]()
   // the rest of the old instance variable is consciously omitted
   
    private(set) lazy var positionsWindowController : NSWindowController = {
        TournamentDelegate.shared.seriesStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "PositionsWindowController")) as! NSWindowController
    }()
    
    private(set) lazy var positionsPanelController : PositionsPanelController = {
        positionsWindowController.window?.contentViewController as! PositionsPanelController
    }()
    
    private(set) lazy var attendanceWindowController : NSWindowController = {
        TournamentDelegate.shared.seriesStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "AttendanceWindowController")) as! NSWindowController
    }()
    
    private(set) lazy var attendanceController : AttendanceController = {
        attendanceWindowController.window?.contentViewController as! AttendanceController
    }()
    
   @IBAction func displaySeriesDraw(_ sender: Any) {
      if let selectedSeries = selectedSeries() {
         if selectedSeries.alreadyDrawn() {
            TournamentDelegate.shared.tournamentViewController.setSeries(selectedSeries)
         } else {
            let alert = NSAlert()
            alert.messageText = §.caution
            alert.informativeText = String(format:§.seriesNotDrawnYet, selectedSeries.fullName())
            alert.addButton(withTitle: §.oohh)
            alert.addButton(withTitle: §.showAnyways)
            
            alert.beginSheetModal(for: seriesWindow) { returnCode in
               if returnCode == .alertFirstButtonReturn {
                  return
               }
            }
         }
      } else {
         keineSerieGewaehlt()
      }
   }
   
   func keineSerieGewaehlt() {
      let alert = NSAlert()
      alert.messageText = §.error
      alert.informativeText = §.noSeriesChosen
      alert.addButton(withTitle: §.abort)
      alert.beginSheetModal(for: seriesWindow, completionHandler: nil)
   }
   
   func selectedSeries() -> Series? {
      if let selectedCell = seriesBrowser.selectedCell() as? SeriesBrowserCell {
         return selectedCell.series()
      }
      return nil
   }
   
   @IBAction func show(_ sender: Any) {
      seriesWindow.makeKeyAndOrderFront(self)
      if allSeries.count == 0 {
         loadSeriesData()
      }
      seriesBrowser.loadColumnZero()
   } //
   
   override func viewWillAppear() {
      seriesWindow = self.view.window!
      // strange that we have to do this in a view delegate, somehow the IB-settings get "overwritten"
      seriesWindow.setFrameAutosaveName(NSWindow.FrameAutosaveName(rawValue: "SeriesWindow"))

      if allSeries.count == 0 {
         loadSeriesData()
      }
      
      seriesBrowser.loadColumnZero()
   }
   
   @IBAction func performSeriesDraw(_ sender: Any) {
      if let selected = seriesBrowser.selectedCell() as? SeriesBrowserCell {
         let selRow = seriesBrowser.selectedRow(inColumn: 0)
         selected.series().doDraw()
         DispatchQueue.main.async {
            self.selectGroup(self.seriesGroup)       // make sure the series list gets updated properly
            self.seriesBrowser.selectRow(selRow, inColumn: 0)
            self.seriesBrowser.display()
         }
      } else {
         let alert = NSAlert()
         alert.messageText = §.drawAllSeries
         alert.informativeText = §.shouldAllSeriesBeDrawn
         alert.addButton(withTitle: §.yes)
         alert.addButton(withTitle: §.no)
         alert.beginSheetModal(for: seriesWindow)   { returnCode in
            if returnCode == .alertFirstButtonReturn {
               DispatchQueue.main.async {
                  for series in self.shownSeries {
                     series.doDraw()
                  }
                  // do we really need this (anymore?): self.seriesBrowser.loadColumnZero()
                  self.seriesBrowser.display()
               }
            }
         }
      }
   }
   
   @IBAction func start(_ sender: NSButton ) {
      let delegate = TournamentDelegate.shared
      if let selectedSeries = selectedSeries() {
         if selectedSeries.alreadyDrawn() {
            if !selectedSeries.started() {
               selectedSeries.printWONPPlayers(into: delegate.smallTextController)
               delegate.showSmallText()
               let alert = NSAlert()
               alert.informativeText = §.checkedAllWalkOverPlayers
               alert.addButton(withTitle: §.yesStartNow)
               alert.addButton(withTitle: §.noWaitSomeMore)
               alert.beginSheetModal(for: seriesWindow)  { returnCode in
                  if returnCode == .alertFirstButtonReturn  {
                     DispatchQueue.main.async {
                        selectedSeries.start()
                        delegate.matchController?.saveDocument(self)
                        self.seriesBrowser.display()
                     }
                  }
               }
            } else {
               let alert = NSAlert()
               alert.informativeText = §.seriesAlreadyStarted
               alert.addButton(withTitle: §.abort)
               alert.beginSheetModal(for: seriesWindow, completionHandler: nil)
            }
         } else {
            notDrawnYet(selectedSeries)
         }
      }
   }
   
   @IBAction func rankingList(_ sender: NSButton ) {
      let delegate = TournamentDelegate.shared
      if let selectedSeries = selectedSeries() {
         if selectedSeries.finished() {
            selectedSeries.textRankingList(in: delegate.smallTextController)
            delegate.showSmallText()
         } else {
            let alert = NSAlert()
            alert.messageText = §.error
            alert.informativeText = §.seriesNotFinishedYet
            alert.addButton(withTitle: §.abort)
            alert.beginSheetModal(for: seriesWindow, completionHandler: nil)
         }
      } else {
         keineSerieGewaehlt()
      }
   }
   
   @IBAction func clubScore(_ sender: NSPopUpButton ) {
      let tourDelegate = TournamentDelegate.shared
      let evaluator : ClubEvaluator
      switch sender.selectedTag() {
      case 0: evaluator = ZkmClubsEvaluator()
      case 1: evaluator = BerbierPokalEvaluator()
      default: evaluator = WinnerPointsEvaluator(title:"Club points")
      }
      evaluateAllSeriesWith(evaluator: evaluator)
      evaluator.showResult(in: tourDelegate.smallTextController, withDetails: tourDelegate.preferences().groupDetails)
      tourDelegate.showSmallText()
   }
   
   func evaluateAllSeriesWith(evaluator: ClubEvaluator) {
      for series in shownSeries {
         evaluator.evaluate(for: series)
      }
   }
   
   @IBAction func selectSeries(_ sender : NSBrowser) {
      if let selCell = sender.selectedCell() as? SeriesBrowserCell {
         TournamentDelegate.shared.tournamentInspector.inspect(selCell.series())
      }
   }
   
   func notDrawnYet(_ series:Series) {
      let alert = NSAlert()
      alert.messageText = §.error
      alert.informativeText = String(format:§.seriesNotDrawnYet, series.fullName())
      alert.addButton(withTitle: §.abort)
      alert.addButton(withTitle: §.drawContinuously)
      alert.beginSheetModal(for: seriesWindow) { returnCode in
         if .alertSecondButtonReturn == returnCode {     // first button cancels, so we ignore itt
            DispatchQueue.main.async {
               series.start()
               self.seriesBrowser.display()
            }
         }
      }
   }
   
   @IBAction func selectGroup(_ sender: NSPopUpButton) {
      let index = sender.indexOfSelectedItem
      if index == 0 {
         shownSeries = allSeries
      } else {
         if let selGroup = sender.selectedItem?.title {
            shownSeries = allSeries.filter {series in
               series.grouping() == selGroup
            }
         }
      }
      seriesBrowser.loadColumnZero()
   }
   
   func loadSeriesData() {
      guard let database=TournamentDelegate.shared.database() else {return}
      let selectAllForTournmaent = String(format:"SELECT %@ FROM Series WHERE TournamentID = '%@' ORDER BY StartTime", Series.allFields(), TournamentDelegate.shared.preferences().tournamentId)
      if let rs = database.open(selectAllForTournmaent) as? PGSQLRecordset {
         var rec = rs.moveFirst()
         while let record = rec {
            self.add(series: self.makeSeriesFrom(record))
            rec = rs.moveNext()
         }
         determinePresentGroupings()
         shownSeries = allSeries
      }
   }
   
   @objc func add(series: Series) {
      if let idx = allSeries.index(where: {ser in ser.startTime() > series.startTime()}) {
         allSeries.insert(series, at: idx)
      } else {
         allSeries.append(series)
      }
   }
   
   @objc func remove(series:Series) {
      if let i = allSeries.index(of:series) {
         allSeries.remove(at: i)
      }
   }
   
   // eliminate the map, too much effort for very little usage
   @objc func seriesWith(name: String) -> Series? {
      for series in allSeries {
         if series.seriesName() == name {
            return series
         }
      }
      return nil
   }
   
   @objc func allContinuouslyDrawableSeries() -> [Series] {
      return allSeries.filter { series in
         series.responds(to: #selector(GroupSeries.addGroup(forPlayers:)))
            && series.responds(to: #selector(GroupSeries.drawFromGroups))
      }
   }
   
   
   func determinePresentGroupings() {
      while seriesGroup.numberOfItems > 1 {
         seriesGroup.removeItem(at:1)
      }
      
      var groupings = [String]()
      for series in allSeries{
         let grouping = series.grouping()!
         if grouping.count > 0 && !groupings.contains(grouping){
            groupings.append(grouping)
         }
      }
      seriesGroup.addItems(withTitles: groupings)
   }
   
   func makeSeriesFrom(_ record: PGSQLRecord) -> Series {
      let typeField = SerFields.Type.takeUnretainedValue() as String
      let type = record.field(byName:typeField).asString()!;
      
      switch type.uppercased() {
      case "D":
         return DoubleSeries(from:record)
      case "E":
         return EloSeries(from:record)
      case "F":
         return Elo18Series(from:record)
      case "G":
         return GroupSeries(from:record)
      case "L":
         return DoubleGroupSeries(from:record)
      case "M":
         return MixedGroupSeries(from:record)
      case "O":
         return Series(from:record)
      case "P":
         return Elo12PlusSeries(from:record)
      case "Q":
         return RLQualiSeries(from:record)
      case "R":
         return RaiseGroupSeries(from:record)
      case "S":
         return SimpleGroupSeries(from:record)
      case "T":
         return ConsolationGroupSeries(from:record)
      case "U":
         return ConsolationGroupedSeries(from:record)
      case "V":
         return Elo14Series(from:record)
      case "W":
         return RLQualiDamenSeries(from:record)
      case "X":
         return MixedSeries(from:record)
      default:
         return Series(from:record)
      }
   }
   
   @IBAction func printAllSeries(_ sender: Any) {
      let alert = NSAlert()
      alert.messageText = §.printAllSeries
      alert.informativeText = §.printWhichSeries
      alert.addButton(withTitle: §.all)
      alert.addButton(withTitle: §.onlyRunning)
      alert.addButton(withTitle: §.abort)
      alert.beginSheetModal(for: seriesWindow) { (returnCode) in
         if returnCode == .alertThirdButtonReturn { return }
         let printAll = returnCode == .alertFirstButtonReturn
         for series in self.shownSeries {
            if printAll || (series.started() && !series.finished()) {
               TournamentDelegate.shared.tournamentViewController.printSensiblePages(of: series)
            }
         }
      }
   }
   
   @objc func checkFinished(series:Series) {
      if series.finished() {
         let alert = NSAlert()
         alert.messageText = §.seriesFinished
         alert.informativeText = String(format:§.lastMatchPlayed, series.fullName())
         alert.addButton(withTitle: §.printRankinglist)
         alert.addButton(withTitle: §.rememberThisIWill)
         
         alert.beginSheetModal(for: seriesWindow) { returnCode in
            if returnCode == .alertFirstButtonReturn {
               let tourDelegate = TournamentDelegate.shared
               series.textRankingList(in: tourDelegate.smallTextController)
               tourDelegate.showSmallText()
               // TODO: We might initiate direct printing here
            }
         }
      }
   }
   
   @IBAction func showPositions(_ sender : Any) {
      if let selSeries = selectedSeries() {
         if selSeries.alreadyDrawn() {
            if !selSeries.started() {
               // posA.selectTText
               positionsPanelController.showModal(for:seriesWindow, with:selSeries)
//               if let win = positionsWindowController.window {
//                  seriesWindow.beginSheet(win, completionHandler: { (response) in
//                     if response == NSApplication.ModalResponse.stop {
//
//                     }
//                  })
//               }
            } else {
               let alert = NSAlert()
               alert.messageText = §.caution
               alert.informativeText = §.seriesAlreadyStartedNoFurtherChanges
               alert.addButton(withTitle: §.ok)
               alert.beginSheetModal(for: seriesWindow, completionHandler: nil)
            }
         } else {
            notDrawnYet(selSeries)
         }
      } else {
         keineSerieGewaehlt()
      }
   }
   
   @IBAction func showAttendance(_ sender : Any) {
      if shownSeries.count > 0 {
         attendanceController.series = shownSeries[0]
         attendanceWindowController.window?.makeKeyAndOrderFront(self)
      }
   }
   
   @objc func listsForDraw() -> NSAttributedString {
      let tabStops = [NSTextTab(textAlignment: .left, location: 153.0),
                      NSTextTab(textAlignment: .right, location: 303.0),
                      NSTextTab(textAlignment: .right, location: 333.0),
                      NSTextTab(textAlignment: .right, location: 383.0),
                      NSTextTab(textAlignment: .right, location: 423.0)]
      let textStyle = NSMutableParagraphStyle()
      textStyle.tabStops = tabStops
      let textAttributes: [NSAttributedStringKey: Any] = [.font: NSFont(name:"Helvetica", size:12.0)!,
                                                          NSAttributedStringKey.paragraphStyle:textStyle]
      let titleAtttribbutes: [NSAttributedStringKey: Any] = [.font: NSFont(name:"Helvetica-Bold", size:12.0)!]
      
      var buf = NSMutableAttributedString()
      buf.beginEditing()
      for series in allSeries {
         let titleLine = NSAttributedString(string: "\(series.fullName)\n", attributes: titleAtttribbutes)
         buf.append(titleLine)
         
         series.loadPlayersFromDatabase()
         if let seriesPlayers = series.players() as? [SeriesPlayer] {
            for serPlayer in seriesPlayers {
               let player = serPlayer.player()!
               let elo : Int
               if let singlPlayer = player as? SinglePlayer {
                  elo = singlPlayer.elo()
               } else {
                  elo = 0
               }
               let line = String(format: "%@\t%@\t%ld\t%ld\t%ld\n", player.longName(), player.club(), player.ranking(in: series),
                                 serPlayer.setNumber(), elo)
               let attrLine = NSAttributedString(string: line, attributes: textAttributes)
               buf.append(attrLine)
            }
         }
      }
      buf.endEditing()
      
      return buf
   }
   
   func seriesGrouping() -> String? {
      if seriesGroup.indexOfSelectedItem == 0 {
         return ""
      } else {
         return seriesGroup.titleOfSelectedItem
      }
   }
   
   func setSeriesGrouping(_ grouping:String) {
      if grouping.count == 0 {
         seriesGroup.selectItem(at: 0)
      } else {
         seriesGroup.selectItem(withTitle: grouping)
      }
   }
   
   @objc func appendFinishedSeries(to text:NSMutableString) {
      for series in allSeries {
         if series.finished() {
            series.appendAsXml(to: text)
         }
      }
   }
   
   func alreadyHas(_ series : Series) -> Bool {
      return allSeries.contains(series)
   }
   
   @objc func loadAdditionalSeries(_ sender: Any) {
      let tourDelegate = TournamentDelegate.shared
      if let database = tourDelegate.databse {
         let selectAll = String(format:"SELECT %@ FROM Series WHERE TournamentID = '%@' ORDER BY FullName", Series.allFields(), tourDelegate.preferences().tournamentId)
         if let rs = database.open(selectAll) as? PGSQLRecordset {
            var rec = rs.moveFirst()
            while let record = rec {
               let ser = makeSeriesFrom(record)
               if !alreadyHas(ser) {
                  add(series: ser)
               }
               rec = rs.moveNext()
            }
            determinePresentGroupings()
         }
      }
   }
   
   @IBAction func allMatchSheets(_ sender : Any) {
      if let selectedSeries = selectedSeries() {
         if selectedSeries.alreadyDrawn() {
            selectedSeries.allMatchSheets(sender)
         } else {
            notDrawnYet(selectedSeries)
         }
      }
   }
   
}

extension SeriesController2 : NSBrowserDelegate {
   
   func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
      if item == nil {
        if index < shownSeries.count {
            return shownSeries[index]
        } else {
            return "unknown"
        }
      } else {
         if let seris = item as? Series {
            return "huh, really the series?? (\(seris.seriesName))"
         } else {
            return "unknown"
         }
      }
   }
   
   func browser(_ browser: NSBrowser, isLeafItem item: Any?) -> Bool {
      return item != nil;
   }
   
   func browser(_ browser: NSBrowser, numberOfChildrenOfItem item: Any?) -> Int {
      if item == nil {
         if !(browser.cellPrototype is SeriesBrowserCell) {
            browser.setCellClass(SeriesBrowserCell.self)
         }
         if allSeries.count == 0 {
            loadSeriesData()
         }
         if shownSeries.count == 0 {
            shownSeries = allSeries
         }
         return shownSeries.count
      } else {
         return 0
      }
   }
   
   func browser(_ browser:NSBrowser, objectValueForItem item:Any?) -> Any? {
      if let seris = item as? Series {
         return seris.seriesName
      }
      return "unknown";
   }
   
   func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
      if let seriesCell = cell as? SeriesBrowserCell {
         let seris = self.shownSeries[row]
         seriesCell.setSeries(seris)
      } else if let aCell = cell as? NSCell {
         print(aCell.type)
      }
   }
   
   @IBAction func saveSeriesAsPDF(_ sender:Any) {
      let tourDelegate = TournamentDelegate.shared
      let openPanel = NSOpenPanel()
      openPanel.canChooseDirectories = true
      openPanel.canChooseFiles = false
      if openPanel.runModal() == .OK {
         if let dir = openPanel.directoryURL {
            for series in shownSeries {
               if series.alreadyDrawn() {
                  TournamentDelegate.shared.tournamentViewController.saveSeries(series, asPDFToDirectory: dir)
               }
            }
            if let uploadScript = tourDelegate.tournament()?.upload {
               if uploadScript.count > 0 {
                  let task = Process()
                  task.currentDirectoryPath = dir.path
                  task.launchPath = uploadScript
                  task.launch()
                  // currentDirectoryPath, launchPath and launch will be deprecated starting 10.13,
                  // but we currently want to support 10.12 too
                  // system(command.utf8String)
               }
            }
         }
      }
   }
}

