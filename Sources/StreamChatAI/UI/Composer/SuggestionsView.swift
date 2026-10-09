//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

public struct SuggestionsView: View {
    var suggestions: [String]
    var height: CGFloat
    var itemMaxWidth: CGFloat
    var onMessageSend: (MessageData) -> Void
    
    public init(
        suggestions: [String],
        height: CGFloat = 100,
        itemMaxWidth: CGFloat = 160,
        onMessageSend: @escaping (MessageData) -> Void
    ) {
        self.suggestions = suggestions
        self.height = height
        self.itemMaxWidth = itemMaxWidth
        self.onMessageSend = onMessageSend
    }
    
    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(suggestions, id: \.self) { option in
                    Button {
                        onMessageSend(.init(text: option))
                    } label: {
                        Text(option)
                            .font(fonts.suggestion)
                            .foregroundColor(Color(colors.suggestionText))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: itemMaxWidth)
                            .padding()
                            .background(Color(colors.suggestionBackground))
                            .cornerRadius(layout.radiusXl)
                    }
                }
            }
            .padding()
        }
        .frame(height: height)
    }
}
