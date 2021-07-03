//
//  PlayingTable.swift
//  Tournament
//
//  Created by Paul Trunz on 11.07.17.
//
//

import Foundation

@objcMembers class PlayingTable: NSObject {
   var number: Int
   var priority: Int
   var nextToFollowing: Bool
   var _occupiedBy: Playable?
   var occupiedBy: Playable? { get { return _occupiedBy }
      set {
         if newValue !== _occupiedBy {
            _occupiedBy = newValue
            store()
         }
      }
   }
   
   init(number: Int, priority: Int = 3, nextToFollowing: Bool = false) {
      self.number = number
      self.priority = priority
      self.nextToFollowing = nextToFollowing
      self._occupiedBy = nil              
   }
   
   init(from row: PGSQLRecordset) {
      self.number = row.field(byName: "Number").asLong()
      self.priority = row.field(byName: "Priority").asLong()
      self.nextToFollowing = row.field(byName: "NextToFollowing").asBoolean()
      let playableNumber = row.field(byName: "occupiedBy").asLong()
      if playableNumber > 0 {
         self._occupiedBy = TournamentDelegate.shared.playable(withNumber:playableNumber)
      } else {
         self._occupiedBy = nil
      }
   }
   
   func store() {
      let tournamentId = (TournamentDelegate.shared.tournament()?.id)!
      guard let database=TournamentDelegate.shared.database() else { return }
      let playableNumber : Int
      if let playable = occupiedBy {
         playableNumber = playable.rNumber()
      } else {
         playableNumber = 0
      }
      let updateSQL = String(format:"UPDATE TourTable SET Priority = %ld, NextToFollowing = '%d', OccupiedBy = %ld WHERE Number = %ld AND TournamentID = '%@'", priority, nextToFollowing.asPg(), playableNumber, number, tournamentId)
      if database.execCommand(updateSQL) == 0 || "UPDATE 0" == database.lastCmdStatus()  {
         // if we fail to update I guess we need to insert, unfortunately the number of updated rows is not returned
         let insertSQL = String(format:"INSERT INTO TourTable (Number, Priority, NextToFollowing, OccupiedBy, TournamentId) VALUES (%ld, %ld, '%d', %ld, '%@')", number, priority, nextToFollowing.asPg(), playableNumber, tournamentId)
         database.execCommand(insertSQL)
      }
   }
}
