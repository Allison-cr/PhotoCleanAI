import SwiftUI
import Photos
import CoreML

#Preview {
    MainView()
}

struct MainView: View {
    /// ml model logic and other actions
    @StateObject private var viewModel = PhotoSimilarityViewModel()
    /// image storage
    @StateObject private var photoCacheModel = PhotoThumbnailViewModel()
    @State private var showDeleteConfirmation: Bool = false
    @Namespace private var imageNamespace
    var body: some View {
        NavigationView {
            ZStack {
                Color.accentColor
                    .ignoresSafeArea()
                if viewModel.similarGroups.isEmpty {
                    StubView()
                } else {
                    VStack {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 0) {
                                Text("Similar")
                                    .font(.system(size: 28, weight: .bold))
                                    .padding(.top, 58)
                                Spacer()
                            }
                            HStack(spacing: 0) {
                                Text("\(viewModel.assets.count) photos")
                                if !viewModel.selectedForDeletion.isEmpty {
                                    Text("• \(viewModel.selectedForDeletion.count) selected")
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 15)
                        .foregroundStyle(.white)
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.similarGroups) { group in
                                    GroupView(
                                        group: group,
                                        selectedImage: $viewModel.selectedImage,
                                        selectedImageID: $viewModel.selectedImageID,
                                        selectedForDeletion: $viewModel.selectedForDeletion,
                                        imageNamespace: imageNamespace,
                                        viewModel: photoCacheModel
                                    )
                                }
                            }
                            .padding(.top, 8)
                        }
                        .ignoresSafeArea()
                        .background(.white)
                        .cornerRadius(20)
                    }
                    .ignoresSafeArea(edges: .bottom)
                    
                }
                if let selectedImage = viewModel.selectedImage, let id = viewModel.selectedImageID {
                    FullScreenImageView(
                        image: selectedImage,
                        id: id,
                        namespace: imageNamespace
                    ) {
                        self.viewModel.selectedImage = nil
                        self.viewModel.selectedImageID = nil
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
                
                if viewModel.showSuccessScreen  {
                    CongratulationsView(
                        deletedCount: $viewModel.deletedPhotoCount,
                        freedMemoryMB: $viewModel.freedMemoryMB,
                        showSuccessScreen: $viewModel.showSuccessScreen
                    )
                    .transition(.opacity)
                    .zIndex(1)
                }
                
                if !viewModel.selectedForDeletion.isEmpty {
                    VStack {
                        Spacer()
                        Button {
                            viewModel.deleteSelectedPhotos()
                            
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "trash")
                                Text("Delete \(viewModel.selectedForDeletion.count) similars")
                                Spacer()
                            }
                        }
                        .padding(.vertical, 19)
                        .foregroundColor(.white)
                        .background(Color.main)
                        .font(.system(size: 20, weight: .medium))
                        .cornerRadius(24)
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .onAppear {
            viewModel.requestPhotoAccessRecursively()
        }
        .alert(isPresented: $viewModel.showPermissionAlert) {
            Alert(
                title: Text("Разрешение на доступ"),
                message: Text("Для работы с приложением нужно предоставить доступ к вашим фотографиям. Перейдите в настройки, чтобы разрешить доступ."),
                primaryButton: .default(Text("Перейти в настройки"), action: {
                    if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(appSettings)
                    }
                }),
                secondaryButton: .cancel(Text("Попробовать снова"), action: {
                    viewModel.showPermissionAlert = false
                      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                          viewModel.requestPhotoAccessRecursively()
                      }
                  })
            )
        }
    }
}

struct GroupView: View {
    let group: SimilarGroup
    @Binding var selectedImage: UIImage?
    @Binding var selectedImageID: String?
    @Binding var selectedForDeletion: Set<PHAsset>
    let imageNamespace: Namespace.ID
    @ObservedObject var viewModel: PhotoThumbnailViewModel
    private var anySelected: Bool {
        group.assets.contains { selectedForDeletion.contains($0) }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text("\(group.assets.count) Similar")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.black)
                Spacer()
                Button {
                    toggleSelectionForGroup()
                } label: {
                    Text(anySelected ? "Deselect all" : "Select all")
                }
            }
            .padding(.horizontal, 17)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(group.assets, id: \.localIdentifier) { asset in
                        PhotoThumbnail(
                            asset: asset,
                            isSelected: selectedForDeletion.contains(asset),
                            onToggle: {
                                if selectedForDeletion.contains(asset) {
                                    selectedForDeletion.remove(asset)
                                } else {
                                    selectedForDeletion.insert(asset)
                                }
                            }, namespace: imageNamespace,
                            viewModel: viewModel,
                            onImageTap: { image, id in
                                withAnimation(.spring()) {
                                    selectedImage = image
                                    selectedImageID = id
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    private func toggleSelectionForGroup() {
        if anySelected {
            for asset in group.assets {
                selectedForDeletion.remove(asset)
            }
        } else {
            for asset in group.assets {
                selectedForDeletion.insert(asset)
            }
        }
    }
}
