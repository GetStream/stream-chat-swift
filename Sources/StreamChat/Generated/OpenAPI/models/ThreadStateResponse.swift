//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class ThreadStateResponse: Sendable, Decodable {
    let thread: ThreadResponse
    let draft: DraftPayload?
    let latestReplies: [MessageResponse]
    let read: [ReadStateResponse]?

    init(
        thread: ThreadResponse,
        draft: DraftPayload? = nil,
        latestReplies: [MessageResponse],
        read: [ReadStateResponse]? = nil
    ) {
        self.thread = thread
        self.draft = draft
        self.latestReplies = latestReplies
        self.read = read
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.thread = try ThreadResponse(from: decoder)
        self.draft = try container.decodeIfPresent(DraftPayload.self, forKey: .draft)
        self.latestReplies = try container.decodeArrayIfPresentIgnoringFailures(
            [MessageResponse].self,
            forKey: .latestReplies
        ) ?? []
        self.read = try container.decodeArrayIfPresentIgnoringFailures(
            [ReadStateResponse].self,
            forKey: .read
        )
    }
}
