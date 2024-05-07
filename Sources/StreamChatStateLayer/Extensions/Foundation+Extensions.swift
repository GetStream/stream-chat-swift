//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
extension CheckedContinuation where T == Void, E == Error {
    func resume(with error: Error?) {
        if let error {
            resume(throwing: error)
        } else {
            resume(returning: ())
        }
    }
}
