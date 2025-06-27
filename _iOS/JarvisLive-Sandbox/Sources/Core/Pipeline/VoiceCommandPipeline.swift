// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Central orchestrator for voice command processing pipeline - TDD implementation
 * Issues & Complexity Summary: Complete voice-to-action pipeline with classification, MCP execution, and response generation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~600
 *   - Core Algorithm Complexity: Very High (Pipeline orchestration, error handling, state management)
 *   - Dependencies: 8 New (Foundation, Combine, VoiceClassificationManager, MCPServerManager, KeychainManager, Models)
 *   - State Management Complexity: Very High (Pipeline states, concurrent processing, metrics tracking)
 *   - Novelty/Uncertainty Factor: High (End-to-end voice command orchestration)
 * AI Pre-Task Self-Assessment: 92%
 * Problem Estimate: 88%
 * Initial Code Complexity Estimate: 90%
 * Final Code Complexity: 93%
 * Overall Result Score: 94%
 * Key Variances/Learnings: Pipeline orchestration requires careful error boundaries and state transitions
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

@MainActor
final class VoiceCommandPipeline: ObservableObject {
    // MARK: - Published Properties

    @Published private(set) var currentState: VoiceCommandPipelineState = .idle
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var lastResult: VoiceCommandPipelineResult?
    @Published private(set) var metrics: VoiceCommandPipelineMetrics = .empty
    @Published private(set) var lastError: Error?

    // MARK: - Dependencies

    private let classificationManager: VoiceClassificationManager
    private let mcpServerManager: any MCPServerManagerProtocol
    private let keychainManager: KeychainManager
    private let configuration: VoiceCommandPipelineConfiguration

    // MARK: - State Management

    private var cancellables = Set<AnyCancellable>()
    private var processingHistory: [VoiceCommandPipelineResult] = []
    private let maxHistorySize = 100

    // Performance tracking
    private var totalProcessedCommands: Int = 0
    private var successfulCommands: Int = 0
    private var processingTimes: [TimeInterval] = []
    private var classificationTimes: [TimeInterval] = []
    private var mcpExecutionTimes: [TimeInterval] = []

    // Concurrent processing management
    private let processingQueue = DispatchQueue(label: "com.jarvis.pipeline.processing", qos: .userInitiated)
    private var activeProcessingTasks = Set<String>()

    // MARK: - Computed Properties

    var publicTotalProcessedCommands: Int {
        return self.totalProcessedCommands
    }

    var averageProcessingTime: TimeInterval {
        guard !processingTimes.isEmpty else { return 0.0 }
        return processingTimes.reduce(0, +) / Double(processingTimes.count)
    }

    var successRate: Double {
        guard totalProcessedCommands > 0 else { return 0.0 }
        return Double(successfulCommands) / Double(totalProcessedCommands)
    }

    // MARK: - Initialization

    @MainActor
    init(
        classificationManager: VoiceClassificationManager,
        mcpServerManager: any MCPServerManagerProtocol,
        keychainManager: KeychainManager,
        configuration: VoiceCommandPipelineConfiguration = .default
    ) {
        self.classificationManager = classificationManager
        self.mcpServerManager = mcpServerManager
        self.keychainManager = keychainManager
        self.configuration = configuration

        setupObservations()
        initializeMetrics()
    }

    private func setupObservations() {
        // Observe classification manager state
        classificationManager.$isProcessing
            .sink { [weak self] isClassifying in
                if isClassifying && self?.currentState == .idle {
                    self?.currentState = .classifying
                }
            }
            .store(in: &cancellables)

        // Observe classification manager errors
        classificationManager.$lastError
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.lastError = error
            }
            .store(in: &cancellables)

