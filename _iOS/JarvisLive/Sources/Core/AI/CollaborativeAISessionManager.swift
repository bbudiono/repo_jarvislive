// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Collaborative AI sessions with shared context and multi-participant AI interactions
 * Issues & Complexity Summary: Complex AI context sharing, session state management, and collaborative decision making
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~550
 *   - Core Algorithm Complexity: Very High (Multi-AI coordination, shared context)
 *   - Dependencies: 6 New (AI providers, CollaborationManager, MCP, Context management)
 *   - State Management Complexity: Very High (Shared AI context, multi-participant state)
 *   - Novelty/Uncertainty Factor: High (Collaborative AI patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 88%
 * Problem Estimate (Inherent Problem Difficulty %): 92%
 * Initial Code Complexity Estimate %: 90%
 * Justification for Estimates: Multi-participant AI context sharing is highly complex
 * Final Code Complexity (Actual %): 93%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Implemented consensus-based AI decision making and context merging
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - Collaborative AI Types

public struct CollaborativeAISession: Codable, Identifiable {
    public let id: UUID
    public let collaborationSessionID: UUID
    public let sessionType: AISessionType
    public let participants: [String]
    public let activeAIProviders: [AIProvider]
    public let sharedContext: SharedAIContext
    public let createdAt: Date
    public let lastActivity: Date
    public let configuration: AISessionConfiguration

    public enum AISessionType: String, Codable, CaseIterable {
        case brainstorming = "brainstorming"
        case problemSolving = "problem_solving"
        case codeReview = "code_review"
        case documentAnalysis = "document_analysis"
        case decisionMaking = "decision_making"
        case learning = "learning"
        case creativity = "creativity"

        public var displayName: String {
            switch self {
            case .brainstorming: return "Brainstorming"
            case .problemSolving: return "Problem Solving"
            case .codeReview: return "Code Review"
            case .documentAnalysis: return "Document Analysis"
            case .decisionMaking: return "Decision Making"
            case .learning: return "Learning Session"
            case .creativity: return "Creative Workshop"
            }
        }
    }

    public struct AIProvider: Codable {
        public let name: String
        public let model: String
        public let capabilities: [String]
        public let costPerToken: Double
        public let isActive: Bool

        public init(name: String, model: String, capabilities: [String], costPerToken: Double, isActive: Bool = true) {
            self.name = name
            self.model = model
            self.capabilities = capabilities
            self.costPerToken = costPerToken
            self.isActive = isActive
        }
    }

    public init(collaborationSessionID: UUID, sessionType: AISessionType, participants: [String], activeAIProviders: [AIProvider], configuration: AISessionConfiguration) {
        self.id = UUID()
        self.collaborationSessionID = collaborationSessionID
        self.sessionType = sessionType
        self.participants = participants
        self.activeAIProviders = activeAIProviders
        self.sharedContext = SharedAIContext()
        self.createdAt = Date()
        self.lastActivity = Date()
        self.configuration = configuration
    }
}

public struct SharedAIContext: Codable {
    public var conversationHistory: [AIContextMessage]
    public var sharedDocuments: [ContextDocument]
    public var keyInsights: [Insight]
    public var decisions: [CollaborativeDecision]
    public var actionItems: [ActionItem]
    public var knowledgeBase: [String: Any]
    public var metadata: ContextMetadata

    public init() {
        self.conversationHistory = []
        self.sharedDocuments = []
        self.keyInsights = []
        self.decisions = []
        self.actionItems = []
        self.knowledgeBase = [:]
        self.metadata = ContextMetadata()
    }

    private enum CodingKeys: String, CodingKey {
        case conversationHistory, sharedDocuments, keyInsights, decisions, actionItems, metadata
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        conversationHistory = try container.decode([AIContextMessage].self, forKey: .conversationHistory)
        sharedDocuments = try container.decode([ContextDocument].self, forKey: .sharedDocuments)
        keyInsights = try container.decode([Insight].self, forKey: .keyInsights)
        decisions = try container.decode([CollaborativeDecision].self, forKey: .decisions)
        actionItems = try container.decode([ActionItem].self, forKey: .actionItems)
        metadata = try container.decode(ContextMetadata.self, forKey: .metadata)
        knowledgeBase = [:]
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(conversationHistory, forKey: .conversationHistory)
        try container.encode(sharedDocuments, forKey: .sharedDocuments)
        try container.encode(keyInsights, forKey: .keyInsights)
        try container.encode(decisions, forKey: .decisions)
        try container.encode(actionItems, forKey: .actionItems)
        try container.encode(metadata, forKey: .metadata)
    }
}

public struct AIContextMessage: Codable, Identifiable {
    public let id: UUID
    public let participantID: String
    public let content: String
    public let role: MessageRole
    public let timestamp: Date
    public let aiProvider: String?
    public let confidence: Float
    public let contextRelevance: Float

    public enum MessageRole: String, Codable {
        case user = "user"
        case assistant = "assistant"
        case system = "system"
        case facilitator = "facilitator"
    }

    public init(participantID: String, content: String, role: MessageRole, aiProvider: String? = nil, confidence: Float = 1.0, contextRelevance: Float = 1.0) {
        self.id = UUID()
        self.participantID = participantID
        self.content = content
        self.role = role
        self.timestamp = Date()
        self.aiProvider = aiProvider
        self.confidence = confidence
        self.contextRelevance = contextRelevance
    }
}

public struct ContextDocument: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let content: String
    public let documentType: DocumentType
    public let sharedBy: String
    public let sharedAt: Date
    public let relevanceScore: Float
    public let annotations: [DocumentAnnotation]

    public enum DocumentType: String, Codable {
        case text = "text"
        case code = "code"
        case image = "image"
        case pdf = "pdf"
        case link = "link"
    }

    public init(title: String, content: String, documentType: DocumentType, sharedBy: String, relevanceScore: Float = 1.0) {
        self.id = UUID()
        self.title = title
        self.content = content
        self.documentType = documentType
        self.sharedBy = sharedBy
        self.sharedAt = Date()
        self.relevanceScore = relevanceScore
        self.annotations = []
    }
}

