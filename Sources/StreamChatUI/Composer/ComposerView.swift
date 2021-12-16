//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// /// The composer view that layouts all the components to create a new message.
///
/// High level overview of the composer layout:
/// ```
/// |---------------------------------------------------------|
/// |                       headerView                        |
/// |---------------------------------------------------------|--|
/// | leadingContainer | inputMessageView | trailingContainer |  | = centerContainer
/// |---------------------------------------------------------|--|
/// |                     bottomContainer                     |
/// |---------------------------------------------------------|
/// |                     ToolkitView                         |
/// |---------------------------------------------------------|
/// ```
open class ComposerView: _View, ThemeProvider {
    var keyboardToolTipTapped: ((_ tooltip: ToolKit) -> Void)?
    lazy var toolTipList: [ToolKit] = {
        return KeyboardToolKit().getList()
    }()
    /// The main container of the composer that layouts all the other containers around the message input view.
    public private(set) lazy var container = UIStackView()//ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The header view that displays components above the message input view.
    public private(set) lazy var headerView = UIView()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var toolKitView = UIView()
        .withoutAutoresizingMaskConstraints

    /// The container that displays the components below the message input view.
    public private(set) lazy var bottomContainer = UIStackView()

    /// The container that layouts the message input view and the leading/trailing containers around it.
    public private(set) lazy var centerContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The container that displays the components in the leading side of the message input view.
    public private(set) lazy var leadingContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// The container that displays the components in the trailing side of the message input view.
    public private(set) lazy var trailingContainer = ContainerStackView()
        .withoutAutoresizingMaskConstraints

    /// A view to to input content of the new message.
    public private(set) lazy var inputMessageView: InputChatMessageView = components
        .inputMessageView.init()
        .withoutAutoresizingMaskConstraints

