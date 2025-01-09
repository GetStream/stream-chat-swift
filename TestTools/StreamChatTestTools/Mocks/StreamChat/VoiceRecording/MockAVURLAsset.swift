//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation

@dynamicMemberLookup
public final class MockAVURLAsset: AVURLAsset, Spy, Stub, @unchecked Sendable {

    public let spyState = SpyState()
    public var stubbedProperties: [String: Any] = [:]

    public var statusOfValueResultMap: [String: AVKeyValueStatus] = [:]
    public var statusOfValueErrorMap: [String: Error] = [:]

    public private(set) var loadValuesAsynchronouslyWasCalledWithKeys: [String]?

    public override var duration: CMTime {
        get { self[dynamicMember: \.duration] }
    }

    public override func statusOfValue(
        forKey key: String,
        error outError: NSErrorPointer
    ) -> AVKeyValueStatus {
        spyState.record("statusOfValue(\(key))")
        outError?.pointee = statusOfValueErrorMap[key] as? NSError
        return statusOfValueResultMap[key] ?? super.statusOfValue(forKey: key, error: outError)
    }

    public override func loadValuesAsynchronously(
        forKeys keys: [String],
        completionHandler handler: (() -> Void)? = nil
    ) {
        loadValuesAsynchronouslyWasCalledWithKeys = keys
        handler?()
    }
}
