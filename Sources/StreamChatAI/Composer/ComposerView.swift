//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Photos
import PhotosUI
import SwiftUI
import UIKit

/// A fully featured prompt-composer surface for AI chat applications.
///
/// `ComposerView` is generic over a ``ComposerViewFactory`` so you can swap out any
/// individual slot — the leading attachment button, the central input area, the
/// trailing action area, or the attachment picker sheet — without rebuilding the
/// whole composer from scratch.
///
/// ## Basic usage
///
/// ```swift
/// ComposerView { message in
///     send(message)
/// }
/// ```
///
/// ## Custom factory
///
/// ```swift
/// ComposerView(viewFactory: MyFactory()) { message in
///     send(message)
/// }
/// ```
///
/// Pass a ``ComposerViewModel`` instance if you need to control focus, inject
/// pre-filled text, or manage chat-option chips from outside the view:
///
/// ```swift
/// @StateObject private var composerViewModel = ComposerViewModel()
///
/// ComposerView(viewModel: composerViewModel) { message in
///     send(message)
/// }
/// ```
///
/// - Note: Requires iOS 16 or later.
@available(iOS 16, *)
public struct ComposerView<ComposerFactory: ComposerViewFactory>: View {
    private let viewFactory: ComposerFactory

    @StateObject var viewModel: ComposerViewModel
    @StateObject var speechHandler: SpeechHandler = .init()

    private let colors: Colors

    var isGenerating: Bool

    var onMessageSend: (MessageData) -> Void
    var onStopGenerating: (() -> Void)?

    public init(
        viewFactory: ComposerFactory = DefaultViewFactory.shared,
        viewModel: ComposerViewModel? = nil,
        colors: Colors = Colors(),
        isGenerating: Bool = false,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.viewFactory = viewFactory
        _viewModel = StateObject(wrappedValue: viewModel ?? ComposerViewModel())
        self.colors = colors
        self.onMessageSend = onMessageSend
        self.isGenerating = isGenerating
        self.onStopGenerating = onStopGenerating
    }
    
    public var body: some View {
        HStack {
            viewFactory.makeLeadingComposerView(
                options: .init(
                    colors: colors, onTap: {
                        viewModel.sheetShown = true
                    }
                )
            )
            
            viewFactory.makeComposerInputView(
                options: .init(
                    viewModel: viewModel,
                    speechHandler: speechHandler,
                    colors: colors,
                    isGenerating: isGenerating,
                    onMessageSend: onMessageSend,
                    onStopGenerating: onStopGenerating
                )
            )

            viewFactory.makeTrailingComposerView(options: .init())
        }
        .padding(.all, 8)
        .foregroundStyle(colors.composer.containerForeground)
        .sheet(isPresented: $viewModel.sheetShown) {
            viewFactory.makeComposerPickerView(options: .init(viewModel: viewModel))
                .presentationDetents([.medium, .large])
        }
    }
}

/// The default leading button for ``ComposerView``.
///
/// Renders a circular `+` icon that, when tapped, opens the attachment picker sheet.
/// The ``ComposerViewFactory/makeLeadingComposerView(options:)`` default implementation
/// returns this view. Supply your own factory method to replace it.
@available(iOS 16, *)
public struct AddAttachmentsButton: View {
    var colors: Colors
    var onTap: () -> Void
    
    public init(colors: Colors, onTap: @escaping () -> Void) {
        self.colors = colors
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: "plus")
                .foregroundStyle(colors.composer.attachmentButtonIcon)
                .fontWeight(.semibold)
        }
        .padding(.all, 12)
        .background(colors.composer.attachmentButtonBackground)
        .clipShape(.circle)
    }
}

/// The default central input area rendered by ``ComposerView``.
///
/// Contains a multi-line `TextField`, an inline ``SpeechToTextButton``, a send
/// button, and a stop-generating button. It also shows attachment thumbnails and
/// the active chat-option chip when those are present on the view model.
///
/// `ComposerInputView` observes ``ComposerViewModel/isTextFieldFocused`` and keeps
/// the keyboard in sync: set `isTextFieldFocused = true` to programmatically focus
/// the field and `false` to dismiss the keyboard.
///
/// Override ``ComposerViewFactory/makeComposerInputView(options:)`` to replace this
/// view with your own implementation while keeping the rest of the composer intact.
@available(iOS 16, *)
public struct ComposerInputView<TrailingView: View>: View {
    @ObservedObject var viewModel: ComposerViewModel
    @ObservedObject var speechHandler: SpeechHandler

