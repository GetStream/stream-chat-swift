//
//  SendPaymentViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 24/01/22.
//

import UIKit
import SwiftUI
import StreamChat

@available(iOS 14.0.0, *)
struct SendPaymentOptionView: View {
    @State private var selectedPaymentMode: WalletAttachmentPayload.PaymentTheme = .none
    @Binding var amount: String!
    var paymentType: WalletAttachmentPayload.PaymentType!
    var didSelectPayment: ((WalletAttachmentPayload.PaymentTheme) -> Void)?

    let rows = [
           GridItem(.flexible())
       ]
    var paymentTypes: [WalletAttachmentPayload.PaymentTheme] {
        return WalletAttachmentPayload.PaymentTheme.allCases
    }
    private var paymentTypeDescription: String {
        return paymentType == .request ? "REQUESTING" : "SENDING"
    }
    var body: some View {
        ZStack {
            Color(UIColor(rgb: 0x1E1F1F))
            Spacer()
                .frame(height: 15)
            VStack(spacing: 0) {
                Text("\(paymentTypeDescription) \(amount) ONE")
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
                                    Text(type.rawValue)
                                        .font(.system(size: 14))
                                        .foregroundColor(Color.white)
                                        .padding(.top, 10)
                                        .padding(.leading, 10)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .onTapGesture {
                                self.selectedPaymentMode = type
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    self.didSelectPayment?(type)
                                }
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
            .background(Color(UIColor(rgb: 0x1E1F1F)))
            .padding(15)
        }
    }
}
