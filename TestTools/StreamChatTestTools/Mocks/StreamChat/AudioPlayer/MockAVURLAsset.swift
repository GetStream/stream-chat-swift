//
//  MockAsset.swift
//  StreamChatTests
//
//  Created by Ilias Pavlidakis on 21/3/23.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

public protocol Stub: AnyObject {
    var stubbedProperties: [String: Any] { get set }

    func stubProperty<T>(_ keyPath: KeyPath<Self, T>, with value: T)
    func removePropertyStub<T>(_ keyPath: KeyPath<Self, T>)
}

extension Stub {
    public func stubProperty<T>(
        _ keyPath: KeyPath<Self, T>,
        with value: T
    ) {
        let keyPathName = NSExpression(forKeyPath: keyPath).keyPath
        stubbedProperties[keyPathName] = value
    }

    public func removePropertyStub<T>(
        _ keyPath: KeyPath<Self, T>
    ) {
        let keyPathName = NSExpression(forKeyPath: keyPath).keyPath
        stubbedProperties[keyPathName] = nil
    }

    subscript<T>(
        dynamicMember keyPath: KeyPath<Self, T>
    ) -> T {
        let keyPathName = NSExpression(forKeyPath: keyPath).keyPath
        return (stubbedProperties[keyPathName] as? T) ?? self[keyPath: keyPath]
    }
}

@dynamicMemberLookup
public final class MockAVURLAsset: AVURLAsset, Spy, Stub {

    public var recordedFunctions: [String] = []
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
        recordedFunctions.append("statusOfValue(\(key))")
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
