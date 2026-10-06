//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public extension StreamingReasoningView {
    /// Shows a reasoning step: its live `text` when the app has it, otherwise the step's
    /// preview, with its summary beside "Thought for 12s" once it is done.
    init(
        part: AIReasoningPart,
        text: String? = nil,
        footnote: String? = nil,
        font: Font? = nil
    ) {
        self.init(
            text: text ?? part.preview ?? part.summary ?? "",
            isThinking: part.isStreaming,
            duration: part.duration,
            summary: part.summary,
            footnote: footnote,
            font: font
        )
    }
}
