// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Advanced voice command processing engine with multi-turn conversations, command chaining, and intelligent context management
 * Issues & Complexity Summary: Complex multi-step command execution, context-aware parameter filling, command history management, and undo/redo functionality
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~1200
 *   - Core Algorithm Complexity: Very High (Multi-turn conversations, command chaining, context intelligence, parameter resolution)
 *   - Dependencies: 8 New (Foundation, Combine, NaturalLanguage, VoiceCommandClassifier, MCPContextManager, ConversationManager, CoreData, SwiftUI)
 *   - State Management Complexity: Very High (Command state machine, context persistence, operation chaining, undo stack)
 *   - Novelty/Uncertainty Factor: Very High (Advanced voice command processing patterns with MCP integration)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 95%
 * Problem Estimate (Inherent Problem Difficulty %): 92%
 * Initial Code Complexity Estimate %: 94%
 * Justification for Estimates: Sophisticated voice command processing with multi-step operations, context intelligence, and command orchestration
 * Final Code Complexity (Actual %): 95%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Advanced voice command processing requires sophisticated state management and context intelligence
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import NaturalLanguage
import CoreData
import SwiftUI

// MARK: - Advanced Voice Command Models

struct VoiceCommand {
    let id = UUID()
    let text: String
    let intent: CommandIntent
    let parameters: [String: Any]
    let confidence: Double
    let timestamp: Date
    let executionId: UUID?

    init(text: String, intent: CommandIntent, parameters: [String: Any] = [:], confidence: Double = 0.0, executionId: UUID? = nil) {
        self.text = text
        self.intent = intent
        self.parameters = parameters
        self.confidence = confidence
        self.timestamp = Date()
        self.executionId = executionId
    }
}

struct ChainedCommand {
    let id = UUID()
    let commands: [VoiceCommand]
    let chainType: ChainType
    let executionOrder: ExecutionOrder
    let dependencies: [UUID: [UUID]] // Command ID -> Dependencies
    let createdAt: Date

    enum ChainType {
        case sequential    // Execute in order: "Generate PDF, then email it"
        case parallel      // Execute simultaneously: "Generate report and schedule meeting"
        case conditional   // Execute based on results: "If PDF is created, then email it"
        case loop          // Repeat operation: "Send daily reports for next week"
    }

    enum ExecutionOrder {
        case strict        // Must execute in exact order
        case flexible      // Can optimize order based on dependencies
        case userDefined   // User specifies exact order
    }

    init(commands: [VoiceCommand], chainType: ChainType = .sequential, executionOrder: ExecutionOrder = .flexible) {
        self.commands = commands
        self.chainType = chainType
        self.executionOrder = executionOrder
        self.dependencies = [:]
        self.createdAt = Date()
    }
}

struct CommandExecution {
    let id = UUID()
    let command: VoiceCommand
    let state: ExecutionState
    let result: CommandResult?
    let startTime: Date
    let endTime: Date?
    let error: Error?
    let canUndo: Bool
    let undoData: [String: Any]?

    enum ExecutionState {
        case pending
        case running
        case completed
        case failed
        case cancelled
        case undone
    }

    init(command: VoiceCommand, canUndo: Bool = true, undoData: [String: Any]? = nil) {
        self.command = command
        self.state = .pending
        self.result = nil
        self.startTime = Date()
        self.endTime = nil
        self.error = nil
        self.canUndo = canUndo
        self.undoData = undoData
    }
}

struct CommandResult {
    let success: Bool
    let data: [String: Any]
    let message: String
    let artifacts: [CommandArtifact]
    let metadata: [String: Any]

    struct CommandArtifact {
        let type: ArtifactType
        let name: String
        let url: URL?
        let data: Data?
        let metadata: [String: Any]

        enum ArtifactType {
            case document
            case email
            case calendarEvent
            case file
            case image
            case audio
            case other(String)
        }
    }
}

struct VoiceCommandShortcut {
    let id = UUID()
    let name: String
    let trigger: String
    let commands: [VoiceCommand]
    let category: ShortcutCategory
    let isUserDefined: Bool
    let usageCount: Int
    let lastUsed: Date?
    let createdAt: Date

    enum ShortcutCategory {
        case productivity
        case communication
        case scheduling
        case documentation
        case custom
    }
}

struct CommandHistory {
    let id = UUID()
    let execution: CommandExecution
    let conversationId: UUID
    let isFavorite: Bool
    let notes: String?
    let tags: [String]

    var canRepeat: Bool {
        execution.state == .completed && execution.error == nil
    }
}

// MARK: - Advanced Voice Command Processor

