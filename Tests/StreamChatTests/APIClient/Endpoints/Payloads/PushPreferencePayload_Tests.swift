//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class PushPreferencePayload_Tests: XCTestCase {
    func test_pushPreferencePayload_withAllLevel_isDecodedCorrectly() throws {
        // GIVEN
        let json = """
        {
            "chat_level": "all",
            "disabled_until": null
        }
        """.data(using: .utf8)!
        
        // WHEN
        let payload = try JSONDecoder.default.decode(PushPreferencesResponse.self, from: json)
        
        // THEN
        XCTAssertEqual(payload.chatLevel, "all")
        XCTAssertNil(payload.disabledUntil)
    }
    
    func test_pushPreferencePayload_withMentionsLevel_isDecodedCorrectly() throws {
        // GIVEN
        let json = """
        {
            "chat_level": "mentions",
            "disabled_until": "2024-12-31T23:59:59.999Z"
        }
        """.data(using: .utf8)!
        
        // WHEN
        let payload = try JSONDecoder.default.decode(PushPreferencesResponse.self, from: json)
        
        // THEN
        XCTAssertEqual(payload.chatLevel, "mentions")
        XCTAssertEqual(payload.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
    }
    
    func test_pushPreferencePayload_withNoneLevel_isDecodedCorrectly() throws {
        // GIVEN
        let json = """
        {
            "chat_level": "none",
            "disabled_until": "2024-01-01T00:00:00.000Z"
        }
        """.data(using: .utf8)!
        
        // WHEN
        let payload = try JSONDecoder.default.decode(PushPreferencesResponse.self, from: json)
        
        // THEN
        XCTAssertEqual(payload.chatLevel, "none")
        XCTAssertEqual(payload.disabledUntil, "2024-01-01T00:00:00.000Z".toDate())
    }

    func test_pushPreferenceRequestPayload_encoding() throws {
        // GIVEN
        let requestPayload = PushPreferenceInput(
            channelCid: "messaging:test-channel",
            chatLevel: PushPreferenceInput.PushPreferenceInputChatLevel(rawValue: "mentions"),
            disabledUntil: "2024-12-31T23:59:59.999Z".toDate(),
            removeDisable: true
        )
        
        // WHEN
        let encoded = try JSONEncoder.default.encode(requestPayload)

        AssertJSONEqual(encoded, [
            "chat_level": "mentions",
            "channel_cid": "messaging:test-channel",
            "disabled_until": "2024-12-31T23:59:59.999Z",
            "remove_disable": true
        ])
    }
    
    func test_pushPreferencesPayloadResponse_isDecodedCorrectly() throws {
        // GIVEN
        let json = """
        {
            "duration": "",
            "user_preferences": {
                "user1": {
                    "chat_level": "all",
                    "disabled_until": null
                }
            },
            "user_channel_preferences": {
                "messaging:channel1": {
                    "user1": {
                        "chat_level": "mentions",
                        "disabled_until": "2024-12-31T23:59:59.999Z"
                    }
                }
            }
        }
        """.data(using: .utf8)!
        
        // WHEN
        let response = try JSONDecoder.default.decode(UpsertPushPreferencesResponse.self, from: json)
        
        // THEN
        XCTAssertEqual(response.userPreferences.count, 1)
        XCTAssertEqual(response.userChannelPreferences.count, 1)
        
        // Test user preferences
        let user1Preference = try XCTUnwrap(try XCTUnwrap(response.userPreferences["user1"]))
        XCTAssertEqual(user1Preference.chatLevel, "all")
        XCTAssertNil(user1Preference.disabledUntil)
        
        // Test channel preferences
        let channelPreferences = try XCTUnwrap(response.userChannelPreferences["messaging:channel1"])
        let user1ChannelPreference = try XCTUnwrap(channelPreferences["user1"])
        XCTAssertEqual(user1ChannelPreference?.chatLevel, "mentions")
        XCTAssertEqual(user1ChannelPreference?.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
    }
    
    func test_pushPreferencesPayloadResponse_withMissingFields_isDecodedCorrectly() throws {
        // GIVEN
        let json = """
        {
            "duration": "",
            "user_preferences": {},
            "user_channel_preferences": {}
        }
        """.data(using: .utf8)!
        
        // WHEN
        let response = try JSONDecoder.default.decode(UpsertPushPreferencesResponse.self, from: json)
        
        // THEN
        XCTAssertTrue(response.userPreferences.isEmpty)
        XCTAssertTrue(response.userChannelPreferences.isEmpty)
    }
}
