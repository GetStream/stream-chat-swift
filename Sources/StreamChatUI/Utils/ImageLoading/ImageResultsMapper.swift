//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import UIKit

/// Helper component to map image results.
struct ImageResultsMapper {
    let results: [Result<UIImage, Error>]

    init(results: [Result<UIImage, Error>]) {
        self.results = results
    }

    /// Replace errors with placeholder images.
    ///
    /// - Parameter placeholderImages: The placeholder images.
    /// - Returns: Returns an array of UIImages without errors.
    func mapErrors(with placeholderImages: [UIImage]) -> [UIImage] {
        var placeholderImages = placeholderImages
        var finalImages: [UIImage] = []

        for result in results {
            switch result {
            case let .success(image):
                finalImages.append(image)
            case .failure:
                guard !placeholderImages.isEmpty else {
                    continue
                }

                let placeholder = placeholderImages.removeFirst()
                finalImages.append(placeholder)
            }
        }

        return finalImages
    }
}