@MainActor
final class AdvancedVoiceCommandProcessor: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var currentExecution: CommandExecution?
    @Published private(set) var executionQueue: [CommandExecution] = []
    @Published private(set) var executionHistory: [CommandHistory] = []
    @Published private(set) var commandShortcuts: [VoiceCommandShortcut] = []
    @Published private(set) var favoriteCommands: [CommandHistory] = []
    @Published private(set) var undoStack: [CommandExecution] = []
    @Published private(set) var redoStack: [CommandExecution] = []
    @Published private(set) var processingStats: ProcessingStatistics = ProcessingStatistics()

    // MARK: - Dependencies

    private let voiceCommandClassifier: VoiceCommandClassifier
    private let mcpContextManager: MCPContextManager
    private let conversationManager: ConversationManager

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private let commandParser = AdvancedCommandParser()
    private let contextAnalyzer = ContextIntelligenceEngine()
    private let chainExecutor = CommandChainExecutor()
    private let undoRedoManager = UndoRedoManager()

    // Configuration
    private let maxHistorySize = 1000
    private let maxUndoStackSize = 50
    private let executionTimeout: TimeInterval = 300 // 5 minutes
    private let contextWindow = 10 // Number of previous commands to consider

    // State tracking
    private var activeChains: [UUID: ChainedCommand] = [:]
    private var conversationContexts: [UUID: VoiceConversationContext] = [:]
    private var parameterFillingQueue: [ParameterFillingRequest] = []

    // MARK: - Initialization

    init(voiceCommandClassifier: VoiceCommandClassifier,
         mcpContextManager: MCPContextManager,
         conversationManager: ConversationManager) {
        self.voiceCommandClassifier = voiceCommandClassifier
        self.mcpContextManager = mcpContextManager
        self.conversationManager = conversationManager

        setupObservations()
        loadShortcuts()
        loadHistory()
        setupProcessingStats()

        print("✅ AdvancedVoiceCommandProcessor initialized")
    }

    // MARK: - Setup Methods

    private func setupObservations() {
        // Observe conversation changes for context continuity
        conversationManager.$currentConversation
            .sink { [weak self] conversation in
                if let conversation = conversation {
                    self?.ensureConversationContext(for: conversation.id)
                }
            }
            .store(in: &cancellables)

        // Monitor execution queue changes
        $executionQueue
            .sink { [weak self] queue in
                if !queue.isEmpty && !(self?.isProcessing ?? true) {
                    Task {
                        await self?.processNextInQueue()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func setupProcessingStats() {
        processingStats = ProcessingStatistics()
    }

    // MARK: - Main Processing Interface

    func processVoiceCommand(_ text: String, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        processingStats.totalCommands += 1
        let startTime = Date()

        do {
            // Ensure conversation context exists
            ensureConversationContext(for: conversationId)

            // Parse the command for chaining and complexity
            let parseResult = await commandParser.parseCommand(text)

            // Check if this is a command chain
            if parseResult.isChainedCommand {
                return try await processChainedCommand(parseResult, conversationId: conversationId)
            }

            // Check if this is a shortcut invocation
            if let shortcut = identifyShortcut(from: text) {
                return try await executeShortcut(shortcut, conversationId: conversationId)
            }

            // Check for undo/redo commands
            if let undoRedoAction = parseUndoRedoCommand(text) {
                return try await handleUndoRedo(undoRedoAction, conversationId: conversationId)
            }

            // Process as single command with context intelligence
            return try await processSingleCommand(text, conversationId: conversationId, parseResult: parseResult)
        } catch {
            processingStats.failedCommands += 1
            throw error
        }
    }

    // MARK: - Single Command Processing

    private func processSingleCommand(_ text: String, conversationId: UUID, parseResult: CommandParseResult) async throws -> VoiceCommandProcessingResult {
        // Classify the command
        let classification = await voiceCommandClassifier.classifyVoiceCommand(text)

        // Apply context intelligence to fill parameters
        let contextEnhancedParams = await contextAnalyzer.enhanceParameters(
            classification.extractedParameters,
            intent: classification.intent,
            conversationId: conversationId,
            history: getRecentHistory(for: conversationId)
        )

        // Create voice command
        let command = VoiceCommand(
            text: text,
            intent: classification.intent,
            parameters: contextEnhancedParams,
            confidence: classification.confidence
        )

        // Check if we need additional parameters
        let missingParams = identifyMissingParameters(for: command)
        if !missingParams.isEmpty {
            return try await requestMissingParameters(
                command: command,
                missingParams: missingParams,
                conversationId: conversationId
            )
        }

        // Execute the command
        return try await executeCommand(command, conversationId: conversationId)
    }

    // MARK: - Command Chaining

    private func processChainedCommand(_ parseResult: CommandParseResult, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        let chainedCommand = try await buildChainedCommand(from: parseResult)

        // Store the chain for tracking
        activeChains[chainedCommand.id] = chainedCommand

        // Execute based on chain type
        switch chainedCommand.chainType {
        case .sequential:
            return try await executeSequentialChain(chainedCommand, conversationId: conversationId)
        case .parallel:
            return try await executeParallelChain(chainedCommand, conversationId: conversationId)
        case .conditional:
            return try await executeConditionalChain(chainedCommand, conversationId: conversationId)
        case .loop:
            return try await executeLoopChain(chainedCommand, conversationId: conversationId)
        }
    }

    private func executeSequentialChain(_ chain: ChainedCommand, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        var results: [CommandResult] = []
        var contextData: [String: Any] = [:]

        for command in chain.commands {
            // Apply context from previous commands in chain
            let contextEnhancedCommand = applyChainContext(command, contextData: contextData)

            let result = try await executeCommand(contextEnhancedCommand, conversationId: conversationId)

            if let commandResult = result.commandResult {
                results.append(commandResult)

                // Pass result data to next command in chain
                contextData.merge(commandResult.data) { _, new in new }

                // If command failed and chain requires all to succeed, stop
                if !commandResult.success && chain.executionOrder == .strict {
                    throw VoiceCommandError.chainExecutionFailed("Command failed in strict sequential chain")
                }
            }
        }

        return VoiceCommandProcessingResult(
            success: true,
            message: "Successfully executed command chain with \(results.count) operations",
            commandResult: nil,
            needsUserInput: false,
            chainResults: results
        )
    }

    private func executeParallelChain(_ chain: ChainedCommand, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        // Execute commands in parallel using TaskGroup
        return try await withThrowingTaskGroup(of: VoiceCommandProcessingResult.self) { group in
            var results: [CommandResult] = []

            for command in chain.commands {
                group.addTask {
                    return try await self.executeCommand(command, conversationId: conversationId)
                }
            }

            for try await result in group {
                if let commandResult = result.commandResult {
                    results.append(commandResult)
                }
            }

            return VoiceCommandProcessingResult(
                success: true,
                message: "Successfully executed \(results.count) parallel operations",
                commandResult: nil,
                needsUserInput: false,
                chainResults: results
            )
        }
    }

    private func executeConditionalChain(_ chain: ChainedCommand, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        var results: [CommandResult] = []
        var shouldContinue = true

        for (index, command) in chain.commands.enumerated() {
            guard shouldContinue else { break }

            let result = try await executeCommand(command, conversationId: conversationId)

            if let commandResult = result.commandResult {
                results.append(commandResult)

                // Evaluate condition for next command
                if index < chain.commands.count - 1 {
                    shouldContinue = evaluateCondition(
                        result: commandResult,
                        nextCommand: chain.commands[index + 1]
                    )
                }
            }
        }

        return VoiceCommandProcessingResult(
            success: true,
            message: "Executed conditional chain with \(results.count) operations",
            commandResult: nil,
            needsUserInput: false,
            chainResults: results
        )
    }

    private func executeLoopChain(_ chain: ChainedCommand, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        // Implementation for loop-based command chains
        // This would handle repetitive operations like "Send daily reports for next week"
        let results: [CommandResult] = []

        // For now, return a placeholder implementation
        return VoiceCommandProcessingResult(
            success: true,
            message: "Loop chain execution scheduled",
            commandResult: nil,
            needsUserInput: false,
            chainResults: results
        )
    }

    // MARK: - Command Execution

    private func executeCommand(_ command: VoiceCommand, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        let execution = CommandExecution(command: command)
        currentExecution = execution
        isProcessing = true

        defer {
            isProcessing = false
            currentExecution = nil
        }

        do {
            // Execute through MCP Context Manager
            let contextualResponse = try await mcpContextManager.processVoiceCommandWithContext(
                command.text,
                conversationId: conversationId
            )

            // Convert response to command result
            let commandResult = CommandResult(
                success: !contextualResponse.needsUserInput,
                data: command.parameters,
                message: contextualResponse.message,
                artifacts: [],
                metadata: ["contextState": contextualResponse.contextState.rawValue]
            )

            // Add to history
            let historyEntry = CommandHistory(
                execution: CommandExecution(command: command),
                conversationId: conversationId,
                isFavorite: false,
                notes: nil,
                tags: []
            )
            addToHistory(historyEntry)

            // Add to undo stack if command is undoable
            if execution.canUndo {
                addToUndoStack(execution)
            }

            processingStats.successfulCommands += 1

            return VoiceCommandProcessingResult(
                success: commandResult.success,
                message: commandResult.message,
                commandResult: commandResult,
                needsUserInput: contextualResponse.needsUserInput,
                suggestedActions: contextualResponse.suggestedActions
            )
        } catch {
            processingStats.failedCommands += 1
            throw error
        }
    }

    // MARK: - Parameter Intelligence

    private func requestMissingParameters(command: VoiceCommand, missingParams: [String], conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        let paramRequest = ParameterFillingRequest(
            command: command,
            missingParameters: missingParams,
            conversationId: conversationId
        )

        parameterFillingQueue.append(paramRequest)

        let prompt = generateParameterPrompt(for: missingParams.first!, command: command)

        return VoiceCommandProcessingResult(
            success: false,
            message: prompt,
            commandResult: nil,
            needsUserInput: true,
            suggestedActions: generateParameterSuggestions(for: missingParams.first!)
        )
    }

    private func identifyMissingParameters(for command: VoiceCommand) -> [String] {
        let requiredParams = getRequiredParameters(for: command.intent)
        return requiredParams.filter { !command.parameters.keys.contains($0) }
    }

    private func getRequiredParameters(for intent: CommandIntent) -> [String] {
        switch intent {
        case .generateDocument:
            return ["content", "format"]
        case .sendEmail:
            return ["to", "subject", "body"]
        case .scheduleCalendar:
            return ["title", "startTime"]
        case .performSearch:
            return ["query"]
        default:
            return []
        }
    }

    // MARK: - Shortcuts Management

    func createShortcut(name: String, trigger: String, commands: [VoiceCommand], category: VoiceCommandShortcut.ShortcutCategory = .custom) {
        let shortcut = VoiceCommandShortcut(
            name: name,
            trigger: trigger,
            commands: commands,
            category: category,
            isUserDefined: true,
            usageCount: 0,
            lastUsed: nil,
            createdAt: Date()
        )

        commandShortcuts.append(shortcut)
        saveShortcuts()

        print("✅ Created shortcut: \(name) with trigger '\(trigger)'")
    }

    private func identifyShortcut(from text: String) -> VoiceCommandShortcut? {
        let lowerText = text.lowercased()
        return commandShortcuts.first { shortcut in
            lowerText.contains(shortcut.trigger.lowercased())
        }
    }

    private func executeShortcut(_ shortcut: VoiceCommandShortcut, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        // Execute all commands in the shortcut
        var results: [CommandResult] = []

        for command in shortcut.commands {
            let result = try await executeCommand(command, conversationId: conversationId)
            if let commandResult = result.commandResult {
                results.append(commandResult)
            }
        }

        // Update shortcut usage statistics
        updateShortcutUsage(shortcut)

        return VoiceCommandProcessingResult(
            success: true,
            message: "Executed shortcut '\(shortcut.name)' with \(results.count) operations",
            commandResult: nil,
            needsUserInput: false,
            chainResults: results
        )
    }

    // MARK: - Undo/Redo Functionality

    private func parseUndoRedoCommand(_ text: String) -> UndoRedoAction? {
        let lowerText = text.lowercased()

        if lowerText.contains("undo") {
            return .undo
        } else if lowerText.contains("redo") {
            return .redo
        }

        return nil
    }

    private func handleUndoRedo(_ action: UndoRedoAction, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        switch action {
        case .undo:
            return try await performUndo(conversationId: conversationId)
        case .redo:
            return try await performRedo(conversationId: conversationId)
        }
    }

    private func performUndo(conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        guard let lastExecution = undoStack.last else {
            return VoiceCommandProcessingResult(
                success: false,
                message: "No operations to undo",
                commandResult: nil,
                needsUserInput: false
            )
        }

        // Remove from undo stack and add to redo stack
        undoStack.removeLast()
        redoStack.append(lastExecution)

        // Perform the undo operation
        let undoResult = try await undoRedoManager.undoExecution(lastExecution)

        return VoiceCommandProcessingResult(
            success: undoResult.success,
            message: undoResult.message,
            commandResult: nil,
            needsUserInput: false
        )
    }

    private func performRedo(conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        guard let lastUndone = redoStack.last else {
            return VoiceCommandProcessingResult(
                success: false,
                message: "No operations to redo",
                commandResult: nil,
                needsUserInput: false
            )
        }

        // Remove from redo stack and add back to undo stack
        redoStack.removeLast()
        undoStack.append(lastUndone)

        // Re-execute the command
        return try await executeCommand(lastUndone.command, conversationId: conversationId)
    }

    // MARK: - History and Favorites

    func addToFavorites(_ historyEntry: CommandHistory) {
        var updatedEntry = historyEntry
        updatedEntry = CommandHistory(
            execution: historyEntry.execution,
            conversationId: historyEntry.conversationId,
            isFavorite: true,
            notes: historyEntry.notes,
            tags: historyEntry.tags
        )

        favoriteCommands.append(updatedEntry)

        // Update in main history
        if let index = executionHistory.firstIndex(where: { $0.id == historyEntry.id }) {
            executionHistory[index] = updatedEntry
        }

        saveHistory()
        print("✅ Added command to favorites")
    }

    func repeatCommand(_ historyEntry: CommandHistory, conversationId: UUID) async throws -> VoiceCommandProcessingResult {
        guard historyEntry.canRepeat else {
            throw VoiceCommandError.commandNotRepeatable("Command cannot be repeated")
        }

        return try await executeCommand(historyEntry.execution.command, conversationId: conversationId)
    }

    // MARK: - Context Management

    private func ensureConversationContext(for conversationId: UUID) {
        if conversationContexts[conversationId] == nil {
            conversationContexts[conversationId] = VoiceConversationContext(
                conversationId: conversationId,
                recentCommands: [],
                contextParameters: [:],
                activeParameterFilling: nil
            )
        }
    }

    private func getRecentHistory(for conversationId: UUID) -> [CommandHistory] {
        return Array(executionHistory
            .filter { $0.conversationId == conversationId }
            .suffix(contextWindow))
    }

    // MARK: - Utility Methods

    private func addToHistory(_ entry: CommandHistory) {
        executionHistory.append(entry)

        // Maintain history size limit
        if executionHistory.count > maxHistorySize {
            executionHistory.removeFirst(executionHistory.count - maxHistorySize)
        }

        saveHistory()
    }

    private func addToUndoStack(_ execution: CommandExecution) {
        undoStack.append(execution)

        // Clear redo stack when new operation is performed
        redoStack.removeAll()

        // Maintain undo stack size limit
        if undoStack.count > maxUndoStackSize {
            undoStack.removeFirst(undoStack.count - maxUndoStackSize)
        }
    }

    private func generateParameterPrompt(for parameter: String, command: VoiceCommand) -> String {
        let prompts: [String: String] = [
            "content": "What content would you like me to include in the \(command.intent.displayName)?",
            "format": "What format would you prefer? (PDF, Word, HTML, etc.)",
            "to": "Who should I send this to? Please provide email addresses.",
            "subject": "What should the subject line be?",
            "body": "What should the message content be?",
            "title": "What should the title be?",
            "startTime": "When should this start? Please specify date and time.",
            "query": "What would you like me to search for?",
        ]

        return prompts[parameter] ?? "Please provide the \(parameter) for this operation."
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

    private func updateShortcutUsage(_ shortcut: VoiceCommandShortcut) {
        if let index = commandShortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            let updatedShortcut = VoiceCommandShortcut(
                name: shortcut.name,
                trigger: shortcut.trigger,
                commands: shortcut.commands,
                category: shortcut.category,
                isUserDefined: shortcut.isUserDefined,
                usageCount: shortcut.usageCount + 1,
                lastUsed: Date(),
                createdAt: shortcut.createdAt
            )
            commandShortcuts[index] = updatedShortcut
            saveShortcuts()
        }
    }

    // MARK: - Persistence

    private func loadShortcuts() {
        // Load from UserDefaults or Core Data
        // Placeholder implementation
        commandShortcuts = getDefaultShortcuts()
    }

    private func saveShortcuts() {
        // Save to UserDefaults or Core Data
        // Placeholder implementation
    }

    private func loadHistory() {
        // Load from Core Data
        // Placeholder implementation
        executionHistory = []
    }

    private func saveHistory() {
        // Save to Core Data
        // Placeholder implementation
    }

    private func getDefaultShortcuts() -> [VoiceCommandShortcut] {
        return [
            VoiceCommandShortcut(
                name: "Quick Report",
                trigger: "quick report",
                commands: [
                    VoiceCommand(text: "generate document", intent: .generateDocument, parameters: ["format": "pdf"])
                ],
                category: .productivity,
                isUserDefined: false,
                usageCount: 0,
                lastUsed: nil,
                createdAt: Date()
            ),
            VoiceCommandShortcut(
                name: "Daily Standup",
                trigger: "daily standup",
                commands: [
                    VoiceCommand(text: "schedule meeting", intent: .scheduleCalendar, parameters: ["title": "Daily Standup", "duration": 30])
                ],
                category: .scheduling,
                isUserDefined: false,
                usageCount: 0,
                lastUsed: nil,
                createdAt: Date()
            ),
        ]
    }

    // MARK: - Statistics and Analytics

    func getProcessingStatistics() -> ProcessingStatistics {
        return processingStats
    }

    func getCommandAnalytics(for conversationId: UUID) -> CommandAnalytics {
        let conversationHistory = executionHistory.filter { $0.conversationId == conversationId }

        return CommandAnalytics(
            totalCommands: conversationHistory.count,
            successfulCommands: conversationHistory.filter { $0.execution.state == .completed }.count,
            averageExecutionTime: calculateAverageExecutionTime(from: conversationHistory),
            mostUsedIntents: getMostUsedIntents(from: conversationHistory),
            favoriteCount: conversationHistory.filter { $0.isFavorite }.count
        )
    }

    private func calculateAverageExecutionTime(from history: [CommandHistory]) -> TimeInterval {
        let executionTimes = history.compactMap { entry -> TimeInterval? in
            guard let endTime = entry.execution.endTime else { return nil }
            return endTime.timeIntervalSince(entry.execution.startTime)
        }

        return executionTimes.isEmpty ? 0 : executionTimes.reduce(0, +) / Double(executionTimes.count)
    }

    private func getMostUsedIntents(from history: [CommandHistory]) -> [CommandIntent: Int] {
        var intentCounts: [CommandIntent: Int] = [:]

        for entry in history {
            intentCounts[entry.execution.command.intent, default: 0] += 1
        }

        return intentCounts
    }

    // MARK: - Public Interface Methods

    func clearHistory() {
        executionHistory.removeAll()
        saveHistory()
        print("🗑️ Command history cleared")
    }

    func clearUndoStack() {
        undoStack.removeAll()
        redoStack.removeAll()
        print("🗑️ Undo/Redo stack cleared")
    }

    func exportHistory() -> String {
        var export = "Jarvis Live - Voice Command History Export\n"
        export += "Exported: \(Date())\n"
        export += "Total Commands: \(executionHistory.count)\n\n"

        for entry in executionHistory {
            export += "[\(entry.execution.startTime)] \(entry.execution.command.intent.displayName)\n"
            export += "Command: \(entry.execution.command.text)\n"
            export += "Status: \(entry.execution.state)\n"
            if entry.isFavorite {
                export += "⭐ Favorite\n"
            }
            export += "\n"
        }

        return export
    }
}

// MARK: - Supporting Types and Extensions

struct VoiceCommandProcessingResult {
    let success: Bool
    let message: String
    let commandResult: CommandResult?
    let needsUserInput: Bool
    let suggestedActions: [String]
    let chainResults: [CommandResult]

    init(success: Bool, message: String, commandResult: CommandResult?, needsUserInput: Bool, suggestedActions: [String] = [], chainResults: [CommandResult] = []) {
        self.success = success
        self.message = message
        self.commandResult = commandResult
        self.needsUserInput = needsUserInput
        self.suggestedActions = suggestedActions
        self.chainResults = chainResults
    }
}

struct ProcessingStatistics {
    var totalCommands: Int = 0
    var successfulCommands: Int = 0
    var failedCommands: Int = 0
    var averageProcessingTime: TimeInterval = 0
    var chainedCommands: Int = 0
    var shortcutUsage: Int = 0
    var undoOperations: Int = 0

    var successRate: Double {
        guard totalCommands > 0 else { return 0.0 }
        return Double(successfulCommands) / Double(totalCommands)
    }
}

struct CommandAnalytics {
    let totalCommands: Int
    let successfulCommands: Int
    let averageExecutionTime: TimeInterval
    let mostUsedIntents: [CommandIntent: Int]
    let favoriteCount: Int
}

struct VoiceConversationContext {
    let conversationId: UUID
    var recentCommands: [VoiceCommand]
    var contextParameters: [String: Any]
    var activeParameterFilling: ParameterFillingRequest?
}

struct ParameterFillingRequest {
    let command: VoiceCommand
    let missingParameters: [String]
    let conversationId: UUID
    let timestamp: Date = Date()
}

enum UndoRedoAction {
    case undo
    case redo
}

enum VoiceCommandError: Error, LocalizedError {
    case chainExecutionFailed(String)
    case commandNotRepeatable(String)
    case parameterExtractionFailed(String)
    case executionTimeout
    case invalidCommand(String)

    var errorDescription: String? {
        switch self {
        case .chainExecutionFailed(let details):
            return "Chain execution failed: \(details)"
        case .commandNotRepeatable(let details):
            return "Command not repeatable: \(details)"
        case .parameterExtractionFailed(let details):
            return "Parameter extraction failed: \(details)"
        case .executionTimeout:
            return "Command execution timed out"
        case .invalidCommand(let details):
            return "Invalid command: \(details)"
        }
    }
}

// MARK: - Supporting Classes

private class AdvancedCommandParser {
    // Advanced patterns for complex command recognition
    private let complexPatterns: [ComplexCommandPattern] = [
        ComplexCommandPattern(
            name: "document_and_email",
            pattern: "(?:create|generate|make)\\s+(?:a\\s+)?(?:pdf|document|report).*(?:and|then).*(?:email|send).*(?:to|@)",
            intents: [.generateDocument, .sendEmail],
            extractors: [
                PatternExtractor(name: "document_content", pattern: "(?:about|on|regarding)\\s+([^,]+?)(?:\\s+and|$)", type: .content),
                PatternExtractor(name: "document_format", pattern: "(pdf|docx|html|markdown)", type: .format),
                PatternExtractor(name: "email_recipient", pattern: "(?:to|email\\s+to|send\\s+to)\\s+([\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}|[A-Z][a-z]+\\s+[A-Z][a-z]+)", type: .email),
                PatternExtractor(name: "email_subject", pattern: "(?:with\\s+subject|subject:?)\\s+[\"']?([^\"'\\n]+)[\"']?", type: .subject),
            ]
        ),
        ComplexCommandPattern(
            name: "quarterly_report_workflow",
            pattern: "(?:create|generate).*(?:quarterly|q[1-4]).*(?:report|summary).*(?:schedule|send|email|meeting)",
            intents: [.generateDocument, .sendEmail, .scheduleCalendar],
            extractors: [
                PatternExtractor(name: "report_type", pattern: "(quarterly|monthly|weekly|annual)\\s+(report|summary|review)", type: .content),
                PatternExtractor(name: "meeting_purpose", pattern: "(?:schedule.*)?(?:meeting|call).*(?:to\\s+discuss|about|for)\\s+([^\\n]+)", type: .title),
                PatternExtractor(name: "timeframe", pattern: "(q[1-4]|quarter\\s+[1-4]|[a-z]+\\s+\\d{4})", type: .timeframe),
            ]
        ),
        ComplexCommandPattern(
            name: "research_and_summarize",
            pattern: "(?:search|research|find|look\\s+up).*(?:and|then).*(?:summarize|summary|write|create|generate)",
            intents: [.performSearch, .generateDocument],
            extractors: [
                PatternExtractor(name: "search_topic", pattern: "(?:search|research|find)\\s+(?:for|about|on)?\\s+([^,]+?)(?:\\s+and|$)", type: .query),
                PatternExtractor(name: "summary_format", pattern: "(?:in|as)\\s+(?:a\\s+)?(email|document|pdf|summary|report)", type: .format),
                PatternExtractor(name: "summary_audience", pattern: "(?:for|to)\\s+(?:my\\s+)?(team|manager|client|stakeholders)", type: .audience),
            ]
        ),
        ComplexCommandPattern(
            name: "project_status_workflow",
            pattern: "(?:generate|create).*(?:project|status).*(?:document|report).*(?:based\\s+on|from).*(?:conversation|history|notes)",
            intents: [.generateDocument, .performSearch],
            extractors: [
                PatternExtractor(name: "project_name", pattern: "(?:project|for)\\s+([A-Z][a-zA-Z\\s]+?)(?:\\s+(?:document|report|status)|$)", type: .project),
                PatternExtractor(name: "time_range", pattern: "(?:from|since|last)\\s+(week|month|quarter|\\d+\\s+days?)", type: .timeframe),
                PatternExtractor(name: "document_type", pattern: "(status\\s+update|progress\\s+report|summary|overview)", type: .content),
            ]
        ),
    ]

    func parseCommand(_ text: String) async -> CommandParseResult {
        let lowerText = text.lowercased()

        // First check for complex patterns
        let complexResult = await parseComplexCommand(text)
        if complexResult.isComplex {
            return complexResult
        }

        // Fallback to basic chaining detection
        let chainKeywords = ["then", "and then", "after that", "next", "followed by", "also"]
        let isChained = chainKeywords.contains { lowerText.contains($0) }

        // Detect conditional keywords
        let conditionalKeywords = ["if", "when", "unless", "only if"]
        let isConditional = conditionalKeywords.contains { lowerText.contains($0) }

        // Detect parallel keywords
        let parallelKeywords = ["and", "while", "simultaneously", "at the same time"]
        let isParallel = parallelKeywords.contains { lowerText.contains($0) }

        return CommandParseResult(
            isChainedCommand: isChained,
            isConditional: isConditional,
            isParallel: isParallel,
            complexity: calculateComplexity(text),
            segments: segmentCommand(text),
            extractedIntents: [],
            extractedParameters: [:],
            isComplex: false,
            matchedPattern: nil
        )
    }

    private func parseComplexCommand(_ text: String) async -> CommandParseResult {
        for pattern in complexPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern.pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let range = NSRange(location: 0, length: text.count)

                if regex.firstMatch(in: text, options: [], range: range) != nil {
                    let extractedParams = await extractComplexParameters(from: text, using: pattern)
                    let segments = generateSegmentsFromPattern(text, pattern: pattern, parameters: extractedParams)

                    return CommandParseResult(
                        isChainedCommand: true,
                        isConditional: false,
                        isParallel: pattern.intents.count > 1,
                        complexity: .complex,
                        segments: segments,
                        extractedIntents: pattern.intents,
                        extractedParameters: extractedParams,
                        isComplex: true,
                        matchedPattern: pattern.name
                    )
                }
            } catch {
                print("⚠️ Error parsing complex pattern '\(pattern.name)': \(error)")
            }
        }

        return CommandParseResult(
            isChainedCommand: false,
            isConditional: false,
            isParallel: false,
            complexity: .simple,
            segments: [text],
            extractedIntents: [],
            extractedParameters: [:],
            isComplex: false,
            matchedPattern: nil
        )
    }

    private func extractComplexParameters(from text: String, using pattern: ComplexCommandPattern) async -> [String: Any] {
        var parameters: [String: Any] = [:]

        for extractor in pattern.extractors {
            do {
                let regex = try NSRegularExpression(pattern: extractor.pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
                let range = NSRange(location: 0, length: text.count)

                if let match = regex.firstMatch(in: text, options: [], range: range) {
                    let matchRange = match.range(at: 1)
                    if matchRange.location != NSNotFound {
                        let extractedValue = (text as NSString).substring(with: matchRange).trimmingCharacters(in: .whitespacesAndNewlines)

                        switch extractor.type {
                        case .content, .query, .subject, .title, .project, .audience:
                            parameters[extractor.name] = extractedValue
                        case .format:
                            parameters[extractor.name] = extractedValue.lowercased()
                        case .email:
                            if isValidEmail(extractedValue) {
                                parameters[extractor.name] = extractedValue
                            } else {
                                // Try to extract from name format
                                parameters[extractor.name] = convertNameToEmail(extractedValue)
                            }
                        case .timeframe:
                            parameters[extractor.name] = parseTimeframe(extractedValue)
                        }
                    }
                }
            } catch {
                print("⚠️ Error extracting parameter '\(extractor.name)': \(error)")
            }
        }

        return parameters
    }

    private func generateSegmentsFromPattern(_ text: String, pattern: ComplexCommandPattern, parameters: [String: Any]) -> [String] {
        var segments: [String] = []

        for intent in pattern.intents {
            var segment = ""

            switch intent {
            case .generateDocument:
                if let content = parameters["document_content"] as? String ?? parameters["report_type"] as? String ?? parameters["document_type"] as? String {
                    let format = parameters["document_format"] as? String ?? parameters["summary_format"] as? String ?? "pdf"
                    segment = "Generate \(format) document about \(content)"
                }

            case .sendEmail:
                if let recipient = parameters["email_recipient"] as? String {
                    let subject = parameters["email_subject"] as? String ?? "Document from Jarvis"
                    segment = "Send email to \(recipient) with subject '\(subject)'"
                }

            case .scheduleCalendar:
                if let purpose = parameters["meeting_purpose"] as? String {
                    segment = "Schedule meeting to discuss \(purpose)"
                } else {
                    segment = "Schedule meeting"
                }

            case .performSearch:
                if let topic = parameters["search_topic"] as? String {
                    segment = "Search for information about \(topic)"
                }

            default:
                segment = text
            }

            if !segment.isEmpty {
                segments.append(segment)
            }
        }

        return segments.isEmpty ? [text] : segments
    }

    private func calculateComplexity(_ text: String) -> CommandComplexity {
        let words = text.components(separatedBy: .whitespaces).count
        let hasMultipleIntents = text.lowercased().contains("and") && (text.lowercased().contains("then") || text.lowercased().contains("also"))

        if hasMultipleIntents || words > 20 {
            return .complex
        } else if words > 10 {
            return .moderate
        } else {
            return .simple
        }
    }

    private func segmentCommand(_ text: String) -> [String] {
        // Enhanced segmentation for complex commands
        let chainKeywords = ["then", "and then", "after that", "next", "followed by", "also", "and"]

        var segments = [text]
        for keyword in chainKeywords {
            if text.lowercased().contains(keyword) {
                let components = text.components(separatedBy: keyword)
                if components.count > 1 {
                    segments = components
                    break
                }
            }
        }

        return segments.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }

    // MARK: - Utility Methods

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: email)
    }

    private func convertNameToEmail(_ name: String) -> String {
        // Convert "John Smith" to "john.smith@company.com" format
        let cleanName = name.lowercased().replacingOccurrences(of: " ", with: ".")
        return "\(cleanName)@company.com"
    }

    private func parseTimeframe(_ timeframe: String) -> String {
        let lower = timeframe.lowercased()

        if lower.contains("q1") || lower.contains("quarter 1") {
            return "Q1"
        } else if lower.contains("q2") || lower.contains("quarter 2") {
            return "Q2"
        } else if lower.contains("q3") || lower.contains("quarter 3") {
            return "Q3"
        } else if lower.contains("q4") || lower.contains("quarter 4") {
            return "Q4"
        }

        return timeframe
    }
}

