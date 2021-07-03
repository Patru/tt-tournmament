//
//  WaitingListEntry.swift
//  Tournament
//
//  Created by Paul Trunz on 16.07.20.
//

import Foundation

class WaitingListEntry {
   let tournamentId, series: String
   let licence, partner: Int
   let createdAt: Date
   static let hours:DateFormatter = {
      let format = DateFormatter()
      format.calendar = Calendar(identifier: .iso8601)
      // formatter.timeZone = TimeZone(secondsFromGMT: 0)
      format.dateFormat = "dd.MM.' 'HH:mm"
      return format
   }()
   lazy var player = {
      TournamentDelegate.shared.playerController.player(forLicence: licence)
   }()
   lazy var representation: String = {
      let create = WaitingListEntry.hours.string(from: self.createdAt)
      if let player = self.player {
         return "\(player.longName()!), \(player.club()!) (\(create): \(player.elo()))"
      } else {
         return "unknown: \(licence); \(create)"
      }
   }()
   
   enum Fields : String {
      case tournamentId, series, licence, partner, createdAt
      
      static var all : String =  {
         let allFields : [Fields] = [.tournamentId, .series, .licence, createdAt]
         return allFields.map{ field in field.rawValue}.joined(separator: ", ")
      }()
   }
   
   init(tournamentId: String, series: String, licence: Int, partner: Int, createdAt: Date) {
      self.tournamentId = tournamentId
      self.series = series
      self.licence = licence
      self.partner = partner
      self.createdAt = createdAt
   }
   
   convenience init(from rs: PGSQLRecord) {
      let id = rs.field(byName: Fields.tournamentId.rawValue).asString()!
      let ser = rs.field(byName: Fields.series.rawValue).asString()!
      let lic = rs.field(byName: Fields.licence.rawValue).asLong()
      let partnerLicence = rs.field(byName: Fields.partner.rawValue).asLong()
      let createdAt = rs.field(byName: Fields.createdAt.rawValue).asDate()!
      self.init(tournamentId: id, series: ser, licence: lic, partner: partnerLicence, createdAt:createdAt)
   }
   
   /// - returns: all waiting list entries of the series in the current tournament
   /// - parameter series: the (short) name of the series
   static func all(series : String) -> [WaitingListEntry] {
      let tDel = TournamentDelegate.shared
      guard let tourId = tDel.tournament()?.id, let db = tDel.database() else {
         return []
      }
      var entries = [WaitingListEntry]()
      let query = String(format: "SELECT %@ FROM WaitingListEntry WHERE tournamentId = '%@' AND series = '%@'", Fields.all, tourId, series)
      if let rs = db.open(query) as? PGSQLRecordset {
         var rec = rs.moveFirst()
         while let record = rec {
            entries.append(WaitingListEntry(from: record))
            rec = rs.moveNext()
         }
         return entries
      } else {
         return []
      }
   }
   
   static func removeAll(for tournamentId: String) {
      let tDel = TournamentDelegate.shared
      guard let db = tDel.database() else { return }
      
      let delete = String(format: "DELETE FROM WaitingListEntry WHERE tournamentId = '%@'", tournamentId)
      
      db.execCommand(delete) 
   }
   
   func save() {
      let tDel = TournamentDelegate.shared
      guard let db = tDel.database() else { return }
      
      let insert = String(format:"INSERT INTO WaitingListEntry (%@) VALUES ('%@', '%@', %d, '%@')", WaitingListEntry.Fields.all, tournamentId, series, licence, createdAt.pgTimestamp())
      if db.execCommand(insert) != 1 {
         NSLog("could not insert WaitingListEntry for %@, %d; error: %@", series, licence, db.errorDescription)
      }
   }
   
   func remove() {
      let tDel = TournamentDelegate.shared
      guard let db = tDel.database() else { return }
      
      let delete = String(format:"DELETE FROM WaitingListEntry WHERE \(Fields.tournamentId.rawValue) = '%@' AND \(Fields.series.rawValue) = '%@' AND \(Fields.licence.rawValue) = %d", tournamentId, series, licence)
      if db.execCommand(delete) != 1 {
         NSLog("could not delete WaitingListEntry for %@, %d", series, licence)
      }
   }
}
