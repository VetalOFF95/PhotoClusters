//
//  PhotoClusterer.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI
import Vision

@MainActor
final class PhotoClusterer: ObservableObject {

    @Published var clusters: [PhotoCluster] = []
    @Published var isProcessing = false
    @Published var progress: Double = 0
    
    private let library: PhotoLibrary

    init(library: PhotoLibrary) {
        self.library = library
    }

    // MARK: - Public funcs
    public func clusterCurrentLibrary(threshold: Float, maxItems: Int? = nil) async {
        guard !isProcessing else {
            return
        }

        resetState()

        let items = Array(library.allPhotoItems.prefix(maxItems ?? Int.max))

        do {
            let prints = try await computeFeaturePrints(for: items)
            let graph = buildGraph(prints: prints, threshold: threshold)

            let groups = connectedComponents(
                graph: graph,
                itemsByID: Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
            )

            clusters = groups.map { PhotoCluster(items: $0) }
            isProcessing = false
            progress = 1.0
        } catch {
            isProcessing = false
            print("Clustering error: \(error)")
        }
    }
    
    // MARK: - Private funcs
    private func resetState() {
        isProcessing = true
        progress = 0
        clusters = []
    }

    private func computeFeaturePrints(for items: [PhotoItem]) async throws -> [FeaturePrint] {
        var result: [FeaturePrint] = []
        result.reserveCapacity(items.count)

        let request = VNGenerateImageFeaturePrintRequest()

        for (idx, item) in items.enumerated() {
            if let cg = await library.requestCGImage(for: item.asset) {
                let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                do {
                    try handler.perform([request])

                    if let obs = request.results?.first as? VNFeaturePrintObservation {
                        result.append(FeaturePrint(id: item.id, observation: obs))
                    } else {
                        throw ClusteringError.failedFeaturePrint(item.id)
                    }
                } catch {
                    print("Vision error for asset \(item.id): \(error)")
                }
            }

            progress = Double(idx + 1) / Double(items.count) * 0.6
        }
        return result
    }

    private func buildGraph(prints: [FeaturePrint], threshold: Float) -> [String: Set<String>] {
        var adjacency: [String: Set<String>] = [:]
        
        for fp in prints {
            adjacency[fp.id] = []
        }

        let n = prints.count
        
        if n == 0 {
            return adjacency
        }

        for i in 0..<(n - 1) {
            for j in (i + 1)..<n {
                var distance: Float = .greatestFiniteMagnitude
                do {
                    try prints[i].observation.computeDistance(&distance, to: prints[j].observation)
                } catch { continue }

                if distance < threshold {
                    adjacency[prints[i].id, default: []].insert(prints[j].id)
                    adjacency[prints[j].id, default: []].insert(prints[i].id)
                }
            }

            let pairsDone = (i + 1) * (n - 1) - (i * (i + 1) / 2)
            let totalPairs = n * (n - 1) / 2
            progress = 0.6 + 0.4 * (Double(pairsDone) / Double(max(totalPairs, 1)))
        }
        return adjacency
    }

    private func connectedComponents(graph: [String: Set<String>], itemsByID: [String: PhotoItem]) -> [[PhotoItem]] {
        var visited: Set<String> = []
        var groups: [[PhotoItem]] = []

        for id in graph.keys {
            guard !visited.contains(id) else { continue }

            var stack: [String] = [id]
            var component: [PhotoItem] = []
            visited.insert(id)

            while let current = stack.popLast() {
                if let item = itemsByID[current] {
                    component.append(item)
                }
                for neighbor in graph[current] ?? [] {
                    if !visited.contains(neighbor) {
                        visited.insert(neighbor)
                        stack.append(neighbor)
                    }
                }
            }

            if !component.isEmpty {
                groups.append(component)
            }
        }

        groups = groups.filter { $0.count > 1 }
        groups.sort { $0.count > $1.count }

        return groups
    }
}
