//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI
import Combine

@available(iOS 13.0, *)
extension Components {
    /// Used to initialize `Components` as `ObservableObject`.
    public var asObservableObject: ObservableObject { .init(self) }

    @dynamicMemberLookup
    /// `Components` represented as `ObservableObject` class for SwiftUI requirements.
    public class ObservableObject: SwiftUI.ObservableObject {
        private let wrappedComponents: Components

        public subscript<T>(dynamicMember keyPath: KeyPath<Components, T>) -> T {
            wrappedComponents[keyPath: keyPath]
        }

        fileprivate init(_ wrappedComponents: Components) {
            self.wrappedComponents = wrappedComponents
        }
    }
}

@available(iOS 13.0, *)
/// Modifier for setting `Components` environment object.
private struct SwiftUIComponents: ViewModifier {
    /// Custom `ObservableObject` of `components`
    private let components: Components

    public init(_ components: Components) {
        self.components = components
    }

    public func body(content: Content) -> some View {
        content.environmentObject(components.asObservableObject)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Sets up custom `Components`.
    func setUpStreamChatComponents(
        _ components: Components = .default
    ) -> some View {
        modifier(SwiftUIComponents(components))
    }

    func setUpStreamChatComponents() -> some View {
        modifier(SwiftUIComponents(.default))
    }
}
