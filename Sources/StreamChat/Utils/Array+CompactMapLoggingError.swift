//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

extension Collection {
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