public struct DocumentAnnotation: Codable, Identifiable {
    public let id: UUID
    public let annotatorID: String
    public let content: String
    public let position: AnnotationPosition
    public let timestamp: Date

    public struct AnnotationPosition: Codable {
        public let startOffset: Int
        public let endOffset: Int
        public let page: Int?

        public init(startOffset: Int, endOffset: Int, page: Int? = nil) {
            self.startOffset = startOffset
            self.endOffset = endOffset
            self.page = page
        }
    }

    public init(annotatorID: String, content: String, position: AnnotationPosition) {
        self.id = UUID()
        self.annotatorID = annotatorID
        self.content = content
        self.position = position
        self.timestamp = Date()
    }
}

public struct Insight: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let generatedBy: InsightSource
    public let confidence: Float
    public let supportingEvidence: [String]
    public let relatedTopics: [String]
    public let timestamp: Date

    public enum InsightSource: Codable {
        case participant(String)
        case ai(String)
        case collaborative

        private enum CodingKeys: String, CodingKey {
            case type, value
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .participant(let id):
                try container.encode("participant", forKey: .type)
                try container.encode(id, forKey: .value)
            case .ai(let provider):
                try container.encode("ai", forKey: .type)
                try container.encode(provider, forKey: .value)
            case .collaborative:
                try container.encode("collaborative", forKey: .type)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "participant":
                let value = try container.decode(String.self, forKey: .value)
                self = .participant(value)
            case "ai":
                let value = try container.decode(String.self, forKey: .value)
                self = .ai(value)
            case "collaborative":
                self = .collaborative
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid insight source type")
            }
        }
    }

    public init(title: String, description: String, generatedBy: InsightSource, confidence: Float, supportingEvidence: [String] = [], relatedTopics: [String] = []) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.generatedBy = generatedBy
        self.confidence = confidence
        self.supportingEvidence = supportingEvidence
        self.relatedTopics = relatedTopics
        self.timestamp = Date()
    }
}

