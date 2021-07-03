//
//  DBMitrations.swift
//  Tournament
//
//  Created by Paul Trunz on 20.04.17.
//
//

import Foundation

class DBMigrations : NSObject {
    static var CreateSchemaMigration = SqlMigration("0.00.000", sql:"CREATE TABLE SchemaMigration (version VARCHAR(20), ExecutionDate Timestamp)")
    static var ALL : [DBMigration] = [
        SqlMigration("0.01.000", sql:"CREATE TABLE Player ( Licence DECIMAL(10), Name VARCHAR(100), FirstName VARCHAR(100), Category VARCHAR(10), Club VARCHAR(100), DateOfBirth VARCHAR(13), Ranking DECIMAL(10), WomanRanking DECIMAL(10), EloPoints DECIMAL(10) )"),
        SqlMigration("0.01.001", sql:"CREATE TABLE Series ( SeriesName VARCHAR(20), FullName VARCHAR(100), SetPlayers DECIMAL(5), Type VARCHAR(10), StartTime VARCHAR(10), Grouping VARCHAR(10), MinRanking DECIMAL(10), MaxRanking DECIMAL(10), Promotees DECIMAL(5), BestOfSeven DECIMAL(5), Age VARCHAR(10), SerCoefficient DECIMAL(10, 5), Sex VARCHAR(10), SmallFinal VARCHAR(5), TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.002", sql:"CREATE TABLE PlaySeries (Series VARCHAR(20), Licence Decimal(10), SetNumber Decimal(10), PartnerLicence Decimal(10), TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.003", sql:"CREATE TABLE TourTable (Number DECIMAL(5), Priority DECIMAL(2), NextToFollowing BOOLEAN, OccupiedBy DECIMAL(5), TournamentID VARCHAR(20))"),
        SqlMigration("0.01.005", sql:"CREATE TABLE PlayedMatch ( Number SMALLINT, Winner INTEGER, Looser INTEGER, Result VARCHAR(50), StartTime VARCHAR(10), wo BOOLEAN, duration SMALLINT, TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.006", sql:"CREATE TABLE Umpire ( Licence INTEGER, TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.007", sql:"CREATE TABLE NotPresent ( Licence INTEGER, TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.008", sql:"CREATE TABLE WalkOver ( Licence INTEGER, TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.009", sql:"CREATE TABLE PlayingMatch ( Number SMALLINT, StartTime VARCHAR(10), Umpire INTEGER, TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.010", sql:"CREATE TABLE Tournament ( tournamentId VARCHAR(20), apiKey VARCHAR(100), title VARCHAR(100), subtitle VARCHAR(100), dateRange VARCHAR(100), referee VARCHAR(100), associations VARCHAR(100), upload VARCHAR(100), commercial VARCHAR(100), depotStartingNumber Decimal(5, 2), clickTtId VARCHAR(100), region VARCHAR(100), type VARCHAR(100), dateFrom DATE, dateTo DATE, dateForExport DATE )"),
        SqlMigration("0.01.011", sql:"ALTER TABLE Series ADD COLUMN PriceAdult DECIMAL(10, 2), ADD COLUMN PriceYoung DECIMAL(10, 2)"),
        SqlMigration("0.01.012", sql:"CREATE TABLE PresentEntry ( Licence INTEGER, Series VARCHAR(20), TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.013", sql:"CREATE TABLE TourPayment ( Licence INTEGER, TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.014", sql:"CREATE TABLE WaitingListEntry (Series VARCHAR(20), Licence Decimal(10), PartnerLicence Decimal(10), TournamentID VARCHAR(20) )"),
        SqlMigration("0.01.015", sql: "ALTER TABLE WaitingListEntry ADD COLUMN CreatedAt Timestamp")
    ]
    
    // Once we start assigning primary keys using something like      did    integer PRIMARY KEY DEFAULT nextval('serial'),
    // we should use SELECT CURRVAL('name_of_primary_key_sequence'); to fetch the inserted key
    
    static func determineLastMigration(for connection:PGSQLConnection) -> String? {
        
        if let rs = connection.open("SELECT MAX(Version) from SchemaMigration") {
            return rs.field(by: 0).asString()
        } else {
            if CreateSchemaMigration.migrate(for: connection) {
                return CreateSchemaMigration.version
            }
            return nil
        }
        
    }
    
    static func apply(to connection: PGSQLConnection) {
        if let lastSuccessfulMigrationVersion = determineLastMigration(for:connection) {
            for migration in ALL {
                if lastSuccessfulMigrationVersion < migration.version {
                    connection.execCommand("START TRANSACTION")
                    defer {
                        connection.execCommand("ROLLBACK")     // whateever is not committed before the end of this block
                    }
                    if (!migration.migrate(for: connection)) {
                        let alert = NSAlert()
                        alert.messageText = "Error in migration number \(migration.version)"
                        if let description = connection.errorDescription {
                            alert.informativeText = "Description: \(description)No further migration steps have been executed."
                        } else {
                            alert.informativeText = "no useful info in description"
                        }
                        alert.addButton(withTitle: "OK")
                        alert.alertStyle = .warning
                        
                        alert.runModal()     // no window on display as of yet
                    } else {
                        connection.execCommand("COMMIT")
                    }
                }
            }
        } else {
            
        }
    }
}
