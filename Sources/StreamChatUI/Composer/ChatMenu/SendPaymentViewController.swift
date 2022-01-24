//
//  SendPaymentViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 24/01/22.
//

import UIKit
import SwiftUI

class SendPaymentViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(rgb: 0x2C2C2E)
        if #available(iOS 14.0.0, *) {
            let controller = UIHostingController(rootView: SendPaymentView())
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(controller.view)
            controller.didMove(toParent: self)

            NSLayoutConstraint.activate([
                controller.view.widthAnchor.constraint(equalTo: view.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: view.heightAnchor),
                controller.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                controller.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
        } else {
            // Fallback on earlier versions
        }
    }

}

@available(iOS 14.0.0, *)
struct SendPaymentView: View {
    @State private var selectedPaymentMode = ""
    let rows = [
           GridItem(.flexible())
       ]
    var paymentTypes: [String] {
        return ["Default",
                "Anniversary",
                "Birthday",
                "Booze",
                "Gracias",
                "Je t'aime",
                "Holiday"]
    }
    var body: some View {
        ZStack {
            Color(UIColor(rgb: 0x2C2C2E))
            Spacer()
                .frame(height: 15)
            VStack(spacing: 0) {
                Text("SENDING 750 ONE")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                Spacer()
                    .frame(height: 25)
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, alignment: .center) {
                        ForEach(paymentTypes, id: \.self) { type  in
                            ZStack(alignment: .topLeading) {
                                if type == selectedPaymentMode {
                                    Color(Appearance.default.colorPalette.themeBlue).opacity(0.2)
                                } else {
                                    Color.white.opacity(0.2)
                                }
                                VStack {
                                    Text(type)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.white)
                                        .padding(.top, 10)
                                        .padding(.leading, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .onTapGesture {
                                selectedPaymentMode = type
                            }
                            .cornerRadius(4)
                            .frame(width: 130)
                            .padding(5)
                        }
                    }
                }
                .frame(height: 130)
                Spacer()
            }
            .background(Color(UIColor(rgb: 0x2C2C2E)))
            .padding(15)
        }
    }
}
