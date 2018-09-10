//
//  Elo18GroupSeries.swift
//  Tournament
//
//  Created by Paul Trunz on 31.01.18.
//

import Foundation

class Elo18GroupSeries: EloGroupSeries {
   
   class func series(for mother: EloSeries, index:Int, players: [SeriesPlayer]) -> Elo18GroupSeries {
      let ser = Elo18GroupSeries()!
      ser.setFullName(String(format:"%@ Serie %ld", mother.fullName(), index))
      ser.setSeriesName(String(format:"%@-%ld", mother.seriesName(), index))
      ser.setSex(mother.sex())
      ser.setBestOfSeven(mother.bestOfSeven())
      ser.setGrouping(mother.grouping())
      ser.setStartTime(mother.startTime())
      ser.setSMode(mother.sMode())
      players.forEach { (player) in
         ser.addPlayer(player)
      }
      ser.setCoefficient(Elo18GroupSeries.groupSize(players.count))
   
      return ser
   }
   
   class func groupSize(_ all:Int) -> Float {
      let groupCount = Elo18GroupSeries.groupCount(all)
      
      return Float((all+groupCount-1)/groupCount)
   }
   
   class func groupCount(_ all:Int) -> Int {
      return (all+5)/6
   }
   
   override func groupStage() {
      let groupCount = Elo18GroupSeries.groupCount(players().count)
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
      var lists = NSMutableArray()
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
   
   override func makeTable() -> Bool {
      groupStage()
      guard let grps = groups() as? [Group] else { return false }
      switch grps.count {
      case 3: secondStage(from3:grps)
      case 2: secondStage(from:grps[0], and:grps[1])
      default: return false // we do not know what to do here
      }
      self.numberKoMatches()
      if let lastGroup = self.groups().last as? Group {
         lastGroup.finishedDrawing()
      }
      self.setAlreadyDrawn(true)
      return true
   }
   
   func secondStage(from3 groups:[Group])  {
      var players = [Player]()
      if let tab = secondStage3Players(from: groups, startWith: 0) {
         players.append(WinnerPlayer(for:tab))
      }
      if let tab = secondStage3Players(from: groups, startWith: 1) {
         players.append(WinnerPlayer(for:tab))
      }
      if let tab = secondStage3Players(from: groups, startWith: 2) {
         players.append(WinnerPlayer(for:tab))
      }
      self.addGroup(forPlayers: players)
   }
   
   func secondStage3Players(from groups:[Group], startWith:Int) -> Match? {
      let max = groups.count
      let first = groups[startWith]
      let second = groups[(startWith+1)%max]
      let third = groups[(startWith+2)%max]

      var positions = NSMutableArray()
      if let secStage = Match(upTo: 3, current: 1, total: 1, next: nil, series: self, posList: positions) {
         if let pos1 = positions[0] as? Match {
            pos1.setWinner(GroupPlayer(group: first, position: 1))
         }
         if let pos2 = positions[1] as? Match {
            pos2.setWinner(GroupPlayer(group: third, position: 3))
         }
         if let pos3 = positions[2] as? Match {
            pos3.setWinner(GroupPlayer(group: second, position: 2))
         }
         self.matchTables().add(secStage)
         
         return secStage
      }
      return nil
   }
   
   func secondStage(from first:Group, and second:Group) {
      var list = NSMutableArray()
      if let secStage = Match(upTo: 6, current: 1, total: 1, next: nil, series: self, posList: list),
         let positions = list as? [Match] {
         positions[0].setWinner(GroupPlayer(group: first, position: 1))
         positions[1].setWinner(GroupPlayer(group: first, position: 3))
         positions[2].setWinner(GroupPlayer(group: second, position: 2))
         positions[3].setWinner(GroupPlayer(group: first, position: 2))
         positions[4].setWinner(GroupPlayer(group: second, position: 3))
         positions[5].setWinner(GroupPlayer(group: second, position: 1))
         self.matchTables().add(secStage)
         self.matchTables().add(secStage.makeLoser())
      }
   }
   
   override func finished() -> Bool {
      guard let grps = groups() as? [Group] else { return false }
      return ((grps.count == 4) && (grps.last!.finished()))
         || ((grps.count == 2) && tablesFinished())
   }
   
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
      guard let grps = groups() as? [Group],
            let tables = matchTables() as? [Match] else { return [] }
      var rankngList = [Player]()
      
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
      }
      
      return rankngList
   }
   
   func addRanks(from tables:[Match], to list:inout [Player]) {
      var second = [Player]()
      var third = [Player]()
      for winner in list {
         for table in tables {
            if let first = table.winner(), first.licence() == winner.licence() {
               // TODO: make these licence() go away, eventually things whould not remain WinnerPlayers in the group
               second.append(table.losing())
               third.append(table.lower().losing())
            }
         }
      }
      list.append(contentsOf: second)
      list.append(contentsOf: third)
   }
   
   override func smallFinalTable() -> Match! {
      guard let grps = groups() as? [Group],
         let tables = matchTables() as? [Match] else { return nil }
      
      if grps.count == 2 && tables.count == 2 {
         return tables[1]
      }
      return nil
   }
   
   override func roundString(for match: Match!) -> String! {
      guard let grps = groups() as? [Group],
         let tables = matchTables() as? [Match] else { return "oops" }
      
      if grps.count > 3 {
         if tables.contains(match) {
            return "Zwischenrunde";
         }
      }
      return super.roundString(for: match)
   }
}
