// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Mock VoiceClassificationManager for testing VoiceCommandPipeline
 * Issues & Complexity Summary: Configurable mock with realistic behavior simulation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~150
 *   - Core Algorithm Complexity: Medium (Mock behavior configuration)
 *   - Dependencies: 2 New (Foundation, Combine)
 *   - State Management Complexity: Medium (Mock state tracking)
 *   - Novelty/Uncertainty Factor: Low (Standard mock implementation)
 * AI Pre-Task Self-Assessment: 80%
 * Problem Estimate: 70%
 * Initial Code Complexity Estimate: 75%
 * Final Code Complexity: 78%
 * Overall Result Score: 92%
 * Key Variances/Learnings: Mock flexibility crucial for comprehensive testing
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
@testable import JarvisLiveSandbox

@MainActor
final class MockVoiceClassificationManager: ObservableObject {
    // MARK: - Published Properties (Mirror real implementation)

    @Published var isProcessing: Bool = false
    @Published var isAuthenticated: Bool = true
    @Published var lastClassification: ClassificationResult?
    @Published var connectionStatus: VoiceClassificationManager.ConnectionStatus = .connected
    @Published var lastError: VoiceClassificationError?

    // MARK: - Mock Configuration

    var mockClassificationResult: ClassificationResult?
    var shouldThrowError: Bool = false
    var mockError: VoiceClassificationError?
    var shouldDelayResponse: Bool = false
    var responseDelay: TimeInterval = 0.1

    // MARK: - Test Tracking

    var classifyCallCount: Int = 0
    var lastClassificationRequest: String?
    var lastUserId: String?
    var lastSessionId: String?

    // MARK: - Mock Implementation

    func classifyVoiceCommand(_ text: String, userId: String? = nil, sessionId: String? = nil) async throws -> ClassificationResult {
        // Update tracking
        classifyCallCount += 1
        lastClassificationRequest = text
        lastUserId = userId
        lastSessionId = sessionId

        // Simulate processing state
        isProcessing = true

        // Simulate network delay if configured
        if shouldDelayResponse {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        // Check for error simulation
        if shouldThrowError {
            isProcessing = false
            if let error = mockError {
                lastError = error
                throw error
            } else {
                let error = VoiceClassificationError.classificationFailed("Mock error")
                lastError = error
                throw error
            }
        }

        // Return mock result
        guard let result = mockClassificationResult else {
            isProcessing = false
            let error = VoiceClassificationError.invalidResponse
            lastError = error
            throw error
        }

        lastClassification = result
        isProcessing = false

        return result
    }

    // MARK: - Additional Mock Methods

    func getContextualSuggestions(userId: String? = nil, sessionId: String? = nil) async throws -> [ContextualSuggestion] {
        return [
            ContextualSuggestion(suggestion: "Create a document", category: "document", confidence: 0.8, priority: "high"),
            ContextualSuggestion(suggestion: "Send an email", category: "email", confidence: 0.7, priority: "medium"),
        ]
    }

    func getContextSummary(userId: String? = nil, sessionId: String? = nil) async throws -> ContextSummaryResponse {
        return ContextSummaryResponse(
            userId: userId ?? "mock_user",
            sessionId: sessionId ?? "mock_session",
            totalInteractions: 5,
            categoriesUsed: ["document_generation", "email_management"],
            currentTopic: "productivity",
            recentTopics: ["documents", "emails"],
            lastActivity: "2025-06-26T10:00:00Z",
            activeParameters: ["context": "enabled"],
            sessionDuration: 300.0,
            preferences: ["format": "brief"]
        )
    }

    func executeClassifiedCommand(_ result: ClassificationResult) async throws -> CommandExecutionResult {
        return CommandExecutionResult(
            success: true,
            message: "Mock command executed",
            actionPerformed: "mock_action",
            timeSpent: 0.1,
            additionalData: nil
        )
    }

    func storeAPIKey(_ apiKey: String) throws {
        // Mock implementation - no-op
    }

    func hasStoredAPIKey() -> Bool {
        return true
    }

    func clearAuthentication() async {
        isAuthenticated = false
        connectionStatus = .disconnected
    }

    func setUserId(_ userId: String) {
        // Mock implementation - no-op
    }

    func performHealthCheck() async throws -> Bool {
        return true
    }

    func getAuthenticationStatus() -> [String: Any] {
        return [
            "isAuthenticated": isAuthenticated,
            "connectionStatus": String(describing: connectionStatus),
            "hasStoredAPIKey": true,
            "userId": "mock_user",
            "sessionId": "mock_session",
        ]
    }

    // MARK: - Helper Methods for Testing

    func reset() {
        classifyCallCount = 0
        lastClassificationRequest = nil
        lastUserId = nil
        lastSessionId = nil
        mockClassificationResult = nil
        shouldThrowError = false
        mockError = nil
        shouldDelayResponse = false
        responseDelay = 0.1
        isProcessing = false
        isAuthenticated = true
        lastClassification = nil
        connectionStatus = .connected
        lastError = nil
    }

    func configureMockSuccess(category: String, intent: String, confidence: Double = 0.85) {
        mockClassificationResult = ClassificationResult(
            category: category,
            intent: intent,
            confidence: confidence,
            parameters: [:],
            suggestions: [],
            rawText: "mock input",
            normalizedText: "mock input",
            confidenceLevel: confidence > 0.8 ? "high" : confidence > 0.6 ? "medium" : "low",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.02,
            requiresConfirmation: confidence < 0.7
        )
        shouldThrowError = false
        mockError = nil
    }

    func configureMockError(_ error: VoiceClassificationError) {
        shouldThrowError = true
        mockError = error
        mockClassificationResult = nil
    }
}
