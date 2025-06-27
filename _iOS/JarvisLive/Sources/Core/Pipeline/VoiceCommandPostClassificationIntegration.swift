/*
* Purpose: Integration layer between voice processing and post-classification UI flow
* Issues & Complexity Summary: Bridge between backend classification and iOS UI presentation
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~350
  - Core Algorithm Complexity: Medium (async coordination, state management)
  - Dependencies: 5 New (VoiceClassificationManager, UI flow, network client)
  - State Management Complexity: High (multiple async states, error handling)
  - Novelty/Uncertainty Factor: Medium (integration complexity)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 80%
* Initial Code Complexity Estimate: 82%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
*/

import SwiftUI
import Combine
import Foundation

// MARK: - Integration Manager

@MainActor
class VoiceCommandPostClassificationIntegration: ObservableObject {
    // MARK: - Published Properties
    @Published var isProcessingVoiceCommand = false
    @Published var currentClassificationResult: ClassificationResult?
    @Published var showingPostClassificationFlow = false
    @Published var lastError: VoiceProcessingError?

    // MARK: - Dependencies
    private let voiceClassificationManager: VoiceClassificationManager
    private let pythonBackendClient: PythonBackendClient
    private let conversationManager: ConversationManager

    // MARK: - Internal State
    private var cancellables = Set<AnyCancellable>()
    private var currentSessionId: String?
    private var currentUserId: String

    // MARK: - Configuration
    private let configuration: IntegrationConfiguration

    // MARK: - Initialization

    init(
        voiceClassificationManager: VoiceClassificationManager = VoiceClassificationManager(),
        pythonBackendClient: PythonBackendClient = PythonBackendClient(),
        conversationManager: ConversationManager = ConversationManager(),
        userId: String = "default_user"
    ) {
        self.voiceClassificationManager = voiceClassificationManager
        self.pythonBackendClient = pythonBackendClient
        self.conversationManager = conversationManager
        self.currentUserId = userId
        self.configuration = IntegrationConfiguration()

        setupObservers()
    }

    // MARK: - Public Interface

    /// Process voice input through the complete classification and UI flow pipeline
    func processVoiceInput(_ voiceText: String, audioData: Data? = nil) async {
        guard !isProcessingVoiceCommand else {
            print("⚠️ Voice processing already in progress, ignoring new input")
            return
        }

        isProcessingVoiceCommand = true
        lastError = nil

        do {
            // Start new session if needed
            if currentSessionId == nil {
                currentSessionId = await startNewVoiceSession()
            }

            // Step 1: Classify the voice command
            let classificationResult = try await classifyVoiceCommand(voiceText, audioData: audioData)

            // Step 2: Store classification in conversation history
            await recordVoiceInteraction(voiceText: voiceText, classification: classificationResult)

            // Step 3: Present post-classification UI flow
            await presentPostClassificationFlow(classificationResult)
        } catch {
            await handleVoiceProcessingError(error)
        }

        isProcessingVoiceCommand = false
    }

    /// Handle the completion of a post-classification flow
    func handleFlowCompletion(_ result: CommandExecutionResult) async {
        showingPostClassificationFlow = false

        // Record the completion in conversation history
        if let classificationResult = currentClassificationResult {
            await recordCommandCompletion(
                classification: classificationResult,
                executionResult: result
            )
        }

        currentClassificationResult = nil

        // Optionally start a new session for the next command
        if configuration.autoStartNewSession {
            currentSessionId = await startNewVoiceSession()
        }
    }

    /// Cancel the current voice processing operation
    func cancelCurrentOperation() {
        isProcessingVoiceCommand = false
        showingPostClassificationFlow = false
        currentClassificationResult = nil
        lastError = nil
    }

    /// Get contextual suggestions based on current conversation
    func getContextualSuggestions() async -> [String] {
        guard let sessionId = currentSessionId else {
            return configuration.defaultSuggestions
        }

        // TODO: Implement getContextualSuggestions method in PythonBackendClient
        // For now, return default suggestions
        return configuration.defaultSuggestions
        
        /*
        do {
            return try await pythonBackendClient.getContextualSuggestions(
                userId: currentUserId,
                sessionId: sessionId
            )
        } catch {
            print("Failed to get contextual suggestions: \(error)")
            return configuration.defaultSuggestions
        }
        */
    }

    // MARK: - Private Implementation

    private func setupObservers() {
        // Observe voice classification manager state
        voiceClassificationManager.$isProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isProcessingVoiceCommand, on: self)
            .store(in: &cancellables)

