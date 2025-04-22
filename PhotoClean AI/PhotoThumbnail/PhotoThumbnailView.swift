//
//  PhotoThumbnail.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 22.04.2025.
//

import SwiftUI
import Photos

struct PhotoThumbnail: View {
    let asset: PHAsset
    @State private var image: UIImage?
    let isSelected: Bool
    let onToggle: () -> Void
    let namespace: Namespace.ID
    @ObservedObject var viewModel: PhotoThumbnailViewModel
    let onImageTap: (UIImage, String) -> Void
    
    var body: some View {
        ZStack {
            Image(uiImage: image ?? UIImage())
                .resizable()
                .scaledToFill()
                .matchedGeometryEffect(id: asset.localIdentifier, in: namespace)
                .frame(width: UIScreen.main.bounds.width * 0.46, height: 0.25 * UIScreen.main.bounds.height)
                .clipped()
                .contentShape(Rectangle())
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Rectangle()
                        .frame(width: 30, height: 30)
                        .overlay(
                            ZStack {
                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white, lineWidth: 3)
                                }
                            }
                        )
                        .foregroundStyle(isSelected ? Color.green : Color.clear)
                        .onTapGesture {
                            withAnimation {
                                onToggle()
                            }
                        }
                        .cornerRadius(12)
                    
                }
            }
            .padding(.trailing, 10)
            .padding(.bottom, 8)
        }
        .cornerRadius(14)
        .onTapGesture {
            if let image = image {
                onImageTap(image, asset.localIdentifier)
            }
        }
        .onAppear {
            viewModel.loadImage(for: asset) { loadedImage in
                image = loadedImage
            }
        }
    }
}

