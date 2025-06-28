// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Smart context suggestion engine with pattern-based intelligent recommendations
 * Issues & Complexity Summary: Complex suggestion system with pattern recognition, contextual intelligence, and adaptive recommendations
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~900
 *   - Core Algorithm Complexity: Very High (Pattern recognition, contextual analysis, intelligent suggestions)
 *   - Dependencies: 6 New (CoreData, Foundation, Combine, NaturalLanguage, GameplayKit, OSLog)
 *   - State Management Complexity: High (Suggestion caching, pattern tracking, context awareness)
 *   - Novelty/Uncertainty Factor: High (Advanced suggestion algorithms, contextual intelligence)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 88%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 90%
 * Justification for Estimates: Advanced suggestion engine with pattern recognition and contextual intelligence
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-26
 */

import Foundation
import CoreData
import Combine
import NaturalLanguage
import GameplayKit
import OSLog

// MARK: - Smart Suggestion Models

struct SmartContextSuggestion {
    let id: UUID
    let text: String
    let type: SmartSuggestionType
    let category: SuggestionCategory
    let relevanceScore: Double
    let confidence: Double
    let priority: SuggestionPriority
    let context: SuggestionContext
    let reasoning: String
    let evidence: [SuggestionEvidence]
    let actionability: SuggestionActionability
    let personalization: PersonalizationAlignment
    let temporalRelevance: TemporalRelevance
    let adaptiveProperties: AdaptiveProperties
    let interactionHints: [InteractionHint]
    let relatedSuggestions: [UUID]
    let createdAt: Date
    let expiresAt: Date?
    let usageTracking: SuggestionUsageTracking
}

enum SmartSuggestionType: String, CaseIterable {
    case followUpQuestion = "follow_up_question"
    case topicExpansion = "topic_expansion"
    case skillBuilding = "skill_building"
    case problemSolving = "problem_solving"
    case goalAlignment = "goal_alignment"
    case contextualInsight = "contextual_insight"
    case crossConversationLink = "cross_conversation_link"
    case learningOpportunity = "learning_opportunity"
    case actionableNext = "actionable_next"
    case clarificationRequest = "clarification_request"
    case synthesisOpportunity = "synthesis_opportunity"
    case patternRecognition = "pattern_recognition"
    case goalProgress = "goal_progress"
    case knowledgeGap = "knowledge_gap"
    case efficiency_improvement = "efficiency_improvement"

    var description: String {
        switch self {
        case .followUpQuestion: return "Natural follow-up question to explore deeper"
        case .topicExpansion: return "Expand current topic into related areas"
        case .skillBuilding: return "Opportunity to develop relevant skills"
        case .problemSolving: return "Suggest problem-solving approaches"
        case .goalAlignment: return "Align discussion with user goals"
        case .contextualInsight: return "Provide contextual insights from patterns"
        case .crossConversationLink: return "Connect to previous conversations"
        case .learningOpportunity: return "Educational opportunity based on interests"
        case .actionableNext: return "Actionable next steps based on conversation"
        case .clarificationRequest: return "Request clarification on ambiguous points"
        case .synthesisOpportunity: return "Synthesize multiple conversation threads"
        case .patternRecognition: return "Highlight patterns in user behavior or topics"
        case .goalProgress: return "Check progress toward stated goals"
        case .knowledgeGap: return "Address identified knowledge gaps"
        case .efficiency_improvement: return "Suggest more efficient approaches"
        }
    }

    var baseWeight: Double {
        switch self {
        case .actionableNext: return 1.0
        case .goalAlignment: return 0.95
        case .problemSolving: return 0.9
        case .followUpQuestion: return 0.85
        case .clarificationRequest: return 0.8
        case .topicExpansion: return 0.75
        case .synthesisOpportunity: return 0.75
        case .contextualInsight: return 0.7
        case .learningOpportunity: return 0.7
        case .crossConversationLink: return 0.65
        case .skillBuilding: return 0.6
        case .patternRecognition: return 0.6
        case .goalProgress: return 0.55
        case .knowledgeGap: return 0.5
        case .efficiency_improvement: return 0.45
        }
    }
}

enum SuggestionCategory: String, CaseIterable {
    case conversational = "conversational"
    case educational = "educational"
    case procedural = "procedural"
    case analytical = "analytical"
    case creative = "creative"
    case strategic = "strategic"
    case tactical = "tactical"
    case reflective = "reflective"
    case exploratory = "exploratory"
    case decisive = "decisive"

    var description: String {
        switch self {
        case .conversational: return "Natural conversation flow suggestions"
        case .educational: return "Learning and knowledge development"
        case .procedural: return "Step-by-step process guidance"
        case .analytical: return "Analysis and evaluation suggestions"
        case .creative: return "Creative thinking and ideation"
        case .strategic: return "Strategic planning and direction"
        case .tactical: return "Tactical implementation suggestions"
        case .reflective: return "Reflection and introspection prompts"
        case .exploratory: return "Exploration and discovery opportunities"
        case .decisive: return "Decision-making support suggestions"
        }
    }
}

enum SuggestionPriority: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case contextual = "contextual"

    var weight: Double {
        switch self {
        case .critical: return 1.0
        case .high: return 0.8
        case .medium: return 0.6
        case .low: return 0.4
        case .contextual: return 0.5
        }
    }

    var description: String {
        switch self {
        case .critical: return "Critical suggestion requiring immediate attention"
        case .high: return "High priority with significant impact"
        case .medium: return "Moderately important suggestion"
        case .low: return "Low priority, optional enhancement"
        case .contextual: return "Priority depends on current context"
        }
    }
}

struct SuggestionContext {
    let currentTopic: String?
    let conversationPhase: ConversationPhase
    let userEngagementLevel: EngagementLevel
    let sessionDuration: TimeInterval
    let messagesSinceLastSuggestion: Int
    let relatedConversations: [UUID]
    let activeGoals: [String]
    let recentPatterns: [String]
    let environmentalFactors: [EnvironmentalFactor]
}

enum ConversationPhase: String, CaseIterable {
    case opening = "opening"
    case exploration = "exploration"
    case deepDive = "deep_dive"
    case analysis = "analysis"
    case synthesis = "synthesis"
    case conclusion = "conclusion"
    case transition = "transition"
    case pause = "pause"

