// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Advanced conversation intelligence system for sophisticated context management and cross-session memory
 * Issues & Complexity Summary: Complex intelligence system with context analysis, summarization, relationship mapping, and personalization
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~1500
 *   - Core Algorithm Complexity: Very High (AI-driven analysis, semantic understanding, relationship mapping)
 *   - Dependencies: 8 New (CoreData, Foundation, Combine, SwiftUI, NaturalLanguage, GameplayKit, Network, OSLog)
 *   - State Management Complexity: Very High (Intelligence state, context relationships, cross-conversation linking)
 *   - Novelty/Uncertainty Factor: Very High (Advanced AI-driven intelligence, semantic analysis)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 95%
 * Problem Estimate (Inherent Problem Difficulty %): 92%
 * Initial Code Complexity Estimate %: 95%
 * Justification for Estimates: Advanced AI-driven conversation intelligence with semantic understanding and cross-session memory
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-26
 */

import Foundation
import CoreData
import Combine
import SwiftUI
import NaturalLanguage
import GameplayKit
import Network
import OSLog

// MARK: - Enhanced Data Models for Intelligence

struct ConversationSummary {
    let id: UUID
    let conversationId: UUID
    let title: String
    let keyPoints: [String]
    let mainTopics: [String]
    let sentiment: ConversationSentiment
    let participantInsights: [String]
    let actionItems: [String]
    let followUpSuggestions: [String]
    let confidence: Double
    let createdAt: Date
    let wordCount: Int
    let duration: TimeInterval
}

struct ConversationSentiment {
    let overall: String // "positive", "negative", "neutral", "mixed"
    let confidence: Double
    let emotionalTone: String // "professional", "casual", "urgent", "supportive"
    let intensityScore: Double // 0.0 - 1.0
    let keyEmotions: [String]
}

struct ConversationRelationship {
    let id: UUID
    let primaryConversationId: UUID
    let relatedConversationId: UUID
    let relationshipType: RelationshipType
    let strength: Double
    let commonTopics: [String]
    let commonEntities: [String]
    let temporalDistance: TimeInterval
    let contextualSimilarity: Double
    let createdAt: Date
}

enum RelationshipType: String, CaseIterable {
    case continuation = "continuation"
    case followUp = "follow_up"
    case related = "related"
    case reference = "reference"
    case topicalSimilarity = "topical_similarity"
    case temporalSequence = "temporal_sequence"
    case userPatternMatch = "user_pattern_match"

    var description: String {
        switch self {
        case .continuation: return "Direct continuation of previous conversation"
        case .followUp: return "Follow-up discussion on previous topic"
        case .related: return "Related discussion with shared context"
        case .reference: return "References or mentions previous conversation"
        case .topicalSimilarity: return "Similar topics or themes"
        case .temporalSequence: return "Part of temporal conversation sequence"
        case .userPatternMatch: return "Matches user behavioral pattern"
        }
    }
}

struct ContextSuggestion {
    let id: UUID
    let text: String
    let type: SuggestionType
    let relevanceScore: Double
    let sourceContext: String
    let reasoning: String
    let actionable: Bool
    let priority: SuggestionPriority
    let relatedConversationIds: [UUID]
    let createdAt: Date
}

enum SuggestionType: String, CaseIterable {
    case question = "question"
    case topic = "topic"
    case action = "action"
    case information = "information"
    case clarification = "clarification"
    case continuation = "continuation"
    case deepDive = "deep_dive"
    case synthesis = "synthesis"

    var description: String {
        switch self {
        case .question: return "Suggested question to ask"
        case .topic: return "Related topic to explore"
        case .action: return "Recommended action to take"
        case .information: return "Relevant information to consider"
        case .clarification: return "Clarification needed"
        case .continuation: return "Natural conversation continuation"
        case .deepDive: return "Deeper exploration opportunity"
        case .synthesis: return "Synthesis of multiple conversation threads"
        }
    }
}

enum SuggestionPriority: String, CaseIterable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"

    var weight: Double {
        switch self {
        case .critical: return 1.0
        case .high: return 0.8
        case .medium: return 0.6
        case .low: return 0.4
        }
    }
}

struct IntelligenceInsight {
    let id: UUID
    let type: InsightType
    let title: String
    let description: String
    let confidence: Double
    let impact: InsightImpact
    let recommendation: String
    let supportingEvidence: [String]
    let relatedConversations: [UUID]
    let createdAt: Date
    let expiresAt: Date?
}

enum InsightType: String, CaseIterable {
    case userBehavior = "user_behavior"
    case topicEvolution = "topic_evolution"
    case conversationPattern = "conversation_pattern"
    case preferenceShift = "preference_shift"
    case knowledgeGap = "knowledge_gap"
    case goalAlignment = "goal_alignment"
    case communicationStyle = "communication_style"
    case contextualConnection = "contextual_connection"

    var description: String {
        switch self {
        case .userBehavior: return "User behavior pattern"
        case .topicEvolution: return "Topic evolution over time"
        case .conversationPattern: return "Conversation flow pattern"
        case .preferenceShift: return "Change in user preferences"
        case .knowledgeGap: return "Identified knowledge gap"
        case .goalAlignment: return "Goal alignment analysis"
        case .communicationStyle: return "Communication style insight"
        case .contextualConnection: return "Cross-conversation connection"
        }
    }
}

enum InsightImpact: String, CaseIterable {
    case transformative = "transformative"
    case significant = "significant"
    case moderate = "moderate"
    case minor = "minor"

    var score: Double {
        switch self {
        case .transformative: return 1.0
        case .significant: return 0.8
        case .moderate: return 0.6
        case .minor: return 0.4
        }
    }
}

// MARK: - Advanced Conversation Intelligence Manager

@MainActor
class ConversationIntelligence: ObservableObject {
    // MARK: - Published Properties

