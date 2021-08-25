//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ChatChannelAvatarView_Tests: XCTestCase {
    var currentUserId: UserId!
    var channel: ChatChannel!
    
    override func setUp() {
        super.setUp()
        currentUserId = .unique

        channel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
        ])
        
        Components.default.imageLoader = MockImageLoader()
    }
    
    func test_emptyAppearance() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance_withDirectMessageChannel() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles, suffix: "with online indicator")

        // Reset the channel such that both members are offline
        channel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url)
        ])

        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_defaultAppearanceWithNoMembersInChannel() {
        let emptyChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [])
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: emptyChannel, currentUserId: currentUserId)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_defaultAppearanceWithSingleMemberInNonDMChannel() {
        let singleMemberChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
        ])
        
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: singleMemberChannel, currentUserId: currentUserId)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_defaultAppearanceWithTwoMembersInNonDMChannel() {
        let twoMemberChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true),
            .mock(id: .unique, imageURL: TestImages.vader.url, isOnline: true)
        ])
        
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: twoMemberChannel, currentUserId: currentUserId)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_defaultAppearanceWithThreeMembersInNonDMChannel() {
        let threeMemberChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true),
            .mock(id: .unique, imageURL: TestImages.vader.url, isOnline: true),
            .mock(id: .unique, imageURL: TestImages.chewbacca.url, isOnline: true)
        ])
        
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: threeMemberChannel, currentUserId: currentUserId)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    func test_defaultAppearanceWithFourMembersInNonDMChannel() {
        let fourMemberChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true),
            .mock(id: .unique, imageURL: TestImages.vader.url, isOnline: true),
            .mock(id: .unique, imageURL: TestImages.chewbacca.url, isOnline: true),
            .mock(id: .unique, imageURL: TestImages.r2.url, isOnline: true)
        ])
        
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: fourMemberChannel, currentUserId: currentUserId)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingAppearanceAndComponents() {
        class RectIndicator: UIView, MaskProviding {
            override func didMoveToSuperview() {
                super.didMoveToSuperview()
                backgroundColor = .systemPink
                widthAnchor.constraint(equalTo: heightAnchor, multiplier: 1).isActive = true
            }
            
            var maskingPath: CGPath? {
                UIBezierPath(rect: frame.insetBy(dx: -frame.width / 4, dy: -frame.height / 4)).cgPath
            }
        }
        
        var appearance = Appearance()
        var components = Components()
        appearance.colorPalette.alternativeActiveTint = .brown
        components.onlineIndicatorView = RectIndicator.self
        components.imageLoader = MockImageLoader()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.appearance = appearance
        view.components = components
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelAvatarView {
            override func setUpAppearance() {
                presenceAvatarView.onlineIndicatorView.backgroundColor = .red
                backgroundColor = .yellow
            }

            override func setUpLayout() {
                super.setUpLayout()
                NSLayoutConstraint.activate([
                    presenceAvatarView.onlineIndicatorView.leftAnchor.constraint(equalTo: leftAnchor),
                    presenceAvatarView.onlineIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
                    presenceAvatarView.onlineIndicatorView.widthAnchor.constraint(equalToConstant: 20),
                    presenceAvatarView.onlineIndicatorView.heightAnchor.constraint(equalToConstant: 20)
                ])
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
    
    @available(iOS 13.0, *)
    func test_wrappedChatChannelAvatarViewInSwiftUI() {
        struct CustomView: View {
            @EnvironmentObject var components: Components.ObservableObject
            let content: (channel: ChatChannel?, currentUserId: UserId?)
            
            var body: some View {
                components.channelAvatarView.asView(content)
                    .frame(width: 50, height: 50)
            }
        }
        
        final class CustomAvatarView: ChatChannelAvatarView {
            override func setUpAppearance() {
                super.setUpAppearance()
                
                presenceAvatarView.avatarView.imageView.backgroundColor = .red
            }
        }
        
        let channel = ChatChannel.mock(cid: .unique)
        
        var components = Components()
        components.channelAvatarView = CustomAvatarView.self
        let view = CustomView(content: (channel, .unique))
            .environmentObject(components.asObservableObject)
        
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}

private extension ChatChannelAvatarView {
    /// `ChatChannelAvatarView` infers its size from the image but we want the size to be the same for all snapshots.
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 50),
            widthAnchor.constraint(equalToConstant: 50)
        ])
    }
}

/// A mock implementation of the image loader which loads images synchronusly
class MockImageLoader: ImageLoading {
    func loadImage(
        using urlRequest: URLRequest,
        cachingKey: String?,
        completion: @escaping ((Result<UIImage, Error>) -> Void)
    ) -> Cancellable? {
        let image = UIImage(data: try! Data(contentsOf: urlRequest.url!))!
        completion(.success(image))
        return nil
    }
    
    func loadImage(
        into imageView: UIImageView,
        url: URL?,
        imageCDN: ImageCDN,
        placeholder: UIImage?,
        resize: Bool,
        preferredSize: CGSize?,
        completion: ((Result<UIImage, Error>) -> Void)?
    ) -> Cancellable? {
        if let url = url {
            let image = UIImage(data: try! Data(contentsOf: url))!
            imageView.image = image
            completion?(.success(image))
        } else {
            imageView.image = placeholder
        }
        
        return nil
    }
    
    func loadImages(
        from urls: [URL],
        placeholders: [UIImage],
        imageCDN: ImageCDN,
        completion: @escaping (([UIImage]) -> Void)
    ) {
        let images = urls.map { UIImage(data: try! Data(contentsOf: $0))! }
        completion(images)
    }
}
