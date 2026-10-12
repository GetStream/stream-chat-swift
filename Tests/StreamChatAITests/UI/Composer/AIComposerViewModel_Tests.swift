//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

@MainActor
final class AIComposerViewModel_Tests: XCTestCase {
    private var viewModel: AIComposerViewModel!
    private var createdFiles: [URL] = []

    override func setUp() async throws {
        try await super.setUp()
        viewModel = AIComposerViewModel()
    }

    override func tearDown() async throws {
        createdFiles.forEach { try? FileManager.default.removeItem(at: $0) }
        createdFiles = []
        viewModel = nil
        try await super.tearDown()
    }

    func test_init_storesValues() {
        let option = ChatOption(id: "search", title: "Search", description: "Search the web", icon: "globe", shortTitle: "Search")

        let viewModel = AIComposerViewModel(selectedChatOption: option, isTextFieldFocused: true, chatOptions: [option])

        XCTAssertEqual(viewModel.text, "")
        XCTAssertFalse(viewModel.sheetShown)
        XCTAssertEqual(viewModel.selectedChatOption, option)
        XCTAssertTrue(viewModel.isTextFieldFocused)
        XCTAssertEqual(viewModel.chatOptions, [option])
    }

    func test_appendAttachment_whenTemporary_tracksFileForCleanup() throws {
        let url = try makeFile()

        viewModel.appendAttachment(AttachmentLocation(url: url, isTemporary: true))

        XCTAssertEqual(viewModel.attachments, [url])
        XCTAssertEqual(viewModel.temporaryAttachmentURLs, [url])
    }

    func test_appendAttachment_whenNotTemporary_doesNotTrackFile() throws {
        let url = try makeFile()

        viewModel.appendAttachment(AttachmentLocation(url: url, isTemporary: false))

        XCTAssertEqual(viewModel.attachments, [url])
        XCTAssertTrue(viewModel.temporaryAttachmentURLs.isEmpty)
    }

    func test_removeAttachment_whenTemporary_deletesFile() throws {
        let url = try makeFile()
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: url, isTemporary: true))

        viewModel.removeAttachment(url)

        XCTAssertTrue(viewModel.attachments.isEmpty)
        XCTAssertTrue(viewModel.selectedAssetURLs.isEmpty)
        XCTAssertTrue(viewModel.temporaryAttachmentURLs.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func test_removeAttachment_whenNotTemporary_keepsFile() throws {
        let kept = try makeFile()
        let other = try makeFile()
        viewModel.appendAttachment(AttachmentLocation(url: kept, isTemporary: false))
        viewModel.appendAttachment(AttachmentLocation(url: other, isTemporary: false))

        viewModel.removeAttachment(kept)

        XCTAssertEqual(viewModel.attachments, [other])
        XCTAssertTrue(FileManager.default.fileExists(atPath: kept.path))
    }

    func test_selectAsset_whenAlreadySelected_doesNotAddItAgain() throws {
        let first = try makeFile()
        let second = try makeFile()

        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: first, isTemporary: false))
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: second, isTemporary: false))

        XCTAssertEqual(viewModel.attachments, [first])
        XCTAssertEqual(viewModel.selectedAssetURLs, ["asset-1": first])
    }

    func test_deselectAsset_removesAttachmentAndDeletesTemporaryFile() throws {
        let url = try makeFile()
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: url, isTemporary: true))

        viewModel.deselectAsset(assetID: "asset-1")

        XCTAssertTrue(viewModel.attachments.isEmpty)
        XCTAssertTrue(viewModel.selectedAssetURLs.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func test_deselectAsset_whenAssetIsNotSelected_keepsAttachments() throws {
        let url = try makeFile()
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: url, isTemporary: true))

        viewModel.deselectAsset(assetID: "asset-2")

        XCTAssertEqual(viewModel.attachments, [url])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func test_cleanUpData_clearsTextAndAttachmentsAndDeletesTemporaryFiles() throws {
        let temporary = try makeFile()
        let library = try makeFile()
        viewModel.text = "Describe these photos"
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: temporary, isTemporary: true))
        viewModel.appendAttachment(AttachmentLocation(url: library, isTemporary: false))

        viewModel.cleanUpData()

        XCTAssertEqual(viewModel.text, "")
        XCTAssertTrue(viewModel.attachments.isEmpty)
        XCTAssertTrue(viewModel.selectedAssetURLs.isEmpty)
        XCTAssertTrue(viewModel.temporaryAttachmentURLs.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporary.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: library.path))
    }

    func test_clearAfterSending_emptiesTheComposerButKeepsTemporaryFiles() throws {
        let temporary = try makeFile()
        viewModel.text = "Describe this photo"
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: temporary, isTemporary: true))

        viewModel.clearAfterSending()

        XCTAssertEqual(viewModel.text, "")
        XCTAssertTrue(viewModel.attachments.isEmpty)
        XCTAssertTrue(viewModel.selectedAssetURLs.isEmpty)
        XCTAssertTrue(viewModel.temporaryAttachmentURLs.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: temporary.path), "the sent message may still be uploading it")
    }

    func test_isGenerating_isFalseUnlessSet() {
        XCTAssertFalse(viewModel.isGenerating)
        XCTAssertTrue(AIComposerViewModel(isGenerating: true).isGenerating)
    }

    func test_attachments_whenCleared_dropSelectionsAndTemporaryFiles() throws {
        let url = try makeFile()
        viewModel.selectAsset(assetID: "asset-1", attachment: AttachmentLocation(url: url, isTemporary: true))

        viewModel.attachments = []

        XCTAssertTrue(viewModel.selectedAssetURLs.isEmpty)
        XCTAssertTrue(viewModel.temporaryAttachmentURLs.isEmpty)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    // MARK: - Helpers

    private func makeFile() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("composer-test-\(UUID().uuidString).jpg")
        try Data([0xff, 0xd8]).write(to: url)
        createdFiles.append(url)
        return url
    }
}
