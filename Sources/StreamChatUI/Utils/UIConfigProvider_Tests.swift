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
        let parentView = TestView<ExtraData>()
        let subView = TestView<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestButton.self
        
        parentView.addSubview(subView)
        parentView.uiConfig = uiConfig
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: subView.uiConfig.channelList.newChannelButton),
            String(describing: uiConfig.channelList.newChannelButton)
        )
    }
    
    func test_uiConfig_passedDown_ignoringNonProviders() {
        let parentView = TestView<ExtraData>()
        let intermediateView = UIView()
        let subView = TestView<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestButton.self
        
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
        let vc = TestViewController<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestButton.self
        
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
        let vc = TestViewController<ExtraData>()
        var uiConfig = UIConfig()
        // Set some random subclass to check if the config is passed down
        uiConfig.channelList.newChannelButton = TestButton.self
        
        vc.uiConfig = uiConfig
        
        // Force to call viewDidLoad
        vc.loadViewIfNeeded()
        
        // We can only compare string descriptions, which should be good enough
        XCTAssertEqual(
            String(describing: type(of: vc.testButton)),
            String(describing: uiConfig.channelList.newChannelButton)
        )
    }
}

private class TestView<ExtraData: ExtraDataTypes>: UIView, UIConfigProvider {}

private class TestViewController<ExtraData: ExtraDataTypes>: UIViewController, UIConfigProvider {
    let subView = TestView<ExtraData>()
    lazy var testButton = uiConfig.channelList.newChannelButton.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(subView)
        view.addSubview(testButton)
    }
}

private class TestButton: ChatChannelCreateNewButton {}
