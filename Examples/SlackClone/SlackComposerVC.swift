//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI
import UIKit

/// WIP Implementation of a custom typing suggestion.
/// This is a proof of concept and it not yet finalised.
class SlackComposerVC: ComposerVC {
    var emojiSuggester = TypingSuggester(
        options: TypingSuggestionOptions(
            symbol: ":",
            shouldTriggerOnlyAtStart: false,
            minimumRequiredCharacters: 2
        )
    )

    override func updateContent() {
        super.updateContent()

        if let typingEmojiSuggestion = typingEmoji(in: composerView.inputMessageView.textView) {
            showEmojiSuggestions(for: typingEmojiSuggestion)
            return
        }
    }

    func typingEmoji(in textView: UITextView) -> TypingSuggestion? {
        let typingSuggestion = emojiSuggester.typingSuggestion(in: textView)
        return typingSuggestion
    }

    func showEmojiSuggestions(for typingSuggestion: TypingSuggestion) {
        let dataSource = ComposerEmojiSuggestionsDataSource(
            collectionView: suggestionsVC.collectionView
        )
        suggestionsVC.dataSource = dataSource
        suggestionsVC.didSelectItemAt = { [weak self] index in
            guard let self = self else { return }

            let textView = self.composerView.inputMessageView.textView
            let text = textView.text as NSString

            var typingSuggestionLocation = typingSuggestion.locationRange
            typingSuggestionLocation.location -= 1
            typingSuggestionLocation.length += 1

            let emoji = dataSource.emojis[index].symbol
            let newText = text.replacingCharacters(in: typingSuggestionLocation, with: emoji)
            self.content.text = newText

            let caretLocation = textView.selectedRange.location
            let newCaretLocation = caretLocation + typingSuggestion.text.count
            textView.selectedRange = NSRange(location: newCaretLocation, length: 0)

            self.dismissSuggestions()
        }

        showSuggestions()
    }
}

open class ComposerEmojiSuggestionsDataSource: NSObject, UICollectionViewDataSource {
    /// The collection view of the mentions.
    open var collectionView: ChatSuggestionsCollectionView

    var emojis: [(symbol: String, code: String)] = [
        ("😃", ":happy:"),
        ("🙁", ":sad:"),
        ("😂", ":joy:"),
        ("😅", ":sweat_smile:")
    ]

    init(collectionView: ChatSuggestionsCollectionView) {
        self.collectionView = collectionView

        super.init()

        collectionView.register(
            ComposerEmojiSuggestionsCollectionViewCell.self,
            forCellWithReuseIdentifier: ComposerEmojiSuggestionsCollectionViewCell.reuseId
        )

        let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout
        collectionViewLayout?.headerReferenceSize = CGSize(width: collectionView.frame.size.width, height: 0)

        self.collectionView.reloadData()
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emojis.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: ComposerEmojiSuggestionsCollectionViewCell.reuseId,
            for: indexPath
        ) as? ComposerEmojiSuggestionsCollectionViewCell else {
            return UICollectionViewCell()
        }

        let emoji = emojis[indexPath.row]
        cell.emojiLabel.text = emoji.symbol + "  " + emoji.code
        return cell
    }
}

class ComposerEmojiSuggestionsCollectionViewCell: UICollectionViewCell {
    class var reuseId: String { String(describing: self) }

    lazy var emojiLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            emojiLabel.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            emojiLabel.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
