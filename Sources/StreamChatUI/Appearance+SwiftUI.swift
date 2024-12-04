//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

extension Appearance {
    /// Used to initialize `Components` as `ObservableObject`.
    public var asObservableObject: ObservableObject { .init(self) }

    @dynamicMemberLookup
    /// `Components` represented as `ObservableObject` class for SwiftUI requirements.
    public class ObservableObject: SwiftUI.ObservableObject {
        private let wrappedAppearance: Appearance

        public subscript<T>(dynamicMember keyPath: KeyPath<Appearance, T>) -> T {
            wrappedAppearance[keyPath: keyPath]
        }

        fileprivate init(_ wrappedAppearance: Appearance) {
            self.wrappedAppearance = wrappedAppearance
        }
    }
}

/// Modifier for setting `Components` environment object.
private struct SwiftUIAppearance: ViewModifier {
    /// Custom `ObservableObject` of `components`
    private let appearance: Appearance

    public init(_ appearance: Appearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content.environmentObject(appearance.asObservableObject)
    }
}

public extension View {
    /// Sets up custom `Components`.
    func setUpStreamChatAppearance(_ appearance: Appearance = .default) -> some View {
        modifier(SwiftUIAppearance(appearance))
    }
}
