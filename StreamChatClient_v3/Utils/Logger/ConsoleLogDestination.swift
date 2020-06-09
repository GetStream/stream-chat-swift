//
// ConsoleLogDestination.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic destination for outputting messages to console.
public class ConsoleLogDestination: BaseLogDestination {
  open override func write(message: String) {
    print(message)
  }
}
