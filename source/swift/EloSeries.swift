//
//  EloSeries.swift
//  Tournament
//
//  Rewritten from Obective-C by Paul Trunz on 17.11.2019.
//

import Cocoa

class EloSeries: Series {
    override  init(from record: PGSQLRecord) {
        super.init(from: record)
        super.setRankSel(#selector(SinglePlayer.elo))
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func preferredGroupSize() -> Int {
        return 12
    }
    
    /**
     This is the method to be overridden by subclasses if they do not want the regular 12 series or another mode of plas
     
     - Parameter idx: number of the series to be created
     - Parameter players: the SeriesPlayers to be put into his series
    */
    func makeGroupSeries(number idx:Int, with players:[SeriesPlayer]) -> EloGroupSeries {
        return EloGroupSeries.seriesfor(self, index: idx, players: players)
    }
    
    override func makeTable() -> Bool {
        guard !alreadyDrawn() else { return false }
        let pls = players() as NSArray
        guard let playrs = pls as? [SeriesPlayer]  else {
            return false
        }
        let seriesController = TournamentDelegate.shared.seriesController
        let numberOfCategories = Int(ceil( Double(playrs.count)/Double(preferredGroupSize()) ))

        let groupSizes = straightSplit(playrs.count, into: numberOfCategories)
        var start = 0
        for (index, size) in groupSizes.enumerated() {
            let list = Array(playrs[start..<(start+size)])
            let groupSeries = makeGroupSeries(number:index+1, with: list)
            seriesController.add(series:groupSeries)
            start += size
        }
        
        seriesController.remove(series:self)
        updateInscriptions(seriesController.allSeries as! [Series])
        seriesController.show(self)
      
        return true
   }
    
    // TODO: Move this back to SeriesController once it is rewritten in Swift
    func updateInscriptions(_ list: [Series]) {
        for series in list {
            updateInscriptions(of:series)
        }
    }
    
    func updateInscriptions(of series:Series) {
        let players = series.players() as! [SeriesPlayer]
        
        for serPlayer in players {
            if let player = serPlayer.player() as? SinglePlayer {
                updateInscription(of:player, to:series)
            }
        }
    }
    
    func updateInscription(of player:SinglePlayer, to series:Series) {
        let delegate = TournamentDelegate.shared;
        guard let tournamentId = delegate.tournament()?.id,
            let db = delegate.database() else { return }
        
        let updateSQL = String(format:"UPDATE PlaySeries SET Series = '%@' WHERE TournamentId = '%@' AND Licence = %ld",
                               series.seriesName(), tournamentId, player.licence())
        if db.execCommand(updateSQL) == 0 {
            NSLog("failed to update DB for %ld", player.licence())
        }
    }
    
    /**
     This method will also help subclasses to determine the sizes of some groups
     */
    func straightSplit(_ n: Int, into parts:Int) -> [Int] {
        guard parts > 1 else {
            return [n]
        }
        let largerSize = Int(ceil(Double(n)/Double(parts)))
        var largerCount = n%parts
        var smallerCount : Int
        if largerCount == 0 {
            largerCount = parts
            smallerCount = 0
        } else {
            smallerCount = parts-largerCount
        }
        
        return Array(repeatElement(largerSize, count: largerCount))
            + Array(repeatElement(largerSize-1, count: smallerCount))
    }
   
   override func paymentName() -> String! {
      return seriesName()
   }
}
