//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

@available(iOS 16, *)
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onCapture: (AttachmentLocation) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.delegate = context.coordinator
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            controller.sourceType = .camera
        }
        controller.allowsEditing = false
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        private let parent: CameraPicker
        
        init(parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
        
        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { dismiss() }
            
            if let imageURL = info[.imageURL] as? URL {
                DispatchQueue.main.async {
                    self.parent.onCapture(.init(url: imageURL, isTemporary: false))
                }
                return
            }
            
            let image = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
            guard let image, let data = image.jpegData(compressionQuality: 0.9) else { return }
            guard let url = writeAttachmentDataToTemporaryURL(data) else { return }
            DispatchQueue.main.async {
                self.parent.onCapture(.init(url: url, isTemporary: true))
            }
        }
        
        private func dismiss() {
            DispatchQueue.main.async {
                self.parent.isPresented = false
            }
        }
    }
}
