//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum SpeechHandlerError: LocalizedError {
    case recognizerUnavailable
    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return L10n.Transcription.recognizerUnavailable
        }
    }
}
