//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class VideoAttachmentComposerPreview_Tests: XCTestCase {
    func test_whenContentIsSet_videoLoadingComponentIsInvoked() throws {
        // Create mock components
        let components: Components = .mock
                
        // Create a view and inject components
        let view = VideoAttachmentComposerPreview()
        view.components = components
        
        // Set the content
        let url = URL.unique()
        view.content = url
        
        // Add view to view heirarchy to trigger lifecycle methods
        UIView().addSubview(view)
        
        // Assert injected loader is invoked with correct values
        XCTAssertEqual(components.mockVideoLoader.loadPreviewForVideoMockFunc.calls.map(\.0), [url])
        XCTAssertEqual(components.mockVideoLoader.videoAssetMockFunc.calls, [url])
    }
}
