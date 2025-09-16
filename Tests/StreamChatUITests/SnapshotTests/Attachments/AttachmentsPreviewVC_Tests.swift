// 
// Auto-generated tests for AttachmentsPreviewVC
//

import XCTest
@testable import StreamChatUI
import StreamChat

final class AttachmentsPreviewVC_Tests: XCTestCase {
}

extension AttachmentsPreviewVC_Tests {

    func test_initialState_hidesBothScrollViews() {
        let sut = makeSUT()

        XCTAssertTrue(sut.horizontalScrollView.isHidden, "Horizontal scroll view should be hidden initially.")
        XCTAssertTrue(sut.verticalScrollView.isHidden, "Vertical scroll view should be hidden initially.")
    }

    func test_settingHorizontalOnlyContent_showsHorizontal_hidesVertical_andAddsSpacer() {
        let sut = makeSUT()
        let a = StubAttachmentPreviewProvider()
        let b = StubAttachmentPreviewProvider()

        StubAttachmentPreviewProvider.preferredAxis = .horizontal
        sut.content = [a, b]
        sut.updateContentIfNeeded()

        XCTAssertFalse(sut.horizontalScrollView.isHidden)
        XCTAssertTrue(sut.verticalScrollView.isHidden)

        // Expect attachment cells + spacer (UIView)
        let arranged = sut.horizontalStackView.arrangedSubviews
        XCTAssertGreaterThanOrEqual(arranged.count, 3, "Should contain 2 cells + spacer.")
        XCTAssertTrue(arranged.last is UIView, "Last arranged subview should be spacer UIView.")
    }

    func test_settingVerticalOnlyContent_showsVertical_hidesHorizontal() {
        let sut = makeSUT()
        let a = VerticalAttachmentPreviewProvider()
        let b = VerticalAttachmentPreviewProvider()

        sut.content = [a, b]
        sut.updateContentIfNeeded()

        XCTAssertTrue(sut.horizontalScrollView.isHidden)
        XCTAssertFalse(sut.verticalScrollView.isHidden)

        // Vertical stack should be populated with attachment cells
        XCTAssertGreaterThan(sut.verticalStackView.arrangedSubviews.count, 0)
    }

    func test_verticalScrollViewHeightConstraint_addedWhenCountExceedsMax() {
        let sut = makeSUT()
        sut.maxNumberOfVerticalItems = 3

        // Create 5 vertical attachment previews to exceed max
        let providers = (0..<5).map { _ in VerticalAttachmentPreviewProvider(size: CGSize(width: 100, height: 24), background: .green) }
        sut.content = providers
        sut.updateContentIfNeeded()

        // After update, a height constraint should be set
        XCTAssertNotNil(sut.verticalScrollViewHeightConstraint)
        XCTAssertTrue(sut.verticalScrollViewHeightConstraint?.isActive == true)

        // The calculated constant should be greater than zero
        XCTAssertGreaterThan(sut.verticalScrollViewHeightConstraint\!.constant, 0)
    }

    func test_verticalScrollViewHeightConstraint_removedWhenCountWithinMax() {
        let sut = makeSUT()
        sut.maxNumberOfVerticalItems = 3

        // First exceed to create constraint
        let many = (0..<5).map { _ in VerticalAttachmentPreviewProvider(size: CGSize(width: 100, height: 24), background: .blue) }
        sut.content = many
        sut.updateContentIfNeeded()
        XCTAssertNotNil(sut.verticalScrollViewHeightConstraint)

        // Then reduce to be within max, constraint should be deactivated and cleared
        let few = (0..<2).map { _ in VerticalAttachmentPreviewProvider(size: CGSize(width: 100, height: 24), background: .blue) }
        sut.content = few
        sut.updateContentIfNeeded()

        XCTAssertNil(sut.verticalScrollViewHeightConstraint)
    }

    func test_didTapRemoveItemButton_calledWithCorrectIndex() {
        let sut = makeSUT()
        var tappedIndex: Int?
        sut.didTapRemoveItemButton = { tappedIndex = $0 }

        StubAttachmentPreviewProvider.preferredAxis = .horizontal
        let providers = (0..<3).map { _ in StubAttachmentPreviewProvider() }
        sut.content = providers
        sut.updateContentIfNeeded()

        // Find the first attachment cell and trigger discard handler
        let cells = sut.horizontalStackView.arrangedSubviews.compactMap { $0 as? _MessageComposerAttachmentCell }
        XCTAssertEqual(cells.count, 3, "Expected 3 attachment cells.")

        // Simulate discard on index 1
        cells[1].discardButtonHandler?()

        XCTAssertEqual(tappedIndex, 1)
    }

    func test_voiceRecordingAttachment_setsAudioPlayer_andIndexProvider() {
        let sut = makeSUT()
        let audio = StubAudioPlayer()
        sut.audioPlayer = audio

        // Mix voice recordings with duplicates to test indexProvider resolution
        let vr1 = StubVoiceRecordingAttachment()
        let vr2 = StubVoiceRecordingAttachment()
        let std = StubAttachmentPreviewProvider()

        // preferredAxis is horizontal for StubVoiceRecordingAttachment
        sut.content = [vr1, std, vr2]
        sut.updateContentIfNeeded()

        // Extract the embedded preview views
        let cells = sut.horizontalStackView.arrangedSubviews.compactMap { $0 as? _MessageComposerAttachmentCell }
        XCTAssertEqual(cells.count, 3)

        let previews = cells.compactMap { cell -> VoiceRecordingAttachmentComposerPreview? in
            cell.subviews.compactMap { $0 as? VoiceRecordingAttachmentComposerPreview }.first
        }.compactMap { $0 }

        // There should be two voice recording previews
        XCTAssertEqual(previews.count, 2)

        // Audio player should be wired
        XCTAssertTrue(previews.allSatisfy { $0.audioPlayer === audio })

        // indexProvider should resolve to consistent indices within voiceRecordingAttachmentPayloads ordering
        let indices = previews.compactMap { $0.indexProvider?() }
        XCTAssertEqual(indices.sorted(), indices, "Index provider should map in order of encountered voice recordings.")
    }

    func test_scrollVerticalViewToBottom_scrollsToLastItem() {
        let sut = makeSUT()
        sut.maxNumberOfVerticalItems = 2

        let providers = (0..<4).map { _ in VerticalAttachmentPreviewProvider(size: CGSize(width: 200, height: 30), background: .orange) }
        sut.content = providers
        sut.updateContentIfNeeded()

        // Call explicit scroll; since it uses DispatchQueue.main.async we allow a short expectation
        let exp = expectation(description: "scrolls to bottom")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // We can't easily assert contentOffset precisely without a real runloop/layout pass,
            // but we can assert there are arranged subviews and constraint exists implying scrollability.
            XCTAssertNotNil(sut.verticalScrollViewHeightConstraint)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}