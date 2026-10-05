//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct SuggestionsView: View {
    var suggestions: [String]
    var height: CGFloat
    var itemMaxWidth: CGFloat
    private let colors: Colors
    var onMessageSend: (MessageData) -> Void
    
    public init(
        suggestions: [String],
        height: CGFloat = 100,
        itemMaxWidth: CGFloat = 160,
        colors: Colors = Colors(),
        onMessageSend: @escaping (MessageData) -> Void
    ) {
        self.suggestions = suggestions
        self.height = height
        self.itemMaxWidth = itemMaxWidth
        self.colors = colors
        self.onMessageSend = onMessageSend
    }
    
    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(suggestions, id: \.self) { option in
                    Button {
                        onMessageSend(.init(text: option))
                    } label: {
                        Text(option)
                            .font(.subheadline)
                            .foregroundColor(colors.suggestions.text)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: itemMaxWidth)
                            .padding()
                            .background(colors.suggestions.background)
                            .cornerRadius(16)
                    }
                }
            }
            .padding()
        }
        .frame(height: height)
    }
}
