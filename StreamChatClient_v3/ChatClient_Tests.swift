//
// ChatClient_Tests.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient_v3
import XCTest

class ChatClientTests: XCTestCase {
  func testTestsWork() {
    let user = User(id: "test")
    _ = ChatClient(currentUser: user)
    XCTAssert(true)
  }
}
