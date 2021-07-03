//
//  DBMigration.swift
//  Tournament
//
//  Created by Paul Trunz on 20.04.17.
//
//

import Foundation

protocol DBMigration {
   var version : String { get }
   func doMigrate(for connection:PGSQLConnection) -> Bool
}

extension DBMigration {
   func migrate(for connection:PGSQLConnection) -> Bool {
      if doMigrate(for:connection) {
         return connection.execCommand("INSERT INTO SchemaMigration (Version, ExecutionDate) VALUES ('\(version)', CURRENT_TIMESTAMP)") != 0
      }
      return false
   }
}
