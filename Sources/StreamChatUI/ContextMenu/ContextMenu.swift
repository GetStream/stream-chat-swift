//
//  ContextMenu.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 10/02/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

public protocol ContextMenuItem {
    var title: String {
        get
    }
    var image: UIImage? {
        get
    }
    var type: ContextMenuType {
        get
    }
}

extension ContextMenuItem {
    public var image: UIImage? {
        get { return nil }
    }
}

extension String: ContextMenuItem {
    public var type: ContextMenuType {
        get {
            return type
        }
    }

    public var title: String {
        get {
            return "\(self)"
        }
    }
}

public struct ContextMenuItemWithImage: ContextMenuItem {
    public var title: String
    public var image: UIImage?
    public var type: ContextMenuType

    public init(title: String, image: UIImage, type: ContextMenuType) {
        self.title = title
        self.image = image
        self.type = type
    }
}

public enum ContextMenuType {
    case privateGroup
    case searchMessage
    case invite
    case groupQR
    case mute
    case unmute
    case leaveGroup
    case deleteAndLeave
    case deleteChat
    case groupImage
}

public protocol ContextMenuDelegate: AnyObject {
    func contextMenuDidSelect(
        _ contextMenu: ContextMenu,
        cell: ContextMenuCell,
        targetedView: UIView,
        didSelect item: ContextMenuItem,
        forRowAt index: Int) -> Bool
    func contextMenuDidDeselect(
        _ contextMenu: ContextMenu,
        cell: ContextMenuCell,
        targetedView: UIView,
        didSelect item: ContextMenuItem,
        forRowAt index: Int)
    func contextMenuDidAppear(_ contextMenu: ContextMenu)
    func contextMenuDidDisappear(_ contextMenu: ContextMenu)
}
extension ContextMenuDelegate {
    func contextMenuDidAppear(_ contextMenu: ContextMenu){}
    func contextMenuDidDisappear(_ contextMenu: ContextMenu){}
}

public var CM : ContextMenu = ContextMenu()

public struct ContextMenuConstants {
    public var MaxZoom: CGFloat = 1.15
    public var MinZoom: CGFloat = 0.6
    public var MenuDefaultHeight: CGFloat = 120
    public var MenuWidth: CGFloat = 262
    public var MenuMarginSpace: CGFloat = 20
    public var TopMarginSpace: CGFloat = 40
    public var BottomMarginSpace: CGFloat = 24
    public var HorizontalMarginSpace: CGFloat = 20
    public var ItemDefaultHeight: CGFloat = 37

    public var LabelDefaultFont: UIFont = .systemFont(ofSize: 16)
    public var LabelDefaultColor: UIColor = .white
    public var ItemDefaultColor: UIColor = Appearance.default.colorPalette.popoverBackground

    public var MenuCornerRadius: CGFloat = 12
    public var BlurEffectEnabled: Bool = true
    public var BlurEffectDefault: UIBlurEffect = UIBlurEffect(style: .dark)
    public var BackgroundViewColor: UIColor = UIColor.black.withAlphaComponent(0.6)

    public var DismissOnItemTap: Bool = false
}

open class ContextMenu: NSObject {

    // MARK:- open Variables
    open var MenuConstants = ContextMenuConstants()
    open var viewTargeted: UIView!
    open var placeHolderView: UIView?
    open var headerView: UIView?
    open var footerView: UIView?
    open var nibView = UINib(nibName: ContextMenuCell.identifier, bundle: Bundle(for: ContextMenuCell.self))
    open var closeAnimation = true

    open var onItemTap: ((_ index: Int, _ item: ContextMenuItem) -> Bool)?
    open var onViewAppear: ((UIView) -> Void)?
    open var onViewDismiss: ((UIView) -> Void)?

    open var items = [ContextMenuItem]()

    // MARK:- Private Variables
    private weak var delegate: ContextMenuDelegate?

