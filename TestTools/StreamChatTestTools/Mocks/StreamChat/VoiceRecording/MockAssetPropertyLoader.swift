//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamChat

open class MockAssetPropertyLoader: AssetPropertyLoading {
    open var loadPropertiesWasCalledWithProperties: [AssetProperty]?
    open var loadPropertiesWasCalledWithAsset: AVAsset?
    open var loadPropertiesResult: Result<AVAsset, AssetPropertyLoadingCompositeError>?
    open var holdLoadProperties = false

    public init() {}

    open func loadProperties<Asset>(
        _ properties: [AssetProperty],
        of asset: Asset,
        completion: @escaping (Result<Asset, AssetPropertyLoadingCompositeError>) -> Void
    ) where Asset: AVAsset {
        guard holdLoadProperties == false else {
            return
        }
        loadPropertiesWasCalledWithProperties = properties
        loadPropertiesWasCalledWithAsset = asset
        completion(loadPropertiesResult!.map { $0 as! Asset })
    }
}
