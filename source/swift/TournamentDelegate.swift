//
//  TournamentDelegate.swift
//  Tournament
//
//  Created by Paul Trunz on 24.05.17.
//
//

import Foundation
import Cocoa

class TournamentDelegate: NSObject, NSApplicationDelegate {
   @objc static var shared : TournamentDelegate { get {
      return NSApplication.shared.delegate as! TournamentDelegate
      }
   }
   
   var logHandle : FileHandle?
   var databse : PGSQLConnection?
   @objc lazy var matchResultController : MatchResultController = {
      let aMatchResultController = MatchResultController()
      Bundle.main.loadNibNamed(NSNib.Name(rawValue: "MatchResult"), owner:aMatchResultController, topLevelObjects: nil)
      
      return aMatchResultController
   }()
//   @objc private(set) lazy var seriesController = SeriesController()
    @objc private(set) lazy var seriesController = {
        return seriesWindowController.contentViewController as! SeriesController2
    }()
    
    private(set) lazy var seriesWindowController : NSWindowController = {
        seriesStoryboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Series Window Controller")) as! NSWindowController
    }()
    
   private var _lastNumberedMatch : Int = 0
   private var allMatches = [Int:Playable]()
   @objc private(set) lazy var matchViewController : MatchViewController = {
      var matchViewCont = MatchViewController()
      Bundle.main.loadNibNamed(NSNib.Name(rawValue: "MatchView"), owner: matchViewCont, topLevelObjects: nil)
      return matchViewCont
   }()
   @objc private(set) lazy var tournamentViewController : TournamentViewController = {return TournamentViewController()}()
   @objc private(set) lazy var smallTextController : SmallTextController = {
      let aSmallTextController = SmallTextController();
      Bundle.main.loadNibNamed(NSNib.Name(rawValue: "SmallText"), owner: aSmallTextController, topLevelObjects: nil);
      return aSmallTextController!
   }()
   @objc private(set) lazy var notPresentController : NotPresentController = {
      let aNotPresentController = NotPresentController()
      Bundle.main.loadNibNamed(NSNib.Name(rawValue: "NotPresent"), owner: aNotPresentController, topLevelObjects: nil)
      aNotPresentController.setBrowserTitles()
      
      return aNotPresentController
   }()
   @objc private(set) lazy var tournamentInspector = {
      return TournamentInspectorController()
   }()
   private(set) lazy var inputController = {
      return InputController()!
   }()
   @objc var playerController : PlayerController { get {return inputController.playerController()! } }
   @objc var seriesDataController : SeriesDataController { get {return inputController.seriesController()! } }
   private(set) lazy var groupMakerController = {
      return GroupMakerController()!
   }()
   @objc var matchController : TournamentController?
   @objc private(set) lazy var groupResult : GroupResult = {
      let aGroupResult = GroupResult()
      Bundle.main.loadNibNamed(NSNib.Name(rawValue: "GroupResult"), owner:aGroupResult, topLevelObjects: nil)
      return aGroupResult
   }()
   private(set) lazy var paymentController = PaymentViewController()!
   private(set) lazy var startingListController = StartingListController()!
   @objc func tournament() -> Tournament? {
      if tournamentData.tournament == nil || preferences().tournamentId != tournamentData.tournament?.id {
         tournamentData.fetchConfiguredTournament()
      }
      return tournamentData.tournament
   }
   @objc private(set) lazy var clickTtFormat : DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      return formatter
   }()
   
   @objc func rootList() -> [AnyObject] {
      let matches = NSMutableDictionary(dictionary: allMatches)
      // TODO: Weird, this used to be possible through a cast before ...
      return [playerController.value(forKey: "playersInTournament") as! NSObject,
              seriesController.allSeries as NSObject,
              matches,
              NSNumber(value:lastNumberedMatch()),
              matchController!.matchBrowser().matches(),
              
              seriesController.seriesGrouping()! as NSString,
              groupMakerController.confirmationState()! as NSArray
      ]
   }
   
   @objc func reset(from rootList: [AnyObject]) {
      playerController.setValue(rootList[0], forKey: "playersInTournament")
      seriesController.allSeries=rootList[1] as! [Series]
      seriesController.determinePresentGroupings()
//      seriesController.rebuildMap()
      allMatches = rootList[2] as! [Int:Playable]
      _lastNumberedMatch = (rootList[3] as! NSNumber).intValue
      matchController!.matchBrowser().setMatches(rootList[4] as! NSMutableArray)
      
      seriesController.setSeriesGrouping(rootList[5] as! String)
      groupMakerController.setConfirmationState(rootList[6] as! [Any])
   }

   @objc func clickTtDateStringForExport() -> String {
      return clickTtFormat.string(from: tournament()!.dateForExport)
   }
   
   @objc private(set) lazy var passwordController : PasswordController = {
      let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "Password"), bundle: nil)
      let pwWindow = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Password Window Controller")) as? NSWindowController
      let pwController = pwWindow?.contentViewController as? PasswordController

      return pwController!
   }()
   
   func applicationDidFinishLaunching(_ notification: Notification) {
      let logPath = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask)[0].appendingPathComponent("Turnier.log")
      if !FileManager.default.fileExists(atPath: logPath.path) {
         FileManager.default.createFile(atPath: logPath.path, contents: "".data(using: .utf8))
      }
      do {
         logHandle = try FileHandle(forWritingTo: logPath)
         NSLog("will now log at %@", logPath.path)
      } catch let error as NSError {
         NSLog("Can't open fileHandle \(error)")
      }
      updateDatabaseSchema()
   }
   
   func applicationWillTerminate(_ notification: Notification) {
      logHandle?.closeFile()
   }
   
   @objc func logLine(_ line: String) {
      logHandle?.seekToEndOfFile()
      logHandle?.write(line.data(using: .utf8)!)
   }
   
   func updateDatabaseSchema() {
      if let db  = database() {
         DBMigrations.apply(to: db)
      }
   }
   
   // we do not do this as a (lazy) property since it should keep trying if it does not work the first time.
   @objc func database() -> PGSQLConnection? {
      if (databse == nil) {
         let connectionString = String(format: "host=%@ port=%d dbname=%@ user=%@ password=%@", "localhost", 5433, "docker", "docker", "docker")
         databse = PGSQLConnection()
         databse?.setConnectionString(connectionString)
         if (databse?.connect())! {
            databse!.setDefaultEncoding(String.Encoding.utf8.rawValue)
            return databse;
         } else {
            if let message = databse?.errorDescription {
               if message.hasPrefix("could not connect to server: Connection refused") {
                  startDockerPostgreSQL()
                  reportDbError("trying to start docker container, keep your fingers crossed and try again in a few seconds")
               } else {
                  reportDbError(message)
               }
            }
            databse = nil
         }
      }
      return databse
   }
   
   func startDockerPostgreSQL() {
      DispatchQueue.global(qos: .background).async {
         let task = Process()
         task.launchPath = "/usr/local/bin/docker"
         task.arguments = ["run", "-p", "5433:5432", "-e", "POSTGRES_USER=docker", "-e", "POSTGRES_PASSWORD=docker", "-v", "/Users/Shared/postgres/data:/var/lib/postgresql/data", "postgres"]
         task.launch()
      }
   }
   
   @objc func lastNumberedMatch() -> Int {      // TODO: get rid of this (maybe should be get-property??
      return _lastNumberedMatch
   }
   
   @objc func number(_ aPlayable : Playable) {
      _lastNumberedMatch += 1
      aPlayable.setRNumber(_lastNumberedMatch)
      allMatches[_lastNumberedMatch] = aPlayable
   }
   
   @objc func playable(withNumber number:Int) -> Playable? {
      return allMatches[number]
   }

   @objc func findMatchWithSamePlayersAs(_ otherMatch:Match) -> Match? {
      for (_, playable) in allMatches {
         if let match = playable as? Match {
            if match.hasSamePlayers(as: otherMatch) {
               return match
            }
         }
      }
      return nil
   }

   @IBAction func downloadInscriptions(_ sender: Any) {
      InscriptionLoader.fetchAndReplaceInscriptions()
   }
   
   func deleteExternalPlayers(from: Int, to: Int) {
      let db = database()!;
      let deletePlayers = String(format:"DELETE FROM Player WHERE Licence >= %d AND Licence <= %d", from, to);
      
      let deleted = db.execCommand(deletePlayers)
      if deleted > 0 {
         print("\(deleted) players deleted")
      }
   }

    func deletePlaySeries(from: Int, to: Int) {
        guard let tourId = TournamentDelegate.shared.tournament()?.id
            else { return }
        let db = database()!;
        let deletePlayers = "DELETE FROM PlaySeries WHERE TournamentId = '\(tourId)' AND Licence >= \(from) AND Licence <= \(to)"
        
        let deleted = db.execCommand(deletePlayers)
        if deleted > 0 {
            print("\(deleted) entries deleted")
        }
    }

   @objc func importCsvPlayers(externalSource: URL) {
      let min = 1000
      let max = min+999

      deleteExternalPlayers(from: min, to: max)
      deletePlaySeries(from: min, to: max)
      do {
         let allLines = try String(contentsOf:externalSource, encoding: String.Encoding.utf8)
         var count = 0
         // we switch years after June, so this gets a little complicated
         let calendar = Calendar.current
         let yearMonth = calendar.dateComponents([.year, .month], from: Date())
         let year: Int
         if yearMonth.month! > 6 {
            year = yearMonth.year!+1
         } else {
            year = yearMonth.year!
        }
        
         let seriesMapping = [
            "\(year-15) - \(year-14)":"U15",
            "\(year-13) - \(year-12)":"U13",
            "\(year-11) - \(year-10)":"U11",
            "\(year-9) und jünger":"U9",
         ]
         allLines.enumerateLines { (line: String, stop: inout Bool) in
            if count > 0 {
                let elements = line.split(separator: "\t")
               if let player = SinglePlayer() {
                  player.setClub(String(elements[6]))
                  let ser = String(elements[5])
                  if let read_series = seriesMapping[ser] {
                     player.setCategory(read_series)
                  } else {
                     player.setCategory(ser)
                  }
                  player.setPName(String(elements[3]))
                  player.setFirstName(String(elements[2]).trimmingCharacters(in: .whitespaces))
                  if elements[1] == "Mädchen" {
                     player.setWomanRanking(1)
                  }
                  player.setRanking(1)
                  player.setLicence(min+count)
                  player.storeInDatabase()
                  
                  if let plSer = PlaySeries() {
                     plSer.setPass(player.licence())
                     let ser = player.sex()+player.category()
                     plSer.setSeries(ser)
                     plSer.storeInDatabase()
                  }
               }
            }
            count = count + 1
         }
      } catch {
         let alert = NSAlert()
         alert.alertStyle = .warning
         alert.messageText = "Could not load file";
         if let window = NSApp.mainWindow {
            alert.beginSheetModal(for: window, completionHandler: nil)
         } else {
            alert.runModal()     // no window on display as of yet
         }
      }
   }

   @objc func showSmallText() {
      smallTextController.showWindow(self)
   }
   
   @IBAction func showInspector(_ sender:NSMenuItem) {
      tournamentInspector.updateView(nil)
   }
   
   @IBAction func showNotPresentWindow(_ sender:Any?) {
      notPresentController.display()
   }
   
   @IBAction func showSeriesWindow(_ sender:Any?) {
      // seriesController.show(sender)
      seriesWindowController.showWindow(sender)
   }

   @IBAction func showPlayerWindow(_ sender:Any?) {
      playerController.showWindow(sender)
   }

   @IBAction func showSeriesDataWindow(_ sender:Any?) {
      seriesDataController.showWindow(sender)
   }
   
   @IBAction func showPreferencesPanel(_ sender:Any?) {
      preferencesWindowController.showWindow(sender);
   }
   
   @IBAction func showPaymentsWindow(_ sender:Any?) {
      paymentController.show(sender)
   }
   
   @IBAction func showStartingListWindow(_ sender:Any?) {
      startingListController.showWindow(sender)
   }
   
   @IBAction func showDrawingLists(_ sender:Any?) {
      startingListController.showDrawingLists(sender)
   }
   
   private(set) lazy var preferencesWindowController : NSWindowController = {
      let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "PreferencesW"), bundle: nil)
      let controller = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Pref Window Controller")) as! NSWindowController
      