    private var mainViewRect: CGRect
    private var customView = UIView()
    private var blurEffectView = UIVisualEffectView()
    private var closeButton = UIButton()
    private var targetedImageView = UIImageView()
    private var menuView = UIView()
    public var tableView = UITableView()
    private var tableViewConstraint : NSLayoutConstraint?
    private var zoomedTargetedSize = CGRect()

    private var menuHeight: CGFloat = 180
    private var isLandscape: Bool = false

    private var touchGesture: UITapGestureRecognizer?
    private var closeGesture: UITapGestureRecognizer?

    private var tvH: CGFloat = 0.0
    private var tvW: CGFloat = 0.0
    private var tvY: CGFloat = 0.0
    private var tvX: CGFloat = 0.0
    private var mH: CGFloat = 0.0
    private var mW: CGFloat = 0.0
    private var mY: CGFloat = 0.0
    private var mX: CGFloat = 0.0

    // MARK:- Init Functions
    public init(window: UIView? = nil) {
        let wind = window ?? UIApplication.shared.windows.first ?? UIApplication.shared.keyWindow
        self.customView = wind!
        self.mainViewRect = wind!.frame
    }

    init?(viewTargeted: UIView, window: UIView? = nil) {
        if let wind = window ?? UIApplication.shared.windows.first ?? UIApplication.shared.keyWindow {
            self.customView = wind
            self.viewTargeted = viewTargeted
            self.mainViewRect = self.customView.frame
        }else{
            return nil
        }
    }

    init(viewTargeted: UIView, window: UIView) {
        self.viewTargeted = viewTargeted
        self.customView = window
        self.mainViewRect = window.frame
    }

    deinit {
        print("Deinit")
    }

