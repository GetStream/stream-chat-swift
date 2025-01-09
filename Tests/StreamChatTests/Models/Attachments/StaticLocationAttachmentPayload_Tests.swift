//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@_spi(ExperimentalLocation)
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class StaticLocationAttachmentPayload_Tests: XCTestCase {
    func test_decodingDefaultValues() throws {
        // Create attachment field values
        let latitude: Double = 51.5074
        let longitude: Double = -0.1278
        
        // Create JSON with the given values
        let json = """
        {
            "latitude": \(latitude),
            "longitude": \(longitude)
        }
        """.data(using: .utf8)!
        
        // Decode attachment from JSON
        let payload = try JSONDecoder.stream.decode(StaticLocationAttachmentPayload.self, from: json)
        
        // Assert values are decoded correctly
        XCTAssertEqual(payload.latitude, latitude)
        XCTAssertEqual(payload.longitude, longitude)
    }
    
    func test_decodingExtraData() throws {
        // Create attachment field values
        let latitude: Double = 51.5074
        let longitude: Double = -0.1278
        let locationName: String = .unique
        
        // Create JSON with the given values
        let json = """
        {
            "latitude": \(latitude),
            "longitude": \(longitude),
            "locationName": "\(locationName)"
        }
        """.data(using: .utf8)!
        
        // Decode attachment from JSON
        let payload = try JSONDecoder.stream.decode(StaticLocationAttachmentPayload.self, from: json)
        
        // Assert values are decoded correctly
        XCTAssertEqual(payload.latitude, latitude)
        XCTAssertEqual(payload.longitude, longitude)
        XCTAssertEqual(payload.extraData?["locationName"]?.stringValue, locationName)
    }
    
    func test_encoding() throws {
        let payload = StaticLocationAttachmentPayload(
            latitude: 51.5074,
            longitude: -0.1278,
            extraData: ["locationName": "London"]
        )
        
        let json = try JSONEncoder.stream.encode(payload)
        
        let expectedJsonObject: [String: Any] = [
            "latitude": 51.5074,
            "longitude": -0.1278,
            "locationName": "London"
        ]
        
        AssertJSONEqual(json, expectedJsonObject)
    }
}
