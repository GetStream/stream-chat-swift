//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension Result {
    func invoke(with completion: ((Self) -> Void)? = nil) {
        completion?(self)
    }
}

extension Result where Success == Void {
    func invoke(with completion: ((Error?) -> Void)? = nil) {
        switch self {
        case .success:
            completion?(nil)
        case .failure(let error):
            completion?(error)
        }
    }
}
