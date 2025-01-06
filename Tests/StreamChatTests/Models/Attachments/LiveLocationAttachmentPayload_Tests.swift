//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class LiveLocationAttachmentPayload_Tests: XCTestCase {
    func test_decodingDefaultValues() throws {
        // Create attachment field values
        let latitude: Double = 51.5074
        let longitude: Double = -0.1278
        let stoppedSharing = true
        
        // Create JSON with the given values
        let json = """
        {
            "latitude": \(latitude),
            "longitude": \(longitude),
            "stopped_sharing": \(stoppedSharing)
        }
        """.data(using: .utf8)!
        
        // Decode attachment from JSON
        let payload = try JSONDecoder.stream.decode(LiveLocationAttachmentPayload.self, from: json)
        
        // Assert values are decoded correctly
        XCTAssertEqual(payload.latitude, latitude)
        XCTAssertEqual(payload.longitude, longitude)
        XCTAssertEqual(payload.stoppedSharing, stoppedSharing)
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
        let payload = try JSONDecoder.stream.decode(LiveLocationAttachmentPayload.self, from: json)
        
        // Assert values are decoded correctly
        XCTAssertEqual(payload.latitude, latitude)
        XCTAssertEqual(payload.longitude, longitude)
        XCTAssertEqual(payload.extraData?["locationName"]?.stringValue, locationName)
    }
    
    func test_encoding() throws {
        let payload = LiveLocationAttachmentPayload(
            latitude: 51.5074,
            longitude: -0.1278,
            stoppedSharing: true,
            extraData: ["locationName": "London"]
        )
        
        let json = try JSONEncoder.stream.encode(payload)
        
        let expectedJsonObject: [String: Any] = [
            "latitude": 51.5074,
            "longitude": -0.1278,
            "stopped_sharing": true,
            "locationName": "London"
        ]
        
        AssertJSONEqual(json, expectedJsonObject)
    }
}
