//
//  WinnerPlayer.swift
//  Tournament
//
//  Created by Paul Trunz on 03.02.18.
//

import Cocoa

class WinnerPlayer : NSObject, Player, VictoryNotification {
    
    var match:Match
    var group:Group?     // usually we will continue in a group
    
    enum CodingKeys: String, CodingKey {
        case match, group
    }
    
    init(for match: Match) {
        self.match = match
        self.group = nil
        super.init()
        match.add(self)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(match)
        aCoder.encode(group)
//        aCoder.encode(match, forKey: CodingKeys.match.stringValue)
//        aCoder.encode(group, forKey: CodingKeys.group.stringValue)
    }
    
    required init?(coder aDecoder: NSCoder) {
        if aDecoder.version(forClassName:"WinnerPlayer") >= 1 {
            self.match = aDecoder.decodeObject() as! Match
            self.group = aDecoder.decodeObject() as? Group
//            self.match = aDecoder.decodeObject(forKey: CodingKeys.match.stringValue) as! Match
//            self.group = aDecoder.decodeObject(forKey: CodingKeys.group.stringValue) as? Group
        } else {
            self.match = aDecoder.decodeObject() as! Match
        }
    }
    
    func pName() -> String! {
        if let winner = match.winner() {
            return winner.pName()
        } else {
            return "not finished"
        }
    }
    
    func firstName() -> String! {
        if let winner = match.winner() {
            return winner.firstName()
        } else {
            return "not finished"
        }
    }
    
    func club() -> String! {
        if let winner = match.winner() {
            return winner.club()
        } else {
            return ""
        }
    }
    
    func drawClub() -> String! {
        if let winner = match.winner() {
            return winner.pName()
        } else {
            return "none"
        }
    }
    
    func category() -> String! {
        if let winner = match.winner() {
            return winner.category()
        } else {
            return "not finished"
        }
    }
    
    func licenceNumber() -> NSNumber! {
        if let winner = match.winner() {
            return winner.licenceNumber()
        } else {
            return 0
        }
    }
    
    func licence() -> Int {
        if let winner = match.winner() {
            return winner.licence()
        } else {
            return 0
        }
    }
    
    func ranking() -> Int {
        if let winner = match.winner() {
            return winner.ranking()
        } else {
            return 0
        }
    }
    
    func ranking(in aSeries: drawableSeries!) -> Int {
        if let winner = match.winner() {
            return winner.ranking(in:aSeries)
        } else {
            return 0
        }
    }
    
    func dayRanking() -> Float {
        if let winner = match.winner() {
            return winner.dayRanking()
        } else {
            return 0.0
        }
    }
    
    func womanRanking() -> Int {
        if let winner = match.winner() {
            return winner.womanRanking()
        } else {
            return 0
        }
    }
    
    func perform(withLongResult aSelector: Selector!) -> Int {
        return 0
    }
    
    func tourPriority() -> Float {
        if let winner = match.winner() {
            return winner.tourPriority()
        } else {
            return 0.0
        }
    }
    
    func ready() -> Bool {
        if let winner = match.winner() {
            return winner.ready()
        } else {
            return false
        }
    }
    
    func longName() -> String! {
        if let winner = match.winner() {
            return winner.longName()
        } else {
            return String(format:"Sieger Spiel %d", match.rNumber())
        }
    }
    
    func shortName() -> String! {
        if let winner = match.winner() {
            return winner.longName()
        } else {
            return String(format:"Sieger %d", match.rNumber())
        }
    }
    
    func present() -> Bool {
        if let winner = match.winner() {
            return winner.present()
        } else {
            return true
        }
    }
    
    func wo() -> Bool {
        return false
    }
    
    func attendant() -> Bool {
        if let winner = match.winner() {
            return winner.attendant()
        } else {
            return true
        }
    }
    
    func canContinue() -> Bool {
        if let winner = match.winner() {
            return winner.canContinue()
        } else {
            return false
        }
    }
    
    func setReady(_ flag: Bool) {
        if let winner = match.winner() {
            return winner.setReady(flag)
        }
    }
    
