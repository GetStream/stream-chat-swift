//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

// The spinner above the turns while older messages can load, which loads them.
@available(iOS 15.0, macOS 12.0, *)
struct OlderMessagesLoadingView: View {
    // Loading starts again when the first turn changes, once the older messages arrived.
    let firstTurnID: AnyHashable?
    let load: @MainActor () async -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        ProgressView()
            .tint(Color(colors.conversationLoadingIndicator))
            .frame(maxWidth: .infinity)
            .padding(.top, layout.spacingMd)
            .task(id: firstTurnID) {
                await Self.keepLoading(load)
            }
    }

    // Loads once the spinner has stayed in view a moment, rather than for the frame a list that
    // opens at its end can show its start. While the first turn stays the same, such as after a
    // load that failed, it loads again, less and less often, until the spinner leaves the screen.
    static func keepLoading(
        _ load: @MainActor () async -> Void,
        wait: (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) }
    ) async {
        var delay: UInt64 = 300_000_000
        while true {
            do {
                try await wait(delay)
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            await load()
            delay = min(max(delay * 2, 1_000_000_000), 30_000_000_000)
        }
    }
}
