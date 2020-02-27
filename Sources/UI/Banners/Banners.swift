//
//  Banners.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import RxSwift
import RxAppState

/// A banners manager.
public final class Banners {
    struct BannerItem: Equatable {
        let delay: TimeInterval
        let bouncing: CGFloat
        let title: String
        let backgroundColor: UIColor
        let borderColor: UIColor?
    }
    
    /// A shared banners manager.
    public static let shared = Banners()
    
    private static let hiddenTransform = CGAffineTransform(translationX: 0, y: -.bannerMaxY)
    private var items = [BannerItem]()
    private var currentItem: BannerItem?
    private let disposeBag = DisposeBag()
    
    lazy var window: UIWindow = {
        let frame = CGRect(x: .messageEdgePadding, y: .bannerTopOffset, width: .bannerWidth, height: .bannerHeight)
        let window = UIWindow(frame: frame)
        window.windowLevel = .alert
        window.isHidden = true
        window.isUserInteractionEnabled = false
        return window
    }()
    
    init() {
        DispatchQueue.main.async {
            UIApplication.shared.rx.appState
                .filter { $0 == .background }
                .subscribe(onNext: { [weak self] _ in self?.items = [] })
                .disposed(by: self.disposeBag)
        }
    }
    
    /// Shows a banner with a given title.
    ///
    /// - Parameters:
    ///   - title: a banner title.
    ///   - delay: a delay before it will be hidden (1...5 sec).
    ///   - backgroundColor: a background color.
    ///   - borderColor: a border color.
    public func show(_ title: String,
                     delay: TimeInterval = 3,
                     bouncing: CGFloat = 1,
                     backgroundColor: UIColor = .white,
                     borderColor: UIColor? = nil) {
        DispatchQueue.main.async {
            guard UIApplication.shared.appState == .active else {
                return
            }
            
            self.items.append(.init(delay: max(1, min(5, delay)),
                                    bouncing: bouncing,
                                    title: title,
                                    backgroundColor: backgroundColor,
                                    borderColor: borderColor))
            self.showNext()
        }
    }
    
    private func showNext() {
        guard !items.isEmpty, window.isHidden else {
            currentItem = nil
            return
        }
        
        let bannerItem = items.remove(at: 0)
        
        if bannerItem == currentItem {
            showNext()
            return
        }
        
        currentItem = bannerItem
        let bannerView = BannerView(frame: window.bounds)
        bannerView.update(with: bannerItem)
        window.addSubview(bannerView)
        
        window.isHidden = false
        window.transform = Banners.hiddenTransform
        
        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: bannerItem.bouncing,
                       initialSpringVelocity: 0,
                       options: (bannerItem.bouncing < 1 ? .curveLinear : .curveEaseOut),
                       animations: { self.window.transform = .identity },
                       completion: { _ in
                        UIView.animate(withDuration: 0.3,
                                       delay: bannerItem.delay,
                                       usingSpringWithDamping: 1,
                                       initialSpringVelocity: 0,
                                       options: .curveEaseIn,
                                       animations: { self.window.transform = Banners.hiddenTransform },
                                       completion: { _ in
                                        self.window.isHidden = true
                                        bannerView.removeFromSuperview()
                                        self.showNext()
                        })
        })
    }
}

// MARK: - Extensions

public extension Banners {
    
    /// Shows error message.
    ///
    /// - Parameter errorMessage: an error message.
    func show(errorMessage: String) {
        show(errorMessage,
             delay: errorMessage.count > 100 ? 7 : 5,
             bouncing: 0.6,
             backgroundColor: .messageErrorBackground,
             borderColor: .messageErrorBorder)
    }
    
    /// Shows error.
    ///
    /// - Parameter error: an error.
    func show(error: Error) {
        show(errorMessage: error.localizedDescription)
    }
}
