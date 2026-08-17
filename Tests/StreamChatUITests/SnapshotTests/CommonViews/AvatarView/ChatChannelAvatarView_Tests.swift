//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import SwiftUI
import XCTest

@MainActor final class ChatChannelAvatarView_Tests: XCTestCase {
    var currentUserId: UserId!
    var channel: ChatChannel!

    override func setUp() {
        super.setUp()
        currentUserId = .unique

        channel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
        ])
    }

    func test_emptyAppearance() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance_withDirectMessageChannel() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
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

    func test_defaultAppearance_withDirectMessageChannel_whenMultipleMembers() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.imageProcessingQueue = nil

        channel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url),
            .mock(id: .unique, imageURL: TestImages.chewbacca.url),
            .mock(id: .unique, imageURL: TestImages.r2.url)
        ])

        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearanceWithNoMembersInChannel() {
        let emptyChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [])
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.content = (channel: emptyChannel, currentUserId: currentUserId)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance_withNilChannel_showsPersonIcon() {
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.content = (channel: nil, currentUserId: currentUserId)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance_dmChannel_memberHasNoImageURL_showsInitials() {
        let dmChannel = ChatChannel.mockDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, name: "Leia Organa", imageURL: nil)
        ])
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.content = (channel: dmChannel, currentUserId: currentUserId)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance_groupChannel_membersHaveNoImageURLs_showsInitials() {
        let groupChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, name: "Luke Skywalker", imageURL: nil),
            .mock(id: .unique, name: "Han Solo", imageURL: nil),
            .mock(id: .unique, name: "Leia Organa", imageURL: nil)
        ])
        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.imageProcessingQueue = nil
        view.content = (channel: groupChannel, currentUserId: currentUserId)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearanceWithSingleMemberInNonDMChannel() {
        let singleMemberChannel = ChatChannel.mockNonDMChannel(lastActiveMembers: [
            .mock(id: currentUserId, imageURL: TestImages.vader.url),
            .mock(id: .unique, imageURL: TestImages.yoda.url, isOnline: true)
        ])

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.imageProcessingQueue = nil
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
        view.components = .mock
        view.imageProcessingQueue = nil
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
        view.components = .mock
        view.imageProcessingQueue = nil
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
        view.components = .mock
        view.imageProcessingQueue = nil
        view.content = (channel: fourMemberChannel, currentUserId: currentUserId)

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_loadMergedAvatars_doesNotRecomputeAvatar_whenLastActiveMembersAreReorderedForSameChannel() {
        let cid = ChannelId.unique
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        // Add to a window so that `content` updates trigger `updateContent()`.
        let window = UIWindow()
        window.addSubview(view)

        let memberA: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url)
        let memberB: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.chewbacca.url)
        let memberC: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.r2.url)

        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB, memberC]),
            currentUserId: currentUserId
        )

        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)
        let renderedImage = view.presenceAvatarView.avatarView.imageView.image
        XCTAssertNotNil(renderedImage)

        // Simulate the last active members being reordered for the same channel (e.g. because a
        // member's activity changed). The set of members is unchanged.
        imageMergerSpy.reset()
        view.content = (
            channel: groupChannel(cid: cid, members: [memberC, memberA, memberB]),
            currentUserId: currentUserId
        )

        XCTAssertEqual(imageMergerSpy.mergeCallCount, 0, "The avatar should not be recomputed when the last active members are only reordered")
        XCTAssertTrue(view.presenceAvatarView.avatarView.imageView.image === renderedImage)
    }

    func test_loadMergedAvatars_recomputesAvatar_whenBoundToADifferentChannel() {
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        let window = UIWindow()
        window.addSubview(view)

        view.content = (
            channel: groupChannel(cid: .unique, memberImageURLs: [TestImages.yoda.url, TestImages.chewbacca.url, TestImages.r2.url]),
            currentUserId: currentUserId
        )
        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)

        // Simulate the view being reused for a different channel (e.g. cell reuse).
        imageMergerSpy.reset()
        view.content = (
            channel: groupChannel(cid: .unique, memberImageURLs: [TestImages.vader.url, TestImages.yoda.url, TestImages.chewbacca.url]),
            currentUserId: currentUserId
        )

        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0, "The avatar should be recomputed when bound to a different channel")
    }

    func test_loadMergedAvatars_recomputesAvatar_whenAShownMemberLeavesTheChannel() {
        let cid = ChannelId.unique
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        let window = UIWindow()
        window.addSubview(view)

        let memberA: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url)
        let memberB: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.chewbacca.url)
        let memberC: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.r2.url)

        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB, memberC]),
            currentUserId: currentUserId
        )
        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)

        // Simulate a member that is shown in the avatar leaving the channel.
        imageMergerSpy.reset()
        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB]),
            currentUserId: currentUserId
        )

        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0, "The avatar should be recomputed when a member shown in it leaves the channel")
    }

    func test_loadMergedAvatars_recomputesAvatar_whenAShownMemberIsReplaced() {
        let cid = ChannelId.unique
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        let window = UIWindow()
        window.addSubview(view)

        let memberA: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url)
        let memberB: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.chewbacca.url)
        let memberC: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.r2.url)
        let memberD: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.vader.url)

        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB, memberC]),
            currentUserId: currentUserId
        )
        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)

        // Simulate a member shown in the avatar being replaced by another one. The member count
        // stays the same, but the avatar must reflect the new membership.
        imageMergerSpy.reset()
        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB, memberD]),
            currentUserId: currentUserId
        )

        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0, "The avatar should be recomputed when a member shown in it is replaced even if the member count is unchanged")
    }

    func test_loadMergedAvatars_recomputesAvatar_whenAMemberIsAddedWhileFewerThanTheMaximumAreShown() {
        let cid = ChannelId.unique
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        let window = UIWindow()
        window.addSubview(view)

        let memberA: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url)
        let memberB: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.chewbacca.url)
        let memberC: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.r2.url)

        // The avatar shows two members, fewer than the maximum of four.
        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB]),
            currentUserId: currentUserId
        )
        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)

        // A member is added. Since the avatar wasn't full, the new member should be shown.
        imageMergerSpy.reset()
        view.content = (
            channel: groupChannel(cid: cid, members: [memberA, memberB, memberC]),
            currentUserId: currentUserId
        )

        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0, "The avatar should be recomputed when a member is added while it shows fewer than the maximum number of members")
    }

    func test_loadMergedAvatars_doesNotRecomputeAvatar_whenANonShownMemberLeavesTheChannel() {
        let cid = ChannelId.unique
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        let window = UIWindow()
        window.addSubview(view)

        // The avatar shows at most four members, the four that joined earliest. The fifth member
        // (latest `memberCreatedAt`) is therefore not shown in the avatar.
        let shown1: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url, memberCreatedAt: Date(timeIntervalSince1970: 1))
        let shown2: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.chewbacca.url, memberCreatedAt: Date(timeIntervalSince1970: 2))
        let shown3: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.r2.url, memberCreatedAt: Date(timeIntervalSince1970: 3))
        let shown4: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.vader.url, memberCreatedAt: Date(timeIntervalSince1970: 4))
        let notShown: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url, memberCreatedAt: Date(timeIntervalSince1970: 5))

        view.content = (
            channel: groupChannel(cid: cid, members: [shown1, shown2, shown3, shown4, notShown]),
            currentUserId: currentUserId
        )
        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)
        let renderedImage = view.presenceAvatarView.avatarView.imageView.image

        // Simulate the member that isn't shown in the avatar leaving the channel.
        imageMergerSpy.reset()
        view.content = (
            channel: groupChannel(cid: cid, members: [shown1, shown2, shown3, shown4]),
            currentUserId: currentUserId
        )

        XCTAssertEqual(imageMergerSpy.mergeCallCount, 0, "The avatar should not be recomputed when a member that isn't shown in it changes")
        XCTAssertTrue(view.presenceAvatarView.avatarView.imageView.image === renderedImage)
    }

    func test_loadMergedAvatars_doesNotRecomputeAvatar_whenANonShownMemberIsAddedToTheChannel() {
        let cid = ChannelId.unique
        let imageMergerSpy = ImageMergerSpy()

        let view = ChatChannelAvatarView().withoutAutoresizingMaskConstraints
        view.components = .mock
        view.imageProcessingQueue = nil
        view.imageMerger = imageMergerSpy
        let window = UIWindow()
        window.addSubview(view)

        let shown1: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url, memberCreatedAt: Date(timeIntervalSince1970: 1))
        let shown2: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.chewbacca.url, memberCreatedAt: Date(timeIntervalSince1970: 2))
        let shown3: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.r2.url, memberCreatedAt: Date(timeIntervalSince1970: 3))
        let shown4: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.vader.url, memberCreatedAt: Date(timeIntervalSince1970: 4))

        view.content = (
            channel: groupChannel(cid: cid, members: [shown1, shown2, shown3, shown4]),
            currentUserId: currentUserId
        )
        XCTAssertGreaterThan(imageMergerSpy.mergeCallCount, 0)
        let renderedImage = view.presenceAvatarView.avatarView.imageView.image

        // Simulate a new member joining. The four shown members joined earlier, so the new member
        // isn't shown in the avatar and it stays unchanged.
        imageMergerSpy.reset()
        let newMember: ChatChannelMember = .mock(id: .unique, imageURL: TestImages.yoda.url, memberCreatedAt: Date(timeIntervalSince1970: 5))
        view.content = (
            channel: groupChannel(cid: cid, members: [shown1, shown2, shown3, shown4, newMember]),
            currentUserId: currentUserId
        )

        XCTAssertEqual(imageMergerSpy.mergeCallCount, 0, "The avatar should not be recomputed when a newly added member isn't shown in it")
        XCTAssertTrue(view.presenceAvatarView.avatarView.imageView.image === renderedImage)
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

        let appearance = Appearance()
        var components = Components.mock
        appearance.colorPalette.accentSuccess = .brown
        components.onlineIndicatorView = RectIndicator.self

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
        view.components = .mock
        view.content = (channel: channel, currentUserId: currentUserId)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }
}

