//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
extension _UIConfig {

    /// Used to initialize `_UIConfig` as `ObservableObject`.
    public var asObservableObject: ObservableObject { .init(self) }

    @dynamicMemberLookup
    /// `_UIConfig` represented as `ObservableObject` class for SwiftUI requirements.
    public class ObservableObject: SwiftUI.ObservableObject {

        private let wrappedConfig: _UIConfig<ExtraData>

        public subscript<T>(dynamicMember keyPath: KeyPath<_UIConfig<ExtraData>, T>) -> T {
            wrappedConfig[keyPath: keyPath]
        }

        fileprivate init(_ wrappedConfig: _UIConfig<ExtraData>) {
            self.wrappedConfig = wrappedConfig
        }
    }
}

@available(iOS 13.0, *)
/// Modifier for setting `UIConfig` environment object.
private struct SwiftUIEnvironment<ExtraData: ExtraDataTypes>: ViewModifier {
    /// Custom `ObservableObject` of `UIConfig`
    private let config: _UIConfig<ExtraData>

    public init(_ config: _UIConfig<ExtraData>) {
        self.config = config
    }

    public func body(content: Content) -> some View {
        content.environmentObject(config.asObservableObject)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Sets up custom `UIConfig`.
    func setUpStreamChatUIConfig<ExtraData: ExtraDataTypes>(
        _ config: _UIConfig<ExtraData> = .default
    ) -> some View {
        self.modifier(SwiftUIEnvironment<ExtraData>(config))
    }

    func setUpStreamChatUIConfig() -> some View {
        self.modifier(SwiftUIEnvironment<NoExtraData>(.default))
    }
}
