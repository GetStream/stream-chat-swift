//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import Swifter
import XCTest

enum TestData {
    
    static var uniqueId: String { UUID().uuidString }
    
    static var currentDate: String {
        try! XCTUnwrap(DateFormatter.Stream.rfc3339DateString(from: Date()))
    }
    
    static func getMockResponse(fromFile file: MockFile) -> String {
        String(decoding: XCTestCase.mockData(fromFile: file.rawValue, bundle: .test), as: UTF8.self)
    }
    
    static func mockData(fromFile file: MockFile) -> [UInt8] {
        [UInt8](XCTestCase.mockData(fromFile: file.rawValue, bundle: .test))
    }
    
    static func toJson(_ requestBody: [UInt8]) -> [String: Any] {
        String(bytes: requestBody, encoding: .utf8)!.json
    }
    
    static func toJson(_ file: MockFile) -> [String: Any] {
        toJson(mockData(fromFile: file))
    }
    
    enum Reactions: String {
        case love
        case lol = "haha"
        case wow
        case sad
        case like
    }
    
}
