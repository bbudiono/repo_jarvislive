// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Document scanner UI with real-time camera integration and AI analysis
 * Issues & Complexity Summary: SwiftUI camera integration with document detection and analysis UI
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400
 *   - Core Algorithm Complexity: Medium
 *   - Dependencies: 3 New (SwiftUI, VisionKit, AVFoundation)
 *   - State Management Complexity: Medium
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 70%
 * Problem Estimate (Inherent Problem Difficulty %): 75%
 * Initial Code Complexity Estimate %: 70%
 * Justification for Estimates: SwiftUI camera integration with state management
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import SwiftUI
import VisionKit
import AVFoundation

struct DocumentScannerView: View {
    @ObservedObject var documentCameraManager: DocumentCameraManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingPermissionAlert = false
    @State private var showingResultsSheet = false
    @State private var selectedScanResult: DocumentScanResult?
    @State private var showingAnalysisDetail = false
    @State private var selectedAnalysis: DocumentAnalysis?

    var body: some View {
        NavigationView {
            ZStack {
                // Background matching main app
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header
                    documentScannerHeader

                    // Camera Status
                    cameraStatusView

                    // Main Content
                    if documentCameraManager.isCameraAvailable && documentCameraManager.hasPermission {
                        if documentCameraManager.isScanning || documentCameraManager.isAnalyzing {
                            scanningProgressView
                        } else {
                            scanControlsView
                        }

                        // Scan Results
                        if !documentCameraManager.scanResults.isEmpty {
                            scanResultsView
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .onAppear {
                Task {
                    await documentCameraManager.requestCameraPermission()
                }
            }
            .alert("Camera Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("To scan documents, please enable camera access in Settings.")
            }
            .sheet(isPresented: $showingResultsSheet) {
                if let result = selectedScanResult {
                    DocumentResultDetailView(
                        scanResult: result,
                        analysis: documentCameraManager.getAnalysisResult(for: result.id),
                        onAnalyze: {
                            Task {
                                await documentCameraManager.analyzeDocument(result)
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Header

    private var documentScannerHeader: some View {
        VStack(spacing: 8) {
            HStack {
                Button("Cancel") {
                    documentCameraManager.cancelScanning()
                    dismiss()
                }
                .foregroundColor(.white)

                Spacer()

                Text("Document Scanner")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                Button("Clear") {
                    documentCameraManager.clearResults()
                }
                .foregroundColor(.white)
                .opacity(documentCameraManager.scanResults.isEmpty ? 0.5 : 1.0)
                .disabled(documentCameraManager.scanResults.isEmpty)
            }

            Text("Capture documents and get AI-powered insights")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .accessibilityIdentifier("DocumentScannerHeader")
    }

    // MARK: - Camera Status

    private var cameraStatusView: some View {
        VStack(spacing: 12) {
            if !documentCameraManager.isCameraAvailable {
                StatusCard(
                    icon: "camera.fill",
                    title: "Camera Not Available",
                    message: "This device does not support camera functionality",
                    color: .red
                )
            } else if !documentCameraManager.hasPermission {
                StatusCard(
                    icon: "camera.circle",
                    title: "Camera Permission Required",
                    message: "Please grant camera access to scan documents",
                    color: .orange,
                    action: {
                        Task {
                            let granted = await documentCameraManager.requestCameraPermission()
                            if !granted {
                                showingPermissionAlert = true
                            }
                        }
                    },
                    actionLabel: "Grant Permission"
                )
            } else {
                StatusCard(
                    icon: "checkmark.circle.fill",
                    title: "Camera Ready",
                    message: "Ready to scan documents",
                    color: .green
                )
            }
        }
    }

    // MARK: - Scanning Progress

    private var scanningProgressView: some View {
        VStack(spacing: 20) {
            // Progress indicator
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: CGFloat(documentCameraManager.currentProgress))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: documentCameraManager.currentProgress)

                if documentCameraManager.isScanning {
                    Image(systemName: "doc.viewfinder")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                } else if documentCameraManager.isAnalyzing {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.white)
                }
            }

            VStack(spacing: 8) {
                if documentCameraManager.isScanning {
                    Text("Scanning Document...")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Position document within the camera frame")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                } else if documentCameraManager.isAnalyzing {
                    Text("Analyzing with AI...")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Extracting insights and information")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
            }

            Button("Cancel") {
                documentCameraManager.cancelScanning()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.3))
            .foregroundColor(.white)
            .cornerRadius(25)
            .accessibilityIdentifier("CancelScanningButton")
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                )
        )
    }

    // MARK: - Scan Controls

    private var scanControlsView: some View {
        VStack(spacing: 16) {
            // Main scan button
            Button(action: {
                Task {
                    do {
                        try await documentCameraManager.startDocumentScanning()
                    } catch {
                        print("Scanning failed: \(error)")
                    }
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.title2)

                    Text("Scan Document")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(30)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .accessibilityIdentifier("ScanDocumentButton")
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.1), value: documentCameraManager.isScanning)

            // Feature highlights
            VStack(spacing: 8) {
                FeatureHighlight(
                    icon: "brain.head.profile",
                    title: "AI Analysis",
                    description: "Extract key information automatically"
                )

                FeatureHighlight(
                    icon: "text.viewfinder",
                    title: "Text Recognition",
                    description: "Convert documents to searchable text"
                )

                FeatureHighlight(
                    icon: "square.and.arrow.up",
                    title: "Smart Insights",
                    description: "Get recommendations and summaries"
                )
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Scan Results

    private var scanResultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("\(documentCameraManager.scanResults.count)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(documentCameraManager.scanResults.reversed().prefix(5), id: \.id) { result in
                        ScanResultThumbnail(
                            result: result,
                            analysis: documentCameraManager.getAnalysisResult(for: result.id)
                        ) {
                            selectedScanResult = result
                            showingResultsSheet = true
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .accessibilityIdentifier("ScanResultsView")
    }
}

// MARK: - Supporting Views

struct StatusCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color
    var action: (() -> Void)?
    var actionLabel: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)

            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }

            if let action = action, let actionLabel = actionLabel {
                Button(actionLabel, action: action)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(color.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.3))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        )
    }
}

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

struct ScanResultThumbnail: View {
    let result: DocumentScanResult
    let analysis: DocumentAnalysis?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Image thumbnail
                Image(uiImage: result.originalImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 100)
                    .clipped()
                    .cornerRadius(8)

                // Analysis status
                if let analysis = analysis {
                    VStack(spacing: 2) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)

                        Text("Analyzed")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: "clock.circle")
                            .font(.caption)
                            .foregroundColor(.orange)

                        Text("Pending")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Document Result Detail View

struct DocumentResultDetailView: View {
    let scanResult: DocumentScanResult
    let analysis: DocumentAnalysis?
    let onAnalyze: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Document Image
                    Image(uiImage: scanResult.originalImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 300)
                        .cornerRadius(12)
                        .shadow(radius: 5)

                    // Scan Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scan Details")
                            .font(.headline)
                            .foregroundColor(.primary)

                        DetailRow(label: "Scanned", value: DateFormatter.medium.string(from: scanResult.timestamp))
                        DetailRow(label: "Confidence", value: String(format: "%.1f%%", scanResult.confidence * 100))

                        if let detectedText = scanResult.detectedText, !detectedText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Detected Text")
                                    .font(.subheadline)
                                    .fontWeight(.medium)

                                Text(detectedText)
                                    .font(.caption)
                                    .padding()
                                    .background(Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)

                    // Analysis Results
                    if let analysis = analysis {
                        analysisResultsView(analysis)
                    } else {
                        analysisPlaceholderView
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Document Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func analysisResultsView(_ analysis: DocumentAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("AI Analysis")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(analysis.aiProvider)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(6)
            }

            if !analysis.summary.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Summary")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(analysis.summary)
                        .font(.body)
                }
            }

            if !analysis.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recommendations")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(analysis.recommendations, id: \.self) { recommendation in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)

                            Text(recommendation)
                                .font(.body)
                        }
                    }
                }
            }

            DetailRow(label: "Processing Time", value: String(format: "%.2fs", analysis.processingTime))
            DetailRow(label: "Confidence", value: String(format: "%.1f%%", analysis.confidence * 100))
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }

    private var analysisPlaceholderView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.blue.opacity(0.6))

            Text("Analysis Not Available")
                .font(.headline)
                .foregroundColor(.primary)

            Text("This document hasn't been analyzed yet. Tap the button below to start AI analysis.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Analyze with AI") {
                onAnalyze()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Extensions
// Note: DateFormatter.medium is defined in DocumentGenerationView.swift to avoid duplication

// MARK: - Preview

#Preview {
    DocumentScannerView(
        documentCameraManager: DocumentCameraManager(
            keychainManager: KeychainManager(service: "preview"),
            liveKitManager: LiveKitManager()
        )
    )
}
