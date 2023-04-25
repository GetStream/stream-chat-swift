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

    public func normalise(
        _ value: Float
    ) -> Float {
        pow(10, (0.05 * value))
    }
}
