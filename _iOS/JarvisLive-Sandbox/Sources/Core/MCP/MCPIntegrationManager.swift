// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: MCP integration manager that orchestrates context management with conversation flow
 * Issues & Complexity Summary: Complex integration between MCP context, conversation management, and voice processing
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High (Multi-component orchestration, state synchronization)
 *   - Dependencies: 7 New (MCPContextManager, ConversationManager, MCPServerManager, LiveKitManager, etc.)
 *   - State Management Complexity: Very High (Cross-component state management)
 *   - Novelty/Uncertainty Factor: High (Integration orchestration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 88%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 87%
 * Justification for Estimates: Complex multi-component integration with state synchronization
 * Final Code Complexity (Actual %): 89%
 * Overall Result Score (Success & Quality %): 93%
 * Key Variances/Learnings: Integration requires careful state management and error handling
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - MCP Integration Manager

@MainActor
final class MCPIntegrationManager: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var lastResponse: String = ""
    @Published private(set) var currentContextState: MCPConversationContext.MCPSessionState = .idle
    @Published private(set) var suggestedActions: [String] = []
    @Published private(set) var pendingUserInput: String?
    @Published private(set) var lastError: Error?

    // MARK: - Dependencies

    private let mcpContextManager: MCPContextManager
    private let conversationManager: ConversationManager
    private let mcpServerManager: MCPServerManager

    // Optional dependencies for full integration
    private weak var liveKitManager: LiveKitManager?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - State Management

    private var activeConversationId: UUID?
    private let responseQueue = DispatchQueue(label: "com.jarvis.mcp.response", qos: .userInitiated)

    // MARK: - Initialization

    init(
        mcpContextManager: MCPContextManager,
        conversationManager: ConversationManager,
        mcpServerManager: MCPServerManager,
        liveKitManager: LiveKitManager? = nil
    ) {
        self.mcpContextManager = mcpContextManager
        self.conversationManager = conversationManager
        self.mcpServerManager = mcpServerManager
        self.liveKitManager = liveKitManager

        setupObservations()
        print("✅ MCP Integration Manager initialized")
    }

    // MARK: - Setup Methods

    private func setupObservations() {
        // Observe current conversation changes
        conversationManager.$currentConversation
            .sink { [weak self] conversation in
                self?.activeConversationId = conversation?.id
                if let conversationId = conversation?.id {
                    self?.updateContextState(for: conversationId)
                }
            }
            .store(in: &cancellables)

        // Observe MCP context manager state
        mcpContextManager.$isProcessingContext
            .sink { [weak self] isProcessing in
                self?.isProcessing = isProcessing
            }
            .store(in: &cancellables)

        // Observe MCP server manager errors
        mcpServerManager.$lastError
            .sink { [weak self] error in
                if let error = error {
                    self?.lastError = error
                }
            }
            .store(in: &cancellables)
    }

    private func updateContextState(for conversationId: UUID) {
        if let state = mcpContextManager.getCurrentSessionState(for: conversationId) {
            currentContextState = state

            // Update suggested actions based on state
            switch state {
            case .idle:
                suggestedActions = ["generate document", "send email", "schedule meeting", "search"]
            case .collectingParameters:
                suggestedActions = ["provide details", "skip", "cancel"]
            case .awaitingConfirmation:
                suggestedActions = ["yes", "no", "modify"]
            case .executing:
                suggestedActions = ["cancel"]
            case .error:
                suggestedActions = ["try again", "start over", "cancel"]
            }
        }
    }

    // MARK: - Voice Command Processing

    func processVoiceCommand(_ command: String) async -> MCPProcessingResult {
        guard let conversationId = activeConversationId else {
            return MCPProcessingResult(
                response: "Please start a conversation first.",
                needsUserInput: false,
                success: false,
                contextState: .idle
            )
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            // Process with context
            let contextualResponse = try await mcpContextManager.processVoiceCommandWithContext(
                command,
                conversationId: conversationId
            )

            // Update conversation with MCP context
            if let conversation = conversationManager.conversations.first(where: { $0.id == conversationId }) {
                await updateConversationWithMCPResult(
                    conversation: conversation,
                    userInput: command,
                    response: contextualResponse
                )
            }

            // Update UI state
            lastResponse = contextualResponse.message
            currentContextState = contextualResponse.contextState
            suggestedActions = contextualResponse.suggestedActions
            pendingUserInput = contextualResponse.needsUserInput ? "Waiting for user input..." : nil

            // Optional: Trigger text-to-speech
            if let liveKitManager = liveKitManager {
                await liveKitManager.synthesizeAndPlay(text: contextualResponse.message)
            }

            return MCPProcessingResult(
                response: contextualResponse.message,
                needsUserInput: contextualResponse.needsUserInput,
                success: true,
                contextState: contextualResponse.contextState,
                suggestedActions: contextualResponse.suggestedActions
            )
        } catch {
            lastError = error
            let errorMessage = "I encountered an error: \(error.localizedDescription)"

            if let conversation = conversationManager.conversations.first(where: { $0.id == conversationId }) {
                conversationManager.addMessage(
                    to: conversation,
                    content: command,
                    role: .user
                )
                conversationManager.addMessage(
                    to: conversation,
                    content: errorMessage,
                    role: .assistant
                )
            }

            return MCPProcessingResult(
                response: errorMessage,
                needsUserInput: false,
                success: false,
                contextState: .error,
                error: error
            )
        }
    }

    // MARK: - Direct MCP Operations

    func executeDirectMCPOperation(
        toolName: String,
        parameters: [String: Any],
        userContext: String? = nil
    ) async -> MCPProcessingResult {
        guard let conversationId = activeConversationId else {
            return MCPProcessingResult(
                response: "No active conversation for MCP operation.",
                needsUserInput: false,
                success: false,
                contextState: .idle
            )
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await mcpServerManager.executeTool(name: toolName, arguments: parameters)

            let responseMessage = formatMCPResult(result, toolName: toolName)

            // Update conversation
            if let conversation = conversationManager.conversations.first(where: { $0.id == conversationId }) {
                conversationManager.addMCPContextMessage(
                    to: conversation,
                    userInput: userContext ?? "Direct MCP operation: \(toolName)",
                    aiResponse: responseMessage,
                    toolName: toolName,
                    parameters: parameters,
                    result: result
                )

                conversationManager.addMCPHistoryEntry(
                    to: conversation,
                    toolName: toolName,
                    userInput: userContext ?? "Direct operation",
                    parameters: parameters,
                    result: result,
                    success: !result.isError
                )
            }

            lastResponse = responseMessage

            return MCPProcessingResult(
                response: responseMessage,
                needsUserInput: false,
                success: !result.isError,
                contextState: .idle,
                mcpResult: result
            )
        } catch {
            lastError = error
            let errorMessage = "MCP operation failed: \(error.localizedDescription)"

            if let conversation = conversationManager.conversations.first(where: { $0.id == conversationId }) {
                conversationManager.addMCPHistoryEntry(
                    to: conversation,
                    toolName: toolName,
                    userInput: userContext ?? "Direct operation",
                    parameters: parameters,
                    result: nil,
                    success: false
                )
            }

            return MCPProcessingResult(
                response: errorMessage,
                needsUserInput: false,
                success: false,
                contextState: .error,
                error: error
            )
        }
    }

    // MARK: - Context Management Methods

    func getCurrentContextState() -> MCPConversationContext.MCPSessionState {
        return currentContextState
    }

    func getPendingParameters() -> [String: Any] {
        guard let conversationId = activeConversationId else { return [:] }
        return mcpContextManager.getPendingParameters(for: conversationId)
    }

    func getContextHistory() -> [MCPConversationContext.MCPContextEntry] {
        guard let conversationId = activeConversationId else { return [] }
        return mcpContextManager.getContextHistory(for: conversationId)
    }

    func clearCurrentContext() {
        guard let conversationId = activeConversationId else { return }
        mcpContextManager.clearContext(for: conversationId)

        currentContextState = .idle
        suggestedActions = ["generate document", "send email", "schedule meeting", "search"]
        pendingUserInput = nil
        lastResponse = "Context cleared. How can I help you?"

        print("🗑️ Cleared MCP context for current conversation")
    }

    func enrichContextFromHistory() async {
        guard let conversationId = activeConversationId else { return }
        await mcpContextManager.enrichContextFromHistory(conversationId: conversationId)
        print("✨ Enriched context from conversation history")
    }

    // MARK: - Conversation Integration

    private func updateConversationWithMCPResult(
        conversation: Conversation,
        userInput: String,
        response: MCPContextualResponse
    ) async {
        // Add user message
        conversationManager.addMessage(
            to: conversation,
            content: userInput,
            role: .user
        )

        // Add AI response
        conversationManager.addMessage(
            to: conversation,
            content: response.message,
            role: .assistant
        )

        // Store MCP context if applicable
        let contextInfo: [String: Any] = [
            "session_state": response.contextState.rawValue,
            "needs_user_input": response.needsUserInput,
            "suggested_actions": response.suggestedActions,
        ]

        conversationManager.storeMCPContext(contextInfo, for: conversation)
    }

    // MARK: - Utility Methods

    private func formatMCPResult(_ result: MCPToolResult, toolName: String) -> String {
        if result.isError {
            return "❌ \(toolName) failed. Please try again or check your parameters."
        }

        var response = "✅ \(toolName) completed successfully."

        for content in result.content {
            if let text = content.text, !text.isEmpty {
                response = text
                break
            }
        }

        return response
    }

    // MARK: - High-Level Convenience Methods

    func generateDocument(content: String, format: String = "pdf") async -> MCPProcessingResult {
        let parameters: [String: Any] = [
            "content": content,
            "format": format,
        ]

        return await executeDirectMCPOperation(
            toolName: "document-generator.generate",
            parameters: parameters,
            userContext: "Generate \(format.uppercased()) document: \(content.prefix(50))..."
        )
    }

    func sendEmail(to: [String], subject: String, body: String) async -> MCPProcessingResult {
        let parameters: [String: Any] = [
            "to": to,
            "subject": subject,
            "body": body,
        ]

        return await executeDirectMCPOperation(
            toolName: "email-server.send",
            parameters: parameters,
            userContext: "Send email to \(to.joined(separator: ", ")): \(subject)"
        )
    }

    func scheduleEvent(title: String, startTime: Date, endTime: Date, location: String? = nil) async -> MCPProcessingResult {
        var parameters: [String: Any] = [
            "title": title,
            "startTime": startTime,
            "endTime": endTime,
        ]

        if let location = location {
            parameters["location"] = location
        }

        return await executeDirectMCPOperation(
            toolName: "calendar-server.create_event",
            parameters: parameters,
            userContext: "Schedule event: \(title) at \(startTime)"
        )
    }

    func performSearch(query: String, sources: [String]? = nil) async -> MCPProcessingResult {
        var parameters: [String: Any] = [
            "query": query
        ]

        if let sources = sources {
            parameters["sources"] = sources
        }

        return await executeDirectMCPOperation(
            toolName: "search-server.search",
            parameters: parameters,
            userContext: "Search for: \(query)"
        )
    }

    // MARK: - Statistics and Monitoring

    func getIntegrationStats() -> MCPIntegrationStats {
        let contextStats = mcpContextManager.contextStats

        var conversationMCPUsage: [String: Int] = [:]

        for conversation in conversationManager.conversations {
            let mcpHistory = conversationManager.getRecentMCPHistory(for: conversation)
            for entry in mcpHistory {
                conversationMCPUsage[entry.toolName, default: 0] += 1
            }
        }

        return MCPIntegrationStats(
            activeContexts: contextStats.activeContextCount,
            totalMCPOperations: contextStats.totalOperations,
            pendingOperations: contextStats.pendingOperations,
            averageContextAge: contextStats.averageContextAge,
            toolUsageFrequency: conversationMCPUsage,
            currentSessionState: currentContextState,
            isProcessing: isProcessing
        )
    }
}

