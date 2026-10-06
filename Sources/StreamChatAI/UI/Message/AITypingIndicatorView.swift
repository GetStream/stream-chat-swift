//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct AITypingIndicatorView: View {
    @State private var animate = false
    
    var text: String
    
    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 5) {
            Text(text)
            ForEach(0..<3) { i in
                Circle()
                    .frame(width: 8, height: 8)
                    .scaleEffect(animate ? 1 : 0.5)
                    .opacity(animate ? 1 : 0.3)
                    .animation(
                        Animation.easeInOut(duration: 0.8)
                            .repeatForever()
                            .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
        .onAppear {
            animate = true
        }
    }
}
