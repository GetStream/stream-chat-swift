//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

@available(iOS 14, *)
extension View {
    func alert(isPresented: Binding<Bool>, _ alert: TextAlert) -> some View {
        AlertWrapper(isPresented: isPresented, alert: alert, content: self)
    }
}

@available(iOS 14, *)
struct TextAlert {
    var title: String
    var placeholder: String = ""
    var action: (String?) -> Void
}

@available(iOS 14, *)
struct AlertWrapper<Content: View>: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let alert: TextAlert
    let content: Content

    func makeUIViewController(context: UIViewControllerRepresentableContext<AlertWrapper>) -> UIHostingController<Content> {
        UIHostingController(rootView: content)
    }

    final class Coordinator {
        var alertController: UIAlertController?
        init(_ controller: UIAlertController? = nil) {
            alertController = controller
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIViewController(
        _ uiViewController: UIHostingController<Content>,
        context: UIViewControllerRepresentableContext<AlertWrapper>
    ) {
        uiViewController.rootView = content
        if isPresented, uiViewController.presentedViewController == nil {
            uiViewController.alertTextField(title: alert.title, placeholder: alert.placeholder) {
                self.isPresented = false
                self.alert.action($0)
            }
        }
        
        if !isPresented, uiViewController.presentedViewController == context.coordinator.alertController {
            uiViewController.dismiss(animated: true)
        }
    }
}