// MARK: - Supporting Types

struct MCPProcessingResult {
    let response: String
    let needsUserInput: Bool
    let success: Bool
    let contextState: MCPConversationContext.MCPSessionState
    let suggestedActions: [String]
    let mcpResult: MCPToolResult?
    let error: Error?

    init(
        response: String,
        needsUserInput: Bool,
        success: Bool,
        contextState: MCPConversationContext.MCPSessionState,
        suggestedActions: [String] = [],
        mcpResult: MCPToolResult? = nil,
        error: Error? = nil
    ) {
        self.response = response
        self.needsUserInput = needsUserInput
        self.success = success
        self.contextState = contextState
        self.suggestedActions = suggestedActions
        self.mcpResult = mcpResult
        self.error = error
    }
}

struct MCPIntegrationStats {
    let activeContexts: Int
    let totalMCPOperations: Int
    let pendingOperations: Int
    let averageContextAge: TimeInterval
    let toolUsageFrequency: [String: Int]
    let currentSessionState: MCPConversationContext.MCPSessionState
    let isProcessing: Bool
}

// MARK: - Extensions

extension MCPIntegrationManager {
    // Voice processing integration
    func processVoiceTranscription(_ transcription: String, confidence: Double) async -> MCPProcessingResult {
        // Add confidence-based processing
        if confidence < 0.7 {
            return MCPProcessingResult(
                response: "I didn't catch that clearly. Could you please repeat?",
                needsUserInput: true,
                success: false,
                contextState: currentContextState,
                suggestedActions: ["repeat", "type instead"]
            )
        }

        return await processVoiceCommand(transcription)
    }

    // Batch processing for multiple commands
    func processBatchCommands(_ commands: [String]) async -> [MCPProcessingResult] {
        var results: [MCPProcessingResult] = []

        for command in commands {
            let result = await processVoiceCommand(command)
            results.append(result)

            // If a command requires user input, stop batch processing
            if result.needsUserInput {
                break
            }
        }

        return results
    }

    // Context-aware command suggestions
    func getContextualSuggestions() -> [String] {
        switch currentContextState {
        case .idle:
            return ["What can you help me with?", "Generate a document", "Send an email", "Schedule a meeting"]
        case .collectingParameters:
            return ["Provide the missing information", "Skip this step", "Cancel operation"]
        case .awaitingConfirmation:
            return ["Yes, proceed", "No, cancel", "Let me modify this"]
        case .executing:
            return ["Please wait...", "Cancel operation"]
        case .error:
            return ["Try again", "Start over", "Get help"]
        }
    }
}
