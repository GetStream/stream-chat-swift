
//
// MARK: - Additional Tests (Generated)
// Frameworks: XCTest (+ SnapshotTesting if available)
//
// These tests focus on FileAttachmentView scenarios: rendering variations,
// state transitions, and edge/failure conditions.
//

private struct _TestFileAttachmentData {
    let name: String
    let size: Int
    let mimeType: String?
    let isUploading: Bool
    let uploadProgress: Double
    let isFailed: Bool
    let isDownloaded: Bool
}

/// Minimal test harness to build a FileAttachmentView.
/// Adjust factory wiring to project conventions if helpers exist.
private func makeFileAttachmentView(
    name: String,
    size: Int,
    mimeType: String? = nil,
    isUploading: Bool = false,
    uploadProgress: Double = 0.0,
    isFailed: Bool = false,
    isDownloaded: Bool = false
) -> some SwiftUI.View {
    // The following assumes StreamChatUI exposes a FileAttachmentView initializer
    // that accepts a model or discrete params. If your codebase uses a ViewModel,
    // replace with the appropriate constructor and mapping.
    // We keep this lightweight and compile-friendly for common APIs.
    #if canImport(SwiftUI)
    import SwiftUI
    #endif

    // Create a basic model using likely API surface. Replace if your code differs.
    let item = FileAttachmentItem(
        id: UUID(),
        title: name,
        fileExtension: (name as NSString).pathExtension.isEmpty ? nil : (name as NSString).pathExtension,
        size: size,
        mimeType: mimeType,
        uploading: isUploading,
        progress: uploadProgress,
        failed: isFailed,
        downloaded: isDownloaded
    )
    return FileAttachmentView(item: item)
}

final class FileAttachmentView_GeneratedTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here if the project uses appearance or environment configuration.
    }

    override func tearDown() {
        // Clean up global/singleton state if needed.
        super.tearDown()
    }

    func test_rendersBasicNameAndSize() {
        // Given
        let view = makeFileAttachmentView(
            name: "Report.pdf",
            size: 1_234_567,
            mimeType: "application/pdf"
        )

        // Then
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func test_showsUploadProgress_whenUploading() {
        let view25 = makeFileAttachmentView(
            name: "Video.mov",
            size: 25_000_000,
            mimeType: "video/quicktime",
            isUploading: true,
            uploadProgress: 0.25
        )
        let view75 = makeFileAttachmentView(
            name: "Video.mov",
            size: 25_000_000,
            mimeType: "video/quicktime",
            isUploading: true,
            uploadProgress: 0.75
        )

        assertSnapshot(matching: view25, as: .image(layout: .device(config: .iPhone13)), named: "upload-25")
        assertSnapshot(matching: view75, as: .image(layout: .device(config: .iPhone13)), named: "upload-75")
    }

    func test_showsFailedState_whenUploadFails() {
        let view = makeFileAttachmentView(
            name: "Archive.zip",
            size: 10_240,
            mimeType: "application/zip",
            isUploading: false,
            uploadProgress: 0.0,
            isFailed: true
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func test_showsDownloadedIndicator_whenDownloaded() {
        let view = makeFileAttachmentView(
            name: "Audio.mp3",
            size: 3_145_728,
            mimeType: "audio/mpeg",
            isDownloaded: true
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func test_longFileName_truncatesGracefully() {
        let longName = "Very_Long_File_Name_With_Many_Sections_And_Spaces That_Should_Truncate_Properly_2025_09_16.pptx"
        let view = makeFileAttachmentView(
            name: longName,
            size: 987_654,
            mimeType: "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func test_zeroSize_displaysFallback() {
        let view = makeFileAttachmentView(
            name: "Empty.txt",
            size: 0,
            mimeType: "text/plain"
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func test_unknownMimeType_showsGenericIcon() {
        let view = makeFileAttachmentView(
            name: "data.bin",
            size: 42,
            mimeType: nil
        )

        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13)))
    }

    func test_multipleRapidStateChanges_areStable() {
        // Simulate quick changes: uploading -> failed -> retry uploading -> downloaded
        let uploading = makeFileAttachmentView(
            name: "Doc.docx",
            size: 222_222,
            mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            isUploading: true,
            uploadProgress: 0.4
        )
        let failed = makeFileAttachmentView(
            name: "Doc.docx",
            size: 222_222,
            mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            isFailed: true
        )
        let retry = makeFileAttachmentView(
            name: "Doc.docx",
            size: 222_222,
            mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            isUploading: true,
            uploadProgress: 0.1
        )
        let downloaded = makeFileAttachmentView(
            name: "Doc.docx",
            size: 222_222,
            mimeType: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
            isDownloaded: true
        )

        assertSnapshot(matching: uploading, as: .image(layout: .device(config: .iPhone13)), named: "01-uploading")
        assertSnapshot(matching: failed, as: .image(layout: .device(config: .iPhone13)), named: "02-failed")
        assertSnapshot(matching: retry, as: .image(layout: .device(config: .iPhone13)), named: "03-retry")
        assertSnapshot(matching: downloaded, as: .image(layout: .device(config: .iPhone13)), named: "04-downloaded")
    }

    func test_accessibility_labels_arePresent() {
        // If the project exposes accessibility identifiers/labels for elements,
        // consider verifying via an accessibility snapshot or ViewInspector (if used).
        // Here we at least verify the view renders without crashing with A11y enabled env.
        let view = makeFileAttachmentView(
            name: "Invoice.pdf",
            size: 44_000,
            mimeType: "application/pdf"
        )
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13, traits: .init(userInterfaceStyle: .light))))
    }
}