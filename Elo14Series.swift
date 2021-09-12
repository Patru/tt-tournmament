
//
//  Elo14Series.swift
//  Tournament
//
//  Created by Paul Trunz on 27.11.2019
//

import Foundation

class Elo14Series: EloSeries {
   override func makeGroupSeries(number idx:Int, with players:[SeriesPlayer]) -> EloGroupSeries {
      return Elo14GroupSeries.series(for: self, index: idx, players: players)
   }
   
   override func preferredGroupSize() -> Int {
      return 14
   }
   
}




