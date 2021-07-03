//
//  InscriptionLoader.swift
//  Tournament
//
//  Created by Paul Trunz on 06.07.17.
//
//

import Foundation
class InscriptionLoader {
   let tournamentId : String
   let softWerkerApiKey : String
   let resultInfo = NSAlert()
    let counter = LoadCounter()
    private var _result = Result.success
    private(set) var alertText=""
    var	 result : Result {
        get {
            return _result
        }
        set( newVal ) {
            if newVal.rawValue > _result.rawValue {
                _result = newVal
            }
        }
    }

   init() {
      tournamentId = TournamentDelegate.shared.tournament()!.id
      softWerkerApiKey = TournamentDelegate.shared.tournament()!.apiKey
      resultInfo.alertStyle = .informational
   }
    
    enum Result : Int {
        case success, warning, error
    }
    
    class LoadCounter {
        private(set) var seriesCounts = [String:Int]()
        private(set) var playersCount = 0
        private(set) var undefCounts = [String:Int]()
        private(set) var total = 0
        let beforeCount = InscriptionManager.numberInscriptions()

        init() {
            let seriesSql = String(format:"SELECT * FROM Series WHERE TournamentID = '%@'", TournamentDelegate.shared.tournament()!.id)
            let database = TournamentDelegate.shared.databse
            if let rs = database?.open(seriesSql) as? PGSQLRecordset {
                var rec = rs.moveFirst()
                while let record = rec {
                    if let series = Series(from: record) {
                        seriesCounts[series.seriesName()] = 0
                    }
                    rec = rs.moveNext()
                }
            }
        }

        func count(series name: String) {
            if let seriesCount = self.seriesCounts[name] {
                self.seriesCounts[name] = seriesCount+1
            } else {
                if let count = self.undefCounts[name] {
                    self.undefCounts[name] = count+1
                } else {
                    self.undefCounts[name] = 1
                }
            }
            total = total+1
        }
        
        func writeResult(to alert: NSAlert, start:String) {
            var infoText = start
            infoText.append(String(format:§.entryImportCompleted, beforeCount, total))
            alert.informativeText = infoText
            if undefCounts.count == 0 {
                alert.messageText = §.completed
                alert.informativeText.append(§.seriesImportedSuccessfully)
                alert.informativeText.append(statistics(series:seriesCounts))
            } else {
                alert.informativeText.append(String(format:"%@\n%@", §.undefinedSeriesLoaded, statistics(series:undefCounts)))
            }
        }

        func statistics(series:[String:Int]) -> String {
            var result = ""
            series.forEach { (series, count) in
                result.append("\(series): \(count)\n")
            }
            return result
        }
        
    }
   
    func fetchInscriptions() {
        var urlComponents = URLComponents(string: "https://tt.soft-werker.ch/tournaments")!
        urlComponents.path.append(String(format:"/%@/%@/all_entries.json", tournamentId, softWerkerApiKey))
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "GET"
        let session = URLSession(configuration: .ephemeral)
        session.dataTask(with: request) {data, response, err in
            if err == nil {
                if let httpResponse = response as? HTTPURLResponse {
                    switch httpResponse.statusCode {
                    case 200:
                        switch(response?.mimeType) {
                        case .some("text/csv"):
                            if let data = data {
                                self.replaceInscriptions(from: data)
                            }
                        case .some("application/json"):
                            if let data = data {
                                self.replaceUnlicensedPlayersAndEntries(json: data)
                                if let str =  String(data: data, encoding: String.Encoding.utf8) {
                                    NSLog(str)
                                }
                            }
                        case .some(let unknownType):
                            self.resultInfo.messageText = §.error
                            self.resultInfo.informativeText = String(format:§.unknownTypeReceived, unknownType)
                            self.resultInfo.alertStyle = .warning
                            if let returnData = String(data: data!, encoding: .utf8) {
                                print(returnData)
                            }
                        default:
                            print("oops, what is ", response?.mimeType ?? "?no Mime-Type!?")
                        }
                    case 404:
                        self.resultInfo.messageText = §.error
                        self.resultInfo.alertStyle = .warning
                        self.resultInfo.informativeText = §.failedConsiderSettingUpApiKey
                    case 500:
                        self.resultInfo.messageText = §.error
                        self.resultInfo.alertStyle = .warning
                        self.resultInfo.informativeText = §.failureOnServer
                    default:
                        NSLog("something unexpected happened with code %d", httpResponse.statusCode)
                    }
                }
                // we always issue an http-request, so we should not get another response type
            } else {
                if let error = err {
                    self.resultInfo.messageText = §.error
                    self.resultInfo.alertStyle = .warning
                    self.resultInfo.informativeText = String(format:§.httpError, error.localizedDescription)
                }
            }
            DispatchQueue.main.async() {
                if let mainWindow = NSApp.mainWindow {
                    self.resultInfo.beginSheetModal(for: mainWindow, completionHandler: nil)
                } else {
                    NSLog("error: %@: %@", self.resultInfo.messageText, self.resultInfo.informativeText)
                }
            }
            }.resume()
    }

    func replaceInscriptions(from data: Data) {
        let allLines = String(data: data, encoding: String.Encoding.utf8)!
        var importCount = -1             // omit one header line
        InscriptionManager.deleteInscriptions()
        allLines.enumerateLines { (line: String, stop: inout Bool) in
            let attrs = line.components(separatedBy: "\t")
            if importCount >= 0 {
                if let playSer = InscriptionManager.createPlaySeries(from: attrs) {
                    if let serName = playSer.seriesName() {
                        self.counter.count(series:serName)
                        playSer.storeInDatabase()
                    }
                }
            }
            importCount += 1
        }
    }
    