        // Observe MCP server manager state
        mcpServerManager.lastErrorPublisher
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.lastError = error
            }
            .store(in: &cancellables)
    }

    private func initializeMetrics() {
        if configuration.enablePerformanceTracking {
            // Update metrics every 30 seconds
            Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    await self?.updateMetrics()
                }
            }
        }
    }

    // MARK: - Main Pipeline Processing

    /// Process a voice command through the complete pipeline
    func processVoiceCommand(_ text: String, userId: String? = nil, sessionId: String? = nil) async throws -> VoiceCommandPipelineResult {
        let startTime = Date()
        let taskId = UUID().uuidString

        // Validate input
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw VoiceCommandPipelineError.invalidInput("Empty voice command")
        }

        // Check if already processing this command (prevent duplicates)
        guard !activeProcessingTasks.contains(text) else {
            throw VoiceCommandPipelineError.invalidInput("Command already being processed")
        }

        // Update state
        currentState = .idle
        isProcessing = true
        activeProcessingTasks.insert(text)

        defer {
            isProcessing = false
            activeProcessingTasks.remove(text)
            currentState = .completed
        }

        do {
            // Step 1: Voice Classification
            currentState = .classifying
            let classificationStartTime = Date()

            let classification = try await classificationManager.classifyVoiceCommand(
                text,
                userId: userId,
                sessionId: sessionId
            )

            let classificationTime = Date().timeIntervalSince(classificationStartTime)
            classificationTimes.append(classificationTime)

            // Step 2: Confidence Check
            if classification.confidence < configuration.minimumConfidenceThreshold || classification.requiresConfirmation {
                let processingTime = Date().timeIntervalSince(startTime)
                let result = VoiceCommandPipelineResult.lowConfidence(
                    classification: classification,
                    processingTime: processingTime
                )

                await recordResult(result)
                return result
            }

            // Step 3: MCP Execution (if enabled and applicable)
            var mcpResult: MCPExecutionResult?

            if configuration.enableMCPExecution && shouldExecuteViaMCP(classification) {
                currentState = .executingMCP
                let mcpStartTime = Date()

                mcpResult = try await executeMCPCommand(classification)

                let mcpExecutionTime = Date().timeIntervalSince(mcpStartTime)
                mcpExecutionTimes.append(mcpExecutionTime)
            }

            // Step 4: Response Generation
            currentState = .generatingResponse
            let finalResponse = generateFinalResponse(classification: classification, mcpResult: mcpResult)

            // Step 5: Create Result
            let processingTime = Date().timeIntervalSince(startTime)
            let result: VoiceCommandPipelineResult

            if let mcpResult = mcpResult, mcpResult.success {
                result = VoiceCommandPipelineResult.success(
                    classification: classification,
                    mcpResult: mcpResult,
                    finalResponse: finalResponse,
                    processingTime: processingTime,
                    suggestions: configuration.enableContextualSuggestions ? classification.suggestions : [],
                    metadata: [
                        "task_id": taskId,
                        "classification_time": classificationTime,
                        "mcp_execution_time": mcpExecutionTimes.last ?? 0.0,
                    ]
                )
            } else {
                // MCP failed or wasn't used - still consider success if we have a response
                let success = mcpResult?.success ?? true // No MCP execution is still success
                result = VoiceCommandPipelineResult(
                    success: success,
                    classification: classification,
                    mcpExecutionResult: mcpResult,
                    finalResponse: finalResponse,
                    suggestions: classification.suggestions,
                    processingTime: processingTime,
                    error: mcpResult?.error,
                    metadata: [
                        "task_id": taskId,
                        "classification_time": classificationTime,
                        "mcp_attempted": mcpResult != nil,
                    ]
                )
            }

            await recordResult(result)
            return result
        } catch {
            let processingTime = Date().timeIntervalSince(startTime)

            // Generate appropriate error response
            let errorResponse: String
            if let vcError = error as? VoiceClassificationError {
                switch vcError {
                case .authenticationFailed, .tokenExpired:
                    errorResponse = VoiceCommandResponseGenerator.generateAuthenticationRequiredResponse()
                case .networkError:
                    errorResponse = "I'm having trouble connecting. Please check your internet connection and try again."
                default:
                    errorResponse = VoiceCommandResponseGenerator.generateFailureResponse(classification: nil, error: error)
                }
            } else {
                errorResponse = VoiceCommandResponseGenerator.generateFailureResponse(classification: nil, error: error)
            }

            let result = VoiceCommandPipelineResult.failure(
                classification: nil,
                finalResponse: errorResponse,
                processingTime: processingTime,
                error: error,
                suggestions: ["Try again", "Check your connection", "Rephrase your request"],
                metadata: ["task_id": taskId, "error_type": String(describing: type(of: error))]
            )

            await recordResult(result)
            lastError = error
            currentState = .error(error.localizedDescription)

            throw error
        }
    }

    // MARK: - MCP Execution Logic

    private func shouldExecuteViaMCP(_ classification: ClassificationResult) -> Bool {
        // Check if this category is supported by MCP
        let mcpSupportedCategories = [
            "document_generation",
            "email_management",
            "calendar_scheduling",
            "web_search",
            "file_storage",
        ]

        return mcpSupportedCategories.contains(classification.category)
    }

    private func executeMCPCommand(_ classification: ClassificationResult) async throws -> MCPExecutionResult {
        // Execute the voice command using the MCP server manager
        return try await mcpServerManager.executeVoiceCommand(classification)
    }

    // MARK: - Response Generation

    private func generateFinalResponse(classification: ClassificationResult, mcpResult: MCPExecutionResult?) -> String {
        if let mcpResult = mcpResult {
            if mcpResult.success {
                return VoiceCommandResponseGenerator.generateSuccessResponse(
                    classification: classification,
                    mcpResult: mcpResult
                )
            } else {
                return VoiceCommandResponseGenerator.generateFailureResponse(
                    classification: classification,
                    error: mcpResult.error
                )
            }
        } else {
            // No MCP execution - generate conversational response
            switch classification.category {
            case "general_conversation":
                return generateConversationalResponse(classification)
            case "system_control":
                return "I understand you want to \(classification.intent). This feature will be available soon."
            default:
                return "I understand your request about \(classification.category). Let me help you with that."
            }
        }
    }

    private func generateConversationalResponse(_ classification: ClassificationResult) -> String {
        let intent = classification.intent.lowercased()

        switch intent {
        case "greeting":
            return "Hello! I'm Jarvis, your AI assistant. How can I help you today?"
        case "farewell":
            return "Goodbye! Feel free to ask me anything anytime."
        case "status_inquiry":
            return "I'm working well and ready to help you with documents, emails, scheduling, and more!"
        case "capabilities_inquiry":
            return "I can help you create documents, send emails, schedule events, search the web, and have conversations. What would you like to do?"
        default:
            return "I'm here to help! You can ask me to create documents, send emails, schedule events, or just have a conversation."
        }
    }

    // MARK: - Result Recording and Metrics

    private func recordResult(_ result: VoiceCommandPipelineResult) async {
        totalProcessedCommands += 1

        if result.success {
            successfulCommands += 1
        }

        processingTimes.append(result.processingTime)
        processingHistory.append(result)
        lastResult = result

        // Maintain history size
        if processingHistory.count > maxHistorySize {
            processingHistory.removeFirst(processingHistory.count - maxHistorySize)
        }

        // Maintain processing times array size
        if processingTimes.count > maxHistorySize {
            processingTimes.removeFirst(processingTimes.count - maxHistorySize)
        }

        // Update metrics if enabled
        if configuration.enablePerformanceTracking {
            await updateMetrics()
        }
    }

    private func updateMetrics() async {
        let avgClassificationTime = classificationTimes.isEmpty ? 0.0 : classificationTimes.reduce(0, +) / Double(classificationTimes.count)
        let avgMCPTime = mcpExecutionTimes.isEmpty ? 0.0 : mcpExecutionTimes.reduce(0, +) / Double(mcpExecutionTimes.count)

        let classificationSuccessRate = totalProcessedCommands > 0 ? Double(successfulCommands) / Double(totalProcessedCommands) : 0.0
        let mcpSuccessRate = mcpExecutionTimes.isEmpty ? 0.0 : classificationSuccessRate // Simplified for now

        metrics = VoiceCommandPipelineMetrics(
            totalCommands: totalProcessedCommands,
            successfulCommands: successfulCommands,
            averageProcessingTime: averageProcessingTime,
            averageClassificationTime: avgClassificationTime,
            averageMCPExecutionTime: avgMCPTime,
            classificationSuccessRate: classificationSuccessRate,
            mcpSuccessRate: mcpSuccessRate,
            lastUpdated: Date()
        )
    }

    // MARK: - Public Interface

    /// Get processing history
    func getProcessingHistory() -> [VoiceCommandPipelineResult] {
        return processingHistory
    }

    /// Clear processing history and reset metrics
    func clearHistory() {
        processingHistory.removeAll()
        processingTimes.removeAll()
        classificationTimes.removeAll()
        mcpExecutionTimes.removeAll()
        totalProcessedCommands = 0
        successfulCommands = 0
        metrics = .empty
        lastResult = nil
        lastError = nil
    }

    /// Check if pipeline is ready to process commands
    func isReady() async -> Bool {
        // Check authentication status
        guard classificationManager.isAuthenticated else { return false }

        // Check MCP server availability if MCP execution is enabled
        if configuration.enableMCPExecution {
            guard mcpServerManager.isInitialized else { return false }
        }

        return true
    }

    /// Initialize pipeline and dependencies
    func initialize() async throws {
        // Ensure classification manager is authenticated
        if !classificationManager.isAuthenticated && classificationManager.hasStoredAPIKey() {
            try await classificationManager.authenticate()
        }

        // Initialize MCP server manager if needed
        if configuration.enableMCPExecution && !mcpServerManager.isInitialized {
            await mcpServerManager.initialize()
        }

        currentState = .idle
    }

    /// Get current pipeline status
    func getStatus() -> [String: Any] {
        return [
            "state": currentState.description,
            "isProcessing": isProcessing,
            "isReady": Task { await isReady() },
            "totalCommands": totalProcessedCommands,
            "successRate": successRate,
            "averageProcessingTime": averageProcessingTime,
            "classificationManagerAuthenticated": classificationManager.isAuthenticated,
            "mcpServerManagerInitialized": mcpServerManager.isInitialized,
            "activeProcessingTasks": activeProcessingTasks.count,
            "configuration": [
                "minimumConfidenceThreshold": configuration.minimumConfidenceThreshold,
                "enableMCPExecution": configuration.enableMCPExecution,
                "enableFallbackResponses": configuration.enableFallbackResponses,
            ],
        ]
    }
}