    /// A button to send the message.
    public private(set) lazy var sendButton: UIButton = components
        .sendButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to transfer p2p payment
    public private(set) lazy var moneyTransferButton: UIButton = components
        .sendMoneyButton.init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var toolbarToggleButton: UIButton = components
        .toolTipToggleButton.init()
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var toolBarCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(
            frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 38),
            collectionViewLayout: layout)
            .withoutAutoresizingMaskConstraints
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        return collectionView
    }()

    /// A button to confirm when editing a message.
    public private(set) lazy var confirmButton: UIButton = components
        .confirmButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to open the user attachments.
    public private(set) lazy var attachmentButton: UIButton = components
        .attachmentButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to open the available commands.
    public private(set) lazy var commandsButton: UIButton = components
        .commandsButton.init()
        .withoutAutoresizingMaskConstraints

    /// A Button for shrinking the input view to allow more space for other actions.
    public private(set) lazy var shrinkInputButton: UIButton = components
        .shrinkInputButton.init()
        .withoutAutoresizingMaskConstraints

    /// A button to dismiss the current state (quoting, editing, etc..).
    public private(set) lazy var dismissButton: UIButton = components
        .closeButton.init()
        .withoutAutoresizingMaskConstraints

    /// A label part of the header view to display the current state (quoting, editing, etc..).
    public private(set) lazy var titleLabel: UILabel = UILabel()
        .withoutAutoresizingMaskConstraints
        .withBidirectionalLanguagesSupport
        .withAdjustingFontForContentSizeCategory

    /// A checkbox to check/uncheck if the message should also
    /// be sent to the channel while replying in a thread.
    public private(set) lazy var checkboxControl: CheckboxControl = components
        .checkmarkControl.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()
        backgroundColor = appearance.colorPalette.walletTabbarBackground
        toolKitView.backgroundColor = appearance.colorPalette.walletTabbarBackground
        headerView.backgroundColor = appearance.colorPalette.walletTabbarBackground
        centerContainer.backgroundColor = appearance.colorPalette.walletTabbarBackground
        bottomContainer.backgroundColor = appearance.colorPalette.walletTabbarBackground
        layer.shadowColor = UIColor.systemGray.cgColor
        layer.shadowOpacity = 1
        layer.shadowOffset = .zero
        layer.shadowRadius = 0.5

        titleLabel.textAlignment = .center
        titleLabel.textColor = appearance.colorPalette.text
        titleLabel.font = appearance.fonts.bodyBold
        titleLabel.adjustsFontForContentSizeCategory = true
    }
    
    override open func setUpLayout() {
        super.setUpLayout()
        embed(container)

        container.isLayoutMarginsRelativeArrangement = true
        container.axis = .vertical
        container.alignment = .fill
        container.distribution = .fill
        container.spacing = 0
        container.addArrangedSubview(headerView)
        container.addArrangedSubview(centerContainer)
        container.addArrangedSubview(bottomContainer)
        container.addArrangedSubview(toolKitView)
        bottomContainer.isHidden = false
        headerView.isHidden = true

        toolKitView.addSubview(toolBarCollectionView)
        toolKitView.heightAnchor.constraint(equalToConstant: 38).isActive = true
        toolBarCollectionView.leadingAnchor.constraint(equalTo: toolKitView.leadingAnchor).isActive = true
        toolBarCollectionView.trailingAnchor.constraint(equalTo: toolKitView.trailingAnchor).isActive = true
        toolBarCollectionView.topAnchor.constraint(equalTo: toolKitView.topAnchor).isActive = true
        toolBarCollectionView.bottomAnchor.constraint(equalTo: toolKitView.bottomAnchor).isActive = true

        bottomContainer.addArrangedSubview(checkboxControl)
        headerView.addSubview(titleLabel)
        headerView.addSubview(dismissButton)
        centerContainer.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        centerContainer.isLayoutMarginsRelativeArrangement = true
        centerContainer.axis = .horizontal
        centerContainer.alignment = .bottom
        centerContainer.spacing = .auto
        centerContainer.addArrangedSubview(leadingContainer)
        centerContainer.addArrangedSubview(inputMessageView, respectsLayoutMargins: true)
        inputMessageView.layoutMargins = UIEdgeInsets(top: 2, left: 0, bottom: 3, right: 0)
        centerContainer.addArrangedSubview(trailingContainer)
        trailingContainer.alignment = .center
        trailingContainer.spacing = .auto
        trailingContainer.distribution = .equal
        trailingContainer.isLayoutMarginsRelativeArrangement = true
        trailingContainer.directionalLayoutMargins = .zero
        trailingContainer.addArrangedSubview(sendButton)
        trailingContainer.addArrangedSubview(confirmButton)
        confirmButton.isHidden = true

        leadingContainer.axis = .horizontal
        leadingContainer.alignment = .center
        leadingContainer.spacing = .auto
        leadingContainer.distribution = .equal
        leadingContainer.isLayoutMarginsRelativeArrangement = true
        leadingContainer.directionalLayoutMargins = .zero
        //leadingContainer.addArrangedSubview(attachmentButton)
        //leadingContainer.addArrangedSubview(commandsButton)
        //leadingContainer.addArrangedSubview(moneyTransferButton)
        //leadingContainer.addArrangedSubview(shrinkInputButton)
        leadingContainer.addArrangedSubview(toolbarToggleButton)

        shrinkInputButton.isHidden = true

        dismissButton.widthAnchor.pin(equalToConstant: 22).isActive = true
        dismissButton.heightAnchor.pin(equalToConstant: 22).isActive = true
        dismissButton.trailingAnchor.pin(equalTo: trailingContainer.trailingAnchor).isActive = true
        titleLabel.centerXAnchor.pin(equalTo: centerXAnchor).isActive = true
        titleLabel.pin(anchors: [.top, .bottom], to: headerView)

        /*[shrinkInputButton, attachmentButton, commandsButton, moneyTransferButton, sendButton, confirmButton]
            .forEach { button in
                button.pin(anchors: [.width], to: 30)
                button.pin(anchors: [.height], to: 38)
            }*/
        toolbarToggleButton.pin(anchors: [.width], to: 40)
        toolbarToggleButton.pin(anchors: [.height], to: 38)
        [sendButton, confirmButton]
            .forEach { button in
                button.pin(anchors: [.width], to: 30)
                button.pin(anchors: [.height], to: 38)
            }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        toolBarCollectionView.delegate = self
        toolBarCollectionView.dataSource = self
        toolBarCollectionView.register(KeyboardToolTipCVCell.self,
                                       forCellWithReuseIdentifier: KeyboardToolTipCVCell.reuseId)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension ComposerView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return toolTipList.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: KeyboardToolTipCVCell.reuseId,
            for: indexPath) as? KeyboardToolTipCVCell else {
            return UICollectionViewCell()
        }
        let indexData = toolTipList[indexPath.row]
        cell.configCell(indexData)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView,
                               layout collectionViewLayout: UICollectionViewLayout,
                               sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let indexData = toolTipList[indexPath.row]
        keyboardToolTipTapped?(indexData)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: 8, height: collectionView.frame.height)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: 8, height: collectionView.frame.height)
    }
}

class KeyboardToolTipCVCell: UICollectionViewCell {

    class var reuseId: String { String(describing: self) }

    lazy var toolImage: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = imageView.frame.size.height/2
        imageView.clipsToBounds = true
        return imageView
    }()

    override public init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(toolImage)
        NSLayoutConstraint.activate([
            toolImage.heightAnchor.constraint(equalToConstant: 30),
            toolImage.widthAnchor.constraint(equalToConstant: 40),
            toolImage.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 0),
            toolImage.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: 0)
        ])
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configCell(_ model: ToolKit) {
        toolImage.image = model.image
    }
}