    @Published var isAnalyzing = false
    @Published var conversationSummaries: [ConversationSummary] = []
    @Published var conversationRelationships: [ConversationRelationship] = []
    @Published var contextSuggestions: [ContextSuggestion] = []
    @Published var intelligenceInsights: [IntelligenceInsight] = []
    @Published var crossConversationContext: [UUID: [UUID]] = [:]
    @Published var userPersonalization: UserPersonalizationProfile = UserPersonalizationProfile()

    // MARK: - Dependencies

    private let conversationManager: ConversationManager
    private let memoryManager: ConversationMemoryManager
    private let logger = Logger(subsystem: "com.jarvis.intelligence", category: "ConversationIntelligence")

    // MARK: - Intelligence Configuration

    private let maxSummaryWords = 150
    private let maxKeyPoints = 8
    private let maxRelationships = 50
    private let maxSuggestions = 12
    private let maxInsights = 20
    private let contextAnalysisWindow = 25
    private let relationshipThreshold = 0.6
    private let suggestionRefreshInterval: TimeInterval = 300 // 5 minutes

    // MARK: - Natural Language Processing

    private let sentimentPredictor = NLModel(mlModel: try! NLModel.sentimentPredictionModel().mlModel)
    private let languageRecognizer = NLLanguageRecognizer()
    private let tokenizer = NLTokenizer(unit: .sentence)
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .sentimentScore, .language])
    private let summarizer = TextSummarizer()

    // MARK: - Intelligence Cache

    private var summaryCache: [UUID: ConversationSummary] = [:]
    private var relationshipCache: [UUID: [ConversationRelationship]] = [:]
    private var suggestionCache: [UUID: [ContextSuggestion]] = [:]
    private var lastAnalysisTime: [UUID: Date] = [:]
    private var intelligenceGraph: ConversationGraph

    // MARK: - Publishers

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(conversationManager: ConversationManager, memoryManager: ConversationMemoryManager) {
        self.conversationManager = conversationManager
        self.memoryManager = memoryManager
        self.intelligenceGraph = ConversationGraph()

        setupNaturalLanguageProcessing()
        setupIntelligenceMonitoring()
        loadIntelligenceData()
    }

    private func setupNaturalLanguageProcessing() {
        tokenizer.setLanguage(.english)
        tagger.setLanguage(.english, range: NSRange(location: 0, length: 0))
        languageRecognizer.processString("")
    }

    private func setupIntelligenceMonitoring() {
        // Monitor conversation updates
        conversationManager.$conversations
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] conversations in
                Task { @MainActor in
                    await self?.analyzeConversationChanges(conversations)
                }
            }
            .store(in: &cancellables)

        // Monitor memory updates
        memoryManager.$recentMemories
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] memories in
                Task { @MainActor in
                    await self?.analyzeMemoryChanges(memories)
                }
            }
            .store(in: &cancellables)

        // Periodic intelligence analysis
        Timer.scheduledTimer(withTimeInterval: suggestionRefreshInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.performPeriodicIntelligenceAnalysis()
            }
        }
    }

    // MARK: - Core Intelligence Operations

    func analyzeConversation(_ conversation: Conversation) async -> ConversationSummary {
        isAnalyzing = true
        logger.info("Starting conversation analysis for: \(conversation.title)")

        do {
            // Check cache first
            if let cached = summaryCache[conversation.id],
               let lastAnalysis = lastAnalysisTime[conversation.id],
               Date().timeIntervalSince(lastAnalysis) < suggestionRefreshInterval {
                logger.info("Returning cached summary for conversation: \(conversation.title)")
                isAnalyzing = false
                return cached
            }

            let messages = conversation.messagesArray
            guard !messages.isEmpty else {
                isAnalyzing = false
                return createEmptySummary(for: conversation)
            }

            // Analyze conversation content
            let fullText = messages.map { $0.content }.joined(separator: "\n")
            let keyPoints = await extractKeyPoints(from: messages)
            let mainTopics = await extractMainTopics(from: fullText)
            let sentiment = await analyzeSentiment(from: fullText, messages: messages)
            let participantInsights = await analyzeParticipantInsights(from: messages)
            let actionItems = await extractActionItems(from: messages)
            let followUpSuggestions = await generateFollowUpSuggestions(from: messages, topics: mainTopics)

            // Calculate confidence
            let confidence = calculateAnalysisConfidence(
                messageCount: messages.count,
                topicCount: mainTopics.count,
                keyPointCount: keyPoints.count
            )

            // Create summary
            let summary = ConversationSummary(
                id: UUID(),
                conversationId: conversation.id,
                title: conversation.title,
                keyPoints: keyPoints,
                mainTopics: mainTopics,
                sentiment: sentiment,
                participantInsights: participantInsights,
                actionItems: actionItems,
                followUpSuggestions: followUpSuggestions,
                confidence: confidence,
                createdAt: Date(),
                wordCount: fullText.components(separatedBy: .whitespacesAndNewlines).count,
                duration: calculateConversationDuration(messages)
            )

            // Cache results
            summaryCache[conversation.id] = summary
            lastAnalysisTime[conversation.id] = Date()

            // Update intelligence graph
            intelligenceGraph.addConversation(conversation, summary: summary)

            logger.info("Completed conversation analysis for: \(conversation.title)")
            isAnalyzing = false
            return summary
        } catch {
            logger.error("Failed to analyze conversation: \(error)")
            isAnalyzing = false
            return createEmptySummary(for: conversation)
        }
    }

    func findRelatedConversations(for conversation: Conversation) async -> [ConversationRelationship] {
        logger.info("Finding related conversations for: \(conversation.title)")

        // Check cache
        if let cached = relationshipCache[conversation.id],
           let lastAnalysis = lastAnalysisTime[conversation.id],
           Date().timeIntervalSince(lastAnalysis) < suggestionRefreshInterval {
            return cached
        }

        let currentSummary = await analyzeConversation(conversation)
        let allConversations = conversationManager.conversations.filter { $0.id != conversation.id }
        var relationships: [ConversationRelationship] = []

        for otherConversation in allConversations {
            let otherSummary = await analyzeConversation(otherConversation)

            // Calculate relationship strength
            let topicSimilarity = calculateTopicSimilarity(
                topics1: currentSummary.mainTopics,
                topics2: otherSummary.mainTopics
            )

            let entitySimilarity = await calculateEntitySimilarity(
                conversation1: conversation,
                conversation2: otherConversation
            )

            let temporalRelevance = calculateTemporalRelevance(
                time1: conversation.updatedAt,
                time2: otherConversation.updatedAt
            )

            let contextSimilarity = await calculateContextualSimilarity(
                conversation1: conversation,
                conversation2: otherConversation
            )

            let overallStrength = (topicSimilarity + entitySimilarity + temporalRelevance + contextSimilarity) / 4.0

            if overallStrength >= relationshipThreshold {
                let relationshipType = determineRelationshipType(
                    topicSimilarity: topicSimilarity,
                    temporalRelevance: temporalRelevance,
                    contextSimilarity: contextSimilarity
                )

                let relationship = ConversationRelationship(
                    id: UUID(),
                    primaryConversationId: conversation.id,
                    relatedConversationId: otherConversation.id,
                    relationshipType: relationshipType,
                    strength: overallStrength,
                    commonTopics: findCommonElements(currentSummary.mainTopics, otherSummary.mainTopics),
                    commonEntities: await findCommonEntities(conversation, otherConversation),
                    temporalDistance: abs(conversation.updatedAt.timeIntervalSince(otherConversation.updatedAt)),
                    contextualSimilarity: contextSimilarity,
                    createdAt: Date()
                )

                relationships.append(relationship)
            }
        }

        // Sort by strength and limit
        relationships = relationships.sorted { $0.strength > $1.strength }
        relationships = Array(relationships.prefix(maxRelationships))

        // Cache results
        relationshipCache[conversation.id] = relationships

        // Update cross-conversation context
        updateCrossConversationContext(for: conversation, relationships: relationships)

        logger.info("Found \(relationships.count) related conversations")
        return relationships
    }

    func generateContextualSuggestions(for conversation: Conversation) async -> [ContextSuggestion] {
        logger.info("Generating contextual suggestions for: \(conversation.title)")

        // Check cache
        if let cached = suggestionCache[conversation.id],
           let lastAnalysis = lastAnalysisTime[conversation.id],
           Date().timeIntervalSince(lastAnalysis) < suggestionRefreshInterval {
            return cached
        }

        var suggestions: [ContextSuggestion] = []

        // Analyze current conversation
        let summary = await analyzeConversation(conversation)
        let relationships = await findRelatedConversations(for: conversation)
        let recentMessages = Array(conversation.messagesArray.suffix(contextAnalysisWindow))

        // Generate different types of suggestions
        suggestions += await generateTopicBasedSuggestions(summary: summary, relationships: relationships)
        suggestions += await generateContinuationSuggestions(messages: recentMessages, summary: summary)
        suggestions += await generateClarificationSuggestions(messages: recentMessages)
        suggestions += await generateActionSuggestions(summary: summary)
        suggestions += await generateSynthesisSuggestions(relationships: relationships)
        suggestions += await generatePersonalizationSuggestions(conversation: conversation)

        // Score and rank suggestions
        suggestions = scoreSuggestions(suggestions, for: conversation)
        suggestions = suggestions.sorted { $0.relevanceScore > $1.relevanceScore }
        suggestions = Array(suggestions.prefix(maxSuggestions))

        // Cache results
        suggestionCache[conversation.id] = suggestions

        logger.info("Generated \(suggestions.count) contextual suggestions")
        return suggestions
    }

    func generateIntelligenceInsights() async -> [IntelligenceInsight] {
        logger.info("Generating intelligence insights")

        var insights: [IntelligenceInsight] = []

        // Analyze conversation patterns
        insights += await analyzeConversationPatterns()

        // Analyze user behavior evolution
        insights += await analyzeUserBehaviorEvolution()

        // Analyze topic evolution
        insights += await analyzeTopicEvolution()

        // Analyze preference shifts
        insights += await analyzePreferenceShifts()

        // Analyze knowledge gaps
        insights += await analyzeKnowledgeGaps()

        // Analyze goal alignment
        insights += await analyzeGoalAlignment()

        // Analyze contextual connections
        insights += await analyzeContextualConnections()

        // Score and rank insights
        insights = insights.sorted { $0.confidence * $0.impact.score > $1.confidence * $1.impact.score }
        insights = Array(insights.prefix(maxInsights))

        // Cache results
        intelligenceInsights = insights

        logger.info("Generated \(insights.count) intelligence insights")
        return insights
    }

    // MARK: - Personalization Profile Management

    func updatePersonalizationProfile() async {
        logger.info("Updating personalization profile")

        let conversations = conversationManager.conversations
        let preferences = memoryManager.userPreferences
        let patterns = memoryManager.behaviorPatterns
        let memories = memoryManager.recentMemories

        // Update communication style
        let communicationStyle = await analyzeCommunicationStyle(from: conversations)

        // Update topic interests
        let topicInterests = await analyzeTopicInterests(from: conversations, memories: memories)

        // Update interaction patterns
        let interactionPatterns = await analyzeInteractionPatterns(from: patterns)

        // Update AI provider preferences
        let aiProviderPrefs = await analyzeAIProviderPreferences(from: conversations)

        // Update response preferences
        let responsePrefs = await analyzeResponsePreferences(from: conversations)

        // Update learning style
        let learningStyle = await analyzeLearningStyle(from: conversations, memories: memories)

        // Create updated profile
        userPersonalization = UserPersonalizationProfile(
            communicationStyle: communicationStyle,
            topicInterests: topicInterests,
            interactionPatterns: interactionPatterns,
            aiProviderPreferences: aiProviderPrefs,
            responsePreferences: responsePrefs,
            learningStyle: learningStyle,
            lastUpdated: Date(),
            confidence: calculatePersonalizationConfidence(
                conversations: conversations,
                preferences: preferences,
                patterns: patterns
            )
        )

        logger.info("Updated personalization profile with confidence: \(userPersonalization.confidence)")
    }

    // MARK: - Cross-Conversation Context Management

    func getCrossConversationContext(for conversation: Conversation) async -> String {
        let relationships = await findRelatedConversations(for: conversation)
        let relatedSummaries = await getRelatedSummaries(relationships: relationships)

        var context = "CROSS-CONVERSATION CONTEXT:\n\n"

        if !relationships.isEmpty {
            context += "RELATED CONVERSATIONS:\n"
            for relationship in relationships.prefix(3) {
                if let summary = relatedSummaries[relationship.relatedConversationId] {
                    context += "- \(summary.title) (\(relationship.relationshipType.description))\n"
                    context += "  Key points: \(summary.keyPoints.prefix(2).joined(separator: ", "))\n"
                    context += "  Relationship strength: \(String(format: "%.1f", relationship.strength * 100))%\n\n"
                }
            }
        }

        // Add user personalization context
        context += "USER PERSONALIZATION:\n"
        context += userPersonalization.getContextString()

        return context
    }

    private func updateCrossConversationContext(for conversation: Conversation, relationships: [ConversationRelationship]) {
        let relatedIds = relationships.map { $0.relatedConversationId }
        crossConversationContext[conversation.id] = relatedIds

        // Update reverse relationships
        for relatedId in relatedIds {
            if crossConversationContext[relatedId] == nil {
                crossConversationContext[relatedId] = []
            }
            if !crossConversationContext[relatedId]!.contains(conversation.id) {
                crossConversationContext[relatedId]!.append(conversation.id)
            }
        }
    }

    // MARK: - Analysis Helper Methods

    private func extractKeyPoints(from messages: [ConversationMessage]) async -> [String] {
        let userMessages = messages.filter { $0.role == "user" }
        let importantMessages = userMessages.filter { $0.content.count > 50 }

        var keyPoints: [String] = []

        for message in importantMessages.prefix(maxKeyPoints) {
            let sentences = await extractSentences(from: message.content)
            let importantSentences = sentences.filter { sentence in
                sentence.count > 20 && (
                    sentence.lowercased().contains("important") ||
                    sentence.lowercased().contains("need") ||
                    sentence.lowercased().contains("want") ||
                    sentence.lowercased().contains("should") ||
                    sentence.lowercased().contains("must")
                )
            }

            if !importantSentences.isEmpty {
                keyPoints.append(importantSentences.first!)
            } else if !sentences.isEmpty {
                keyPoints.append(sentences.first!)
            }
        }

        return Array(keyPoints.prefix(maxKeyPoints))
    }

    private func extractMainTopics(from text: String) async -> [String] {
        tagger.string = text
        var topics: Set<String> = []

        // Extract named entities as topics
        tagger.enumerateTags(in: NSRange(location: 0, length: text.count),
                           unit: .word,
                           scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(text[Range(range, in: text)!])
                if entity.count > 2 {
                    topics.insert(entity)
                }
            }
            return true
        }

        // Extract topic keywords
        let topicKeywords = [
            "work", "project", "meeting", "deadline", "task", "job", "career",
            "family", "friend", "relationship", "personal", "home", "travel",
            "health", "fitness", "diet", "exercise", "medical", "wellness",
            "technology", "software", "programming", "AI", "computer", "app",
            "finance", "money", "budget", "investment", "business", "economy",
            "education", "learning", "course", "study", "school", "university",
            "entertainment", "movie", "music", "book", "game", "sport",
            "food", "cooking", "recipe", "restaurant", "cuisine",
        ]

        let lowercaseText = text.lowercased()
        for keyword in topicKeywords {
            if lowercaseText.contains(keyword) {
                topics.insert(keyword.capitalized)
            }
        }

        return Array(topics.prefix(8))
    }

    private func analyzeSentiment(from text: String, messages: [ConversationMessage]) async -> ConversationSentiment {
        // Overall sentiment
        guard let prediction = try? sentimentPredictor?.prediction(from: text),
              let sentimentLabel = prediction.featureValue(for: "sentiment")?.stringValue else {
            return ConversationSentiment(
                overall: "neutral",
                confidence: 0.5,
                emotionalTone: "neutral",
                intensityScore: 0.5,
                keyEmotions: []
            )
        }

        // Analyze emotional tone
        let emotionalTone = determineEmotionalTone(from: text)

        // Calculate intensity
        let intensityScore = calculateSentimentIntensity(from: text)

        // Extract key emotions
        let keyEmotions = extractKeyEmotions(from: messages)

        return ConversationSentiment(
            overall: sentimentLabel.lowercased(),
            confidence: 0.8, // Simplified confidence
            emotionalTone: emotionalTone,
            intensityScore: intensityScore,
            keyEmotions: keyEmotions
        )
    }

    private func analyzeParticipantInsights(from messages: [ConversationMessage]) async -> [String] {
        var insights: [String] = []

        let userMessages = messages.filter { $0.role == "user" }
        let assistantMessages = messages.filter { $0.role == "assistant" }

        // User insights
        if !userMessages.isEmpty {
            let avgUserMessageLength = userMessages.map { $0.content.count }.reduce(0, +) / userMessages.count
            let communicationStyle = avgUserMessageLength > 100 ? "detailed" : "concise"
            insights.append("User prefers \(communicationStyle) communication")
        }

        // Interaction patterns
        let totalMessages = messages.count
        if totalMessages > 10 {
            insights.append("Engaged in extended conversation (\(totalMessages) messages)")
        }

        // Question patterns
        let questionMessages = userMessages.filter { $0.content.contains("?") }
        if questionMessages.count > userMessages.count / 2 {
            insights.append("User is primarily asking questions")
        }

        return insights
    }

    private func extractActionItems(from messages: [ConversationMessage]) async -> [String] {
        var actionItems: [String] = []

        let actionKeywords = ["need to", "should", "must", "have to", "will", "plan to", "going to", "remind me", "schedule", "book", "call", "email", "send", "create", "make", "do"]

        for message in messages {
            let content = message.content.lowercased()
            for keyword in actionKeywords {
                if content.contains(keyword) {
                    let sentences = await extractSentences(from: message.content)
                    for sentence in sentences {
                        if sentence.lowercased().contains(keyword) {
                            actionItems.append(sentence)
                            break
                        }
                    }
                    break
                }
            }
        }

        return Array(Set(actionItems)).prefix(5).map { String($0) }
    }

    private func generateFollowUpSuggestions(from messages: [ConversationMessage], topics: [String]) async -> [String] {
        var suggestions: [String] = []

        // Topic-based suggestions
        for topic in topics.prefix(3) {
            suggestions.append("Tell me more about \(topic)")
            suggestions.append("How does \(topic) relate to your goals?")
        }

        // Content-based suggestions
        let lastUserMessage = messages.last { $0.role == "user" }
        if let lastMessage = lastUserMessage {
            if lastMessage.content.contains("?") {
                suggestions.append("Would you like me to elaborate on that answer?")
            } else {
                suggestions.append("Is there anything specific you'd like to know about this?")
            }
        }

        return Array(suggestions.prefix(4))
    }

    // MARK: - Similarity Calculations

    private func calculateTopicSimilarity(topics1: [String], topics2: [String]) -> Double {
        let set1 = Set(topics1.map { $0.lowercased() })
        let set2 = Set(topics2.map { $0.lowercased() })

        let intersection = set1.intersection(set2)
        let union = set1.union(set2)

        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    private func calculateEntitySimilarity(conversation1: Conversation, conversation2: Conversation) async -> Double {
        // Simplified entity similarity - in production, use proper NER
        let entities1 = await extractEntities(from: conversation1.messagesArray.map { $0.content }.joined(separator: " "))
        let entities2 = await extractEntities(from: conversation2.messagesArray.map { $0.content }.joined(separator: " "))

        let set1 = Set(entities1.map { $0.lowercased() })
        let set2 = Set(entities2.map { $0.lowercased() })

        let intersection = set1.intersection(set2)
        let union = set1.union(set2)

        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }

    private func calculateTemporalRelevance(time1: Date, time2: Date) -> Double {
        let timeDifference = abs(time1.timeIntervalSince(time2))
        let maxRelevantTime: TimeInterval = 7 * 24 * 3600 // 7 days

        return max(0.0, 1.0 - (timeDifference / maxRelevantTime))
    }

    private func calculateContextualSimilarity(conversation1: Conversation, conversation2: Conversation) async -> Double {
        // Simplified contextual similarity - in production, use embeddings
        let keywords1 = conversation1.memoryKeywordsArray
        let keywords2 = conversation2.memoryKeywordsArray

        return calculateTopicSimilarity(topics1: keywords1, topics2: keywords2)
    }

    // MARK: - Utility Methods

    private func createEmptySummary(for conversation: Conversation) -> ConversationSummary {
        ConversationSummary(
            id: UUID(),
            conversationId: conversation.id,
            title: conversation.title,
            keyPoints: [],
            mainTopics: [],
            sentiment: ConversationSentiment(
                overall: "neutral",
                confidence: 0.0,
                emotionalTone: "neutral",
                intensityScore: 0.0,
                keyEmotions: []
            ),
            participantInsights: [],
            actionItems: [],
            followUpSuggestions: [],
            confidence: 0.0,
            createdAt: Date(),
            wordCount: 0,
            duration: 0
        )
    }

    private func calculateAnalysisConfidence(messageCount: Int, topicCount: Int, keyPointCount: Int) -> Double {
        let messageScore = min(Double(messageCount) * 0.1, 1.0)
        let topicScore = min(Double(topicCount) * 0.15, 1.0)
        let keyPointScore = min(Double(keyPointCount) * 0.12, 1.0)

        return (messageScore + topicScore + keyPointScore) / 3.0
    }

    private func calculateConversationDuration(_ messages: [ConversationMessage]) -> TimeInterval {
        guard messages.count > 1 else { return 0 }
        return messages.last!.timestamp.timeIntervalSince(messages.first!.timestamp)
    }

    private func determineRelationshipType(topicSimilarity: Double, temporalRelevance: Double, contextSimilarity: Double) -> RelationshipType {
        if temporalRelevance > 0.8 && topicSimilarity > 0.7 {
            return .continuation
        } else if temporalRelevance > 0.6 && contextSimilarity > 0.6 {
            return .followUp
        } else if topicSimilarity > 0.8 {
            return .topicalSimilarity
        } else if temporalRelevance > 0.9 {
            return .temporalSequence
        } else if contextSimilarity > 0.7 {
            return .related
        } else {
            return .related
        }
    }

    private func findCommonElements<T: Hashable>(_ array1: [T], _ array2: [T]) -> [T] {
        let set1 = Set(array1)
        let set2 = Set(array2)
        return Array(set1.intersection(set2))
    }

    private func findCommonEntities(_ conversation1: Conversation, _ conversation2: Conversation) async -> [String] {
        let entities1 = await extractEntities(from: conversation1.messagesArray.map { $0.content }.joined(separator: " "))
        let entities2 = await extractEntities(from: conversation2.messagesArray.map { $0.content }.joined(separator: " "))

        return findCommonElements(entities1, entities2)
    }

    private func extractEntities(from text: String) async -> [String] {
        tagger.string = text
        var entities: [String] = []

        tagger.enumerateTags(in: NSRange(location: 0, length: text.count),
                           unit: .word,
                           scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(text[Range(range, in: text)!])
                if entity.count > 2 {
                    entities.append(entity)
                }
            }
            return true
        }

        return entities
    }

    private func extractSentences(from text: String) async -> [String] {
        tokenizer.string = text
        let sentences = tokenizer.tokens(for: NSRange(location: 0, length: text.count))

        return sentences.compactMap { range in
            String(text[Range(range, in: text)!]).trimmingCharacters(in: .whitespacesAndNewlines)
        }.filter { !$0.isEmpty }
    }

    // MARK: - Suggestion Generation

    private func generateTopicBasedSuggestions(summary: ConversationSummary, relationships: [ConversationRelationship]) async -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []

        for topic in summary.mainTopics.prefix(3) {
            suggestions.append(ContextSuggestion(
                id: UUID(),
                text: "Tell me more about \(topic)",
                type: .question,
                relevanceScore: 0.8,
                sourceContext: "Topic analysis",
                reasoning: "User showed interest in \(topic)",
                actionable: true,
                priority: .medium,
                relatedConversationIds: [summary.conversationId],
                createdAt: Date()
            ))
        }

        return suggestions
    }

    private func generateContinuationSuggestions(messages: [ConversationMessage], summary: ConversationSummary) async -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []

        if let lastMessage = messages.last, lastMessage.role == "assistant" {
            suggestions.append(ContextSuggestion(
                id: UUID(),
                text: "Would you like me to elaborate on that?",
                type: .continuation,
                relevanceScore: 0.7,
                sourceContext: "Conversation flow",
                reasoning: "Natural continuation opportunity",
                actionable: true,
                priority: .medium,
                relatedConversationIds: [summary.conversationId],
                createdAt: Date()
            ))
        }

        return suggestions
    }

    private func generateClarificationSuggestions(messages: [ConversationMessage]) async -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []

        let recentUserMessages = messages.suffix(5).filter { $0.role == "user" }
        for message in recentUserMessages {
            if message.content.count < 30 || message.content.components(separatedBy: .whitespacesAndNewlines).count < 8 {
                suggestions.append(ContextSuggestion(
                    id: UUID(),
                    text: "Could you provide more details about that?",
                    type: .clarification,
                    relevanceScore: 0.6,
                    sourceContext: "Message analysis",
                    reasoning: "User message was brief and could benefit from elaboration",
                    actionable: true,
                    priority: .low,
                    relatedConversationIds: [],
                    createdAt: Date()
                ))
                break
            }
        }

        return suggestions
    }

    private func generateActionSuggestions(summary: ConversationSummary) async -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []

        for actionItem in summary.actionItems.prefix(2) {
            suggestions.append(ContextSuggestion(
                id: UUID(),
                text: "Would you like help with: \(actionItem)",
                type: .action,
                relevanceScore: 0.9,
                sourceContext: "Action item extraction",
                reasoning: "Identified actionable item in conversation",
                actionable: true,
                priority: .high,
                relatedConversationIds: [summary.conversationId],
                createdAt: Date()
            ))
        }

        return suggestions
    }

    private func generateSynthesisSuggestions(relationships: [ConversationRelationship]) async -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []

        if relationships.count >= 2 {
            let strongRelationships = relationships.filter { $0.strength > 0.8 }
            if !strongRelationships.isEmpty {
                suggestions.append(ContextSuggestion(
                    id: UUID(),
                    text: "I notice connections between your recent conversations. Would you like me to synthesize the key insights?",
                    type: .synthesis,
                    relevanceScore: 0.85,
                    sourceContext: "Cross-conversation analysis",
                    reasoning: "Multiple strong relationships detected",
                    actionable: true,
                    priority: .high,
                    relatedConversationIds: strongRelationships.map { $0.relatedConversationId },
                    createdAt: Date()
                ))
            }
        }

        return suggestions
    }

    private func generatePersonalizationSuggestions(conversation: Conversation) async -> [ContextSuggestion] {
        var suggestions: [ContextSuggestion] = []

        // Based on user personalization profile
        if userPersonalization.confidence > 0.7 {
            let interests = userPersonalization.topicInterests.prefix(2)
            for interest in interests {
                suggestions.append(ContextSuggestion(
                    id: UUID(),
                    text: "Given your interest in \(interest.topic), you might find this relevant: \(interest.topic)",
                    type: .information,
                    relevanceScore: interest.strength,
                    sourceContext: "User personalization",
                    reasoning: "Matches user's established interests",
                    actionable: true,
                    priority: .medium,
                    relatedConversationIds: [conversation.id],
                    createdAt: Date()
                ))
            }
        }

        return suggestions
    }

    private func scoreSuggestions(_ suggestions: [ContextSuggestion], for conversation: Conversation) -> [ContextSuggestion] {
        return suggestions.map { suggestion in
            var scoredSuggestion = suggestion

            // Adjust score based on priority
            scoredSuggestion.relevanceScore *= suggestion.priority.weight

            // Adjust score based on recency
            let ageInSeconds = Date().timeIntervalSince(suggestion.createdAt)
            let recencyMultiplier = max(0.5, 1.0 - (ageInSeconds / 3600)) // Decay over 1 hour
            scoredSuggestion.relevanceScore *= recencyMultiplier

            return scoredSuggestion
        }
    }

    // MARK: - Intelligence Analysis Methods

    private func analyzeConversationChanges(_ conversations: [Conversation]) async {
        // Analyze new or updated conversations
        for conversation in conversations {
            if let lastAnalysis = lastAnalysisTime[conversation.id] {
                if conversation.updatedAt > lastAnalysis {
                    _ = await analyzeConversation(conversation)
                    _ = await findRelatedConversations(for: conversation)
                }
            } else {
                _ = await analyzeConversation(conversation)
                _ = await findRelatedConversations(for: conversation)
            }
        }
    }

    private func analyzeMemoryChanges(_ memories: [ConversationMemory]) async {
        // Update intelligence when new memories are created
        if !memories.isEmpty {
            await updatePersonalizationProfile()
        }
    }

    private func performPeriodicIntelligenceAnalysis() async {
        logger.info("Performing periodic intelligence analysis")

        // Update personalization profile
        await updatePersonalizationProfile()

        // Generate fresh insights
        _ = await generateIntelligenceInsights()

        // Clean up old cache entries
        cleanupCache()

        logger.info("Completed periodic intelligence analysis")
    }

    private func cleanupCache() {
        let cutoffTime = Date().addingTimeInterval(-suggestionRefreshInterval * 2)

        lastAnalysisTime = lastAnalysisTime.filter { $0.value > cutoffTime }
        summaryCache = summaryCache.filter { lastAnalysisTime[$0.key] != nil }
        relationshipCache = relationshipCache.filter { lastAnalysisTime[$0.key] != nil }
        suggestionCache = suggestionCache.filter { lastAnalysisTime[$0.key] != nil }
    }

    private func loadIntelligenceData() {
        // Load cached data from persistent storage if available
        // This would typically load from Core Data or other persistence layer
        logger.info("Loading intelligence data")
    }

    // MARK: - Placeholder Methods for Insight Generation

    private func analyzeConversationPatterns() async -> [IntelligenceInsight] {
        // Placeholder for conversation pattern analysis
        return []
    }

    private func analyzeUserBehaviorEvolution() async -> [IntelligenceInsight] {
        // Placeholder for user behavior evolution analysis
        return []
    }

    private func analyzeTopicEvolution() async -> [IntelligenceInsight] {
        // Placeholder for topic evolution analysis
        return []
    }

    private func analyzePreferenceShifts() async -> [IntelligenceInsight] {
        // Placeholder for preference shift analysis
        return []
    }

    private func analyzeKnowledgeGaps() async -> [IntelligenceInsight] {
        // Placeholder for knowledge gap analysis
        return []
    }

    private func analyzeGoalAlignment() async -> [IntelligenceInsight] {
        // Placeholder for goal alignment analysis
        return []
    }

    private func analyzeContextualConnections() async -> [IntelligenceInsight] {
        // Placeholder for contextual connection analysis
        return []
    }

    // MARK: - Personalization Analysis Methods

    private func analyzeCommunicationStyle(from conversations: [Conversation]) async -> CommunicationStyle {
        // Placeholder for communication style analysis
        return CommunicationStyle()
    }

    private func analyzeTopicInterests(from conversations: [Conversation], memories: [ConversationMemory]) async -> [TopicInterest] {
        // Placeholder for topic interest analysis
        return []
    }

    private func analyzeInteractionPatterns(from patterns: [UserBehaviorPattern]) async -> [InteractionPattern] {
        // Placeholder for interaction pattern analysis
        return []
    }

    private func analyzeAIProviderPreferences(from conversations: [Conversation]) async -> AIProviderPreferences {
        // Placeholder for AI provider preference analysis
        return AIProviderPreferences()
    }

    private func analyzeResponsePreferences(from conversations: [Conversation]) async -> ResponsePreferences {
        // Placeholder for response preference analysis
        return ResponsePreferences()
    }

    private func analyzeLearningStyle(from conversations: [Conversation], memories: [ConversationMemory]) async -> LearningStyle {
        // Placeholder for learning style analysis
        return LearningStyle()
    }

    private func calculatePersonalizationConfidence(conversations: [Conversation], preferences: [UserPreference], patterns: [UserBehaviorPattern]) -> Double {
        let conversationScore = min(Double(conversations.count) * 0.1, 1.0)
        let preferenceScore = min(Double(preferences.count) * 0.2, 1.0)
        let patternScore = min(Double(patterns.count) * 0.15, 1.0)

        return (conversationScore + preferenceScore + patternScore) / 3.0
    }

    private func getRelatedSummaries(relationships: [ConversationRelationship]) async -> [UUID: ConversationSummary] {
        var summaries: [UUID: ConversationSummary] = [:]

        for relationship in relationships {
            if let summary = summaryCache[relationship.relatedConversationId] {
                summaries[relationship.relatedConversationId] = summary
            } else if let conversation = conversationManager.conversations.first(where: { $0.id == relationship.relatedConversationId }) {
                let summary = await analyzeConversation(conversation)
                summaries[relationship.relatedConversationId] = summary
            }
        }

        return summaries
    }

    // MARK: - Utility Analysis Methods

    private func determineEmotionalTone(from text: String) -> String {
        let professionalKeywords = ["meeting", "project", "deadline", "business", "work", "professional"]
        let casualKeywords = ["hey", "hi", "yeah", "cool", "awesome", "great"]
        let urgentKeywords = ["urgent", "asap", "immediately", "quickly", "hurry", "rush"]
        let supportiveKeywords = ["help", "support", "understand", "appreciate", "thank"]

        let lowercaseText = text.lowercased()

        if professionalKeywords.contains(where: { lowercaseText.contains($0) }) {
            return "professional"
        } else if urgentKeywords.contains(where: { lowercaseText.contains($0) }) {
            return "urgent"
        } else if supportiveKeywords.contains(where: { lowercaseText.contains($0) }) {
            return "supportive"
        } else if casualKeywords.contains(where: { lowercaseText.contains($0) }) {
            return "casual"
        } else {
            return "neutral"
        }
    }

    private func calculateSentimentIntensity(from text: String) -> Double {
        let intensityKeywords = ["very", "extremely", "incredibly", "absolutely", "completely", "totally", "really", "quite"]
        let lowercaseText = text.lowercased()

        let intensityCount = intensityKeywords.reduce(0) { count, keyword in
            count + lowercaseText.components(separatedBy: keyword).count - 1
        }

        return min(1.0, Double(intensityCount) * 0.2 + 0.5)
    }

    private func extractKeyEmotions(from messages: [ConversationMessage]) -> [String] {
        let emotionKeywords = [
            "happy": ["happy", "joy", "excited", "pleased", "glad", "delighted"],
            "sad": ["sad", "disappointed", "upset", "frustrated", "depressed"],
            "angry": ["angry", "mad", "furious", "annoyed", "irritated"],
            "anxious": ["worried", "nervous", "anxious", "concerned", "stressed"],
            "confident": ["confident", "sure", "certain", "positive", "optimistic"],
            "confused": ["confused", "unclear", "uncertain", "puzzled", "lost"],
        ]

        var detectedEmotions: [String] = []
        let allText = messages.map { $0.content }.joined(separator: " ").lowercased()

        for (emotion, keywords) in emotionKeywords {
            if keywords.contains(where: { allText.contains($0) }) {
                detectedEmotions.append(emotion)
            }
        }

        return detectedEmotions
    }
}

