//
//  AssetThumbView.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI
import Photos

struct AssetThumbView: View {
    
    // MARK: - Constants
    private struct Constants {
        static let thumbHeight: CGFloat = 110
        static let cornerRadius: CGFloat = 10
        static let placeholderColor: Color = Color.secondary.opacity(0.1)
        static let thumbSize: CGSize = CGSize(width: 300, height: 300)
    }
    
    // MARK: - Properties
    let asset: PHAsset
    @ObservedObject var library: PhotoLibrary
    @State private var image: UIImage? = nil
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(height: Constants.thumbHeight)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Constants.placeholderColor)
                    .frame(height: Constants.thumbHeight)
                ProgressView()
            }
        }
        .cornerRadius(Constants.cornerRadius)
        .onAppear { Task { await loadImage() } }
    }
    
    // MARK: - Private functions
    private func loadImage() async {
        self.image = await library.requestThumbnail(for: asset, target: Constants.thumbSize)
    }
}
