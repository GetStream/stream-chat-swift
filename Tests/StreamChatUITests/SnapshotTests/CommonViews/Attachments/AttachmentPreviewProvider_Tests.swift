//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import XCTest

final class AttachmentPreviewProvider_VoiceRecordingAttachmentPayload_Tests: XCTestCase {
    // MARK: - preferredAxis

    func test_preferredAxis_returnsExpectedValue() {
        XCTAssertEqual(VoiceRecordingAttachmentPayload.preferredAxis, .vertical)
    }

    // MARK: - previewView(components:)

    func test_previewView_returnsExpectedValue() throws {
        let payload = VoiceRecordingAttachmentPayload(
            title: "Title",
            voiceRecordingRemoteURL: .unique(),
            file: .init(type: .aac, size: 120, mimeType: "audio/aac"),
            duration: 59,
            waveformData: nil,
            extraData: nil
        )

        let previewView = try XCTUnwrap(payload.previewView(components: .default) as? VoiceRecordingAttachmentComposerPreview)

        XCTAssertEqual(previewView.content?.title, payload.title)
        XCTAssertEqual(previewView.content?.size, 120)
        XCTAssertEqual(previewView.content?.duration, 59)
        XCTAssertEqual(previewView.content?.audioAssetURL, payload.voiceRecordingURL)
    }
}