private extension ChatChannelAvatarView_Tests {
    /// Creates a group channel (more than two members) whose avatar is rendered by merging member images.
    func groupChannel(cid: ChannelId, memberImageURLs: [URL]) -> ChatChannel {
        var members: [ChatChannelMember] = [.mock(id: currentUserId, imageURL: TestImages.vader.url)]
        members += memberImageURLs.map { .mock(id: .unique, imageURL: $0) }
        return .mock(cid: cid, lastActiveMembers: members, memberCount: members.count)
    }

    /// Creates a group channel from the given members (plus the current user) whose avatar is rendered
    /// by merging member images. Lets tests control member identity to model reordering and membership changes.
    func groupChannel(cid: ChannelId, members otherMembers: [ChatChannelMember]) -> ChatChannel {
        let currentUserMember: ChatChannelMember = .mock(id: currentUserId, imageURL: TestImages.vader.url)
        let members = [currentUserMember] + otherMembers
        return .mock(cid: cid, lastActiveMembers: members, memberCount: members.count)
    }
}

/// An `ImageMerging` spy that counts how many times the merge happens while delegating to the default merger.
private final class ImageMergerSpy: ImageMerging, @unchecked Sendable {
    private let wrapped = DefaultImageMerger()
    private let lock = NSLock()
    private var count = 0

    var mergeCallCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return count
    }

    func reset() {
        lock.lock()
        count = 0
        lock.unlock()
    }

    func merge(images: [UIImage], orientation: ImageMergeOrientation) -> UIImage? {
        lock.lock()
        count += 1
        lock.unlock()
        return wrapped.merge(images: images, orientation: orientation)
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