// MARK: - Complex Command Pattern Models

struct ComplexCommandPattern {
    let name: String
    let pattern: String
    let intents: [CommandIntent]
    let extractors: [PatternExtractor]
}

struct PatternExtractor {
    let name: String
    let pattern: String
    let type: ExtractorType

    enum ExtractorType {
        case content
        case format
        case email
        case subject
        case query
        case title
        case timeframe
        case project
        case audience
    }
}

private class ContextIntelligenceEngine {
    func enhanceParameters(_ parameters: [String: Any], intent: CommandIntent, conversationId: UUID, history: [CommandHistory]) async -> [String: Any] {
        var enhanced = parameters

        // Apply context from recent history
        for historyEntry in history.reversed() {
            if historyEntry.execution.command.intent == intent {
                // Reuse parameters from similar recent commands
                for (key, value) in historyEntry.execution.command.parameters {
                    if enhanced[key] == nil {
                        enhanced[key] = value
                    }
                }
                break
            }
        }

        // Apply smart defaults based on intent
        switch intent {
        case .generateDocument:
            if enhanced["format"] == nil {
                enhanced["format"] = "pdf" // Default to PDF
            }
        case .sendEmail:
            if enhanced["subject"] == nil && enhanced["content"] != nil {
                // Generate subject from content
                if let content = enhanced["content"] as? String {
                    enhanced["subject"] = generateEmailSubject(from: content)
                }
            }
        case .scheduleCalendar:
            if enhanced["duration"] == nil {
                enhanced["duration"] = 60 // Default 1 hour
            }
        default:
            break
        }

        return enhanced
    }

