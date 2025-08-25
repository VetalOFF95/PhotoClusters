//
//  SettingsView.swift
//  PhotoClusters
//
//  Created by Vitalii Korol on 25/08/2025.
//

import SwiftUI

struct SimpleSettingsView: View {
    
    // MARK: - Constants
    private struct Constants {
        // Texts
        static let similarityThresholdTitle = "Similarity Threshold"
        static let photoLimitTitle = "Photo Limit"
        static let applyButtonTitle = "Apply & Recluster"
        static let thresholdRange: ClosedRange<Double> = 0.5...5
        static let thresholdStep: Double = 0.01
        static let maxItemsRange: ClosedRange<Int> = 50...2000
        static let maxItemsStep: Int = 50
        static let verticalSpacing: CGFloat = 20
        static let padding: CGFloat = 16
        static let fontHeadline: Font = .headline
        static let fontSubheadline: Font = .subheadline
    }
    
    // MARK: - Bindings
    @Binding var threshold: Float
    @Binding var maxItems: Int
    
    let applySettings: () -> Void
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.verticalSpacing) {
            
            // Similarity Threshold
            VStack(alignment: .leading) {
                Text(Constants.similarityThresholdTitle)
                    .font(Constants.fontHeadline)
                Slider(
                    value: Binding(
                        get: { Double(threshold) },
                        set: { threshold = Float($0) }
                    ),
                    in: Constants.thresholdRange,
                    step: Constants.thresholdStep
                )
                Text(String(format: "%.2f", threshold))
                    .font(Constants.fontSubheadline)
            }
            
            // Photo Limit
            VStack(alignment: .leading) {
                Text(Constants.photoLimitTitle)
                    .font(Constants.fontHeadline)
                Stepper(
                    "\(maxItems)",
                    value: $maxItems,
                    in: Constants.maxItemsRange,
                    step: Constants.maxItemsStep
                )
            }
            
            // Apply Button
            Button(Constants.applyButtonTitle) {
                applySettings()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(Constants.padding)
    }
}
