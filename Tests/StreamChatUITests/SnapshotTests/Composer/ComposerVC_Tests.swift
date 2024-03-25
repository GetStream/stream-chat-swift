//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ComposerVC_Tests: XCTestCase {
    private var composerVC: ComposerVC!
    var mockedChatChannelController: ChatChannelController_Mock!
    
    // MARK: - Lifecycle

    /// Static setUp() is only run once. Which is what we want in this case to preload the images.
    override class func setUp() {
        /// Dummy snapshot to preload the TestImages.yoda.url image
        /// This was the only workaround to make sure the image always appears in the snapshots.
        let view = UIImageView(frame: .init(center: .zero, size: .init(width: 100, height: 100)))
        Components.default.imageLoader.loadImage(into: view, from: TestImages.yoda.url)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    override func setUp() {
        super.setUp()
        let chatClient = ChatClient_Mock.mock
        chatClient.mockAuthenticationRepository.mockedCurrentUserId = .newUniqueId
        mockedChatChannelController = ChatChannelController_Mock.mock(chatClient: chatClient)
        mockedChatChannelController.channel_mock = .mock(
            cid: .unique,
            config: .mock(commands: []),
            ownCapabilities: [.sendMessage]
        )

        composerVC = .init()
        composerVC.channelController = mockedChatChannelController
    }
    
    override func tearDown() {
        composerVC = nil
        mockedChatChannelController = nil
        super.tearDown()
    }
    
    // MARK: - Search
    
    func test_userFound_whenSearchedByIDOrName() throws {
        let user1 = ChatUser.mock(id: "searchingThis")
        let user2 = ChatUser.mock(id: "x", name: "searchingThis")
        
        XCTAssertEqual(searchUsers([user1], by: "sear"), [user1])
        XCTAssertEqual(searchUsers([user2], by: "sear"), [user2])
    }
    
    func test_usersFound_whenSearchedWithTieBreaker() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]
        
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
        XCTAssertEqual(searchUsers(users, by: ""), [thierry, tommaso])
    }
    
    func test_userFound_whenTypingTheBeginningOfIDOrName() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]
        
        XCTAssertEqual(searchUsers(users, by: "tom"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "thier"), [thierry])
    }
    
    func test_userFound_whenStartOfTheNameMatchesCase() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]
        
        XCTAssertEqual(searchUsers(users, by: "Tom"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "Thier"), [thierry])
    }
    
    func test_userFound_whenNameIsTransliterated() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "Tommaso")
        let thierry = ChatUser.mock(id: "thierry", name: "Thierry")
        let users = [tommaso, thierry]
        
        XCTAssertEqual(searchUsers(users, by: "tóm"), [tommaso])
        XCTAssertEqual(searchUsers(users, by: "thíer"), [thierry])
    }
    
    func test_usersFoundAndSorted_whenSearchedByBeginningOfNameOrID() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tomas = ChatUser.mock(id: "tomas", name: "tomas")
        let users = [tommaso, tomas]
        
        XCTAssertEqual(searchUsers(users, by: "tom"), [tomas, tommaso])
    }
    
    func test_userFound_whenHappySortedByDistancePrefix() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tommasi = ChatUser.mock(id: "tommasi", name: "tommasi")
        let users = [tommaso, tommasi]
        
        XCTAssertEqual(searchUsers(users, by: "t"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "to"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tom"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomm"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomma"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommas"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommaso"), [tommaso])
    }
    
    func test_userFound_whenHappySortedByDistancePrefix2() throws {
        let tommaso = ChatUser.mock(id: "tommaso", name: "tommaso")
        let tommasi = ChatUser.mock(id: "tommasi", name: "tommasi")
        let users = [tommasi, tommaso]
        
        XCTAssertEqual(searchUsers(users, by: "t"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "to"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tom"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomm"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tomma"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommas"), [tommasi, tommaso])
        XCTAssertEqual(searchUsers(users, by: "tommaso"), [tommaso])
    }
    
    func test_userFound_whenHappyCyrillic() throws {
        let petyo = ChatUser.mock(id: "42", name: "Петьо")
        let anastasia = ChatUser.mock(id: "13", name: "Анастасiя")
        let dmitriy = ChatUser.mock(id: "99", name: "Дмитрий")
        let users = [petyo, anastasia, dmitriy]
        
        XCTAssertEqual(searchUsers(users, by: "petyo"), [])
        XCTAssertEqual(searchUsers(users, by: "Пе"), [petyo])
        XCTAssertEqual(searchUsers(users, by: "Ана"), [anastasia])
        XCTAssertEqual(searchUsers(users, by: "Дмитрии"), [dmitriy])
        XCTAssertEqual(searchUsers(users, by: "Дмитри"), [dmitriy])
    }
    
    func test_userFound_whenHappyFrench() throws {
        let user = ChatUser.mock(id: "fra", name: "françois")
        
        XCTAssertEqual(searchUsers([user], by: "françois"), [user])
        XCTAssertEqual(searchUsers([user], by: "franc"), [user])
    }
    
    // MARK: - attachmentsPreview
    
    func test_attachmentsPreview_withFourAttachments_addedSameTime() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile, .mockFile, .mockFile]
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withFourAttachments_addedOneAfterThree() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile, .mockFile]
        
        composerVC.content.attachments.append(.mockFile)
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withFourAttachments_addedTwoAfterTwo() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile]
        
        composerVC.content.attachments.append(contentsOf: [.mockFile, .mockFile])
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withFourAttachments_addedThreeAfterOne() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile]
        
        composerVC.content.attachments.append(contentsOf: [.mockFile, .mockFile, .mockFile])
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withMultipleAttachmentTypes() {
        composerVC.appearance = Appearance.default

        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFile, .mockFile, .mockImage, .mockVideo]
        
        AssertSnapshot(composerVC)
    }
    
    func test_attachmentsPreview_withLongFileNames() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockFileWithLongName]
        
        AssertSnapshot(composerVC, variants: [.defaultLight])
    }
    
    func test_commandWithNonEmptyArgs_hasSendButtonDisabled() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.addCommand(.init(
            name: "ARGNEEDED",
            description: "some command",
            set: "special",
            args: "[text]"
        ))
        
        AssertSnapshot(composerVC)
    }
    
    func test_commandWithEmptyArgs_hasSendButtonEnabled() {
        composerVC.appearance = Appearance.default
        
        composerVC.content = .initial()
        composerVC.content.addCommand(.init(
            name: "NOARGNEEDED",
            description: "some command",
            set: "special",
            args: ""
        ))
        
        AssertSnapshot(composerVC)
    }

    func test_makeMentionSuggestionsDataSource_whenMentionAllAppUsers_shouldSearchUsers() throws {
        composerVC.components.mentionAllAppUsers = true
        composerVC.channelController = mockedChatChannelController
        let mockedSearchController = ChatUserSearchController_Mock.mock()
        mockedSearchController.users_mock = [.mock(id: .unique, name: "1"), .mock(id: .unique, name: "2")]
        composerVC.userSearchController = mockedSearchController

        // When empty, should not search.
        _ = composerVC.makeMentionSuggestionsDataSource(for: "")
        XCTAssertEqual(mockedSearchController.searchCallCount, 0)

        // When mention already exists, should not search.
        composerVC.content.mentionedUsers.insert(.mock(id: .unique, name: "Han Solo"))
        let existingMentionDataSource = try XCTUnwrap(composerVC.makeMentionSuggestionsDataSource(for: "Han Solo"))
        XCTAssertEqual(mockedSearchController.searchCallCount, 0)

        // Happy path
        let dataSource = try XCTUnwrap(composerVC.makeMentionSuggestionsDataSource(for: "Leia"))
        XCTAssertNil(dataSource.memberListController)
        XCTAssertEqual(dataSource.users, mockedSearchController.users_mock ?? [])
        XCTAssertEqual(mockedSearchController.searchCallCount, 1)
    }

    func test_makeMentionSuggestionsDataSource_whenMentionAllAppUsersIsFalse_whenMemberCountBiggerThanLocalMembers_shouldSearchChannelMembers() throws {
        composerVC.components.mentionAllAppUsers = false
        composerVC.channelController = mockedChatChannelController
        mockedChatChannelController.channel_mock = .mock(cid: .unique, lastActiveMembers: [.dummy, .dummy], memberCount: 10)
        let mockedSearchController = ChatUserSearchController_Mock.mock()
        mockedSearchController.users_mock = []
        composerVC.userSearchController = mockedSearchController

        // When empty, should not create member list controller.
        let emptyDataSource = try XCTUnwrap(composerVC.makeMentionSuggestionsDataSource(for: ""))
        XCTAssertNil(emptyDataSource.memberListController)

        // When mention already exists, should not create member list controller.
        composerVC.content.mentionedUsers.insert(.mock(id: .unique, name: "Han Solo"))
        let existingMentionDataSource = try XCTUnwrap(composerVC.makeMentionSuggestionsDataSource(for: "Han Solo"))
        XCTAssertNil(existingMentionDataSource.memberListController)

        // Happy path
        let dataSource = try XCTUnwrap(composerVC.makeMentionSuggestionsDataSource(for: "Leia"))
        XCTAssertNotNil(dataSource.memberListController)
        XCTAssertEqual(dataSource.memberListController?.state, .localDataFetched)
        XCTAssertEqual(mockedSearchController.searchCallCount, 0)
    }

    func test_makeMentionSuggestionsDataSource_whenMentionAllAppUsersIsFalse_whenMemberCountLowerThanLocalMembers_shoudSearchLocalMembers() throws {
        composerVC.components.mentionAllAppUsers = false
        composerVC.channelController = mockedChatChannelController
        mockedChatChannelController.channel_mock = .mock(
            cid: .unique,
            lastActiveMembers: [.mock(id: .unique, name: "Leia Organa"), .mock(id: .unique, name: "Leia Rockstar")],
            memberCount: 2
        )
        let mockedSearchController = ChatUserSearchController_Mock.mock()
        mockedSearchController.users_mock = []
        composerVC.userSearchController = mockedSearchController

        // When empty, should still return a data source to include all local members.
        XCTAssertNotNil(composerVC.makeMentionSuggestionsDataSource(for: ""))

        let dataSource = try XCTUnwrap(composerVC.makeMentionSuggestionsDataSource(for: "Leia"))
        XCTAssertNil(dataSource.memberListController)
        XCTAssertEqual(dataSource.users, mockedChatChannelController.channel?.lastActiveMembers)
        XCTAssertEqual(dataSource.users.isEmpty, false)
        XCTAssertEqual(mockedSearchController.searchCallCount, 0)
    }

    func test_channelWithSlowModeActive_messageIsSent_SlowModeIsOnWithCountdownShown() {
        composerVC.appearance = Appearance.default
        composerVC.content.text = "Test text"
        composerVC.content.slowMode(cooldown: 120)
        composerVC.composerView.inputMessageView.textView.placeholderLabel.isHidden = true
        
        AssertSnapshot(composerVC)
    }
    
    func test_channelWithSlowModeActive_messageIsSent_SkipSlowModeIsOnWithCountdownShown() {
        let channel = ChatChannel.mock(cid: .unique, ownCapabilities: [.skipSlowMode, .sendMessage], cooldownDuration: 10)
        mockedChatChannelController.channel_mock = channel
        composerVC.channelController = mockedChatChannelController
        composerVC.appearance = Appearance.default
        composerVC.publishMessage(sender: UIButton())
        composerVC.content.text = "Test text"
        composerVC.composerView.inputMessageView.textView.placeholderLabel.isHidden = true
        
        AssertSnapshot(composerVC, variants: [.defaultLight])
    }
    
    func test_didUpdateMessages_startsCooldown() {
        let mockedCooldownTracker = CooldownTracker_Mock(timer: ScheduledStreamTimer_Mock())
        composerVC.cooldownTracker = mockedCooldownTracker
        
        composerVC.channelController(ChatChannelController_Mock.mock(), didUpdateMessages: [])
        
        XCTAssertEqual(mockedCooldownTracker.startCallCount, 1)
    }

    func test_editMessage_addsAttachmentsToContent() {
        // Given
        var content = ComposerVC.Content.initial()
        XCTAssertEqual(content.attachments.count, 0)

        // When
        let messageId = MessageId.unique

        let encoder = JSONEncoder.default
        let attachments: [AnyChatMessageAttachment] = [
            MessageAttachmentPayload.dummy(type: .image),
            MessageAttachmentPayload.dummy(type: .image)
        ].compactMap {
            guard let payload = try? encoder.encode($0.payload) else { return nil }
            return AnyChatMessageAttachment.dummy(type: $0.type, payload: payload)
        }
        let message = ChatMessage.mock(id: messageId, attachments: attachments)
        content.editMessage(message)

        // Then
        let contentAttachmentTypes = content.attachments.map(\.type)
        XCTAssertEqual(content.attachments.count, 2)
        XCTAssertEqual(contentAttachmentTypes, [.image, .image])
    }

    func test_canUploadFiles_hasAttachmentButtonShown() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile, .sendMessage])
        composerVC.channelController = mock
        composerVC.updateContent()

        XCTAssertEqual(composerVC.composerView.attachmentButton.isHidden, false)
    }

    func test_canUploadFiles_hasRecordButtonShown() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()

        var components = Components.default
        components.isVoiceRecordingEnabled = true
        composerVC.components = components

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile, .sendMessage])
        composerVC.channelController = mock
        composerVC.updateContent()

        XCTAssertEqual(composerVC.composerView.recordButton.isHidden, false)
    }

    func test_canNotUploadFiles_hasAttachmentButtonHidden() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.sendMessage])
        composerVC.channelController = mock
        composerVC.updateContent()

        XCTAssertEqual(composerVC.composerView.attachmentButton.isHidden, true)
    }

    func test_canNotUploadFiles_hasRecordButtonHidden() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.sendMessage])
        composerVC.channelController = mock
        composerVC.updateContent()

        XCTAssertEqual(composerVC.composerView.recordButton.isHidden, true)
    }

    func test_isAttachmentsEnabled_whenChannelIsEmpty_thenReturnsTrue() {
        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = nil
        composerVC.channelController = mock
        XCTAssertEqual(composerVC.isAttachmentsEnabled, true)
    }

    func test_canNotSendMessage() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile])
        composerVC.channelController = mock

        AssertSnapshot(composerVC)
    }

    func test_isSendMessageEnabled_whenChannelIsEmpty_thenReturnsTrue() {
        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = nil
        composerVC.channelController = mock
        XCTAssertEqual(composerVC.isSendMessageEnabled, true)
    }

    func test_updateContent_whenSendMessageEnabledAfterBeingDisabled_thenComposerViewIsInteractable() {
        let mock = ChatChannelController_Mock.mock()
        composerVC.components.isVoiceRecordingEnabled = true

        // When disabled
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile])
        composerVC.channelController = mock
        composerVC.updateContent()
        XCTAssertEqual(composerVC.isSendMessageEnabled, false)
        XCTAssertEqual(composerVC.composerView.inputMessageView.isUserInteractionEnabled, false)
        XCTAssertEqual(composerVC.composerView.recordButton.isHidden, true)
        XCTAssertEqual(composerVC.composerView.attachmentButton.isHidden, true)
        XCTAssertEqual(composerVC.composerView.commandsButton.isHidden, true)

        // After enabling it
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile, .sendMessage])
        composerVC.channelController = mock
        composerVC.updateContent()
        XCTAssertEqual(composerVC.isSendMessageEnabled, true)
        XCTAssertEqual(composerVC.composerView.inputMessageView.isUserInteractionEnabled, true)
        XCTAssertEqual(composerVC.composerView.recordButton.isHidden, false)
        XCTAssertEqual(composerVC.composerView.attachmentButton.isHidden, false)
        XCTAssertEqual(composerVC.composerView.commandsButton.isHidden, false)
    }

    func test_quotedTranslatedMessage() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()
        composerVC.content.text = "Reply"
        composerVC.content.quoteMessage(.mock(id: .unique, translations: [.portuguese: "Olá"]))

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, membership: .mock(id: .unique, language: .portuguese))
        composerVC.channelController = mock

        AssertSnapshot(composerVC)
    }

    func test_canNotSendLinks() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()
        composerVC.content.text = "Some link: https://github.com/GetStream/stream-chat-swift"

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile, .sendMessage])
        composerVC.channelController = mock
        composerVC.publishMessage(sender: composerVC.composerView.sendButton)

        XCTAssertEqual(mock.createNewMessageCallCount, 0)

        composerVC.content.text = "Without links"
        composerVC.publishMessage(sender: composerVC.composerView.sendButton)

        XCTAssertEqual(mock.createNewMessageCallCount, 1)
        XCTAssertEqual(composerVC.canSendLinks, false)
    }

    func test_canSendLinks() {
        composerVC.appearance = Appearance.default
        composerVC.content = .initial()
        composerVC.content.text = "Some link: https://github.com/GetStream/stream-chat-swift"

        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = .mock(cid: .unique, ownCapabilities: [.uploadFile, .sendMessage, .sendLinks])
        composerVC.channelController = mock
        composerVC.publishMessage(sender: composerVC.composerView.sendButton)

        XCTAssertEqual(mock.createNewMessageCallCount, 1)
        XCTAssertEqual(composerVC.canSendLinks, true)
    }

    func test_canSendLinks_whenChannelIsEmpty() {
        let mock = ChatChannelController_Mock.mock()
        mock.channel_mock = nil
        composerVC.channelController = mock
        XCTAssertEqual(composerVC.canSendLinks, true)
    }

    // MARK: - Link preview

    func test_linkPreview_whenComposerLinkPreviewEnabled_thenHighlightsLinks() {
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.components.isComposerLinkPreviewEnabled = true

        AssertSnapshot(composerVC, variants: [.defaultLight])
    }

    func test_linkPreview_whenComposerLinkPreviewDisabled_thenNoHighlighting() {
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.components.isComposerLinkPreviewEnabled = false

        AssertSnapshot(composerVC, variants: [.defaultLight])
    }

    func test_linkPreview_whenLinksChange_thenOnLinksChangedCalled() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()

        var links: [TextLink] = []
        let exp = expectation(description: "onLinksChanged called")
        composerVC.composerView.inputMessageView.textView.onLinksChanged = { newLinks in
            links = newLinks
            exp.fulfill()
        }

        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.youtube.com
        """
        composerVC.updateContent()

        waitForExpectations(timeout: defaultTimeout)

        XCTAssertEqual(links.map(\.originalText), [
            "https://github.com/GetStream/stream-chat-swift",
            "www.youtube.com"
        ])
    }

    func test_linkPreview_whenLinksDoNotChange_thenOnLinksChangedNotCalled() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()

        let exp = expectation(description: "onLinksChanged not called")
        exp.isInverted = true
        composerVC.composerView.inputMessageView.textView.onLinksChanged = { _ in
            exp.fulfill()
        }

        composerVC.content.text = """
        Same: https://github.com/GetStream/stream-chat-swift
        Same: www.google.com
        """
        composerVC.updateContent()

        waitForExpectations(timeout: defaultTimeout)
    }

    func test_showLinkPreview() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()
        composerVC.showLinkPreview(for: .init(
            originalURL: .init(string: "https://github.com/GetStream/stream-chat-swift")!,
            title: "GitHub - GetStream/stream-chat-swift",
            text: "iOS Chat SDK in Swift",
            previewURL: .localYodaImage
        ))

        AssertSnapshot(composerVC.view, size: .init(width: 400, height: 140))
        XCTAssertEqual(composerVC.content.skipEnrichUrl, false)
    }

    func test_showLinkPreview_whenNoImage() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()
        composerVC.showLinkPreview(for: .init(
            originalURL: .init(string: "https://github.com/GetStream/stream-chat-swift")!,
            title: "GitHub - GetStream/stream-chat-swift",
            text: "iOS Chat SDK in Swift"
        ))

        AssertSnapshot(composerVC.view, variants: [.defaultLight], size: .init(width: 400, height: 140))
    }

    func test_showLinkPreview_whenNoDescription() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()
        composerVC.showLinkPreview(for: .init(
            originalURL: .init(string: "https://github.com/GetStream/stream-chat-swift")!,
            title: "GitHub - GetStream/stream-chat-swift"
        ))

        AssertSnapshot(composerVC.view, variants: [.defaultLight], size: .init(width: 400, height: 140))
    }

    func test_showLinkPreview_whenNoTitle() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()
        composerVC.showLinkPreview(for: .init(
            originalURL: .init(string: "https://github.com/GetStream/stream-chat-swift")!,
            text: "iOS Chat SDK in Swift"
        ))

        AssertSnapshot(composerVC.view, variants: [.defaultLight], size: .init(width: 400, height: 140))
    }

    func test_showLinkPreview_whenNoMetadata() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()
        composerVC.showLinkPreview(for: .init(
            originalURL: .init(string: "https://github.com/GetStream/stream-chat-swift")!
        ))

        AssertSnapshot(composerVC.view, variants: [.defaultLight], size: .init(width: 400, height: 140))
    }

    func test_dismissLinkPreview() {
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        composerVC.channelController = mock
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()
        composerVC.showLinkPreview(for: .init(
            originalURL: .init(string: "https://github.com/GetStream/stream-chat-swift")!
        ))
        composerVC.dismissLinkPreview()

        AssertSnapshot(composerVC, variants: [.defaultLight])
        XCTAssertEqual(composerVC.content.skipEnrichUrl, true)
    }

    func test_didChangeLinks_whenEmpty_thenDismissLinkPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        composerVC.channelController = mock
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()

        composerVC.didChangeLinks([])

        XCTAssertEqual(composerVC.dismissLinkPreviewCallCount, 1)
    }

    func test_didChangeLinks_whenEnrichSuccess_thenShowPreviewForFirstLink() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        let mockAPIClient = mock.client.mockAPIClient
        composerVC.channelController = mock
        composerVC.enrichUrlDebouncer = .init(0, queue: .main)
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()

        let url = URL(string: "https://github.com/GetStream/stream-chat-swift")!
        mockAPIClient.test_mockResponseResult(.success(LinkAttachmentPayload(
            originalURL: url
        )))

        composerVC.didChangeLinks([
            .init(url: url, originalText: "https://github.com/GetStream/stream-chat-swift", range: .init(location: 0, length: 0)),
            .init(url: URL(string: "http://www.google.com")!, originalText: "www.google.com", range: .init(location: 0, length: 0))
        ])

        AssertAsync {
            Assert.willBeEqual(composerVC.showLinkPreviewCallCount, 1)
            Assert.willBeEqual(composerVC.showLinkPreviewCalledWith?.url, url)
        }
    }

    func test_didChangeLinks_whenEnrichSuccess_whenUrlDoesNotEqualToCurrentInput_thenDoNotCallShowPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        let mockAPIClient = mock.client.mockAPIClient
        composerVC.channelController = mock
        composerVC.enrichUrlDebouncer = .init(0, queue: .main)
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swiftui
        Another one: www.google.com
        """
        composerVC.updateContent()

        let url = URL(string: "https://github.com/GetStream/stream-chat-swift")!
        mockAPIClient.test_mockResponseResult(.success(LinkAttachmentPayload(
            originalURL: url
        )))

        composerVC.didChangeLinks([
            .init(url: url, originalText: "https://github.com/GetStream/stream-chat-swift", range: .init(location: 0, length: 0)),
            .init(url: URL(string: "http://www.google.com")!, originalText: "www.google.com", range: .init(location: 0, length: 0))
        ])

        AssertAsync {
            Assert.willBeEqual(composerVC.showLinkPreviewCallCount, 0)
            Assert.willBeEqual(composerVC.dismissLinkPreviewCallCount, 0)
        }
    }

    func test_didChangeLinks_whenEnrichFails_thenDismissLinkPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        let mockAPIClient = mock.client.mockAPIClient
        composerVC.channelController = mock
        composerVC.enrichUrlDebouncer = .init(0, queue: .main)
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()

        let url = URL(string: "https://github.com/GetStream/stream-chat-swift")!
        mockAPIClient.test_mockResponseResult(Result<LinkAttachmentPayload, Error>.failure(ClientError()))

        composerVC.didChangeLinks([
            .init(url: url, originalText: "https://github.com/GetStream/stream-chat-swift", range: .init(location: 0, length: 0)),
            .init(url: URL(string: "http://www.google.com")!, originalText: "www.google.com", range: .init(location: 0, length: 0))
        ])

        AssertAsync {
            Assert.willBeEqual(composerVC.dismissLinkPreviewCallCount, 1)
        }
    }

    func test_didChangeLinks_whenEnrichFails_whenUrlDoesNotEqualToCurrentInput_thenDoNotCallDismissPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        let mockAPIClient = mock.client.mockAPIClient
        composerVC.channelController = mock
        composerVC.enrichUrlDebouncer = .init(0, queue: .main)
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swiftui
        Another one: www.google.com
        """
        composerVC.updateContent()

        let url = URL(string: "https://github.com/GetStream/stream-chat-swift")!
        mockAPIClient.test_mockResponseResult(Result<LinkAttachmentPayload, Error>.failure(ClientError()))

        composerVC.didChangeLinks([
            .init(url: url, originalText: "https://github.com/GetStream/stream-chat-swift", range: .init(location: 0, length: 0)),
            .init(url: URL(string: "http://www.google.com")!, originalText: "www.google.com", range: .init(location: 0, length: 0))
        ])

        AssertAsync {
            Assert.willBeEqual(composerVC.showLinkPreviewCallCount, 0)
            Assert.willBeEqual(composerVC.dismissLinkPreviewCallCount, 0)
        }
    }

    func test_didChangeLinks_whenEnrichNotEnabled_thenDoNotShowLinkPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: false))
        let mockAPIClient = mock.client.mockAPIClient
        composerVC.channelController = mock
        composerVC.enrichUrlDebouncer = .init(0, queue: .main)
        composerVC.content = .initial()
        composerVC.content.text = """
        Some link: https://github.com/GetStream/stream-chat-swift
        Another one: www.google.com
        """
        composerVC.updateContent()

        let url = URL(string: "https://github.com/GetStream/stream-chat-swift")!
        mockAPIClient.test_mockResponseResult(Result<LinkAttachmentPayload, Error>.failure(ClientError()))

        composerVC.didChangeLinks([
            .init(url: url, originalText: "https://github.com/GetStream/stream-chat-swift", range: .init(location: 0, length: 0)),
            .init(url: URL(string: "http://www.google.com")!, originalText: "www.google.com", range: .init(location: 0, length: 0))
        ])

        AssertAsync {
            Assert.willBeEqual(composerVC.dismissLinkPreviewCallCount, 0)
            Assert.willBeEqual(composerVC.showLinkPreviewCallCount, 0)
            Assert.willBeEqual(mockAPIClient.request_allRecordedCalls.count, 0)
        }
    }

    func test_didChangeLinks_whenMultipleAttachmentTypes_thenDismissLinkPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        composerVC.channelController = mock
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockAudio, .mockFile]

        composerVC.didChangeLinks([.init(url: .localYodaImage, originalText: "fake", range: .init(location: 0, length: 10))])

        XCTAssertEqual(composerVC.dismissLinkPreviewCallCount, 1)
    }

    func test_updateContent_whenMultipleAttachmentTypes_whenSkipEnrichUrlIsFalse_thenDismissLinkPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        composerVC.channelController = mock
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockAudio, .mockFile]
        composerVC.content.skipEnrichUrl = false

        composerVC.updateContent()

        XCTAssertEqual(composerVC.dismissLinkPreviewCallCount, 1)
    }

    func test_updateContent_whenMultipleAttachmentTypes_whenSkipEnrichUrlIsTrue_thenDoNotCallDismissLinkPreview() {
        let composerVC = SpyComposerVC()
        composerVC.components.isComposerLinkPreviewEnabled = true
        let mock = ChatChannelController_Mock.mock(client: .mock())
        mock.channel_mock = .mockNonDMChannel(config: .mock(urlEnrichmentEnabled: true))
        composerVC.channelController = mock
        composerVC.content = .initial()
        composerVC.content.attachments = [.mockAudio, .mockFile]
        composerVC.content.skipEnrichUrl = true

        composerVC.updateContent()

        XCTAssertEqual(composerVC.dismissLinkPreviewCallCount, 0)
    }

    // MARK: - maxAttachmentSize

    func test_maxAttachmentSize_whenChannelControllerNotSet_thenReturnsDefaultFallbackLimit() {
        composerVC.channelController = nil
        XCTAssertEqual(composerVC.maxAttachmentSize(for: .file), AttachmentValidationError.fileSizeMaxLimitFallback)
    }

    func test_maxAttachmentSize_whenImageType_thenReturnsLimitFromImageUploadConfig() {
        let expectedValue: Int64 = 50 * 1024 * 1024
        let chatClient = ChatClient_Mock.mock
        chatClient.mockedAppSettings = .mock(imageUploadConfig: .mock(
            sizeLimitInBytes: expectedValue
        ))
        composerVC.channelController = ChatChannelController_Mock.mock(chatClient: chatClient)

        XCTAssertEqual(composerVC.maxAttachmentSize(for: .image), expectedValue)
    }

    func test_maxAttachmentSize_whenFileType_thenReturnsLimitFromFileUploadConfig() {
        let expectedValue: Int64 = 50 * 1024 * 1024
        let chatClient = ChatClient_Mock.mock
        chatClient.mockedAppSettings = .mock(fileUploadConfig: .mock(
            sizeLimitInBytes: expectedValue
        ))
        composerVC.channelController = ChatChannelController_Mock.mock(chatClient: chatClient)

        XCTAssertEqual(composerVC.maxAttachmentSize(for: .file), expectedValue)
    }

    func test_maxAttachmentSize_whenOtherType_thenReturnsLimitFromFileUploadConfig() {
        let expectedValue: Int64 = 50 * 1024 * 1024
        let chatClient = ChatClient_Mock.mock
        chatClient.mockedAppSettings = .mock(fileUploadConfig: .mock(
            sizeLimitInBytes: expectedValue
        ))
        composerVC.channelController = ChatChannelController_Mock.mock(chatClient: chatClient)

        XCTAssertEqual(composerVC.maxAttachmentSize(for: .video), expectedValue)
    }

    func test_maxAttachmentSize_whenSizeLimitNotDefined_thenReturnsLimitFromChatClientConfig() {
        let expectedValue: Int64 = 50 * 1024 * 1024
        var config = ChatClientConfig(apiKeyString: "sadsad")
        config.maxAttachmentSize = expectedValue
        composerVC.channelController = ChatChannelController_Mock.mock(chatClientConfig: config)

        XCTAssertEqual(composerVC.maxAttachmentSize(for: .image), expectedValue)
    }

    // MARK: - audioPlayer
    
    func test_audioPlayer_voiceRecordingAndAttachmentsVCGetTheSameInstance() {
        let audioPlayer = StreamAudioPlayer()
        
        composerVC.audioPlayer = audioPlayer
        
        XCTAssertTrue(composerVC.voiceRecordingVC.audioPlayer === audioPlayer)
        XCTAssertTrue(composerVC.attachmentsVC.audioPlayer === audioPlayer)
    }
    
    // MARK: - voiceRecordingVC
    
    func test_voiceRecordingVC_getsAReferenceOfTheExpectedComposerView() {
        XCTAssertTrue(composerVC.voiceRecordingVC.view === composerVC.composerView)
    }
    
    // MARK: - setUp
    
    func test_setUp_voiceRecordingVCWasConfiguredCorrectly() {
        final class MockVoiceRecordingVC: VoiceRecordingVC {
            var setUpWasCalled = false
            var didMoveToParentWasCalledWithParent: UIViewController?
            override func setUp() { setUpWasCalled = true }
            override func didMove(toParent parent: UIViewController?) { didMoveToParentWasCalledWithParent = parent }
        }
        
        let mockVoiceRecordingVC = MockVoiceRecordingVC(composerView: composerVC.composerView)
        composerVC.voiceRecordingVC = mockVoiceRecordingVC
        
        composerVC.setUp()
        
        XCTAssertTrue(composerVC.voiceRecordingVC.delegate === composerVC)
        XCTAssertNotNil(composerVC.children.first { $0 === composerVC.voiceRecordingVC })
        XCTAssertTrue(mockVoiceRecordingVC.setUpWasCalled)
        XCTAssertTrue(mockVoiceRecordingVC.didMoveToParentWasCalledWithParent === composerVC)
    }
    
    // MARK: - voiceRecording(_:addAttachmentFromLocation:duration:waveformData:)
    
    func test_voiceRecordingAddAttachment_attachmentWasConfiguredCorrectly() throws {
        let expectedURL: URL = URL(fileURLWithPath: "/tmp/\(UUID().uuidString)")
        let expectedDuration: TimeInterval = 100
        let expectedWaveformData: [Float] = .init(repeating: .random(in: 0...1), count: 10)
        composerVC.channelController = .init(channelQuery: .init(cid: .unique), channelListQuery: nil, client: .mock)
        try Data(count: 1024).write(to: expectedURL)
        defer { try? FileManager.default.removeItem(at: expectedURL) }
        
        composerVC.voiceRecording(
            composerVC.voiceRecordingVC,
            addAttachmentFromLocation: expectedURL,
            duration: expectedDuration,
            waveformData: expectedWaveformData
        )
        
        XCTAssertEqual(composerVC.content.attachments.first?.type, .voiceRecording)
        XCTAssertEqual(composerVC.content.attachments.first?.localFileURL, expectedURL)
        let payload = try XCTUnwrap(composerVC.content.attachments.first?.payload as? VoiceRecordingAttachmentPayload)
        XCTAssertEqual(payload.duration, expectedDuration)
        XCTAssertEqual(payload.waveformData, expectedWaveformData)
    }
    
    // MARK: - voiceRecordingPublishMessage
    
    func test_voiceRecordingPublishMessage_callsPublishMessageWithExpectedSender() {
        let spyComposerVC = SpyComposerVC()
        
        spyComposerVC.voiceRecordingPublishMessage(spyComposerVC.voiceRecordingVC)
        
        XCTAssertTrue(spyComposerVC.publishMessageWasCalledWithSender == spyComposerVC.composerView.sendButton)
    }
    
    // MARK: - voiceRecordingDidBeginRecording
    
    func test_voiceRecordingDidBeginRecording_contentChangesToRecording() {
        composerVC.voiceRecordingDidBeginRecording(composerVC.voiceRecordingVC)
        
        XCTAssertEqual(composerVC.content.state, .recording)
    }
    
    // MARK: - voiceRecordingDidLockRecording
    
    func test_voiceRecordingDidLockRecording_contentChangesToRecording() {
        composerVC.voiceRecordingDidLockRecording(composerVC.voiceRecordingVC)
        
        XCTAssertEqual(composerVC.content.state, .recordingLocked)
    }
    
    // MARK: - voiceRecordingDidStopRecording
    
    func test_voiceRecordingDidStopRecording_contentChangesToRecording() {
        composerVC.voiceRecordingDidStopRecording(composerVC.voiceRecordingVC)
        
        XCTAssertEqual(composerVC.content.state, .new)
    }
    
    // MARK: - voiceRecording(_:presentFloatingView:)
    
    func test_voiceRecordingPresentFloatingView_floatingViewWasAddedOnParentView() {
        let containerViewController = UIViewController()
        containerViewController.addChildViewController(composerVC, embedIn: containerViewController.view)
        let floatingView = UIView()

        composerVC.voiceRecording(composerVC.voiceRecordingVC, presentFloatingView: floatingView)

        XCTAssertTrue(containerViewController.view.subviews.last === floatingView)
    }
}

// MARK: - Helpers

private final class SpyComposerVC: ComposerVC {
    private(set) var publishMessageWasCalledWithSender: UIButton?

    override func publishMessage(sender: UIButton) {
        publishMessageWasCalledWithSender = sender
    }

    var dismissLinkPreviewCallCount = 0
    override func dismissLinkPreview() {
        dismissLinkPreviewCallCount += 1
        super.dismissLinkPreview()
    }

    var showLinkPreviewCallCount = 0
    var showLinkPreviewCalledWith: LinkAttachmentPayload?
    override func showLinkPreview(for linkPayload: LinkAttachmentPayload) {
        showLinkPreviewCallCount += 1
        showLinkPreviewCalledWith = linkPayload
        super.showLinkPreview(for: linkPayload)
    }
}
