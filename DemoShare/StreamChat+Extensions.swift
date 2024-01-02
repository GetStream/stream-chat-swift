//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatClient {
    func connect(userInfo: UserInfo, token: Token) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            connectUser(userInfo: userInfo, token: token) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}

extension ChatChannelController {
    func synchronize() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.synchronize { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
    
    func uploadAttachment(
        localFileURL: URL,
        type: AttachmentType
    ) async throws -> UploadedAttachment {
        return try await withCheckedThrowingContinuation { continuation in
            uploadAttachment(localFileURL: localFileURL, type: type) { result in
                switch result {
                case .success(let uploaded):
                    continuation.resume(returning: uploaded)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @discardableResult
    func createNewMessage(text: String, attachments: [AnyAttachmentPayload]) async throws -> MessageId {
        return try await withCheckedThrowingContinuation { continuation in
            createNewMessage(
                text: text,
                attachments: attachments
            ) { result in
                switch result {
                case .success(let messageId):
                    continuation.resume(returning: messageId)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
