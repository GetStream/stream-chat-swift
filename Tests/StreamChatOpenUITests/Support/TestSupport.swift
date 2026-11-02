//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI

/// Anchor class used to locate the test bundle's resources.
final class TestBundleToken {}

enum Fixtures {
    static var bundle: Bundle { Bundle(for: TestBundleToken.self) }

    static func url(_ name: String) -> URL? {
        let base = (name as NSString).deletingPathExtension
        let ext = (name as NSString).pathExtension
        return bundle.url(forResource: base, withExtension: ext)
            ?? bundle.url(forResource: base, withExtension: ext, subdirectory: "Fixtures")
    }

    static func data(_ name: String) throws -> Data {
        guard let url = url(name) else {
            throw FixtureError.missing(name)
        }
        return try Data(contentsOf: url)
    }

    static func json(_ name: String) throws -> OpenUIValue {
        try OpenUIJSON.parse(data(name))
    }

    enum FixtureError: Error {
        case missing(String)
    }
}

/// Describes the first structural difference between two values (nil when equal).
func firstDifference(_ actual: OpenUIValue, _ expected: OpenUIValue, path: String = "$") -> String? {
    switch (actual, expected) {
    case (.object(let a), .object(let b)):
        let missing = b.keys.filter { !a.contains($0) }
        if let key = missing.first {
            return "\(path).\(key): missing (expected \(b[key]!))"
        }
        let extra = a.keys.filter { !b.contains($0) }
        if let key = extra.first {
            return "\(path).\(key): unexpected \(a[key]!)"
        }
        for key in b.keys {
            if let difference = firstDifference(a[key]!, b[key]!, path: "\(path).\(key)") {
                return difference
            }
        }
        return nil
    case (.array(let a), .array(let b)):
        for index in 0..<min(a.count, b.count) {
            if let difference = firstDifference(a[index], b[index], path: "\(path)[\(index)]") {
                return difference
            }
        }
        if a.count != b.count {
            return "\(path): count \(a.count) != expected \(b.count)"
        }
        return nil
    default:
        return actual == expected ? nil : "\(path): \(actual) != expected \(expected)"
    }
}
