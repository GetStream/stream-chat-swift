//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public var log: Logger {
    LogConfig.logger
}

public typealias BaseLogDestination = StreamCore.BaseLogDestination
public typealias ConsoleLogDestination = StreamCore.ConsoleLogDestination
public typealias LogConfig = StreamCore.LogConfig
public typealias LogDestination = StreamCore.LogDestination
public typealias LogFormatter = StreamCore.LogFormatter
public typealias LogLevel = StreamCore.LogLevel
public typealias LogSubsystem = StreamCore.LogSubsystem
public typealias PrefixLogFormatter = StreamCore.PrefixLogFormatter
