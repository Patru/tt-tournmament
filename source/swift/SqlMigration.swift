//
//  SqlMigration.swift
//  Tournament
//
//  Created by Paul Trunz on 20.04.17.
//
//

import Foundation

class SqlMigration : DBMigration {
   let version: String
   let sql: String
   
   init(_ version: String, sql: String) {
      self.version = version
      self.sql = sql
   }

   func doMigrate(for connection:PGSQLConnection) -> Bool {
      return connection.execCommand(sql) != 0
   }
  
}
