//
//  EmojiMenuViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import UIKit
import SwiftUI
import StreamChat
import Combine
import Nuke
import GiphyUISDK

@available(iOS 13.0, *)
class EmojiMenuViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var collectionMenu: UICollectionView!

    // MARK: Variables
    // -1 to load recent stickers
    private var selectedPack: Int = -1
    private var stickerCalls = Set<AnyCancellable>()
    var stickers = [Sticker]()
    var menus = [StickerMenu]()
    var package = [PackageList]()
    var didSelectSticker: ((Sticker) -> ())?
    var didSelectMarketPlace: (([Int]) -> ())?
    private var pageController: UIPageViewController?
    private var currentIndex: Int = 0
    private var initialVC: EmojiContainerViewController!

    //MARK: Override
    override func viewDidLoad() {
        super.viewDidLoad()
        // Load default stickers
        let menus = UserDefaults.standard.retrieve(object: [StickerMenu].self, fromKey: UserdefaultKey.downloadedSticker) ?? []
        loadMenu(result: menus)
    }

    deinit {
        debugPrint("EmojiMenuViewController", #function)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchSticker()
    }

    @IBAction func btnShowPackage(_ sender: Any) {
        didSelectMarketPlace?(menus.compactMap { $0.menuId })
    }

    private func fetchSticker() {
        StickerApi.mySticker()
            .sink { error in
                print(error)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.menus.removeAll()
                self.package.removeAll()
                self.menus.append(.init(image: "", menuId: -1, name: ""))
                let packageList = result.body?.packageList ?? []
                self.package = packageList
                self.menus.append(contentsOf: packageList.compactMap { StickerMenu.init(image: $0.packageImg ?? "", menuId: $0.packageID ?? 0, name: $0.packageName ?? "") })
                self.setupPageController()
                self.checkAndAddDefaultSticker()
                self.collectionMenu.reloadData()
            }
            .store(in: &stickerCalls)
    }

    private func loadMenu(result: [StickerMenu]) {
        self.menus.removeAll()
        var updatedResult = result
        updatedResult.removeAll(where: { $0.menuId == -1 })
        self.menus.append(.init(image: "", menuId: -1, name: ""))
        self.menus.append(contentsOf: updatedResult)
        self.checkAndAddDefaultSticker()
        self.setupPageController()
        self.collectionMenu.reloadData()
    }

    private func checkAndAddDefaultSticker() {
        // 1. mushroom movie valentines -> 6223
        // 2. cute duck duggy -> 7227
        // 3. sweetanka
        // 4. tubby nugget 2 -> 5851
        // 5. cute baby axolotl: animated -> 5682
        var defaultStickers = [StickerMenu]()
        defaultStickers.append(.init(image: "https://img.stipop.io/2020/11/23/1606123362817_IE7darbhoR.gif", menuId: 5682, name: "Cute Baby Axolotl : Animated"))
        defaultStickers.append(.init(image: "https://img.stipop.io/2021/7/7/1625615224234_gn8QGj9ryD.gif", menuId: 7227, name: "Cute duck Duggy 2s"))
        defaultStickers.append(.init(image: "https://img.stipop.io/2020/12/18/1608261102770_6T1UkUst0l.gif", menuId: 5851, name: "Tubby Nugget Winter Pack"))
        defaultStickers.append(.init(image: "https://img.stipop.io/2021/2/10/1612910010258_LqupKfShY4.gif", menuId: 6223, name: "Mushroom Movie Valentines"))
        var defaultStickerIds = defaultStickers.compactMap { $0.menuId }
        menus.removeAll(where:  { defaultStickerIds.contains($0.menuId) })
        menus.append(contentsOf: defaultStickers)

        //Store Menu in local
        UserDefaults.standard.save(customObject: menus, inKey: UserdefaultKey.downloadedSticker)
        UserDefaults.standard.synchronize()
    }

    private func setupPageController() {
        if pageController == nil {
            pageController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
            guard let pageController = pageController else {
                return
            }
            pageController.dataSource = self
            pageController.delegate = self
            pageController.view.backgroundColor = .clear
            pageController.view.frame = containerView.bounds
            addChild(pageController)
            containerView.addSubview(pageController.view)
            initialVC = EmojiContainerViewController(with: menus.first ?? .init(image: "", menuId: -1, name: ""))
            pageController.setViewControllers([initialVC], direction: .forward, animated: true, completion: nil)
            pageController.didMove(toParent: self)
        } else {
            pageController?.dataSource = nil
            pageController?.dataSource = self
        }
    }
}

@available(iOS 13.0, *)
extension EmojiMenuViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? EmojiContainerViewController else {
            return nil
        }
        var index = currentVC.view.tag ?? 0
        if index == 0 {
            return nil
        }
        index -= 1
        let emojiContainer = EmojiContainerViewController(with: menus[index])
        emojiContainer.view.tag = index
        return emojiContainer
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let currentVC = viewController as? EmojiContainerViewController else {
            return nil
        }
        var index = currentVC.view.tag ?? 0
        if index >= self.menus.count - 1 {
            return nil
        }
        index += 1
        let emojiContainer = EmojiContainerViewController(with: menus[index])
        emojiContainer.view.tag = index
        return emojiContainer
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return menus.count
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (!completed) {
            return
        }
        let index = pageViewController.viewControllers!.first!.view.tag
        currentIndex = index
        guard menus.count > currentIndex else { return }
        selectedPack = menus[currentIndex].menuId
        collectionMenu.reloadData()
        collectionMenu.scrollToItem(at: .init(row: currentIndex, section: 0), at: .right, animated: true)
    }
}

@available(iOS 13.0, *)
extension EmojiMenuViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menus.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StickerMenuCollectionCell", for: indexPath) as? StickerMenuCollectionCell else {
            return UICollectionViewCell()
        }
        cell.configureMenu(menu: menus[indexPath.row], selectedId: selectedPack)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 40, height: 40)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let direction: UIPageViewController.NavigationDirection = indexPath.row < currentIndex ? .reverse : .forward
        let emojiContainer = EmojiContainerViewController(with: menus[indexPath.row])
        guard selectedPack != menus[indexPath.row].menuId else { return }
        emojiContainer.view.tag = indexPath.row
        selectedPack = menus[indexPath.row].menuId
        currentIndex = menus.firstIndex(where: { $0.menuId == selectedPack}) ?? 0
        collectionView.reloadData()
        pageController?.setViewControllers([emojiContainer], direction: direction, animated: true, completion: nil)
    }

}
