//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

public final class MockAudioAnalyser: AudioAnalysing {
    private let queue = DispatchQueue(label: "io.getstream.mock-audio-analyzer", target: .global())
    
    public private(set) var analyseWasCalledWithAudioAnalysisContext: AudioAnalysisContext? {
        get { queue.sync { _analyseWasCalledWithAudioAnalysisContext } }
        set { queue.sync { _analyseWasCalledWithAudioAnalysisContext = newValue } }
    }
    nonisolated(unsafe) private var _analyseWasCalledWithAudioAnalysisContext: AudioAnalysisContext?
    
    public private(set) var analyseWasCalledWithTargetSamples: Int? {
        get { queue.sync { _analyseWasCalledWithTargetSamples } }
        set { queue.sync { _analyseWasCalledWithTargetSamples = newValue } }
    }
    nonisolated(unsafe) private var _analyseWasCalledWithTargetSamples: Int?
    
    public var analyseResult: Result<[Float], Error> {
        get { queue.sync { _analyseResult } }
        set { queue.sync { _analyseResult = newValue } }
    }
    nonisolated(unsafe) private var _analyseResult: Result<[Float], Error> = .success([])

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
