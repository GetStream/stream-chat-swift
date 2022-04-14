//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

extension String {
    
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
        "<p>\(self)</p>\n"
    }
    
}
