//
//  VictoryNotification.swift
//  Tournament
//
//  Created by Paul Trunz on 08.03.19.
//

import Foundation

@objc protocol VictoryNotification {
   func victory(of:Player, in: Match)
}