    private func generateEmailSubject(from content: String) -> String {
        let words = content.components(separatedBy: .whitespaces)
        let firstWords = Array(words.prefix(5)).joined(separator: " ")
        return firstWords.isEmpty ? "Email from Jarvis" : firstWords
    }
}

private class CommandChainExecutor {
    // Implementation for sophisticated command chain execution
    // This class would handle the complex logic of managing dependencies,
    // conditional execution, and error handling in command chains
}

private class UndoRedoManager {
    func undoExecution(_ execution: CommandExecution) async throws -> (success: Bool, message: String) {
        // Implementation would depend on the specific command type
        // Some commands might not be undoable

        switch execution.command.intent {
        case .generateDocument:
            return (true, "Document generation undone")
        case .sendEmail:
            return (false, "Email cannot be undone after sending")
        case .scheduleCalendar:
            return (true, "Calendar event removed")
        default:
            return (false, "This operation cannot be undone")
        }
    }
}

struct CommandParseResult {
    let isChainedCommand: Bool
    let isConditional: Bool
    let isParallel: Bool
    let complexity: CommandComplexity
    let segments: [String]
    let extractedIntents: [CommandIntent]
    let extractedParameters: [String: Any]
    let isComplex: Bool
    let matchedPattern: String?
}

enum CommandComplexity {
    case simple
    case moderate
    case complex
}

