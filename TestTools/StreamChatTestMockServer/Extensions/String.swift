//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import XCTest

public extension String {
    
    var json: [String: Any] {
        try! JSONSerialization.jsonObject(with: Data(self.utf8),
                                          options: .mutableContainers) as! [String: Any]
    }

    func replace(_ target: String, to: String) -> String {
        replacingOccurrences(of: target,
                             with: to,
                             options: NSString.CompareOptions.literal,
                             range: nil)
    }
    
    var html: Self {
        self.isEmpty ? "" : "<p>\(self)</p>\n"
    }

}

public extension Substring {
    func capitalizingFirstLetter() -> Substring {
        prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
