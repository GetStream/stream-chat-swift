//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

private struct ElementWrapper<T: Decodable>: Decodable {
    let value: T?
    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

extension KeyedDecodingContainer {
    func decodeArrayIgnoringFailures<T: Decodable>(_ type: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] {
        let wrapper = try decode([ElementWrapper<T>].self, forKey: key)
        return wrapper.compactMap(\.value)
    }
}
