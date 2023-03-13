//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Defines a type that represents the properties of an asset that can be request for loading
public enum AssetProperty: String {
    case duration
}

/// A simple type that describes the domain specific errors an instance of AssetPropertyLoading can return
public enum AssetPropertyLoadingError: LocalizedError, Equatable {
    case unknown
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .unknown:
            return "[\(type(of: self))] Asset's property loading failed with due to an unknown error"
        case .cancelled:
            return "[\(type(of: self))] Asset's property loading was cancelled"
        }
    }
}

/// A protocol that describes an object that can be used to load properties from an AVURLAsset
public protocol AssetPropertyLoading {
    /// A method that loads the property of an AVURLAsset asynchronously and
    /// returns a result through a completion handler
    ///
    /// - Parameters:
    /// - property: The property to load
    /// - asset: The asset on which we will try to load the provided property
    /// - onSuccessTransformer: If the load succeeds then the onSuccessTransformer
    /// will be called, to provide the value to pass on the completion closure
    /// - completion: The closure to call when we have final result to
    /// report (success or failure)
    func loadProperty<Value>(
        _ property: AssetProperty,
        of asset: AVURLAsset,
        onSuccessTransformer: @escaping (AVURLAsset) -> Value,
        completion: @escaping (Result<Value, Error>) -> Void
    )
}

public struct StreamAssetPropertyLoader: AssetPropertyLoading {
    public func loadProperty<Value>(
        _ property: AssetProperty,
        of asset: AVURLAsset,
        onSuccessTransformer: @escaping (AVURLAsset) -> Value,
        completion: @escaping (Result<Value, Error>) -> Void
    ) {
        asset.loadValuesAsynchronously(forKeys: [property.rawValue]) {
            handlePropertyLoadingResult(
                property,
                of: asset,
                onSuccessTransformer: onSuccessTransformer,
                completion: completion
            )
        }
    }

    /// A private method that handles the result of loading the property of an AVURLAsset and returns a
    /// result through a completion handler
    private func handlePropertyLoadingResult<Value>(
        _ property: AssetProperty,
        of asset: AVURLAsset,
        onSuccessTransformer: @escaping (AVURLAsset) -> Value,
        completion: @escaping (Result<Value, Error>) -> Void
    ) {
        var error: NSError?
        // Get the status of the loaded property and any associated error
        let statusOfValue = asset.statusOfValue(
            forKey: property.rawValue,
            error: &error
        )

        /// Handle the status of the loaded property and call the appropriate completion handler
        switch statusOfValue {
        case .loading:
            /// Do nothing if the property is still loading
            break
        case .loaded:
            /// If the property has been loaded, apply the onSuccessTransformer to the asset and call
            /// the completion handler with a success result
            completion(.success(onSuccessTransformer(asset)))
        case .cancelled:
            /// If loading the property was cancelled, call the completion handler with a failure result
            /// and the appropriate cancelled error
            completion(.failure(AssetPropertyLoadingError.cancelled))
        case .failed:
            /// If loading the property failed, call the completion handler with a failure result and
            /// the associated error (or an unknown error if there is none)
            completion(.failure(error ?? AssetPropertyLoadingError.unknown))
        case .unknown:
            /// If the status of the loaded property is unknown, call the completion handler with a
            /// failure result and an unknown error
            completion(.failure(AssetPropertyLoadingError.unknown))
        @unknown default:
            /// Handle any future cases of the status of the loaded property
            completion(.failure(AssetPropertyLoadingError.unknown))
        }
    }
}
