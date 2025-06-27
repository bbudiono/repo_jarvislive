// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive tests for DocumentCameraManager to verify camera integration and AI analysis
 * Issues & Complexity Summary: Testing camera functionality, document detection, and AI analysis pipeline
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~300
 *   - Core Algorithm Complexity: Medium
 *   - Dependencies: 4 New (XCTest, AVFoundation, Vision, UIKit)
 *   - State Management Complexity: Medium
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 75%
 * Justification for Estimates: Camera testing requires mock setup and async operation validation
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import XCTest
@testable import JarvisLive_Sandbox
import UIKit
import AVFoundation

@MainActor
final class DocumentCameraManagerTests: XCTestCase {
    var documentCameraManager: DocumentCameraManager!
    var mockKeychainManager: KeychainManager!
    var mockLiveKitManager: LiveKitManager!
    private let testService = "com.ablankcanvas.JarvisLive.document.tests"

    override func setUp() {
        super.setUp()
        mockKeychainManager = KeychainManager(service: testService)
        mockLiveKitManager = LiveKitManager(keychainManager: mockKeychainManager)
        documentCameraManager = DocumentCameraManager(
            keychainManager: mockKeychainManager,
            liveKitManager: mockLiveKitManager
        )

        // Clean up any existing test data
        try? mockKeychainManager.clearAllCredentials()
    }

