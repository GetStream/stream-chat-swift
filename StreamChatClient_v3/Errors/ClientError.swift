//
// ClientError.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

public class ClientError: Error {
    public struct Location: Equatable {
        public let file: String
        public let line: Int
    }
    
    /// The file and line number which emitted the error.
    public let location: Location?
    
    public let underlyingError: Error?
    
    public init(with error: Error? = nil, _ file: StaticString = #file, _ line: UInt = #line) {
        location = .init(file: "\(file)", line: Int(line))
        underlyingError = error
    }
}

public class CustomMessageError: ClientError {
    public let localizedDescription: String
    
    init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) {
        localizedDescription = message
        super.init(file, line)
    }
}

extension ClientError {
    public class Unexpected: ClientError {
        public private(set) lazy var localizedDescription: String = "Unexpect error: \(String(describing: underlyingError))"
        
        public convenience init(_ description: String, _ file: StaticString = #file, _ line: UInt = #line) {
            self.init(file, line)
            localizedDescription = description
        }
    }
    
    public class Unknown: CustomMessageError {}
}

// This should probably live only in the test target since it's not "true" equatable
extension ClientError: Equatable {
    public static func == (lhs: ClientError, rhs: ClientError) -> Bool {
        type(of: lhs) == type(of: rhs)
            && String(describing: lhs.underlyingError) == String(describing: rhs.underlyingError)
            && String(describing: lhs.localizedDescription) == String(describing: rhs.localizedDescription)
    }
}
