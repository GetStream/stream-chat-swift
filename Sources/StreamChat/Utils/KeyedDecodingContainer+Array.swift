//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

private struct ElementWrapper<T: Decodable>: Decodable {
    let value: T?
    var error: Error?
    init(from decoder: Decoder) throws {
        do {
            value = try T(from: decoder)
        } catch {
            value = nil
            self.error = error
        }
    }
}

extension KeyedDecodingContainer {
    func decodeArrayIgnoringFailures<T: Decodable>(_ type: [T].Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> [T] {
        let wrapper = try decode([ElementWrapper<T>].self, forKey: key)
        let errors = wrapper.compactMap(\.error)
        if !errors.isEmpty {
            let errorsDescription = errors.map(String.init(describing:))
            log.error("Failed decoding elements from array: \(errorsDescription)", subsystems: .httpRequests)
        }
        return wrapper.compactMap(\.value)
    }
}
