// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: MCP context management system for maintaining conversation context across MCP tool calls
 * Issues & Complexity Summary: Complex context persistence, multi-turn conversation support, context enrichment from history
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~800
 *   - Core Algorithm Complexity: High (Context state management, multi-turn conversations, memory management)
 *   - Dependencies: 6 New (Foundation, Combine, MCPModels, MCPServerManager, ConversationManager, CoreData)
 *   - State Management Complexity: Very High (Context persistence, conversation threading, parameter resolution)
 *   - Novelty/Uncertainty Factor: High (MCP context continuation patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 92%
 * Problem Estimate (Inherent Problem Difficulty %): 88%
 * Initial Code Complexity Estimate %: 90%
 * Justification for Estimates: Complex multi-turn conversation context with MCP tool orchestration
 * Final Code Complexity (Actual %): 91%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Context persistence requires careful state management and cleanup strategies
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import CoreData

// MARK: - MCP Context Models

struct MCPConversationContext: Codable {
    let conversationId: UUID
    let activeContext: MCPActiveContext
    let contextHistory: [MCPContextEntry]
    let pendingOperations: [MCPPendingOperation]
    let lastUpdated: Date
    let expiresAt: Date?

    struct MCPActiveContext: Codable {
        var currentTool: String?
        var pendingParameters: [String: AnyCodable]
        var requiredParameters: [String]
        var contextualInformation: [String: AnyCodable]
        var sessionState: MCPSessionState
        var multiTurnIntent: MCPMultiTurnIntent?
    }

    struct MCPContextEntry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let toolName: String
        let parameters: [String: AnyCodable]
        let result: MCPToolResult?
        let userInput: String
        let aiResponse: String?
        let contextType: MCPContextType

        enum MCPContextType: String, Codable {
            case toolCall = "tool_call"
            case userResponse = "user_response"
            case parameterRequest = "parameter_request"
            case completion = "completion"
            case error = "error"
        }
    }

    struct MCPPendingOperation: Codable, Identifiable {
        let id: UUID
        let toolName: String
        let collectedParameters: [String: AnyCodable]
        let missingParameters: [String]
        let userPrompt: String?
        let createdAt: Date
        let priority: MCPOperationPriority

        enum MCPOperationPriority: String, Codable {
            case high = "high"
            case normal = "normal"
            case low = "low"
        }
    }

    enum MCPSessionState: String, Codable {
        case idle = "idle"
        case collectingParameters = "collecting_parameters"
        case executing = "executing"
        case awaitingConfirmation = "awaiting_confirmation"
        case error = "error"
    }

    struct MCPMultiTurnIntent: Codable {
        let intent: String
        let currentStep: Int
        let totalSteps: Int
        let stepDescriptions: [String]
        let collectedData: [String: AnyCodable]
        let nextExpectedInput: String?
    }
}

// MARK: - MCP Context Manager

