//
//  SQLEscapedStringExtension.swift
//  Tournament
//
//  Created by Paul Trunz on 20.06.17.
//
//

import Foundation

let SqlEscapeChars = CharacterSet(charactersIn: "'")

extension NSString {
   @objc func sqlEscaped() -> NSString {
      if self.rangeOfCharacter(from: SqlEscapeChars).length > 0 {
         return self.replacingOccurrences(of: "'", with: "''") as NSString
      } else {
         return self
      }
   }
}

extension Bool {
   func asPg() -> Int {
      if self {
         return 1
      } else {
        return 0
      }
   }
}