// MARK: - Supporting Classes and Structures

class TextSummarizer {
    func summarize(text: String, maxWords: Int) -> String {
        // Simplified text summarization
        let sentences = text.components(separatedBy: ". ")
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).count

        if wordCount <= maxWords {
            return text
        }

        // Take first few sentences that fit within word limit
        var summary = ""
        var currentWordCount = 0

        for sentence in sentences {
            let sentenceWordCount = sentence.components(separatedBy: .whitespacesAndNewlines).count
            if currentWordCount + sentenceWordCount <= maxWords {
                summary += sentence + ". "
                currentWordCount += sentenceWordCount
            } else {
                break
            }
        }

        return summary.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

class ConversationGraph {
    private var nodes: [UUID: ConversationNode] = [:]
    private var edges: [ConversationEdge] = []

    func addConversation(_ conversation: Conversation, summary: ConversationSummary) {
        let node = ConversationNode(
            id: conversation.id,
            title: conversation.title,
            topics: summary.mainTopics,
            createdAt: conversation.createdAt,
            messageCount: Int(conversation.totalMessages)
        )
        nodes[conversation.id] = node
    }

    func addRelationship(_ relationship: ConversationRelationship) {
        let edge = ConversationEdge(
            from: relationship.primaryConversationId,
            to: relationship.relatedConversationId,
            type: relationship.relationshipType,
            strength: relationship.strength
        )
        edges.append(edge)
    }