    func replaceUnlicensedPlayersAndEntries(json data: Data) {
        do {
            let isoDateFormatter = DateFormatter()
            isoDateFormatter.calendar = Calendar(identifier: .iso8601)
           // formatter.locale = Locale(identifier: "en_US_POSIX")
           // formatter.timeZone = TimeZone(secondsFromGMT: 0)
            isoDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(isoDateFormatter)
            // TODO: should probably be replaced by .iso8601 when target updates tp 10.12
            let playersAndEntries = try decoder.decode(PlayersAndEntries.self, from: data)
            if let players = playersAndEntries.players {
                replace(unlicensed:players)
            }
            replace(entries: playersAndEntries.entries)
            if let waitingList = playersAndEntries.waitingListEntries {
                replace(waitingList: waitingList)
            }
            counter.writeResult(to: resultInfo, start:alertText)
            if counter.undefCounts.count > 0 {
                result = .warning
            }
            resultInfo.messageText = §.completed
//            resultInfo.informativeText.append(§.seriesImportedSuccessfully)

        } catch {
            print(error)
            do {
                if let s = String(data: data, encoding: .utf8) {
                    let tmpPlayEntries = URL(fileURLWithPath: "/tmp/playEnt.json")
                    try s.write(to:tmpPlayEntries , atomically: true, encoding: .utf8)
                }
            } catch {
                
            }
        }
    }
    
    func replace(unlicensed players: [SingPlayer]) {
        let min = players.reduce(99999) { (result, singPlayer) -> Int in
            if result > singPlayer.licence {
                return singPlayer.licence
            } else {
                return result
            }
        }
        let max = players.reduce(0) { (result, singPlayer) -> Int in
            if result < singPlayer.licence {
                return singPlayer.licence
            } else {
                return result
            }
        }
        let database = TournamentDelegate.shared.databse
        let deletePlayers = String(format:"DELETE FROM Player WHERE  %d <= Licence AND %d >= Licence", min, max)
        let deleteCount = database?.execCommand(deletePlayers)
        let unlicCount = add(unlicensed:players)
        
        alertText.append(String(format:"%d Spieler ohne Lizenz geladen, %d gelöscht zwischen %d und %d\n\n", unlicCount, deleteCount!, min, max))
    }
    
    func replace(entries: [PlaySer]) {
        InscriptionManager.deleteInscriptions()

        for entry in entries {
            let plSer = PlaySeries()!
            plSer.setPass(entry.licence)
            plSer.setSeries(entry.series)
            if let rank=entry.rank {
                plSer.setSetNumber(rank)
            }
            if let partnerLicence = entry.partnerLicence {
                plSer.setPartnerPass(partnerLicence)
            }
            plSer.storeInDatabase()
            counter.count(series: entry.series)
        }
    }

    func replace(waitingList: [WaitingEntry]) {
        guard let tourId = TournamentDelegate.shared.tournament()?.id else { return }
        WaitingListEntry.removeAll(for: tourId)
        
        for wle in waitingList {
            let pLicence: Int
            if let lic = wle.partnerLicence {
                pLicence = lic
            } else {
                pLicence = 0
            }
            print(wle.createdAt)
            WaitingListEntry(tournamentId: tourId, series: wle.series, licence: wle.licence, partner: pLicence, createdAt:wle.createdAt).save()
        }
    }

    func add(unlicensed players: [SingPlayer]) -> Int {
        var count = 0
        for player in players {
            let singlePlayer = SinglePlayer()!
            singlePlayer.setLicence(player.licence)
            singlePlayer.setPName(player.name)
            singlePlayer.setFirstName(player.firstName)
            singlePlayer.setClub(player.club)
            singlePlayer.setCategory(player.category)
            singlePlayer.setRanking(player.ranking)
            if let womanRanking = player.womanRanking {
                singlePlayer.setWomanRanking(womanRanking)
            }
            if let elo = player.elo {
                singlePlayer.setElo(elo)
            } else {
                singlePlayer.setElo(100)
            }
            singlePlayer.storeInDatabase()
            count = count + 1
        }
        return count
    }
    
    struct SingPlayer : Codable {
        let licence: Int
        let name: String
        let firstName: String
        let club: String
        let category: String
        let elo: Int?
        let ranking: Int
        let womanRanking: Int?
        let canton: String?
        let rv: String?
        
        enum CodingKeys : String, CodingKey {
            case firstName = "first_name", womanRanking = "woman_ranking" , licence , name, club, category, elo, ranking, canton, rv
        }
    }
    
    struct PlaySer : Codable {
        let licence: Int
        let series: String
        let rank: Int?
        let partnerLicence: Int?
        
        enum CodingKeys : String, CodingKey {
            case licence, series, rank, partnerLicence = "partner_licence"
        }
    }
    
    struct WaitingEntry : Codable {
        let licence: Int
        let series: String
        let partnerLicence: Int?
        let createdAt: Date
        
        enum CodingKeys : String, CodingKey {
            case licence, series, createdAt = "created_at" , partnerLicence = "partner_licence"
        }
    }
    
    struct PlayersAndEntries : Codable {
        let players: [SingPlayer]?
        let entries: [PlaySer]
        let waitingListEntries: [WaitingEntry]?
        
        enum CodingKeys : String, CodingKey {
            case players, entries, waitingListEntries = "waiting_list"
        }
    }
   
   static func fetchAndReplaceInscriptions() {
      let loader = InscriptionLoader()
      loader.fetchInscriptions()
   }
}
