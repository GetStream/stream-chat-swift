//
//  UIViewController+ImagePicker.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 03/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Photos.PHPhotoLibrary

extension ViewController {
    typealias ImagePickerCompletion = (_ imagePickedInfo: PickedImage?, _ authorizationStatus: PHAuthorizationStatus) -> Void
    
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
                        completion(nil, status)
                    }
                }
            }
        case .restricted, .denied:
            completion(nil, status)
        case .authorized:
            showAuthorizeImagePicker(sourceType: sourceType, completion)
        @unknown default:
            print(#file, #function, #line, "Unknown authorization status: \(status.rawValue)")
            return
        }
    }
    
    private func showAuthorizeImagePicker(sourceType: UIImagePickerController.SourceType,
                                          _ completion: @escaping ImagePickerCompletion) {
        let delegateKey = String(ObjectIdentifier(self).hashValue) + "ImagePickerDelegate"
        let imagePickerViewController = UIImagePickerController()
        imagePickerViewController.sourceType = sourceType
        
        if sourceType != .camera || Bundle.main.hasInfoDescription(for: .microphone) {
            imagePickerViewController.mediaTypes = UIImagePickerController.availableMediaTypes(for: sourceType) ?? [.imageFileType]
        }
        
        let delegate = ImagePickerDelegate(completion) {
            objc_setAssociatedObject(self, delegateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            completion(nil, .notDetermined)
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
    
    func showImagePickerAuthorizationStatusAlert(_ status: PHAuthorizationStatus) {
        let message: String
        
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
        
        showAlert(title: "Photo Library Permission",
                  message: message,
                  actions: [.init(title: "Settings",
                                  style: .default,
                                  handler: { _ in
                                      if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                          UIApplication.shared.open(settingsURL)
                                      }
                                  }),
                            .init(title: "Ok", style: .default, handler: nil)])
    }
}

// MARK: - Image Picker Delegate

fileprivate final class ImagePickerDelegate: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    typealias Cancel = () -> Void
    let completion: ViewController.ImagePickerCompletion
    let cancellation: Cancel
    
    init(_ completion: @escaping ViewController.ImagePickerCompletion, cancellation: @escaping Cancel) {
        self.completion = completion
        self.cancellation = cancellation
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        completion(PickedImage(info: info), .authorized)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        cancellation()
    }
}