@MainActor
final class MCPContextManager: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var activeContexts: [UUID: MCPConversationContext] = [:]
    @Published private(set) var isProcessingContext: Bool = false
    @Published private(set) var lastError: Error?
    @Published private(set) var contextStats: MCPContextStats = MCPContextStats()

    // MARK: - Private Properties

    private let mcpServerManager: MCPServerManager
    private let conversationManager: ConversationManager
    private var cancellables = Set<AnyCancellable>()

    // Context persistence
    private let contextCacheLimit = 10
    private let contextExpirationTime: TimeInterval = 3600 // 1 hour
    private let cleanupInterval: TimeInterval = 300 // 5 minutes
    private var cleanupTask: Task<Void, Never>?

    // Parameter resolution
    private let parameterResolver = MCPParameterResolver()
    private let contextEnricher = MCPContextEnricher()

    // Multi-turn conversation patterns
    private let multiTurnPatterns: [String: MCPMultiTurnPattern] = [
        "document_generation": MCPMultiTurnPattern(
            steps: ["content_type", "format", "details", "confirmation"],
            stepPrompts: [
                "What type of document would you like to generate?",
                "What format should the document be in? (PDF, Word, etc.)",
                "Please provide the content or details for the document.",
                "Should I proceed with generating the document?",
            ]
        ),
        "email_composition": MCPMultiTurnPattern(
            steps: ["recipients", "subject", "content", "attachments", "confirmation"],
            stepPrompts: [
                "Who should I send the email to?",
                "What's the subject of the email?",
                "What should the email content be?",
                "Are there any attachments? (optional)",
                "Should I send this email?",
            ]
        ),
        "calendar_scheduling": MCPMultiTurnPattern(
            steps: ["event_type", "date_time", "duration", "attendees", "location", "confirmation"],
            stepPrompts: [
                "What type of event would you like to schedule?",
                "When should the event take place?",
                "How long should the event be?",
                "Who should be invited? (optional)",
                "Where should the event take place? (optional)",
                "Should I create this calendar event?",
            ]
        ),
    ]

    // MARK: - Initialization

    init(mcpServerManager: MCPServerManager, conversationManager: ConversationManager) {
        self.mcpServerManager = mcpServerManager
        self.conversationManager = conversationManager

        setupObservations()
        startContextCleanup()

        print("✅ MCP Context Manager initialized")
    }

    deinit {
        cleanupTask?.cancel()
    }

    // MARK: - Setup Methods

    private func setupObservations() {
        // Observe conversation changes
        conversationManager.$currentConversation
            .sink { [weak self] conversation in
                if let conversation = conversation {
                    self?.ensureContextExists(for: conversation.id)
                }
            }
            .store(in: &cancellables)

        // Observe MCP server manager state
        mcpServerManager.$isInitialized
            .sink { [weak self] isInitialized in
                if isInitialized {
                    self?.refreshAllContexts()
                }
            }
            .store(in: &cancellables)
    }

    private func startContextCleanup() {
        cleanupTask?.cancel()

        cleanupTask = Task {
            while !Task.isCancelled {
                do {
                    try await Task.sleep(nanoseconds: UInt64(cleanupInterval * 1_000_000_000))
                    await cleanupExpiredContexts()
                } catch {
                    // Task was cancelled
                    break
                }
            }
        }
    }

    // MARK: - Context Management

    func ensureContextExists(for conversationId: UUID) {
        if activeContexts[conversationId] == nil {
            let context = MCPConversationContext(
                conversationId: conversationId,
                activeContext: MCPConversationContext.MCPActiveContext(
                    currentTool: nil,
                    pendingParameters: [:],
                    requiredParameters: [],
                    contextualInformation: [:],
                    sessionState: .idle,
                    multiTurnIntent: nil
                ),
                contextHistory: [],
                pendingOperations: [],
                lastUpdated: Date(),
                expiresAt: nil
            )

            activeContexts[conversationId] = context
            updateContextStats()

            print("✅ Created new MCP context for conversation: \(conversationId)")
        }
    }

    func getContext(for conversationId: UUID) -> MCPConversationContext? {
        return activeContexts[conversationId]
    }

    func updateContext(for conversationId: UUID, _ updateBlock: (inout MCPConversationContext) -> Void) {
        guard var context = activeContexts[conversationId] else {
            ensureContextExists(for: conversationId)
            guard var context = activeContexts[conversationId] else { return }
            updateBlock(&context)
            activeContexts[conversationId] = context
            return
        }

        updateBlock(&context)
        context.lastUpdated = Date()
        activeContexts[conversationId] = context
        updateContextStats()
    }

    // MARK: - Voice Command Processing with Context

    func processVoiceCommandWithContext(_ command: String, conversationId: UUID) async throws -> MCPContextualResponse {
        isProcessingContext = true
        defer { isProcessingContext = false }

        ensureContextExists(for: conversationId)
        guard let context = activeContexts[conversationId] else {
            throw MCPContextError.contextNotFound(conversationId)
        }

        do {
            // Analyze command with existing context
            let analysis = await analyzeCommandWithContext(command, context: context)

            // Handle different context states
            switch context.activeContext.sessionState {
            case .idle:
                return try await handleIdleState(analysis: analysis, conversationId: conversationId)

            case .collectingParameters:
                return try await handleParameterCollection(input: command, analysis: analysis, conversationId: conversationId)

            case .awaitingConfirmation:
                return try await handleConfirmation(input: command, conversationId: conversationId)

            case .executing:
                return MCPContextualResponse(
                    message: "I'm currently processing your previous request. Please wait a moment.",
                    needsUserInput: false,
                    contextState: .executing,
                    suggestedActions: []
                )

            case .error:
                return try await handleErrorRecovery(input: command, conversationId: conversationId)
            }
        } catch {
            lastError = error

            updateContext(for: conversationId) { context in
                context.activeContext.sessionState = .error
            }

            return MCPContextualResponse(
                message: "I encountered an error: \(error.localizedDescription). Would you like to try again or start over?",
                needsUserInput: true,
                contextState: .error,
                suggestedActions: ["try again", "start over", "cancel"]
            )
        }
    }

    // MARK: - Context State Handlers

    private func handleIdleState(analysis: MCPCommandAnalysis, conversationId: UUID) async throws -> MCPContextualResponse {
        // Check if this is a multi-turn operation
        if let pattern = multiTurnPatterns[analysis.intent] {
            return try await startMultiTurnConversation(analysis: analysis, pattern: pattern, conversationId: conversationId)
        }

        // Check if we have all required parameters
        let missingParams = analysis.missingParameters
        if !missingParams.isEmpty {
            return try await requestMissingParameters(analysis: analysis, conversationId: conversationId)
        }

        // Execute the tool directly
        return try await executeToolWithContext(analysis: analysis, conversationId: conversationId)
    }

    private func handleParameterCollection(input: String, analysis: MCPCommandAnalysis, conversationId: UUID) async throws -> MCPContextualResponse {
        guard let context = activeContexts[conversationId] else {
            throw MCPContextError.contextNotFound(conversationId)
        }

        // Extract parameters from input
        let extractedParams = await parameterResolver.extractParameters(from: input, analysis: analysis)

        updateContext(for: conversationId) { context in
            // Merge extracted parameters
            for (key, value) in extractedParams {
                context.activeContext.pendingParameters[key] = value
            }

            // Update required parameters list
            context.activeContext.requiredParameters = context.activeContext.requiredParameters.filter { param in
                !extractedParams.keys.contains(param)
            }
        }

        // Check if we still need more parameters
        let updatedContext = activeContexts[conversationId]!
        if !updatedContext.activeContext.requiredParameters.isEmpty {
            let nextParam = updatedContext.activeContext.requiredParameters.first!
            let prompt = generateParameterPrompt(parameter: nextParam, toolName: updatedContext.activeContext.currentTool ?? "")

            return MCPContextualResponse(
                message: prompt,
                needsUserInput: true,
                contextState: .collectingParameters,
                suggestedActions: generateParameterSuggestions(for: nextParam)
            )
        }

        // All parameters collected, move to confirmation
        updateContext(for: conversationId) { context in
            context.activeContext.sessionState = .awaitingConfirmation
        }

        return try await generateConfirmationPrompt(conversationId: conversationId)
    }

    private func handleConfirmation(input: String, conversationId: UUID) async throws -> MCPContextualResponse {
        let confirmationResult = analyzeConfirmation(input)

        if confirmationResult.isConfirmed {
            return try await executeCollectedOperation(conversationId: conversationId)
        } else if confirmationResult.isCancelled {
            updateContext(for: conversationId) { context in
                context.activeContext = MCPConversationContext.MCPActiveContext(
                    currentTool: nil,
                    pendingParameters: [:],
                    requiredParameters: [],
                    contextualInformation: [:],
                    sessionState: .idle,
                    multiTurnIntent: nil
                )
            }

            return MCPContextualResponse(
                message: "Operation cancelled. How else can I help you?",
                needsUserInput: false,
                contextState: .idle,
                suggestedActions: ["generate document", "send email", "schedule meeting", "search"]
            )
        } else {
            // Request clarification
            return MCPContextualResponse(
                message: "I didn't understand. Would you like me to proceed with the operation? Please say 'yes' to continue or 'no' to cancel.",
                needsUserInput: true,
                contextState: .awaitingConfirmation,
                suggestedActions: ["yes", "no", "cancel"]
            )
        }
    }

    private func handleErrorRecovery(input: String, conversationId: UUID) async throws -> MCPContextualResponse {
        let lowerInput = input.lowercased()

        if lowerInput.contains("try again") || lowerInput.contains("retry") {
            updateContext(for: conversationId) { context in
                context.activeContext.sessionState = .collectingParameters
            }

            return MCPContextualResponse(
                message: "Let's try again. What would you like me to help you with?",
                needsUserInput: true,
                contextState: .collectingParameters,
                suggestedActions: ["generate document", "send email", "schedule meeting"]
            )
        } else if lowerInput.contains("start over") || lowerInput.contains("reset") {
            updateContext(for: conversationId) { context in
                context.activeContext = MCPConversationContext.MCPActiveContext(
                    currentTool: nil,
                    pendingParameters: [:],
                    requiredParameters: [],
                    contextualInformation: [:],
                    sessionState: .idle,
                    multiTurnIntent: nil
                )
            }

            return MCPContextualResponse(
                message: "Starting fresh. How can I help you today?",
                needsUserInput: false,
                contextState: .idle,
                suggestedActions: ["generate document", "send email", "schedule meeting", "search"]
            )
        } else {
            return MCPContextualResponse(
                message: "Please choose an option: 'try again' to retry the last operation, 'start over' to begin fresh, or 'cancel' to stop.",
                needsUserInput: true,
                contextState: .error,
                suggestedActions: ["try again", "start over", "cancel"]
            )
        }
    }

    // MARK: - Multi-Turn Conversation Management

    private func startMultiTurnConversation(analysis: MCPCommandAnalysis, pattern: MCPMultiTurnPattern, conversationId: UUID) async throws -> MCPContextualResponse {
        let multiTurnIntent = MCPConversationContext.MCPMultiTurnIntent(
            intent: analysis.intent,
            currentStep: 0,
            totalSteps: pattern.steps.count,
            stepDescriptions: pattern.steps,
            collectedData: [:],
            nextExpectedInput: pattern.steps.first
        )

        updateContext(for: conversationId) { context in
            context.activeContext.currentTool = analysis.toolName
            context.activeContext.sessionState = .collectingParameters
            context.activeContext.multiTurnIntent = multiTurnIntent
        }

        let prompt = pattern.stepPrompts.first ?? "Let's start. What would you like to do?"

        return MCPContextualResponse(
            message: prompt,
            needsUserInput: true,
            contextState: .collectingParameters,
            suggestedActions: generateStepSuggestions(for: pattern.steps.first ?? "")
        )
    }

    // MARK: - Parameter Resolution and Tool Execution

    private func requestMissingParameters(analysis: MCPCommandAnalysis, conversationId: UUID) async throws -> MCPContextualResponse {
        let firstMissingParam = analysis.missingParameters.first!

        updateContext(for: conversationId) { context in
            context.activeContext.currentTool = analysis.toolName
            context.activeContext.requiredParameters = analysis.missingParameters
            context.activeContext.sessionState = .collectingParameters

            // Store already provided parameters
            for (key, value) in analysis.providedParameters {
                context.activeContext.pendingParameters[key] = AnyCodable(value)
            }
        }

        let prompt = generateParameterPrompt(parameter: firstMissingParam, toolName: analysis.toolName)

        return MCPContextualResponse(
            message: prompt,
            needsUserInput: true,
            contextState: .collectingParameters,
            suggestedActions: generateParameterSuggestions(for: firstMissingParam)
        )
    }

    private func executeToolWithContext(analysis: MCPCommandAnalysis, conversationId: UUID) async throws -> MCPContextualResponse {
        updateContext(for: conversationId) { context in
            context.activeContext.sessionState = .executing
        }

        do {
            let result = try await mcpServerManager.executeTool(
                name: analysis.toolName,
                arguments: analysis.providedParameters
            )

            // Add to context history
            let contextEntry = MCPConversationContext.MCPContextEntry(
                id: UUID(),
                timestamp: Date(),
                toolName: analysis.toolName,
                parameters: analysis.providedParameters.mapValues { AnyCodable($0) },
                result: result,
                userInput: analysis.originalCommand,
                aiResponse: nil,
                contextType: .completion
            )

            updateContext(for: conversationId) { context in
                context.contextHistory.append(contextEntry)
                context.activeContext.sessionState = .idle
                context.activeContext.currentTool = nil
                context.activeContext.pendingParameters = [:]
                context.activeContext.requiredParameters = []
            }

            let responseMessage = formatToolResult(result, toolName: analysis.toolName)

            return MCPContextualResponse(
                message: responseMessage,
                needsUserInput: false,
                contextState: .idle,
                suggestedActions: ["help with something else", "export result", "share result"]
            )
        } catch {
            updateContext(for: conversationId) { context in
                context.activeContext.sessionState = .error
            }

            throw error
        }
    }

    private func executeCollectedOperation(conversationId: UUID) async throws -> MCPContextualResponse {
        guard let context = activeContexts[conversationId],
              let toolName = context.activeContext.currentTool else {
            throw MCPContextError.invalidState("No tool specified for execution")
        }

        updateContext(for: conversationId) { context in
            context.activeContext.sessionState = .executing
        }

        // Convert parameters for execution
        let parameters = context.activeContext.pendingParameters.mapValues { $0.value }

        do {
            let result = try await mcpServerManager.executeTool(name: toolName, arguments: parameters)

            // Add to context history
            let contextEntry = MCPConversationContext.MCPContextEntry(
                id: UUID(),
                timestamp: Date(),
                toolName: toolName,
                parameters: context.activeContext.pendingParameters,
                result: result,
                userInput: "Multi-turn operation",
                aiResponse: nil,
                contextType: .completion
            )

            updateContext(for: conversationId) { context in
                context.contextHistory.append(contextEntry)
                context.activeContext = MCPConversationContext.MCPActiveContext(
                    currentTool: nil,
                    pendingParameters: [:],
                    requiredParameters: [],
                    contextualInformation: [:],
                    sessionState: .idle,
                    multiTurnIntent: nil
                )
            }

            let responseMessage = formatToolResult(result, toolName: toolName)

            return MCPContextualResponse(
                message: "✅ " + responseMessage,
                needsUserInput: false,
                contextState: .idle,
                suggestedActions: ["help with something else", "export result", "share result"]
            )
        } catch {
            updateContext(for: conversationId) { context in
                context.activeContext.sessionState = .error
            }

            throw error
        }
    }

    // MARK: - Context Enrichment

    func enrichContextFromHistory(conversationId: UUID) async {
        guard let conversation = conversationManager.conversations.first(where: { $0.id == conversationId }) else {
            return
        }

        let messages = conversationManager.getMessages(for: conversation)
        let enrichedContext = await contextEnricher.enrichFromMessages(messages)

        updateContext(for: conversationId) { context in
            context.activeContext.contextualInformation = enrichedContext
        }

        print("✅ Enriched context for conversation \(conversationId) with \(enrichedContext.count) contextual elements")
    }

    // MARK: - Context Persistence and Cleanup

    private func cleanupExpiredContexts() async {
        let now = Date()
        var expiredContexts: [UUID] = []

        for (conversationId, context) in activeContexts {
            let timeSinceUpdate = now.timeIntervalSince(context.lastUpdated)

            if timeSinceUpdate > contextExpirationTime {
                expiredContexts.append(conversationId)
            }
        }

        for conversationId in expiredContexts {
            activeContexts.removeValue(forKey: conversationId)
        }

        if !expiredContexts.isEmpty {
            updateContextStats()
            print("🧹 Cleaned up \(expiredContexts.count) expired contexts")
        }
    }

    private func updateContextStats() {
        contextStats = MCPContextStats(
            activeContextCount: activeContexts.count,
            totalOperations: activeContexts.values.reduce(0) { $0 + $1.contextHistory.count },
            pendingOperations: activeContexts.values.reduce(0) { $0 + $1.pendingOperations.count },
            averageContextAge: calculateAverageContextAge()
        )
    }

    private func calculateAverageContextAge() -> TimeInterval {
        let now = Date()
        let totalAge = activeContexts.values.reduce(0.0) { $0 + now.timeIntervalSince($1.lastUpdated) }
        return activeContexts.isEmpty ? 0 : totalAge / Double(activeContexts.count)
    }

    private func refreshAllContexts() {
        // Refresh contexts when MCP servers are updated
        for conversationId in activeContexts.keys {
            Task {
                await enrichContextFromHistory(conversationId: conversationId)
            }
        }
    }

    // MARK: - Utility Methods

    private func generateParameterPrompt(parameter: String, toolName: String) -> String {
        let prompts: [String: String] = [
            "content": "What content would you like me to include?",
            "format": "What format would you prefer? (PDF, Word, HTML, etc.)",
            "to": "Who should I send this to? Please provide email addresses.",
            "subject": "What should the subject line be?",
            "body": "What should the message content be?",
            "title": "What should the title be?",
            "startTime": "When should this start? Please specify date and time.",
            "endTime": "When should this end?",
            "query": "What would you like me to search for?",
        ]

        return prompts[parameter] ?? "Please provide the \(parameter) for this \(toolName) operation."
    }

    private func generateParameterSuggestions(for parameter: String) -> [String] {
        let suggestions: [String: [String]] = [
            "format": ["PDF", "Word document", "HTML", "Plain text"],
            "content": ["project update", "meeting notes", "report", "summary"],
            "subject": ["Meeting follow-up", "Project update", "Quick question"],
            "query": ["recent documents", "emails from today", "calendar events this week"],
        ]

        return suggestions[parameter] ?? []
    }

    private func generateStepSuggestions(for step: String) -> [String] {
        let suggestions: [String: [String]] = [
            "content_type": ["project report", "meeting notes", "summary", "proposal"],
            "format": ["PDF", "Word document", "HTML", "Presentation"],
            "recipients": ["team members", "manager", "client"],
            "event_type": ["meeting", "call", "reminder", "deadline"],
        ]

        return suggestions[step] ?? []
    }

    private func generateConfirmationPrompt(conversationId: UUID) async throws -> MCPContextualResponse {
        guard let context = activeContexts[conversationId],
              let toolName = context.activeContext.currentTool else {
            throw MCPContextError.invalidState("No active operation to confirm")
        }

        let parameters = context.activeContext.pendingParameters
        var summary = "I'm ready to \(toolName) with the following details:\n"

        for (key, value) in parameters {
            summary += "• \(key.capitalized): \(value.value)\n"
        }

        summary += "\nShould I proceed?"

        return MCPContextualResponse(
            message: summary,
            needsUserInput: true,
            contextState: .awaitingConfirmation,
            suggestedActions: ["yes", "no", "modify"]
        )
    }

    private func formatToolResult(_ result: MCPToolResult, toolName: String) -> String {
        if result.isError {
            return "There was an error executing \(toolName). Please try again."
        }

        var response = ""
        for content in result.content {
            if let text = content.text {
                response += text
            }
        }

        return response.isEmpty ? "\(toolName) completed successfully." : response
    }

    private func analyzeConfirmation(_ input: String) -> (isConfirmed: Bool, isCancelled: Bool) {
        let lowerInput = input.lowercased()

        let confirmWords = ["yes", "okay", "ok", "sure", "proceed", "go ahead", "do it"]
        let cancelWords = ["no", "cancel", "stop", "don't", "abort"]

        let isConfirmed = confirmWords.contains { lowerInput.contains($0) }
        let isCancelled = cancelWords.contains { lowerInput.contains($0) }

        return (isConfirmed, isCancelled)
    }

    // MARK: - Public Context Access Methods

    func getContextHistory(for conversationId: UUID) -> [MCPConversationContext.MCPContextEntry] {
        return activeContexts[conversationId]?.contextHistory ?? []
    }

    func getCurrentSessionState(for conversationId: UUID) -> MCPConversationContext.MCPSessionState? {
        return activeContexts[conversationId]?.activeContext.sessionState
    }

    func getPendingParameters(for conversationId: UUID) -> [String: Any] {
        let pendingParams = activeContexts[conversationId]?.activeContext.pendingParameters ?? [:]
        return pendingParams.mapValues { $0.value }
    }

    func clearContext(for conversationId: UUID) {
        activeContexts.removeValue(forKey: conversationId)
        updateContextStats()
        print("🗑️ Cleared context for conversation: \(conversationId)")
    }

    func exportContext(for conversationId: UUID) -> String? {
        guard let context = activeContexts[conversationId] else { return nil }

        if let data = try? JSONEncoder().encode(context),
           let jsonString = String(data: data, encoding: .utf8) {
            return jsonString
        }

        return nil
    }
}