    private let colors: Colors

    var isGenerating: Bool

    /// Shown inside the field while it is empty and nothing is generating.
    private let trailingView: TrailingView

    var onMessageSend: (MessageData) -> Void
    var onStopGenerating: (() -> Void)?

    @FocusState var isFocused: Bool

    public init(
        viewModel: ComposerViewModel,
        speechHandler: SpeechHandler,
        colors: Colors,
        isGenerating: Bool,
        trailingView: TrailingView,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.speechHandler = speechHandler
        self.colors = colors
        self.isGenerating = isGenerating
        self.trailingView = trailingView
        self.onMessageSend = onMessageSend
        self.onStopGenerating = onStopGenerating
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            if !viewModel.attachments.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.attachments, id: \.self) { url in
                            SelectedAttachmentThumbnail(url: url) {
                                withAnimation {
                                    viewModel.removeAttachment(url)
                                }
                            }
                        }
                    }
                }
            }
            
            if let selectedChatOption = viewModel.selectedChatOption {
                HStack {
                    HStack {
                        Image(systemName: selectedChatOption.icon)
                        Text(selectedChatOption.shortTitle)
                            .font(.headline)
                        Button {
                            withAnimation {
                                viewModel.selectedChatOption = nil
                            }
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                    .foregroundStyle(colors.composer.selectedOptionForeground)
                    .padding(.all, 8)
                    .background(colors.composer.selectedOptionBackground)
                    .cornerRadius(16)
                    
                    Spacer()
                }
            }
            
            HStack {
                TextField(L10n.Composer.placeholderAskAnything, text: $viewModel.text, axis: .vertical)
                    .lineLimit(1...5)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                
                ZStack {
                    trailingView
                        .fontWeight(.semibold)
                        .opacity(isGenerating ? 0 : (text.isEmpty ? 1 : 0))
                    
                    Button {
                        onMessageSend(.init(text: text, attachments: viewModel.attachments, chatOption: viewModel.selectedChatOption))
                        viewModel.cleanUpData()
                        if speechHandler.isRecording {
                            speechHandler.stop()
                        }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22)
                    }
                    .opacity(isGenerating ? 0 : (text.isEmpty ? 0 : 1))
                    
                    Button {
                        onStopGenerating?()
                    } label: {
                        Image(systemName: "stop.circle")
                            .foregroundStyle(colors.transcription.icon)
                    }
                    .opacity(isGenerating ? 1 : 0)
                }
            }
        }
        .padding(.all, 12)
        .background(colors.composer.containerBackground)
        .cornerRadius(24)
        .onAppear {
            if viewModel.isTextFieldFocused {
                isFocused = true
            }
        }
        .onChange(of: viewModel.isTextFieldFocused) { newValue in
            isFocused = newValue
        }
        .onChange(of: viewModel.text) { newText in
            if newText.isEmpty && speechHandler.isRecording {
                speechHandler.stop()
            }
        }
    }

    var text: String {
        viewModel.text
    }
}

@available(iOS 16, *)
public extension ComposerInputView where TrailingView == SpeechToTextButton {
    /// Creates the input with the default ``SpeechToTextButton`` inside the field.
    init(
        viewModel: ComposerViewModel,
        speechHandler: SpeechHandler,
        colors: Colors,
        isGenerating: Bool,
        onMessageSend: @escaping (MessageData) -> Void,
        onStopGenerating: (() -> Void)? = nil
    ) {
        self.init(
            viewModel: viewModel,
            speechHandler: speechHandler,
            colors: colors,
            isGenerating: isGenerating,
            trailingView: SpeechToTextButton(speechHandler: speechHandler, colors: colors) { newText in
                viewModel.text = newText
            },
            onMessageSend: onMessageSend,
            onStopGenerating: onStopGenerating
        )
    }
}

