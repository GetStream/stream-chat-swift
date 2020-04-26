//
//  WebViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 17/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import WebKit
import SnapKit

/// A siple web view controller with `WKWebView` and navigation buttons in the navigation bar.
open class WebViewController: UIViewController, WKNavigationDelegate {
    
    /// An activity indicator.
    public private(set) lazy var activityIndicatorView = UIActivityIndicatorView(style: .gray)
    /// A web view.
    public private(set) lazy var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    /// An URL to load in the web view.
    public var url: URL?
    
    private lazy var goBackButton = UIBarButtonItem(title: "←", style: .plain, target: self, action: #selector(goBack))
    private lazy var goForwardButton = UIBarButtonItem(title: "→", style: .plain, target: self, action: #selector(goForward))
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupWebView()
        
        if navigationController != nil {
            setupToolbar()
        }
        
        if let url = self.url {
            open(url)
        }
    }
    
    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        setDocumentMenuViewControllerSoureViewsIfNeeded(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    func setDocumentMenuViewControllerSoureViewsIfNeeded(_ viewControllerToPresent: UIViewController) {
        // Prevent the app from crashing if the WKWebView decides to present a UIDocumentMenuViewController
        // while it self is presented modally.
        
        // More info:
        // - https://github.com/GetStream/stream-chat-swift/issues/66
        // - https://stackoverflow.com/questions/58164583/wkwebview-with-the-new-ios13-modal-crash-when-a-file-picker-is-invoked
        
        if #available(iOS 13, *),
            // Using NSClassFromString to remove compiler's deprecation warning for `UIDocumentMenuViewController`.
            let menuViewControllerClass = NSClassFromString("UIDocumentMenuViewController"),
            viewControllerToPresent.isKind(of: menuViewControllerClass),
            UIDevice.current.userInterfaceIdiom == .phone {
            viewControllerToPresent.popoverPresentationController?.sourceView = webView
            viewControllerToPresent.popoverPresentationController?.sourceRect =
                CGRect(x: webView.center.x, y: webView.center.y, width: 1, height: 1)
        }
    }
    
    /// Makes a request with a given `URL` to load the web view.
    ///
    /// - Parameter url: an URL for a request.
    public func open(_ url: URL) {
        open(URLRequest(url: url))
    }
    
    /// Makes a request with a given `URLRequest` to load the web view.
    ///
    /// - Parameter request: a request.
    public func open(_ request: URLRequest) {
        activityIndicatorView.startAnimating()
        webView.load(request)
        
        if title == nil {
            title = request.url?.absoluteString
        }
    }
    
    /// Dismisses the view controller.
    @IBAction public func close(_ sender: Any) {
        dismiss(animated: true)
    }
    
    // MARK: - WebView
    
    /// Setup and layout the web view.
    open func setupWebView() {
        webView.navigationDelegate = self
        view.addSubview(webView)
        
        webView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.topMargin)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
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
    
    /// Goes back in the web view navigation.
    @objc func goBack() {
        if let item = webView.backForwardList.backItem {
            webView.go(to: item)
        }
    }
    
    /// Goes forward in the web view navigation.
    @objc func goForward() {
        if let item = webView.backForwardList.forwardItem {
            webView.go(to: item)
        }
    }
}

// MARK: - Edditional Views

extension WebViewController {
    private func setupToolbar() {
        let closeButton = UIBarButtonItem(image: UIImage.Icons.close, style: .plain, target: self, action: #selector(close(_:)))
        navigationItem.leftBarButtonItem = closeButton
        
        goBackButton.isEnabled = false
        goForwardButton.isEnabled = false
        let activityIndicator = UIBarButtonItem(customView: activityIndicatorView)
        navigationItem.rightBarButtonItems = [goForwardButton, goBackButton, activityIndicator]
        activityIndicatorView.startAnimating()
    }
}

// MARK: - Routing to the Web View

extension UIViewController {
    
    /// Presents the Open Graph data in a `WebViewController`.
    public func showWebView(url: URL?, title: String?, animated: Bool = true) {
        guard let url = url else {
            return
        }
        
        let webViewController = WebViewController()
        webViewController.url = url
        webViewController.title = title
        present(WebViewNavigationController(with: webViewController), animated: animated)
    }
}

private class WebViewNavigationController: UINavigationController {
    private let webViewController: WebViewController
    
    init(with webViewController: WebViewController) {
        self.webViewController = webViewController
        super.init(rootViewController: webViewController)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.webViewController = WebViewController(nibName: nil, bundle: nil)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        webViewController = WebViewController(nibName: nil, bundle: nil)
        super.init(coder: aDecoder)
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        webViewController.setDocumentMenuViewControllerSoureViewsIfNeeded(viewControllerToPresent)
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