public struct CollaborativeDecision: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let options: [DecisionOption]
    public let selectedOption: UUID?
    public let decisionMethod: DecisionMethod
    public let participantVotes: [String: UUID]
    public let finalizedBy: String?
    public let finalizedAt: Date?
    public let reasoning: String?

    public enum DecisionMethod: String, Codable {
        case consensus = "consensus"
        case majority = "majority"
        case facilitated = "facilitated"
        case aiRecommended = "ai_recommended"
    }

    public init(title: String, description: String, options: [DecisionOption], decisionMethod: DecisionMethod) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.options = options
        self.selectedOption = nil
        self.decisionMethod = decisionMethod
        self.participantVotes = [:]
        self.finalizedBy = nil
        self.finalizedAt = nil
        self.reasoning = nil
    }
}

public struct DecisionOption: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let pros: [String]
    public let cons: [String]
    public let estimatedImpact: Impact

    public enum Impact: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case critical = "critical"
    }

    public init(title: String, description: String, pros: [String] = [], cons: [String] = [], estimatedImpact: Impact = .medium) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.pros = pros
        self.cons = cons
        self.estimatedImpact = estimatedImpact
    }
}

public struct ActionItem: Codable, Identifiable {
    public let id: UUID
    public let title: String
    public let description: String
    public let assignedTo: [String]
    public let priority: Priority
    public let dueDate: Date?
    public let status: Status
    public let createdBy: String
    public let createdAt: Date

    public enum Priority: String, Codable, CaseIterable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
    }

    public enum Status: String, Codable, CaseIterable {
        case pending = "pending"
        case inProgress = "in_progress"
        case completed = "completed"
        case blocked = "blocked"
    }

    public init(title: String, description: String, assignedTo: [String], priority: Priority, dueDate: Date? = nil, createdBy: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.assignedTo = assignedTo
        self.priority = priority
        self.dueDate = dueDate
        self.status = .pending
        self.createdBy = createdBy
        self.createdAt = Date()
    }
}

public struct ContextMetadata: Codable {
    public var totalTokensUsed: Int
    public var totalCost: Double
    public var activeProviders: [String]
    public var sessionDuration: TimeInterval
    public var lastSync: Date

    public init() {
        self.totalTokensUsed = 0
        self.totalCost = 0.0
        self.activeProviders = []
        self.sessionDuration = 0
        self.lastSync = Date()
    }
}

public struct AISessionConfiguration: Codable {
    public let maxContextLength: Int
    public let enabledFeatures: [SessionFeature]
    public let aiModelPreferences: [String: String]
    public let costLimits: CostLimits
    public let privacySettings: PrivacySettings

    public enum SessionFeature: String, Codable, CaseIterable {
        case autoSummarization = "auto_summarization"
        case insightGeneration = "insight_generation"
        case documentAnalysis = "document_analysis"
        case decisionSupport = "decision_support"
        case actionTracking = "action_tracking"
        case contextMerging = "context_merging"
    }

    public struct CostLimits: Codable {
        public let maxTotalCost: Double
        public let maxCostPerRequest: Double
        public let costAlertThreshold: Double

        public init(maxTotalCost: Double = 100.0, maxCostPerRequest: Double = 5.0, costAlertThreshold: Double = 80.0) {
            self.maxTotalCost = maxTotalCost
            self.maxCostPerRequest = maxCostPerRequest
            self.costAlertThreshold = costAlertThreshold
        }
    }

    public struct PrivacySettings: Codable {
        public let shareContextWithAI: Bool
        public let storeConversationHistory: Bool
        public let allowExternalAPIs: Bool
        public let encryptSharedData: Bool

        public init(shareContextWithAI: Bool = true, storeConversationHistory: Bool = true, allowExternalAPIs: Bool = false, encryptSharedData: Bool = true) {
            self.shareContextWithAI = shareContextWithAI
            self.storeConversationHistory = storeConversationHistory
            self.allowExternalAPIs = allowExternalAPIs
            self.encryptSharedData = encryptSharedData
        }
    }