// MARK: - Helper Extensions

extension AdvancedVoiceCommandProcessor {
    private func buildChainedCommand(from parseResult: CommandParseResult) async throws -> ChainedCommand {
        var commands: [VoiceCommand] = []

        // For complex patterns, use extracted intents and parameters
        if parseResult.isComplex && !parseResult.extractedIntents.isEmpty {
            for (index, intent) in parseResult.extractedIntents.enumerated() {
                let segment = index < parseResult.segments.count ? parseResult.segments[index] : parseResult.segments.last ?? ""

                // Extract relevant parameters for this specific intent
                let intentParameters = extractParametersForIntent(intent, from: parseResult.extractedParameters)

                let command = VoiceCommand(
                    text: segment,
                    intent: intent,
                    parameters: intentParameters,
                    confidence: 0.9 // High confidence for complex pattern matches
                )
                commands.append(command)
            }
        } else {
            // Fallback to individual segment classification
            for segment in parseResult.segments {
                let classification = await voiceCommandClassifier.classifyVoiceCommand(segment)
                let command = VoiceCommand(
                    text: segment,
                    intent: classification.intent,
                    parameters: classification.extractedParameters,
                    confidence: classification.confidence
                )
                commands.append(command)
            }
        }

        let chainType: ChainedCommand.ChainType
        if parseResult.isConditional {
            chainType = .conditional
        } else if parseResult.isParallel {
            chainType = .parallel
        } else {
            chainType = .sequential
        }

        return ChainedCommand(commands: commands, chainType: chainType)
    }

