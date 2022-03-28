//
//  EmojiMenuViewModel.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 28/03/22.
//

import Foundation
import Combine
import StreamChat

@available(iOS 13.0, *)
class EmojiMenuViewModel {
    
    // MARK: Variables
    private var cancellable: AnyCancellable?
    @Published var stickers = [Sticker]()
    
    func getPackageInfo(_ id: String) {
        cancellable = StickerApi.stickerInfo(id: id)
            .sink { error in
                // TODO: Handle error state
                print(error)
            } receiveValue: { [weak self] result in
                guard let `self` = self else { return }
                self.stickers = result.body?.package?.stickers ?? []
            }
        cancellable?.cancel()
    }
}
