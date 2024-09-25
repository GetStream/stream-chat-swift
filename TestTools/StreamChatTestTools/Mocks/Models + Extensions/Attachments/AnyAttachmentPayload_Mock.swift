//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension AnyAttachmentPayload {
    static let mockFile = try! Self(localFileURL: .localYodaQuote, attachmentType: .file)
    static let mockFileWithLongName = try! Self(localFileURL: .localYodaQuoteLongFileName, attachmentType: .file)
    static let mockImage = try! Self(localFileURL: .localYodaImage, attachmentType: .image)
    static let mockVideo = try! Self(localFileURL: .localYodaQuote, attachmentType: .video)
    static let mockAudio = try! Self(localFileURL: .localYodaQuote, attachmentType: .audio)
    static let mockVoiceRecording = try! Self(localFileURL: .localYodaQuote, attachmentType: .voiceRecording)

    static func mock(type: AttachmentType, localFileURL: URL? = nil) -> Self {
        return try! .init(localFileURL: localFileURL ?? .localYodaQuote, attachmentType: type)
    }
}

public extension AnyAttachmentPayload {
    func attachment<T: AttachmentPayload>(id: AttachmentId) -> ChatMessageAttachment<T>? {
        guard let payload = payload as? T else { return nil }

        return .init(
            id: id,
            type: type,
            payload: payload,
            downloadingState: nil,
            uploadingState: localFileURL.map {
                .init(
                    localFileURL: $0,
                    state: .pendingUpload,
                    file: try! AttachmentFile(url: $0)
                )
            }
        )
    }
}

extension AnyAttachmentPayload: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        let lhsData = try! JSONEncoder.default.encode(lhs.payload.asAnyEncodable)
        let lhsJSON = try! JSONDecoder.default.decode(RawJSON.self, from: lhsData)

        let rhsData = try! JSONEncoder.default.encode(rhs.payload.asAnyEncodable)
        let rhsJSON = try! JSONDecoder.default.decode(RawJSON.self, from: rhsData)

        return lhs.type == rhs.type &&
            lhs.localFileURL == rhs.localFileURL &&
            lhsJSON == rhsJSON
    }
}
