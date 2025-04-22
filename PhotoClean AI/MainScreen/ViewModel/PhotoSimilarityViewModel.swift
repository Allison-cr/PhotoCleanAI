//
//  PhotoSimilarityViewModel.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 19.04.2025.
//
import SwiftUI
import Photos

@MainActor
class PhotoSimilarityViewModel: ObservableObject {
    @Published var assets: [PHAsset] = []
    @Published var embeddingResults: [String: [Double]] = [:]
    @Published var similarGroups: [SimilarGroup] = []
    @Published var deletedPhotoCount: Int = 0
    @Published var freedMemoryMB: Double = 0.0
    @Published var selectedImage: UIImage? = nil
    @Published var selectedImageID: String? = nil
    @Published var selectedForDeletion: Set<PHAsset> = []
    @Published var showSuccessScreen: Bool  = false
    private let extractor = EmbeddingExtractor()
    @Published var showPermissionAlert: Bool = false


    func requestPhotoAccessRecursively() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            loadPhotos(limit: 100)
            
        case .denied, .restricted:
            self.showPermissionAlert = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.requestPhotoAccessRecursively()
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    self.requestPhotoAccessRecursively()
                }
            }
        @unknown default:
            break
        }
    }
    
    func requestAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.requestPhotoAccessRecursively()
            }
        }
    }


    func loadPhotos(limit: Int) {
        PhotoManager.requestAccess { element in
            if element {
                let fetched = PhotoManager.fetchPhotoAssets()
                DispatchQueue.main.async {
                    self.assets = Array(fetched.prefix(limit))
                    self.processEmbeddings(for: self.assets)
                }
            }
        }
    }
    
    private func processEmbeddings(for assets: [PHAsset]) {
        let group = DispatchGroup()
        for asset in assets {
            group.enter()
            PhotoManager.requestImage(asset: asset, targetSize: CGSize(width: 224, height: 224)) { image in
                guard let image = image else {
                    group.leave()
                    return
                }
                DispatchQueue.global().async {
                    self.extractor?.extractFeatures(from: image) { vector in
                        if let vector = vector {
                            Task { @MainActor in
                                self.embeddingResults[asset.localIdentifier] = vector
                            }
                        }
                        group.leave()
                    }
                }
            }
        }
        group.notify(queue: .main) {
            Task { @MainActor in
                let groups = self.groupSimilarPhotos(assets: self.assets, embeddings: self.embeddingResults)
                self.similarGroups = groups
            }
        }

    }
    
    func deleteSelectedPhotos() {
        let assetsToDelete = Array(selectedForDeletion)
        
        calculateTotalSize(of: assetsToDelete) { [weak self] totalSizeMB in
            guard let self = self else { return }
            let deletedCount = assetsToDelete.count

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.freedMemoryMB = totalSizeMB
                        self.deletedPhotoCount = deletedCount
                        self.selectedForDeletion.removeAll()
                        self.showSuccessScreen = true

                        let deletedIDs = Set(assetsToDelete.map { $0.localIdentifier })
                        self.assets.removeAll { deletedIDs.contains($0.localIdentifier) }
                        self.embeddingResults = self.embeddingResults.filter { !deletedIDs.contains($0.key) }

                        self.similarGroups = self.groupSimilarPhotos(
                            assets: self.assets,
                            embeddings: self.embeddingResults
                        )
                    } else {
                        print("Ошибка при удалении: \(String(describing: error))")
                    }
                }
            }
        }
    }

    
    func calculateTotalSize(of assets: [PHAsset], completion: @escaping (Double) -> Void) {
        var totalSize: Int64 = 0
        let imageManager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = true
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        DispatchQueue.global(qos: .userInitiated).async {
            for asset in assets {
                let resources = PHAssetResource.assetResources(for: asset)
                for resource in resources {
                    if let unsignedInt64 = resource.value(forKey: "fileSize") as? CLong {
                        totalSize += Int64(unsignedInt64)
                    }
                }
            }
            let sizeMB = Double(totalSize) / 1_048_576.0
            completion(sizeMB)
        }
    }
    func groupSimilarPhotos(assets: [PHAsset], embeddings: [String: [Double]], threshold: Double = 0.8) -> [SimilarGroup] {
        var groups: [[PHAsset]] = []
        var used = Set<String>()
        
        for i in 0..<assets.count {
            let assetA = assets[i]
            guard let embA = embeddings[assetA.localIdentifier], !used.contains(assetA.localIdentifier) else { continue }
            
            var group = [assetA]
            used.insert(assetA.localIdentifier)
            
            for j in (i + 1)..<assets.count {
                let assetB = assets[j]
                guard let embB = embeddings[assetB.localIdentifier], !used.contains(assetB.localIdentifier) else { continue }
                
                let similarity = cosineSimilarity(embA, embB)
                if similarity >= threshold {
                    group.append(assetB)
                    used.insert(assetB.localIdentifier)
                }
            }
            
            if group.count > 1 {
                groups.append(group)
//                print("\(group.map { $0.localIdentifier })")
            }
        }
        
        return groups.map { SimilarGroup(assets: $0) }
    }
    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dot = zip(a, b).map(*).reduce(0, +)
        let normA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        return dot / (normA * normB + 1e-10)
    }

    func findSimilarPairs(from embeddings: [String: [Double]], threshold: Double = 0.95) -> [(String, String, Double)] {
        var pairs: [(String, String, Double)] = []
        let keys = Array(embeddings.keys)
        
        for i in 0..<keys.count {
            for j in (i + 1)..<keys.count {
                let idA = keys[i]
                let idB = keys[j]
                if let vectorA = embeddings[idA], let vectorB = embeddings[idB] {
                    let similarity = cosineSimilarity(vectorA, vectorB)
                    if similarity >= threshold {
                        pairs.append((idA, idB, similarity))
                    }
                }
            }
        }
        
        return pairs
    }

}

