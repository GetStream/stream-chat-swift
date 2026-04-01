//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatCommonUI
import UIKit

/// Generates a `UIImage` placeholder for a user avatar using the user's initials,
/// mirroring the fallback logic of the SwiftUI SDK's `UserAvatar.PlaceholderView`.
enum UserAvatarInitialsImage {
    private static let formatter: PersonNameComponentsFormatter = {
        let f = PersonNameComponentsFormatter()
        f.style = .abbreviated
        return f
    }()

    /// Extracts abbreviated initials from a display name.
    ///
    /// Mirrors the SwiftUI SDK's `UserAvatar.initials(from:)`:
    /// first tries `PersonNameComponentsFormatter` (works well for natural-language
    /// names), then falls back to taking the first letter of each word so that
    /// non-standard identifiers like "john_doe" or "user_123" still produce
    /// something visible.
    static func initials(from name: String) -> String {
        guard !name.isEmpty else { return "" }

        // Primary: PersonNameComponentsFormatter (same as SwiftUI SDK)
        if let components = formatter.personNameComponents(from: name) {
            let result = formatter.string(from: components)
            if !result.isEmpty { return result }
        }

        // Fallback: split on non-alphanumeric characters and take the first
        // letter of each word, upper-cased.
        let words = name
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
        let letters = words.prefix(2).compactMap { $0.first.map { String($0).uppercased() } }
        return letters.joined()
    }

    /// Renders a square `UIImage` filled with `backgroundColor` and the given
    /// `initials` centered in `textColor`.  When `initials` is empty the
    /// generic person icon is drawn instead, matching the SwiftUI
    /// `PlaceholderView` behaviour.  The image is un-clipped – the circular
    /// mask is applied by the avatar view's layer.
    static func image(
        initials: String,
        size: CGSize,
        backgroundColor: UIColor,
        textColor: UIColor,
        font: UIFont,
        fallbackIcon: UIImage? = nil
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            backgroundColor.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            if initials.isEmpty {
                // Mirror SwiftUI: show the person icon when there are no initials
                if let icon = fallbackIcon, icon.size.width > 0, icon.size.height > 0 {
                    let maxSide = size.width * 0.5
                    let scale = min(maxSide / icon.size.width, maxSide / icon.size.height)
                    let iconSize = CGSize(width: icon.size.width * scale, height: icon.size.height * scale)
                    let iconOrigin = CGPoint(
                        x: (size.width - iconSize.width) / 2,
                        y: (size.height - iconSize.height) / 2
                    )
                    let iconRect = CGRect(origin: iconOrigin, size: iconSize)
                    icon.withTintColor(textColor, renderingMode: .alwaysTemplate).draw(in: iconRect)
                }
            } else {
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: textColor
                ]
                let text = initials as NSString
                let textSize = text.size(withAttributes: attributes)
                let origin = CGPoint(
                    x: (size.width - textSize.width) / 2,
                    y: (size.height - textSize.height) / 2
                )
                text.draw(at: origin, withAttributes: attributes)
            }
        }
    }

    /// Convenience that derives font size from the rendered image dimensions.
    static func image(name: String, size: CGSize, appearance: Appearance) -> UIImage {
        let initials = String(self.initials(from: name).prefix(size.width >= 28 ? 2 : 1))
        let font = scaledFont(for: size, appearance: appearance)
        return image(
            initials: initials,
            size: size,
            backgroundColor: appearance.colorPalette.avatarBackgroundDefault,
            textColor: appearance.colorPalette.avatarTextDefault,
            font: font,
            fallbackIcon: appearance.images.userAvatarPlaceholder
        )
    }

    // MARK: - Private

    private static func scaledFont(for size: CGSize, appearance: Appearance) -> UIFont {
        let fonts = appearance.fonts
        switch size.width {
        case 56...: return fonts.title2.bold
        case 40...: return fonts.title3.bold
        case 32...: return fonts.subheadline.bold
        case 24...: return fonts.footnote.bold
        default: return fonts.caption1.bold
        }
    }
}
