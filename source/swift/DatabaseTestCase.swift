//
//  DatabaseTestCase.swift
//  Tournament
//
//  Created by Paul Trunz on 14.09.17.
//
//

import XCTest
@testable import Tournament

class DatabaseTestCase: XCTestCase {
   let tourDelegate = TournamentDelegate.shared!
   let db = TournamentDelegate.shared!.database()!
   
   override func setUp() {
      // since we hijack the connection we are able to wrap a transaction around our tests
      super.setUp()
      db.execCommand("BEGIN")
   }
   
   override func tearDown() {
      db.execCommand("ROLLBACK")
      super.tearDown()
   }
      
/*   func testPerformanceExample() {
      // This is an example of a performance test case.
      self.measure {
         // Put the code you want to measure the time of here.
      }
   }*/
   
}
