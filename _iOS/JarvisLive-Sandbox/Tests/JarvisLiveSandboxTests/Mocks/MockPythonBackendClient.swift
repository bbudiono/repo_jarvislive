// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Mock PythonBackendClient for testing MCPServerManager and network operations
 * Issues & Complexity Summary: Comprehensive mock for backend client with configurable responses
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High (Network simulation, response configuration)
 *   - Dependencies: 3 New (Foundation, Combine, XCTest)
 *   - State Management Complexity: High (Connection state, request tracking)
 *   - Novelty/Uncertainty Factor: Medium (Network mocking patterns)
 * AI Pre-Task Self-Assessment: 85%
 * Problem Estimate: 80%
 * Initial Code Complexity Estimate: 82%
 * Final Code Complexity: 85%
 * Overall Result Score: 92%
 * Key Variances/Learnings: Network mocking requires realistic behavior simulation
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
@testable import JarvisLiveSandbox

@MainActor
final class MockPythonBackendClient: ObservableObject {
    // MARK: - Published Properties (Mirror real implementation)

    @Published private(set) var connectionStatus: PythonBackendClient.ConnectionStatus = .disconnected
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var lastError: Error?
    @Published private(set) var requestCount: Int = 0

    // MARK: - Mock Configuration

    var shouldThrowError: Bool = false
    var mockError: Error?
    var shouldDelayResponses: Bool = false
    var responseDelay: TimeInterval = 0.1

    // MARK: - Test Tracking

    var connectCallCount: Int = 0
    var disconnectCallCount: Int = 0
    var serverDiscoveryCallCount: Int = 0
    var toolExecutionCallCount: Int = 0
    var documentGenerationCallCount: Int = 0
    var emailSendingCallCount: Int = 0
    var calendarCreationCallCount: Int = 0
    var searchCallCount: Int = 0
    var fileUploadCallCount: Int = 0
    var healthCheckCallCount: Int = 0
    var voiceClassificationCallCount: Int = 0

    // MARK: - Mock Response Configuration

    private var mockServerDiscoveryResponse: [MockServerInfo] = []
    private var mockClassificationResult: ClassificationResult?
    private var mockToolResult: MCPToolResult?
    private var mockDocumentResult: DocumentGenerationResult?
    private var mockEmailResult: EmailResult?
    private var mockCalendarResult: CalendarEventResult?
    private var mockSearchResult: SearchResult?
    private var mockFileUploadResult: StorageResult?
    private var healthCheckFailures: Set<String> = []

    // MARK: - Connection Management

    func connect() async {
        connectCallCount += 1

        if shouldDelayResponses {
            try? await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockError", code: 500)
            lastError = error
            connectionStatus = .error("Connection failed")
            isConnected = false
            return
        }

        connectionStatus = .connected
        isConnected = true
        lastError = nil
    }

    func disconnect() async {
        disconnectCallCount += 1
        connectionStatus = .disconnected
        isConnected = false
    }

    // MARK: - Generic Request Methods

    func sendRequest<T: Codable>(_ request: MCPRequest, responseType: T.Type) async throws -> T {
        requestCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockRequestError", code: 500)
            lastError = error
            throw error
        }

