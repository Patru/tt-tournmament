//
//  Elo18Series.swift
//  Tournament
//
//  Created by Paul Trunz on 04.01.18.
//

import Cocoa

class Elo18Series: EloSeries {
   override func makeTable() -> Bool {
      guard let seriesController = TournamentDelegate.shared?.seriesController else { return false }
      let pls = players() as NSArray
      guard let playrs = pls as? [SeriesPlayer]  else {
         return false
      }
      let sizes = split(playrs.count)
      var start = 0
      for (index, size) in sizes.enumerated() {
         let list = Array(playrs[start..<(start+size)])
         makeSeries(number:index+1, withPlayers: list)
         start += size
      }
      
      setAlreadyDrawn(true)
      seriesController.remove(self)
      updateInscriptions(seriesController.allSeries() as! [Series])

      return true
   }
   
   // TODO: Move this back to SeriesController once it is rewritten in Swift
   func updateInscriptions(_ list: [Series]) {
      for series in list {
         updateInscriptions(series)
      }
   }
   
   func updateInscriptions(_ series:Series) {
      let players = series.players() as! [SeriesPlayer]
      
      for serPlayer in players {
         if let player = serPlayer.player() as? SinglePlayer {
            updateInscription(of:player, to:series)
         }
      }
   }
   
   func updateInscription(of player:SinglePlayer, to series:Series) {
      guard let delegate = TournamentDelegate.shared,
            let tournamentId = delegate.tournament()?.id,
            let db = delegate.database() else { return }
      
      let updateSQL = String(format:"UPDATE PlaySeries SET Series = '%@' WHERE TournamentId = '%@' AND Licence = %ld",
                             series.seriesName(), tournamentId, player.licence())
      if db.execCommand(updateSQL) == 0 {
         NSLog("failed to update DB for %ld", player.licence())
      }
   }
   
   func makeSeries(number: Int, withPlayers playersForSeries: [SeriesPlayer]!) {
      let seriesController = TournamentDelegate.shared!.seriesController
      let groupSeries = Elo18GroupSeries.series(for:self, index: number, players: playersForSeries)
      seriesController.add(groupSeries)
      seriesController.show(self)
   }


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
   
   func split(_ n: Int) -> [Int] {
      let numberOfCategories = Int(ceil(Double(n)/18.0))
      var distribute = n
      var parts = numberOfCategories
      var list = straightSplit(distribute, into:parts)
      var twelves = [Int]()
      
      while true {
         distribute = distribute - 12
         parts = parts - 1
         let newList = straightSplit(distribute, into: parts)
         if newList[0] > 18 || parts <= 1 {
            return list+twelves
         } else {
            list = newList
            twelves.append(12)
         }
      }
   }
}
