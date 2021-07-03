//
//  Elo14GroupSeries.swift
//  Tournament
//
//  Created by Paul Trunz on 18.11.19.
//

import Foundation

class Elo14GroupSeries: EloGroupSeries {
    
    class func series(for mother: EloSeries, index:Int, players: [SeriesPlayer]) -> Elo14GroupSeries {
        let ser = Elo14GroupSeries()!
        ser.setFullName(String(format:"%@ %ld", mother.fullName(), index))
        ser.setSeriesName(String(format:"%@-%ld", mother.seriesName(), index))
        ser.setSex(mother.sex())
        ser.setBestOfSeven(mother.bestOfSeven())
        ser.setGrouping(mother.grouping())
        ser.setStartTime(mother.startTime())
        ser.setSMode(mother.sMode())
        players.forEach { (player) in
            ser.addPlayer(player)
        }
        ser.setCoefficient(7)
        
        return ser
    }
    
    override func finished() -> Bool {
        return tablesFinished()
    }
    
    // TODO: Move to Series (when converted to Swift)
    func tablesFinished() -> Bool {
        guard let mtchTables = matchTables() as? [Match] else { return false }
        if mtchTables.count == 0 { return false }
        
        for table in mtchTables {
            if !table.finished() {
                return false
            }
        }
        return true
    }
    
   override func rankingList() -> [Any]! {
      guard let tables = matchTables() as? [Match] else { return [] }
      let rankngList = NSMutableArray()

      for table in tables {
         rankngList.add(table.winner())
         
         table.rankingList(rankngList, upTo: 24)
      }
      self.addGroupResults(to: rankngList, from: tables.count, upTo: 14, lastGroup: 2)
      
      return rankngList as! [Any]
   }
    
    override func smallFinalTable() -> Match! {
        guard let tables = matchTables() as? [Match] else { return Match() /* this would fail you miserably! */ }
        
        return tables[1]
    }
    
    override func groupStage() {
        let groupCount = 2
        var realPlayers = [[Player]]()
        fixRankingForClickTT()
        
        for num in 1...groupCount {
            self.add(EloGroup(series:self, number:num))
            realPlayers.append([Player]())
        }
        
        for (index, pl) in players().enumerated() {
            if let serPl = pl as? SeriesPlayer {
                let groupIndex:Int
                let idx = index%groupCount
                let groupPos = index/groupCount
                if groupPos%2 == 1 {
                    groupIndex = groupCount - 1 - idx   // mirror the snake
                } else {
                    groupIndex = idx
                }
                
                realPlayers[groupIndex].append(serPl.player())
            }
        }
        let lists = NSMutableArray()
        for list in realPlayers {
            lists.add((list as NSArray).mutableCopy() as! NSMutableArray)
        }
        self.optimizeClubs(lists)
        if let optimizedLists = lists as? [[Player]] {
            for (index, realPls) in optimizedLists.enumerated() {
                if let group = groups()[index] as? Group {
                    group.setPlayers(realPls)
                    group.finishedDrawing()
                }
            }
        }
    }
    
   override func secondStage() -> Bool {
      guard let first = groups()[0] as? Group else { return false }
      guard let second = groups()[1] as? Group else { return false }
      let numDecidingMatches=max(first.players().count, second.players().count)
      
      
      for place in 1...numDecidingMatches {
         let positions = NSMutableArray()        // NSMutableArray will remain mutable, even if let
         let koMatch = Match(upTo: 2, current: 1, total: 1, next: nil, series: self, posList: positions)!
         if let positions = positions as? [Match] {
            positions[0].setWinner(GroupPlayer(group: first, position: place))
            positions[1].setWinner(GroupPlayer(group: second, position: place))
            matchTables().add(koMatch)
         }
      }
      return true
   }
    
}