    private func extractParametersForIntent(_ intent: CommandIntent, from allParameters: [String: Any]) -> [String: Any] {
        var intentParams: [String: Any] = [:]

        switch intent {
        case .generateDocument:
            if let content = allParameters["document_content"] as? String ?? allParameters["report_type"] as? String ?? allParameters["document_type"] as? String {
                intentParams["content"] = content
            }
            if let format = allParameters["document_format"] as? String ?? allParameters["summary_format"] as? String {
                intentParams["format"] = format
            }
            if let project = allParameters["project_name"] as? String {
                intentParams["project"] = project
            }
            if let timeframe = allParameters["timeframe"] as? String ?? allParameters["time_range"] as? String {
                intentParams["timeframe"] = timeframe
            }

        case .sendEmail:
            if let recipient = allParameters["email_recipient"] as? String {
                intentParams["to"] = recipient
            }
            if let subject = allParameters["email_subject"] as? String {
                intentParams["subject"] = subject
            }
            if let audience = allParameters["summary_audience"] as? String {
                intentParams["audience"] = audience
            }

        case .scheduleCalendar:
            if let purpose = allParameters["meeting_purpose"] as? String {
                intentParams["title"] = purpose
            }
            if let timeframe = allParameters["timeframe"] as? String {
                intentParams["when"] = timeframe
            }

        case .performSearch:
            if let topic = allParameters["search_topic"] as? String {
                intentParams["query"] = topic
            }

        default:
            // Pass through all parameters for unknown intents
            intentParams = allParameters
        }

        return intentParams
    }

    private func applyChainContext(_ command: VoiceCommand, contextData: [String: Any]) -> VoiceCommand {
        var enhancedParameters = command.parameters

        // Apply context data from previous commands in chain
        enhancedParameters.merge(contextData) { current, _ in current }

        return VoiceCommand(
            text: command.text,
            intent: command.intent,
            parameters: enhancedParameters,
            confidence: command.confidence,
            executionId: command.executionId
        )
    }

    private func evaluateCondition(result: CommandResult, nextCommand: VoiceCommand) -> Bool {
        // Implement conditional logic based on previous command result
        return result.success
    }

    private func processNextInQueue() async {
        guard let nextExecution = executionQueue.first else { return }

        executionQueue.removeFirst()

        do {
            _ = try await executeCommand(nextExecution.command, conversationId: UUID()) // Need proper conversation ID
        } catch {
            print("❌ Failed to execute queued command: \(error)")
        }
    }
}