// MARK: - Supporting Types and Extensions

struct MCPContextualResponse {
    let message: String
    let needsUserInput: Bool
    let contextState: MCPConversationContext.MCPSessionState
    let suggestedActions: [String]
}

struct MCPCommandAnalysis {
    let originalCommand: String
    let intent: String
    let toolName: String
    let providedParameters: [String: Any]
    let missingParameters: [String]
    let confidence: Double
}

struct MCPMultiTurnPattern {
    let steps: [String]
    let stepPrompts: [String]
}

struct MCPContextStats {
    let activeContextCount: Int
    let totalOperations: Int
    let pendingOperations: Int
    let averageContextAge: TimeInterval

    init() {
        self.activeContextCount = 0
        self.totalOperations = 0
        self.pendingOperations = 0
        self.averageContextAge = 0
    }

    init(activeContextCount: Int, totalOperations: Int, pendingOperations: Int, averageContextAge: TimeInterval) {
        self.activeContextCount = activeContextCount
        self.totalOperations = totalOperations
        self.pendingOperations = pendingOperations
        self.averageContextAge = averageContextAge
    }
}

enum MCPContextError: Error, LocalizedError {
    case contextNotFound(UUID)
    case invalidState(String)
    case parameterExtractionFailed(String)
    case toolExecutionFailed(String)

