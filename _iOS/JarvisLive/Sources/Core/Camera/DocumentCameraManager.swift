// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Advanced document scanning with AI-powered analysis for Jarvis Live
 * Issues & Complexity Summary: Camera integration, document detection, AI analysis pipeline
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High
 *   - Dependencies: 4 New (AVFoundation, Vision, VisionKit, UIKit)
 *   - State Management Complexity: High
 *   - Novelty/Uncertainty Factor: Medium
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 80%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 88%
 * Justification for Estimates: Camera integration with document detection and AI analysis
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import Foundation
import AVFoundation
import Vision
import VisionKit
import UIKit
import Combine

// MARK: - Document Scanning Delegate

protocol DocumentScanningDelegate: AnyObject {
    func documentScanningDidComplete(_ result: DocumentScanResult)
    func documentScanningDidFail(_ error: DocumentScanningError)
    func documentScanningDidCancel()
    func documentAnalysisDidStart()
    func documentAnalysisDidComplete(_ analysis: DocumentAnalysis)
}

// MARK: - Document Scan Result

struct DocumentScanResult {
    let id: UUID
    let timestamp: Date
    let originalImage: UIImage
    let processedImage: UIImage?
    let detectedText: String?
    let confidence: Float
    let documentBounds: CGRect?
}

// MARK: - Document Analysis

struct DocumentAnalysis {
    let id: UUID
    let scanResultID: UUID
    let aiProvider: String
    let summary: String
    let extractedData: [String: Any]
    let recommendations: [String]
    let confidence: Float
    let processingTime: TimeInterval
    let timestamp: Date
}

// MARK: - Document Scanning Error

enum DocumentScanningError: Error, LocalizedError {
    case cameraNotAvailable
    case cameraPermissionDenied
    case documentDetectionFailed
    case imageProcessingFailed
    case aiAnalysisFailed(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available on this device"
        case .cameraPermissionDenied:
            return "Camera permission is required for document scanning"
        case .documentDetectionFailed:
            return "Could not detect document in image"
        case .imageProcessingFailed:
            return "Failed to process captured image"
        case .aiAnalysisFailed(let reason):
            return "AI analysis failed: \(reason)"
        case .unknownError(let reason):
            return "Unknown error: \(reason)"
        }
    }
}

// MARK: - Document Camera Manager

