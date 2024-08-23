//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class VideoAttachmentGalleryPreview_Tests: XCTestCase {
    func test_whenContentIsSet_videoLoadingComponentIsInvoked() throws {
        // Create mock components
        let components: Components = .mock

        // Create a cell and inject components
        let view = VideoAttachmentGalleryPreview()
        view.components = components

        // Assign the content
        let url = URL.localYodaImage
        view.content = ChatMessageVideoAttachment(
            id: .unique,
            type: .video,
            payload: .init(
                title: .unique,
                videoRemoteURL: url,
                file: try! .init(url: url),
                extraData: nil
            ),
            downloadingState: nil,
            uploadingState: nil
        )

        // Add cell to view hierarchy to trigger lifecycle methods
        UIView().addSubview(view)

        // Assert injected loader is invoked with correct values
        XCTAssertEqual(components.mockVideoLoader.loadPreviewForVideoMockFunc.calls.map(\.0), [url])
    }
}
