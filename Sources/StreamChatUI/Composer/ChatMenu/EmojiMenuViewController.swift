//
//  EmojiMenuViewController.swift
//  StreamChatUI
//
//  Created by Parth Kshatriya on 25/03/22.
//

import UIKit
import SwiftUI
import StreamChat

class EmojiMenuViewController: UIViewController {

    //MARK: Override
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 14.0.0, *) {
            self.children.forEach { vc in
                vc.removeFromParent()
            }
            var chatMenuView = EmojiMenuView()
            let controller = UIHostingController(rootView: chatMenuView)
            addChild(controller)
            controller.view.translatesAutoresizingMaskIntoConstraints = false
            controller.view.clipsToBounds = true
            self.view.addSubview(controller.view)
            controller.didMove(toParent: self)
            self.view.clipsToBounds = true
            NSLayoutConstraint.activate([
                controller.view.widthAnchor.constraint(equalTo: self.view.widthAnchor),
                controller.view.heightAnchor.constraint(equalTo: self.view.heightAnchor),
                controller.view.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                controller.view.centerYAnchor.constraint(equalTo: self.view.centerYAnchor)
            ])
        } else {
            // Fallback on earlier versions
        }
    }

}

@available(iOS 14.0.0, *)
struct EmojiMenuView: View {
    let rows = [
        GridItem(.flexible())
    ]
    let emojiType = EmojiType.allCases
    
    var body: some View {
        ZStack {
            VStack{
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: rows, alignment: .center) {
                        ForEach(emojiType, id: \.self) { type  in
                            ZStack(alignment: .topLeading) {
                                Button(action: {

                                }, label: {
                                    Image(uiImage: type.emojiImage())
                                        .foregroundColor(.white)
                                })
                            }
                            .frame(height: 30)
                            .padding(.horizontal, 15)
                        }
                    }
                }
                .frame(height: 30)
                Spacer()
            }
        }
        .background(Color(UIColor(rgb: 0x1E1F1F)))
    }
}

enum EmojiType: CaseIterable {
    case activity
    case animalsNature
    case objects
    case shape
    case smileysPeople
    case travelPlaces
    case add

    func emojiImage() -> UIImage {
        switch self {
        case .activity:
            return Appearance.default.images.activity
        case .animalsNature:
            return Appearance.default.images.animals_Nature
        case .objects:
            return Appearance.default.images.objects
        case .shape:
            return Appearance.default.images.shape
        case .smileysPeople:
            return Appearance.default.images.smileys_People
        case .travelPlaces:
            return Appearance.default.images.travel_Places
        case .add:
            return Appearance.default.images.add
        }
    }
}
