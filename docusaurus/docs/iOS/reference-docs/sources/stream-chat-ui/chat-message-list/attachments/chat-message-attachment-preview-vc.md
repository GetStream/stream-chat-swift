---
title: ChatMessageAttachmentPreviewVC
---

``` swift
open class ChatMessageAttachmentPreviewVC: _ViewController, WKNavigationDelegate, AppearanceProvider 
```

## Inheritance

[`_ViewController`](../../common-views/_view-controller), [`AppearanceProvider`](../../utils/appearance-provider), `WKNavigationDelegate`

## Properties

### `content`

``` swift
public var content: URL? 
```

### `webView`

``` swift
public private(set) lazy var webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
        .withoutAutoresizingMaskConstraints
```

### `activityIndicatorView`

``` swift
public private(set) lazy var activityIndicatorView 
```

## Methods

### `setUpAppearance()`

``` swift
override open func setUpAppearance() 
```

### `setUp()`

``` swift
override open func setUp() 
```

### `setUpLayout()`

``` swift
override open func setUpLayout() 
```

### `updateContent()`

``` swift
override open func updateContent() 
```

### `goBack()`

``` swift
@objc open func goBack() 
```

### `goForward()`

``` swift
@objc open func goForward() 
```

### `close()`

``` swift
@objc open func close() 
```

### `webView(_:didStartProvisionalNavigation:)`

``` swift
public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) 
```

### `webView(_:didFinish:)`

``` swift
public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) 
```