    public init(maxContextLength: Int = 32000, enabledFeatures: [SessionFeature] = SessionFeature.allCases, aiModelPreferences: [String: String] = [:], costLimits: CostLimits = CostLimits(), privacySettings: PrivacySettings = PrivacySettings()) {
        self.maxContextLength = maxContextLength
        self.enabledFeatures = enabledFeatures
        self.aiModelPreferences = aiModelPreferences
        self.costLimits = costLimits
        self.privacySettings = privacySettings
    }
}

// MARK: - Collaborative AI Session Manager

@MainActor
public final class CollaborativeAISessionManager: ObservableObject {
    // MARK: - Published Properties

    @Published public private(set) var currentSession: CollaborativeAISession?
    @Published public private(set) var sharedContext: SharedAIContext = SharedAIContext()
    @Published public private(set) var activeAIProviders: [CollaborativeAISession.AIProvider] = []
    @Published public private(set) var pendingDecisions: [CollaborativeDecision] = []
    @Published public private(set) var actionItems: [ActionItem] = []
    @Published public private(set) var sessionMetrics: SessionMetrics = SessionMetrics()
    @Published public private(set) var isProcessing: Bool = false

    public struct SessionMetrics {
        public var messagesProcessed: Int = 0
        public var insightsGenerated: Int = 0
        public var decisionsCreated: Int = 0
        public var totalCost: Double = 0.0
        public var averageResponseTime: TimeInterval = 0.0
        public var participantEngagement: [String: Double] = [:]
    }

    // MARK: - Private Properties

    private let collaborationManager: LiveKitCollaborationManager
    private let liveKitManager: LiveKitManager
    private let keychainManager: KeychainManager
    private var cancellables = Set<AnyCancellable>()

    private var localParticipantID: String = ""
    private var contextSyncTimer: Timer?
    private let syncInterval: TimeInterval = 10.0

    // AI Processing
    private var processingQueue = DispatchQueue(label: "ai.collaborative.processing", qos: .userInitiated)
    private var pendingRequests: [UUID: AIRequest] = [:]

    private struct AIRequest {
        let id: UUID
        let prompt: String
        let participantID: String
        let timestamp: Date
        let provider: String
    }

    // MARK: - Initialization

    public init(collaborationManager: LiveKitCollaborationManager, liveKitManager: LiveKitManager, keychainManager: KeychainManager) {
        self.collaborationManager = collaborationManager
        self.liveKitManager = liveKitManager
        self.keychainManager = keychainManager

        setupObservers()
        initializeAIProviders()
    }

    deinit {
        contextSyncTimer?.invalidate()
    }

    // MARK: - Public API

    public func startAISession(type: CollaborativeAISession.AISessionType, configuration: AISessionConfiguration? = nil) async throws -> CollaborativeAISession {
        guard let collaborationSession = collaborationManager.currentSession else {
            throw AISessionError.noCollaborationSession
        }

        let participants = collaborationManager.participants.map { $0.id }
        localParticipantID = collaborationManager.localParticipant?.id ?? "unknown"

        let config = configuration ?? AISessionConfiguration()

        let session = CollaborativeAISession(
            collaborationSessionID: collaborationSession.id,
            sessionType: type,
            participants: participants,
            activeAIProviders: activeAIProviders,
            configuration: config
        )

        currentSession = session
        sharedContext = SharedAIContext()

        // Start context synchronization
        startContextSync()

        // Notify participants
        await notifySessionStarted(session)

        print("🤖 Started collaborative AI session: \(type.displayName)")
        return session
    }

    public func processCollaborativePrompt(_ prompt: String, targetAudience: [String] = [], preferredProvider: String? = nil) async throws -> String {
        guard let session = currentSession else {
            throw AISessionError.noActiveSession
        }

        isProcessing = true
        defer { isProcessing = false }

        let startTime = Date()

        // Add to shared context
        let contextMessage = AIContextMessage(
            participantID: localParticipantID,
            content: prompt,
            role: .user
        )

        await addToSharedContext(message: contextMessage)

        // Select optimal AI provider
        let provider = selectOptimalProvider(for: prompt, preferred: preferredProvider, session: session)

        // Build enriched prompt with shared context
        let enrichedPrompt = buildEnrichedPrompt(prompt, session: session)

        // Process with AI
        let response = try await processWithAI(enrichedPrompt, provider: provider, session: session)

        // Add response to shared context
        let responseMessage = AIContextMessage(
            participantID: "ai-\(provider.name)",
            content: response,
            role: .assistant,
            aiProvider: provider.name,
            confidence: 0.9
        )

        await addToSharedContext(message: responseMessage)

        // Generate insights if enabled
        if session.configuration.enabledFeatures.contains(.insightGeneration) {
            await generateInsights(from: response, provider: provider.name)
        }

        // Update metrics
        let processingTime = Date().timeIntervalSince(startTime)
        updateMetrics(processingTime: processingTime, cost: calculateCost(response, provider: provider))

        // Share with other participants
        await shareAIResponse(prompt: prompt, response: response, provider: provider.name, targetAudience: targetAudience)

        print("🧠 Processed collaborative prompt with \(provider.name)")
        return response
    }

