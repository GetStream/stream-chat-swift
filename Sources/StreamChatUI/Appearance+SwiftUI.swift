//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

@available(iOS 13.0, *)
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

@available(iOS 13.0, *)
/// Modifier for setting `Components` environment object.
private struct SwiftUIAppearance: ViewModifier {
    /// Custom `ObservableObject` of `components`
    private let appearance: Appearance

    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    public init(_ appearance: Appearance) {
        self.appearance = appearance
    }

    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    public func body(content: Content) -> some View {
        content.environmentObject(appearance.asObservableObject)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Sets up custom `Components`.
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    func setUpStreamChatAppearance(_ appearance: Appearance = .default) -> some View {
        modifier(SwiftUIAppearance(appearance))
    }
}
