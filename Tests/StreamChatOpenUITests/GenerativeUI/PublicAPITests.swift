//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import StreamChatOpenUI
import SwiftUI
import Testing

// What an app can use without @testable: the renderer, its theme and errors, and restyling the
// library's components.
@MainActor
@Suite("OpenUI public API")
struct PublicAPITests {
    @Test func anAppConfiguresTheRendererAndRestylesAComponent() {
        var theme = OpenUITheme(appearance: AIAppearance())
        theme.colors.accent = .orange
        let library = ComponentLibrary.openUIChat
            .replacingView(of: .button) { context in
                context.defaultView.tint(.orange)
            }
            .removing(["Steps"])
        var errors: [OpenUIError] = []

        let renderer = OpenUIRenderer(
            library: library,
            instructions: "Show places as cards.",
            theme: theme,
            mediaURL: { $0.host == "cdn.example" ? $0 : nil },
            onError: { error, _ in errors.append(error) }
        )

        #expect(renderer.library.componentNames.contains("Button"))
        #expect(!renderer.library.componentNames.contains("Steps"))
        #expect(OpenUIComponentName.button.rawValue == "Button")
        #expect(errors.isEmpty)
    }
}
