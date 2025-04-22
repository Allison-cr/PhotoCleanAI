//
//  FullScreenImage.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 22.04.2025.
//

import SwiftUI
import Photos

struct FullScreenImageView: View {
    var image: UIImage
    var id: String
    var namespace: Namespace.ID
    var onClose: () -> Void
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            VStack {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .matchedGeometryEffect(id: id, in: namespace)
                    .onTapGesture {
                        withAnimation(.spring()) {
                            onClose()
                        }
                    }
                Spacer()
            }
        }
    }
}
