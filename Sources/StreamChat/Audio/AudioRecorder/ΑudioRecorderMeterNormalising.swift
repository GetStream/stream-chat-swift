//
//  ΑudioRecorderMeterNormalising.swift
//  StreamChat
//
//  Created by Ilias Pavlidakis on 3/4/23.
//  Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol ΑudioRecorderMeterNormalising {

    func normalise(_ value: Float) -> Float
}

public struct StreamΑudioRecorderMeterNormaliser: ΑudioRecorderMeterNormalising {

    /// Everything below this noise floor cutoff will be clipped and interpreted as silence. Default is `-50.0`.
    public var noiseFloorDecibelCutoff: Float = 50.0

    public func normalise(
        _ value: Float
    ) -> Float {
        let absoluteValue = abs(value)
        guard absoluteValue < noiseFloorDecibelCutoff else {
            return 0
        }

        return (noiseFloorDecibelCutoff - absoluteValue) / noiseFloorDecibelCutoff
    }
}
