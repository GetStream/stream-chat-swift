//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class VideoAttachmentGalleryCell_Tests: XCTestCase {
    func test_whenContentIsSet_videoLoadingComponentIsInvoked() throws {
        // Create mock components
        let components: Components = .mock
                
        // Create a cell and inject components
        let cell = VideoAttachmentGalleryCell()
        cell.components = components
        
        // Assign the content
        let url = URL.localYodaImage
        cell.content = ChatMessageVideoAttachment(
            id: .unique,
            type: .video,
            payload: .init(
                title: .unique,
                videoRemoteURL: url,
                file: try! .init(url: url),
                extraData: nil
            ),
            uploadingState: nil
        ).asAnyAttachment
        
        // Add cell to view heirarchy to trigger lifecycle methods
        UIView().addSubview(cell)
        
        // Assert injected loader is invoked with correct values
        XCTAssertEqual(components.mockVideoLoader.loadPreviewForVideoMockFunc.calls.map(\.0), [url])
    }
}
