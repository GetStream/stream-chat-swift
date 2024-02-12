//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The link details found in text.
public struct TextLink: Equatable {
    /// The url of the link.
    public let url: URL
    /// The original text.
    public let originalText: String
    /// The position where the link was found.
    public let range: NSRange
}

/// An object responsible to detect and parse links in text.
public class TextLinkDetector {
    private let detector: NSDataDetector?

    public init() {
        let types: NSTextCheckingResult.CheckingType = [.link]
        do {
            detector = try NSDataDetector(types: types.rawValue)
        } catch {
            detector = nil
            assertionFailure("Data detector failed to be created in \(self)")
        }
    }

    /// Checks if the provided text contains links or not.
    /// - Parameter text: The string representing the provided text.
    /// - Returns: A boolean value indicating if it contains link or not.
    public func hasLinks(in text: String) -> Bool {
        firstLink(in: text) != nil
    }

    /// Parses the first link of the provided text.
    /// - Parameter text: The string representing the provided text.
    /// - Returns: The first link found in the text. Contains the url and the location of the link.
    public func firstLink(in text: String) -> TextLink? {
        detector?
            .firstMatch(in: text, range: fullRange(of: text))?
            .toTextLink(with: text)
    }

    /// Parses all the links found of the provided text.
    /// - Parameter text: The string representing the provided text.
    /// - Returns: An array of the parsed links that contain the url and the location of the link.
    public func links(in text: String) -> [TextLink] {
        guard let detector = self.detector else { return [] }
        let matches = detector.matches(in: text, options: [], range: fullRange(of: text))
        return matches.compactMap { $0.toTextLink(with: text) }
    }

    private func fullRange(of text: String) -> NSRange {
        // utf16 is used to make sure every char counts as 1 independent of special symbols.
        // Example: João
        //    utf16.count == 4
        //    utf8.count == 5
        NSRange(location: 0, length: text.utf16.count)
    }
}

private extension NSTextCheckingResult {
    /// Maps a match to `TextLink`.
    func toTextLink(with text: String) -> TextLink? {
        guard let range = Range(self.range, in: text) else { return nil }
        let linkText = String(text[range])
        guard let url = self.url else { return nil }
        return TextLink(url: url, originalText: linkText, range: self.range)
    }
}
