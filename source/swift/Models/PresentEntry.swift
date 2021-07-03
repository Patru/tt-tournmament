//
//  PresentEntry.swift
//  Tournament
//
//  Created by Paul Trunz on 02.07.20.
//

import Foundation

class PresentEntry {
    var series : String
    var licence : Int
    var tournamentId : String
    
    init(series: String = "", licence: Int = -1, tournamentId: String = "") {
        self.series = series
        self.licence = licence
        self.tournamentId = tournamentId
    }
    
    convenience init(from rs: PGSQLRecordset) {
        self.init(series: rs.field(byName: "series").asString(), licence: rs.field(byName: "licence").asLong(),
                  tournamentId: rs.field(byName: "tournamentId").asString())
    }
    
    static let AllFields = "tournamentId, licence, series"
    
    //* we want this to have Set-semantics, so we check before
    func add() {
        guard let database = TournamentDelegate.shared.database() else  { return }
        if let rs = database.open(
            """
            SELECT Count(*) FROM PresentEntry
            WHERE tournamentId = '\(tournamentId)' AND series = '\(series)' AND licence = \(licence)
            """) as? PGSQLRecordset {
            let entryCount = rs.field(by: 0).asLong()
            if entryCount == 0 {
                insert(into:database)
            }
        }
    }
    
    func insert(into database: PGSQLConnection) {
        let insertSql = String(format: "INSERT INTO PresentEntry (%@) VALUES ('%@', %d, '%@')", PresentEntry.AllFields, tournamentId, licence, series )
        if database.execCommand(insertSql) != 1 {
            NSLog("%@", database.errorDescription)
        }
    }
    
    func remove() {
        guard let database = TournamentDelegate.shared.database() else  { return }
        let removeSql = String(format: "DELETE FROM PresentEntry WHERE TournamentId = '%@' AND Licence = %d AND Series = '%@'", tournamentId, licence, series )
        if database.execCommand(removeSql) > 1 {
            NSLog("%@", database.errorDescription)
        }
    }
    
    static func all(for series:Series) -> [Int:PresentEntry] {
        guard let database = TournamentDelegate.shared.database(),
            let tournamentId = TournamentDelegate.shared.tournament()?.id else  { return [:] }
        
        let entriesForSeriesQuery = "SELECT \(AllFields) FROM PresentEntry WHERE tournamentId = '\(tournamentId)' AND series = '\(series.seriesName()!)'"
        if let rs = database.open(entriesForSeriesQuery) as? PGSQLRecordset {
            var entriesMap = [Int:PresentEntry]()
            while !rs.isEOF {
                let entry = PresentEntry(from: rs)
                entriesMap[entry.licence] = entry
                rs.moveNext()
            }
            return entriesMap
        } else {
            NSLog("Error while fetching PresentEntries, no result set")
            return [:]
        }
    }
    
    static func deleteAll(for series:Series) {
        guard let database = TournamentDelegate.shared.database(),
            let tournamentId = TournamentDelegate.shared.tournament()?.id else  { return }
        
        let deleteAllSql = String(format: "DELETE FROM PresentEntry WHERE TournamentId = '%@' AND Series = '%@'", tournamentId, series.seriesName()! )
        let deleteCount = database.execCommand(deleteAllSql)
        if deleteCount > 0 {
            NSLog("%d Einträge gelöscht", deleteCount)
        }
    }
    
}
