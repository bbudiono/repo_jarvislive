// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Mock MCP Server Manager for testing voice command pipeline
 * Issues & Complexity Summary: Mock implementation providing realistic MCP server simulation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~300
 *   - Core Algorithm Complexity: Medium (Mock service simulation)
 *   - Dependencies: 2 (Foundation, Combine)
 *   - State Management Complexity: Medium (Mock server states)
 *   - Novelty/Uncertainty Factor: Low (Mock implementation)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 60%
 * Problem Estimate (Inherent Problem Difficulty %): 50%
 * Initial Code Complexity Estimate %: 65%
 * Justification for Estimates: Mock implementation with realistic behavior patterns
 * Final Code Complexity (Actual %): 62%
 * Overall Result Score (Success & Quality %): 88%
 * Key Variances/Learnings: Mock services need realistic delays and error scenarios
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - MCP Server Manager Protocol

protocol MCPServerManagerProtocol: ObservableObject {
    var isConnected: Bool { get }
    var availableServers: [String] { get }
    var serverStatus: [String: String] { get }
    var isInitialized: Bool { get }
    var lastError: Error? { get }
    
    func connect() async throws
    func disconnect() async
    func isHealthy() async -> Bool
    func executeCommand(_ command: String, server: String, parameters: [String: Any]) async throws -> [String: Any]
    func executeVoiceCommand(_ classification: ClassificationResult) async throws -> MCPExecutionResult
    func getServerCapabilities(_ server: String) async -> [String]
    func initialize() async
}

// MARK: - Mock MCP Server Manager

@MainActor
final class MockMCPServerManager: MCPServerManagerProtocol, ObservableObject {
    // MARK: - Published Properties

    @Published var isConnected: Bool = false
    @Published var availableServers: [String] = []
    @Published var serverStatus: [String: String] = [:]
    @Published var lastError: Error?

    // MARK: - Private Properties

    private let mockServers: [String: MockMCPServer] = [
        "document": MockMCPServer(
            name: "document",
            capabilities: ["generate_pdf", "generate_docx", "generate_markdown", "extract_text"],
            latency: 0.5
        ),
        "email": MockMCPServer(
            name: "email",
            capabilities: ["send_email", "read_inbox", "compose_email", "manage_contacts"],
            latency: 0.3
        ),
        "calendar": MockMCPServer(
            name: "calendar",
            capabilities: ["create_event", "list_events", "update_event", "delete_event"],
            latency: 0.4
        ),
        "search": MockMCPServer(
            name: "search",
            capabilities: ["web_search", "knowledge_query", "fact_check", "research"],
            latency: 0.8
        ),
        "ai_providers": MockMCPServer(
            name: "ai_providers",
            capabilities: ["claude_chat", "gpt_chat", "gemini_chat", "model_selection"],
            latency: 1.2
        ),
    ]

    // MARK: - Initialization

    init() {
        setupMockServers()

        // Auto-connect for testing
        Task {
            try await connect()
        }
    }
    
    // MARK: - Voice Command Execution
    
    func executeVoiceCommand(_ classification: ClassificationResult) async throws -> MCPExecutionResult {
        guard isConnected else {
            throw MCPError.serverUnavailable("No servers connected")
        }
        
        // Route to appropriate server based on classification category
        let serverName = mapCategoryToServer(classification.category)
        
        guard let mockServer = mockServers[serverName] else {
            throw MCPError.serverNotFound(serverName)
        }
        
        // Convert classification to command and parameters
        let command = mapIntentToCommand(classification.intent)
        let parameters = classification.parameters.reduce(into: [String: Any]()) { result, pair in
            result[pair.key] = pair.value
        }
        
        let result = try await mockServer.executeCommand(command, parameters: parameters)
        
        return MCPExecutionResult(
            success: result["success"] as? Bool ?? true,
            response: result["message"] as? String ?? "Command executed successfully",
            executionTime: result["processing_time"] as? TimeInterval ?? 0.5,
            serverUsed: serverName,
            metadata: result.compactMapValues { $0 as? String },
            error: nil
        )
    }
    
    private func mapCategoryToServer(_ category: String) -> String {
        switch category {
        case "document_generation":
            return "document"
        case "email_management":
            return "email"
        case "calendar_scheduling":
            return "calendar"
        case "web_search":
            return "search"
        case "ai_conversation":
            return "ai_providers"
        default:
            return "document" // Default fallback
        }
    }
    
    private func mapIntentToCommand(_ intent: String) -> String {
        switch intent {
        case "generate_document", "create_document":
            return "generate_pdf"
        case "send_email", "compose_email":
            return "send_email"
        case "create_event", "schedule_meeting":
            return "create_event"
        case "search_web", "find_information":
            return "web_search"
        case "chat", "conversation":
            return "claude_chat"
        default:
            return "web_search" // Default fallback
        }
    }

    private func setupMockServers() {
        availableServers = Array(mockServers.keys)
        serverStatus = mockServers.mapValues { _ in "initialized" }
    }

    // MARK: - Connection Management

