//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension KeyPath {
    static func string(_ keyPath: KeyPath) -> String {
        NSExpression(forKeyPath: keyPath).keyPath
    }
}
