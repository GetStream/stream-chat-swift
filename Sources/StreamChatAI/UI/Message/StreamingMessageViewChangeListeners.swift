//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct StreamingMessageViewChangeListeners: ViewModifier {
    // Before iOS 17 `onChange` doesn't pass the old text, so the modifier keeps it. It starts
    // as the text the view appeared with, which the view has already queued.
    @State var previousValue: String
    
    var text: String
    var isGenerating: Bool
    
    var onContentChange: (_ oldValue: String, _ newValue: String) -> Void
    var onIsGeneratingChange: (_ oldValue: Bool, _ newValue: Bool) -> Void

    init(
        text: String,
        isGenerating: Bool,
        onContentChange: @escaping (_ oldValue: String, _ newValue: String) -> Void,
        onIsGeneratingChange: @escaping (_ oldValue: Bool, _ newValue: Bool) -> Void
    ) {
        _previousValue = State(initialValue: text)
        self.text = text
        self.isGenerating = isGenerating
        self.onContentChange = onContentChange
        self.onIsGeneratingChange = onIsGeneratingChange
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content
                .onChange(of: text) { oldValue, newValue in
                    onContentChange(oldValue, newValue)
                }
                .onChange(of: isGenerating) { oldValue, newValue in
                    onIsGeneratingChange(oldValue, newValue)
                }
        } else {
            content
                .onChange(of: text) { newValue in
                    onContentChange(previousValue, newValue)
                    previousValue = newValue
                }
                .onChange(of: isGenerating) { newValue in
                    onIsGeneratingChange(!newValue, newValue)
                }
        }
    }
}

extension View {
    func addChangeListeners(
        content: String,
        isGenerating: Bool,
        onContentChange: @escaping (_ oldValue: String, _ newValue: String) -> Void,
        onIsGeneratingChange: @escaping (_ oldValue: Bool, _ newValue: Bool) -> Void
    ) -> some View {
        self.modifier(
            StreamingMessageViewChangeListeners(
                text: content,
                isGenerating: isGenerating,
                onContentChange: onContentChange,
                onIsGeneratingChange: onIsGeneratingChange
            )
        )
    }
}
