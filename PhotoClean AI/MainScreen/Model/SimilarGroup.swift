import Photos

struct SimilarGroup: Identifiable, Equatable {
    let id = UUID()
    let assets: [PHAsset]
}
