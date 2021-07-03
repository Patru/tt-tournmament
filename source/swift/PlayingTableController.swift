//
//  PlayingTableController.swift
//  Tournament
//
//  Created by Paul Trunz on 11.07.17.
//
//

import Foundation

class PlayingTableController: NSObject {
   @IBOutlet var tableWindow: NSWindow!      // this will loose the window if weak??!! 
   @IBOutlet weak var playingTableBrowser: NSBrowser!
   @objc dynamic var freeTables = [PlayingTable]()
   @objc dynamic var playingTable: PlayingTable?
   var allTables = [Int : PlayingTable]()
   
   @IBAction func newTable(_ sender: Any) {
    let database=TournamentDelegate.shared.database()!
    guard let tourId = TournamentDelegate.shared.tournament()?.id
         else { return }
      let maxSql = String(format: "SELECT MAX(Number) FROM TourTable WHERE TournamentID ='%@'", tourId)
      let maxTableNumber : Int
      if let rs = database.open(maxSql) as? PGSQLRecordset {
         maxTableNumber = rs.field(by:0).asLong()
      } else {
         maxTableNumber = 0
      }
      playingTable = PlayingTable(number: maxTableNumber+1)
      tableWindow.makeKeyAndOrderFront(nil)
   }
   
   @IBAction func delete(_ sender: Any) {
      guard let database=TournamentDelegate.shared.database(), let tourId = TournamentDelegate.shared.tournament()?.id
         else { return }
      guard let selectedSet = playingTableBrowser.selectedRowIndexes(inColumn: 0) else { return }
      /*
 NSAlert *alert = [NSAlert new];
 alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Tisch loeschen", @"Tournament", null), [table number]];
 [alert addButtonWithTitle:NSLocalizedStringFromTable(@"nur jetzt", @"Tournament", null)];
 [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Aus der Datenbank", @"Tournament", null)];
 [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", null)];
 [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
 if (returnCode == NSAlertFirstButtonReturn) {
 [[priorityTables objectAtIndex:[table priority]-1] removeObject:table];
 } else if (returnCode == NSAlertSecondButtonReturn) {
 PGSQLConnection *database=TournamentDelegate.shared.database;
 NSString *deleteTable = [NSString stringWithFormat:@"DELETE FROM TourTable WHERE TournamentID ='%@' AND Number = %ld", TournamentDelegate.shared.preferences.tournamentId, [table number]];
 
 [database execCommand:deleteTable];
 [[priorityTables objectAtIndex:[table priority]-1] removeObject:table];    // TODO: centralize?
 }
 [self updateMatrix];
 }];
*/
      let alert = NSAlert()
      alert.informativeText = §.deleteTables
      alert.addButton(withTitle: §.justNow)
      alert.addButton(withTitle: §.fromDatabase)
      alert.beginSheetModal(for: playingTableBrowser.window!) { returnCode in
         if returnCode == .alertFirstButtonReturn {
            selectedSet.rangeView.reversed().forEach { range in
               self.freeTables.removeSubrange(range)
            }
         } else if returnCode == .alertSecondButtonReturn {
            let selectedString = Array(selectedSet).map{ (i) in String(self.freeTables[i].number)}.joined(separator: ",")
            
            let deleteSQL = String(format: "DELETE FROM TourTable WHERE TournamentId = '%@' and Number IN (%@)", tourId, selectedString)
            database.execCommand(deleteSQL)
            selectedSet.rangeView.reversed().forEach { (range) in
               self.freeTables.removeSubrange(range)
            }
         }
         self.playingTableBrowser.loadColumnZero()
      }
   }
   
   @IBAction func edit(_ sender: Any) {
      guard let selectedSet = playingTableBrowser.selectedRowIndexes(inColumn: 0) else { return }
      if let selected = selectedSet.first {
         playingTable = freeTables[selected]
         tableWindow.makeKeyAndOrderFront(nil)
      }
  }

   @IBAction func store(_ sender: Any) {
      tableWindow.makeFirstResponder(nil)
      playingTable?.store()
      repositionInFreeTables(playingTable!)
      playingTableBrowser.loadColumnZero()
      tableWindow.orderOut(nil)
   }
   
   func repositionInFreeTables(_ table: PlayingTable) {
      if let index = freeTables.index(where: { tbl in tbl.number == table.number }) {
         freeTables.remove(at:index)
      }
      if let newIndex = freeTables.index(where: { tbl in tbl.priority > table.priority } ) {
         freeTables.insert(table, at: newIndex)
      } else {
         freeTables.append(table)
      }
   }
   
