//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import os

func signpost(_ object: AnyObject, _ name: StaticString, _ type: OSSignpostType, _ message: @autoclosure () -> String) {}

func signpost<T>(_ name: StaticString, _ work: () throws -> T) rethrows -> T {
    try work()
}

private let nukeLog = NukeAtomic(value: OSLog(subsystem: "com.github.kean.Nuke.ImagePipeline", category: "Image Loading"))

enum Formatter {
    static func bytes(_ count: Int) -> String {
        bytes(Int64(count))
    }

    static func bytes(_ count: Int64) -> String {
        ByteCountFormatter().string(fromByteCount: count)
    }
}
