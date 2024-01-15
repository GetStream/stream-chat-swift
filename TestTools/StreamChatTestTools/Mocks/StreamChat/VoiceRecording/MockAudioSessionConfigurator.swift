//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public final class MockAudioSessionConfigurator: Stub, Spy, AudioSessionConfiguring {

    // MARK: - Stub & Spy requirements
    public var stubbedProperties: [String : Any] = [:]
    public var recordedFunctions: [String] = []

    // MARK: - Recorded function parameters
    public private(set) var requestRecordPermissionCompletionHandler: ((Bool) -> Void)?

    // MARK: - Flow Control properties
    public var activateRecordingSessionThrowsError: Error?
    public var deactivateRecordingSessionThrowsError: Error?
    public var activatePlaybackSessionThrowsError: Error?
    public var deactivatePlaybackSessionThrowsError: Error?

    public init() { /* No-op */ }

    public func activateRecordingSession() throws {
        record()
        try activateRecordingSessionThrowsError.map { throw $0 }
    }

    public func deactivateRecordingSession() throws {
        record()
        try deactivateRecordingSessionThrowsError.map { throw $0 }
    }

    public func activatePlaybackSession() throws {
        record()
        try activatePlaybackSessionThrowsError.map { throw $0 }
    }

    public func deactivatePlaybackSession() throws {
        record()
        try deactivatePlaybackSessionThrowsError.map { throw $0 }
    }

    public func requestRecordPermission(
        _ completionHandler: @escaping (Bool) -> Void
    ) {
        record()
        requestRecordPermissionCompletionHandler = completionHandler
    }
}
