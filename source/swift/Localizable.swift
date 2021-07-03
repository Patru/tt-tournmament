//
//  Localizable.swift
//  Tournament
//
//  Created by Paul Trunz on 11.06.17.
//
//

import Foundation

prefix operator §

protocol Localizable {
   var key : String { get }
   func localized() -> String
}


extension Localizable {
   func localized() -> String {
      return NSLocalizedString(key, comment:"default")
   }
}

enum Default : String, Localizable {
   case clickTtLoaded
   case playersBeforeAfter
   case ok
   case error
   case warning
   case completed
   case entryImportCompleted
   case tournamentWithIdNotFound
   case failedConsiderSettingUpApiKey
   case failureOnServer
   case undefinedSeriesLoaded
   case unknownTypeReceived
   case httpError
   case seriesImportedSuccessfully
   case downloadingFile, unzippingFile, countingLines, parsingLines
   
   var key : String { get { return rawValue } }
   
   static prefix func §(_ str: Default) -> String {
      return str.localized()
   }
}

enum TournamentLocalized : String, Localizable {
    case caution, reallyFreeAllTables
    case deleteTables = "Tisch loeschen"
    case justNow = "nur jetzt", fromDatabase = "Aus der Datenbank"
    case dismiss = "Abbrechen"
    case yes, no = "Nein"
    case predeterminedTable, doesNotFit, abort, reassign, runningMatches, availableTables
    case tooFewTables = "Zu wenige Tische"
    case requiresButSelected = "%@ fordert %d Tische an\nes sind aber nur %d selektiert"
    case playWithLessTables = "mit weniger Tischen spielen"
    case seriesAlreadyDrawn = "Die Serie\n%@\n wurde bereits ausgelost"
    case seriesNotDrawnYet = "Serie noch nicht ausgelost"
    case seriesNotFinishedYet = "Serie noch nicht fertig"
    case showAnyways = "Trotzdem darstellen"
    case oohh = "Oohh"
    case noSeriesChosen = "Keine Serie gewaehlt"
    case drawAllSeries = "Alle Serien auslosen"
    case shouldAllSeriesBeDrawn = "Sollen jetzt alle Serien ausgelost werden?"
    case checkedAllWalkOverPlayers = "Alle WO Spieler ueberprueft?"
    case yesStartNow = "Ja, anfangen", noWaitSomeMore = "Nein! Warte noch"
    case seriesAlreadyStarted = "Serie bereits gestartet"
    case drawContinuously = "Fortlaufend auslosen"
    case printAllSeries = "Alle Serien drucken"
    case printWhichSeries = "Welche Serien drucken?"
    case all = "Alle", onlyRunning = "Nur laufende"
    case seriesFinished = "SerieBeendet", lastMatchPlayed = "letztesSpielGespielt"
    case printRankinglist = "RanglisteDrucken", rememberThisIWill = "merksMirSo"
    case seriesAlreadyStartedNoFurtherChanges = "Serie bereits begonnen,\nkeine weiteren Wechsel möglich."
    case canntDoThis
    case menSeries = "Herren Einzel", womenSeries = "Damen Einzel", doubleSeries = "Doppel"
    case ageSeries = "Altersserie", tourCard = "Turnierkarte STT", total = "Totalbetrag"
    case attendingPlayersAvailable, paymentsAvailable, use = "benutzen", delete = "loeschen"

    
    var key: String { get { return rawValue } }
    
    func localized() -> String {
        return NSLocalizedString(key, tableName: "Tournament", comment:"default")
    }
    static prefix func §(_ str: TournamentLocalized) -> String {
        return str.localized()
    }
}