        // Observe backend client connectivity
        pythonBackendClient.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                if !isConnected {
                    self?.handleBackendDisconnection()
                }
            }
            .store(in: &cancellables)
    }

    private func startNewVoiceSession() async -> String {
        let sessionId = UUID().uuidString

        do {
            // Fixed: startVoiceSession() takes no parameters
            try await pythonBackendClient.startVoiceSession()
            return sessionId
        } catch {
            print("Failed to start voice session: \(error)")
            return sessionId // Use local session ID as fallback
        }
    }

    private func classifyVoiceCommand(_ voiceText: String, audioData: Data?) async throws -> ClassificationResult {
        // Try backend classification first
        if pythonBackendClient.isConnected {
            do {
                let audioRequest = VoiceClassificationRequestWithAudio(
                    text: voiceText,
                    audioData: audioData,
                    userId: currentUserId,
                    sessionId: currentSessionId ?? "",
                    includeContext: true
                )
                let backendResult = try await pythonBackendClient.classifyVoiceCommand(
                    audioRequest.toStandardRequest()
                )

                // TODO: Fix ClassificationResult constructor to match actual definition
                // return ClassificationResult(from: backendResult)
                return backendResult
            } catch {
                print("Backend classification failed, falling back to local: \(error)")
            }
        }

        // Fallback to local classification
        return try await voiceClassificationManager.classifyVoiceCommand(voiceText)
    }

    private func presentPostClassificationFlow(_ result: ClassificationResult) async {
        currentClassificationResult = result

        // Add small delay for smooth transition
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        showingPostClassificationFlow = true
    }

    private func recordVoiceInteraction(voiceText: String, classification: ClassificationResult) async {
        let interaction = VoiceInteraction(
            id: UUID(),
            timestamp: Date(),
            voiceText: voiceText,
            classification: classification,
            sessionId: currentSessionId,
            userId: currentUserId
        )

        // Store locally using the actual method signature
        if let conversation = conversationManager.currentConversation {
            let _ = conversationManager.addVoiceInteraction(
                to: conversation,
                userVoiceText: voiceText,
                aiResponse: "Voice interaction recorded", // Default response
                processingTime: 0.0,
                aiProvider: "system"
            )
        }

        // TODO: Implement recordVoiceInteraction method in PythonBackendClient
        // Sync to backend if connected
        /*
        if pythonBackendClient.isConnected {
            do {
                try await pythonBackendClient.recordVoiceInteraction(interaction)
            } catch {
                print("Failed to sync voice interaction to backend: \(error)")
            }
        }
        */
    }

    private func recordCommandCompletion(
        classification: ClassificationResult,
        executionResult: CommandExecutionResult
    ) async {
        let completion = CommandCompletion(
            id: UUID(),
            timestamp: Date(),
            classification: classification,
            executionResult: executionResult,
            sessionId: currentSessionId,
            userId: currentUserId
        )

        // Store locally using the actual method signature
        if let conversation = conversationManager.currentConversation {
            let _ = conversationManager.addCommandCompletion(
                to: conversation,
                command: classification.intent,
                result: executionResult.message,
                success: executionResult.success,
                processingTime: executionResult.timeSpent
            )
        }

        // TODO: Implement recordCommandCompletion method in PythonBackendClient
        // Sync to backend if connected
        /*
        if pythonBackendClient.isConnected {
            do {
                try await pythonBackendClient.recordCommandCompletion(completion)
            } catch {
                print("Failed to sync command completion to backend: \(error)")
            }
        }
        */
    }

    private func handleVoiceProcessingError(_ error: Error) async {
        let voiceError = VoiceProcessingError.from(error)
        lastError = voiceError

        // Record error for analytics
        await recordErrorEvent(voiceError)

        // Show user-friendly error based on type
        switch voiceError {
        case .networkUnavailable:
            // Continue with offline mode
            break
        case .classificationFailed:
            // Show clarification UI
            await showClarificationForFailedClassification()
        case .backendTimeout:
            // Retry with local processing
            break
        case .invalidInput:
            // Show input guidance
            break
        case .unknown:
            // Handle unknown errors
            break
        }
    }

    private func showClarificationForFailedClassification() async {
        // Create a low-confidence result using the correct ClassificationResult structure
        let clarificationResult = ClassificationResult(
            category: "unknown",
            intent: "Classification failed",
            confidence: 0.1,
            parameters: [:],
            suggestions: await getContextualSuggestions(),
            rawText: "Could not understand command",
            normalizedText: "unknown command",
            confidenceLevel: "very_low",
            contextUsed: false,
            preprocessingTime: 0.0,
            classificationTime: 0.0,
            requiresConfirmation: true
        )

        await presentPostClassificationFlow(clarificationResult)
    }

    private func recordErrorEvent(_ error: VoiceProcessingError) async {
        let errorEvent = ErrorEvent(
            id: UUID(),
            timestamp: Date(),
            error: error,
            sessionId: currentSessionId,
            userId: currentUserId,
            context: createErrorContext()
        )

        // Store locally for analytics using the actual method signature
        if let conversation = conversationManager.currentConversation {
            let _ = conversationManager.addErrorEvent(
                to: conversation,
                error: error,
                context: "Voice processing error"
            )
        }

        // TODO: Implement recordErrorEvent method in PythonBackendClient
        // Send to backend for aggregated analytics
        /*
        if pythonBackendClient.isConnected {
            Task {
                try? await pythonBackendClient.recordErrorEvent(errorEvent)
            }
        }
        */
    }

    private func createErrorContext() -> [String: Any] {
        return [
            "session_id": currentSessionId ?? "none",
            "user_id": currentUserId,
            "backend_connected": pythonBackendClient.isConnected,
            "conversation_count": conversationManager.conversations.count,
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] ?? "unknown",
        ]
    }

    private func handleBackendDisconnection() {
        // Switch to offline mode gracefully
        print("⚠️ Backend disconnected, switching to offline mode")

        // TODO: Implement cancelAllOperations method in PythonBackendClient
        // Cancel any pending backend operations
        // pythonBackendClient.cancelAllOperations()

        // Continue with local processing only
    }
}

