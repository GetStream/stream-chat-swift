//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SwiftUI

struct FilterButtonStyle: ButtonStyle {
    let isSelected: Bool
    let backgroundColor: Color?
    let foregroundColor: Color?

    init(isSelected: Bool, backgroundColor: Color? = nil, foregroundColor: Color? = nil) {
        self.isSelected = isSelected
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                backgroundColor ?? (isSelected ? Color.accentColor : Color.gray.opacity(0.2))
            )
            .foregroundColor(
                foregroundColor ?? (isSelected ? .white : .primary)
            )
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
