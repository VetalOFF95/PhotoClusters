//
//  PhotoLibrary.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI
import Photos

final class PhotoLibrary: ObservableObject {
    
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var allPhotoItems: [PhotoItem] = []

    private let imageManager = PHCachingImageManager()

    init() {
        refreshAuthStatus()
    }

    // MARK: - Public funcs
    public func requestPermission() async {
        let status = await withCheckedContinuation { (continuation: CheckedContinuation<PHAuthorizationStatus, Never>) in
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                continuation.resume(returning: newStatus)
            }
        }
        
        self.authorizationStatus = status
    }

    public func loadAllPhotos(limit: Int? = nil) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        var items: [PhotoItem] = []
        let count = limit.map { min($0, assets.count) } ?? assets.count
        items.reserveCapacity(count)

        assets.enumerateObjects({ asset, idx, stop in
            if let limit = limit, idx >= limit { stop.pointee = true; return }
            items.append(PhotoItem(id: asset.localIdentifier, asset: asset))
        })

        DispatchQueue.main.async {
            self.allPhotoItems = items
        }
    }

    public func requestCGImage(for asset: PHAsset, target: CGSize = CGSize(width: 256, height: 256)) async -> CGImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(for: asset,
                                      targetSize: target,
                                      contentMode: .aspectFill,
                                      options: options) { image, _ in
                continuation.resume(returning: image?.cgImage)
            }
        }
    }

    public func requestThumbnail(for asset: PHAsset, target: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .fast
            options.isSynchronous = false
            options.isNetworkAccessAllowed = true

            imageManager.requestImage(for: asset,
                                      targetSize: target,
                                      contentMode: .aspectFill,
                                      options: options) { image, info in
                let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                if !isDegraded, let img = image {
                    continuation.resume(returning: img)
                }
            }
        }
    }
    
    // MARK: - Private funcs
    private func refreshAuthStatus() {
        authorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    }
}
