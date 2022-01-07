//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// `ChatScrollView` implements the bottom-to-top scrolling behavior common to chats.
@available(iOS 14, *)
struct ChatScrollView<Content>: View where Content: View {
    var content: () -> Content

    @State private var contentHeight: CGFloat = .zero
    @State private var contentOffset: CGFloat = .zero
    @State private var scrollOffset: CGFloat = .zero

    var body: some View {
        GeometryReader { geometry in
            self.vertical(geometry: geometry)
        }
        .clipped()
    }

    private func vertical(geometry: GeometryProxy) -> some View {
        VStack {
            content()
        }
        .modifier(ViewHeightKey())
        .onPreferenceChange(ViewHeightKey.self) {
            self.updateHeight(with: $0, outerHeight: geometry.size.height)
        }
        .frame(height: geometry.size.height, alignment: .bottom)
        .offset(y: contentOffset + scrollOffset)
        .animation(.easeInOut)
        .gesture(
            DragGesture()
                .onChanged { self.onDragChanged($0) }
                .onEnded { self.onDragEnded($0, outerHeight: geometry.size.height) }
        )
    }

    private func onDragChanged(_ value: DragGesture.Value) {
        scrollOffset = value.location.y - value.startLocation.y
    }

    private func onDragEnded(_ value: DragGesture.Value, outerHeight: CGFloat) {
        let scrollOffset = value.predictedEndLocation.y - value.startLocation.y

        updateOffset(with: scrollOffset, outerHeight: outerHeight)
        self.scrollOffset = 0
    }

    private func updateHeight(with height: CGFloat, outerHeight: CGFloat) {
        let delta = contentHeight - height
        contentHeight = height
        if abs(contentOffset) > .zero {
            updateOffset(with: delta, outerHeight: outerHeight)
        }
    }

    private func updateOffset(with delta: CGFloat, outerHeight: CGFloat) {
        let topLimit = contentHeight - outerHeight

        if topLimit < .zero {
            contentOffset = .zero
        } else {
            var proposedOffset = contentOffset + delta
            if proposedOffset < .zero {
                proposedOffset = 0
            } else if proposedOffset > topLimit {
                proposedOffset = topLimit
            }
            contentOffset = proposedOffset
        }
    }
}

struct ViewHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

@available(iOS 13, *)
extension ViewHeightKey: ViewModifier {
    func body(content: Content) -> some View {
        content.background(GeometryReader { proxy in
            Color.clear.preference(key: Self.self, value: proxy.size.height)
        })
    }
}

@available(iOS 14, *)
extension View {
    func onKeyboardAppear(_ callback: @escaping () -> Void) -> some View {
        onAppear {
            NotificationCenter.default
                .addObserver(forName: UIResponder.keyboardDidShowNotification, object: nil, queue: .main) { _ in
                    callback()
                }
        }
    }
}