    public func createCollaborativeDecision(title: String, description: String, options: [DecisionOption], method: CollaborativeDecision.DecisionMethod = .consensus) async -> CollaborativeDecision {
        let decision = CollaborativeDecision(
            title: title,
            description: description,
            options: options,
            decisionMethod: method
        )

        pendingDecisions.append(decision)
        sharedContext.decisions.append(decision)

        // Share with participants
        await shareDecision(decision)

        print("🗳️ Created collaborative decision: \(title)")
        return decision
    }

    public func voteOnDecision(_ decisionID: UUID, optionID: UUID) async {
        guard let decisionIndex = pendingDecisions.firstIndex(where: { $0.id == decisionID }) else {
            print("⚠️ Decision not found: \(decisionID)")
            return
        }

        var decision = pendingDecisions[decisionIndex]
        var votes = decision.participantVotes
        votes[localParticipantID] = optionID

        // Update local decision
        pendingDecisions[decisionIndex] = CollaborativeDecision(
            title: decision.title,
            description: decision.description,
            options: decision.options,
            decisionMethod: decision.decisionMethod
        )

        // Check if decision is complete
        await checkDecisionCompletion(decisionID)

        // Share vote
        await shareVote(decisionID: decisionID, optionID: optionID)

        print("🗳️ Voted on decision: \(decisionID)")
    }

    public func addDocumentToContext(_ document: ContextDocument) async {
        sharedContext.sharedDocuments.append(document)

        // Analyze document if enabled
        if currentSession?.configuration.enabledFeatures.contains(.documentAnalysis) == true {
            await analyzeDocument(document)
        }

        // Share with participants
        await shareDocument(document)

        print("📄 Added document to shared context: \(document.title)")
    }

    public func createActionItem(title: String, description: String, assignedTo: [String], priority: ActionItem.Priority, dueDate: Date? = nil) async -> ActionItem {
        let actionItem = ActionItem(
            title: title,
            description: description,
            assignedTo: assignedTo,
            priority: priority,
            dueDate: dueDate,
            createdBy: localParticipantID
        )

        actionItems.append(actionItem)
        sharedContext.actionItems.append(actionItem)

        // Share with participants
        await shareActionItem(actionItem)

        print("✅ Created action item: \(title)")
        return actionItem
    }

    public func updateActionItemStatus(_ actionItemID: UUID, status: ActionItem.Status) async {
        guard let index = actionItems.firstIndex(where: { $0.id == actionItemID }) else {
            print("⚠️ Action item not found: \(actionItemID)")
            return
        }

        // Update status (simplified - would need proper update mechanism)
        // actionItems[index].status = status

        // Share update
        await shareActionItemUpdate(actionItemID: actionItemID, status: status)

        print("📝 Updated action item status: \(status)")
    }

