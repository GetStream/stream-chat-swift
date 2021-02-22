//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// This structure is a wrapper for all decodable object
/// What it does is that it stores the optional Decodable object into
/// itself. When the object is malformed, it assignes the object to base as `nil` value
/// When the value is not corrupted somehow, it stores into base and we can use it.
///
/// Use this when you are decoding objects in array and there is possibility
/// that some of the objects can be malformed in JSON. Then you should `compactMap` the array
/// For example usage, see `MessagePayload.swift` `init(from decoder:)`
struct OptionalDecodable<Base: Decodable>: Decodable {
    let base: Base?
    public init(from decoder: Decoder) throws {
        let base: Base?
        do {
            base = try Base(from: decoder)
        } catch {
            log.error("Failed to decode \(Base.self): \(error)")
            base = nil
        }
        self.base = base
    }
}
