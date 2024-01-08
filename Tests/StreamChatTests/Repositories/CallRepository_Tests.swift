//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class CallRepository_Tests: XCTestCase {
    var repository: CallRepository!
    var apiClient: APIClient_Spy!

    override func setUp() {
        super.setUp()
        apiClient = ChatClient.mock.mockAPIClient
        repository = CallRepository(apiClient: apiClient)
    }

    override func tearDown() {
        super.tearDown()
        repository = nil
        apiClient.cleanUp()
        apiClient = nil
    }

    func test_getCallToken_propagatesError() {
        let callId: String = .unique

        // GIVEN
        var completionError: Error?
        repository.getCallToken(callId: callId) { result in
            completionError = result.error
        }

        // WHEN
        let error = TestError()
        apiClient.test_simulateResponse(Result<CallTokenPayload, Error>.failure(error))

        // THEN
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_getCallToken_simulateSuccessfulResponse() {
        let callId: String = .unique
        let agoraUid: UInt = 10
        let agoraAppId: String = .unique
        let token: String = .unique
        let agoraInfo: AgoraInfo = AgoraInfo(uid: agoraUid, appId: agoraAppId)
        let mockCallTokenPayload = CallTokenPayload(token: token, agoraUid: agoraUid, agoraAppId: agoraAppId)
        let expectedCallToken = CallToken(token: token, agoraInfo: agoraInfo)

        // GIVEN
        var resultToken: CallToken?
        repository.getCallToken(callId: callId) { result in
            resultToken = result.value
        }

        // WHEN
        apiClient.test_simulateResponse(Result<CallTokenPayload, Error>.success(mockCallTokenPayload))

        // THEN
        AssertAsync.willBeEqual(resultToken, expectedCallToken)
    }

    func test_createCall_propagatesError() {
        let channelId: ChannelId = .unique
        let callId: String = .unique
        let type: String = "video"

        // GIVEN
        var completionError: Error?
        repository.createCall(in: channelId, callId: callId, type: type) { result in
            completionError = result.error
        }

        // WHEN
        let error = TestError()
        apiClient.test_simulateResponse(Result<CreateCallPayload, Error>.failure(error))

        // THEN
        AssertAsync.willBeEqual(completionError as? TestError, error)
    }

    func test_createCall_simulateSuccessfulResponse() {
        let channelId: ChannelId = .unique
        let callId: String = .unique
        let type: String = "video"
        let callPayloadId: String = .unique
        let provider = "agora"
        let agoraChannelId: String = .unique
        let agoraPayload = AgoraPayload(channel: agoraChannelId)
        let agoraUid: UInt = 10
        let agoraAppId: String = .unique
        let hmsPayload = HMSPayload(roomId: .unique, roomName: .unique)
        let token: String = .unique

        let mockCreateCallPayload = CreateCallPayload(
            call: CallPayload(
                id: callPayloadId,
                provider: provider,
                agora: agoraPayload,
                hms: hmsPayload
            ),
            token: token,
            agoraUid: agoraUid,
            agoraAppId: agoraAppId
        )
        let expectedCallWithToken = CallWithToken(call: Call(id: callPayloadId, provider: provider, agora: AgoraCall(channel: agoraChannelId, agoraInfo: AgoraInfo(uid: agoraUid, appId: agoraAppId)), hms: HMSCall(roomId: hmsPayload.roomId, roomName: hmsPayload.roomName)), token: token)

        // GIVEN
        var resultToken: CallWithToken?
        repository.createCall(in: channelId, callId: callId, type: type) { result in
            resultToken = result.value
        }

        // WHEN
        apiClient.test_simulateResponse(Result<CreateCallPayload, Error>.success(mockCreateCallPayload))

        // THEN
        AssertAsync.willBeEqual(resultToken, expectedCallWithToken)
    }
}
