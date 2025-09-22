//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

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
    
    func invoke(with completion: (@MainActor(Error?) -> Void)? = nil) {
        StreamConcurrency.onMain {
            switch self {
            case .success:
                completion?(nil)
            case .failure(let error):
                completion?(error)
            }
        }
    }
}
