//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import WebKit

open class ChatAttachmentPreviewVC: ViewController {
    public var content: URL? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        .withoutAutoresizingMaskConstraints

    public private(set) lazy var activityIndicatorView = UIActivityIndicatorView(style: .gray)

    private lazy var closeButton = UIBarButtonItem(
        image: UIImage(named: "close", in: .streamChatUI),
        style: .plain,
        target: self,
        action: #selector(close)
    )

    private lazy var goBackButton = UIBarButtonItem(
        title: "←",
        style: .plain,
        target: self,
        action: #selector(goBack)
    )

    private lazy var goForwardButton = UIBarButtonItem(
        title: "→",
        style: .plain,
        target: self,
        action: #selector(goForward)
    )

    // MARK: - Life Cycle

    override public func defaultAppearance() {
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = closeButton
        navigationItem.rightBarButtonItems = [
            goForwardButton,
            goBackButton,
            UIBarButtonItem(customView: activityIndicatorView)
        ]
    }

    override open func setUp() {
        super.setUp()

        webView.navigationDelegate = self
    }

    override open func setUpLayout() {
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    override open func updateContent() {
        goBackButton.isEnabled = false
        goForwardButton.isEnabled = false
        title = content?.absoluteString

        if let url = self.content {
            webView.load(URLRequest(url: url))
        } else {
            activityIndicatorView.stopAnimating()
        }
    }
}

// MARK: - WKNavigationDelegate

extension ChatAttachmentPreviewVC: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activityIndicatorView.startAnimating()
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicatorView.stopAnimating()

        webView.evaluateJavaScript("document.title") { data, _ in
            if let title = data as? String, !title.isEmpty {
                self.title = title
            }
        }

        goBackButton.isEnabled = webView.canGoBack
        goForwardButton.isEnabled = webView.canGoForward
    }
}

// MARK: - Actions

extension ChatAttachmentPreviewVC {
    @objc open func goBack() {
        if let item = webView.backForwardList.backItem {
            webView.go(to: item)
        }
    }

    @objc open func goForward() {
        if let item = webView.backForwardList.forwardItem {
            webView.go(to: item)
        }
    }

    @objc open func close() {
        dismiss(animated: true)
    }
}
