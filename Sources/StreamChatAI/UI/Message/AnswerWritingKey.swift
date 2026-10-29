//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Whether a reply's answer is still being written out on screen, which goes on after the
// agent finishes it. `nil` when nothing in the reply's view says, such as an app's own view.
struct AnswerWritingKey: PreferenceKey {
    static let defaultValue: Bool? = nil

    static func reduce(value: inout Bool?, nextValue: () -> Bool?) {
        guard let next = nextValue() else { return }
        value = (value ?? false) || next
    }
}