public struct ChatOption: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
    public let shortTitle: String
    public var customData: [String: Any]?
    public var action: () -> Void

    public static func == (lhs: ChatOption, rhs: ChatOption) -> Bool {
        lhs.id == rhs.id
    }
    
    public init(
        id: String,
        title: String,
        description: String,
        icon: String,
        shortTitle: String,
        customData: [String: Any]? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.customData = customData
        self.action = action
        self.shortTitle = shortTitle
    }
}

@available(iOS 16, *)
struct ComposerPickerView: View {
    @ObservedObject var viewModel: ComposerViewModel
    
    @StateObject private var photoLibrary = PhotoLibraryService()
    @State private var allPhotosSelection: [PhotosPickerItem] = []
    @State private var cameraPresented = false
        
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                PhotosPicker(
                    selection: $allPhotosSelection,
                    maxSelectionCount: 10,
                    matching: .images
                ) {
                    Text(L10n.Composer.buttonAllPhotos)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(Capsule())
                }
                .padding()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button {
                        cameraPresented = true
                    } label: {
                        AttachmentTile {
                            Image(systemName: "camera")
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                        }
                    }
                    .tint(.primary)
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                    
                    ForEach(photoLibrary.recentAssets, id: \.localIdentifier) { asset in
                        RecentPhotoThumbnail(
                            asset: asset,
                            service: photoLibrary,
                            isSelected: viewModel.selectedAssetURLs[asset.localIdentifier] != nil
                        ) { change in
                            switch change {
                            case .select(let attachment):
                                viewModel.selectAsset(assetID: asset.localIdentifier, attachment: attachment)
                            case .deselect:
                                viewModel.deselectAsset(assetID: asset.localIdentifier)
                            case .failed:
                                viewModel.deselectAsset(assetID: asset.localIdentifier)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            Spacer()
            if !viewModel.chatOptions.isEmpty {
                Divider()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.chatOptions) { option in
                            Button {
                                withAnimation {
                                    option.action()
                                }
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: option.icon)

                                    VStack(alignment: .leading) {
                                        Text(option.title)
                                            .font(.headline)

                                        Text(option.description)
                                            .font(.subheadline)
                                            .foregroundStyle(.gray)
                                    }
                                    Spacer()
                                }
                                .tint(.primary)
                                .foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await photoLibrary.prepare(limit: 10)
        }
        .onChange(of: allPhotosSelection) { newItems in
            guard !newItems.isEmpty else { return }
            
            Task {
                for item in newItems {
                    if let identifier = item.itemIdentifier,
                       let asset = photoLibrary.asset(for: identifier),
                       let url = await photoLibrary.fileURL(for: asset) {
                        viewModel.appendAttachment(.init(url: url, isTemporary: false))
                        continue
                    }
                    
                    if let url = try? await item.loadTransferable(type: URL.self) {
                        viewModel.appendAttachment(.init(url: url, isTemporary: false))
                        continue
                    }
                    
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let tempURL = writeAttachmentDataToTemporaryURL(data) {
                        viewModel.appendAttachment(.init(url: tempURL, isTemporary: true))
                    }
                }
                
                allPhotosSelection = []
            }
        }
        .fullScreenCover(isPresented: $cameraPresented) {
            CameraPicker(isPresented: $cameraPresented) { result in
                viewModel.appendAttachment(result)
            }
        }
    }
}

@available(iOS 16, *)
private struct RecentPhotoThumbnail: View {
    enum SelectionChange {
        case select(AttachmentLocation)
        case deselect
        case failed
    }
    
    let asset: PHAsset
    @ObservedObject var service: PhotoLibraryService
    let isSelected: Bool
    let onSelectionChange: (SelectionChange) -> Void
    
    @State private var image: UIImage?
    @State private var didFail = false
    @State private var isFetchingAttachment = false
    
