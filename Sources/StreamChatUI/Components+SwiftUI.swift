//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import StreamChat
import SwiftUI

@available(iOS 13.0, *)
extension Components {
    /// Used to initialize `Components` as `ObservableObject`.
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    public var asObservableObject: ObservableObject { .init(self) }

    @dynamicMemberLookup
    /// `Components` represented as `ObservableObject` class for SwiftUI requirements.
    public class ObservableObject: SwiftUI.ObservableObject {
        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        private let wrappedComponents: Components

        public subscript<T>(dynamicMember keyPath: KeyPath<Components, T>) -> T {
            wrappedComponents[keyPath: keyPath]
        }

        @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
        fileprivate init(_ wrappedComponents: Components) {
            self.wrappedComponents = wrappedComponents
        }
    }
}

@available(iOS 13.0, *)
/// Modifier for setting `Components` environment object.
private struct SwiftUIComponents: ViewModifier {
    /// Custom `ObservableObject` of `components`
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    private let components: Components

    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    public init(_ components: Components) {
        self.components = components
    }

    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    public func body(content: Content) -> some View {
        content.environmentObject(components.asObservableObject)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Sets up custom `Components`.
    @available(*, deprecated, message: "This is now deprecated, please refer to the SwiftUI SDK at https://github.com/GetStream/stream-chat-swiftui")
    func setUpStreamChatComponents(
        _ components: Components = .default
    ) -> some View {
        modifier(SwiftUIComponents(components))
    }

    func setUpStreamChatComponents() -> some View {
        modifier(SwiftUIComponents(.default))
    }
}
