//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public extension AnyAttachmentPayload {
    static let mockFile = try! Self(localFileURL: .localYodaQuote, attachmentType: .file)
    static let mockImage = try! Self(localFileURL: .localYodaImage, attachmentType: .image)
    static let mockVideo = try! Self(localFileURL: .localYodaQuote, attachmentType: .video)
}

public extension URL {
    private class ThisBundle {}

    static let localYodaImage = Bundle(for: ThisBundle.self)
        .url(forResource: "yoda", withExtension: "jpg")!

    static let localYodaQuote = Bundle(for: ThisBundle.self)
        .url(forResource: "yoda", withExtension: "txt")!
}

public extension AnyAttachmentPayload {
    func attachment<T: AttachmentPayload>(id: AttachmentId) -> _ChatMessageAttachment<T>? {
        guard let payload = payload as? T else { return nil }

        return .init(
            id: id,
            type: type,
            payload: payload,
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
