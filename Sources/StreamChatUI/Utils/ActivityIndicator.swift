//
//  ActivityIndicator.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 14/12/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

fileprivate let overlayViewTag: Int = 999
fileprivate let activityIndicatorViewTag: Int = 1000

// Public interface
public extension UIView {
    func displayAnimatedActivityIndicatorView() {
        setActivityIndicatorView()
    }

    func hideAnimatedActivityIndicatorView() {
        removeActivityIndicatorView()
    }
}

public extension UIViewController {
    private var overlayContainerView: UIView {
        if let navigationView: UIView = navigationController?.view {
            return navigationView
        }
        return view
    }

    func displayAnimatedActivityIndicatorView() {
        overlayContainerView.displayAnimatedActivityIndicatorView()
    }

    func hideAnimatedActivityIndicatorView() {
        overlayContainerView.hideAnimatedActivityIndicatorView()
    }
}

// Private interface
extension UIView {
    private var activityIndicatorView: UIActivityIndicatorView {
        let view: UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            view = UIActivityIndicatorView(style: .large)
        } else {
            // Fallback on earlier versions
            view = UIActivityIndicatorView()
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.tag = activityIndicatorViewTag
        return view
    }

    private var overlayView: UIView {
        let view: UIView = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        view.alpha = 0.5
        view.tag = overlayViewTag
        return view
    }

    private func setActivityIndicatorView() {
        guard !isDisplayingActivityIndicatorOverlay() else { return }
        let overlayView: UIView = self.overlayView
        let activityIndicatorView: UIActivityIndicatorView = self.activityIndicatorView

        //add subviews
        overlayView.addSubview(activityIndicatorView)
        addSubview(overlayView)

        //add overlay constraints
        overlayView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        overlayView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true

        //add indicator constraints
        activityIndicatorView.centerXAnchor.constraint(equalTo: overlayView.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: overlayView.centerYAnchor).isActive = true

        //animate indicator
        activityIndicatorView.startAnimating()
    }

    private func removeActivityIndicatorView() {
        guard let overlayView: UIView = getOverlayView(), let activityIndicator: UIActivityIndicatorView = getActivityIndicatorView() else {
            return
        }
        UIView.animate(withDuration: 0.2, animations: {
            overlayView.alpha = 0.0
            activityIndicator.stopAnimating()
        }) { _ in
            activityIndicator.removeFromSuperview()
            overlayView.removeFromSuperview()
        }
    }

    private func isDisplayingActivityIndicatorOverlay() -> Bool {
        getActivityIndicatorView() != nil && getOverlayView() != nil
    }

    private func getActivityIndicatorView() -> UIActivityIndicatorView? {
        viewWithTag(activityIndicatorViewTag) as? UIActivityIndicatorView
    }

    private func getOverlayView() -> UIView? {
        viewWithTag(overlayViewTag)
    }
}
