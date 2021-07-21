/**
 *  Ink
 *  Copyright (c) John Sundell 2019
 *  MIT license, see LICENSE file for details
 */

internal extension Hashable {
    func isAny(of candidates: Set<Self>) -> Bool {
        candidates.contains(self)
    }
}
