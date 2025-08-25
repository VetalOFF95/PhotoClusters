//
//  ClusterDetailView.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI

struct ClusterDetailView: View {
    
    // MARK: - Constants
    private struct Constants {
        static let gridSpacing: CGFloat = 6
        static let gridPadding: CGFloat = 6
        static let navigationTitleFormat = "Photos in Cluster: %d"
    }
    
    // MARK: - Properties
    let cluster: PhotoCluster
    @ObservedObject var library: PhotoLibrary
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.flexible(), spacing: Constants.gridSpacing),
                    count: 3
                ),
                spacing: Constants.gridSpacing
            ) {
                ForEach(cluster.items) { item in
                    AssetThumbView(asset: item.asset, library: library)
                }
            }
            .padding(Constants.gridPadding)
        }
        .navigationTitle(String(format: Constants.navigationTitleFormat, cluster.items.count))
    }
}
