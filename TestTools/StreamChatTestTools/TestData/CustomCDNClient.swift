//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public final class CustomCDNClient: CDNClient {
    public static var maxAttachmentSize: Int64 { 10 * 1000 * 1000 }

    public func uploadAttachment(
        _ attachment: AnyChatMessageAttachment,
        progress: ((Double) -> Void)?,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {}
}
