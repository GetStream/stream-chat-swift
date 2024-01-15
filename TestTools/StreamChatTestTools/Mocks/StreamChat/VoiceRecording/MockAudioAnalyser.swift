//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public final class MockAudioAnalyser: AudioAnalysing {
    public private(set) var analyseWasCalledWithAudioAnalysisContext: AudioAnalysisContext?
    public private(set) var analyseWasCalledWithTargetSamples: Int?
    public var analyseResult: Result<[Float], Error> = .success([])

    public init() {}

    public func analyse(
        audioAnalysisContext context: AudioAnalysisContext,
        for targetSamples: Int
    ) throws -> [Float] {
        analyseWasCalledWithAudioAnalysisContext = context
        analyseWasCalledWithTargetSamples = targetSamples
        switch analyseResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }
}
