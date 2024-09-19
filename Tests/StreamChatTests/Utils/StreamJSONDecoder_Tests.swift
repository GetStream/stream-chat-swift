//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StreamJSONDecoderTests: XCTestCase {
    private var streamJSONDecoder: StreamJSONDecoder!
    
    override func setUpWithError() throws {
        streamJSONDecoder = StreamJSONDecoder()
    }
    
    override func tearDownWithError() throws {
        streamJSONDecoder = nil
    }
    
    func test_parsingDate_whenMicroseconds_thenReturnsDateWithMicroseconds() throws {
        let jsonData = jsonDataForItem(withDateString: "2024-06-24T21:00:33.167806Z")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        XCTAssertEqual(1_719_262_833.167_806_1, item.date.timeIntervalSince1970)
    }
    
    func test_parsingDate_whenMicrosecondsTruncated_thenReturnsDateWithMicroseconds() throws {
        // Last 0 is not there
        let jsonData = jsonDataForItem(withDateString: "2024-06-14T16:24:37.63793Z")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        XCTAssertEqual(1_718_382_277.637_930, item.date.timeIntervalSince1970)
        
        let jsonData2 = jsonDataForItem(withDateString: "2024-06-14T16:24:37.637930Z")
        let item2 = try streamJSONDecoder.decode(Item.self, from: jsonData2)
        XCTAssertEqual(1_718_382_277.637_930, item2.date.timeIntervalSince1970)
    }
    
    func test_parsingDate_whenNanoseconds_thenReturnsDateWithTruncatedNanoseconds() throws {
        // Date interval is limited to 0.000_000_1 so the last 2 digits are dropped and it gets rounded
        let jsonData = jsonDataForItem(withDateString: "2024-09-18T13:49:11.324282561Z")
        let item = try streamJSONDecoder.decode(Item.self, from: jsonData)
        print(item.date.timeIntervalSince1970)
        XCTAssertEqual(1_726_667_351.324_282_5, item.date.timeIntervalSince1970, accuracy: 0.000_000_1)
    }
}

private extension StreamJSONDecoderTests {
    struct Item: Codable {
        let date: Date
    }
    
    func jsonDataForItem(withDateString dateString: String) -> Data {
        let string = """
        {
          "date": "\(dateString)"
        }
        """
        return Data(string.utf8)
    }
}
