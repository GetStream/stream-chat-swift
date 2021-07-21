//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    // Allows to use fonts from Appearance for attributed strings rendered from markdown
    // preserving traits (italic, bold, mono etc.)
    func with(font: UIFont) -> NSMutableAttributedString {
        enumerateAttribute(
            NSAttributedString.Key.font,
            in: NSMakeRange(0, length),
            options: .longestEffectiveRangeNotRequired,
            using: { (value, range, _) in
                guard let originalFont = value as? UIFont else { return }
                if let newFont = applyTraitsFromFont(originalFont, to: font) {
                    self.addAttribute(NSAttributedString.Key.font, value: newFont, range: range)
                }
            }
        )
        return self
    }
    
    func applyForegroundColor(_ color: UIColor) {
        addAttributes(
            [.foregroundColor: color],
            range: NSMakeRange(0, length)
        )
    }
    
    private func applyTraitsFromFont(_ font1: UIFont, to font2: UIFont) -> UIFont? {
        let originalTrait = font1.fontDescriptor.symbolicTraits
        var traits = font2.fontDescriptor.symbolicTraits
        
        let traitsToPreserve: [UIFontDescriptor.SymbolicTraits] = [
            .traitBold,
            .traitItalic,
            .traitMonoSpace
        ]
        
        traitsToPreserve.forEach {
            if originalTrait.contains($0) {
                traits.insert($0)
            }
        }
        
        if let fontDescriptor = font2.fontDescriptor.withSymbolicTraits(traits) {
            return UIFont(descriptor: fontDescriptor, size: 0)
        }
        
        return font2
    }
}
