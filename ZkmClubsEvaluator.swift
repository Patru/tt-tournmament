//
//  ZkmClubsEvaluator.swift
//  Tournament
//
//  Created by Paul Trunz on 17.11.18.
//

import Foundation

class ZkmClubsEvaluator : WinnerPointsEvaluator {
   
   @objc init() {
      super.init(title: "Clubwertung \(TournamentDelegate.shared.tournament()!.title)")
   }

   override func singlePoints(for rank:Int) -> Double {
      switch rank {
      case 1: return 8
      case 2: return 6
      case 3...4: return 4
      case 5...6: return 2
      case 7...8: return 1
      default: return 0
      }
   }
   
   override func doublePoints(for rank:Int) -> Double {
      switch rank {
      case 1: return 4
      case 2: return 3
      case 3...4: return 2
      default: return 0
      }
   }
}
