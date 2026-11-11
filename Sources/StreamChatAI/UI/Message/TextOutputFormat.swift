//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
struct TextOutputFormat: OutputFormat {
    private let theme: SplashTheme
    
    init(theme: SplashTheme) {
        self.theme = theme
    }
    
    func makeBuilder() -> Builder {
        Builder(theme: self.theme)
    }
}

@available(iOS 15.0, macOS 12.0, *)
extension TextOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: SplashTheme
        private var accumulatedText: [Text]
        
        fileprivate init(theme: SplashTheme) {
            self.theme = theme
            self.accumulatedText = []
        }
        
        mutating func addToken(_ token: String, ofType type: TokenType) {
            let color = self.theme.tokenColors[type] ?? self.theme.plainTextColor
            self.accumulatedText.append(Text(token).foregroundColor(.init(uiColor: color)))
        }
        
        mutating func addPlainText(_ text: String) {
            self.accumulatedText.append(
                Text(text).foregroundColor(.init(uiColor: self.theme.plainTextColor))
            )
        }
        
        mutating func addWhitespace(_ whitespace: String) {
            self.accumulatedText.append(Text(whitespace))
        }
        
        func build() -> Text {
            self.accumulatedText.reduce(Text(""), +)
        }
    }
}