   @IBAction func freeAll(_ sender: Any) {
      let alert = NSAlert()
      alert.messageText = §.caution
      alert.informativeText = §.reallyFreeAllTables
      alert.addButton(withTitle: §.dismiss)
      alert.addButton(withTitle: §.yes)
      alert.beginSheetModal(for: playingTableBrowser.window!) { (response) in
         if response == .alertSecondButtonReturn {
            self.allTables.forEach { index, table in
               if table.occupiedBy != nil {
                  table.occupiedBy = nil
                  table.store()
                  self.freeTables.append(table)
               }
            }
            DispatchQueue.main.async {
               self.playingTableBrowser.loadColumnZero()
            }
         }
      }
   }
   
   @objc func hasBackup() -> Bool {
      guard let database = TournamentDelegate.shared.database(), let tourId = TournamentDelegate.shared.tournament()?.id else { return false }
      if let rs = database.open(String(format:"SELECT COUNT(*) FROM TourTable tournamentId = '%@'", tourId)) {
         return rs.field(by:0).asLong() > 0
      } else {
         return false
      }
   }
   
   /// this is for backup purposes
   @objc func readEmptiedTables() {
      guard let database = TournamentDelegate.shared.database(), let tourId = TournamentDelegate.shared.tournament()?.id else {return}
      
      if database.execCommand(String(format:"UPDATE TourTable SET occupiedBy = null WHERE tournamentId = '%@'", tourId)) > 0 {
         readFromDatabase(self)
      }
   }

   @objc func selectAppropriateTableFor(_ playable: Playable?) {
      guard freeTables.count >  0 else { return }
      guard let playable = playable else { return }
      var selectedIndex : Int
      if let tableNo = Int(playable.tableString()),
         let predeterminedTableIndex = freeTables.index(where: { table in table.number == tableNo }) {
         selectedIndex = predeterminedTableIndex
      } else {
         let desiredPriority = playable.desiredTablePriority()
         if let priorityIndex = freeTables.index(where: { table in table.priority >= desiredPriority }) {
            selectedIndex = priorityIndex
         } else {
            selectedIndex = freeTables.count-1
         }
      }
      playingTableBrowser.selectRow(selectedIndex, inColumn: 0)
      // playingTableBrowser.loadColumnZero()
   }
   
   /*
    - (void)selectAppropriateTableFor:(id<Playable>) aPlayable;
    {
    NSMatrix *tableMatrix = [tournamentTableBrowser matrixInColumn:0];
    NSString *tableStr = [aPlayable tableString];
    long selectRow = -1;
    if ([tableStr length] > 0) {
    int preDeterminedTable = [tableStr intValue];
    long i=0, max=[tableMatrix numberOfRows];
    while ((i<max) && ([[[tableMatrix cellAtRow:i column:0] tournamentTable] number] != preDeterminedTable)) {
    i++;
    }
    if (i<max) {
    selectRow = i;
    }
    }
    if (selectRow < 0) {
    long desiredPriority = [aPlayable desiredTablePriority], selectedPriority;
    long i, max = [tableMatrix numberOfRows];
    
    i = max-1;
    while ( (i>0) && ([[[tableMatrix cellAtRow:i column:0] tournamentTable] priority] > desiredPriority) ) {
    i--;
    }
    selectedPriority = [[[tableMatrix cellAtRow:i column:0] tournamentTable] priority];
    
    selectRow = i;
    if (selectedPriority < desiredPriority) {
    if ((i < max-1)
    && ([[[tableMatrix cellAtRow:i column:0] tournamentTable] priority] <= desiredPriority+1)) {
				selectRow+=1;
    }
    }
    }
    
    [tournamentTableBrowser selectRow:selectRow inColumn:0];
    [tournamentTableBrowser setNeedsDisplay:YES];
    }

    */
   @objc func assignTablesTo(_ playable: Playable) -> Bool {
      if let selectedTables = playingTableBrowser.selectedRowIndexes(inColumn: 0)?.map({ (i) in return freeTables[i] }) {
         if playable.numberOfTables() <= selectedTables.count {
            if selectedTables.count == 1 {
               if let preDetTable = Int(playable.tableString()) {
                  let selectedTable = selectedTables[0].number
                  if preDetTable != selectedTable {
                     let alert = NSAlert()
                     alert.alertStyle = .informational
                     alert.messageText = §.predeterminedTable
                     alert.informativeText = String(format: §.doesNotFit, preDetTable, selectedTable)
                     alert.addButton(withTitle: §.abort)
                     alert.addButton(withTitle: §.reassign)
                     if alert.synchronousModalSheet(for: NSApp.mainWindow) == .alertFirstButtonReturn {
                        return false
                     }
                  }
               }
            }
            assign(selectedTables, to: playable)
            return true
         } else {
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = §.tooFewTables
            alert.informativeText = String(format:§.requiresButSelected, playable.description, playable.numberOfTables(), selectedTables.count)
            alert.addButton(withTitle: §.abort)
            alert.addButton(withTitle: §.playWithLessTables)
            if alert.synchronousModalSheet(for: NSApp.mainWindow) == .alertFirstButtonReturn {
               return false
            } else {
               assign(selectedTables, to:playable)
               return true
            }
         }
      }
      return false
   }
   