        switch request.method {
        case "discover_servers":
            serverDiscoveryCallCount += 1
            let response = ServerDiscoveryResponse(servers: mockServerDiscoveryResponse)
            return response as! T

        case "call_tool":
            toolExecutionCallCount += 1
            if let result = mockToolResult {
                return result as! T
            }

        default:
            break
        }

        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock response not configured"])
    }

    func sendHTTPRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        headers: [String: String]? = nil,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        requestCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockHTTPError", code: 500)
            lastError = error
            throw error
        }

        // Handle health check endpoints
        if endpoint.contains("/health") {
            healthCheckCallCount += 1
            let serverId = extractServerIdFromEndpoint(endpoint)

            if healthCheckFailures.contains(serverId) {
                throw NSError(domain: "HealthCheckError", code: 503)
            }

            let healthResponse = HealthCheckResponse(
                status: "healthy",
                timestamp: Date(),
                serverId: serverId
            )
            return healthResponse as! T
        }

        // Handle tool execution endpoints
        if endpoint.contains("/execute") {
            toolExecutionCallCount += 1
            if let result = mockToolResult {
                return result as! T
            }
        }

        throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock HTTP response not configured"])
    }

    // MARK: - High-Level Operation Methods

    func generateDocument(request: DocumentGenerationRequest) async throws -> DocumentGenerationResult {
        documentGenerationCallCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockDocumentError", code: 500)
            lastError = error
            throw error
        }

        guard let result = mockDocumentResult else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock document result not configured"])
        }

        return result
    }

    func sendEmail(request: EmailRequest) async throws -> EmailResult {
        emailSendingCallCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockEmailError", code: 500)
            lastError = error
            throw error
        }

        guard let result = mockEmailResult else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock email result not configured"])
        }

        return result
    }

    func createCalendarEvent(request: CalendarEventRequest) async throws -> CalendarEventResult {
        calendarCreationCallCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockCalendarError", code: 500)
            lastError = error
            throw error
        }

        guard let result = mockCalendarResult else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock calendar result not configured"])
        }

        return result
    }

    func performSearch(request: SearchRequest) async throws -> SearchResult {
        searchCallCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockSearchError", code: 500)
            lastError = error
            throw error
        }

        guard let result = mockSearchResult else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock search result not configured"])
        }

        return result
    }

    func uploadFile(request: StorageRequest) async throws -> StorageResult {
        fileUploadCallCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockFileError", code: 500)
            lastError = error
            throw error
        }

        guard let result = mockFileUploadResult else {
            throw NSError(domain: "MockError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Mock file upload result not configured"])
        }

        return result
    }

    // MARK: - Voice Classification for E2E Testing

    func classifyVoiceCommand(_ text: String) async throws -> ClassificationResult {
        voiceClassificationCallCount += 1

        if shouldDelayResponses {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        if shouldThrowError {
            let error = mockError ?? NSError(domain: "MockVoiceError", code: 500)
            lastError = error
            throw error
        }

        // Check for environment-based test scenarios
        if let result = determineMockClassificationResponse(for: text) {
            return result
        }

        guard let result = mockClassificationResult else {
            // Default response for E2E testing
            return ClassificationResult(
                category: .unknown,
                intent: "",
                confidence: 0.15,
                parameters: [:],
                suggestions: ["Try saying: 'Show settings'", "Try saying: 'Generate document'"],
                rawText: text,
                normalizedText: text.lowercased(),
                processingTime: 0.25
            )
        }

        return result
    }

    private func determineMockClassificationResponse(for text: String) -> ClassificationResult? {
        let environment = ProcessInfo.processInfo.environment
        
        // Handle specific test scenarios based on launch environment
        if environment["MOCK_CLASSIFICATION_RESPONSES"] == "true" {
            let lowercaseText = text.lowercased()
            
            if lowercaseText.contains("setting") || lowercaseText.contains("show settings") {
                return ClassificationResult(
                    category: .settings,
                    intent: "show_settings",
                    confidence: 0.92,
                    parameters: [:],
                    suggestions: [],
                    rawText: text,
                    normalizedText: lowercaseText,
                    processingTime: 0.15
                )
            } else if lowercaseText.contains("document") || lowercaseText.contains("pdf") {
                return ClassificationResult(
                    category: .documentGeneration,
                    intent: "create_pdf",
                    confidence: 0.88,
                    parameters: ["format": AnyCodable("PDF"), "topic": AnyCodable("quarterly report")],
                    suggestions: [],
                    rawText: text,
                    normalizedText: lowercaseText,
                    processingTime: 0.22
                )
            }
        }
        
        if environment["MOCK_LOW_CONFIDENCE_RESPONSE"] == "true" {
            return ClassificationResult(
                category: .settings,
                intent: "show_settings",
                confidence: 0.45,
                parameters: [:],
                suggestions: ["Show settings", "Open preferences", "Display configuration"],
                rawText: text,
                normalizedText: text.lowercased(),
                processingTime: 0.35
            )
        }
        
        if environment["MOCK_MULTIPLE_OPTIONS_RESPONSE"] == "true" {
            return ClassificationResult(
                category: .emailManagement,
                intent: "email_action",
                confidence: 0.75,
                parameters: ["recipient": AnyCodable("team")],
                suggestions: ["Send email to team", "Create calendar event", "Draft message"],
                rawText: text,
                normalizedText: text.lowercased(),
                processingTime: 0.18
            )
        }
        
        if environment["SIMULATE_NETWORK_ERROR"] == "true" {
            shouldThrowError = true
            mockError = NSError(
                domain: "NetworkError",
                code: -1009,
                userInfo: [NSLocalizedDescriptionKey: "Network connection required for voice processing"]
            )
        }
        
        if environment["SIMULATE_PROCESSING_TIMEOUT"] == "true" {
            shouldDelayResponses = true
            responseDelay = 35.0 // Simulate timeout
        }
        
        return nil
    }

    // MARK: - Mock Configuration Methods

    func configureMockConnection(status: PythonBackendClient.ConnectionStatus) {
        connectionStatus = status
        isConnected = (status == .connected)
        shouldThrowError = false
        mockError = nil
    }

    func configureMockError(_ error: Error) {
        shouldThrowError = true
        mockError = error
    }

    func configureMockServerDiscovery(servers: [MockServerInfo]) {
        mockServerDiscoveryResponse = servers
        shouldThrowError = false
        mockError = nil
    }

    func configureMockToolResult(_ result: MCPToolResult) {
        mockToolResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureMockDocumentResult(_ result: DocumentGenerationResult) {
        mockDocumentResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureMockEmailResult(_ result: EmailResult) {
        mockEmailResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureMockCalendarResult(_ result: CalendarEventResult) {
        mockCalendarResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureMockSearchResult(_ result: SearchResult) {
        mockSearchResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureMockFileUploadResult(_ result: StorageResult) {
        mockFileUploadResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureMockClassificationResult(_ result: ClassificationResult) {
        mockClassificationResult = result
        shouldThrowError = false
        mockError = nil
    }

    func configureHealthCheckFailure(serverId: String) {
        healthCheckFailures.insert(serverId)
    }

    // MARK: - Test Helper Methods

    func reset() {
        connectCallCount = 0
        disconnectCallCount = 0
        serverDiscoveryCallCount = 0
        toolExecutionCallCount = 0
        documentGenerationCallCount = 0
        emailSendingCallCount = 0
        calendarCreationCallCount = 0
        searchCallCount = 0
        fileUploadCallCount = 0
        healthCheckCallCount = 0
        voiceClassificationCallCount = 0

        shouldThrowError = false
        mockError = nil
        shouldDelayResponses = false
        responseDelay = 0.1

        mockServerDiscoveryResponse.removeAll()
        mockToolResult = nil
        mockDocumentResult = nil
        mockEmailResult = nil
        mockCalendarResult = nil
        mockSearchResult = nil
        mockFileUploadResult = nil
        mockClassificationResult = nil
        healthCheckFailures.removeAll()

        connectionStatus = .disconnected
        isConnected = false
        lastError = nil
        requestCount = 0
    }

    private func extractServerIdFromEndpoint(_ endpoint: String) -> String {
        // Extract server ID from endpoint path like "/mcp/document/health"
        let components = endpoint.components(separatedBy: "/")
        if components.count >= 3 {
            return "\(components[2])-server"
        }
        return "unknown-server"
    }

    // MARK: - Mock Data Structures

    struct MockServerInfo: Codable {
        let id: String
        let name: String
        let description: String
        let version: String
        let capabilities: MCPCapabilities
    }
}

// MARK: - Supporting Response Types

private struct ServerDiscoveryResponse: Codable {
    let servers: [MockPythonBackendClient.MockServerInfo]
}

private struct HealthCheckResponse: Codable {
    let status: String
    let timestamp: Date
    let serverId: String
}

// MARK: - HTTP Method Enum

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Extensions for Better Testing

extension MockPythonBackendClient {
    func simulateNetworkDelay(_ delay: TimeInterval = 0.5) {
        shouldDelayResponses = true
        responseDelay = delay
    }

    func simulateConnectionLoss() {
        connectionStatus = .disconnected
        isConnected = false
    }

    func simulateServerError(_ statusCode: Int = 500) {
        shouldThrowError = true
        mockError = NSError(
            domain: "MockServerError",
            code: statusCode,
            userInfo: [NSLocalizedDescriptionKey: "Simulated server error with status \(statusCode)"]
        )
    }

    func getRequestStatistics() -> [String: Int] {
        return [
            "connect": connectCallCount,
            "disconnect": disconnectCallCount,
            "serverDiscovery": serverDiscoveryCallCount,
            "toolExecution": toolExecutionCallCount,
            "documentGeneration": documentGenerationCallCount,
            "emailSending": emailSendingCallCount,
            "calendarCreation": calendarCreationCallCount,
            "search": searchCallCount,
            "fileUpload": fileUploadCallCount,
            "healthCheck": healthCheckCallCount,
            "voiceClassification": voiceClassificationCallCount,
            "totalRequests": requestCount,
        ]
    }
}
