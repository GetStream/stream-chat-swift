//
//  EmojiPickerViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 29/03/22.
//

import UIKit
import Stipop
import StreamChat
import Combine
import Nuke

@available(iOS 13.0, *)
class EmojiPickerViewController: UIViewController {

    // MARK: Outlets
    @IBOutlet weak var segmentController: UISegmentedControl!
    @IBOutlet weak var tblPicker: UITableView!

    // MARK: Variables
    private var stickerCalls = Set<AnyCancellable>()
    private var packages = [PackageList]()
    private var pageMap: [String: Int]?
    private var isMyPackage = false
    var downloadedPackage = [Int]()

    override func viewDidLoad() {
        super.viewDidLoad()
        packages.removeAll()
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
        fetchStickers(pageNumber: 0, animated: true)
        segmentController.selectedSegmentTintColor = Appearance.default.colorPalette.themeBlue
    }

    private func fetchStickers(pageNumber: Int, animated: Bool) {
        StickerApiClient.trendingStickers(pageNumber: pageNumber, animated: animated) { [weak self] result in
            guard let `self` = self else { return }
            let packages = result.body?.packageList ?? []
            self.packages.append(contentsOf: packages)
            self.packages.removeAll(where: { $0.price != "free" })
            self.pageMap = result.body?.pageMap
            self.tblPicker.reloadData()
        }
    }

    private func fetchMySticker() {
        StickerApiClient.mySticker { [weak self] result in
            guard let `self` = self else { return }
            self.packages = result.body?.packageList ?? []
            self.tblPicker.reloadData()
        }
    }

    private func deletePackage(_ packageId: Int) {
        StickerApiClient.hideStickers(packageId: packageId, nil)
    }

    @IBAction func segmentDidChange(_ sender: UISegmentedControl) {
        packages.removeAll()
        tblPicker.reloadData()
        if sender.selectedSegmentIndex == 2 {
            isMyPackage = true
            fetchMySticker()
        } else {
            isMyPackage = false
            fetchStickers(pageNumber: 0, animated: sender.selectedSegmentIndex == 0)
        }
    }

}

@available(iOS 13.0, *)
extension EmojiPickerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return packages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "PickerTableViewCell") as? PickerTableViewCell else {
            return UITableViewCell()
        }
        cell.configure(with: packages[indexPath.row], downloadedPackage: downloadedPackage)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard let packageId = packages[indexPath.row].packageID else { return }
        downloadedPackage.append(packageId)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        if packages[indexPath.row].isDownload != "Y" {
            StickerApiClient.downloadStickers(packageId: packages[indexPath.row].packageID ?? 0) { }
        } else {
            StickerApiClient.hideStickers(packageId: packages[indexPath.row].packageID ?? 0, nil)
        }
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        isMyPackage
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, sourceView, completionHandler) in
            self.deletePackage(self.packages[indexPath.row].packageID ?? 0)
            self.packages.remove(at: indexPath.row)
            self.tblPicker.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        let swipeActionConfig = UISwipeActionsConfiguration(actions: [delete])
        swipeActionConfig.performsFirstActionWithFullSwipe = false
        return swipeActionConfig
    }
}
