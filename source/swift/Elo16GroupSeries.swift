//
//  Elo16GroupSeries.swift
//  Tournament
//
//  Created by Paul Trunz on 16.06.19.
//

import Foundation

class Elo16GroupSeries: EloGroupSeries {
   
   class func series(for mother: EloSeries, index:Int, players: [SeriesPlayer], start time: String) -> Elo16GroupSeries {
      let ser = Elo16GroupSeries()!
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
        
        tables[0].rankingList(rankngList, upTo: 12)
        self.addGroupResults(to: rankngList, from: 3, upTo: 16, lastGroup: 4)
        
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
        let koMatches = Match(upTo: 12, current: 1, total: 1, next: nil, series: self, posList: positions)!
        matchTables().add(koMatches)
        var groupPls:[GroupPlayer] = []
        if let allGroups = groups() as? [Group] {
            for rank in 1...3 {
                for group in allGroups {
                    groupPls.append(GroupPlayer(group: group, position: rank))
                }
            }
            if let positions = positions as? [Match] {
                for i in stride(from: 4, to: 11, by: 2) {   // we have to switch these in order to separate groups
                    groupPls.swapAt(i, i+1)
                }
                for position in positions {
                    position.setWinner(groupPls[position.tNumber()-1])
                }
            }
        }
        matchTables().add(koMatches.makeLoser())        // I do not like this implicit Swift renaming
        
        /*
         if ([groups count] < 2) {        // there is no second stage for just one group
         return YES;
         }
         Group *first = [groups objectAtIndex:0];
         Group *second = [groups objectAtIndex:1];
         long totalPlayers=[[first players] count]+[[second players] count];
         long i, groupsOf4 = totalPlayers/4, remainingPlayers=totalPlayers%4;
         NSMutableArray *pts = [NSMutableArray array];
         
         for (i=0; i<groupsOf4; i++) {
         [pts removeAllObjects];
         Match *secStage = [[Match alloc] initUpTo:4 current:1 total:1 next:nil
         series:self posList:pts];
         GroupPlayer *pl1 = [[GroupPlayer alloc] initGroup:first position:i*2+1];
         GroupPlayer *pl2 = [[GroupPlayer alloc] initGroup:second position:i*2+1];
         GroupPlayer *pl3 = [[GroupPlayer alloc] initGroup:first position:i*2+2];
         GroupPlayer *pl4 = [[GroupPlayer alloc] initGroup:second position:i*2+2];
         [[pts objectAtIndex:0] setWinner:pl1];
         [[pts objectAtIndex:1] setWinner:pl4];
         [[pts objectAtIndex:2] setWinner:pl3];
         [[pts objectAtIndex:3] setWinner:pl2];
         // matches are added to GroupPlayers through setWinner
         
         [matchTables addObject:secStage];
         if ([self secondStageLooserMatch:i]) {
         [matchTables addObject:[secStage makeLoserMatch]];
         }
         }
         if (remainingPlayers == 3) {
         if ([self secondStageLooserMatch:i]) {
         [self groupOfLastThreeFrom:first and:second];
         } else {
         [self simpleOfLastThreeFrom:first and:second];
         }
         } else if (remainingPlayers == 2) {
         [self matchOfLastFrom:first and:second];
         }
         return YES;

 */
        return false
    }

}