@MainActor
final class DocumentCameraManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isScanning = false
    @Published private(set) var isCameraAvailable = false
    @Published private(set) var hasPermission = false
    @Published private(set) var scanResults: [DocumentScanResult] = []
    @Published private(set) var analysisResults: [DocumentAnalysis] = []
    @Published private(set) var isAnalyzing = false
    @Published private(set) var currentProgress: Float = 0.0

    // MARK: - Dependencies

    private let keychainManager: KeychainManager
    private let liveKitManager: LiveKitManager

    // MARK: - Private Properties

    private var currentScanTask: Task<Void, Never>?
    private var currentAnalysisTask: Task<Void, Never>?
    private let urlSession = URLSession.shared

    weak var delegate: DocumentScanningDelegate?

    // MARK: - Initialization

    init(keychainManager: KeychainManager, liveKitManager: LiveKitManager) {
        self.keychainManager = keychainManager
        self.liveKitManager = liveKitManager
        super.init()

        checkCameraAvailability()
        checkCameraPermission()
    }

    // MARK: - Public Methods

    func requestCameraPermission() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            hasPermission = true
            return true

        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            hasPermission = granted
            return granted

        case .denied, .restricted:
            hasPermission = false
            return false

        @unknown default:
            hasPermission = false
            return false
        }
    }

    func startDocumentScanning() async throws {
        guard isCameraAvailable else {
            throw DocumentScanningError.cameraNotAvailable
        }

        if !hasPermission {
            let permission = await requestCameraPermission()
            guard permission else {
                throw DocumentScanningError.cameraPermissionDenied
            }
        }

        guard !isScanning else { return }

        isScanning = true
        currentProgress = 0.0

        // Cancel any existing scan task
        currentScanTask?.cancel()

        currentScanTask = Task {
            do {
                let scanResult = try await performDocumentScan()
                await MainActor.run {
                    self.scanResults.append(scanResult)
                    self.delegate?.documentScanningDidComplete(scanResult)
                    self.isScanning = false

                    // Start AI analysis automatically
                    Task {
                        await self.analyzeDocument(scanResult)
                    }
                }
            } catch {
                await MainActor.run {
                    self.isScanning = false
                    self.delegate?.documentScanningDidFail(error as? DocumentScanningError ?? .unknownError(error.localizedDescription))
                }
            }
        }
    }

    func analyzeDocument(_ scanResult: DocumentScanResult) async {
        guard !isAnalyzing else { return }

        isAnalyzing = true
        currentProgress = 0.0
        delegate?.documentAnalysisDidStart()

        // Cancel any existing analysis task
        currentAnalysisTask?.cancel()

        currentAnalysisTask = Task {
            do {
                let analysis = try await performAIAnalysis(scanResult)
                await MainActor.run {
                    self.analysisResults.append(analysis)
                    self.delegate?.documentAnalysisDidComplete(analysis)
                    self.isAnalyzing = false
                    self.currentProgress = 1.0
                }
            } catch {
                await MainActor.run {
                    self.isAnalyzing = false
                    self.currentProgress = 0.0
                    self.delegate?.documentScanningDidFail(.aiAnalysisFailed(error.localizedDescription))
                }
            }
        }
    }

    func cancelScanning() {
        currentScanTask?.cancel()
        currentAnalysisTask?.cancel()
        isScanning = false
        isAnalyzing = false
        currentProgress = 0.0
        delegate?.documentScanningDidCancel()
    }

    func clearResults() {
        scanResults.removeAll()
        analysisResults.removeAll()
    }

    func getScanResult(by id: UUID) -> DocumentScanResult? {
        return scanResults.first { $0.id == id }
    }

    func getAnalysisResult(for scanResultID: UUID) -> DocumentAnalysis? {
        return analysisResults.first { $0.scanResultID == scanResultID }
    }

    // MARK: - Private Methods

    private func checkCameraAvailability() {
        isCameraAvailable = UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        hasPermission = (status == .authorized)
    }

    private func performDocumentScan() async throws -> DocumentScanResult {
        // Simulate camera scanning process with VNDocumentCameraViewController
        // In a real implementation, this would integrate with VisionKit

        await updateProgress(0.3)

        // Simulate document detection and capture
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        await updateProgress(0.6)

        // Create mock scan result for development
        // In production, this would be real camera captured image
        let mockImage = createMockDocumentImage()

        await updateProgress(0.8)

        // Perform text recognition using Vision framework
        let detectedText = try await performTextRecognition(on: mockImage)

        await updateProgress(1.0)

        let scanResult = DocumentScanResult(
            id: UUID(),
            timestamp: Date(),
            originalImage: mockImage,
            processedImage: mockImage, // In production, this would be the cropped/enhanced image
            detectedText: detectedText,
            confidence: 0.92, // Mock confidence score
            documentBounds: CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        )

        return scanResult
    }

    private func performTextRecognition(on image: UIImage) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            guard let cgImage = image.cgImage else {
                continuation.resume(throwing: DocumentScanningError.imageProcessingFailed)
                return
            }

            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: DocumentScanningError.documentDetectionFailed)
                    return
                }

                let recognizedText = observations.compactMap { observation in
                    return try? observation.topCandidates(1).first?.string
                }.joined(separator: "\n")

                continuation.resume(returning: recognizedText)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private func performAIAnalysis(_ scanResult: DocumentScanResult) async throws -> DocumentAnalysis {
        let startTime = Date()

        await updateProgress(0.1)

        // Prepare analysis prompt
        let analysisPrompt = createAnalysisPrompt(for: scanResult)

        await updateProgress(0.3)

        // Try different AI providers in order of preference
        let (aiResponse, provider) = try await callAIForDocumentAnalysis(prompt: analysisPrompt)

        await updateProgress(0.7)

        // Parse AI response into structured analysis
        let analysis = try parseAIAnalysisResponse(
            aiResponse,
            scanResultID: scanResult.id,
            provider: provider,
            processingTime: Date().timeIntervalSince(startTime)
        )

        await updateProgress(1.0)

        return analysis
    }

    private func createAnalysisPrompt(for scanResult: DocumentScanResult) -> String {
        let detectedText = scanResult.detectedText ?? "No text detected"

        return """
        Please analyze this document and provide a structured response:

        DETECTED TEXT:
        \(detectedText)

        Please provide:
        1. DOCUMENT TYPE: What type of document is this?
        2. KEY INFORMATION: Extract important data (dates, names, amounts, etc.)
        3. SUMMARY: Brief summary of the document content
        4. RECOMMENDATIONS: Any actionable recommendations
        5. CONFIDENCE: Your confidence level (0.0-1.0)

        Format your response as JSON with these exact keys:
        {
            "document_type": "string",
            "key_information": {"key": "value"},
            "summary": "string",
            "recommendations": ["string"],
            "confidence": 0.95
        }
        """
    }

    private func callAIForDocumentAnalysis(prompt: String) async throws -> (String, String) {
        // Try Claude first
        do {
            let response = try await callClaudeAPI(prompt: prompt)
            return (response, "Claude")
        } catch {
            print("Claude analysis failed: \(error)")
        }

        // Try OpenAI as fallback
        do {
            let response = try await callOpenAIAPI(prompt: prompt)
            return (response, "OpenAI")
        } catch {
            print("OpenAI analysis failed: \(error)")
        }

        // Try Gemini as fallback
        do {
            let response = try await callGeminiAPI(prompt: prompt)
            return (response, "Gemini")
        } catch {
            print("Gemini analysis failed: \(error)")
        }

        // Use intelligent fallback
        let fallbackResponse = generateFallbackAnalysis(prompt: prompt)
        return (fallbackResponse, "Fallback")
    }

    private func callClaudeAPI(prompt: String) async throws -> String {
        guard let apiKey = try? keychainManager.getCredential(forKey: "anthropic-api-key") else {
            throw DocumentScanningError.aiAnalysisFailed("Claude API key not found")
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DocumentScanningError.aiAnalysisFailed("Claude API request failed")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw DocumentScanningError.aiAnalysisFailed("Invalid Claude API response format")
        }

        return text
    }

    private func callOpenAIAPI(prompt: String) async throws -> String {
        guard let apiKey = try? keychainManager.getCredential(forKey: "openai-api-key") else {
            throw DocumentScanningError.aiAnalysisFailed("OpenAI API key not found")
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "max_tokens": 1000,
            "messages": [
                ["role": "user", "content": prompt]
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DocumentScanningError.aiAnalysisFailed("OpenAI API request failed")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw DocumentScanningError.aiAnalysisFailed("Invalid OpenAI API response format")
        }

        return content
    }

    private func callGeminiAPI(prompt: String) async throws -> String {
        guard let apiKey = try? keychainManager.getCredential(forKey: "google-api-key") else {
            throw DocumentScanningError.aiAnalysisFailed("Google API key not found")
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": prompt
                        ],
                    ],
                ],
            ],
            "generationConfig": [
                "temperature": 0.3,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1000,
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw DocumentScanningError.aiAnalysisFailed("Gemini API request failed")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw DocumentScanningError.aiAnalysisFailed("Invalid Gemini API response format")
        }

        return text
    }

    private func generateFallbackAnalysis(prompt: String) -> String {
        // Generate intelligent fallback analysis based on the prompt
        let fallbackAnalysis = """
        {
            "document_type": "Unknown Document",
            "key_information": {
                "status": "offline_mode",
                "note": "AI analysis requires internet connection"
            },
            "summary": "Document detected but AI analysis is unavailable. Please check your internet connection and API credentials.",
            "recommendations": [
                "Verify internet connection",
                "Check API credentials in Settings",
                "Try scanning again when online"
            ],
            "confidence": 0.5
        }
        """

        return fallbackAnalysis
    }

    private func parseAIAnalysisResponse(_ response: String, scanResultID: UUID, provider: String, processingTime: TimeInterval) throws -> DocumentAnalysis {
        // Extract JSON from the response
        guard let jsonData = extractJSON(from: response)?.data(using: .utf8) else {
            throw DocumentScanningError.aiAnalysisFailed("Invalid JSON format in AI response")
        }

        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw DocumentScanningError.aiAnalysisFailed("Failed to parse JSON response")
        }

        let documentType = json["document_type"] as? String ?? "Unknown"
        let keyInformation = json["key_information"] as? [String: Any] ?? [:]
        let summary = json["summary"] as? String ?? "No summary available"
        let recommendations = json["recommendations"] as? [String] ?? []
        let confidence = (json["confidence"] as? NSNumber)?.floatValue ?? 0.5

        return DocumentAnalysis(
            id: UUID(),
            scanResultID: scanResultID,
            aiProvider: provider,
            summary: summary,
            extractedData: [
                "document_type": documentType,
                "key_information": keyInformation,
            ],
            recommendations: recommendations,
            confidence: confidence,
            processingTime: processingTime,
            timestamp: Date()
        )
    }

    private func extractJSON(from text: String) -> String? {
        // Find JSON block in the response
        if let range = text.range(of: "\\{.*\\}", options: .regularExpression) {
            return String(text[range])
        }

        // If no JSON block found, check if the entire response is JSON
        if text.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") &&
           text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("}") {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return nil
    }

    private func createMockDocumentImage() -> UIImage {
        // Create a mock document image for development
        let size = CGSize(width: 400, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // White background
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Black text
            UIColor.black.setFill()
            let textRect = CGRect(x: 40, y: 60, width: 320, height: 480)

            let sampleText = """
            INVOICE

            Invoice #: 2025-001
            Date: June 25, 2025

            Bill To:
            John Smith
            123 Main Street
            Anytown, CA 12345

            Items:
            1. Consulting Services    $500.00
            2. Software License       $299.00

            Subtotal:                 $799.00
            Tax (8.5%):               $67.92
            Total:                    $866.92

            Payment Terms: Net 30
            Due Date: July 25, 2025
            """

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14),
                .foregroundColor: UIColor.black,
            ]

            sampleText.draw(in: textRect, withAttributes: attributes)
        }

        return image
    }

    private func updateProgress(_ progress: Float) async {
        await MainActor.run {
            self.currentProgress = progress
        }
    }
}