    func connect() async throws {
        print("🔌 Connecting to mock MCP servers...")

        // Simulate connection delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Start all servers
        for (name, server) in mockServers {
            try await server.start()
            serverStatus[name] = "running"
        }

        isConnected = true
        print("✅ Mock MCP servers connected")
    }

    func disconnect() async {
        print("🔌 Disconnecting from mock MCP servers...")

        // Stop all servers
        for (name, server) in mockServers {
            await server.stop()
            serverStatus[name] = "stopped"
        }

        isConnected = false
        print("✅ Mock MCP servers disconnected")
    }

    // MARK: - Health Check

    func isHealthy() async -> Bool {
        guard isConnected else { return false }

        // Check if all servers are running
        return serverStatus.values.allSatisfy { $0 == "running" }
    }

    // MARK: - Command Execution

    func executeCommand(_ command: String, server: String, parameters: [String: Any]) async throws -> [String: Any] {
        guard let mockServer = mockServers[server] else {
            throw MCPError.serverNotFound(server)
        }

        guard isConnected && serverStatus[server] == "running" else {
            throw MCPError.serverUnavailable(server)
        }

        return try await mockServer.executeCommand(command, parameters: parameters)
    }

    // MARK: - Server Capabilities

    func getServerCapabilities(_ server: String) async -> [String] {
        guard let mockServer = mockServers[server] else {
            return []
        }

        return mockServer.capabilities
    }

    // MARK: - Server Information

    func getServerInfo() -> [String: Any] {
        return [
            "connected": isConnected,
            "server_count": availableServers.count,
            "running_servers": serverStatus.filter { $0.value == "running" }.count,
            "available_servers": availableServers,
            "server_status": serverStatus,
        ]
    }
}

// MARK: - Mock MCP Server

private class MockMCPServer {
    let name: String
    let capabilities: [String]
    let latency: TimeInterval
    private var isRunning: Bool = false

    init(name: String, capabilities: [String], latency: TimeInterval) {
        self.name = name
        self.capabilities = capabilities
        self.latency = latency
    }

    func start() async throws {
        // Simulate startup time
        try await Task.sleep(nanoseconds: UInt64(latency * 200_000_000))
        isRunning = true
        print("✅ Mock \(name) server started")
    }

    func stop() async {
        isRunning = false
        print("✅ Mock \(name) server stopped")
    }

    func executeCommand(_ command: String, parameters: [String: Any]) async throws -> [String: Any] {
        guard isRunning else {
            throw MCPError.serverUnavailable(name)
        }

        // Simulate processing time
        try await Task.sleep(nanoseconds: UInt64(latency * 1_000_000_000))

        // Route command based on server type and command
        switch name {
        case "document":
            return try await executeDocumentCommand(command, parameters: parameters)
        case "email":
            return try await executeEmailCommand(command, parameters: parameters)
        case "calendar":
            return try await executeCalendarCommand(command, parameters: parameters)
        case "search":
            return try await executeSearchCommand(command, parameters: parameters)
        case "ai_providers":
            return try await executeAICommand(command, parameters: parameters)
        default:
            throw MCPError.unsupportedCommand(command)
        }
    }

    // MARK: - Document Commands

    private func executeDocumentCommand(_ command: String, parameters: [String: Any]) async throws -> [String: Any] {
        switch command {
        case "generate_pdf":
            let content = parameters["content"] as? String ?? "Sample content"
            let title = parameters["title"] as? String ?? "Generated Document"

            return [
                "success": true,
                "document_url": "file:///tmp/\(title.replacingOccurrences(of: " ", with: "_")).pdf",
                "document_type": "pdf",
                "page_count": content.count / 500 + 1,
                "processing_time": latency,
            ]

        case "generate_docx":
            let content = parameters["content"] as? String ?? "Sample content"
            let title = parameters["title"] as? String ?? "Generated Document"

            return [
                "success": true,
                "document_url": "file:///tmp/\(title.replacingOccurrences(of: " ", with: "_")).docx",
                "document_type": "docx",
                "word_count": content.split(separator: " ").count,
                "processing_time": latency,
            ]

        case "generate_markdown":
            let content = parameters["content"] as? String ?? "Sample content"
            let title = parameters["title"] as? String ?? "Generated Document"

            return [
                "success": true,
                "content": "# \(title)\n\n\(content)",
                "document_type": "markdown",
                "processing_time": latency,
            ]

        default:
            throw MCPError.unsupportedCommand(command)
        }
    }

    // MARK: - Email Commands

    private func executeEmailCommand(_ command: String, parameters: [String: Any]) async throws -> [String: Any] {
        switch command {
        case "send_email":
            let to = parameters["to"] as? String ?? ""
            let subject = parameters["subject"] as? String ?? "No Subject"
            let body = parameters["body"] as? String ?? ""

            guard !to.isEmpty else {
                throw MCPError.invalidParameters("Recipient email is required")
            }

            return [
                "success": true,
                "message_id": "msg_\(UUID().uuidString)",
                "recipient": to,
                "subject": subject,
                "sent_at": ISO8601DateFormatter().string(from: Date()),
                "processing_time": latency,
            ]

        case "read_inbox":
            return [
                "success": true,
                "messages": [
                    [
                        "id": "msg_1",
                        "from": "example@test.com",
                        "subject": "Test Message 1",
                        "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
                    ],
                    [
                        "id": "msg_2",
                        "from": "another@test.com",
                        "subject": "Test Message 2",
                        "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200)),
                    ],
                ],
                "count": 2,
                "processing_time": latency,
            ]

        default:
            throw MCPError.unsupportedCommand(command)
        }
    }