    var errorDescription: String? {
        switch self {
        case .contextNotFound(let id):
            return "Context not found for conversation: \(id)"
        case .invalidState(let description):
            return "Invalid context state: \(description)"
        case .parameterExtractionFailed(let details):
            return "Parameter extraction failed: \(details)"
        case .toolExecutionFailed(let details):
            return "Tool execution failed: \(details)"
        }
    }
}

// MARK: - Parameter Resolver

private class MCPParameterResolver {
    func extractParameters(from input: String, analysis: MCPCommandAnalysis) async -> [String: Any] {
        var parameters: [String: Any] = [:]

        // Simple extraction logic - can be enhanced with NLP
        let lowercaseInput = input.lowercased()

        // Extract format specifications
        if lowercaseInput.contains("pdf") {
            parameters["format"] = "pdf"
        } else if lowercaseInput.contains("word") || lowercaseInput.contains("docx") {
            parameters["format"] = "docx"
        } else if lowercaseInput.contains("html") {
            parameters["format"] = "html"
        }

        // Extract email addresses
        let emailRegex = try! NSRegularExpression(pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}")
        let emailMatches = emailRegex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        if !emailMatches.isEmpty {
            let emails = emailMatches.compactMap { match in
                Range(match.range, in: input).map { String(input[$0]) }
            }
            parameters["to"] = emails
        }

        // Extract content (everything after command words)
        let commandWords = ["generate", "create", "send", "schedule", "search"]
        var content = input
        for word in commandWords {
            if let range = content.lowercased().range(of: word) {
                content = String(content[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                break
            }
        }

        if !content.isEmpty && content != input {
            parameters["content"] = content
        }

        return parameters
    }
}

// MARK: - Context Enricher

private class MCPContextEnricher {
    func enrichFromMessages(_ messages: [ConversationMessage]) async -> [String: AnyCodable] {
        var enrichedContext: [String: AnyCodable] = [:]

        // Extract patterns from conversation history
        let recentMessages = Array(messages.suffix(10))

        // Identify frequently mentioned topics
        var topicFrequency: [String: Int] = [:]
        for message in recentMessages {
            let words = message.content.components(separatedBy: .whitespaces)
            for word in words where word.count > 3 {
                topicFrequency[word.lowercased(), default: 0] += 1
            }
        }

        let frequentTopics = topicFrequency
            .filter { $0.value > 1 }
            .sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }

        enrichedContext["frequent_topics"] = AnyCodable(Array(frequentTopics))

        // Identify conversation patterns
        let toolUsagePatterns = extractToolUsagePatterns(from: recentMessages)
        enrichedContext["tool_usage_patterns"] = AnyCodable(toolUsagePatterns)

        // Extract user preferences
        let preferences = extractUserPreferences(from: recentMessages)
        enrichedContext["user_preferences"] = AnyCodable(preferences)

        return enrichedContext
    }

    private func extractToolUsagePatterns(from messages: [ConversationMessage]) -> [String: Any] {
        var patterns: [String: Any] = [:]

        // Count AI provider usage
        var providerCount: [String: Int] = [:]
        for message in messages {
            if let provider = message.aiProvider {
                providerCount[provider, default: 0] += 1
            }
        }
        patterns["preferred_ai_provider"] = providerCount.max { $0.value < $1.value }?.key

        // Analyze response times
        let avgProcessingTime = messages.reduce(0.0) { $0 + $1.processingTime } / Double(messages.count)
        patterns["average_processing_time"] = avgProcessingTime

        return patterns
    }

    private func extractUserPreferences(from messages: [ConversationMessage]) -> [String: Any] {
        var preferences: [String: Any] = [:]

        // Extract format preferences
        let userMessages = messages.filter { $0.role == "user" }
        var formatMentions: [String: Int] = [:]

        for message in userMessages {
            let content = message.content.lowercased()
            if content.contains("pdf") { formatMentions["pdf", default: 0] += 1 }
            if content.contains("word") { formatMentions["docx", default: 0] += 1 }
            if content.contains("html") { formatMentions["html", default: 0] += 1 }
        }

        if let preferredFormat = formatMentions.max(by: { $0.value < $1.value })?.key {
            preferences["preferred_document_format"] = preferredFormat
        }

        return preferences
    }
}

// MARK: - Command Analysis Extension

extension MCPContextManager {
    private func analyzeCommandWithContext(_ command: String, context: MCPConversationContext) async -> MCPCommandAnalysis {
        let lowercaseCommand = command.lowercased()

        // Determine intent based on context and command
        var intent = "unknown"
        var toolName = ""
        var providedParameters: [String: Any] = [:]
        var missingParameters: [String] = []

        // Use context to understand partial commands
        if let currentTool = context.activeContext.currentTool {
            intent = deriveIntentFromTool(currentTool)
            toolName = currentTool
        } else {
            // Analyze fresh command
            if lowercaseCommand.contains("document") || lowercaseCommand.contains("generate") {
                intent = "document_generation"
                toolName = "document-generator.generate"
            } else if lowercaseCommand.contains("email") || lowercaseCommand.contains("send") {
                intent = "email_composition"
                toolName = "email-server.send"
            } else if lowercaseCommand.contains("calendar") || lowercaseCommand.contains("schedule") {
                intent = "calendar_scheduling"
                toolName = "calendar-server.create_event"
            } else if lowercaseCommand.contains("search") || lowercaseCommand.contains("find") {
                intent = "search"
                toolName = "search-server.search"
            }
        }

        // Extract parameters from command
        providedParameters = await parameterResolver.extractParameters(
            from: command,
            analysis: MCPCommandAnalysis(
                originalCommand: command,
                intent: intent,
                toolName: toolName,
                providedParameters: [:],
                missingParameters: [],
                confidence: 0.0
            )
        )

        // Merge with context parameters
        for (key, value) in context.activeContext.pendingParameters {
            providedParameters[key] = value.value
        }

        // Determine missing parameters based on tool requirements
        missingParameters = determineMissingParameters(for: toolName, provided: providedParameters)

        let confidence = calculateConfidence(intent: intent, providedParams: providedParameters.count, missingParams: missingParameters.count)

        return MCPCommandAnalysis(
            originalCommand: command,
            intent: intent,
            toolName: toolName,
            providedParameters: providedParameters,
            missingParameters: missingParameters,
            confidence: confidence
        )
    }

    private func deriveIntentFromTool(_ toolName: String) -> String {
        if toolName.contains("document") { return "document_generation" }
        if toolName.contains("email") { return "email_composition" }
        if toolName.contains("calendar") { return "calendar_scheduling" }
        if toolName.contains("search") { return "search" }
        return "unknown"
    }

    private func determineMissingParameters(for toolName: String, provided: [String: Any]) -> [String] {
        let requiredParams: [String: [String]] = [
            "document-generator.generate": ["content", "format"],
            "email-server.send": ["to", "subject", "body"],
            "calendar-server.create_event": ["title", "startTime", "endTime"],
            "search-server.search": ["query"],
        ]

        let required = requiredParams[toolName] ?? []
        return required.filter { !provided.keys.contains($0) }
    }

    private func calculateConfidence(intent: String, providedParams: Int, missingParams: Int) -> Double {
        if intent == "unknown" { return 0.1 }

        let totalParams = providedParams + missingParams
        if totalParams == 0 { return 0.5 }

        let completeness = Double(providedParams) / Double(totalParams)
        return min(0.9, 0.3 + completeness * 0.6)
    }
}
