//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        let payload = try JSONDecoder.default.decode(PushPreferencePayload.self, from: json)
        
        // THEN
        XCTAssertEqual(payload.chatLevel, "all")
        XCTAssertNil(payload.disabledUntil)
        
        // Test asModel conversion
        let model = payload.asModel()
        XCTAssertEqual(model.level, .all)
        XCTAssertNil(model.disabledUntil)
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
        let payload = try JSONDecoder.default.decode(PushPreferencePayload.self, from: json)
        
        // THEN
        XCTAssertEqual(payload.chatLevel, "mentions")
        XCTAssertEqual(payload.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
        
        // Test asModel conversion
        let model = payload.asModel()
        XCTAssertEqual(model.level, .mentions)
        XCTAssertEqual(model.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
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
        let payload = try JSONDecoder.default.decode(PushPreferencePayload.self, from: json)
        
        // THEN
        XCTAssertEqual(payload.chatLevel, "none")
        XCTAssertEqual(payload.disabledUntil, "2024-01-01T00:00:00.000Z".toDate())
        
        // Test asModel conversion
        let model = payload.asModel()
        XCTAssertEqual(model.level, .none)
        XCTAssertEqual(model.disabledUntil, "2024-01-01T00:00:00.000Z".toDate())
    }

    func test_pushPreferenceRequestPayload_encoding() throws {
        // GIVEN
        let requestPayload = PushPreferenceRequestPayload(
            chatLevel: "mentions",
            channelId: "messaging:test-channel",
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
        let response = try JSONDecoder.default.decode(PushPreferencesPayloadResponse.self, from: json)
        
        // THEN
        XCTAssertEqual(response.userPreferences.count, 2)
        XCTAssertEqual(response.channelPreferences.count, 1)
        
        // Test user preferences
        let user1Preference = try XCTUnwrap(response.userPreferences["user1"])
        XCTAssertEqual(user1Preference?.chatLevel, "all")
        XCTAssertNil(user1Preference?.disabledUntil)
        
        // Test channel preferences
        let channelPreferences = try XCTUnwrap(response.channelPreferences["messaging:channel1"])
        let user1ChannelPreference = try XCTUnwrap(channelPreferences["user1"])
        XCTAssertEqual(user1ChannelPreference.chatLevel, "mentions")
        XCTAssertEqual(user1ChannelPreference.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
    }
    
    func test_pushPreferencesPayloadResponse_withMissingFields_isDecodedCorrectly() throws {
        // GIVEN
        let json = """
        {
            "user_preferences": {},
            "user_channel_preferences": {}
        }
        """.data(using: .utf8)!
        
        // WHEN
        let response = try JSONDecoder.default.decode(PushPreferencesPayloadResponse.self, from: json)
        
        // THEN
        XCTAssertTrue(response.userPreferences.isEmpty)
        XCTAssertTrue(response.channelPreferences.isEmpty)
    }
    
    func test_userPushPreferencesPayload_asModel() throws {
        // GIVEN
        let userPreferences: UserPushPreferencesPayload = [
            "user1": PushPreferencePayload(chatLevel: "all", disabledUntil: nil),
            "user2": PushPreferencePayload(chatLevel: "mentions", disabledUntil: "2024-12-31T23:59:59.999Z".toDate()),
            "user3": nil
        ]
        
        // WHEN
        let models = userPreferences.asModel()
        
        // THEN
        XCTAssertEqual(models.count, 2) // user3 is nil, so excluded
        XCTAssertTrue(models.contains { $0.level == .all && $0.disabledUntil == nil })
        XCTAssertTrue(models.contains { $0.level == .mentions && $0.disabledUntil == "2024-12-31T23:59:59.999Z".toDate() })
    }
    
    func test_channelPushPreferencesPayload_asModel() throws {
        // GIVEN
        let channelPreferences: ChannelPushPreferencesPayload = [
            "messaging:channel1": [
                "user1": PushPreferencePayload(chatLevel: "all", disabledUntil: nil)
            ],
            "messaging:channel2": [
                "user1": PushPreferencePayload(chatLevel: "mentions", disabledUntil: "2024-12-31T23:59:59.999Z".toDate())
            ]
        ]
        
        // WHEN
        let models = channelPreferences.asModel()
        
        // THEN
        XCTAssertEqual(models.count, 2)
        XCTAssertEqual(models[try ChannelId(cid: "messaging:channel1")]?.level, .all)
        XCTAssertNil(models[try ChannelId(cid: "messaging:channel1")]?.disabledUntil)
        XCTAssertEqual(models[try ChannelId(cid: "messaging:channel2")]?.level, .mentions)
        XCTAssertEqual(models[try ChannelId(cid: "messaging:channel2")]?.disabledUntil, "2024-12-31T23:59:59.999Z".toDate())
    }
}
