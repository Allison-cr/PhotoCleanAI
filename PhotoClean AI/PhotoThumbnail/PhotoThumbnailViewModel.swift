//
//  PhotoThumbnailViewModel.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 22.04.2025.
//

import SwiftUI
import Photos


class PhotoThumbnailViewModel: ObservableObject {
    @Published var imageCache: [String: UIImage] = [:]
    
    func loadImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = imageCache[asset.localIdentifier] {
            completion(cachedImage)
            return
        }
        
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: CGSize(width: UIScreen.main.bounds.width * 0.46, height: 0.25 * UIScreen.main.bounds.height),
                                              contentMode: .aspectFill,
                                              options: nil) { result, _ in
            if let result = result {
                self.imageCache[asset.localIdentifier] = result
                completion(result)
            } else {
                completion(nil)
            }
        }
    }
}