    func setPresent(_ aFlag: Bool) {
    }
    
    func setWO(_ aFlag: Bool) {
    }
    
    func contains(_ aPlayer: Player!) -> Bool {
        if let winner = match.winner() {
            return winner.contains(aPlayer)
        } else {
            return false
        }
    }
    
    func show(at x: Float, yPos y: Float, clPos club: Float) {
        if let winner = match.winner() {
            winner.show(at:x, yPos:y, clPos:club)
        } else {
            let point = CGPoint(x: Double(x), y: Double(y))
            let attrs = [NSAttributedStringKey.font: NSFont(name:"Helvetica", size:10)!]
            self.longName().draw(at:point, withAttributes:attrs)
        }
    }
    
    func drawInMatchTableOf(_ sender: Any!, x: Float, y: Float) {
        if let winner = match.winner() {
            winner.drawInMatchTableOf(sender, x:x, y:y)
        } else {
            let point = CGPoint(x: Double(x), y: Double(y))
            let attrs = [NSAttributedStringKey.font: NSFont(name:"Helvetica", size:10)!]
            self.longName().draw(at:point, withAttributes:attrs)
        }
        
    }
    
    func setPersPriority(_ aFloat: Float) {
        if let winner = match.winner() {
            return winner.setPersPriority(aFloat)
        }
    }
    
    func seriesPriority(_ series: drawableSeries!) -> Float {
        return 0.0
    }
    
    func putAsUmpire() {
        if let winner = match.winner() {
            return winner.putAsUmpire()
        }
    }
    
    func removeFromUmpireList() {
        // no players, no umpires
    }
    
    func shouldUmpire() -> Bool {
        if let winner = match.winner() {
            return winner.shouldUmpire()
        } else {
            return false
        }
    }
    
    func numberOfDependentMatches() -> Int {
        if let winner = match.winner() {
            return winner.numberOfDependentMatches()
        } else {
            return 1
        }
    }
    
    func addMatch(_ aMatch: Playable!) {
        if let winner = match.winner() {
            return winner.addMatch(aMatch)
        } else {
            if let grp = aMatch as? Group {
                group = grp     // keep the group, we will have to forward it to the player once our match is finished
            }
        }
    }
    
    func removeMatch(_ aMatch: Playable!) {
        if let winner = match.winner() {
            return winner.removeMatch(aMatch)
        }
    }
    
    // Dummy, WinnerPlayer should never play in a group
    func finishMatch(_ aMatch: Playable!) {
        
    }
    
    func hasRealPlayers() -> Bool {
        if let winner = match.winner() {
            return winner.hasRealPlayers()
        } else {
            return false
        }
    }
    
    func clickId(_ series: drawableSeries!) -> String! {
        if let winner = match.winner() {
            return winner.clickId(series)
        } else {
            assertionFailure("never call clickId without a winner")
            return "cannot export"
        }
    }
    
    func appendXml(to text: NSMutableString!, for series: drawableSeries!) {
        if let winner = match.winner() {
            return winner.appendXml(to:text, for:series)
        } else {
            assertionFailure("never call appendXml without a winner")
        }
    }
    
    func rankingListLines(_ rankStr: String!) -> String! {
        if let winner = match.winner() {
            return winner.rankingListLines(rankStr)
        } else {
            assertionFailure("never call rankingListLines without a winner")
            return "no lines"
        }
    }
    
    func adjustDayRanking(_ adjustRanking: Float) {
        if let winner = match.winner() {
            return winner.adjustDayRanking(adjustRanking)
        } else {
            assertionFailure("never call adjustDayRanking without a winner")
        }
    }
    
    // TODO: To be deleted
    @objc func actualPlayer() -> Player? {
        return match.winner()
    }
    
    func victory(of pl: Player, in mtch: Match) {
        if match == mtch, let grp=group {
            if var pls = grp.players() as? [Player] {
                if let idx = pls.index(where: { (pl) -> Bool in (pl as? WinnerPlayer) == self }) {
                    pls[idx] = pl
                    pl.addMatch(group)
                }
            }
        }
    }
}
