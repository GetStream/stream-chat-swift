//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

public final class MockAudioQueuePlayerNextItemProvider: AudioQueuePlayerNextItemProvider {
    public private(set) var findNextItemWasCalledWithMessages: [ChatMessage]?
    public private(set) var findNextItemWasCalledWithCurrentVoiceRecordingURL: URL?
    public private(set) var findNextItemWasCalledWithLookUpScope: LookUpScope?
    public var findNextItemResult: URL?

    override public func findNextItem(
        in messages: [ChatMessage],
        currentVoiceRecordingURL: URL?,
        lookUpScope: LookUpScope
    ) -> URL? {
        findNextItemWasCalledWithMessages = messages
        findNextItemWasCalledWithCurrentVoiceRecordingURL = currentVoiceRecordingURL
        findNextItemWasCalledWithLookUpScope = lookUpScope
        return findNextItemResult
    }
}
