//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ComposerVC_Tests: XCTestCase {
    private var composerVC: ComposerVC! = .init()
    
    // MARK: - Lifecycle
    
    override func tearDown() {
        composerVC = nil
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
    
    func test_whenSuggestionsLookupIsLocal_onlyChannelMembersAreShown() {
        final class ComposerContainerVC: UIViewController {
            var composerVC: ComposerVC!
            var textWithMention = ""
            
            override func viewDidLoad() {
                super.viewDidLoad()
                
                view.backgroundColor = .white
                addChildViewController(composerVC, targetView: view)
                composerVC.view.pin(anchors: [.leading, .trailing, .bottom], to: view)
            }
            
            override func viewWillAppear(_ animated: Bool) {
                super.viewWillAppear(animated)
                
                composerVC.content.text = textWithMention
            }
        }
        
        let member: ChatChannelMember = .mock(
            id: "1",
            name: "Yoda (member)",
            imageURL: nil
        )
        
        let watcher: ChatUser = .mock(
            id: "2",
            name: "Yoda (watcher)",
            imageURL: nil
        )
        
        let mockUserSearchController = ChatUserSearchController_Mock.mock()
        
        let mockChannelController = ChatChannelController_Mock.mock()
        mockChannelController.client.authenticationRepository.setMockToken()
        mockChannelController.channel_mock = .mock(
            cid: .unique,
            lastActiveMembers: [member],
            lastActiveWatchers: [watcher]
        )
        
        composerVC.userSearchController = mockUserSearchController
        composerVC.channelController = mockChannelController
        
        let containerVC = ComposerContainerVC()
        containerVC.composerVC = composerVC
        containerVC.textWithMention = "@Yo"
        
        AssertSnapshot(containerVC, variants: [.defaultLight])
    }
    
    func test_channelWithSlowModeActive_messageIsSent_SlowModeIsOnWithCountdownShown() {
        composerVC.cooldownTracker = CooldownTracker_Mock(timer: ScheduledStreamTimer_Mock())
        composerVC.appearance = Appearance.default
        composerVC.content.text = "Test text"
        composerVC.viewDidLoad()
        
        composerVC.cooldownTracker.start(with: 120)
        
        AssertSnapshot(composerVC)
    }
    
    func test_didUpdateMessages_startsCooldown() {
        let mockedCooldownTracker = CooldownTracker_Mock(timer: ScheduledStreamTimer_Mock())
        composerVC.cooldownTracker = mockedCooldownTracker
        
        composerVC.channelController(ChatChannelController_Mock.mock(), didUpdateMessages: [])
        
        XCTAssertEqual(mockedCooldownTracker.startCallCount, 1)
    }
    
    // MARK: - audioPlayer
    
    func test_audioPlayer_voiceRecordingAndAttachmentsVCGetTheSameInstance() {
        let audioPlayer = StreamRemoteAudioPlayer()
        
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
        XCTAssertEqual(payload.extraData?.duration, expectedDuration)
        XCTAssertEqual(payload.extraData?.waveform, expectedWaveformData)
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
}
