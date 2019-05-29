//
//  UIViewController+Extensions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Photos.PHPhotoLibrary

extension UIViewController {
    public var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }

    /// Hides the back button title from the navigation bar.
    public func hideBackButtonTitle() {
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}

// MARK: - Image Picker View

extension UIViewController {
    /// A completion block of an image picking.
    ///
    /// - Parameters:
    ///     - imagePickerInfo: the result of the image picking from `UIImagePickerController`.
    ///     - authorizationStatus: the current authorization status. See `PHAuthorizationStatus`.
    typealias ImagePickerCompletion = (_ imagePickerInfo: [UIImagePickerController.InfoKey : Any],
        _ authorizationStatus: PHAuthorizationStatus) -> Void
    
    func showImagePicker(sourceType: UIImagePickerController.SourceType, _ completion: @escaping ImagePickerCompletion) {
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            showAuthorizeImagePicker(sourceType: sourceType, completion)
            return
        }
        
        let status = PHPhotoLibrary.authorizationStatus()
        
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self?.showAuthorizeImagePicker(sourceType: sourceType, completion)
                    } else {
                        completion([:], status)
                    }
                }
            }
        case .restricted, .denied:
            completion([:], status)
        case .authorized:
            showAuthorizeImagePicker(sourceType: sourceType, completion)
        @unknown default:
            print(#file, #function, #line, "Unknown authorization status: \(status.rawValue)")
            return
        }
    }
    
    private func showAuthorizeImagePicker(sourceType: UIImagePickerController.SourceType, _ completion: @escaping ImagePickerCompletion) {
        let delegateKey = String(ObjectIdentifier(self).hashValue) + "ImagePickerDelegate"
        let imagePickerViewController = UIImagePickerController()
        imagePickerViewController.sourceType = sourceType
        
        let delegate = ImagePickerDelegate(completion) {
            objc_setAssociatedObject(self, delegateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            completion([:], .notDetermined)
        }
        
        imagePickerViewController.delegate = delegate
        
        if case .camera = sourceType {
            imagePickerViewController.cameraCaptureMode = .photo
            imagePickerViewController.cameraDevice = .front
            
            if UIImagePickerController.isFlashAvailable(for: .front) {
                imagePickerViewController.cameraFlashMode = .on
            }
        }
        
        objc_setAssociatedObject(self, delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        present(imagePickerViewController, animated: true)
    }
    
    func showImpagePickerAuthorizationStatusAlert(_ status: PHAuthorizationStatus) {
        var message = ""
        
        switch status {
        case .notDetermined:
            message = "Permissions are not determined."
        case .denied:
            message = "You have explicitly denied this application access to photos data."
        case .restricted:
            message = "This application is not authorized to access photo data."
        default:
            return
        }
        
        let alert = UIAlertController(title: "The Photo Library Permissions", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Ok", style: .default, handler: nil))
        present(alert, animated: true)
    }
}

// MARK: - Image Picker Delegate

fileprivate final class ImagePickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    typealias Cancel = () -> Void
    let completion: UIViewController.ImagePickerCompletion
    let cancellation: Cancel
    
    init(_ completion: @escaping UIViewController.ImagePickerCompletion, cancellation: @escaping Cancel) {
        self.completion = completion
        self.cancellation = cancellation
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        completion(info, .authorized)
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        cancellation()
        picker.dismiss(animated: true)
    }
}
