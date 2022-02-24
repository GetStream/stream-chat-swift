//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import SwiftUI

@available(iOS 13.0, *)
extension Appearance {
    /// Used to initialize `_Components` as `ObservableObject`.
    public var asObservableObject: ObservableObject { .init(self) }

    @dynamicMemberLookup
    /// `_Components` represented as `ObservableObject` class for SwiftUI requirements.
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

    public init(_ appearance: Appearance) {
        self.appearance = appearance
    }

    public func body(content: Content) -> some View {
        content.environmentObject(appearance.asObservableObject)
    }
}

@available(iOS 13.0, *)
public extension View {
    /// Sets up custom `Components`.
    func setUpStreamChatAppearance(_ appearance: Appearance = .default) -> some View {
        modifier(SwiftUIAppearance(appearance))
    }
}

@available(iOS 13.0, *)
extension Color {
    init(hexString: String, alpha: Double = 1, darker percentage: Double = 0) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(hex: Int(int), alpha: alpha, darker: percentage)
    }

    init(hex: Int, alpha: Double = 1, darker percentage: Double = 0.0) {
        let components = (
            R: Double((hex >> 16) & 0xff) / 255,
            G: Double((hex >> 08) & 0xff) / 255,
            B: Double((hex >> 00) & 0xff) / 255
        )

        let multiplier = percentage / 100.0
        let newRed = min(max(components.R + multiplier * components.R, 0.0), 1.0)
        let newGreen = min(max(components.G + multiplier * components.G, 0.0), 1.0)
        let newBlue = min(max(components.B + multiplier * components.B, 0.0), 1.0)

        self.init(
            .sRGB,
            red: newRed,
            green: newGreen,
            blue: newBlue,
            opacity: alpha
        )
    }
}
