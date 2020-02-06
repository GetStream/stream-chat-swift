//
//  RxDocumentPickerViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatCore
import RxSwift
import RxCocoa
import UIKit

extension UIDocumentPickerViewController: HasDelegate {
    public typealias Delegate = UIDocumentPickerDelegate
}

private final class RxUIDocumentPickerDelegateProxy: DelegateProxy<UIDocumentPickerViewController, UIDocumentPickerDelegate>,
                                                     DelegateProxyType,
                                                     UIDocumentPickerDelegate {
    
    private (set) weak var controller: UIDocumentPickerViewController?
    
    init(controller: ParentObject) {
        self.controller = controller
        super.init(parentObject: controller, delegateProxy: RxUIDocumentPickerDelegateProxy.self)
    }
    
    static func registerKnownImplementations() {
        register { RxUIDocumentPickerDelegateProxy(controller: $0) }
    }
}

extension Reactive where Base: UIDocumentPickerViewController {
    
    /// Delegate proxy for `UIDocumentPickerViewController`.
    var delegate: DelegateProxy<UIDocumentPickerViewController, UIDocumentPickerDelegate> {
        return RxUIDocumentPickerDelegateProxy.proxy(for: base)
    }
    
    /// Tells that user has selected one or more documents.
    var didPickDocumentsAt: Observable<[URL]> {
        return delegate.methodInvoked(#selector(UIDocumentPickerDelegate.documentPicker(_:didPickDocumentsAt:)))
            .compactMap { $0.last as? [URL] }
    }
    
    /// Tells that user canceled the document picker.
    var documentPickerWasCancelled: Observable<()> {
        return delegate.methodInvoked(#selector(UIDocumentPickerDelegate.documentPickerWasCancelled(_:))).map {_ in () }
    }
}
