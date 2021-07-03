//
//  PostgreSQLFormatedDateExtension.swift
//  Tournament
//
//  Created by Paul Trunz on 03.07.17.
//
//

import Foundation

extension Date {
    static let pgDateFormat =  { () -> DateFormatter in
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd"
        return format
    }()
    static let pgTimestampFormat =  { () -> DateFormatter in
        let format = DateFormatter()
        format.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return format
    }()

    func pgDate() -> String {
        return Date.pgDateFormat.string(from:self)
    }
    
    func pgTimestamp() -> String {
        return Date.pgTimestampFormat.string(from:self)
    }
}
