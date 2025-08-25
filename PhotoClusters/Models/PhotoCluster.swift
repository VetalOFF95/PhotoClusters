//
//  PhotoCluster.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import Photos

struct PhotoCluster: Identifiable, Hashable {
    let id = UUID()
    let items: [PhotoItem]
}
