//
//  Elo18Series.swift
//  Tournament
//
//  Created by Paul Trunz on 04.01.18.
//

import Cocoa

class Elo18Series: EloSeries {
    let seriesStartTimes = ["08:00", "08:30", "10:30", "11:00", "12:30", "13:30"]
    
   override func makeTable() -> Bool {
      let seriesController = TournamentDelegate.shared.seriesController
      let pls = players() as NSArray
      guard let playrs = pls as? [SeriesPlayer]  else {
         return false
      }
      let sizes = split(playrs.count)
      let max = sizes.count
      var start = 0
      for (index, size) in sizes.enumerated() {
         let list = Array(playrs[start..<(start+size)])
         makeSeries(number:max-index, withPlayers: list, start:seriesStartTimes[max-index-1])
         start += size
      }
      
      setAlreadyDrawn(true)
      seriesController.remove(series:self)
      updateInscriptions(seriesController.allSeries as! [Series])

      return true
   }
   

    func makeSeries(number: Int, withPlayers playersForSeries: [SeriesPlayer]!, start time:String) {
      let seriesController = TournamentDelegate.shared.seriesController
        let groupSeries = Elo18GroupSeries.series(for:self, index: number, players: playersForSeries, start: time)
      seriesController.add(series:groupSeries)
      seriesController.show(self)
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
