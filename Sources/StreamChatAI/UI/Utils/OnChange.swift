//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Calls `action` when `value` changes, with the view as it is after the change. SwiftUI's
// `onChange(of:perform:)` runs the closure of the view from before the change, whose other
// values are stale, so before iOS 17 the latest action is kept and run instead.
struct OnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let action: () -> Void

    @State private var latest = LatestAction()

    func body(content: Content) -> some View {
        latest.action = action
        return Group {
            if #available(iOS 17.0, *) {
                content.onChange(of: value) { action() }
            } else {
                content.onChange(of: value) { [latest] _ in latest.action() }
            }
        }
    }
}

private final class LatestAction {
    var action: () -> Void = {}
}