    // MARK:- Show, Change, Update Menu Functions
    open func showMenu(viewTargeted: UIView, delegate: ContextMenuDelegate, animated: Bool = true) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.delegate = delegate
            self.viewTargeted = viewTargeted
            if !self.items.isEmpty {
                self.menuHeight = (CGFloat(self.items.count) * self.MenuConstants.ItemDefaultHeight) + (self.headerView?.frame.height ?? 0) + (self.footerView?.frame.height ?? 0)
            }else{
                self.menuHeight = self.MenuConstants.MenuDefaultHeight
            }
            self.addBlurEffectView()
            self.addMenuView()
            self.addTargetedImageView()
            self.openAllViews()
        }
    }

    open func changeViewTargeted(newView: UIView, animated: Bool = true) {
        DispatchQueue.main.async {
            guard self.viewTargeted != nil else{
                print("targetedView is nil")
                return
            }
            self.viewTargeted.alpha = 1
            if let gesture = self.touchGesture {
                self.viewTargeted.removeGestureRecognizer(gesture)
            }
            self.viewTargeted = newView
            self.targetedImageView.image = self.getRenderedImage(afterScreenUpdates: true)
            if let gesture = self.touchGesture {
                self.viewTargeted.addGestureRecognizer(gesture)
            }
            self.updateTargetedImageViewPosition(animated: animated)
        }
    }

    open func updateView(animated: Bool = true){
        DispatchQueue.main.async {
            guard self.viewTargeted != nil else{
                print("targetedView is nil")
                return
            }
            guard self.customView.subviews.contains(self.targetedImageView) else { return }
            if !self.items.isEmpty {
                self.menuHeight = (CGFloat(self.items.count) * self.MenuConstants.ItemDefaultHeight) + (self.headerView?.frame.height ?? 0) + (self.footerView?.frame.height ?? 0)
            }else{
                self.menuHeight = self.MenuConstants.MenuDefaultHeight
            }
            self.viewTargeted.alpha = 0
            self.addMenuView()
            self.updateTargetedImageViewPosition(animated: animated)
        }
    }

    open func closeMenu(){
        self.closeAllViews()
    }

    open func closeMenu(withAnimation animation: Bool) {
        closeAllViews(withAnimation: animation)
    }

    // MARK:- Get Rendered Image Functions
    func getRenderedImage(afterScreenUpdates: Bool = false) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: viewTargeted.bounds.size)
        let viewSnapShotImage = renderer.image { ctx in
            viewTargeted.contentScaleFactor = 3
            viewTargeted.drawHierarchy(in: viewTargeted.bounds, afterScreenUpdates: afterScreenUpdates)
        }
        return viewSnapShotImage
    }

    func addBlurEffectView() {

        if !customView.subviews.contains(blurEffectView) {
            customView.addSubview(blurEffectView)
        }
        if MenuConstants.BlurEffectEnabled {
            blurEffectView.effect = MenuConstants.BlurEffectDefault
            blurEffectView.backgroundColor = .clear
        }else{
            blurEffectView.effect = nil
            blurEffectView.backgroundColor = MenuConstants.BackgroundViewColor
        }

        blurEffectView.frame = CGRect(
            x: mainViewRect.origin.x,
            y: mainViewRect.origin.y,
            width: mainViewRect.width,
            height: mainViewRect.height)
        if closeGesture == nil {
            blurEffectView.isUserInteractionEnabled = true
            closeGesture = UITapGestureRecognizer(target: self, action: #selector(self.dismissViewAction(_:)))
            blurEffectView.addGestureRecognizer(closeGesture!)
        }
    }

    @objc func dismissViewAction(_ sender: UITapGestureRecognizer? = nil) {
        self.closeAllViews()
    }

    func addCloseButton(){

        if !customView.subviews.contains(closeButton) {
            customView.addSubview(closeButton)
        }
        closeButton.frame = CGRect(
            x: mainViewRect.origin.x,
            y: mainViewRect.origin.y,
            width: mainViewRect.width,
            height: mainViewRect.height)
        closeButton.setTitle("", for: .normal)
        closeButton.actionHandler(controlEvents: .touchUpInside) {
            self.closeAllViews()
        }
    }

    func addTargetedImageView(){
        if !customView.subviews.contains(targetedImageView) {
            customView.addSubview(targetedImageView)
        }
        let rect = viewTargeted.convert(mainViewRect.origin, to: nil)
        targetedImageView.image = self.getRenderedImage()
        targetedImageView.frame = CGRect(x: rect.x,
                                         y: rect.y,
                                         width: viewTargeted.frame.width,
                                         height: viewTargeted.frame.height)
        targetedImageView.layer.shadowColor = UIColor.black.cgColor
        targetedImageView.layer.shadowRadius = 16
        targetedImageView.layer.shadowOpacity = 0
        targetedImageView.isUserInteractionEnabled = true
    }

    func addMenuView(){
        if !customView.subviews.contains(menuView) {
            customView.addSubview(menuView)
            tableView = UITableView()
        }else{
            tableView.removeFromSuperview()
            tableView = UITableView()
        }
        let rect = viewTargeted.convert(mainViewRect.origin, to: nil)
        menuView.backgroundColor = MenuConstants.ItemDefaultColor
        menuView.layer.cornerRadius = MenuConstants.MenuCornerRadius
        menuView.clipsToBounds = true
        menuView.frame = CGRect(x: rect.x,
                                y: rect.y,
                                width: self.viewTargeted.frame.width,
                                height: self.viewTargeted.frame.height)
        menuView.addSubview(tableView)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = menuView.bounds
        tableView.register(self.nibView, forCellReuseIdentifier: "ContextMenuCell")
        tableView.tableHeaderView = self.headerView
        tableView.tableFooterView = self.footerView
        tableView.clipsToBounds = true
        tableView.isScrollEnabled = true
        tableView.alwaysBounceVertical = false
        tableView.allowsMultipleSelection = true
        tableView.backgroundColor = .clear
        tableView.reloadData()
    }

    func openAllViews(animated: Bool = true) {
        let rect = self.viewTargeted.convert(self.mainViewRect.origin, to: nil)
        viewTargeted.alpha = 0
        blurEffectView.alpha = 0
        closeButton.isUserInteractionEnabled = true
        targetedImageView.alpha = 1
        targetedImageView.layer.shadowOpacity = 0.0
        targetedImageView.isUserInteractionEnabled = true
        targetedImageView.frame = CGRect(
            x: rect.x,
            y: rect.y,
            width: self.viewTargeted.frame.width,
            height: self.viewTargeted.frame.height)
        menuView.alpha = 0
        menuView.isUserInteractionEnabled = true
        menuView.frame = CGRect(
            x: rect.x,
            y: rect.y,
            width: self.viewTargeted.frame.width,
            height: self.viewTargeted.frame.height)
        if animated {
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else {
                    return
                }
                self.blurEffectView.alpha = 1
                self.targetedImageView.layer.shadowOpacity = 0.2
            }
        }else{
            self.blurEffectView.alpha = 1
            self.targetedImageView.layer.shadowOpacity = 0.2
        }
        self.updateTargetedImageViewPosition(animated: animated)
        self.onViewAppear?(self.viewTargeted)

        self.delegate?.contextMenuDidAppear(self)
    }

    func closeAllViews() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            self.targetedImageView.isUserInteractionEnabled = false
            self.menuView.isUserInteractionEnabled = false
            self.closeButton.isUserInteractionEnabled = false

            let rect = self.viewTargeted.convert(self.mainViewRect.origin, to: nil)
            if self.closeAnimation {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6, options: [.layoutSubviews, .preferredFramesPerSecond60, .allowUserInteraction], animations: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.prepareViewsForRemoveFromSuperView(with: rect)
                }) { (_) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.removeAllViewsFromSuperView()
                    }
                }
            }else{
                DispatchQueue.main.async {
                    self.prepareViewsForRemoveFromSuperView(with: rect)
                    self.removeAllViewsFromSuperView()
                }
            }
            self.onViewDismiss?(self.viewTargeted)
            self.delegate?.contextMenuDidDisappear(self)
        }
    }

    func closeAllViews(withAnimation animation: Bool = true) {
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
        DispatchQueue.main.async {
            self.targetedImageView.isUserInteractionEnabled = false
            self.menuView.isUserInteractionEnabled = false
            self.closeButton.isUserInteractionEnabled = false

            let rect = self.viewTargeted.convert(self.mainViewRect.origin, to: nil)
            if animation {
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 6, options: [.layoutSubviews, .preferredFramesPerSecond60, .allowUserInteraction], animations: { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.prepareViewsForRemoveFromSuperView(with: rect)
                }) { (_) in
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.removeAllViewsFromSuperView()
                    }
                }
            } else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else {
                        return
                    }
                    self.prepareViewsForRemoveFromSuperView(with: rect)
                    self.removeAllViewsFromSuperView()
                }
            }
            self.onViewDismiss?(self.viewTargeted)
            self.delegate?.contextMenuDidDisappear(self)
        }
    }

    func prepareViewsForRemoveFromSuperView(with rect: CGPoint) {
        self.blurEffectView.alpha = 0
        self.targetedImageView.layer.shadowOpacity = 0
        self.targetedImageView.frame = CGRect(
            x: rect.x,
            y: rect.y,
            width: self.viewTargeted.frame.width,
            height: self.viewTargeted.frame.height)
        self.menuView.alpha = 0
        self.menuView.frame = CGRect(
            x: rect.x,
            y: rect.y,
            width: self.viewTargeted.frame.width,
            height: self.viewTargeted.frame.height)
    }

    func removeAllViewsFromSuperView() {
        self.viewTargeted?.alpha = 1
        self.targetedImageView.alpha = 0
        self.targetedImageView.removeFromSuperview()
        self.blurEffectView.removeFromSuperview()
        self.closeButton.removeFromSuperview()
        self.menuView.removeFromSuperview()
        self.tableView.removeFromSuperview()
    }

    @objc func rotated() {
        if UIDevice.current.orientation.isLandscape, !isLandscape {
            self.updateView()
            isLandscape = true
            print("Landscape")
        } else if !UIDevice.current.orientation.isLandscape, isLandscape {
            self.updateView()
            isLandscape = false
            print("Portrait")
        }
    }

    func getZoomedTargetedSize() -> CGRect{
        let rect = viewTargeted.convert(mainViewRect.origin, to: nil)
        let targetedImageFrame = viewTargeted.frame
        let backgroundWidth = mainViewRect.width - (2 * MenuConstants.HorizontalMarginSpace)
        let backgroundHeight = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace
        var zoomFactor = MenuConstants.MaxZoom
        var updatedWidth = targetedImageFrame.width
        var updatedHeight = targetedImageFrame.height
        if backgroundWidth > backgroundHeight {
            let zoomFactorHorizontalWithMenu = (backgroundWidth - MenuConstants.MenuWidth - MenuConstants.MenuMarginSpace)/updatedWidth
            let zoomFactorVerticalWithMenu = backgroundHeight/updatedHeight
            if zoomFactorHorizontalWithMenu < zoomFactorVerticalWithMenu {
                zoomFactor = zoomFactorHorizontalWithMenu
            }else{
                zoomFactor = zoomFactorVerticalWithMenu
            }
            if zoomFactor > MenuConstants.MaxZoom {
                zoomFactor = MenuConstants.MaxZoom
            }
            // Menu Height
            if self.menuHeight > backgroundHeight {
                self.menuHeight = backgroundHeight + MenuConstants.MenuMarginSpace
            }
        }else{
            let zoomFactorHorizontalWithMenu = backgroundWidth/(updatedWidth)
            let zoomFactorVerticalWithMenu = backgroundHeight/(updatedHeight + self.menuHeight + MenuConstants.MenuMarginSpace)
            if zoomFactorHorizontalWithMenu < zoomFactorVerticalWithMenu {
                zoomFactor = zoomFactorHorizontalWithMenu
            }else{
                zoomFactor = zoomFactorVerticalWithMenu
            }
            if zoomFactor > MenuConstants.MaxZoom {
                zoomFactor = MenuConstants.MaxZoom
            }else if zoomFactor < MenuConstants.MinZoom {
                zoomFactor = MenuConstants.MinZoom
            }
        }
        updatedWidth = (updatedWidth * zoomFactor)
        updatedHeight = (updatedHeight * zoomFactor)
        let updatedX = rect.x - (updatedWidth - targetedImageFrame.width)/2
        let updatedY = rect.y - (updatedHeight - targetedImageFrame.height)/2
        return CGRect(x: updatedX, y: updatedY, width: updatedWidth, height: updatedHeight)
    }

    func fixTargetedImageViewExtrudings() { // here I am checking for extruding part of ImageView
        if tvY > mainViewRect.height - MenuConstants.BottomMarginSpace - tvH {
            tvY = mainViewRect.height - MenuConstants.BottomMarginSpace - tvH
        }
        else if tvY < MenuConstants.TopMarginSpace {
            tvY = MenuConstants.TopMarginSpace
        }
        if tvX < MenuConstants.HorizontalMarginSpace {
            tvX = MenuConstants.HorizontalMarginSpace
        }
        else if tvX > mainViewRect.width - MenuConstants.HorizontalMarginSpace - tvW {
            tvX = mainViewRect.width - MenuConstants.HorizontalMarginSpace - tvW
        }
    }

    func updateHorizontalTargetedImageViewRect() {
        let rightClippedSpace = (tvW + MenuConstants.MenuMarginSpace + mW + tvX + MenuConstants.HorizontalMarginSpace) - mainViewRect.width
        let leftClippedSpace = -(tvX - MenuConstants.MenuMarginSpace - mW - MenuConstants.HorizontalMarginSpace)
        if leftClippedSpace > 0, rightClippedSpace > 0 {
            let diffY = mainViewRect.width - (mW + MenuConstants.MenuMarginSpace + tvW + MenuConstants.HorizontalMarginSpace + MenuConstants.HorizontalMarginSpace)
            if diffY > 0 {
                if (tvX + tvW/2) > mainViewRect.width/2 { //right
                    tvX = tvX + leftClippedSpace
                    mX = tvX - MenuConstants.MenuMarginSpace - mW
                } else { //left
                    tvX = tvX - rightClippedSpace
                    mX = tvX + MenuConstants.MenuMarginSpace + tvW
                }
            }else{
                if (tvX + tvW/2) > mainViewRect.width/2 { //right
                    tvX = mainViewRect.width - MenuConstants.HorizontalMarginSpace - tvW
                    mX = MenuConstants.HorizontalMarginSpace
                }else{ //left
                    tvX = MenuConstants.HorizontalMarginSpace
                    mX = tvX + tvW + MenuConstants.MenuMarginSpace
                }
            }
        }
        else if rightClippedSpace > 0 {
            mX = tvX - MenuConstants.MenuMarginSpace - mW
        }
        else if leftClippedSpace > 0  {
            mX = tvX + MenuConstants.MenuMarginSpace  + tvW
        }
        else{
            mX = tvX + MenuConstants.MenuMarginSpace + tvW
        }
        if mH >= (mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace) {
            mY = MenuConstants.TopMarginSpace
            mH = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace
        }
        else if (tvY + mH) <= (mainViewRect.height - MenuConstants.BottomMarginSpace) {
            mY = tvY
        }
        else if (tvY + mH) > (mainViewRect.height - MenuConstants.BottomMarginSpace){
            mY = tvY - ((tvY + mH) - (mainViewRect.height - MenuConstants.BottomMarginSpace))
        }
    }

    func updateVerticalTargetedImageViewRect() {
        let bottomClippedSpace = (tvH + MenuConstants.MenuMarginSpace + mH + tvY + MenuConstants.BottomMarginSpace) - mainViewRect.height
        let topClippedSpace = -(tvY - MenuConstants.MenuMarginSpace - mH - MenuConstants.TopMarginSpace)
        // not enought space down
        if topClippedSpace > 0, bottomClippedSpace > 0 {
            let diffY = mainViewRect.height - (mH + MenuConstants.MenuMarginSpace + tvH + MenuConstants.TopMarginSpace + MenuConstants.BottomMarginSpace)
            if diffY > 0 {
                if (tvY + tvH/2) > mainViewRect.height/2 { //down
                    tvY = tvY + topClippedSpace
                    mY = tvY - MenuConstants.MenuMarginSpace - mH
                }else{ //up
                    tvY = tvY - bottomClippedSpace
                    mY = tvY + MenuConstants.MenuMarginSpace + tvH
                }
            }else{
                if (tvY + tvH/2) > mainViewRect.height/2 { //down
                    tvY = mainViewRect.height - MenuConstants.BottomMarginSpace - tvH
                    mY = MenuConstants.TopMarginSpace
                    mH = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace - MenuConstants.MenuMarginSpace - tvH
                }else{ //up
                    tvY = MenuConstants.TopMarginSpace
                    mY = tvY + tvH + MenuConstants.MenuMarginSpace
                    mH = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace - MenuConstants.MenuMarginSpace - tvH
                }
            }
        }
        else if bottomClippedSpace > 0 {
            mY = tvY - MenuConstants.MenuMarginSpace - mH
        }
        else if topClippedSpace > 0  {
            mY = tvY + MenuConstants.MenuMarginSpace  + tvH
        }
        else{
            mY = tvY + MenuConstants.MenuMarginSpace + tvH
        }
    }

    func updateTargetedImageViewRect() {
        self.mainViewRect = self.customView.frame
        let targetedImagePosition = getZoomedTargetedSize()
        tvH = targetedImagePosition.height
        tvW = targetedImagePosition.width
        tvY = targetedImagePosition.origin.y
        tvX = targetedImagePosition.origin.x
        mH = menuHeight
        mW = MenuConstants.MenuWidth
        mY = tvY + MenuConstants.MenuMarginSpace
        mX = mainViewRect.width - targetedImagePosition.maxX + menuView.frame.width + MenuConstants.HorizontalMarginSpace + 20
        self.fixTargetedImageViewExtrudings()
        let backgroundWidth = mainViewRect.width - (2 * MenuConstants.HorizontalMarginSpace)
        let backgroundHeight = mainViewRect.height - MenuConstants.TopMarginSpace - MenuConstants.BottomMarginSpace
        if backgroundHeight > backgroundWidth {
            self.updateVerticalTargetedImageViewRect()
        } else {
            self.updateHorizontalTargetedImageViewRect()
        }
        tableView.frame = CGRect(x: 0, y: 0, width: mW, height: mH)
        tableView.layoutIfNeeded()
    }

    func updateTargetedImageViewPosition(animated: Bool = true) {
        self.updateTargetedImageViewRect()
        if animated {
            UIView.animate(withDuration: 0.2,
                           delay: 0,
                           usingSpringWithDamping: 0.9,
                           initialSpringVelocity: 6,
                           options: [.layoutSubviews, .preferredFramesPerSecond60, .allowUserInteraction],
                           animations:
                            {  [weak self] in
                self?.updateTargetedImageViewPositionFrame()
            })
        } else {
            self.updateTargetedImageViewPositionFrame()
        }
    }

    func updateTargetedImageViewPositionFrame() {
        let weakSelf = self
        weakSelf.menuView.alpha = 1
        weakSelf.menuView.frame = CGRect(
            x: weakSelf.mX,
            y: weakSelf.mY,
            width: weakSelf.mW,
            height: weakSelf.mH
        )
        weakSelf.targetedImageView.frame = CGRect(
            x: weakSelf.tvX,
            y: weakSelf.tvY,
            width: weakSelf.tvW,
            height: weakSelf.tvH
        )
        weakSelf.blurEffectView.frame = CGRect(
            x: weakSelf.mainViewRect.origin.x,
            y: weakSelf.mainViewRect.origin.y,
            width: weakSelf.mainViewRect.width,
            height: weakSelf.mainViewRect.height
        )
        weakSelf.closeButton.frame = CGRect(
            x: weakSelf.mainViewRect.origin.x,
            y: weakSelf.mainViewRect.origin.y,
            width: weakSelf.mainViewRect.width,
            height: weakSelf.mainViewRect.height
        )
    }
}

