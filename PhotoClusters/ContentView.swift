//
//  ContentView.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI
import Photos
import Vision

struct ContentView: View {
    
    // MARK: - Constants
    private struct Constants {
        static let navigationTitle = "Similar Photos"
        static let analyzingText = "Analyzing…"
        static let noClustersText = "No clusters yet"
        static let startClusteringText = "Start clusterization"
        static let galleryAccessTitle = "Gallery Access"
        static let galleryAccessDescription = "The app needs access to your photo library to group similar photos."
        static let grantAccessButton = "Grant Access"
        static let accessDeniedTitle = "Access Denied"
        static let accessDeniedDescription = "Go to Settings → Privacy → Photos and allow access for this app."
        static let gridSpacing: CGFloat = 8
        static let gridPadding: CGFloat = 8
        static let clusterVStackSpacing: CGFloat = 0
        static let noClustersVStackSpacing: CGFloat = 12
        static let requestAccessVStackSpacing: CGFloat = 16
        static let deniedVStackSpacing: CGFloat = 12
        static let settingsIcon = "slider.horizontal.3"
        static let startClusteringIcon = "sparkles"
        static let grantAccessIcon = "photo"
    }
    
    // MARK: - State
    @StateObject private var library: PhotoLibrary
    @StateObject private var clusterer: PhotoClusterer

    @State private var threshold: Float = 0.6
    @State private var maxItems: Int = 300
    @State private var showingSettings = false

    // MARK: - Init
    init() {
        let lib = PhotoLibrary()
        _library = StateObject(wrappedValue: lib)
        _clusterer = StateObject(wrappedValue: PhotoClusterer(library: lib))
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            Group {
                switch library.authorizationStatus {
                case .authorized, .limited:
                    content
                case .notDetermined:
                    requestAccessView
                default:
                    deniedView
                }
            }
            .navigationTitle(Constants.navigationTitle)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: Constants.settingsIcon)
                    }
                    .sheet(isPresented: $showingSettings) {
                        SimpleSettingsView(
                            threshold: $threshold,
                            maxItems: $maxItems,
                            applySettings: {
                                runClustering()
                                showingSettings = false
                            }
                        )
                        .presentationDetents([.medium, .large])
                    }
                }
            }
        }
        .task {
            if library.authorizationStatus == .authorized || library.authorizationStatus == .limited {
                library.loadAllPhotos()
                await clusterer.clusterCurrentLibrary(threshold: threshold, maxItems: maxItems)
            }
        }
    }

    // MARK: - Private Views
    private var content: some View {
        VStack(spacing: Constants.clusterVStackSpacing) {
            if clusterer.isProcessing {
                ProgressView(value: clusterer.progress) {
                    Text(Constants.analyzingText)
                }
                .padding()
            }

            if clusterer.clusters.isEmpty && !clusterer.isProcessing {
                VStack(spacing: Constants.noClustersVStackSpacing) {
                    Text(Constants.noClustersText)
                        .font(.headline)
                    Button(action: runClustering) {
                        Label(Constants.startClusteringText, systemImage: Constants.startClusteringIcon)
                    }
                }
                .padding()
            } else {
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: Constants.gridSpacing), count: 3),
                        spacing: Constants.gridSpacing
                    ) {
                        ForEach(clusterer.clusters) { cluster in
                            NavigationLink(destination: ClusterDetailView(cluster: cluster, library: library)) {
                                ClusterTile(cluster: cluster, library: library)
                            }
                        }
                    }
                    .padding(Constants.gridPadding)
                }
            }
        }
        .onAppear {
            library.loadAllPhotos(limit: maxItems)
        }
    }

    private var requestAccessView: some View {
        VStack(spacing: Constants.requestAccessVStackSpacing) {
            Text(Constants.galleryAccessTitle)
                .font(.title2).bold()
            Text(Constants.galleryAccessDescription)
                .multilineTextAlignment(.center)
            Button {
                Task {
                    await library.requestPermission()
                    if library.authorizationStatus == .authorized || library.authorizationStatus == .limited {
                        library.loadAllPhotos(limit: maxItems)
                        await clusterer.clusterCurrentLibrary(threshold: threshold, maxItems: maxItems)
                    }
                }
            } label: {
                Label(Constants.grantAccessButton, systemImage: Constants.grantAccessIcon)
            }
        }
        .padding()
    }

    private var deniedView: some View {
        VStack(spacing: Constants.deniedVStackSpacing) {
            Text(Constants.accessDeniedTitle)
                .font(.headline)
            Text(Constants.accessDeniedDescription)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Private funcs
    private func runClustering() {
        Task {
            library.loadAllPhotos(limit: maxItems)
            await clusterer.clusterCurrentLibrary(threshold: threshold, maxItems: maxItems)
        }
    }
}
