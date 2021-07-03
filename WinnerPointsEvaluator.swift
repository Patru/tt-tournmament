//
//  WinnerPointsEvaluator.swift
//  Tournament
//
//  Created by Paul Trunz on 15.11.18.
//

import Foundation

@objc class WinnerPointsEvaluator : NSObject, ClubEvaluator {
   var clubs = [String: ClubResult]()
   let title:String
   
   init(title:String) {
      self.title = title
   }
   
   func singlePoints(for rank:Int) -> Double {
      switch rank {
      case 0: return 8
      case 1: return 6
      case 2...3: return 4
      case 4...5: return 2
      case 6...7: return 1
      default: return 0
      }
   }
   
   func doublePoints(for rank:Int) -> Double {
      switch rank {
      case 0: return 4
      case 1: return 3
      case 2...3: return 2
      default: return 0
      }
   }
   
   func evaluate(for series:Series) {
      let max = maxPlayersWithPoints(for:series)
      let rkList = series.rankingListUp(to: max)
      if let winners = rkList as? [Player] {
         winners.enumerated().forEach{ (rank, player) in
            add(resultOf:player, for: series, rank: rank+1)
         }
      }
   }
   
   func showResult(in text:SmallTextController, withDetails:Bool) {
      var previousTotal = 0.0
      let sortedClubs = clubs.values.sorted(by: >)
      
      text.clearText()
      text.setTitleText("\(title)\n")
      
      for (rank, clubResult) in sortedClubs.enumerated() {
         let rankStr: String
         if previousTotal != clubResult.total {
            rankStr = "\(rank+1)."
         } else {
            rankStr = ""
         }
         previousTotal = clubResult.total
         clubResult.appendAsLine(with: rankStr, to: text)
         if withDetails {
            clubResult.appendDetails(to:text)
         }
      }
   }
   
   func add(resultOf player : Player, for series: Series, rank: Int) {
      switch player {
      case let singlePl as SinglePlayer:
         add(pointsOf: singlePl, for: series, points: singlePoints(for:rank))
      case let doublePl as DoublePlayer:
         add(pointsOf: doublePl.player(), for: series, points: doublePoints(for:rank))
         add(pointsOf: doublePl.partner(), for: series, points: doublePoints(for:rank))
      default:
         return
      }
   }
   
   func add(pointsOf player : SinglePlayer, for series: Series, points: Double) {
      if let clubResult = clubs[player.club()] {
         clubResult.add(player, series: series, points: points)
      } else {
         let clubResult = ClubResult(for:player.club())
         clubResult.add(player, series: series, points: points)
         clubs[clubResult.name] = clubResult
      }
   }

   func maxPlayersWithPoints(for series:Series) -> Int {
      switch series {
      case is DoubleSeries:
         return 4
      default:
         return 8
      }
   }
}