    func getConnectedConversations(for conversationId: UUID) -> [UUID] {
        return edges.filter { $0.from == conversationId || $0.to == conversationId }
                   .map { $0.from == conversationId ? $0.to : $0.from }
    }
}

struct ConversationNode {
    let id: UUID
    let title: String
    let topics: [String]
    let createdAt: Date
    let messageCount: Int
}

struct ConversationEdge {
    let from: UUID
    let to: UUID
    let type: RelationshipType
    let strength: Double
}

// MARK: - Personalization Profile Structures

struct UserPersonalizationProfile {
    var communicationStyle: CommunicationStyle = CommunicationStyle()
    var topicInterests: [TopicInterest] = []
    var interactionPatterns: [InteractionPattern] = []
    var aiProviderPreferences: AIProviderPreferences = AIProviderPreferences()
    var responsePreferences: ResponsePreferences = ResponsePreferences()
    var learningStyle: LearningStyle = LearningStyle()
    var lastUpdated: Date = Date()
    var confidence: Double = 0.0

    func getContextString() -> String {
        var context = ""

        if confidence > 0.5 {
            context += "Communication Style: \(communicationStyle.primaryStyle)\n"

            if !topicInterests.isEmpty {
                let topInterests = topicInterests.prefix(3).map { $0.topic }.joined(separator: ", ")
                context += "Primary Interests: \(topInterests)\n"
            }

            context += "Preferred Response Length: \(responsePreferences.preferredLength)\n"
            context += "Learning Style: \(learningStyle.primaryStyle)\n"
        } else {
            context += "User personalization profile is still being established.\n"
        }

        return context
    }
}

struct CommunicationStyle {
    var primaryStyle: String = "neutral"
    var formality: String = "mixed"
    var directness: String = "moderate"
    var emotionExpression: String = "moderate"
    var confidence: Double = 0.0
}

struct TopicInterest {
    let topic: String
    let strength: Double
    let frequency: Int
    let lastMentioned: Date
}

struct InteractionPattern {
    let pattern: String
    let frequency: Int
    let confidence: Double
}

struct AIProviderPreferences {
    var preferredProvider: String = "auto"
    var providerScores: [String: Double] = [:]
    var confidence: Double = 0.0
}

struct ResponsePreferences {
    var preferredLength: String = "medium"
    var preferredStyle: String = "informative"
    var preferredFormat: String = "conversational"
    var confidence: Double = 0.0
}

struct LearningStyle {
    var primaryStyle: String = "adaptive"
    var preferredExplanationDepth: String = "medium"
    var examplePreference: String = "some"
    var confidence: Double = 0.0
}
