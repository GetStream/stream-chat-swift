//
// DatabaseContainer_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class DatabaseContainerTests: XCTestCase {
  func test_databaseContainer_isInitialized_withInMemoryPreset() {
    XCTAssertNoThrow(try DatabaseContainer(kind: .inMemory))
  }

  func test_databaseContainer_isInitialized_withOnDiskPreset() {
    let dbURL = URL.newTemporaryFileURL()
    XCTAssertNoThrow(try DatabaseContainer(kind: .onDisk(databaseFileURL: dbURL)))
    XCTAssertTrue(FileManager.default.fileExists(atPath: dbURL.path))
  }

  func test_databaseContainer_propagatesError_wnenInitializedWithIncorrectURL() {
    let dbURL = URL(fileURLWithPath: "/") // This URL is not writable
    XCTAssertThrowsError(try DatabaseContainer(kind: .onDisk(databaseFileURL: dbURL)))
  }
}
