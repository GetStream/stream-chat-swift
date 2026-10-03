//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatLogsUI
@testable import StreamCore
import XCTest

final class LogViewerDestination_Tests: XCTestCase {
    private var destination: LogViewerDestination!

    override func setUp() {
        super.setUp()
        InMemoryLogRecorder.shared.removeAll()
        InMemoryLogRecorder.shared.isRecording = true
        destination = LogViewerDestination(
            identifier: "",
            level: .debug,
            subsystems: .all,
            showDate: true,
            dateFormatter: DateFormatter(),
            formatters: [],
            showLevel: true,
            showIdentifier: false,
            showThreadName: true,
            showFileName: true,
            showLineNumber: true,
            showFunctionName: true
        )
    }

    override func tearDown() {
        InMemoryLogRecorder.shared.removeAll()
        InMemoryLogRecorder.shared.isRecording = true
        destination = nil
        super.tearDown()
    }

    func test_process_recordsEntry() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)

        destination.process(logDetails: LogDetails(
            loggerIdentifier: "",
            subsystem: .httpRequests,
            level: .warning,
            date: date,
            message: "200 GET /users",
            threadName: "[main] ",
            functionName: "request()",
            fileName: "APIClient.swift",
            lineNumber: 42,
            error: nil,
            metadata: [.httpMethod: "GET"]
        ))

        let entry = try XCTUnwrap(InMemoryLogRecorder.shared.entries.last)
        XCTAssertEqual(entry.date, date)
        XCTAssertEqual(entry.level, .warning)
        XCTAssertEqual(entry.subsystems, ["httpRequests"])
        XCTAssertEqual(entry.message, "200 GET /users")
        XCTAssertEqual(entry.threadName, "main")
        XCTAssertEqual(entry.functionName, "request()")
        XCTAssertEqual(entry.fileName, "APIClient.swift")
        XCTAssertEqual(entry.lineNumber, 42)
        XCTAssertEqual(entry.metadata, [.httpMethod: "GET"])
    }

    func test_isEnabled_whenNotRecording_returnsFalse() {
        XCTAssertTrue(destination.isEnabled(level: .debug, subsystems: .other))

        InMemoryLogRecorder.shared.isRecording = false

        XCTAssertFalse(destination.isEnabled(level: .debug, subsystems: .other))
    }

    func test_logLevel_fromLogEntryLevel() {
        XCTAssertEqual(LogLevel(LogEntry.Level.trace), .debug)
        XCTAssertEqual(LogLevel(LogEntry.Level.debug), .debug)
        XCTAssertEqual(LogLevel(LogEntry.Level.info), .info)
        XCTAssertEqual(LogLevel(LogEntry.Level.notice), .info)
        XCTAssertEqual(LogLevel(LogEntry.Level.warning), .warning)
        XCTAssertEqual(LogLevel(LogEntry.Level.error), .error)
        XCTAssertEqual(LogLevel(LogEntry.Level.critical), .error)
    }

    func test_logEntryLevel_fromLogLevel() {
        XCTAssertEqual(LogEntry.Level(LogLevel.debug), .debug)
        XCTAssertEqual(LogEntry.Level(LogLevel.info), .info)
        XCTAssertEqual(LogEntry.Level(LogLevel.warning), .warning)
        XCTAssertEqual(LogEntry.Level(LogLevel.error), .error)
    }
}
