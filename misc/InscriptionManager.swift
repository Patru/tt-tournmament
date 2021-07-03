//
//  InscriptionManager.swift
//  Tournament
//
//  Created by Paul Trunz on 06.07.17.
//
//

import Foundation

class InscriptionManager {
   
   static func createPlaySeries(from attrs: [String]) -> PlaySeries? {
      let playSer = PlaySeries()!
      if attrs[0] == TournamentDelegate.shared.tournament()?.id {
         playSer.setPass(Int(attrs[1])!)
         playSer.setSeries(attrs[2])
         if !attrs[3].isEmpty {
            playSer.setSetNumber(Int(attrs[3])!)
         }
         if !attrs[4].isEmpty {
            playSer.setPartnerPass(Int(attrs[4])!)
         }
         
         return playSer
      }
      return nil
   }
   
   // A little Swift-bridge to convert/store a record to DB
   static func addToDB(_ attrs: [String]) -> PlaySeries? {
      let playSer = PlaySeries()!
      if attrs[0] == TournamentDelegate.shared.tournament()?.id {
         playSer.setPass(Int(attrs[1])!)
         playSer.setSeries(attrs[2])
         if !attrs[3].isEmpty {
            playSer.setSetNumber(Int(attrs[3])!)
         }
         if !attrs[4].isEmpty {
            playSer.setPartnerPass(Int(attrs[4])!)
         }
         
         playSer.storeInDatabase()
         return playSer
      }
      return nil
   }
   
   static func deleteInscriptions() {
      let db = TournamentDelegate.shared.database()!;
      let tourId = TournamentDelegate.shared.tournament()!.id
      let deleteClickPlayers = String(format:"DELETE FROM PlaySeries WHERE TournamentId = '%@'", tourId);
      
      let deleted = db.execCommand(deleteClickPlayers)
      if deleted > 0 {
         print("inscriptions deleted")
      }
   }
   
   static func numberInscriptions() -> Int {
      let db = TournamentDelegate.shared.database()!;
      let tourId = TournamentDelegate.shared.tournament()!.id
      let countClickPlayers = String(format:"SELECT Count(*) FROM PlaySeries WHERE TournamentId = '%@'", tourId);
      
      if let rs = db.open(countClickPlayers), !rs.isEOF {
         return rs.field(by: 0).asLong()
      } else {
         return 0
      }
   }
}
