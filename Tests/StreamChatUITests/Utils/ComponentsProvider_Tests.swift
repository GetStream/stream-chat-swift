//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
@testable import StreamChatUI
import XCTest

final class ComponentsProvider_Tests: XCTestCase {
    func test_components_passedDownToSubview() {
        let parentView = TestViewWithExtraData()
        let subView = TestViewWithExtraData()
        var components = Components()
        // Set some random subclass to check if the components are passed down
        components.galleryView = TestChatMessageGalleryView.self
        
        parentView.addSubview(subView)
        parentView.components = components
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.components.galleryView),
            String(describing: components.galleryView)
        )
    }
    
    func test_components_passedDown_ignoringNonProviders() {
        let parentView = TestViewWithExtraData()
        let intermediateView = UIView()
        let subView = TestViewWithExtraData()
        var components = Components()
        // Set some random subclass to check if the components are passed down
        components.galleryView = TestChatMessageGalleryView.self
        
        parentView.addSubview(intermediateView)
        intermediateView.addSubview(subView)
        parentView.components = components
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.components.galleryView),
            String(describing: components.galleryView)
        )
    }
    
    func test_components_passedDown_withoutProviders() {
        let parentView = UIView()
        let subView = TestViewWithExtraData()
        let defaultComponents = Components.default
        
        parentView.addSubview(subView)
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.components.galleryView),
            String(describing: defaultComponents.galleryView)
        )
    }
    
    func test_components_passedDownToVCView() {
        let vc = TestViewWithExtraDataController()
        var components = Components()
        // Set some random subclass to check if the components are passed down
        components.galleryView = TestChatMessageGalleryView.self
        
        vc.components = components
        
        // Force to call viewDidLoad
        vc.loadViewIfNeeded()
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: vc.subView.components.galleryView),
            String(describing: components.galleryView)
        )
    }
    
    func test_vcSubviews_initedFromConfig() {
        let vc = TestViewWithExtraDataController()
        var components = Components()
        // Set some random subclass to check if the components are passed down
        components.galleryView = TestChatMessageGalleryView.self
        
        vc.components = components
        
        // Force to call viewDidLoad
        vc.loadViewIfNeeded()
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: type(of: vc.TestCreateChannelButton)),
            String(describing: components.galleryView)
        )
    }
}

private class TestViewWithExtraData: UIView, ComponentsProvider {}

private class TestViewWithExtraDataController: UIViewController, ComponentsProvider {
    let subView = TestViewWithExtraData()
    lazy var TestCreateChannelButton = components.galleryView.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(subView)
        view.addSubview(TestCreateChannelButton)
    }
}

private class TestChatMessageGalleryView: ChatMessageGalleryView {}
