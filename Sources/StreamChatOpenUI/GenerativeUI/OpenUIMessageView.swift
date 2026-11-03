//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import SwiftUI

// A reply's UI, which follows its program as the agent writes it.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIMessageView: View {
    let runtime: OpenUIRuntime
    let program: String
    let isStreaming: Bool
    var mediaURL: @Sendable (URL) -> URL? = { $0 }
    var theme: OpenUITheme?

    @Injected(\.aiAppearance) private var appearance
    @State private var isOnScreen = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        OpenUIView(runtime: runtime)
            .environment(\.openUIMediaURL, mediaURL)
            .openUITheme(theme ?? OpenUITheme(appearance: appearance))
            .onAppear {
                isOnScreen = true
                runtime.update(response: program, isStreaming: isStreaming)
                refreshWhileShown()
            }
            .onDisappear {
                isOnScreen = false
                refreshWhileShown()
            }
            .onChange(of: program) { runtime.update(response: program, isStreaming: isStreaming) }
            .onChange(of: isStreaming) { runtime.update(response: program, isStreaming: isStreaming) }
            .onChange(of: scenePhase) { refreshWhileShown() }
    }

    // A reply off screen, or in an app in the background, doesn't keep running the host's tools.
    private func refreshWhileShown() {
        if isOnScreen && scenePhase == .active {
            runtime.queryManager.resumeRefreshes()
        } else {
            runtime.queryManager.pauseRefreshes()
        }
    }
}
