//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// A formatter that converts the video duration to textual representation.
public protocol AudioRecordingNameFormatter {
    func title(
        forItemAtURL location: URL,
        index: Int
    ) -> String
}

/// The default video duration formatter.
open class DefaultAudioRecordingNameFormatter: AudioRecordingNameFormatter {
    public init() {}

    open func title(
        forItemAtURL location: URL,
        index: Int
    ) -> String {
        L10n.Recording.Presentation.name(index)
    }
}
