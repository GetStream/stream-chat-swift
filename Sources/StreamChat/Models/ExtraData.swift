//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

/// A parent protocol for all extra data protocols. Not meant to be adopted directly.
public protocol ExtraData: Codable & Hashable {
    /// Returns an `ExtraData` instance with default parameters.
    static var defaultValue: Self { get }
}

/// A type representing no extra data for the given model object.
public struct NoExtraData: Codable,
    Hashable,
    ChannelExtraData,
    MessageExtraData,
    ExtraDataTypes {
    /// Returns a concrete `NoExtraData` instance.
    public static var defaultValue: Self { .init() }
}
