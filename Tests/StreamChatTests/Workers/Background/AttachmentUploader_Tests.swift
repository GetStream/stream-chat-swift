//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentUploader_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var uploader: AttachmentUploader!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        uploader = AttachmentUploader(database: database, apiClient: apiClient)
    }

    override func tearDown() {
        apiClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&uploader)
            Assert.canBeReleased(&webSocketClient)
            Assert.canBeReleased(&apiClient)
            Assert.canBeReleased(&database)
        }

        super.tearDown()
    }

    // MARK: - Tests

    func test_uploader_happyPaths() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        let attachmentEnvelopes: [AnyAttachmentPayload] = [
            .mockFile,
            .mockImage,
            .mockVideo
        ]

        for (index, envelope) in attachmentEnvelopes.enumerated() {
            let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: index)
            // Seed attachment in `.pendingUpload` state to the database.
            try database.writeSynchronously { session in
                try session.createNewAttachment(attachment: envelope, id: attachmentId)
            }

            // Load attachment from the database.
            let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

            // Assert attachment is in `.pendingUpload` state.
            XCTAssertEqual(attachment.localState, .pendingUpload)
            
            let attachmentModelId = try XCTUnwrap(attachment.asAnyModel()).id
            // Wait attachment uploading begins.
            AssertAsync.willBeEqual(
                apiClient.uploadFile_attachment?.id,
                attachmentModelId
            )

            for progress in stride(from: 0, through: 1, by: 5 * uploader.minSignificantUploadingProgressChange) {
                // Simulate progress in uploading process.
                apiClient.uploadFile_progress?(progress)
                // Assert uploading progress in reflected by attachment local state.
                AssertAsync.willBeEqual(attachment.localState, .uploading(progress: progress))
            }

            // Simulate successful backend response with remote file URL.
            let payload = FileUploadPayload(file: .unique())
            apiClient.uploadFile_completion?(.success(payload.file))

            switch envelope.type {
            case .image:
                var imageModel: ChatMessageImageAttachment? {
                    attachment.asAnyModel().attachment(payloadType: ImageAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(imageModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.imageURL` is set.
                    Assert.willBeEqual(originalURLString(imageModel?.imageURL), payload.file.absoluteString)
                }
            case .file:
                var fileModel: ChatMessageFileAttachment? {
                    attachment.asAnyModel().attachment(payloadType: FileAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(fileModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.assetURL` is set.
                    Assert.willBeEqual(originalURLString(fileModel?.assetURL), payload.file.absoluteString)
                }
            case .video:
                var videoModel: ChatMessageVideoAttachment? {
                    attachment.asAnyModel().attachment(payloadType: VideoAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(videoModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.assetURL` is set.
                    Assert.willBeEqual(originalURLString(videoModel?.videoURL), payload.file.absoluteString)
                }
            default: throw TestError()
            }

            // In ChatMessageDefaultAttachment we have private func `fixedURL` that modifies `http` part of the URL
            func originalURLString(_ url: URL?) -> String? {
                url?.absoluteString.replacingOccurrences(of: "https://", with: "")
            }
        }
    }

    func test_uploader_doesNotUploadAttachments_notInPendingUploadState() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        let localStates: [LocalAttachmentState?] = [
            .uploading(progress: .random(in: 0...1)),
            .uploadingFailed,
            .uploaded,
            nil
        ]

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        // Seed attachments with different `localState` to the database.
        try database.writeSynchronously { session in
            for index in (0..<localStates.count) {
                let id = AttachmentId(cid: cid, messageId: messageId, index: index)
                let attachment = try session.createNewAttachment(attachment: .mockFile, id: id)
                attachment.localState = localStates[index]
            }
        }

        // Assert only for attachment at `pendingUploadIndex` the uploading started.
        AssertAsync.staysTrue(apiClient.request_allRecordedCalls.isEmpty)
    }

    func test_uploader_doesNotRetainItself() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)
        let attachmentEnvelope: AnyAttachmentPayload = .mockImage

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)
        // Seed attachment in `.pendingUpload` state to the database.
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentEnvelope, id: attachmentId)
        }

        // Wait attachment uploading begins.
        AssertAsync.willBeEqual(
            apiClient.uploadFile_attachment?.id,
            attachmentId
        )

        // Assert uploader can be released even though uploading is in progress.
        AssertAsync.canBeReleased(&uploader)
    }
}

private extension URL {
    static let fakeFile = Self(string: "file://fake/path/to/file.txt")!
}