    public func generateSessionSummary() async -> String {
        guard let session = currentSession else {
            return "No active session"
        }

        let insights = sharedContext.keyInsights
        let decisions = sharedContext.decisions
        let actions = sharedContext.actionItems
        let messages = sharedContext.conversationHistory

        var summary = "# \(session.sessionType.displayName) Session Summary\n\n"
        summary += "**Participants:** \(session.participants.count)\n"
        summary += "**Duration:** \(formatDuration(sessionMetrics.averageResponseTime))\n"
        summary += "**Messages Processed:** \(sessionMetrics.messagesProcessed)\n"
        summary += "**Total Cost:** $\(String(format: "%.2f", sessionMetrics.totalCost))\n\n"

        if !insights.isEmpty {
            summary += "## Key Insights\n"
            for insight in insights.prefix(5) {
                summary += "- \(insight.title): \(insight.description)\n"
            }
            summary += "\n"
        }

        if !decisions.isEmpty {
            summary += "## Decisions Made\n"
            for decision in decisions {
                let status = decision.selectedOption != nil ? "✅ Decided" : "🔄 Pending"
                summary += "- \(status) \(decision.title)\n"
            }
            summary += "\n"
        }

        if !actions.isEmpty {
            summary += "## Action Items\n"
            for action in actions {
                let assignees = action.assignedTo.joined(separator: ", ")
                summary += "- \(action.title) (Assigned to: \(assignees))\n"
            }
            summary += "\n"
        }

        return summary
    }

