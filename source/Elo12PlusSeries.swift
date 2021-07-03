//
//  Elo12PlusSeries.swift
//  Tournament
//
//  Created by Paul Trunz on 16.06.19.
//

import Foundation

class Elo12PlusSeries: EloSeries {
   // TODO: this is now probably standard, I am pretty sure we can easily remove this one
   override func makeTable() -> Bool {
      let seriesController = TournamentDelegate.shared.seriesController
      let pls = players() as NSArray
      guard let playrs = pls as? [SeriesPlayer]  else {
         return false
      }
      let sizes = split(playrs.count)
      var start = 0
      for (index, size) in sizes.enumerated() {
         let list = Array(playrs[start..<(start+size)])
         let groupSeries = makeGroupSeries(number:index+1, with: list)
         groupSeries.setStartTime(startTime())
         seriesController.add(series:groupSeries)
         start += size
      }
      
      setAlreadyDrawn(true)
      seriesController.remove(series:self)
      updateInscriptions(seriesController.allSeries)
      
      return true
   }

   func split(_ n: Int) -> [Int] {
      var sumSizes=n
      var sizes:[Int]
      if n <= 16 {
         sizes=[n]
      } else {
         sizes=[16]
         sumSizes-=16
      }
      let numberOfCategories = Int(ceil(Double(sumSizes)/12.0))
      
      return sizes + straightSplit(sumSizes, into:numberOfCategories)
   }

   override func makeGroupSeries(number idx:Int, with players:[SeriesPlayer]) -> EloGroupSeries {
      let groupSeries : EloGroupSeries
      if players.count == 16 {
         if (type() == "P") {
            groupSeries = Elo16GroupSeries.series(for:self, index: idx, players: players, start: startTime())
         } else {
            groupSeries = Elo16GroupConsolationSeries.series(for:self, index: idx, players: players, start: startTime())
         }
      } else {
         groupSeries = EloGroupSeries.seriesfor(self, index: idx, players: players)
         groupSeries.setStartTime(startTime())
      }
      
      return groupSeries
   }
   
}
