//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import StreamChat
import Foundation

public final class MockAudioQueuePlayerNextItemProvider: AudioQueuePlayerNextItemProvider {

    public private(set) var findNextItemWasCalledWithMessages: [ChatMessage]?
    public private(set) var findNextItemWasCalledWithCurrentVoiceRecordingURL: URL?
    public private(set) var findNextItemWasCalledWithLookUpScope: LookUpScope?
    public var findNextItemResult: URL?

    public override func findNextItem(
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