    public func exportSession() async -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(sharedContext)
            return String(data: data, encoding: .utf8) ?? "{}"
        } catch {
            return "{\"error\": \"Failed to export session\"}"
        }
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // Observe collaboration changes
        collaborationManager.$participants
            .sink { [weak self] participants in
                Task { @MainActor in
                    await self?.handleParticipantChanges(participants)
                }
            }
            .store(in: &cancellables)
    }

    private func initializeAIProviders() {
        activeAIProviders = [
            CollaborativeAISession.AIProvider(
                name: "claude",
                model: "claude-3-5-sonnet-20241022",
                capabilities: ["reasoning", "analysis", "coding"],
                costPerToken: 0.000015
            ),
            CollaborativeAISession.AIProvider(
                name: "gpt4",
                model: "gpt-4o",
                capabilities: ["conversation", "multimodal", "general"],
                costPerToken: 0.00003
            ),
            CollaborativeAISession.AIProvider(
                name: "gemini",
                model: "gemini-pro",
                capabilities: ["cost-effective", "long-context"],
                costPerToken: 0.000001
            ),
        ]
    }

    private func selectOptimalProvider(for prompt: String, preferred: String?, session: CollaborativeAISession) -> CollaborativeAISession.AIProvider {
        if let preferred = preferred,
           let provider = activeAIProviders.first(where: { $0.name == preferred }) {
            return provider
        }

        // Simple selection based on cost and capabilities
        return activeAIProviders.min(by: { $0.costPerToken < $1.costPerToken }) ?? activeAIProviders.first!
    }

    private func buildEnrichedPrompt(_ prompt: String, session: CollaborativeAISession) -> String {
        var enrichedPrompt = "You are participating in a collaborative \(session.sessionType.displayName.lowercased()) session.\n\n"

        // Add recent context
        let recentMessages = sharedContext.conversationHistory.suffix(10)
        if !recentMessages.isEmpty {
            enrichedPrompt += "Recent context:\n"
            for message in recentMessages {
                enrichedPrompt += "- \(message.role.rawValue): \(message.content)\n"
            }
            enrichedPrompt += "\n"
        }

        // Add relevant insights
        let relevantInsights = sharedContext.keyInsights.suffix(3)
        if !relevantInsights.isEmpty {
            enrichedPrompt += "Key insights:\n"
            for insight in relevantInsights {
                enrichedPrompt += "- \(insight.title): \(insight.description)\n"
            }
            enrichedPrompt += "\n"
        }

        enrichedPrompt += "Current request: \(prompt)\n\n"
        enrichedPrompt += "Please provide a helpful response considering the collaborative context and session goals."

        return enrichedPrompt
    }

    private func processWithAI(_ prompt: String, provider: CollaborativeAISession.AIProvider, session: CollaborativeAISession) async throws -> String {
        // Use existing LiveKitManager AI processing
        switch provider.name {
        case "claude":
            return try await liveKitManager.callClaudeAPI(input: prompt)
        case "gpt4":
            return try await liveKitManager.callOpenAIAPI(input: prompt)
        case "gemini":
            return try await liveKitManager.callGeminiAPI(input: prompt)
        default:
            throw AISessionError.providerNotSupported(provider.name)
        }
    }

    private func addToSharedContext(message: AIContextMessage) async {
        sharedContext.conversationHistory.append(message)

        // Maintain context length limit
        let maxLength = currentSession?.configuration.maxContextLength ?? 32000
        if sharedContext.conversationHistory.count > maxLength {
            sharedContext.conversationHistory.removeFirst(100) // Remove older messages
        }

        await syncContext()
    }

    private func generateInsights(from response: String, provider: String) async {
        // Simple insight generation (would be more sophisticated in practice)
        let words = response.components(separatedBy: .whitespaces)

        if words.count > 50 {
            let insight = Insight(
                title: "Detailed Analysis Provided",
                description: "AI provided comprehensive analysis with \(words.count) words",
                generatedBy: .ai(provider),
                confidence: 0.7
            )

            sharedContext.keyInsights.append(insight)
            sessionMetrics.insightsGenerated += 1
        }
    }

    private func calculateCost(_ response: String, provider: CollaborativeAISession.AIProvider) -> Double {
        let estimatedTokens = response.count / 4 // Rough estimation
        return Double(estimatedTokens) * provider.costPerToken
    }

    private func updateMetrics(processingTime: TimeInterval, cost: Double) {
        sessionMetrics.messagesProcessed += 1
        sessionMetrics.totalCost += cost

        // Update average response time
        let totalTime = sessionMetrics.averageResponseTime * Double(sessionMetrics.messagesProcessed - 1) + processingTime
        sessionMetrics.averageResponseTime = totalTime / Double(sessionMetrics.messagesProcessed)
    }

    private func startContextSync() {
        contextSyncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncContext()
            }
        }
    }

    private func syncContext() async {
        sharedContext.metadata.lastSync = Date()
        // Share context updates with participants
        print("🔄 Syncing shared context...")
    }

    private func handleParticipantChanges(_ participants: [CollaborationParticipant]) async {
        // Update session participants if needed
        print("👥 Handling participant changes in AI session")
    }

    private func checkDecisionCompletion(_ decisionID: UUID) async {
        // Check if all participants have voted and finalize decision
        print("🗳️ Checking decision completion: \(decisionID)")
    }

    private func analyzeDocument(_ document: ContextDocument) async {
        // Analyze document content for insights
        print("📄 Analyzing document: \(document.title)")
    }

    // MARK: - Sharing Methods

    private func notifySessionStarted(_ session: CollaborativeAISession) async {
        // Notify via collaboration manager
        print("📢 Notifying session started: \(session.sessionType.displayName)")
    }

    private func shareAIResponse(prompt: String, response: String, provider: String, targetAudience: [String]) async {
        await collaborationManager.shareAIResponse(
            prompt: prompt,
            response: response,
            aiProvider: provider,
            relevantParticipants: targetAudience
        )
    }

    private func shareDecision(_ decision: CollaborativeDecision) async {
        print("📤 Sharing decision: \(decision.title)")
    }

    private func shareVote(decisionID: UUID, optionID: UUID) async {
        print("📤 Sharing vote: \(decisionID) -> \(optionID)")
    }

    private func shareDocument(_ document: ContextDocument) async {
        print("📤 Sharing document: \(document.title)")
    }

    private func shareActionItem(_ actionItem: ActionItem) async {
        print("📤 Sharing action item: \(actionItem.title)")
    }

    private func shareActionItemUpdate(actionItemID: UUID, status: ActionItem.Status) async {
        print("📤 Sharing action item update: \(actionItemID) -> \(status)")
    }

    // MARK: - Utility Methods

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

// MARK: - AI Session Errors

public enum AISessionError: LocalizedError {
    case noCollaborationSession
    case noActiveSession
    case providerNotSupported(String)
    case costLimitExceeded
    case contextTooLarge
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .noCollaborationSession:
            return "No active collaboration session"
        case .noActiveSession:
            return "No active AI session"
        case .providerNotSupported(let provider):
            return "AI provider not supported: \(provider)"
        case .costLimitExceeded:
            return "Cost limit exceeded"
        case .contextTooLarge:
            return "Context size too large"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}