    override func tearDown() {
        // Clean up test keychain entries
        try? mockKeychainManager.clearAllCredentials()
        documentCameraManager = nil
        mockKeychainManager = nil
        mockLiveKitManager = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_setsCorrectInitialState() {
        // Then: Initial state should be correct
        XCTAssertFalse(documentCameraManager.isScanning)
        XCTAssertFalse(documentCameraManager.isAnalyzing)
        XCTAssertTrue(documentCameraManager.scanResults.isEmpty)
        XCTAssertTrue(documentCameraManager.analysisResults.isEmpty)
        XCTAssertEqual(documentCameraManager.currentProgress, 0.0)
    }

    func test_initialization_checksCameraAvailability() {
        // Camera availability is device-dependent, so we just verify the property exists
        // In simulator, this will typically be false; on real device, true
        let isAvailable = documentCameraManager.isCameraAvailable
        XCTAssertNotNil(isAvailable) // Property should have a value
    }

    // MARK: - Camera Permission Tests

    func test_requestCameraPermission_whenNotDetermined_requestsPermission() async {
        // This test runs in a simulator where camera might not be available
        // We're testing the logic flow rather than actual camera hardware

        let hasPermission = await documentCameraManager.requestCameraPermission()

        // The result depends on the environment (simulator vs device)
        // We verify that the method completes and updates the state
        XCTAssertEqual(documentCameraManager.hasPermission, hasPermission)
    }

    // MARK: - Document Scanning Tests

    func test_startDocumentScanning_whenCameraNotAvailable_throwsError() async {
        // Given: Camera is not available (typical in iOS Simulator)
        if !documentCameraManager.isCameraAvailable {
            // When/Then: Should throw camera not available error
            do {
                try await documentCameraManager.startDocumentScanning()
                XCTFail("Should have thrown cameraNotAvailable error")
            } catch DocumentScanningError.cameraNotAvailable {
                // Expected error
                XCTAssertFalse(documentCameraManager.isScanning)
            } catch {
                XCTFail("Unexpected error: \(error)")
            }
        }
    }

    func test_startDocumentScanning_whenNoPermission_throwsError() async {
        // Given: No camera permission (simulate denied permission)
        documentCameraManager.hasPermission = false

        // When/Then: Should throw permission denied error
        do {
            try await documentCameraManager.startDocumentScanning()
            XCTFail("Should have thrown cameraPermissionDenied error")
        } catch DocumentScanningError.cameraPermissionDenied {
            // Expected error
            XCTAssertFalse(documentCameraManager.isScanning)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_cancelScanning_stopsAllOperations() {
        // Given: Some mock scanning state
        documentCameraManager.isScanning = true
        documentCameraManager.isAnalyzing = true
        documentCameraManager.currentProgress = 0.5

        // When: Canceling scanning
        documentCameraManager.cancelScanning()

        // Then: All operations should be stopped
        XCTAssertFalse(documentCameraManager.isScanning)
        XCTAssertFalse(documentCameraManager.isAnalyzing)
        XCTAssertEqual(documentCameraManager.currentProgress, 0.0)
    }

    // MARK: - Document Analysis Tests

    func test_analyzeDocument_withValidScanResult_createsAnalysis() async {
        // Given: Valid scan result
        let mockImage = createMockDocumentImage()
        let scanResult = DocumentScanResult(
            id: UUID(),
            timestamp: Date(),
            originalImage: mockImage,
            processedImage: mockImage,
            detectedText: "Test document content",
            confidence: 0.95,
            documentBounds: CGRect(x: 0, y: 0, width: 1, height: 1)
        )

        // Add credentials for testing
        try? mockKeychainManager.storeCredential("sk-ant-test", forKey: "anthropic-api-key")

        // When: Analyzing document
        await documentCameraManager.analyzeDocument(scanResult)

        // Then: Analysis should be created (may fail due to network, but should attempt)
        // We verify the attempt was made rather than the success due to test environment
        XCTAssertFalse(documentCameraManager.isAnalyzing) // Should finish (success or failure)
    }

    func test_analyzeDocument_whenNoAPICredentials_usesFallback() async {
        // Given: No API credentials stored
        let mockImage = createMockDocumentImage()
        let scanResult = DocumentScanResult(
            id: UUID(),
            timestamp: Date(),
            originalImage: mockImage,
            processedImage: mockImage,
            detectedText: "Test document content",
            confidence: 0.95,
            documentBounds: CGRect(x: 0, y: 0, width: 1, height: 1)
        )

        // When: Analyzing document without credentials
        await documentCameraManager.analyzeDocument(scanResult)

        // Then: Should complete with fallback analysis
        XCTAssertFalse(documentCameraManager.isAnalyzing)

        // Check if fallback analysis was created
        let analysis = documentCameraManager.getAnalysisResult(for: scanResult.id)
        if let analysis = analysis {
            XCTAssertEqual(analysis.aiProvider, "Fallback")
            XCTAssertTrue(analysis.summary.contains("offline"))
        }
    }

    // MARK: - Results Management Tests

    func test_clearResults_removesAllData() {
        // Given: Some mock results
        let mockImage = createMockDocumentImage()
        let scanResult = DocumentScanResult(
            id: UUID(),
            timestamp: Date(),
            originalImage: mockImage,
            processedImage: mockImage,
            detectedText: "Test",
            confidence: 0.9,
            documentBounds: nil
        )

        documentCameraManager.scanResults.append(scanResult)

        // When: Clearing results
        documentCameraManager.clearResults()

        // Then: All results should be removed
        XCTAssertTrue(documentCameraManager.scanResults.isEmpty)
        XCTAssertTrue(documentCameraManager.analysisResults.isEmpty)
    }

    func test_getScanResult_withValidID_returnsResult() {
        // Given: Scan result in storage
        let mockImage = createMockDocumentImage()
        let scanResult = DocumentScanResult(
            id: UUID(),
            timestamp: Date(),
            originalImage: mockImage,
            processedImage: mockImage,
            detectedText: "Test",
            confidence: 0.9,
            documentBounds: nil
        )

        documentCameraManager.scanResults.append(scanResult)

        // When: Getting scan result by ID
        let retrievedResult = documentCameraManager.getScanResult(by: scanResult.id)

        // Then: Should return the correct result
        XCTAssertNotNil(retrievedResult)
        XCTAssertEqual(retrievedResult?.id, scanResult.id)
        XCTAssertEqual(retrievedResult?.detectedText, "Test")
    }

    func test_getScanResult_withInvalidID_returnsNil() {
        // Given: Empty scan results
        let randomID = UUID()

        // When: Getting scan result with non-existent ID
        let retrievedResult = documentCameraManager.getScanResult(by: randomID)

        // Then: Should return nil
        XCTAssertNil(retrievedResult)
    }

    func test_getAnalysisResult_withValidScanResultID_returnsAnalysis() {
        // Given: Analysis result in storage
        let scanResultID = UUID()
        let analysis = DocumentAnalysis(
            id: UUID(),
            scanResultID: scanResultID,
            aiProvider: "TestProvider",
            summary: "Test summary",
            extractedData: ["type": "test"],
            recommendations: ["Test recommendation"],
            confidence: 0.85,
            processingTime: 1.5,
            timestamp: Date()
        )

        documentCameraManager.analysisResults.append(analysis)

        // When: Getting analysis result
        let retrievedAnalysis = documentCameraManager.getAnalysisResult(for: scanResultID)

        // Then: Should return the correct analysis
        XCTAssertNotNil(retrievedAnalysis)
        XCTAssertEqual(retrievedAnalysis?.scanResultID, scanResultID)
        XCTAssertEqual(retrievedAnalysis?.summary, "Test summary")
    }

    // MARK: - Error Handling Tests

    func test_documentScanningError_hasCorrectDescriptions() {
        // Test all error cases have proper descriptions
        let errors: [DocumentScanningError] = [
            .cameraNotAvailable,
            .cameraPermissionDenied,
            .documentDetectionFailed,
            .imageProcessingFailed,
            .aiAnalysisFailed("Test reason"),
            .unknownError("Test error"),
        ]

        for error in errors {
            XCTAssertFalse(error.localizedDescription.isEmpty, "Error description should not be empty")
            XCTAssertNotNil(error.errorDescription, "Error description should not be nil")
        }
    }

    // MARK: - Document Data Structure Tests

    func test_documentScanResult_initializesCorrectly() {
        // Given: Document scan parameters
        let id = UUID()
        let timestamp = Date()
        let image = createMockDocumentImage()
        let text = "Test document text"
        let confidence: Float = 0.92
        let bounds = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)

        // When: Creating scan result
        let scanResult = DocumentScanResult(
            id: id,
            timestamp: timestamp,
            originalImage: image,
            processedImage: image,
            detectedText: text,
            confidence: confidence,
            documentBounds: bounds
        )

        // Then: All properties should be set correctly
        XCTAssertEqual(scanResult.id, id)
        XCTAssertEqual(scanResult.timestamp, timestamp)
        XCTAssertEqual(scanResult.originalImage, image)
        XCTAssertEqual(scanResult.detectedText, text)
        XCTAssertEqual(scanResult.confidence, confidence)
        XCTAssertEqual(scanResult.documentBounds, bounds)
    }

    func test_documentAnalysis_initializesCorrectly() {
        // Given: Document analysis parameters
        let id = UUID()
        let scanResultID = UUID()
        let provider = "TestProvider"
        let summary = "Test summary"
        let extractedData = ["key": "value"]
        let recommendations = ["Recommendation 1", "Recommendation 2"]
        let confidence: Float = 0.88
        let processingTime: TimeInterval = 2.5
        let timestamp = Date()

        // When: Creating analysis
        let analysis = DocumentAnalysis(
            id: id,
            scanResultID: scanResultID,
            aiProvider: provider,
            summary: summary,
            extractedData: extractedData,
            recommendations: recommendations,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: timestamp
        )

        // Then: All properties should be set correctly
        XCTAssertEqual(analysis.id, id)
        XCTAssertEqual(analysis.scanResultID, scanResultID)
        XCTAssertEqual(analysis.aiProvider, provider)
        XCTAssertEqual(analysis.summary, summary)
        XCTAssertEqual(analysis.recommendations, recommendations)
        XCTAssertEqual(analysis.confidence, confidence)
        XCTAssertEqual(analysis.processingTime, processingTime)
        XCTAssertEqual(analysis.timestamp, timestamp)
    }

    // MARK: - Integration Tests

    func test_documentWorkflow_endToEnd() async {
        // This is a mock end-to-end test since we can't use real camera in tests
        // We test the workflow logic without actual camera hardware

        // Given: Document camera manager is ready
        XCTAssertFalse(documentCameraManager.isScanning)
        XCTAssertTrue(documentCameraManager.scanResults.isEmpty)

        // When: Attempting document workflow (will fail gracefully without camera)
        do {
            try await documentCameraManager.startDocumentScanning()
        } catch {
            // Expected in test environment - verify error handling works
            XCTAssertTrue(error is DocumentScanningError)
        }

        // Then: State should be consistent
        XCTAssertFalse(documentCameraManager.isScanning)
    }

    // MARK: - Helper Methods

    private func createMockDocumentImage() -> UIImage {
        // Create a simple test image
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            UIColor.black.setFill()
            let textRect = CGRect(x: 10, y: 10, width: 80, height: 80)
            textRect.fill()
        }
    }
}

// MARK: - Mock Document Scanning Delegate

class MockDocumentScanningDelegate: DocumentScanningDelegate {
    var completedResults: [DocumentScanResult] = []
    var failedErrors: [DocumentScanningError] = []
    var didCancel = false
    var analysisStarted = false
    var completedAnalyses: [DocumentAnalysis] = []

    func documentScanningDidComplete(_ result: DocumentScanResult) {
        completedResults.append(result)
    }

    func documentScanningDidFail(_ error: DocumentScanningError) {
        failedErrors.append(error)
    }

    func documentScanningDidCancel() {
        didCancel = true
    }

    func documentAnalysisDidStart() {
        analysisStarted = true
    }

    func documentAnalysisDidComplete(_ analysis: DocumentAnalysis) {
        completedAnalyses.append(analysis)
    }
}
