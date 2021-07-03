//
//  PlayerManager.swift
//  Tournament
//
//  Created by Paul Trunz on 11.06.17.
//
//

import Foundation

let NonNumberChars = CharacterSet.decimalDigits.inverted

class AssignmentManager : NSObject {
   
   // A little Swift-bridge to convert/store a record to DB
   static func addToDB(_ fields: [String]) {
      let playSer = PlaySeries()!
      playSer.setPass(Int(fields[0])!)
      playSer.setSeries(fields[1])
      if let setNum = Int(fields[2]) {
         playSer.setSetNumber(setNum)
      }
      if let parnerLicence = Int(fields[3]) {
         playSer.setPartnerPass(parnerLicence)
      }
      
      playSer.storeInDatabase()
   }
   
   @objc static func deleteAssignments() {
      guard let database=TournamentDelegate.shared.database(),
            let tourId = TournamentDelegate.shared.tournament()?.id
         else { return }
      let deleteClickPlayers = String(format:"DELETE FROM PlaySeries WHERE TournamentId = '%@'", tourId);
      
      if database.execCommand(deleteClickPlayers) > 0 {
         print("players reinitialized")
      }
   }
   
   @objc open static func numberOfAssignments() -> Int {
      guard let database=TournamentDelegate.shared.database(),
         let tourId = TournamentDelegate.shared.tournament()?.id
         else { return 0 }
      let countAssignments = String(format:"SELECT Count(*) FROM PlaySeries WHERE TournamentId = '%@'", tourId);

      if let rs = database.open(countAssignments), !rs.isEOF {
         return rs.field(by: 0).asLong()
      } else {
         return 0
      }
   }
   
   @objc static func load(_ lines:String) -> Int {
      var newCount = 0
      lines.enumerateLines { (line: String, stop: inout Bool) in
         let fields = line.components(separatedBy: ";")
         if !fields[0].isEmpty && fields[0].rangeOfCharacter(from: NonNumberChars) == nil {
            addToDB(fields)
            newCount += 1
         }
      }
      return newCount
   }
}
