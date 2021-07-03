//
//  PlayerManager.swift
//  Tournament
//
//  Created by Paul Trunz on 11.06.17.
//
//

import Foundation

class PlayerManager {
   
   // A little Swift-bridge to convert/store a record to DB
   static func addToDB(with licence: Int, _ attrs: [String]) {
      let player = SinglePlayer()!
      player.setLicence(licence)
      player.setPName(attrs[2])
      player.setFirstName(attrs[3])
      player.setDateOfBirth(attrs[4])
      player.setCategory(attrs[5])
      if let classement = Int(attrs[8]) {
         player.setRanking(classement)
      } else {
         print(player.pName())
      }
      if let womanClassement = Int(attrs[10]) {
         player.setWomanRanking(womanClassement)
      }
      if let elo = Int(attrs[12]) {
         player.setElo(elo)
      }
      player.setClub(attrs[15])
      // player.setRv(attrs[13])
      // player.setLicenceValidUntil(Date(attrs[17])
      
      player.storeInDatabase()
   }
   
   static func deleteClickTTMembers() {
      let db = TournamentDelegate.shared.database()!;
      let deleteClickPlayers = String(format:"DELETE FROM Player WHERE Licence BETWEEN %d AND %d", 100000, 999999);
      
      if db.execCommand(deleteClickPlayers) > 0 {
         print("players reinitialized")
      }
   }
   
   static func numberOfClickTTMembers() -> Int {
      let db = TournamentDelegate.shared.database()!;
      let countClickPlayers = String(format:"SELECT Count(*) FROM Player WHERE Licence BETWEEN %d AND %d", 100000, 999999);

      if let rs = db.open(countClickPlayers), !rs.isEOF {
         return rs.field(by: 0).asLong()
      } else {
         return 0
      }
   }
}
