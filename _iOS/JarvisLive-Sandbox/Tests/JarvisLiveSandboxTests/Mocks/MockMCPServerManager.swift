// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Mock MCPServerManager for testing VoiceCommandPipeline
 * Issues & Complexity Summary: Configurable mock for MCP server interactions and execution
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: Medium (Mock MCP behavior simulation)
 *   - Dependencies: 2 New (Foundation, Combine)
 *   - State Management Complexity: Medium (Mock server state tracking)
 *   - Novelty/Uncertainty Factor: Low (Standard mock implementation)
 * AI Pre-Task Self-Assessment: 75%
 * Problem Estimate: 70%
 * Initial Code Complexity Estimate: 78%
 * Final Code Complexity: 80%
 * Overall Result Score: 90%
 * Key Variances/Learnings: MCP mock requires realistic server simulation
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
@testable import JarvisLiveSandbox

// MARK: - Mock MCP Execution Result

struct MCPExecutionResult {
    let success: Bool
    let response: String
    let executionTime: TimeInterval
    let serverUsed: String
    let metadata: [String: String]?
    let error: Error?

    init(success: Bool, response: String, executionTime: TimeInterval, serverUsed: String, metadata: [String: String]? = nil, error: Error? = nil) {
        self.success = success
        self.response = response
        self.executionTime = executionTime
        self.serverUsed = serverUsed
        self.metadata = metadata
        self.error = error
    }
}

@MainActor
final class MockMCPServerManager: MCPServerManagerProtocol, ObservableObject {
    // MARK: - Published Properties (Mirror real implementation)

    @Published private(set) var servers: [MCPServer] = []
    @Published private(set) var availableTools: [String: MCPCapabilities.MCPTool] = [:]
    @Published private(set) var isInitialized: Bool = true
    @Published private(set) var lastError: Error?
    @Published private(set) var activeOperations: Set<String> = []

    // MARK: - Mock Configuration

    var mockExecutionResult: MCPExecutionResult?
    var shouldThrowError: Bool = false
    var mockError: Error?
    var shouldDelayExecution: Bool = false
    var executionDelay: TimeInterval = 0.1

    // MARK: - Test Tracking

    var executeCallCount: Int = 0
    var lastExecutedCategory: String?
    var lastExecutedParameters: [String: String]?
    var generateDocumentCallCount: Int = 0
    var sendEmailCallCount: Int = 0
    var createCalendarEventCallCount: Int = 0
    var performSearchCallCount: Int = 0
    var uploadFileCallCount: Int = 0

    // MARK: - Initialization

    init() {
        setupMockServers()
    }

    private func setupMockServers() {
        servers = [
            MCPServer(
                id: "document-generator",
                name: "Document Generator",
                status: .connected,
                capabilities: MCPCapabilities(
                    name: "document-generator",
                    version: "1.0.0",
                    tools: [
                        "generate_pdf": MCPCapabilities.MCPTool(
                            name: "generate_pdf",
                            description: "Generate PDF documents",
                            inputSchema: [:],
                            examples: []
                        ),
                    ]
                ),
                lastPing: Date(),
                endpoint: "/mcp/document"
            ),
            MCPServer(
                id: "email-server",
                name: "Email Server",
                status: .connected,
                capabilities: MCPCapabilities(
                    name: "email-server",
                    version: "1.0.0",
                    tools: [
                        "send_email": MCPCapabilities.MCPTool(
                            name: "send_email",
                            description: "Send emails",
                            inputSchema: [:],
                            examples: []
                        ),
                    ]
                ),
                lastPing: Date(),
                endpoint: "/mcp/email"
            ),
        ]

        // Setup available tools
        availableTools = servers.reduce(into: [:]) { result, server in
            for (toolName, tool) in server.capabilities.tools {
                result[toolName] = tool
            }
        }
    }

    // MARK: - Mock MCP Execution Methods

    func executeVoiceCommand(category: String, intent: String, parameters: [String: String]) async throws -> MCPExecutionResult {
        // Update tracking
        executeCallCount += 1
        lastExecutedCategory = category
        lastExecutedParameters = parameters

        // Simulate execution delay if configured
        if shouldDelayExecution {
            try await Task.sleep(nanoseconds: UInt64(executionDelay * 1_000_000_000))
        }

        // Check for error simulation
        if shouldThrowError {
            if let error = mockError {
                lastError = error
                throw error
            } else {
                let error = NSError(domain: "MockMCPError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock MCP execution failed"])
                lastError = error
                throw error
            }
        }

