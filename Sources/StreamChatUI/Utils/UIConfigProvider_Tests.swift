//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
@testable import StreamChatUI
import XCTest

class UIConfigProvider_Tests: XCTestCase {
    typealias ExtraData = NoExtraData
    
    func test_uiConfig_passedDownToSubview() {
        let parentView = TestViewWithExtraData<ExtraData>()
        let subView = TestViewWithExtraData<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestCreateChannelButton.self
        
        parentView.addSubview(subView)
        parentView.uiConfig = uiConfig
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.uiConfig.channelList.newChannelButton),
            String(describing: uiConfig.channelList.newChannelButton)
        )
    }
    
    func test_uiConfig_passedDown_ignoringNonProviders() {
        let parentView = TestViewWithExtraData<ExtraData>()
        let intermediateView = UIView()
        let subView = TestViewWithExtraData<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestCreateChannelButton.self
        
        parentView.addSubview(intermediateView)
        intermediateView.addSubview(subView)
        parentView.uiConfig = uiConfig
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.uiConfig.channelList.newChannelButton),
            String(describing: uiConfig.channelList.newChannelButton)
        )
    }
    
    func test_uiConfig_passedDownToVCView() {
        let vc = TestViewWithExtraDataController<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestCreateChannelButton.self
        
        vc.uiConfig = uiConfig
        
        // Force to call viewDidLoad
        vc.loadViewIfNeeded()
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: vc.subView.uiConfig.channelList.newChannelButton),
            String(describing: uiConfig.channelList.newChannelButton)
        )
    }
    
    func test_vcSubviews_initedFromConfig() {
        let vc = TestViewWithExtraDataController<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestCreateChannelButton.self
        
        vc.uiConfig = uiConfig
        
        // Force to call viewDidLoad
        vc.loadViewIfNeeded()
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: type(of: vc.TestCreateChannelButton)),
            String(describing: uiConfig.channelList.newChannelButton)
        )
    }
}

private class TestViewWithExtraData<ExtraData: ExtraDataTypes>: UIView, UIConfigProvider {}

private class TestViewWithExtraDataController<ExtraData: ExtraDataTypes>: UIViewController, UIConfigProvider {
    let subView = TestViewWithExtraData<ExtraData>()
    lazy var TestCreateChannelButton = uiConfig.channelList.newChannelButton.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(subView)
        view.addSubview(TestCreateChannelButton)
    }
}

private class TestCreateChannelButton: ChatChannelCreateNewButton {}