   func assign(_ tables: [PlayingTable], to playable:Playable) {
      let requiredTables = playable.numberOfTables()
      
      tables.enumerated().forEach { offset, table in
         if offset < requiredTables {
            playable.addTable(table.number)
            table.occupiedBy = playable
            if let i = freeTables.index(of: table) {
               freeTables.remove(at: i)
            }
         }
      }
      playingTableBrowser.loadColumnZero()
   }
   /*
   NSArray *selectedTables = [tournamentTableBrowser selectedCells];
   
   if ([aPlayable numberOfTables] <= [selectedTables count]) {
   if ([selectedTables count] == 1) {
			long preDetTable = [[aPlayable tableString] integerValue];
			long selectedTable = [[[selectedTables objectAtIndex:0] tournamentTable] number];
			if ((preDetTable > 0) && (preDetTable != selectedTable)) {
   NSAlert *alert = [[NSAlert alloc] init];
   alert.messageText = NSLocalizedStringFromTable(@"Vorbestimmter Tisch", @"Tournament", nil);
   alert.informativeText = [NSString stringWithFormat:NSLocalizedStringFromTable(@"Passt nicht zu", @"Tournament", nil), preDetTable, selectedTable];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil)];
   [alert addButtonWithTitle:NSLocalizedStringFromTable(@"Neu zuweisen", @"Tournament", nil)];
   if ([alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn) {
   return false;
   }
			}
   }
   [self assign:[aPlayable numberOfTables] tablesTo:aPlayable];
   
   return true;
   } else {
   NSString *zuWenigTische = NSLocalizedStringFromTable(@"Zu wenige Tische", @"Tournament", nil);
   NSString *fordert = NSLocalizedStringFromTable(@"%@ fordert %d Tische an\nes sind aber nur %d selektiert",
   @"Tournament", nil);
   NSString *abbrechen = NSLocalizedStringFromTable(@"Abbrechen", @"Tournament", nil);
   NSString *wenigerSpielen = NSLocalizedStringFromTable(@"mit weniger Tischen spielen", @"Tournament", nil);
   NSAlert *alert = [[NSAlert alloc] init];
   alert.messageText = zuWenigTische;
   alert.informativeText = [NSString stringWithFormat:fordert, [aPlayable description], [aPlayable numberOfTables], [selectedTables count]];
   [alert addButtonWithTitle:abbrechen];
   [alert addButtonWithTitle:wenigerSpielen];
   if ([alert synchronousModalSheetForWindow:[NSApp mainWindow]] == NSAlertFirstButtonReturn) {
   return false;
   } else {
   [self assign:[selectedTables count] tablesTo:aPlayable];
   return true;
   }
   }
*/
   
   @objc func freeTablesOf(_ playable: Playable) {
      var freedTables = 0
      allTables.forEach { index, table in
         if let ocupied = table.occupiedBy {
            if ocupied.rNumber() == playable.rNumber() {
               table.occupiedBy = nil
               repositionInFreeTables(table)
               freedTables += 1
            }
         }
      }
      if freedTables > 0 {
         playingTableBrowser.loadColumnZero()
      }
   }
   
   override func awakeFromNib() {
      playingTableBrowser.setCellClass(TournamentTableCell.self)
      playingTableBrowser.target = self
      playingTableBrowser.doubleAction = #selector(edit)
      playingTableBrowser.setTitle(§.availableTables, ofColumn: 0)
   }
   /*- (void)awakeFromNib;
    {
    [playingMatchesBrowser setCellClass:[OMBrowserCell class]];
    [playingMatchesBrowser setTitle:NSLocalizedStringFromTable(@"runningMatches", @"Tournament", null) ofColumn:0];
    [playingMatchesBrowser tile];    // this makes the title show, even if it does not redraw right away.
    }
*/

