//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that provides the name for a recording in a specified list of recordings.
public protocol AudioRecordingNameFormatter {
    func title(
        forItemAtURL location: URL,
        index: Int
    ) -> String
}

/// The default video recording name formatter.
open class DefaultAudioRecordingNameFormatter: AudioRecordingNameFormatter {
    public init() {}

    open func title(
        forItemAtURL location: URL,
        index: Int
    ) -> String {
        L10n.Recording.Presentation.name(index)
    }
}
