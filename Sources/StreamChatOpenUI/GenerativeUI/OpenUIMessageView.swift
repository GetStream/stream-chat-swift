//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// A reply's UI, which follows its program as the agent writes it.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIMessageView: View {
    let runtime: OpenUIRuntime
    let program: String
    let isStreaming: Bool

    var body: some View {
        OpenUIView(runtime: runtime)
            .onAppear { runtime.update(response: program, isStreaming: isStreaming) }
            .onChange(of: program) { runtime.update(response: program, isStreaming: isStreaming) }
            .onChange(of: isStreaming) { runtime.update(response: program, isStreaming: isStreaming) }
    }
}