   @IBAction func readFromDatabase(_ sender: Any) {
      guard let tourId = TournamentDelegate.shared.tournament()?.id,  let database = TournamentDelegate.shared.database() else {
         return
      }
      freeTables.removeAll()
      let selectTables = String(format:"SELECT Number, Priority, NextToFollowing, OccupiedBy FROM TourTable WHERE TournamentID ='%@' ORDER BY Priority, Number", tourId)
      if let rs = database.open(selectTables) as? PGSQLRecordset {
         while !rs.isEOF {
            let prioTable = PlayingTable(from:rs)
            allTables[prioTable.number] = prioTable
            if prioTable.occupiedBy == nil {
               freeTables.append(prioTable)
            } else {
               prioTable.occupiedBy!.addTable(prioTable.number)
            }
            rs.moveNext()
         }
         playingTableBrowser.loadColumnZero()
      }
   }

}

extension PlayingTableController : NSBrowserDelegate {
//   func rootItem(for browser: NSBrowser) -> Any? {
//      return freeTables
//   }
   
   func browser(_ browser: NSBrowser, child index: Int, ofItem item: Any?) -> Any {
      if item == nil {
         return freeTables[index]
      } else {
         if let table = item as? PlayingTable {
            return "huh, playing table?? (\(table.number))"
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
         if !(browser.cellPrototype is TournamentTableCell) {
            browser.setCellClass(TournamentTableCell.self)
         }
         return freeTables.count
      } else {
         return 0
      }
   }
   
   func browser(_ browser:NSBrowser, objectValueForItem item:Any?) -> Any? {
      if let playTable = item as? PlayingTable {
         return String(format: "%d, %d", playTable.number, playTable.priority)
      }
      return "unknown";
   }
   
   func browser(_ sender: NSBrowser, willDisplayCell cell: Any, atRow row: Int, column: Int) {
      if let tableCell = cell as? TournamentTableCell {
         let playTable = freeTables[row]
         tableCell.setTournamentTable(TournamentTable(number:playTable.number, priority: playTable.priority, nextToFollowing: playTable.nextToFollowing, occupiedBy: playTable.occupiedBy))
      } else if let aCell = cell as? NSCell {
         print(aCell.type)
      }
   }
   
//   {
//   PGSQLConnection *database=[TournamentDelegate.shared database];
//   NSString *selectMaxPriority = [NSString stringWithFormat:@"SELECT MAX(Priority) FROM TourTable WHERE TournamentID ='%@'", tourId];
//   PGSQLRecordset *rs = (PGSQLRecordset *)[database open:selectMaxPriority];
//   if ((rs != nil) &&(![rs isEOF])) {
//   maxPriority = [[rs fieldByIndex:0] asLong];
//   }
//   [rs close];
//   [freeTables removeAllObjects];
//   while ([freeTables count] < maxPriority) {
//   [freeTables addObject:[NSMutableArray array]];
//   }
//   
//   NSString *selectTables = [NSString stringWithFormat:@"SELECT Number, Priority, NextToFollowing, OccupiedBy FROM TourTable WHERE TournamentID ='%@'", tourId];
//   rs = (PGSQLRecordset *)[database open:selectTables];
//   while (![rs isEOF]) {
//   long number, priority, occupiedBy;
//   BOOL nextToFollowing;
//   number=[[rs fieldByName:@"Number"] asLong];
//   priority=[[rs fieldByName:@"Priority"] asLong];
//   occupiedBy=[[rs fieldByName:@"OccupiedBy"] asLong];
//   nextToFollowing=[[rs fieldByName:@"NextToFollowing"] asBoolean];
//   id<Playable> occupyingPlayable = [TournamentDelegate.shared playableWithNumber:occupiedBy];
//   
//   TournamentTable *table = [TournamentTable tableWithNumber:number
//   priority:priority  nextToFollowing:nextToFollowing
//   occupiedBy:occupyingPlayable];
//   NSMutableArray *thisfreeTables = (NSMutableArray *)[freeTables objectAtIndex:priority-1];
//   
//   if (occupyingPlayable == nil) {
//   [freeTables addObject:table];
//   } else {
//   [occupyingPlayable addTable:number];
//   }
//   
//   if ([thisPriorityTables indexOfObject:table] == NSNotFound) {
//   [[rs.field(byName: "tournamentId").asString() objectAtIndex:priority-1] addObject:table];
//   }
//   [rs moveNext];
//   }
//   [rs close];
//   [self updateMatrix];
//   }

}
