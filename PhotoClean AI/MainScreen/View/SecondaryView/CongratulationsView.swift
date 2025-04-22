//
//  CongratulationsView.swift
//  PhotoClean AI
//
//  Created by Alexander Suprun on 21.04.2025.
//

import SwiftUI

struct CongratulationsView: View {
    @Binding var deletedCount: Int
    @Binding var freedMemoryMB: Double
    @Binding var showSuccessScreen: Bool
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            VStack(alignment: .center,spacing: 0) {
                Image(.congr)
                Text("Congratulations!")
                    .foregroundStyle(.black)
                    .font(.system(size: 36, weight: .bold))
                VStack(alignment: .leading, spacing: 52) {
                    HStack(spacing: 14) {
                        Image(.star)
                        Text("You have deleted ")
                            .foregroundColor(.black)
                        + Text("\(deletedCount) Photos")
                            .foregroundColor(.accentColor)
                            .fontWeight(.bold)
                        + Text(" (\(String(format: "%.1f", freedMemoryMB)) MB)")
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 63)
                    
                    HStack(spacing: 14) {
                        Image(.time)
                        Text("Saved ")
                            .foregroundColor(.black)
                        +
                        Text("\(deletedCount) Minutes")
                            .foregroundColor(.accentColor)
                            .fontWeight(.bold)
                        +
                        Text(" using Cleanup")
                            .foregroundColor(.black)
                    }
                    .padding(.horizontal, 72)
                    
                }
                .font(.system(size: 20))
                .padding(.top, 47)
                
                Text("Review all your videos. Sort them by size or date. See the ones that occupy the most space.")
                    .padding(.horizontal, 24)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.text)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 51)
                    .padding(.top, 36)
                
                Button {
                    withAnimation {
                        showSuccessScreen = false
                    }
                } label: {
                    Text("Great")
                        .buttonModifier()
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