//      if let preferenceController = (controller.window?.contentViewController) as? PreferencesController {
//         preferenceController.revert(self)
//      }
      return controller
   }()

    private(set) lazy var seriesStoryboard: NSStoryboard = {
        NSStoryboard(name: NSStoryboard.Name(rawValue: "Series"), bundle: nil)
    }()

   @objc func preferences() -> PreferencesViewController {
      return preferencesWindowController.contentViewController as! PreferencesViewController
   }
   
   @IBAction func showPreferencesWindow(_ sender:Any?) {
      preferencesWindowController.showWindow(sender)
   }
   
   private(set) lazy var tournamentDataWindow : NSWindowController = {
      let storyboard = NSStoryboard(name: NSStoryboard.Name(rawValue: "TournamentData"), bundle: nil)
      let controller = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "Tournament Data Window")) as! NSWindowController
      return controller
   }()
   
   private(set) lazy var tournamentData : TournamentDataController = {
      return self.tournamentDataWindow.contentViewController as! TournamentDataController
   }()
   
   @IBAction func showGroupMakerWindow(_ sender:Any?) {
      groupMakerController.show(sender)
   }

    public func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        if let window = matchController?.matchWindow() {
            let oldname = window.representedFilename
            if oldname != "" {
                let alert=NSAlert()
                alert.messageText = "Turnier öffnen?"
                alert.alertStyle = .warning
                alert.messageText="Vorsicht, das Turnier \(oldname) ist bereits am laufen. Soll \(filename) trotzdem geladen werden?"
                alert.addButton(withTitle: "Nein")
                alert.addButton(withTitle: "Ja")
                alert.beginSheetModal(for: window) { (result) in
                    if result == .alertFirstButtonReturn  {
                        return
                    } else {
                        DispatchQueue.main.async {
                            self.matchController?.openFile(filename)
                        }
                    }
                }
            } else {
                if let opened = matchController?.openFile(filename) {
                    return opened
                } else {
                    return false
                }
            }
        }
        return false
    }
   
   @objc public func reportDbError(_ message:String) {
      let alert = NSAlert()
      alert.messageText = "Database Error"
      alert.alertStyle = .warning
      alert.informativeText = message
      alert.addButton(withTitle: "OK")
      if let window = NSApp.mainWindow {
         alert.beginSheetModal(for: window, completionHandler: nil)
      } else {
         alert.runModal()     // no window on display as of yet
      }
   }
   
   // just for convenience, belongs to TournamentController and should be moved there once its Swift
   @IBAction func newTournmaent(_ sender: Any) {
      tournamentData.tournament = Tournament()
      tournamentData.Id.isEnabled = true
      tournamentDataWindow.window?.title = "New Tournament"
      tournamentDataWindow.showWindow(sender)
   }
   
   @IBAction func details(_ sender: Any) {
      tournamentData.fetchConfiguredTournament()
      if tournamentData.tournament != nil {
         tournamentDataWindow.window?.title = "Details"
         tournamentDataWindow.showWindow(sender)
      } 
   }
   
   @objc public func restoreInProgress() -> Bool {
      if let inProgress = matchController?.umpireController()?.restoreInProgress() {
         return inProgress
      } else {
         return false;
      }
   }
   
   lazy var StatisticsAttributes : [NSAttributedStringKey : Any] = {
      let tabStops = [NSTextTab(textAlignment:.right, location:100.0)]
      let textStyle = NSMutableParagraphStyle()
      textStyle.tabStops=tabStops
      let attributes : [NSAttributedStringKey : Any] = [.font : NSFont(name: "Helvetica", size:12.0)!,
                                                        .paragraphStyle: textStyle]
      return attributes;
   }()
   
   @IBAction func showMatchesWindow(_ sender:Any) {
      matchController?.matchWindow().makeKeyAndOrderFront(sender)
   }
   
   @IBAction func statistics(_ sender:Any) {
      let text = smallTextController
      text.clearText()
      text.setTitleText("Statistik\n")     // TODO: internationalize
      text.appendText("Geschlecht\n")
      
      let db = database()
      let sqlString = String(format: "SELECT CASE WHEN WomanRanking=0 THEN 'Herren' ELSE 'Damen' END Sex, Count(DISTINCT p.Licence) FROM PlaySeries ps JOIN Player p USING (Licence) WHERE TournamentId = '%@' and ps.series <> 'NiLi' GROUP BY Sex", preferences().tournamentId)
      
      if let rs = db?.open(sqlString) {
         while !rs.isEOF {
            if let sex = rs.field(by: 0).asString() {
               let number = rs.field(by: 1).asLong()
               text.appendAttributed(NSAttributedString(string: String(format: "%@\t%d\n", sex, number), attributes: StatisticsAttributes))
            }
            rs.moveNext()
         }
      }
      
      let categorySql = String(format: "SELECT Category, count(DISTINCT p.Licence) Anzahl FROM PlaySeries ps, Player p WHERE p.Licence = ps.Licence AND TournamentId = '%@' and ps.series <> 'NiLi' GROUP BY Category ORDER BY Category", preferences().tournamentId)
      text.appendText("\nKategorie\n")     // TODO: internationalize
      if let rs = db?.open(categorySql) {
         while !rs.isEOF {
            if let category = rs.field(by: 0).asString() {
               let number = rs.field(by: 1).asLong()
               text.appendAttributed(NSAttributedString(string: String(format: "%@\t%d\n", category, number), attributes: StatisticsAttributes))
            }
            rs.moveNext()
         }
      }

      smallTextController.showWindow(self)
   }
    
    @objc func names(matching fragment:String) -> [String] {
        var names = [String]()
        if let players = playerController.players(matching:fragment) {
            for player in players {
                names.append(player.longName())
            }
        }
        return names
    }
    
    @IBAction func exportDrawnSeries(_ sender:Any) {
        let savePanel = NSSavePanel()
        
        savePanel.allowedFileTypes = ["csv"]
        savePanel.message = "Store players in drawn series"
        savePanel.nameFieldStringValue = "SerienSpieler.csv"
        savePanel.directoryURL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory:true)
        
        savePanel.beginSheetModal(for: (matchController?.matchWindow())!) { (result) in
            if result == NSApplication.ModalResponse.OK {
                if let url = savePanel.url {
                    self.storeDrawnPlayers(to:url)
                }
            }
        }
    }
    
    func storeDrawnPlayers(to file:URL) {
        if let series = seriesController.allSeries as? [Series] {
            var drawnPlayers = ""
            for ser in series {
                if let players = ser.players() as? [SeriesPlayer] {
                    for serPl in players {
                        if let player = serPl.player() {
                            let line = ["\(player.licence())", player.longName(), ser.seriesName()].joined(separator: "\t")
                            drawnPlayers.append(line)
                            drawnPlayers.append("\n")
                        }
                    }
                }
            }
            do {
                try drawnPlayers.write(to: file, atomically: false, encoding: .utf8)
            } catch {
                print(error)
            }
        }
    }
}
