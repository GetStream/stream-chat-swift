//
//  Date+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 04/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Date {
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
}

extension Date {
    
    public static var yesterday = "Yesterday"
    public static var wordsSeparator = ", "
    
    /// A relative date from the current time in string.
    public var relative: String {
        let timeString = DateFormatter.time.string(from: self)
        
        if isToday {
            return timeString
        }
        
        if isYesterday {
            return Date.yesterday.appending(Date.wordsSeparator).appending(timeString)
        }
        
        if timeIntervalSinceNow > -518_400 {
            return DateFormatter.weekDay.string(from: self).appending(Date.wordsSeparator).appending(timeString)
        }
        
        return DateFormatter.shortDate.string(from: self)
    }
    
    public func isLessThan(timeInterval: TimeInterval, with date: Date) -> Bool {
        return abs(timeIntervalSinceNow - date.timeIntervalSinceNow) < timeInterval
    }
}

extension DateFormatter {
    
    /// A short time formatter from the date.
    public static let time: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    /// A short date and time formatter from the date.
    public static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .short
        return formatter
    }()
    
    /// A short date and time formatter from the date.
    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .none
        formatter.dateStyle = .short
        return formatter
    }()

    /// A week formatter from the date.
    public static let weekDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
}
