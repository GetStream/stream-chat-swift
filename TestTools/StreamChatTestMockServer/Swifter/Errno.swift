//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public class Errno {
    public class func description() -> String {
        // https://forums.developer.apple.com/thread/113919
        return String(cString: strerror(errno))
    }
}
