//
//  ClubResult.swift
//  Tournament
//
//  Created by Paul Trunz on 17.11.18.
//

import Foundation

struct PlayerResult {
   let playerInSeries: String
   let points: Double
   init(for plInSer: String, points: Double) {
      playerInSeries = plInSer
      self.points = points
   }
   
   func appendAsLine(to text:SmallTextController) {
      text.appendText("\t\t\(playerInSeries)\t\(points)\n")
   }
}

class ClubResult : Comparable {
   static func <(lhs: ClubResult, rhs: ClubResult) -> Bool {
      return lhs.total < rhs.total
   }
   
   static func ==(lhs: ClubResult, rhs: ClubResult) -> Bool {
      return lhs.total == rhs.total
   }
   
   let name:String
   var results = [PlayerResult]()
   private(set) var total = 0.0
   
   init(for name:String) {
      self.name=name
   }
   
   func add(_ player:SinglePlayer, series:Series, points:Double) {
      let seriesPlayer = "\(series.seriesName()!): \(player.longName()!)"
      let plRes = PlayerResult(for:seriesPlayer, points:points)
      // TODO: make it a real double
      results.append(plRes)
      
      total += points
   }
   
   func appendAsLine(with rank:String, to text:SmallTextController) {
      text.appendText("\t\(rank)\t\(name)\t\(total)\n")
   }
   
   func appendDetails(to text:SmallTextController) {
      for result in results {
         result.appendAsLine(to:text)
      }
   }
}

