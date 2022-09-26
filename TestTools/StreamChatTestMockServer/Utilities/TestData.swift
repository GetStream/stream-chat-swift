//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest
import StreamChatTestHelpers

public enum TestData {
    
    public static var uniqueId: String { UUID().uuidString }
    
    public static var currentDate: String {
        stringTimestamp(Date())
    }
    
    public static func stringTimestamp(_ date: Date) -> String {
        try! XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: date))
    }
    
    public static var currentTimeInterval: TimeInterval {
        Date().timeIntervalSince1970 * 1000
    }
    
    public static var waitingEndTime: TimeInterval {
        currentTimeInterval + 10_000
    }
    
    public static func getMockResponse(fromFile file: MockFile) -> String {
        String(decoding: XCTestCase.mockData(fromFile: file.filePath, bundle: .testTools), as: UTF8.self)
    }
    
    public static func mockData(fromFile file: MockFile) -> [UInt8] {
        [UInt8](XCTestCase.mockData(fromFile: file.filePath, bundle: .testTools))
    }
    
    public static func toJson(_ requestBody: [UInt8]) -> [String: Any] {
        String(bytes: requestBody, encoding: .utf8)!.json
    }
    
    public static func toJson(_ file: MockFile) -> [String: Any] {
        toJson(mockData(fromFile: file))
    }
    
    public enum Reactions: String {
        case love
        case lol = "haha"
        case wow
        case sad
        case like
    }
    
}
