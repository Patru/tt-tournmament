//
//  TourPayment.swift
//  Tournament
//
//  Created by Paul Trunz on 05.07.20.
//

import Foundation

class TourPayment {
    var licence : Int
    var tournamentId : String
    
    init(player: SinglePlayer) {
        licence = player.licence()
        tournamentId = TournamentDelegate.shared.tournament()!.id
    }
    
    init(from rs: PGSQLRecordset) {
        tournamentId = rs.field(byName: "tournamentId").asString()
        licence = rs.field(byName: "licence").asLong()
    }
    
    enum Field : String {
        case tournamentId, licence
        
        static let fields: [Field] = [.tournamentId, .licence]
        static let all: String = fields.flatMap({ field in field.rawValue }).joined(separator: ", ")
    }

    //* we want this to have Set-semantics, so we check before inserts
    func add() {
        guard let database = TournamentDelegate.shared.database() else  { return }
        if let rs = database.open("SELECT Count(*) FROM TourPayment WHERE tournamentId = '\(tournamentId)' AND licence = \(licence)")
            as? PGSQLRecordset {
            let entryCount = rs.field(by: 0).asLong()
            if entryCount == 0 {
                insert(into:database)
            }
        }
    }
    
    func insert(into database: PGSQLConnection) {
        let insertSql = String(format: "INSERT INTO TourPayment (%@) VALUES ('%@', %d)", Field.all, tournamentId, licence )
        if database.execCommand(insertSql) != 1 {
            NSLog("%@", database.errorDescription)
        }
    }
    
    func remove() {
        guard let database = TournamentDelegate.shared.database() else  { return }
        let removeSql = String(format: "DELETE FROM TourPayment WHERE TournamentId = '%@' AND Licence = %d", tournamentId, licence )
        if database.execCommand(removeSql) > 1 {
            NSLog("%@", database.errorDescription)
        }
    }
    
    static func all() -> [Int:TourPayment] {
        guard let database = TournamentDelegate.shared.database(),
            let tournamentId = TournamentDelegate.shared.tournament()?.id else  { return [:] }
        
        let paymentsQuery = "SELECT \(Field.all) FROM TourPayment WHERE tournamentId = '\(tournamentId)'"
        if let rs = database.open(paymentsQuery) as? PGSQLRecordset {
            var paymentsMap = [Int:TourPayment]()
            while !rs.isEOF {
                let payment = TourPayment(from: rs)
                paymentsMap[payment.licence] = payment
                rs.moveNext()
            }
            return paymentsMap
        } else {
            NSLog("Error while fetching TourPayment, no result set")
            return [:]
        }
    }
    
    static func deleteAll() {
        guard let database = TournamentDelegate.shared.database(),
            let tournamentId = TournamentDelegate.shared.tournament()?.id else  { return }
        
        let deleteAllSql = String(format: "DELETE FROM TourPayment WHERE TournamentId = '%@'", tournamentId )
        let deleteCount = database.execCommand(deleteAllSql)
        if deleteCount > 0 {
            NSLog("%d Zahlungen gelöscht", deleteCount)
        }
    }
    
}
