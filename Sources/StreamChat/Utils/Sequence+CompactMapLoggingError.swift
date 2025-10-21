//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

extension Sequence {
    @inlinable
    func compactMapLoggingError<ElementOfResult>(_ transform: (Element) throws -> ElementOfResult?) -> [ElementOfResult] {
        compactMap {
            do {
                return try transform($0)
            } catch {
                log.warning(error)
                return nil
            }
        }
    }
}
