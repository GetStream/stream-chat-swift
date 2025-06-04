//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// A class that provides an in-memory store for recording log entries.
public class InMemoryLogEntryStoreProvider {
    @Published public private(set) var logs: [LogEntry] = []

    public static let shared = InMemoryLogEntryStoreProvider()

    private let queue = DispatchQueue(label: "com.getstream.in-memory-log-entry-store")

    private init() {}

    public func addLog(_ log: LogEntry) {
        queue.async { [weak self] in
            self?.logs.append(log)
        }
    }

    public func deleteLog(with id: UUID) {
        queue.async { [weak self] in
            self?.logs.removeAll(where: { $0.id == id })
        }
    }

    public func clear() {
        queue.async { [weak self] in
            self?.logs.removeAll()
        }
    }
}

/// A log destination that records logs in memory.
public class InMemoryRecorderLogDestination: BaseLogDestination {
    private let logsStoreProvider = InMemoryLogEntryStoreProvider.shared

    override public func process(logDetails: LogDetails) {
        let entry = LogEntry(
            timestamp: Date(),
            level: logDetails.level,
            subsystems: logDetails.subsystems,
            functionName: "\(logDetails.functionName)",
            fileName: URL(fileURLWithPath: String(describing: logDetails.fileName)).lastPathComponent,
            lineNumber: logDetails.lineNumber,
            description: logDetails.message
        )
        logsStoreProvider.addLog(entry)
    }
}

public struct LogEntry: Identifiable {
    public let id = UUID()
    public let timestamp: Date
    public let level: LogLevel
    public let subsystems: LogSubsystem
    public let functionName: String
    public let fileName: String
    public let lineNumber: UInt
    public let description: String

    public init(
        timestamp: Date,
        level: LogLevel,
        subsystems: LogSubsystem,
        functionName: String,
        fileName: String,
        lineNumber: UInt,
        description: String
    ) {
        self.timestamp = timestamp
        self.level = level
        self.subsystems = subsystems
        self.functionName = functionName
        self.fileName = fileName
        self.lineNumber = lineNumber
        self.description = description
    }
}
