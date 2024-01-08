//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatTestTools
import StreamChatUI

public final class MockAudioSessionFeedbackGenerator: AudioSessionFeedbackGenerator, Spy {
    public var recordedFunctions: [String] = []

    public init() {}

    public func feedbackForPlay() { record() }

    public func feedbackForPause() { record() }

    public func feedbackForStop() { record() }

    public func feedbackForPlaybackRateChange() { record() }

    public func feedbackForSeeking() { record() }

    public func feedbackForPreparingRecording() { record() }

    public func feedbackForBeginRecording() { record() }

    public func feedbackForCancelRecording() { record() }

    public func feedbackForStopRecording() { record() }

    public func feedbackForDiscardRecording() { record() }
}
