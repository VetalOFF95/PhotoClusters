//
//  ClusterTile.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI

struct ClusterTile: View {
    
    // MARK: - Constants
    private struct Constants {
        static let tileHeight: CGFloat = 110
        static let cornerRadius: CGFloat = 12
        static let countFont: Font = .caption2
        static let countPadding: CGFloat = 6
        static let countBackgroundColor: Color = Color.black.opacity(0.6)
        static let countForegroundColor: Color = .white
        static let placeholderColor: Color = Color.secondary.opacity(0.1)
        static let thumbSize: CGSize = CGSize(width: 300, height: 300)
    }
    
    // MARK: - Properties
    let cluster: PhotoCluster
    @ObservedObject var library: PhotoLibrary
    @State private var thumb: UIImage? = nil
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if let thumb = thumb {
                Image(uiImage: thumb)
                    .resizable()
                    .scaledToFill()
                    .frame(height: Constants.tileHeight)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Constants.placeholderColor)
                    .frame(height: Constants.tileHeight)
                ProgressView()
            }
            
            // Count Badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(cluster.items.count)")
                        .font(Constants.countFont)
                        .padding(Constants.countPadding)
                        .background(Constants.countBackgroundColor)
                        .foregroundColor(Constants.countForegroundColor)
                        .clipShape(Capsule())
                        .padding(Constants.countPadding)
                }
            }
        }
        .cornerRadius(Constants.cornerRadius)
        .onAppear {
            Task {
                await loadThumb()
            }
        }
    }
    
    // MARK: - Private functions
    private func loadThumb() async {
        guard let first = cluster.items.first else { return }
        self.thumb = await library.requestThumbnail(
            for: first.asset,
            target: Constants.thumbSize
        )
    }
}
