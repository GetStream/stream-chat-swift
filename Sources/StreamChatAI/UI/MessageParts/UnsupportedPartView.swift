//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A step from a newer SDK: say that something happened without guessing what.
@available(iOS 15.0, macOS 12.0, *)
struct UnsupportedPartView: View {
    var font: Font

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images

    var body: some View {
        Label {
            Text(L10n.ToolCall.unsupported)
        } icon: {
            images.unsupportedPart
        }
        .font(font)
        .foregroundStyle(Color(colors.toolCallDetail))
    }
}
