//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import StreamCore
import SwiftUI

public struct SpeechToTextButton: View {
    @StateObject private var speech: SpeechHandler

    private var locale: Locale
    private var silenceTimeout: Double

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var onTranscriptChange: (String) -> Void

    public init(
        speechHandler: SpeechHandler? = nil,
        locale: Locale? = nil,
        silenceTimeout: Double = 3.0,
        onTranscriptChange: @escaping (String) -> Void = { _ in }
    ) {
        self.locale = locale ?? Locale.current
        self.silenceTimeout = silenceTimeout
        self.onTranscriptChange = onTranscriptChange
        _speech = StateObject(wrappedValue: speechHandler ?? .init())
    }

    public var body: some View {
        VStack(spacing: layout.spacingXl) {
            Button {
                if speech.isRecording {
                    speech.stop()
                } else {
                    speech.start()
                }
            } label: {
                (speech.isRecording ? images.composerStopDictation : images.composerStartDictation)
                    .foregroundStyle(Color(colors.composerIcon))
            }
        }
        .onAppear {
            speech.silenceTimeout = silenceTimeout
            speech.locale = locale
        }
        .onReceive(Self.transcripts(speech.$transcript)) { newValue in
            onTranscriptChange(newValue)
        }
    }

    // The publisher starts with the empty transcript, and dictation clears it as it starts.
    // Forwarding either would wipe what is already in the field.
    static func transcripts(_ transcript: Published<String>.Publisher) -> AnyPublisher<String, Never> {
        transcript
            .dropFirst()
            .filter { !$0.isEmpty }
            .eraseToAnyPublisher()
    }
}
