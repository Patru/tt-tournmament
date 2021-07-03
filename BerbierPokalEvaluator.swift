//
//  BerbierPokalEvaluator.swift
//  Tournament
//
//  Created by Paul Trunz on 18.11.18.
//

import Foundation

class BerbierPokalEvaluator : WinnerPointsEvaluator {
   
   @objc init() {
      super.init(title: "Berbierpokal \(TournamentDelegate.shared.tournament()!.title)")
   }
   
   override func singlePoints(for rank:Int) -> Double {
      switch rank {
      case 1: return 6
      case 2: return 4
      case 3...4: return 3
      case 5...8: return 2
      case 9...16: return 1
      default: return 0
      }
   }
   
   override func doublePoints(for rank:Int) -> Double {
      switch rank {
      case 1: return 3
      case 2: return 2
      case 3...4: return 1.5
      case 5...8: return 1
      case 9...16: return 0.5
      default: return 0
      }
   }
   
   override func maxPlayersWithPoints(for series:Series) -> Int {
      return 16
   }
}
