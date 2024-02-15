//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AttachmentQueueUploader_Tests: XCTestCase {
    var webSocketClient: WebSocketClient_Mock!
    var apiClient: APIClient_Spy!
    var database: DatabaseContainer_Spy!
    var queueUploader: AttachmentQueueUploader!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClient_Mock()
        apiClient = APIClient_Spy()
        database = DatabaseContainer_Spy()
        queueUploader = AttachmentQueueUploader(database: database, apiClient: apiClient, attachmentPostProcessor: nil)
    }

    override func tearDown() {
        apiClient.cleanUp()

        AssertAsync {
            Assert.canBeReleased(&queueUploader)
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

        let attachmentPayloads: [AnyAttachmentPayload] = [
            .mockFile,
            .mockImage,
            .mockVideo,
            .mockAudio,
            .mockVoiceRecording
        ]

        for (index, envelope) in attachmentPayloads.enumerated() {
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

            for progress in stride(from: 0, through: 1, by: 5 * queueUploader.minSignificantUploadingProgressChange) {
                // Simulate progress in uploading process.
                apiClient.uploadFile_progress?(progress)
                // Assert uploading progress in reflected by attachment local state.
                AssertAsync.willBeEqual(attachment.localState, .uploading(progress: progress))
            }

            // Simulate successful backend response with remote file URL.
            let attachmentModel = try XCTUnwrap(attachment.asAnyModel())
            let response = UploadedAttachment.dummy(attachment: attachmentModel, remoteURL: .fakeFile)
            let remoteUrl = response.remoteURL
            apiClient.uploadFile_completion?(.success(response))

            switch envelope.type {
            case .image:
                var imageModel: ChatMessageImageAttachment? {
                    attachment.asAnyModel()?.attachment(payloadType: ImageAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(imageModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.imageURL` is set.
                    Assert.willBeEqual(originalURLString(imageModel?.imageURL), remoteUrl.absoluteString)
                }
            case .file:
                var fileModel: ChatMessageFileAttachment? {
                    attachment.asAnyModel()?.attachment(payloadType: FileAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(fileModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.assetURL` is set.
                    Assert.willBeEqual(originalURLString(fileModel?.assetURL), remoteUrl.absoluteString)
                }
            case .video:
                var videoModel: ChatMessageVideoAttachment? {
                    attachment.asAnyModel()?.attachment(payloadType: VideoAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(videoModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.assetURL` is set.
                    Assert.willBeEqual(originalURLString(videoModel?.videoURL), remoteUrl.absoluteString)
                }
            case .audio:
                var audioModel: ChatMessageAudioAttachment? {
                    attachment.asAnyModel()?.attachment(payloadType: AudioAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(audioModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.assetURL` is set.
                    Assert.willBeEqual(originalURLString(audioModel?.audioURL), remoteUrl.absoluteString)
                }
            case .voiceRecording:
                var audioModel: ChatMessageVoiceRecordingAttachment? {
                    attachment.asAnyModel()?.attachment(payloadType: VoiceRecordingAttachmentPayload.self)
                }
                AssertAsync {
                    // Assert attachment state eventually becomes `.uploaded`.
                    Assert.willBeEqual(audioModel?.uploadingState?.state, .uploaded)
                    // Assert `attachment.assetURL` is set.
                    Assert.willBeEqual(originalURLString(audioModel?.voiceRecordingURL), remoteUrl.absoluteString)
                }
            default:
                throw TestError()
            }
        }
    }

    func test_uploader_whenAllAttachmentsFinishUploading_whenMessageSendingFailed_markMessagePendingSend() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .sendingFailed)

        var message: MessageDTO? { database.viewContext.message(id: messageId) }

        XCTAssertEqual(message?.localMessageState, .sendingFailed)

        // Create the successful attachments in the database
        try database.writeSynchronously { session in
            let attachment1 = try session.createNewAttachment(
                attachment: .mockAudio,
                id: .init(cid: cid, messageId: messageId, index: 1)
            )
            let attachment2 = try session.createNewAttachment(
                attachment: .mockAudio,
                id: .init(cid: cid, messageId: messageId, index: 2)
            )
            attachment1.localState = .uploaded
            attachment2.localState = .uploaded
        }

        let attachmentPayload: AnyAttachmentPayload = .mockImage
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 1)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentPayload, id: attachmentId)
        }

        // Load attachment from the database.
        let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment is in `.pendingUpload` state.
        XCTAssertEqual(attachment.localState, .pendingUpload)

        // Wait attachment uploading begins.
        let attachmentModelId = try XCTUnwrap(attachment.asAnyModel()).id
        AssertAsync.willBeEqual(
            apiClient.uploadFile_attachment?.id,
            attachmentModelId
        )

        // Simulate successful backend response with remote file URL.
        let attachmentModel = try XCTUnwrap(attachment.asAnyModel())
        let response = UploadedAttachment.dummy(attachment: attachmentModel, remoteURL: .fakeFile)
        apiClient.uploadFile_completion?(.success(response))

        AssertAsync {
            Assert.willBeEqual(message?.localMessageState, .pendingSend)
        }
    }

    func test_uploader_whenAllAttachmentsFinishUploading_whenMessageNotSendingFailed_doNotMarkMessagePendingSend() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSync)

        var message: MessageDTO? { database.viewContext.message(id: messageId) }

        XCTAssertEqual(message?.localMessageState, .pendingSync)

        // Create the successful attachments in the database
        try database.writeSynchronously { session in
            let attachment1 = try session.createNewAttachment(
                attachment: .mockAudio,
                id: .init(cid: cid, messageId: messageId, index: 1)
            )
            let attachment2 = try session.createNewAttachment(
                attachment: .mockAudio,
                id: .init(cid: cid, messageId: messageId, index: 2)
            )
            attachment1.localState = .uploaded
            attachment2.localState = .uploaded
        }

        let attachmentPayload: AnyAttachmentPayload = .mockImage
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 1)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentPayload, id: attachmentId)
        }

        // Load attachment from the database.
        let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment is in `.pendingUpload` state.
        XCTAssertEqual(attachment.localState, .pendingUpload)

        // Wait attachment uploading begins.
        let attachmentModelId = try XCTUnwrap(attachment.asAnyModel()).id
        AssertAsync.willBeEqual(
            apiClient.uploadFile_attachment?.id,
            attachmentModelId
        )

        // Simulate successful backend response with remote file URL.
        let attachmentModel = try XCTUnwrap(attachment.asAnyModel())
        let response = UploadedAttachment.dummy(attachment: attachmentModel, remoteURL: .fakeFile)
        apiClient.uploadFile_completion?(.success(response))

        AssertAsync {
            Assert.willBeEqual(message?.localMessageState, .pendingSync)
        }
    }

    func test_uploader_whenHasFailedAttachments_doNotMarkMessagePendingSend() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .sendingFailed)

        var message: MessageDTO? { database.viewContext.message(id: messageId) }

        XCTAssertEqual(message?.localMessageState, .sendingFailed)

        // Create the successful attachments in the database
        try database.writeSynchronously { session in
            let attachment1 = try session.createNewAttachment(
                attachment: .mockAudio,
                id: .init(cid: cid, messageId: messageId, index: 1)
            )
            let attachment2 = try session.createNewAttachment(
                attachment: .mockAudio,
                id: .init(cid: cid, messageId: messageId, index: 2)
            )
            attachment1.localState = .uploadingFailed
            attachment2.localState = .uploaded
        }

        let attachmentPayload: AnyAttachmentPayload = .mockImage
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 1)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentPayload, id: attachmentId)
        }

        // Load attachment from the database.
        let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment is in `.pendingUpload` state.
        XCTAssertEqual(attachment.localState, .pendingUpload)

        // Wait attachment uploading begins.
        let attachmentModelId = try XCTUnwrap(attachment.asAnyModel()).id
        AssertAsync.willBeEqual(
            apiClient.uploadFile_attachment?.id,
            attachmentModelId
        )

        // Simulate successful backend response with remote file URL.
        let attachmentModel = try XCTUnwrap(attachment.asAnyModel())
        let response = UploadedAttachment.dummy(attachment: attachmentModel, remoteURL: .fakeFile)
        apiClient.uploadFile_completion?(.success(response))

        AssertAsync {
            Assert.willBeEqual(message?.localMessageState, .sendingFailed)
        }
    }

    func test_uploader_whenUploadFails_markMessageAsFailed() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        var message: MessageDTO? { database.viewContext.message(id: messageId) }

        XCTAssertEqual(message?.localMessageState, .pendingSend)

        let attachmentPayload: AnyAttachmentPayload = .mockImage
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 1)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentPayload, id: attachmentId)
        }

        // Load attachment from the database.
        let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        // Assert attachment is in `.pendingUpload` state.
        XCTAssertEqual(attachment.localState, .pendingUpload)

        // Wait attachment uploading begins.
        let attachmentModelId = try XCTUnwrap(attachment.asAnyModel()).id
        AssertAsync.willBeEqual(
            apiClient.uploadFile_attachment?.id,
            attachmentModelId
        )

        // Simulate error backend response
        apiClient.uploadFile_completion?(.failure(ClientError("Upload failed")))

        AssertAsync {
            Assert.willBeEqual(message?.localMessageState, .sendingFailed)
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
        AssertAsync.canBeReleased(&queueUploader)
    }

    func test_uploader_whenPostProcessorAvailable_shouldChangeTheAttachmentPayload() throws {
        struct FakePostProcessor: UploadedAttachmentPostProcessor {
            let attachmentPayloadUpdater = AnyAttachmentUpdater()

            func process(uploadedAttachment: UploadedAttachment) -> UploadedAttachment {
                var attachment = uploadedAttachment.attachment

                attachmentPayloadUpdater.update(&attachment, forPayload: ImageAttachmentPayload.self) { payload in
                    payload.title = "New Title"
                    payload.extraData = ["test": 123]
                }

                return UploadedAttachment(attachment: attachment, remoteURL: uploadedAttachment.remoteURL, thumbnailURL: uploadedAttachment.thumbnailURL)
            }
        }

        queueUploader = AttachmentQueueUploader(
            database: database,
            apiClient: apiClient,
            attachmentPostProcessor: FakePostProcessor()
        )

        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        // Create the attachment in the database
        let attachmentPayload: AnyAttachmentPayload = .mockImage
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 1)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachmentPayload, id: attachmentId)
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

        // Simulate successful backend response with remote file URL.
        let attachmentModel = try XCTUnwrap(attachment.asAnyModel())
        let response = UploadedAttachment.dummy(attachment: attachmentModel, remoteURL: .fakeFile)
        let remoteUrl = response.remoteURL
        apiClient.uploadFile_completion?(.success(response))

        var imageModel: ChatMessageImageAttachment? {
            attachment.asAnyModel()?.attachment(payloadType: ImageAttachmentPayload.self)
        }
        AssertAsync {
            Assert.willBeEqual(imageModel?.uploadingState?.state, .uploaded)
            Assert.willBeEqual(originalURLString(imageModel?.imageURL), remoteUrl.absoluteString)
            Assert.willBeEqual(imageModel?.title, "New Title")
            Assert.willBeEqual(imageModel?.extraData, ["test": 123])
        }
    }

    func test_attachmentsAreCopiedToSandbox_beforeBeingSent() throws {
        // GIVEN
        let cid: ChannelId = .init(type: .messaging, id: "dummy")
        let messageId: MessageId = "fake"
        let attachmentId: AttachmentId = .init(cid: cid, messageId: messageId, index: 0)

        let fileManager = FileManager.default
        let fileContent = "This is the file content"
        let fileName = "Test.txt"

        // Save a temporary file for the attachment to be sent
        let fileData = try XCTUnwrap(fileContent.data(using: .utf8))
        let folderURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
        let temporaryFileURL = folderURL.appendingPathComponent(fileName)
        try fileData.write(to: temporaryFileURL)

        let documentsURL = try XCTUnwrap(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first)
        let attachmentsDirectory = documentsURL.appendingPathComponent("LocalAttachments")
        var locallyStoredAttachments: [URL] {
            (try? fileManager.contentsOfDirectory(at: attachmentsDirectory, includingPropertiesForKeys: nil)) ?? []
        }
        try locallyStoredAttachments.forEach(fileManager.removeItem)

        // WHEN
        // Create an attachment using the temporary file
        let attachment = AnyAttachmentPayload.mock(type: .file, localFileURL: temporaryFileURL)
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)
        try database.writeSynchronously { session in
            try session.createNewAttachment(attachment: attachment, id: attachmentId)
        }

        // THEN
        let attachmentDTO = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        wait(for: [apiClient.uploadRequest_expectation], timeout: defaultTimeout)

        XCTAssertEqual(locallyStoredAttachments.count, 1)
        XCTAssertEqual(
            locallyStoredAttachments.first?.lastPathComponent,
            "messaging:dummy-fake-0.txt"
        )
        XCTAssertEqual(attachmentDTO.localState, .pendingUpload)

        // Simulate attachment upload
        let mockedRemoteURL = documentsURL.appendingPathComponent("mock-remote-url")
        apiClient.uploadFile_completion!(.success(.dummy(remoteURL: mockedRemoteURL)))

        AssertAsync.willBeTrue(attachmentDTO.localState == .uploaded)
        XCTAssertEqual(locallyStoredAttachments.count, 0)
    }

    func test_multipleAttachmentsAreCopiedToSandbox_onlySuccessfulOnesAreRemoved() throws {
        let fileManager = FileManager.default
        // GIVEN
        let cid: ChannelId = .init(type: .messaging, id: "dummy")
        let messageId: MessageId = "fake"

        let documentsURL = try XCTUnwrap(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first)
        var locallyStoredAttachments: [URL] {
            let attachmentsDirectory = documentsURL.appendingPathComponent("LocalAttachments")
            return (try? fileManager.contentsOfDirectory(at: attachmentsDirectory, includingPropertiesForKeys: nil)) ?? []
        }

        func saveFile(for attachmentId: AttachmentId, fileName: String) throws -> URL {
            let fileData = try XCTUnwrap("This is the file content".data(using: .utf8))
            let folderURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try fileManager.createDirectory(at: folderURL, withIntermediateDirectories: true)
            let temporaryFileURL = folderURL.appendingPathComponent(fileName)
            try fileData.write(to: temporaryFileURL)
            return temporaryFileURL
        }

        func completeUploadRequest(with result: Result<UploadedAttachment, Error>) throws {
            try XCTUnwrap(apiClient.uploadFile_completion)(result)
        }

        let attachmentId1: AttachmentId = .init(cid: cid, messageId: messageId, index: 0)
        let attachmentId2: AttachmentId = .init(cid: cid, messageId: messageId, index: 1)
        let fileName1 = "Test\(attachmentId1.index).txt"
        let fileName2 = "Test\(attachmentId2.index).txt"

        let temporaryFileURL1 = try saveFile(for: attachmentId1, fileName: fileName1)
        let temporaryFileURL2 = try saveFile(for: attachmentId2, fileName: fileName2)
        try locallyStoredAttachments.forEach(fileManager.removeItem)

        // WHEN
        // Create channel and message
        try database.createChannel(cid: cid, withMessages: false)
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        // Save first attachment
        try database.writeSynchronously { session in
            let attachment = AnyAttachmentPayload.mock(type: .file, localFileURL: temporaryFileURL1)
            try session.createNewAttachment(attachment: attachment, id: attachmentId1)
        }

        wait(for: [apiClient.uploadRequest_expectation], timeout: defaultTimeout)
        try completeUploadRequest(with: .failure(TestError()))

        apiClient.cleanUp()

        // Save first attachment
        try database.writeSynchronously { session in
            let attachment = AnyAttachmentPayload.mock(type: .file, localFileURL: temporaryFileURL2)
            try session.createNewAttachment(attachment: attachment, id: attachmentId2)
        }

        wait(for: [apiClient.uploadRequest_expectation], timeout: defaultTimeout)
        let mockedRemoteURL2 = documentsURL.appendingPathComponent("mock-remote-url")
        try completeUploadRequest(with: .success(.dummy(remoteURL: mockedRemoteURL2)))

        // THEN
        let attachmentDTO1 = try XCTUnwrap(database.viewContext.attachment(id: attachmentId1))
        let attachmentDTO2 = try XCTUnwrap(database.viewContext.attachment(id: attachmentId2))

        AssertAsync.willBeTrue(attachmentDTO1.localState == .uploadingFailed)
        AssertAsync.willBeTrue(attachmentDTO2.localState == .uploaded)

        XCTAssertEqual(locallyStoredAttachments.count, 1)
        XCTAssertEqual(
            locallyStoredAttachments.first?.lastPathComponent,
            "messaging:dummy-fake-0.txt"
        )
    }

    func test_uploadAttachmentsInParallel() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        let attachmentPayloads: [AnyAttachmentPayload] = [
            .mockFile,
            .mockImage,
            .mockVideo,
            .mockAudio,
            .mockVoiceRecording
        ]

        for (index, envelope) in attachmentPayloads.enumerated() {
            let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: index)
            // Seed attachment in `.pendingUpload` state to the database.
            try database.writeSynchronously { session in
                try session.createNewAttachment(attachment: envelope, id: attachmentId)
            }

            // Load attachment from the database.
            let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

            // Assert attachment is in `.pendingUpload` state.
            XCTAssertEqual(attachment.localState, .pendingUpload)
        }

        // Attachments start all uploading at the same time.
        AssertAsync.willBeEqual(
            apiClient.uploadFile_callCount,
            attachmentPayloads.count
        )
    }
}

private extension URL {
    static let fakeFile = Self(string: "file://fake/path/to/file.txt")!
}

// In ChatMessageDefaultAttachment we have private func `fixedURL` that modifies `http` part of the URL
private func originalURLString(_ url: URL?) -> String? {
    url?.absoluteString.replacingOccurrences(of: "https://", with: "")
}
