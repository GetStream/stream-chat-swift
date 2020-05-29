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

  public init(underlyingError: Error? = nil, _ file: StaticString = #file, _ line: UInt = #line) {
    self.location = .init(file: "\(file)", line: Int(line))
    self.underlyingError = nil
  }
}

extension ClientError {
  public class Unexpect: ClientError {
    public private(set) lazy var localizedDescription: String = "Unexpect error: \(String(describing: underlyingError))"

    public convenience init(_ description: String, _ file: StaticString = #file, _ line: UInt = #line) {
      self.init(file, line)
      self.localizedDescription = description
    }
  }
}

// This should probably live only in the test target since it's not "true" equatable
extension ClientError: Equatable {
  public static func ==(lhs: ClientError, rhs: ClientError) -> Bool {
    lhs.location == rhs.location
      && String(describing: lhs.underlyingError) == String(describing: rhs.underlyingError)
  }
}
