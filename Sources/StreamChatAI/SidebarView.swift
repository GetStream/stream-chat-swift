//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct SidebarView<Menu: View, Content: View>: View {
    @Binding var isOpen: Bool
    var splitWidthRatio: CGFloat
    var edgeActivationWidth: CGFloat
    let excludedBottomHeight: CGFloat
    let menu: () -> Menu
    let content: () -> Content
    
    @State private var dragOffset: CGFloat = 0
    @State private var isDragActive = false
    
    private let sidebarAnimation = Animation.spring(response: 0.28, dampingFraction: 0.85)
    
    public init(
        isOpen: Binding<Bool>,
        splitWidthRatio: CGFloat = 0.82,
        edgeActivationWidth: CGFloat = 32,
        excludedBottomHeight: CGFloat,
        menu: @escaping () -> Menu,
        content: @escaping () -> Content
    ) {
        self.menu = menu
        self.content = content
        _isOpen = isOpen
        self.splitWidthRatio = splitWidthRatio
        self.edgeActivationWidth = edgeActivationWidth
        self.excludedBottomHeight = excludedBottomHeight
        self.dragOffset = dragOffset
        self.isDragActive = isDragActive
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let splitWidth = geometry.size.width * splitWidthRatio
            let clampedDrag = max(-splitWidth, min(splitWidth, dragOffset))
            let baselineOffset = isOpen ? 0 : -splitWidth
            let totalOffset = baselineOffset + clampedDrag
            let availableHeight = max(0, geometry.size.height - excludedBottomHeight)
            let contentGesture = splitDragGesture(splitWidth: splitWidth, availableHeight: availableHeight)
            let overlayGesture = splitDragGesture(splitWidth: splitWidth, availableHeight: nil)
            let openProgress = min(max(1 - abs(totalOffset) / max(splitWidth, .leastNormalMagnitude), 0), 1)
            let overlayOrigin = max(splitWidth + totalOffset, 0)
            let overlayWidth = max(geometry.size.width - overlayOrigin, 0)
            
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    menu()
                        .frame(width: splitWidth, height: geometry.size.height)
                        .background(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.15), radius: 12, x: 4, y: 0)
                        .simultaneousGesture(contentGesture, including: .gesture)
                    
                    content()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .simultaneousGesture(contentGesture, including: .gesture)
                }
                .offset(x: totalOffset)
                
                if openProgress > 0 {
                    Color.black.opacity(0.25 * openProgress)
                        .frame(width: overlayWidth)
                        .offset(x: overlayOrigin)
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeSplitView(animated: true)
                        }
                        .gesture(overlayGesture)
                }
            }
            .animation(sidebarAnimation, value: isOpen)
            .animation(sidebarAnimation, value: dragOffset)
            .transaction { transaction in
                if isDragActive {
                    transaction.animation = .none
                }
            }
        }
        .onChange(of: isOpen) { newValue in
            if !newValue {
                dragOffset = 0
                isDragActive = false
            }
        }
    }
    
    private func splitDragGesture(splitWidth: CGFloat, availableHeight: CGFloat?) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .local)
            .onChanged { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                
                if !isOpen && !isDragActive && value.startLocation.x > edgeActivationWidth {
                    return
                }
                
                if let availableHeight, value.startLocation.y > availableHeight {
                    return
                }
                if abs(horizontal) < abs(vertical) {
                    return
                }
                
                if !isDragActive {
                    isDragActive = true
                }
                
                if isOpen {
                    dragOffset = max(-splitWidth, min(0, horizontal))
                } else if horizontal >= 0 {
                    dragOffset = min(splitWidth, horizontal)
                } else {
                    dragOffset = 0
                }
            }
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                
                if !isOpen && value.startLocation.x > edgeActivationWidth {
                    resetDragState(animated: false)
                    return
                }
                if let availableHeight, value.startLocation.y > availableHeight {
                    resetDragState(animated: false)
                    return
                }
                if abs(horizontal) < abs(vertical) {
                    resetDragState(animated: false)
                    return
                }
                
                if isOpen {
                    if horizontal < -splitWidth * 0.2 {
                        closeSplitView(animated: true)
                    } else {
                        openSplitView()
                    }
                } else if horizontal > splitWidth * 0.2 {
                    openSplitView()
                } else {
                    closeSplitView(animated: true)
                }
                
                resetDragState(animated: false)
            }
    }
    
    private func openSplitView() {
        withAnimation(sidebarAnimation) {
            isOpen = true
            dragOffset = 0
        }
        isDragActive = false
    }
    
    private func closeSplitView(animated: Bool) {
        let animation = animated ? sidebarAnimation : nil
        if let animation {
            withAnimation(animation) {
                isOpen = false
                dragOffset = 0
            }
        } else {
            isOpen = false
            dragOffset = 0
        }
        isDragActive = false
    }
    
    private func resetDragState(animated: Bool) {
        let animation = animated ? sidebarAnimation : nil
        if let animation {
            withAnimation(animation) {
                dragOffset = 0
            }
        } else {
            dragOffset = 0
        }
        isDragActive = false
    }
}
