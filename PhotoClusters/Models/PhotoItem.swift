//
//  PhotoItem.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import Photos

struct PhotoItem: Identifiable, Hashable {
    let id: String 
    let asset: PHAsset
}
