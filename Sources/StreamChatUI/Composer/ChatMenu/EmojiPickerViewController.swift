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
    private var currentPage : Int = 0
    private var totalCount: Int = 0
    private var isLoadingList : Bool = false
    var downloadedPackage = [Int]()
    private var isMyPackage = false

    override func viewDidLoad() {
        super.viewDidLoad()
        packages.removeAll()
        view.backgroundColor = Appearance.default.colorPalette.stickerBg
        fetchStickers(pageNumber: 0)
        segmentController.selectedSegmentTintColor = Appearance.default.colorPalette.themeBlue
    }

    func loadMoreSticker(){
        guard !isMyPackage else { return }
        currentPage += 1
        fetchStickers(pageNumber: currentPage)
    }

    private func fetchStickers(pageNumber: Int) {
        StickerApi.trendingStickers(pageNumber: pageNumber)
            .sink { [weak self] success in
                guard let `self` = self else { return }
                self.isLoadingList = false
                debugPrint(#function)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                let packages = result.body?.packageList ?? []
                self.packages.append(contentsOf: packages)
                self.pageMap = result.body?.pageMap
                self.totalCount = self.pageMap?["pageCount"] as? Int ?? 0
                self.currentPage = self.pageMap?["pageNumber"] as? Int ?? 1
                self.tblPicker.reloadData()
            }
            .store(in: &stickerCalls)
    }

    private func fetchMySticker() {
        StickerApi.mySticker()
            .sink { result in
                print(result)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.packages = result.body?.packageList ?? []
                self.downloadedPackage = self.packages.compactMap { $0.packageID ?? 0}
                self.tblPicker.reloadData()
            }
            .store(in: &stickerCalls)
    }

    private func deletePackage(_ packageId: Int) {
        StickerApi.hideStickers(packageId: packageId)
            .sink { result in } receiveValue: { _ in }
            .store(in: &stickerCalls)
    }

    @IBAction func segmentDidiChange(_ sender: UISegmentedControl) {
        packages.removeAll()
        tblPicker.reloadData()
        if sender.selectedSegmentIndex == 0 {
            isMyPackage = false
            fetchStickers(pageNumber: 0)
        } else {
            isMyPackage = true
            fetchMySticker()
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let lastSectionIndex = tableView.numberOfSections - 1
        let lastRowIndex = tableView.numberOfRows(inSection: lastSectionIndex) - 1
        guard !isMyPackage else { return }
        if indexPath.section ==  lastSectionIndex && indexPath.row == lastRowIndex {
            let spinner = UIActivityIndicatorView(style: .white)
            spinner.startAnimating()
            spinner.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: tableView.bounds.width, height: CGFloat(44))
            self.tblPicker.tableFooterView = spinner
            self.tblPicker.tableFooterView?.isHidden = false
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (((scrollView.contentOffset.y + scrollView.frame.size.height) > scrollView.contentSize.height ) && !isLoadingList){
            self.isLoadingList = true
            self.loadMoreSticker()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        guard let packageId = packages[indexPath.row].packageID else { return }
        downloadedPackage.append(packageId)
        tableView.reloadRows(at: [indexPath], with: .automatic)
        StickerApi.downloadStickers(packageId: packages[indexPath.row].packageID ?? 0)
            .sink(receiveCompletion: { _ in
            }, receiveValue: { _ in
            })
            .store(in: &stickerCalls)
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


class PickerTableViewCell: UITableViewCell {
    @IBOutlet weak var lblPackName: UILabel!
    @IBOutlet weak var lblArtistName: UILabel!
    @IBOutlet weak var imgPack: UIImageView!
    @IBOutlet weak var btnDownload: UIButton!

    func configure(with package: PackageList, downloadedPackage: [Int]) {
        lblPackName.text = package.packageName ?? ""
        lblArtistName.text = package.artistName ?? ""
        Nuke.loadImage(with: URL(string: package.packageImg ?? ""), into: imgPack)
        selectionStyle = .none
        if !downloadedPackage.contains(package.packageID ?? 0) {
            btnDownload.setImage(Appearance.default.images.downloadSticker, for: .normal)
        } else {
            btnDownload.setImage(Appearance.default.images.downloadStickerFill, for: .normal)
        }
    }
}
