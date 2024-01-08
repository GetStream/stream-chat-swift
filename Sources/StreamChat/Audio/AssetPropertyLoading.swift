//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// A simple type that describes the domain cancelled errors an instance of AssetPropertyLoading can return
public struct AssetPropertyLoadingCancelledError: Error {
    /// The property for which the loading cancelled
    public let property: AssetProperty

    /// Initialises a new instance of the error
    /// - Parameter property: The property for which the error was occurred during loading
    public init(_ property: AssetProperty) {
        self.property = property
    }

    public var localizedDescription: String? {
        "Loading of asset's \(property) property cancelled"
    }
}

/// A simple type that describes the domain specific errors an instance of AssetPropertyLoading can return
public struct AssetPropertyLoadingFailedError: Error {
    /// The property for which the loading failed
    public let property: AssetProperty

    /// The error which occurred during loading, if nil the failure occurred due to an unknown error
    public var error: Error?

    /// The property for which the error was generated. The instance will additionally include the original
    /// error (if any)
    /// - Parameters:
    ///   - property: The property for which the error was generated
    ///   - error: The error that was occurred during loading or nil if an unknown error occurred
    init(_ property: AssetProperty, error: Error?) {
        self.property = property
        self.error = error
    }

    public var localizedDescription: String? {
        if let error = error {
            return "Loading of asset's \(property) property failed with error \(error)"
        } else {
            return "Loading of asset's \(property) property failed due to an unknown error."
        }
    }
}

/// A composite type that will be returned on the completion of a loading request. It will contain the errors
/// that occurred for each property that we tried to load but failed.
public struct AssetPropertyLoadingCompositeError: Error {
    /// An array containing the errors for the properties that failed
    public let failedProperties: [AssetPropertyLoadingFailedError]

    /// An array containing the errors for the properties that were cancelled
    public let cancelledProperties: [AssetPropertyLoadingCancelledError]

    public init(
        failedProperties: [AssetPropertyLoadingFailedError],
        cancelledProperties: [AssetPropertyLoadingCancelledError]
    ) {
        self.failedProperties = failedProperties
        self.cancelledProperties = cancelledProperties
    }

    public var errorDescription: String? {
        "Loading of \(cancelledProperties.count) properties was cancelled and the loading of \(failedProperties.count) failed with various errors."
    }
}

/// Defines a type that represents the properties of an asset that can be loaded
public struct AssetProperty: CustomStringConvertible {
    /// The property's name
    public var name: String

    /// Initialises a new instance from a typed keyPath
    public init<Asset: AVAsset, Value>(_ keyPath: KeyPath<Asset, Value>) {
        name = NSExpression(forKeyPath: keyPath).keyPath
    }

    public var description: String { name }
}

/// A protocol that describes an object that can be used to load properties from an AVAsset
public protocol AssetPropertyLoading {
    /// A method that loads the property of an AVAsset asynchronously and
    /// returns a result through a completion handler
    /// - Parameters:
    ///   - properties: An array containing the properties we would like to load
    ///   - asset: The asset on which we will try to load the provided properties
    ///   - completion: The closure to call when we have a final result to report (success or failure)
    func loadProperties<Asset: AVAsset>(
        _ properties: [AssetProperty],
        of asset: Asset,
        completion: @escaping (Result<Asset, AssetPropertyLoadingCompositeError>) -> Void
    )
}

/// A concrete implementation of `AssetPropertyLoading`
public struct StreamAssetPropertyLoader: AssetPropertyLoading {
    public init() {}

    public func loadProperties<Asset: AVAsset>(
        _ properties: [AssetProperty],
        of asset: Asset,
        completion: @escaping (Result<Asset, AssetPropertyLoadingCompositeError>) -> Void
    ) {
        // it's worth noting here that according to the documentation, the completion
        // handler will be invoked only once, regardless of the number of
        // properties we are loading.
        // https://developer.apple.com/documentation/avfoundation/avasynchronouskeyvalueloading/1387321-loadvaluesasynchronously
        asset.loadValuesAsynchronously(forKeys: properties.map(\.name)) {
            handlePropertiesLoadingResult(
                properties,
                of: asset,
                completion: completion
            )
        }
    }

    /// A private method that handles the result of loading the properties of an AVURLAsset and returns a
    /// result through a completion handler
    private func handlePropertiesLoadingResult<Asset: AVAsset>(
        _ properties: [AssetProperty],
        of asset: Asset,
        completion: @escaping (Result<Asset, AssetPropertyLoadingCompositeError>) -> Void
    ) {
        var failedProperties: [AssetPropertyLoadingFailedError] = []
        var cancelledProperties: [AssetPropertyLoadingCancelledError] = []

        properties.forEach { property in
            var error: NSError?
            let statusOfValue = asset.statusOfValue(
                forKey: property.name,
                error: &error
            )

            /// Handle the status of the loaded property and call the appropriate completion handler
            switch statusOfValue {
            case .loading, .loaded:
                /// Do nothing if the property is still loading or it has been loaded successfully
                break
            case .cancelled:
                /// If loading the property was cancelled, call the completion handler with a failure result
                /// and the appropriate cancelled error
                cancelledProperties.append(.init(property))
            case .failed:
                /// If loading the property failed, call the completion handler with a failure result and
                /// the associated error if any
                failedProperties.append(
                    AssetPropertyLoadingFailedError(property, error: error)
                )
            case .unknown:
                fallthrough
            @unknown default:
                /// If the status of the loaded property is unknown or any unhandled case, call the
                /// completion handler with a failure result and an unknown error.
                failedProperties.append(.init(property, error: nil))
            }
        }

        if failedProperties.isEmpty, cancelledProperties.isEmpty {
            return completion(.success(asset))
        } else {
            return completion(
                .failure(AssetPropertyLoadingCompositeError(
                    failedProperties: failedProperties,
                    cancelledProperties: cancelledProperties
                )))
        }
    }
}
