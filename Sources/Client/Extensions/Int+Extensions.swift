//
//  Int+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 07/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Int {
    
    /// A short string for the number, e.g. "k", "m", "b".
    public func shortString() -> String {
        if self >= 1_000_000_000 {
            return shortString(divider: 1_000_000_000, suffix: "b")
        }
        
        if self >= 1_000_000 {
            return shortString(divider: 1_000_000, suffix: "m")
        }
        
        if self >= 1_000 {
            return shortString(divider: 1_000, suffix: "k")
        }
        
        return String(self)
    }
    
    private func shortString(divider: Double, suffix: String) -> String {
        guard divider > 0 else {
            return ""
        }
        
        let string: String
        
        if Double(self) < divider * 10 {
            string = String(round(Double(self) / divider * 10) / 10)
        } else {
            string = String(Int(round(Double(self) / divider)))
        }
        
        return string.appending(suffix)
    }
}
