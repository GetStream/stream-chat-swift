//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AttachmentUploader_Tests: StressTestCase {
    typealias ExtraData = DefaultExtraData

    var webSocketClient: WebSocketClientMock!
    var apiClient: APIClientMock!
    var database: DatabaseContainerMock!
    var uploader: AttachmentUploader<ExtraData>!

    // MARK: - Setup

    override func setUp() {
        super.setUp()

        webSocketClient = WebSocketClientMock()
        apiClient = APIClientMock()
        database = DatabaseContainerMock()
        uploader = AttachmentUploader(database: database, webSocketClient: webSocketClient, apiClient: apiClient)
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

        for (index, attachmentType) in [AttachmentType.image, .file].enumerated() {
            let localURL = Bundle(for: MockNetworkURLProtocol.self).url(forResource: "FileUploadPayload", withExtension: "json")!
            let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: index)
            let attachmentSeed = ChatMessageAttachment.Seed.dummy(localURL: localURL, type: attachmentType)

            // Seed attachment in `.pendingUpload` state to the database.
            try database.writeSynchronously { session in
                try session.createNewAttachment(seed: attachmentSeed, id: attachmentId)
            }

            // Load attachment from the database.
            let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

            // Assert attachment is in `.pendingUpload` state.
            XCTAssertEqual(attachment.localState, .pendingUpload)

            // Wait attachment uploading begins.
            AssertAsync.willBeEqual(
                apiClient.uploadFile_endpoint.flatMap(AnyEndpoint.init),
                AnyEndpoint(.uploadAttachment(with: attachmentId, type: attachmentSeed.type))
            )

            for progress in stride(from: 0, through: 1, by: 5 * uploader.minSignificantUploadingProgressChange) {
                // Simulate progress in uploading process.
                apiClient.uploadFile_progress?(progress)
                // Assert uploading progress in reflected by attachment local state.
                AssertAsync.willBeEqual(attachment.localState, .uploading(progress: progress))
            }

            // Simulate successful backend response with remote file URL.
            let payload = FileUploadPayload(file: .unique())
            apiClient.uploadFile_completion?(.success(payload))

            AssertAsync {
                // Assert attachment state eventually becomes `.uploaded`.
                Assert.willBeEqual(attachment.localState, .uploaded)
                // Assert `attachment.imageURL` is set if attachment type is `.image`.
                Assert.willBeEqual(attachment.imageURL, attachmentType == .image ? payload.file : nil)
                // Assert `attachment.url` is set if attachment type is not `.image`.
                Assert.willBeEqual(attachment.url, attachmentType == .image ? nil : payload.file)
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
                let seed = ChatMessageAttachment.Seed.dummy(
                    localURL: Bundle(for: MockNetworkURLProtocol.self).url(forResource: "FileUploadPayload", withExtension: "json")!
                )

                let attachment = try session.createNewAttachment(seed: seed, id: id)
                attachment.localState = localStates[index]
            }
        }

        // Assert only for attachment at `pendingUploadIndex` the uploading started.
        AssertAsync.staysTrue(apiClient.request_allRecordedCalls.isEmpty)
    }

    func test_uploader_changesAttachmentState_whenLocalURLIsInvalid() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentSeed = ChatMessageAttachment.Seed.dummy(localURL: .unique())
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)

        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)

        // Seed attachment with invalid `localURL` to the database.
        try database.writeSynchronously { session in
            try session.createNewAttachment(seed: attachmentSeed, id: attachmentId)
        }

        // Load attachment from the database.
        let attachment = try XCTUnwrap(database.viewContext.attachment(id: attachmentId))

        AssertAsync {
            // Assert attachment state eventually becomes `.uploadingFailed`.
            Assert.willBeEqual(attachment.localState, .uploadingFailed)
            // Uploading didn't begin.
            Assert.staysTrue(self.apiClient.request_allRecordedCalls.isEmpty)
        }
    }

    func test_uploader_doesNotRetainItself() throws {
        let cid: ChannelId = .unique
        let messageId: MessageId = .unique
        let attachmentId = AttachmentId(cid: cid, messageId: messageId, index: 0)
        let attachmentSeed = ChatMessageAttachment.Seed.dummy(
            localURL: Bundle(for: MockNetworkURLProtocol.self).url(forResource: "FileUploadPayload", withExtension: "json")!
        )

        // Create channel in the database.
        try database.createChannel(cid: cid, withMessages: false)
        // Create message in the database.
        try database.createMessage(id: messageId, cid: cid, localState: .pendingSend)
        // Seed attachment in `.pendingUpload` state to the database.
        try database.writeSynchronously { session in
            try session.createNewAttachment(seed: attachmentSeed, id: attachmentId)
        }

        // Wait attachment uploading begins.
        AssertAsync.willBeEqual(
            apiClient.uploadFile_endpoint.flatMap(AnyEndpoint.init),
            AnyEndpoint(.uploadAttachment(with: attachmentId, type: attachmentSeed.type))
        )

        // Assert uploader can be released even though uploading is in progress.
        AssertAsync.canBeReleased(&uploader)
    }
}
