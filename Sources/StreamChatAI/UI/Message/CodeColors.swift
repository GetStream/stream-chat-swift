//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// The colors that highlighted code shows in.
@available(iOS 15.0, macOS 12.0, *)
struct CodeColors: Equatable {
    let plainText: Color
    let tokens: [TokenType: Color]

    func text(for runs: [CodeRun]) -> AttributedString {
        var text = AttributedString()
        for run in runs {
            text.append(colored(run.text, color: run.type.flatMap { tokens[$0] } ?? plainText))
        }
        return text
    }

    func plain<Code: StringProtocol>(_ code: Code) -> AttributedString {
        colored(code, color: plainText)
    }

    private func colored<Code: StringProtocol>(_ code: Code, color: Color) -> AttributedString {
        var text = AttributedString(code)
        text.foregroundColor = color
        return text
    }
}
