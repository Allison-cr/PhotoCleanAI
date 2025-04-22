//
//  StubView.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 22.04.2025.
//

import SwiftUI

#Preview {
    StubView()
}

struct StubView: View {
    var body: some View {
        ZStack {
            Color.accentColor
                .ignoresSafeArea()
            VStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        Text("Similar")
                            .font(.system(size: 28, weight: .bold))
                            .padding(.top, 58)
                        Spacer()
                    }
                    HStack(spacing: 0) {
                        Color.gray.opacity(0.3)
                            .frame(width: 120, height: 20)
                            .cornerRadius(14)

                        Spacer()
                    }
                }
                .padding(.horizontal, 15)
                .foregroundStyle(.white)
                
                VStack(alignment: .leading, spacing: 16) {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 32) {
                                ForEach(0..<5) { _ in
                                    Color.gray.opacity(0.3)
                                        .frame(width: 100, height: 20)

                                    .padding(.leading, 16)
                                    .padding(.top, 16)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack {
                                            Color.gray.opacity(0.3)
                                                .frame(width: UIScreen.main.bounds.width * 0.46, height: 0.25 * UIScreen.main.bounds.height)
                                                .cornerRadius(14)

                                            Color.gray.opacity(0.3)
                                                .frame(width: UIScreen.main.bounds.width * 0.46, height: 0.25 * UIScreen.main.bounds.height)
                                                .cornerRadius(14)
                                                
                                        }
                                }
                            }
                        }
                        
                    }
                }
                .background(.white)
                .cornerRadius(24)
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}
