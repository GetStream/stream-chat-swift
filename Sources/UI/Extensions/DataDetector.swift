//
//  DataDetector.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 11/11/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCore

/// A data detector worker.
/// It works in a background thread and returns the result in the completion block.
final class DataDetector {
    
    static let shared = DataDetector(types: .link)
    
    private let detector: NSDataDetector?
    
    public init(types: NSTextCheckingResult.CheckingType) {
        detector = try? NSDataDetector(types: types.rawValue)
    }
    
    /// Starts the matching in a given text.
    func matchURLs(_ text: String) -> [DataDetectorURLItem] {
        guard text.probablyHasURL, let detector = detector else {
            return []
        }
        
        var items: [DataDetectorURLItem] = []
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        
        detector.enumerateMatches(in: text, options: [], range: range) { (match, _, _) in
            guard let match = match, case .link = match.resultType, let url = match.url else {
                return
            }
            
            items.append(DataDetectorURLItem(url: url, range: match.range))
        }
        
        return items
    }
}

/// A result item of the data detection.
public struct DataDetectorURLItem {
    /// A founded URL.
    public let url: URL
    /// A range of a text of the founded URL.
    public let range: NSRange
}