// MARK: - Configuration

struct IntegrationConfiguration {
    let autoStartNewSession: Bool
    let enableOfflineMode: Bool
    let maxRetryAttempts: Int
    let timeoutInterval: TimeInterval
    let defaultSuggestions: [String]

    init() {
        self.autoStartNewSession = true
        self.enableOfflineMode = true
        self.maxRetryAttempts = 3
        self.timeoutInterval = 10.0
        self.defaultSuggestions = [
            "Create a document",
            "Send an email",
            "Schedule a meeting",
            "Search the web",
            "Set a reminder",
        ]
    }
}

// MARK: - Supporting Models

struct VoiceInteraction: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let voiceText: String
    let classification: ClassificationResult
    let sessionId: String?
    let userId: String
}

struct CommandCompletion: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let classification: ClassificationResult
    let executionResult: CommandExecutionResult
    let sessionId: String?
    let userId: String
}

// CommandExecutionResult is defined in VoiceClassificationManager.swift
// We'll use that canonical definition to avoid duplication

extension CommandExecutionResult {
    static let success = CommandExecutionResult(
        success: true,
        message: "Command executed successfully",
        actionPerformed: "post_classification_flow_completed",
        timeSpent: 2.5,
        additionalData: nil
    )

    static let failure = CommandExecutionResult(
        success: false,
        message: "Command execution failed",
        actionPerformed: nil,
        timeSpent: 1.0,
        additionalData: ["error": "Network timeout"]
    )
}

struct ErrorEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let error: VoiceProcessingError
    let sessionId: String?
    let userId: String
    let context: [String: Any]

    // Custom coding for context dictionary
    enum CodingKeys: String, CodingKey {
        case id, timestamp, error, sessionId, userId, context
    }

    init(id: UUID, timestamp: Date, error: VoiceProcessingError, sessionId: String?, userId: String, context: [String: Any]) {
        self.id = id
        self.timestamp = timestamp
        self.error = error
        self.sessionId = sessionId
        self.userId = userId
        self.context = context
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        error = try container.decode(VoiceProcessingError.self, forKey: .error)
        sessionId = try container.decodeIfPresent(String.self, forKey: .sessionId)
        userId = try container.decode(String.self, forKey: .userId)
        context = [:] // Simplified for this example
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(error, forKey: .error)
        try container.encodeIfPresent(sessionId, forKey: .sessionId)
        try container.encode(userId, forKey: .userId)
        // Context encoding simplified for this example
    }
}

enum VoiceProcessingError: String, Codable, Error {
    case networkUnavailable = "network_unavailable"
    case classificationFailed = "classification_failed"
    case backendTimeout = "backend_timeout"
    case invalidInput = "invalid_input"
    case unknown = "unknown"