        // Return configured mock result or default
        if let result = mockExecutionResult {
            return result
        } else {
            // Generate realistic default based on category
            return generateDefaultResult(for: category, intent: intent, parameters: parameters)
        }
    }

    private func generateDefaultResult(for category: String, intent: String, parameters: [String: String]) -> MCPExecutionResult {
        switch category {
        case "document_generation":
            return MCPExecutionResult(
                success: true,
                response: "Document generated successfully",
                executionTime: 2.0,
                serverUsed: "document-generator",
                metadata: ["document_id": "doc_\(UUID().uuidString.prefix(8))", "format": parameters["format"] ?? "pdf"]
            )

        case "email_management":
            return MCPExecutionResult(
                success: true,
                response: "Email sent successfully",
                executionTime: 1.0,
                serverUsed: "email-server",
                metadata: ["message_id": "msg_\(UUID().uuidString.prefix(8))", "recipients": parameters["to"] ?? "unknown"]
            )

        case "calendar_scheduling":
            return MCPExecutionResult(
                success: true,
                response: "Calendar event created",
                executionTime: 0.8,
                serverUsed: "calendar-server",
                metadata: ["event_id": "evt_\(UUID().uuidString.prefix(8))", "title": parameters["title"] ?? "New Event"]
            )

        case "web_search":
            return MCPExecutionResult(
                success: true,
                response: "Search completed with 42 results",
                executionTime: 0.5,
                serverUsed: "search-server",
                metadata: ["query": parameters["query"] ?? "unknown", "result_count": "42"]
            )

        default:
            return MCPExecutionResult(
                success: true,
                response: "Command processed successfully",
                executionTime: 0.3,
                serverUsed: "generic-server",
                metadata: ["category": category, "intent": intent]
            )
        }
    }

    // MARK: - Individual MCP Action Methods

    func generateDocument(content: String, format: DocumentGenerationRequest.DocumentFormat) async throws -> DocumentGenerationResponse {
        generateDocumentCallCount += 1

        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500)
        }

        return DocumentGenerationResponse(
            documentURL: "https://example.com/doc_\(UUID().uuidString.prefix(8)).pdf",
            format: format,
            size: 1024 * 256, // 256KB
            generationTime: 2.0
        )
    }

    func sendEmail(to: [String], subject: String, body: String) async throws -> EmailResponse {
        sendEmailCallCount += 1

        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500)
        }

        return EmailResponse(
            messageId: "msg_\(UUID().uuidString.prefix(8))",
            status: "sent",
            deliveryTime: 1.2
        )
    }

    func createCalendarEvent(title: String, startTime: Date, endTime: Date) async throws -> CalendarEventResponse {
        createCalendarEventCallCount += 1

        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500)
        }

        return CalendarEventResponse(
            eventId: "evt_\(UUID().uuidString.prefix(8))",
            title: title,
            startTime: startTime,
            endTime: endTime,
            status: "created"
        )
    }

    func performSearch(query: String) async throws -> SearchResponse {
        performSearchCallCount += 1

        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500)
        }

        return SearchResponse(
            results: [
                SearchResult(
                    title: "Mock Search Result",
                    url: "https://example.com/result1",
                    snippet: "This is a mock search result",
                    relevanceScore: 0.95
                ),
            ],
            totalCount: 42,
            searchTime: 0.5
        )
    }

    func uploadFile(data: Data, path: String) async throws -> FileUploadResponse {
        uploadFileCallCount += 1

        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500)
        }

        return FileUploadResponse(
            path: path,
            size: data.count,
            uploadTime: 1.0
        )
    }

    // MARK: - State Management Methods

    func initialize() async {
        isInitialized = true
    }

    func getServerStatus() -> [String: MCPServerStatus] {
        return servers.reduce(into: [:]) { result, server in
            result[server.id] = server.status
        }
    }

    func refreshServerStatus() async {
        // Mock implementation - no-op
    }

    // MARK: - Helper Methods for Testing

    func reset() {
        executeCallCount = 0
        lastExecutedCategory = nil
        lastExecutedParameters = nil
        generateDocumentCallCount = 0
        sendEmailCallCount = 0
        createCalendarEventCallCount = 0
        performSearchCallCount = 0
        uploadFileCallCount = 0
        mockExecutionResult = nil
        shouldThrowError = false
        mockError = nil
        shouldDelayExecution = false
        executionDelay = 0.1
        isInitialized = true
        lastError = nil
        activeOperations.removeAll()
    }

    func configureMockSuccess(category: String, response: String, executionTime: TimeInterval = 1.0) {
        mockExecutionResult = MCPExecutionResult(
            success: true,
            response: response,
            executionTime: executionTime,
            serverUsed: "\(category)-server",
            metadata: ["category": category]
        )
        shouldThrowError = false
        mockError = nil
    }

    func configureMockFailure(category: String, errorMessage: String, executionTime: TimeInterval = 0.5) {
        mockExecutionResult = MCPExecutionResult(
            success: false,
            response: errorMessage,
            executionTime: executionTime,
            serverUsed: "\(category)-server",
            metadata: nil,
            error: NSError(domain: "MockMCPError", code: 500, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        )
        shouldThrowError = false // Use result failure instead of throwing
        mockError = nil
    }

    func configureMockError(_ error: Error) {
        shouldThrowError = true
        mockError = error
        mockExecutionResult = nil
    }
    
    // MARK: - MCPServerManagerProtocol Conformance
    
    var isConnected: Bool {
        return true // Always connected for testing
    }
    
    var availableServers: [String] {
        return servers.map { $0.id }
    }
    
    var serverStatus: [String: String] {
        return servers.reduce(into: [:]) { result, server in
            result[server.id] = server.status.rawValue
        }
    }
    
    func connect() async throws {
        // Mock implementation - always succeeds
    }
    
    func disconnect() async {
        // Mock implementation - no-op
    }
    
    func isHealthy() async -> Bool {
        return true
    }
    
    func executeCommand(_ command: String, server: String, parameters: [String: Any]) async throws -> [String: Any] {
        // Basic mock implementation
        return [
            "success": true,
            "result": "Mock command executed",
            "command": command,
            "server": server
        ]
    }
    
    func getServerCapabilities(_ server: String) async -> [String] {
        if let mcpServer = servers.first(where: { $0.id == server }) {
            return mcpServer.capabilities.tools.map { $0.key }
        }
        return []
    }
}