    var description: String {
        switch self {
        case .opening: return "Conversation is just beginning"
        case .exploration: return "Exploring topics and directions"
        case .deepDive: return "Deep exploration of specific topics"
        case .analysis: return "Analyzing information and patterns"
        case .synthesis: return "Synthesizing insights and conclusions"
        case .conclusion: return "Wrapping up conversation"
        case .transition: return "Transitioning between topics"
        case .pause: return "Natural pause in conversation"
        }
    }
}

enum EngagementLevel: String, CaseIterable {
    case veryHigh = "very_high"
    case high = "high"
    case medium = "medium"
    case low = "low"
    case declining = "declining"

    var suggestionModifier: Double {
        switch self {
        case .veryHigh: return 1.2
        case .high: return 1.1
        case .medium: return 1.0
        case .low: return 0.9
        case .declining: return 0.8
        }
    }
}

struct EnvironmentalFactor {
    let factor: String
    let impact: Double
    let reasoning: String
}

struct SuggestionEvidence {
    let type: EvidenceType
    let description: String
    let strength: Double
    let source: EvidenceSource
    let timestamp: Date
}

enum EvidenceType: String, CaseIterable {
    case conversationPattern = "conversation_pattern"
    case userBehavior = "user_behavior"
    case topicAnalysis = "topic_analysis"
    case goalAlignment = "goal_alignment"
    case crossConversational = "cross_conversational"
    case temporalPattern = "temporal_pattern"
    case preferenceInference = "preference_inference"
    case contextualCue = "contextual_cue"
}

enum EvidenceSource: String, CaseIterable {
    case currentConversation = "current_conversation"
    case conversationHistory = "conversation_history"
    case userProfile = "user_profile"
    case patternAnalysis = "pattern_analysis"
    case crossReference = "cross_reference"
    case temporalAnalysis = "temporal_analysis"
}

struct SuggestionActionability {
    let isActionable: Bool
    let actionType: ActionType
    let complexity: ActionComplexity
    let timeToComplete: TimeEstimate
    let prerequisites: [String]
    let expectedOutcome: String
}

enum ActionType: String, CaseIterable {
    case immediate = "immediate"
    case research = "research"
    case planning = "planning"
    case execution = "execution"
    case reflection = "reflection"
    case decision = "decision"
}

enum ActionComplexity: String, CaseIterable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case expert = "expert"
}

enum TimeEstimate: String, CaseIterable {
    case immediate = "immediate"        // < 1 minute
    case quick = "quick"               // 1-5 minutes
    case moderate = "moderate"         // 5-15 minutes
    case extended = "extended"         // 15-60 minutes
    case longTerm = "long_term"        // > 1 hour
}

struct PersonalizationAlignment {
    let alignsWithPreferences: Bool
    let alignmentScore: Double
    let personalizedElements: [PersonalizedElement]
    let adaptationReasoning: String
}

struct PersonalizedElement {
    let element: String
    let personalizationType: PersonalizationType
    let confidenceLevel: Double
}

enum PersonalizationType: String, CaseIterable {
    case communicationStyle = "communication_style"
    case contentDepth = "content_depth"
    case interactionPace = "interaction_pace"
    case learningStyle = "learning_style"
    case topicPreference = "topic_preference"
    case goalOrientation = "goal_orientation"
}

struct TemporalRelevance {
    let timeScore: Double
    let urgency: UrgencyLevel
    let temporalWindow: TemporalWindow
    let expirationReason: String?
}

enum UrgencyLevel: String, CaseIterable {
    case immediate = "immediate"
    case soon = "soon"
    case moderate = "moderate"
    case eventual = "eventual"
    case flexible = "flexible"
}

enum TemporalWindow: String, CaseIterable {
    case now = "now"
    case thisSession = "this_session"
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    case ongoing = "ongoing"
}

struct AdaptiveProperties {
    let learningRate: Double
    let adaptationTriggers: [AdaptationTrigger]
    let contextSensitivity: ContextSensitivity
    let feedbackIntegration: FeedbackIntegration
}

enum AdaptationTrigger: String, CaseIterable {
    case userFeedback = "user_feedback"
    case contextChange = "context_change"
    case performanceMetric = "performance_metric"
    case temporalShift = "temporal_shift"
    case goalUpdate = "goal_update"
}

enum ContextSensitivity: String, CaseIterable {
    case high = "high"
    case moderate = "moderate"
    case low = "low"
    case adaptive = "adaptive"
}

enum FeedbackIntegration: String, CaseIterable {
    case immediate = "immediate"
    case gradual = "gradual"
    case batch = "batch"
    case manual = "manual"
}

struct InteractionHint {
    let hint: String
    let hintType: HintType
    let applicability: HintApplicability
}

enum HintType: String, CaseIterable {
    case phrasing = "phrasing"
    case timing = "timing"
    case context = "context"
    case approach = "approach"
    case followUp = "follow_up"
}

enum HintApplicability: String, CaseIterable {
    case always = "always"
    case contextual = "contextual"
    case conditional = "conditional"
    case experimental = "experimental"
}

struct SuggestionUsageTracking {
    let timesShown: Int
    let timesSelected: Int
    let averageRelevanceRating: Double?
    let lastShown: Date?
    let lastSelected: Date?
    let contextSuccessRate: Double
    let adaptationHistory: [SuggestionAdaptation]
}

struct SuggestionAdaptation {
    let timestamp: Date
    let originalSuggestion: String
    let adaptedSuggestion: String
    let adaptationReason: String
    let effectiveness: Double?
}

// MARK: - Smart Context Suggestion Engine

@MainActor
class SmartContextSuggestionEngine: ObservableObject {
    // MARK: - Published Properties

    @Published var isGenerating = false
    @Published var contextualSuggestions: [SmartContextSuggestion] = []
    @Published var suggestionProgress: Double = 0.0
    @Published var currentOperation: String = ""
    @Published var suggestionMetrics: SuggestionMetrics = SuggestionMetrics()

    // MARK: - Dependencies

    private let conversationManager: ConversationManager
    private let memoryManager: ConversationMemoryManager
    private let conversationIntelligence: ConversationIntelligence
    private let personalizationEngine: UserPersonalizationEngine
    private let conversationLinker: ConversationLinker
    private let logger = Logger(subsystem: "com.jarvis.suggestions", category: "SmartContextSuggestionEngine")

