//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatLogsUI
@testable import StreamCore
import XCTest

@MainActor
final class LogViewerInstall_Tests: XCTestCase {
    private let userDefaultsSuiteName = "LogViewerInstall_Tests"
    private var settings: LogSettings!

    override func setUp() {
        super.setUp()
        UserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
        settings = LogSettings(userDefaults: UserDefaults(suiteName: userDefaultsSuiteName)!)
        LogConfig.destinationTypes = [ConsoleLogDestination.self]
        LogConfig.level = .warning
        LogConfig.subsystems = [.httpRequests, .webSocket]
    }

    override func tearDown() {
        LogConfig.reset()
        settings = nil
        UserDefaults().removePersistentDomain(forName: userDefaultsSuiteName)
        super.tearDown()
    }

    func test_install_withSharedSettings_listsStreamChatSubsystems() {
        LogSettings.shared.reset()
        LogViewer.install()

        XCTAssertEqual(LogSettings.shared.availableSubsystems, [
            "other",
            "database",
            "httpRequests",
            "webSocket",
            "offlineSupport",
            "authentication",
            "audio-playback",
            "audio-recording"
        ])
        XCTAssertTrue(LogConfig.destinations.contains { $0 is LogViewerDestination })
    }

    func test_install_setsDefaultsFromLogConfig() {
        LogViewer.install(subsystems: [.other, .httpRequests, .webSocket], settings: settings)

        XCTAssertEqual(settings.availableLevels, [.debug, .info, .warning, .error])
        XCTAssertEqual(settings.availableSubsystems, ["other", "httpRequests", "webSocket"])
        XCTAssertEqual(settings.destinations, [
            LogDestinationSettings(id: "console", name: "Console", level: .warning, disabledSubsystems: ["other"]),
            LogDestinationSettings(id: "logViewer", name: "Log Viewer", level: .debug)
        ])
    }

    func test_install_setsConsoleAndLogViewerDestinations() throws {
        LogConfig.formatters = [PrefixLogFormatter(prefixes: [.warning: "⚠️"])]

        LogViewer.install(subsystems: [.other, .httpRequests, .webSocket], settings: settings)

        let destinations = LogConfig.destinations
        XCTAssertEqual(destinations.count, 2)
        let console = try XCTUnwrap(destinations.first as? ConsoleLogDestination)
        XCTAssertEqual(console.level, .warning)
        XCTAssertEqual(console.subsystems, [.httpRequests, .webSocket])
        XCTAssertEqual(console.formatters.count, 1)
        let logViewer = try XCTUnwrap(destinations.last as? LogViewerDestination)
        XCTAssertEqual(logViewer.level, .debug)
        XCTAssertEqual(logViewer.subsystems, .all)
    }

    func test_settingsChange_updatesDestinations() throws {
        LogViewer.install(subsystems: [.other, .httpRequests, .webSocket], settings: settings)

        settings.destinations[0].level = .info
        settings.destinations[0].disabledSubsystems = []
        settings.destinations[1].isEnabled = false

        let destinations = LogConfig.destinations
        XCTAssertEqual(destinations.count, 1)
        let console = try XCTUnwrap(destinations.first as? ConsoleLogDestination)
        XCTAssertEqual(console.level, .info)
        XCTAssertEqual(console.subsystems, .all)
    }

    func test_settingsChange_withDisabledSubsystem_keepsOnlyEnabledListedSubsystems() throws {
        LogViewer.install(subsystems: [.other, .httpRequests, .webSocket], settings: settings)

        settings.destinations[1].disabledSubsystems = ["webSocket"]

        let logViewer = try XCTUnwrap(LogConfig.destinations.last as? LogViewerDestination)
        XCTAssertEqual(logViewer.subsystems, [.other, .httpRequests])
    }
}
