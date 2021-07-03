//
//  Elo16GroupConsolationSeries.swift
//  Tournament
//
//  Created by Paul Trunz on 21.08.20.
//

import Foundation

class Elo16GroupConsolationSeries: EloGroupSeries {
   
   class func series(for mother: EloSeries, index:Int, players: [SeriesPlayer], start time: String) -> Elo16GroupConsolationSeries {
      let ser = Elo16GroupConsolationSeries()!
      ser.setFullName(String(format:"%@ Topserie", mother.fullName(), index))
      ser.setSeriesName(String(format:"%@-%ld", mother.seriesName(), index))
      ser.setSex(mother.sex())
      ser.setBestOfSeven(mother.bestOfSeven())
      ser.setGrouping(mother.grouping())
      ser.setStartTime(time)
      ser.setSMode(mother.sMode())
      players.forEach { (player) in
         ser.addPlayer(player)
      }
      ser.setCoefficient(4)
      
      return ser
   }
   
   override func finished() -> Bool {
      return tablesFinished()
   }
   
   // TODO: Move to Series (when converted to Swift)
   func tablesFinished() -> Bool {
      guard let mtchTables = matchTables() as? [Match] else { return false }
      
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
        rankngList.add(tables[0].winner())
        
        tables[0].rankingList(rankngList, upTo: 8)
        if tables.count > 2 {
            rankngList.add(tables[2].winner())
            tables[2].rankingList(rankngList, upTo: 16)
        }
        
        /* maybe we do not need this, since it is more or less a regular GroupSeries?
         switch grps.count {
         case 4:
         if let top3 = grps[3].rankingList() as? [Player] {
         rankngList.append(contentsOf: top3)
         }
         addRanks(from:tables, to:&rankngList)
         let list = NSMutableArray()
         addGroupResults(to: list, from: 3, upTo: 18, lastGroup: 3)
         rankngList.append(contentsOf: list as! [Player])
         case 2:
         let list = NSMutableArray()
         list.add(tables[0].winner())
         tables[0].rankingList(list, upTo: 6)
         self.addGroupResults(to: list, from: 3, upTo: 12, lastGroup: 2)
         rankngList.append(contentsOf: list as! [Player])
         default: break
         }*/
        
        return rankngList as! [Any]
    }
   
   override func smallFinalTable() -> Match! {
      guard let tables = matchTables() as? [Match] else { return Match() /* this would fail you miserably! */ }
      
      return tables[1]
   }
   
   override func groupStage() {
      let groupCount = 4
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
      let positions = NSMutableArray()        // NSMutableArray will remain mutable, even if assigned by let
      let koMatches = Match(upTo: 8, current: 1, total: 1, next: nil, series: self, posList: positions)!
      matchTables().add(koMatches)
      var groupPls:[GroupPlayer] = []
      if let allGroups = groups() as? [Group] {
         for rank in 1...2 {
            for group in allGroups {
               groupPls.append(GroupPlayer(group: group, position: rank))
            }
         }
         if let positions = positions as? [Match] {
            for i in stride(from: 4, to: 7, by: 2) {   // we have to switch these in order to separate groups
               groupPls.swapAt(i, i+1)
            }
            for position in positions {
                let grpPlayer = groupPls[position.tNumber()-1]
                position.setWinner(grpPlayer)
//                if let grp = grpPlayer.group() as? Group {
//                    grp.addPosition(grpPlayer)
//                }
            }
         }
      }
      matchTables().add(koMatches.makeLoser())        // I do not like this implicit Swift renaming,
      // should be makeLoserMatch
    let consPos = NSMutableArray()
      let consolationMatches = Match(upTo: 8, current: 1, total: 1, next: nil, series: self, posList: consPos)!
      matchTables().add(consolationMatches)
      groupPls = []
      if let allGroups = groups() as? [Group] {
         for rank in 3...4 {
            for group in allGroups {
               groupPls.append(GroupPlayer(group: group, position: rank))
            }
         }
         if let consPos = consPos as? [Match] {
            for i in stride(from: 4, to: 7, by: 2) {   // we have to switch these in order to separate groups
               groupPls.swapAt(i, i+1)
            }
            for position in consPos {
               position.setWinner(groupPls[position.tNumber()-1])
            }
         }
      }
      
      return false
   }
   
}

