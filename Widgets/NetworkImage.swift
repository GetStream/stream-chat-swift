import SwiftUI

struct NetworkImage: View {
    let url: URL?

    var body: some View {
        Group {
            if let url = url, let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person")
            }
        }
    }
}