    // MARK: - Configuration

    private let maxSuggestionsPerContext = 8
    private let suggestionRefreshInterval: TimeInterval = 300 // 5 minutes
    private let minRelevanceThreshold = 0.4
    private let adaptationLearningRate = 0.1
    private let contextWindowSize = 10

    // MARK: - Pattern Recognition

    private let patternRecognizer = ConversationPatternRecognizer()
    private let contextAnalyzer = ContextualAnalyzer()
    private let suggestionOptimizer = SuggestionOptimizer()

    // MARK: - Cache and State

    private var suggestionCache: [String: [SmartContextSuggestion]] = [:]
    private var patternCache: [String: ConversationPattern] = [:]
    private var adaptationRules: [AdaptationRule] = []
    private var performanceMetrics: [String: Double] = [:]
    private var lastGenerationTime: Date?

    // MARK: - Publishers

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        conversationManager: ConversationManager,
        memoryManager: ConversationMemoryManager,
        conversationIntelligence: ConversationIntelligence,
        personalizationEngine: UserPersonalizationEngine,
        conversationLinker: ConversationLinker
    ) {
        self.conversationManager = conversationManager
        self.memoryManager = memoryManager
        self.conversationIntelligence = conversationIntelligence
        self.personalizationEngine = personalizationEngine
        self.conversationLinker = conversationLinker

        setupSuggestionMonitoring()
        loadAdaptationRules()
    }

    private func setupSuggestionMonitoring() {
        // Monitor conversation updates
        conversationManager.$currentConversation
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] conversation in
                if let conversation = conversation {
                    Task { @MainActor in
                        await self?.generateContextualSuggestions(for: conversation)
                    }
                }
            }
            .store(in: &cancellables)

        // Monitor personalization updates
        personalizationEngine.$userProfile
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] profile in
                if profile != nil {
                    Task { @MainActor in
                        await self?.updatePersonalizationAdaptations()
                    }
                }
            }
            .store(in: &cancellables)

        // Periodic suggestion refresh
        Timer.scheduledTimer(withTimeInterval: suggestionRefreshInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.refreshContextualSuggestions()
            }
        }
    }

    // MARK: - Core Suggestion Generation

    func generateContextualSuggestions(for conversation: Conversation) async {
        isGenerating = true
        suggestionProgress = 0.0
        currentOperation = "Analyzing conversation context..."

        logger.info("Generating contextual suggestions for: \(conversation.title)")

        // Check cache first
        let cacheKey = generateCacheKey(for: conversation)
        if let cached = suggestionCache[cacheKey],
           let lastGeneration = lastGenerationTime,
           Date().timeIntervalSince(lastGeneration) < suggestionRefreshInterval {
            contextualSuggestions = cached
            isGenerating = false
            return
        }

        do {
            // Step 1: Analyze current context
            currentOperation = "Analyzing current context..."
            suggestionProgress = 0.1
            let context = await analyzeCurrentContext(for: conversation)

            // Step 2: Identify conversation patterns
            currentOperation = "Identifying conversation patterns..."
            suggestionProgress = 0.2
            let patterns = await identifyConversationPatterns(conversation: conversation, context: context)

            // Step 3: Generate base suggestions
            currentOperation = "Generating base suggestions..."
            suggestionProgress = 0.3
            let baseSuggestions = await generateBaseSuggestions(conversation: conversation, context: context, patterns: patterns)

            // Step 4: Apply personalization
            currentOperation = "Applying personalization..."
            suggestionProgress = 0.5
            let personalizedSuggestions = await applyPersonalization(suggestions: baseSuggestions, conversation: conversation)

            // Step 5: Cross-conversation analysis
            currentOperation = "Analyzing cross-conversation connections..."
            suggestionProgress = 0.6
            let crossConversationalSuggestions = await generateCrossConversationalSuggestions(conversation: conversation)

            // Step 6: Goal alignment suggestions
            currentOperation = "Generating goal-aligned suggestions..."
            suggestionProgress = 0.7
            let goalAlignedSuggestions = await generateGoalAlignedSuggestions(conversation: conversation, context: context)

            // Step 7: Pattern-based suggestions
            currentOperation = "Generating pattern-based suggestions..."
            suggestionProgress = 0.8
            let patternBasedSuggestions = await generatePatternBasedSuggestions(patterns: patterns, context: context)

            // Step 8: Combine and optimize
            currentOperation = "Optimizing suggestion mix..."
            suggestionProgress = 0.9
            let allSuggestions = personalizedSuggestions + crossConversationalSuggestions + goalAlignedSuggestions + patternBasedSuggestions
            let optimizedSuggestions = await optimizeSuggestionMix(suggestions: allSuggestions, context: context)

            // Step 9: Apply adaptive learning
            currentOperation = "Applying adaptive learning..."
            suggestionProgress = 0.95
            let adaptedSuggestions = await applyAdaptiveLearning(suggestions: optimizedSuggestions)

            // Update state
            contextualSuggestions = Array(adaptedSuggestions.prefix(maxSuggestionsPerContext))
            suggestionCache[cacheKey] = contextualSuggestions
            lastGenerationTime = Date()

            // Update metrics
            updateSuggestionMetrics(suggestions: contextualSuggestions)

            suggestionProgress = 1.0
            currentOperation = "Suggestions generated"
            isGenerating = false

            logger.info("Generated \(contextualSuggestions.count) contextual suggestions")
        } catch {
            logger.error("Failed to generate contextual suggestions: \(error)")
            isGenerating = false
        }
    }

    func getSuggestionsForContext(_ contextType: String) -> [SmartContextSuggestion] {
        return contextualSuggestions.filter { suggestion in
            suggestion.category.rawValue.contains(contextType) ||
            suggestion.type.rawValue.contains(contextType)
        }.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    func recordSuggestionUsage(_ suggestion: SmartContextSuggestion, wasUsed: Bool, userRating: Double? = nil) {
        // Record usage for adaptation learning
        let adaptationData = SuggestionAdaptationData(
            suggestionId: suggestion.id,
            wasUsed: wasUsed,
            userRating: userRating,
            context: suggestion.context,
            timestamp: Date()
        )

        Task {
            await learnFromSuggestionUsage(adaptationData)
        }
    }

    func requestSuggestionAdaptation(for suggestion: SmartContextSuggestion, feedback: String) async {
        await adaptSuggestionBasedOnFeedback(suggestion: suggestion, feedback: feedback)
    }

    // MARK: - Context Analysis

    private func analyzeCurrentContext(for conversation: Conversation) async -> SuggestionContext {
        let messages = conversation.messagesArray
        let recentMessages = Array(messages.suffix(contextWindowSize))

        // Determine conversation phase
        let conversationPhase = determineConversationPhase(messages: messages)

        // Assess engagement level
        let engagementLevel = assessEngagementLevel(recentMessages: recentMessages)

        // Calculate session duration
        let sessionDuration = messages.isEmpty ? 0 : Date().timeIntervalSince(messages.first!.timestamp)

        // Find related conversations
        let relatedConversations = await conversationLinker.findLinkedConversations(for: conversation)
        let relatedIds = relatedConversations.map { $0.targetConversationId }

        // Extract current topics
        let currentTopic = extractCurrentTopic(from: recentMessages)

        // Identify active goals
        let activeGoals = await identifyActiveGoals(conversation: conversation)

        // Analyze recent patterns
        let recentPatterns = await analyzeRecentPatterns(conversation: conversation)

        // Assess environmental factors
        let environmentalFactors = assessEnvironmentalFactors()

        return SuggestionContext(
            currentTopic: currentTopic,
            conversationPhase: conversationPhase,
            userEngagementLevel: engagementLevel,
            sessionDuration: sessionDuration,
            messagesSinceLastSuggestion: recentMessages.count,
            relatedConversations: relatedIds,
            activeGoals: activeGoals,
            recentPatterns: recentPatterns,
            environmentalFactors: environmentalFactors
        )
    }

    private func identifyConversationPatterns(conversation: Conversation, context: SuggestionContext) async -> [ConversationPattern] {
        let cacheKey = "patterns_\(conversation.id.uuidString)"

        if let cached = patternCache[cacheKey] {
            return [cached]
        }

        let patterns = await patternRecognizer.identify(
            conversation: conversation,
            context: context,
            historicalData: conversationManager.conversations
        )

        // Cache the primary pattern
        if let primaryPattern = patterns.first {
            patternCache[cacheKey] = primaryPattern
        }

        return patterns
    }

    // MARK: - Base Suggestion Generation

    private func generateBaseSuggestions(conversation: Conversation, context: SuggestionContext, patterns: [ConversationPattern]) async -> [SmartContextSuggestion] {
        var suggestions: [SmartContextSuggestion] = []

        // Generate phase-appropriate suggestions
        suggestions += await generatePhaseBasedSuggestions(phase: context.conversationPhase, conversation: conversation)

        // Generate topic-driven suggestions
        if let topic = context.currentTopic {
            suggestions += await generateTopicDrivenSuggestions(topic: topic, conversation: conversation)
        }

        // Generate engagement-appropriate suggestions
        suggestions += await generateEngagementBasedSuggestions(engagement: context.userEngagementLevel, conversation: conversation)

        // Generate pattern-driven suggestions
        for pattern in patterns {
            suggestions += await generatePatternDrivenSuggestions(pattern: pattern, conversation: conversation)
        }

        return suggestions
    }

    private func generatePhaseBasedSuggestions(phase: ConversationPhase, conversation: Conversation) async -> [SmartContextSuggestion] {
        var suggestions: [SmartContextSuggestion] = []

        switch phase {
        case .opening:
            suggestions.append(createSuggestion(
                text: "What specific aspect would you like to explore first?",
                type: .followUpQuestion,
                category: .conversational,
                relevanceScore: 0.8,
                reasoning: "Opening phase benefits from direction-setting questions"
            ))

        case .exploration:
            suggestions.append(createSuggestion(
                text: "Let's dive deeper into the most interesting aspect you mentioned",
                type: .topicExpansion,
                category: .exploratory,
                relevanceScore: 0.85,
                reasoning: "Exploration phase is ideal for topic expansion"
            ))

        case .deepDive:
            suggestions.append(createSuggestion(
                text: "Based on this analysis, what would be your next practical step?",
                type: .actionableNext,
                category: .procedural,
                relevanceScore: 0.9,
                reasoning: "Deep dive phase should lead to actionable insights"
            ))

        case .analysis:
            suggestions.append(createSuggestion(
                text: "What patterns do you notice emerging from our discussion?",
                type: .patternRecognition,
                category: .analytical,
                relevanceScore: 0.8,
                reasoning: "Analysis phase benefits from pattern recognition"
            ))

        case .synthesis:
            suggestions.append(createSuggestion(
                text: "How do these insights connect to your broader goals?",
                type: .goalAlignment,
                category: .strategic,
                relevanceScore: 0.9,
                reasoning: "Synthesis phase should connect to larger goals"
            ))

        case .conclusion:
            suggestions.append(createSuggestion(
                text: "What key takeaways would you like to remember from this conversation?",
                type: .synthesisOpportunity,
                category: .reflective,
                relevanceScore: 0.85,
                reasoning: "Conclusion phase benefits from synthesis and reflection"
            ))

        case .transition:
            suggestions.append(createSuggestion(
                text: "Would you like to explore a related topic or focus on something different?",
                type: .topicExpansion,
                category: .conversational,
                relevanceScore: 0.7,
                reasoning: "Transition phase offers opportunity for topic shifts"
            ))

        case .pause:
            suggestions.append(createSuggestion(
                text: "Is there anything you'd like to clarify before we continue?",
                type: .clarificationRequest,
                category: .conversational,
                relevanceScore: 0.6,
                reasoning: "Pause phase is good for clarification"
            ))
        }

        return suggestions
    }

    private func generateTopicDrivenSuggestions(topic: String, conversation: Conversation) async -> [SmartContextSuggestion] {
        var suggestions: [SmartContextSuggestion] = []

        // Knowledge expansion suggestions
        suggestions.append(createSuggestion(
            text: "Would you like to explore the practical applications of \(topic)?",
            type: .learningOpportunity,
            category: .educational,
            relevanceScore: 0.75,
            reasoning: "Topic-focused learning opportunity"
        ))

        // Skill building suggestions
        suggestions.append(createSuggestion(
            text: "What specific skills related to \(topic) would you like to develop?",
            type: .skillBuilding,
            category: .educational,
            relevanceScore: 0.7,
            reasoning: "Skill development aligned with current topic"
        ))

        // Problem-solving suggestions
        suggestions.append(createSuggestion(
            text: "What challenges have you encountered with \(topic) in practice?",
            type: .problemSolving,
            category: .analytical,
            relevanceScore: 0.8,
            reasoning: "Problem identification related to current topic"
        ))

        return suggestions
    }

    private func generateEngagementBasedSuggestions(engagement: EngagementLevel, conversation: Conversation) async -> [SmartContextSuggestion] {
        var suggestions: [SmartContextSuggestion] = []

        switch engagement {
        case .veryHigh:
            suggestions.append(createSuggestion(
                text: "You seem really engaged with this topic! What aspect excites you most?",
                type: .followUpQuestion,
                category: .conversational,
                relevanceScore: 0.9,
                reasoning: "High engagement warrants deeper exploration"
            ))

        case .high:
            suggestions.append(createSuggestion(
                text: "Let's explore this further - what would you like to understand better?",
                type: .topicExpansion,
                category: .exploratory,
                relevanceScore: 0.8,
                reasoning: "High engagement supports topic expansion"
            ))

        case .medium:
            suggestions.append(createSuggestion(
                text: "Would it help to look at this from a different angle?",
                type: .contextualInsight,
                category: .analytical,
                relevanceScore: 0.7,
                reasoning: "Medium engagement may benefit from new perspectives"
            ))

        case .low:
            suggestions.append(createSuggestion(
                text: "Is there a more relevant aspect of this topic you'd prefer to focus on?",
                type: .topicExpansion,
                category: .conversational,
                relevanceScore: 0.6,
                reasoning: "Low engagement suggests need for topic adjustment"
            ))

        case .declining:
            suggestions.append(createSuggestion(
                text: "Would you like to take a different approach or switch to something else?",
                type: .efficiency_improvement,
                category: .strategic,
                relevanceScore: 0.8,
                reasoning: "Declining engagement requires intervention"
            ))
        }

        return suggestions
    }

    // MARK: - Advanced Suggestion Generation

    private func applyPersonalization(suggestions: [SmartContextSuggestion], conversation: Conversation) async -> [SmartContextSuggestion] {
        guard let userProfile = personalizationEngine.userProfile else {
            return suggestions
        }

        return suggestions.map { suggestion in
            var personalizedSuggestion = suggestion

            // Adapt communication style
            if let adaptedText = adaptToCommuncationStyle(
                text: suggestion.text,
                style: userProfile.communicationPreferences.primaryStyle
            ) {
                personalizedSuggestion.text = adaptedText
            }

            // Adjust for content preferences
            let contentAlignment = calculateContentAlignment(
                suggestion: suggestion,
                preferences: userProfile.contentPreferences
            )
            personalizedSuggestion.relevanceScore *= contentAlignment

            // Apply personalization alignment
            let personalizationAlignment = PersonalizationAlignment(
                alignsWithPreferences: contentAlignment > 0.7,
                alignmentScore: contentAlignment,
                personalizedElements: extractPersonalizedElements(suggestion: suggestion, profile: userProfile),
                adaptationReasoning: "Adapted to user's \(userProfile.communicationPreferences.primaryStyle.rawValue) communication style"
            )
            personalizedSuggestion.personalization = personalizationAlignment

            return personalizedSuggestion
        }
    }

    private func generateCrossConversationalSuggestions(conversation: Conversation) async -> [SmartContextSuggestion] {
        let relatedConversations = await conversationLinker.findLinkedConversations(for: conversation)
        var suggestions: [SmartContextSuggestion] = []

        for link in relatedConversations.prefix(3) {
            if let relatedConv = conversationManager.conversations.first(where: { $0.id == link.targetConversationId }) {
                suggestions.append(createSuggestion(
                    text: "This connects to our previous discussion about \(relatedConv.title). Should we explore that connection?",
                    type: .crossConversationLink,
                    category: .analytical,
                    relevanceScore: link.strength,
                    reasoning: "Strong connection to previous conversation with \(String(format: "%.1f", link.strength * 100))% similarity"
                ))
            }
        }

        return suggestions
    }

    private func generateGoalAlignedSuggestions(conversation: Conversation, context: SuggestionContext) async -> [SmartContextSuggestion] {
        var suggestions: [SmartContextSuggestion] = []

        for goal in context.activeGoals {
            suggestions.append(createSuggestion(
                text: "How does this relate to your goal of \(goal)?",
                type: .goalAlignment,
                category: .strategic,
                relevanceScore: 0.85,
                reasoning: "Alignment with active user goal"
            ))

            suggestions.append(createSuggestion(
                text: "What's your next step toward achieving \(goal)?",
                type: .goalProgress,
                category: .tactical,
                relevanceScore: 0.8,
                reasoning: "Progress tracking for active goal"
            ))
        }

        return suggestions
    }

    private func generatePatternBasedSuggestions(patterns: [ConversationPattern], context: SuggestionContext) async -> [SmartContextSuggestion] {
        var suggestions: [SmartContextSuggestion] = []

        for pattern in patterns {
            switch pattern.type {
            case .questionAsking:
                suggestions.append(createSuggestion(
                    text: "I notice you ask thoughtful questions. What would you like to explore next?",
                    type: .patternRecognition,
                    category: .conversational,
                    relevanceScore: pattern.confidence,
                    reasoning: "Recognized pattern of thoughtful questioning"
                ))

            case .problemSolving:
                suggestions.append(createSuggestion(
                    text: "You have a systematic approach to problems. Should we break this down step by step?",
                    type: .problemSolving,
                    category: .procedural,
                    relevanceScore: pattern.confidence,
                    reasoning: "Recognized systematic problem-solving pattern"
                ))

            case .learning:
                suggestions.append(createSuggestion(
                    text: "You seem to enjoy learning new concepts. Would you like to dive deeper into the theory?",
                    type: .learningOpportunity,
                    category: .educational,
                    relevanceScore: pattern.confidence,
                    reasoning: "Recognized strong learning orientation"
                ))

            case .goalOriented:
                suggestions.append(createSuggestion(
                    text: "You're very goal-focused. How can we make this more actionable?",
                    type: .actionableNext,
                    category: .tactical,
                    relevanceScore: pattern.confidence,
                    reasoning: "Recognized goal-oriented conversation pattern"
                ))
            }
        }

        return suggestions
    }

    private func optimizeSuggestionMix(suggestions: [SmartContextSuggestion], context: SuggestionContext) async -> [SmartContextSuggestion] {
        // Remove duplicates and low-relevance suggestions
        let filtered = suggestions.filter { $0.relevanceScore >= minRelevanceThreshold }
        let unique = removeDuplicateSuggestions(filtered)

        // Balance suggestion types
        let balanced = balanceSuggestionTypes(unique)

        // Apply temporal relevance
        let temporallyRelevant = applyTemporalRelevance(balanced, context: context)

        // Sort by relevance score
        return temporallyRelevant.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    private func applyAdaptiveLearning(suggestions: [SmartContextSuggestion]) async -> [SmartContextSuggestion] {
        return suggestions.map { suggestion in
            var adaptedSuggestion = suggestion

            // Apply learned adaptations
            for rule in adaptationRules {
                if rule.appliesTo(suggestion) {
                    adaptedSuggestion = rule.apply(to: adaptedSuggestion)
                }
            }

            return adaptedSuggestion
        }
    }

    // MARK: - Helper Methods

    private func createSuggestion(
        text: String,
        type: SmartSuggestionType,
        category: SuggestionCategory,
        relevanceScore: Double,
        reasoning: String
    ) -> SmartContextSuggestion {
        SmartContextSuggestion(
            id: UUID(),
            text: text,
            type: type,
            category: category,
            relevanceScore: relevanceScore * type.baseWeight,
            confidence: 0.8,
            priority: determinePriority(type: type, relevanceScore: relevanceScore),
            context: SuggestionContext(
                currentTopic: nil,
                conversationPhase: .exploration,
                userEngagementLevel: .medium,
                sessionDuration: 0,
                messagesSinceLastSuggestion: 0,
                relatedConversations: [],
                activeGoals: [],
                recentPatterns: [],
                environmentalFactors: []
            ),
            reasoning: reasoning,
            evidence: [],
            actionability: SuggestionActionability(
                isActionable: true,
                actionType: .immediate,
                complexity: .simple,
                timeToComplete: .quick,
                prerequisites: [],
                expectedOutcome: "Enhanced conversation flow"
            ),
            personalization: PersonalizationAlignment(
                alignsWithPreferences: true,
                alignmentScore: 0.7,
                personalizedElements: [],
                adaptationReasoning: "Base suggestion without personalization"
            ),
            temporalRelevance: TemporalRelevance(
                timeScore: 1.0,
                urgency: .moderate,
                temporalWindow: .thisSession,
                expirationReason: nil
            ),
            adaptiveProperties: AdaptiveProperties(
                learningRate: adaptationLearningRate,
                adaptationTriggers: [.userFeedback, .contextChange],
                contextSensitivity: .moderate,
                feedbackIntegration: .immediate
            ),
            interactionHints: [],
            relatedSuggestions: [],
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(3600), // 1 hour
            usageTracking: SuggestionUsageTracking(
                timesShown: 0,
                timesSelected: 0,
                averageRelevanceRating: nil,
                lastShown: nil,
                lastSelected: nil,
                contextSuccessRate: 0.0,
                adaptationHistory: []
            )
        )
    }

    private func generateCacheKey(for conversation: Conversation) -> String {
        let messageCount = conversation.messagesArray.count
        let lastUpdate = conversation.updatedAt.timeIntervalSince1970
        return "suggestions_\(conversation.id.uuidString)_\(messageCount)_\(Int(lastUpdate))"
    }

    private func determineConversationPhase(messages: [ConversationMessage]) -> ConversationPhase {
        guard !messages.isEmpty else { return .opening }

        let messageCount = messages.count
        let recentMessages = Array(messages.suffix(5))

        // Analyze message patterns to determine phase
        if messageCount <= 3 {
            return .opening
        } else if messageCount <= 10 {
            return .exploration
        } else if hasDeepAnalysisIndicators(messages: recentMessages) {
            return .analysis
        } else if hasSynthesisIndicators(messages: recentMessages) {
            return .synthesis
        } else if hasDeepDiveIndicators(messages: recentMessages) {
            return .deepDive
        } else {
            return .exploration
        }
    }

    private func assessEngagementLevel(recentMessages: [ConversationMessage]) -> EngagementLevel {
        guard !recentMessages.isEmpty else { return .medium }

        let userMessages = recentMessages.filter { $0.role == "user" }
        let averageLength = userMessages.map { $0.content.count }.reduce(0, +) / max(userMessages.count, 1)
        let questionCount = userMessages.filter { $0.content.contains("?") }.count
        let engagementWords = ["interesting", "fascinating", "tell me more", "explain", "how", "why"]
        let engagementScore = userMessages.reduce(0) { score, message in
            score + engagementWords.filter { message.content.lowercased().contains($0) }.count
        }

        let totalScore = Double(averageLength) / 100.0 + Double(questionCount) * 0.5 + Double(engagementScore) * 0.3

        if totalScore > 2.0 {
            return .veryHigh
        } else if totalScore > 1.5 {
            return .high
        } else if totalScore > 1.0 {
            return .medium
        } else if totalScore > 0.5 {
            return .low
        } else {
            return .declining
        }
    }

    private func extractCurrentTopic(from messages: [ConversationMessage]) -> String? {
        guard let lastUserMessage = messages.last(where: { $0.role == "user" }) else {
            return nil
        }

        // Extract key nouns and topics from the last user message
        let words = lastUserMessage.content.components(separatedBy: .whitespacesAndNewlines)
        let meaningfulWords = words.filter { word in
            word.count > 3 && !["this", "that", "with", "from", "they", "them", "have", "been"].contains(word.lowercased())
        }

        return meaningfulWords.first
    }

    private func identifyActiveGoals(conversation: Conversation) async -> [String] {
        let messages = conversation.messagesArray.filter { $0.role == "user" }
        let goalIndicators = ["goal", "objective", "want to", "trying to", "hoping to", "plan to", "need to"]
        var goals: [String] = []

        for message in messages {
            let content = message.content.lowercased()
            for indicator in goalIndicators {
                if content.contains(indicator) {
                    // Extract sentence containing the goal
                    let sentences = message.content.components(separatedBy: ". ")
                    for sentence in sentences {
                        if sentence.lowercased().contains(indicator) {
                            goals.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                            break
                        }
                    }
                }
            }
        }

        return Array(Set(goals)) // Remove duplicates
    }

    private func analyzeRecentPatterns(conversation: Conversation) async -> [String] {
        // Simplified pattern analysis
        let messages = conversation.messagesArray.suffix(10)
        let userMessages = messages.filter { $0.role == "user" }

        var patterns: [String] = []

        // Question pattern
        let questionCount = userMessages.filter { $0.content.contains("?") }.count
        if questionCount > userMessages.count / 2 {
            patterns.append("question_heavy")
        }

        // Detail seeking pattern
        let detailWords = ["explain", "detail", "specific", "example", "how"]
        let detailCount = userMessages.reduce(0) { count, message in
            count + detailWords.filter { message.content.lowercased().contains($0) }.count
        }
        if detailCount > 2 {
            patterns.append("detail_seeking")
        }

        // Problem solving pattern
        let problemWords = ["problem", "issue", "challenge", "solve", "solution"]
        let problemCount = userMessages.reduce(0) { count, message in
            count + problemWords.filter { message.content.lowercased().contains($0) }.count
        }
        if problemCount > 1 {
            patterns.append("problem_solving")
        }

        return patterns
    }

    private func assessEnvironmentalFactors() -> [EnvironmentalFactor] {
        var factors: [EnvironmentalFactor] = []

        // Time of day factor
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 || hour <= 6 {
            factors.append(EnvironmentalFactor(
                factor: "late_hour",
                impact: 0.8,
                reasoning: "Late hour may affect user attention and preference for briefer interactions"
            ))
        }

        // Day of week factor
        let weekday = Calendar.current.component(.weekday, from: Date())
        if weekday == 1 || weekday == 7 { // Sunday or Saturday
            factors.append(EnvironmentalFactor(
                factor: "weekend",
                impact: 1.1,
                reasoning: "Weekend may allow for more exploratory and creative conversations"
            ))
        }

        return factors
    }

    // MARK: - Utility Methods (Simplified Implementations)

    private func hasDeepAnalysisIndicators(messages: [ConversationMessage]) -> Bool {
        let analysisWords = ["analyze", "compare", "evaluate", "assess", "examine"]
        return messages.contains { message in
            analysisWords.contains { message.content.lowercased().contains($0) }
        }
    }

    private func hasSynthesisIndicators(messages: [ConversationMessage]) -> Bool {
        let synthesisWords = ["overall", "summary", "conclusion", "takeaway", "combine"]
        return messages.contains { message in
            synthesisWords.contains { message.content.lowercased().contains($0) }
        }
    }

    private func hasDeepDiveIndicators(messages: [ConversationMessage]) -> Bool {
        let deepDiveWords = ["deeper", "detail", "specific", "elaborate", "expand"]
        return messages.contains { message in
            deepDiveWords.contains { message.content.lowercased().contains($0) }
        }
    }

    private func determinePriority(type: SmartSuggestionType, relevanceScore: Double) -> SuggestionPriority {
        if relevanceScore > 0.9 {
            return .critical
        } else if relevanceScore > 0.7 {
            return .high
        } else if relevanceScore > 0.5 {
            return .medium
        } else {
            return .low
        }
    }

    private func adaptToCommuncationStyle(text: String, style: CommunicationStyle) -> String? {
        switch style {
        case .direct:
            return text.replacingOccurrences(of: "Would you like to", with: "Let's")
        case .supportive:
            return "I'm here to help. " + text
        case .analytical:
            return text.replacingOccurrences(of: "explore", with: "analyze")
        default:
            return nil
        }
    }

    private func calculateContentAlignment(suggestion: SmartContextSuggestion, preferences: ContentPreferences) -> Double {
        var alignment = 0.7 // Base alignment

        // Adjust for depth preference
        switch preferences.preferredDepth {
        case .surface:
            if suggestion.type == .followUpQuestion {
                alignment += 0.2
            }
        case .deep, .comprehensive:
            if suggestion.type == .topicExpansion || suggestion.type == .learningOpportunity {
                alignment += 0.2
            }
        default:
            break
        }

        return min(alignment, 1.0)
    }

    private func extractPersonalizedElements(suggestion: SmartContextSuggestion, profile: UserPersonalizationProfileDetailed) -> [PersonalizedElement] {
        var elements: [PersonalizedElement] = []

        elements.append(PersonalizedElement(
            element: "communication_style_adapted",
            personalizationType: .communicationStyle,
            confidenceLevel: profile.communicationPreferences.confidence
        ))

        return elements
    }

    private func removeDuplicateSuggestions(_ suggestions: [SmartContextSuggestion]) -> [SmartContextSuggestion] {
        var unique: [SmartContextSuggestion] = []
        var seenTexts: Set<String> = []

        for suggestion in suggestions {
            let normalizedText = suggestion.text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !seenTexts.contains(normalizedText) {
                seenTexts.insert(normalizedText)
                unique.append(suggestion)
            }
        }

        return unique
    }

    private func balanceSuggestionTypes(_ suggestions: [SmartContextSuggestion]) -> [SmartContextSuggestion] {
        let grouped = Dictionary(grouping: suggestions) { $0.type }
        var balanced: [SmartContextSuggestion] = []

        // Limit each type to avoid overwhelming
        for (_, typeSuggestions) in grouped {
            balanced += Array(typeSuggestions.prefix(2))
        }

        return balanced
    }

    private func applyTemporalRelevance(_ suggestions: [SmartContextSuggestion], context: SuggestionContext) -> [SmartContextSuggestion] {
        return suggestions.map { suggestion in
            var temporalSuggestion = suggestion

            // Adjust relevance based on temporal factors
            let timeAdjustment = calculateTemporalAdjustment(suggestion: suggestion, context: context)
            temporalSuggestion.relevanceScore *= timeAdjustment

            return temporalSuggestion
        }
    }

    private func calculateTemporalAdjustment(suggestion: SmartContextSuggestion, context: SuggestionContext) -> Double {
        var adjustment = 1.0

        // Adjust based on session duration
        if context.sessionDuration > 3600 { // Over 1 hour
            if suggestion.type == .actionableNext || suggestion.type == .synthesisOpportunity {
                adjustment += 0.2 // Prefer conclusion-oriented suggestions
            }
        }

        return adjustment
    }

    // MARK: - Learning and Adaptation

    private func learnFromSuggestionUsage(_ adaptationData: SuggestionAdaptationData) async {
        // Update performance metrics
        let suggestionTypeKey = adaptationData.suggestionId.uuidString
        let currentPerformance = performanceMetrics[suggestionTypeKey] ?? 0.5
        let newPerformance = adaptationData.wasUsed ? 1.0 : 0.0
        performanceMetrics[suggestionTypeKey] = currentPerformance * 0.9 + newPerformance * 0.1

        // Create adaptation rule if pattern emerges
        if let userRating = adaptationData.userRating, userRating < 0.5, adaptationData.wasUsed {
            // Low rating but was used - suggests suggestion needs improvement
            let rule = AdaptationRule(
                condition: "low_rating_but_used",
                action: "improve_suggestion_quality",
                effectiveness: 0.7
            )
            adaptationRules.append(rule)
        }
    }

    private func adaptSuggestionBasedOnFeedback(suggestion: SmartContextSuggestion, feedback: String) async {
        // Analyze feedback to create adaptation
        let adaptation = SuggestionAdaptation(
            timestamp: Date(),
            originalSuggestion: suggestion.text,
            adaptedSuggestion: adaptSuggestionText(suggestion.text, basedOn: feedback),
            adaptationReason: "User feedback: \(feedback)",
            effectiveness: nil
        )

        // Store adaptation for future use
        // In a real implementation, this would be persisted
        logger.info("Adapted suggestion based on feedback: \(feedback)")
    }

    private func adaptSuggestionText(_ originalText: String, basedOn feedback: String) -> String {
        // Simplified adaptation based on feedback
        if feedback.lowercased().contains("too formal") {
            return originalText.replacingOccurrences(of: "Would you like to", with: "Want to")
        } else if feedback.lowercased().contains("too casual") {
            return originalText.replacingOccurrences(of: "Want to", with: "Would you like to")
        }
        return originalText
    }

    private func updatePersonalizationAdaptations() async {
        // Update adaptation rules based on new personalization data
        logger.info("Updating personalization adaptations")
    }

    private func refreshContextualSuggestions() async {
        // Refresh suggestions if we have a current conversation
        if let currentConversation = conversationManager.currentConversation {
            await generateContextualSuggestions(for: currentConversation)
        }
    }

    private func updateSuggestionMetrics(suggestions: [SmartContextSuggestion]) {
        suggestionMetrics = SuggestionMetrics(
            totalGenerated: suggestions.count,
            averageRelevance: suggestions.map { $0.relevanceScore }.reduce(0, +) / Double(suggestions.count),
            typeDistribution: Dictionary(grouping: suggestions, by: { $0.type.rawValue }).mapValues { $0.count },
            averageConfidence: suggestions.map { $0.confidence }.reduce(0, +) / Double(suggestions.count),
            personalizationAlignment: suggestions.map { $0.personalization.alignmentScore }.reduce(0, +) / Double(suggestions.count)
        )
    }

    private func loadAdaptationRules() {
        // Load any persisted adaptation rules
        logger.info("Loading adaptation rules")
    }
}

// MARK: - Supporting Types

struct SuggestionMetrics {
    let totalGenerated: Int
    let averageRelevance: Double
    let typeDistribution: [String: Int]
    let averageConfidence: Double
    let personalizationAlignment: Double

    init() {
        totalGenerated = 0
        averageRelevance = 0.0
        typeDistribution = [:]
        averageConfidence = 0.0
        personalizationAlignment = 0.0
    }

    init(totalGenerated: Int, averageRelevance: Double, typeDistribution: [String: Int], averageConfidence: Double, personalizationAlignment: Double) {
        self.totalGenerated = totalGenerated
        self.averageRelevance = averageRelevance
        self.typeDistribution = typeDistribution
        self.averageConfidence = averageConfidence
        self.personalizationAlignment = personalizationAlignment
    }
}

struct SuggestionAdaptationData {
    let suggestionId: UUID
    let wasUsed: Bool
    let userRating: Double?
    let context: SuggestionContext
    let timestamp: Date
}

struct AdaptationRule {
    let condition: String
    let action: String
    let effectiveness: Double

    func appliesTo(_ suggestion: SmartContextSuggestion) -> Bool {
        // Simplified rule application logic
        return true
    }

    func apply(to suggestion: SmartContextSuggestion) -> SmartContextSuggestion {
        // Apply the adaptation rule
        return suggestion
    }
}

// MARK: - Pattern Recognition Components (Simplified)

class ConversationPatternRecognizer {
    func identify(conversation: Conversation, context: SuggestionContext, historicalData: [Conversation]) async -> [ConversationPattern] {
        // Simplified pattern recognition
        return [
            ConversationPattern(
                type: .questionAsking,
                confidence: 0.8,
                description: "User asks many questions",
                evidence: ["High question frequency in recent messages"]
            ),
        ]
    }
}

class ContextualAnalyzer {
    func analyze(context: SuggestionContext) -> [String: Double] {
        // Simplified contextual analysis
        return ["engagement": 0.8, "focus": 0.7, "depth": 0.6]
    }
}

class SuggestionOptimizer {
    func optimize(suggestions: [SmartContextSuggestion], context: SuggestionContext) -> [SmartContextSuggestion] {
        // Simplified optimization
        return suggestions.sorted { $0.relevanceScore > $1.relevanceScore }
    }
}

struct ConversationPattern {
    let type: PatternType
    let confidence: Double
    let description: String
    let evidence: [String]

    enum PatternType {
        case questionAsking
        case problemSolving
        case learning
        case goalOriented
    }
}
