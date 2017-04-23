//
//  LocalLogger.swift
//  QRCodeReader
//
//  Created by Dan Edgar on 4/23/17.
//  Copyright © 2017 AppCoda. All rights reserved.
//

import Foundation

class LocalLogger {
    
    // Can't init is singleton
    private init() { }
    
    //MARK: Shared Instance
    
    static let `default`: LocalLogger = LocalLogger()
    
    public func debug(_ message: String?) {
        if let realMessage = message {
            NSLog(realMessage)
        }
    }
    
    public func info(_ message: String?) {
        if let realMessage = message {
            NSLog(realMessage)
        }
    }
    
    public func warning(_ message: String?) {
        if let realMessage = message {
            NSLog(realMessage)
        }
    }
}
