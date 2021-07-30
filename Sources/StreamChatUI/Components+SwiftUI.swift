//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
extension _Components {
    /// Used to initialize `_Components` as `ObservableObject`.
    public var asObservableObject: ObservableObject { .init(self) }

    @dynamicMemberLookup
    /// `_Components` represented as `ObservableObject` class for SwiftUI requirements.
    public class ObservableObject: SwiftUI.ObservableObject {
        private let wrappedComponents: _Components<ExtraData>

        public subscript<T>(dynamicMember keyPath: KeyPath<_Components<ExtraData>, T>) -> T {
            wrappedComponents[keyPath: keyPath]
        }

        fileprivate init(_ wrappedComponents: _Components<ExtraData>) {
            self.wrappedComponents = wrappedComponents
        }
    }
}

@available(iOS 13.0, *)
/// Modifier for setting `Components` environment object.
private struct SwiftUIComponents: ViewModifier {
    /// Custom `ObservableObject` of `components`
    private let components: _Components<ExtraData>

    public init(_ components: _Components<ExtraData>) {
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
        _ components: _Components<ExtraData> = .default
    ) -> some View {
        modifier(SwiftUIComponents<ExtraData>(components))
    }

    func setUpStreamChatComponents() -> some View {
        modifier(SwiftUIComponents<NoExtraData>(.default))
    }
}
