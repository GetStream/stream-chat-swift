//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

class CallRepository {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func getCallToken(callId: String, completion: @escaping (Result<CallToken, Error>) -> Void) {
        apiClient.request(endpoint: .getCallToken(callId: callId)) { result in
            switch result {
            case let .failure(error):
                completion(.failure(error))
            case let .success(tokenPayload):
                let agoraInfo: AgoraInfo?
                if let uid = tokenPayload.agoraUid, let appId = tokenPayload.agoraAppId {
                    agoraInfo = AgoraInfo(uid: uid, appId: appId)
                } else {
                    agoraInfo = nil
                }

                completion(.success(CallToken(token: tokenPayload.token, agoraInfo: agoraInfo)))
            }
        }
    }

    func createCall(in cid: ChannelId, callId: String, type: String, completion: @escaping (Result<CallWithToken, Error>) -> Void) {
        apiClient.request(endpoint: .createCall(cid: cid, callId: callId, type: type)) { result in
            switch result {
            case let .success(payload):
                var agoraCall: AgoraCall?
                var hmsCall: HMSCall?

                if let agora = payload.call.agora {
                    let agoraInfo: AgoraInfo?
                    if let uid = payload.agoraUid, let appId = payload.agoraAppId {
                        agoraInfo = AgoraInfo(uid: uid, appId: appId)
                    } else {
                        agoraInfo = nil
                    }
                    agoraCall = .init(channel: agora.channel, agoraInfo: agoraInfo)
                }

                if let hms = payload.call.hms {
                    hmsCall = .init(roomId: hms.roomId, roomName: hms.roomName)
                }

                let call = Call(
                    id: payload.call.id,
                    provider: payload.call.provider,
                    agora: agoraCall,
                    hms: hmsCall
                )

                let callWithToken = CallWithToken(call: call, token: payload.token)
                completion(.success(callWithToken))
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
}
