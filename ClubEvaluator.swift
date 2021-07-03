//
//  ClubEvaluator.swift
//  Tournament
//
//  Created by Paul Trunz on 15.11.18.
//

import Foundation

@objc protocol ClubEvaluator {
   func evaluate(for series:Series)
   func showResult(in:SmallTextController, withDetails:Bool)
}
