//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct SpeechToTextButton: View {
    @StateObject private var speech: SpeechHandler

    private var locale: Locale
    private var silenceTimeout: Double
    private let colors: Colors

    var onTranscriptChange: (String) -> Void

    public init(
        speechHandler: SpeechHandler? = nil,
        locale: Locale? = nil,
        silenceTimeout: Double = 3.0,
        colors: Colors = Colors(),
        onTranscriptChange: @escaping (String) -> Void = { _ in }
    ) {
        self.locale = locale ?? Locale.current
        self.silenceTimeout = silenceTimeout
        self.colors = colors
        self.onTranscriptChange = onTranscriptChange
        _speech = StateObject(wrappedValue: speechHandler ?? .init())
    }

    public var body: some View {
        VStack(spacing: 24) {
            Button {
                if speech.isRecording {
                    speech.stop()
                } else {
                    speech.start()
                }
            } label: {
                Image(systemName: speech.isRecording ? "stop.circle" : "mic")
                    .foregroundStyle(colors.transcription.icon)
            }
        }
        .onAppear {
            speech.silenceTimeout = silenceTimeout
            speech.locale = locale
        }
        .onReceive(speech.$transcript) { newValue in
            onTranscriptChange(newValue)
        }
    }
}