    static func from(_ error: Error) -> VoiceProcessingError {
        if let voiceError = error as? VoiceProcessingError {
            return voiceError
        }

        let errorString = error.localizedDescription.lowercased()

        if errorString.contains("network") || errorString.contains("connection") {
            return .networkUnavailable
        } else if errorString.contains("timeout") {
            return .backendTimeout
        } else if errorString.contains("classification") {
            return .classificationFailed
        } else if errorString.contains("input") || errorString.contains("invalid") {
            return .invalidInput
        } else {
            return .unknown
        }
    }

    var userFriendlyMessage: String {
        switch self {
        case .networkUnavailable:
            return "Network connection is unavailable. Working in offline mode."
        case .classificationFailed:
            return "Could not understand your command. Please try rephrasing."
        case .backendTimeout:
            return "Processing is taking longer than expected. Please try again."
        case .invalidInput:
            return "The voice input was not clear enough. Please try again."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// VoiceClassificationRequest is defined in AuthenticationModels.swift
// We'll use that canonical definition to avoid duplication

struct VoiceClassificationRequestWithAudio: Codable {
    let text: String
    let audioData: Data?
    let userId: String
    let sessionId: String
    let includeContext: Bool
    
    // Convert to standard VoiceClassificationRequest
    func toStandardRequest() -> VoiceClassificationRequest {
        return VoiceClassificationRequest(
            text: text,
            userId: userId,
            sessionId: sessionId,
            useContext: includeContext,
            includeSuggestions: true
        )
    }
}

// MARK: - ClassificationResult Extension

extension ClassificationResult {
    init(from backendResult: BackendClassificationResult) {
        self.init(
            category: CommandCategory(rawValue: backendResult.category) ?? .unknown,
            intent: backendResult.intent,
            confidence: backendResult.confidence,
            parameters: backendResult.parameters.mapValues { AnyCodable($0) },
            suggestions: backendResult.suggestions,
            rawText: backendResult.rawText,
            normalizedText: backendResult.normalizedText,
            processingTime: backendResult.processingTime
        )
    }
}

struct BackendClassificationResult: Codable {
    let category: String
    let intent: String
    let confidence: Double
    let parameters: [String: Any]
    let suggestions: [String]
    let rawText: String
    let normalizedText: String
    let processingTime: Double

    // Custom coding for parameters dictionary
    enum CodingKeys: String, CodingKey {
        case category, intent, confidence, parameters, suggestions, rawText, normalizedText, processingTime
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        category = try container.decode(String.self, forKey: .category)
        intent = try container.decode(String.self, forKey: .intent)
        confidence = try container.decode(Double.self, forKey: .confidence)
        suggestions = try container.decode([String].self, forKey: .suggestions)
        rawText = try container.decode(String.self, forKey: .rawText)
        normalizedText = try container.decode(String.self, forKey: .normalizedText)
        processingTime = try container.decode(Double.self, forKey: .processingTime)
        parameters = [:] // Simplified for this example
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(category, forKey: .category)
        try container.encode(intent, forKey: .intent)
        try container.encode(confidence, forKey: .confidence)
        try container.encode(suggestions, forKey: .suggestions)
        try container.encode(rawText, forKey: .rawText)
        try container.encode(normalizedText, forKey: .normalizedText)
        try container.encode(processingTime, forKey: .processingTime)
        // Parameters encoding simplified for this example
    }
}

// MARK: - SwiftUI Integration

struct VoiceCommandWithPostClassificationView: View {
    @StateObject private var integration = VoiceCommandPostClassificationIntegration()
    @State private var voiceInput = ""

    var body: some View {
        VStack(spacing: 20) {
            // Voice input area
            VStack(spacing: 12) {
                TextField("Say something...", text: $voiceInput)
                    .textFieldStyle(.roundedBorder)
                    .disabled(integration.isProcessingVoiceCommand)

                Button("Process Voice Command") {
                    Task {
                        await integration.processVoiceInput(voiceInput)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(voiceInput.isEmpty || integration.isProcessingVoiceCommand)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

            // Status indicators
            if integration.isProcessingVoiceCommand {
                ProgressView("Processing voice command...")
                    .progressViewStyle(.circular)
            }

            if let error = integration.lastError {
                Text(error.userFriendlyMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $integration.showingPostClassificationFlow) {
            if let result = integration.currentClassificationResult {
                PostClassificationFlowView(classificationResult: result)
                    .onDisappear {
                        Task {
                            await integration.handleFlowCompletion(.success)
                        }
                    }
            }
        }
    }
}

#Preview {
    VoiceCommandWithPostClassificationView()
        .modifier(GlassViewModifier())
}
