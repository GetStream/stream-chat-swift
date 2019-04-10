//
//  DataDetectorWorker.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A data detector worker.
/// It works in a background thread and returns the result in the completion block.
public final class DataDetectorWorker {
    /// A completion block.
    public typealias Completion = (_ urls: [DataDetectorURLItem]) -> Void
    
    private let detector: NSDataDetector
    private let dispatchQueue = DispatchQueue(label: "io.getstream.DataDetectorWorker")
    private let completion: Completion
    private let callbackQueue: DispatchQueue
    
    public init(types: NSTextCheckingResult.CheckingType,
                callbackQueue: DispatchQueue = .main,
                completion: @escaping Completion) throws {
        detector = try NSDataDetector(types: types.rawValue)
        self.completion = completion
        self.callbackQueue = callbackQueue
    }
    
    /// Starts the matching in a given text.
    public func match(_ text: String) {
        dispatchQueue.async { [weak self] in self?.matchInBackground(text) }
    }
    
    private func matchInBackground(_ text: String) {
        var urls: [DataDetectorURLItem] = []
        let matches: [NSTextCheckingResult] = detector.matches(in: text,
                                                               options: [],
                                                               range: NSRange(location: 0, length: text.utf16.count))
        
        for match in matches {
            guard let range = Range(match.range, in: text) else {
                continue
            }
            
            var urlString = String(text[range])
            
            if urlString.hasPrefix("//") {
                urlString = "https:\(urlString)"
            }
            
            if !urlString.lowercased().hasPrefix("http") {
                urlString = "https://\(urlString)"
            }
            
            if let url = URL(string: urlString) {
                urls.append(DataDetectorURLItem(url: url, range: range))
            }
        }
        
        callbackQueue.async { [weak self] in self?.completion(urls) }
    }
}

/// A result item of the data detection.
public struct DataDetectorURLItem {
    /// A founded URL.
    public let url: URL
    /// A range of a text of the founded URL.
    public let range: Range<String.Index>
}