extension ContextMenu : UITableViewDataSource, UITableViewDelegate {

    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContextMenuCell", for: indexPath) as! ContextMenuCell
        cell.contextMenu = self
        cell.tableView = tableView
        cell.style = self.MenuConstants
        cell.item = self.items[indexPath.row]
        cell.setup()
        if indexPath.row == self.items.count - 1 {
            cell.separator.isHidden = true
        } else {
            cell.separator.isHidden = false
        }
        return cell
    }

    open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items[indexPath.row]
        if self.onItemTap?(indexPath.row, item) ?? false {
            self.closeAllViews()
        }
        if self.delegate?.contextMenuDidSelect(
            self,
            cell: tableView.cellForRow(
                at: indexPath) as! ContextMenuCell,
            targetedView: self.viewTargeted,
            didSelect: self.items[indexPath.row],
            forRowAt: indexPath.row) ?? false {
            self.closeAllViews()
        }
    }

    open func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        self.delegate?.contextMenuDidDeselect(
            self,
            cell: tableView.cellForRow(
                at: indexPath) as! ContextMenuCell,
            targetedView: self.viewTargeted,
            didSelect: self.items[indexPath.row],
            forRowAt: indexPath.row)
    }

    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return MenuConstants.ItemDefaultHeight
    }

    open func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return MenuConstants.ItemDefaultHeight
    }
}

@objc class ClosureSleeve: NSObject {
    let closure: () -> Void

    init (_ closure: @escaping () -> Void) {
        self.closure = closure
    }

    @objc func invoke () {
        closure()
    }
}

extension UIControl {
    func actionHandler(controlEvents control: UIControl.Event = .touchUpInside, ForAction action: @escaping () -> Void) {
        let sleeve = ClosureSleeve(action)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: control)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}
