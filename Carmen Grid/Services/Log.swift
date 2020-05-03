//
//  Log.swift
//  Carmen Grid
//
//  Created by Abbey Jackson on 2019-09-27.
//  Copyright © 2019 Abbey Jackson. All rights reserved.
//

import Foundation

class Log {
    static func logUserEvent(_ message: String) {
        print("ACTION >> \(message)")
    }
    
    static func logInfo(_ message: String) {
        print(message)
    }
    
    static func logVerbose(_ message: String) {
        print(message)
    }
    
    static func logError(_ message: String) {
        print("!!!!! \(message) !!!!!")
    }
}