    var body: some View {
        Button {
            Task {
                if isSelected {
                    didFail = false
                    onSelectionChange(.deselect)
                    return
                }
                
                guard !isFetchingAttachment else { return }
                didFail = false
                isFetchingAttachment = true
                
                var attachment: AttachmentLocation?
                if let url = await service.fileURL(for: asset) {
                    attachment = .init(url: url, isTemporary: false)
                } else if let data = await service.data(for: asset),
                          let tempURL = writeAttachmentDataToTemporaryURL(data) {
                    attachment = .init(url: tempURL, isTemporary: true)
                }
                isFetchingAttachment = false
                if let attachment {
                    didFail = false
                    onSelectionChange(.select(attachment))
                } else {
                    didFail = true
                    onSelectionChange(.failed)
                }
            }
        } label: {
            ThumbnailTile(image: image, didFail: didFail)
                .overlay(alignment: .topTrailing) {
                    SelectionBadge(isSelected: isSelected)
                        .padding(6)
                }
        }
        .disabled(isFetchingAttachment)
        .task {
            guard image == nil else { return }
            let scale = UIScreen.main.scale
            let size = CGSize(width: 100 * scale, height: 100 * scale)
            if let thumbnail = await service.thumbnail(for: asset, targetSize: size) {
                image = thumbnail
                didFail = false
            } else {
                didFail = true
            }
        }
        .onChange(of: isSelected) { selected in
            if !selected {
                didFail = false
            }
        }
    }
}

@available(iOS 16, *)
private struct SelectedAttachmentThumbnail: View {
    let url: URL
    let onRemove: () -> Void
    
    @State private var image: UIImage?
    @State private var didFail = false
    
    var body: some View {
        ThumbnailTile(image: image, didFail: didFail)
            .overlay(alignment: .topTrailing) {
                Button(action: onRemove) {
                    TileBadge(systemName: "xmark", fill: Color.black.opacity(0.7))
                        .frame(width: 22, height: 22)
                }
                .buttonStyle(.plain)
                .padding(6)
            }
            .task {
                guard image == nil else { return }
                if let loaded = await loadImage() {
                    image = loaded
                    didFail = false
                } else {
                    didFail = true
                }
            }
    }
    
    private func loadImage() async -> UIImage? {
        await Task.detached(priority: .userInitiated) {
            let shouldStopAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if shouldStopAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            guard let data = try? Data(contentsOf: url) else { return nil }
            return UIImage(data: data)
        }.value
    }
}

@available(iOS 16, *)
private struct AttachmentTile<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(UIColor.lightGray).opacity(0.3))
            .overlay {
                content()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .frame(width: 100, height: 100)
            .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// A photo's tile: the photo once it has loaded, a warning if it couldn't, and a spinner until then.
@available(iOS 16, *)
private struct ThumbnailTile: View {
    let image: UIImage?
    let didFail: Bool
    
    var body: some View {
        AttachmentTile {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .allowsHitTesting(false)
                    .clipped()
            } else if didFail {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else {
                ProgressView()
            }
        }
    }
}

/// A round badge on a tile, such as its check mark or its remove button.
@available(iOS 16, *)
private struct TileBadge: View {
    let systemName: String
    let fill: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.9))
                .shadow(radius: 1)
            Circle()
                .fill(fill)
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

@available(iOS 16, *)
private struct SelectionBadge: View {
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            if isSelected {
                TileBadge(systemName: "checkmark", fill: .accentColor)
            } else {
                Circle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: 16, height: 16)
            }
        }
        .frame(width: 20, height: 20)
    }
}

@available(iOS 16, *)
private struct CameraPicker: UIViewControllerRepresentable {
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

private func writeAttachmentDataToTemporaryURL(_ data: Data) -> URL? {
    let fileManager = FileManager.default
    let fileURL = fileManager.temporaryDirectory.appendingPathComponent(
        "streamchat-attachment-\(UUID().uuidString).jpg"
    )
    
    let dataToWrite: Data
    if data.starts(with: [0xff, 0xd8]) {
        dataToWrite = data
    } else if let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.9) {
        dataToWrite = jpegData
    } else {
        return nil
    }
    
    do {
        try dataToWrite.write(to: fileURL, options: [.atomic])
        return fileURL
    } catch {
        print("ComposerView attachment write error: \(error.localizedDescription)")
        return nil
    }
}

public struct MessageData {
    public let text: String
    public let attachments: [URL]
    public var chatOption: ChatOption?
    
    public init(text: String, attachments: [URL] = [], chatOption: ChatOption? = nil) {
        self.text = text
        self.attachments = attachments
        self.chatOption = chatOption
    }
}
