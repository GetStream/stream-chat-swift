//
//  URL+Extensions.swift
//  StreamChatClient
//
//  Created by Alexey Bukhtin on 04/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

extension URL {
    
    static let placeholder = URL(string: "http://example.com")!
    
    /// Removes a front-end default SVG image. iOS doesn't support SVG by default.
    func removingRandomSVG() -> URL? {
        absoluteString.contains("random_svg") ? nil : self
    }
}