    // MARK: - Calendar Commands

    private func executeCalendarCommand(_ command: String, parameters: [String: Any]) async throws -> [String: Any] {
        switch command {
        case "create_event":
            let title = parameters["title"] as? String ?? "New Event"
            let date = parameters["date"] as? String ?? ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600))
            let duration = parameters["duration"] as? Int ?? 60

            return [
                "success": true,
                "event_id": "evt_\(UUID().uuidString)",
                "title": title,
                "date": date,
                "duration_minutes": duration,
                "calendar": "primary",
                "processing_time": latency,
            ]

        case "list_events":
            return [
                "success": true,
                "events": [
                    [
                        "id": "evt_1",
                        "title": "Sample Meeting",
                        "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
                        "duration": 60,
                    ],
                    [
                        "id": "evt_2",
                        "title": "Another Event",
                        "date": ISO8601DateFormatter().string(from: Date().addingTimeInterval(7200)),
                        "duration": 30,
                    ],
                ],
                "count": 2,
                "processing_time": latency,
            ]

        default:
            throw MCPError.unsupportedCommand(command)
        }
    }

    // MARK: - Search Commands

    private func executeSearchCommand(_ command: String, parameters: [String: Any]) async throws -> [String: Any] {
        switch command {
        case "web_search":
            let query = parameters["query"] as? String ?? ""
            let maxResults = parameters["max_results"] as? Int ?? 5

            guard !query.isEmpty else {
                throw MCPError.invalidParameters("Search query is required")
            }

            let mockResults = (1...maxResults).map { index in
                [
                    "title": "Result \(index) for '\(query)'",
                    "url": "https://example.com/result\(index)",
                    "snippet": "This is a sample search result snippet for query '\(query)'",
                    "relevance_score": Double(maxResults - index + 1) / Double(maxResults),
                ]
            }

            return [
                "success": true,
                "query": query,
                "results": mockResults,
                "count": maxResults,
                "processing_time": latency,
            ]

        default:
            throw MCPError.unsupportedCommand(command)
        }
    }

    // MARK: - AI Provider Commands

    private func executeAICommand(_ command: String, parameters: [String: Any]) async throws -> [String: Any] {
        switch command {
        case "claude_chat", "gpt_chat", "gemini_chat":
            let prompt = parameters["prompt"] as? String ?? ""
            let model = parameters["model"] as? String ?? "default"

            guard !prompt.isEmpty else {
                throw MCPError.invalidParameters("Prompt is required")
            }

            // Generate a mock AI response based on the prompt
            let response = generateMockAIResponse(for: prompt, provider: command.replacingOccurrences(of: "_chat", with: ""))

            return [
                "success": true,
                "response": response,
                "model": model,
                "provider": command.replacingOccurrences(of: "_chat", with: ""),
                "tokens_used": prompt.count / 4, // Rough approximation
                "processing_time": latency,
            ]

        default:
            throw MCPError.unsupportedCommand(command)
        }
    }

    private func generateMockAIResponse(for prompt: String, provider: String) -> String {
        let lowercasePrompt = prompt.lowercased()

        if lowercasePrompt.contains("hello") || lowercasePrompt.contains("hi") {
            return "Hello! I'm your AI assistant powered by \(provider). How can I help you today?"
        } else if lowercasePrompt.contains("document") {
            return "I can help you create documents in various formats including PDF, DOCX, and Markdown. What kind of document would you like me to generate?"
        } else if lowercasePrompt.contains("email") {
            return "I can assist with email management including sending emails, reading your inbox, and organizing messages. What would you like me to do?"
        } else if lowercasePrompt.contains("calendar") {
            return "I can help manage your calendar by creating events, scheduling meetings, and checking your availability. What calendar task can I assist with?"
        } else if lowercasePrompt.contains("search") {
            return "I can perform web searches and research topics for you. What would you like me to search for?"
        } else {
            return "I understand you need assistance with '\(prompt)'. I'm here to help with documents, emails, calendar management, and web searches through the MCP system."
        }
    }
}

// MARK: - MCP Errors

enum MCPError: Error, LocalizedError {
    case serverNotFound(String)
    case serverUnavailable(String)
    case unsupportedCommand(String)
    case invalidParameters(String)
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .serverNotFound(let server):
            return "MCP server '\(server)' not found"
        case .serverUnavailable(let server):
            return "MCP server '\(server)' is not available"
        case .unsupportedCommand(let command):
            return "Unsupported command: '\(command)'"
        case .invalidParameters(let message):
            return "Invalid parameters: \(message)"
        case .executionFailed(let message):
            return "Command execution failed: \(message)"
        }
    }
}
