// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Enhanced conversation memory management with persistent context, user pattern learning, and intelligent enrichment
 * Issues & Complexity Summary: Complex memory system with Core Data, context analysis, pattern recognition, and AI integration
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~1200
 *   - Core Algorithm Complexity: Very High (Memory persistence, context analysis, pattern learning, AI integration)
 *   - Dependencies: 6 New (CoreData, Foundation, Combine, SwiftUI, NaturalLanguage, GameplayKit)
 *   - State Management Complexity: Very High (Memory states, context tracking, user patterns, topic analysis)
 *   - Novelty/Uncertainty Factor: High (Advanced memory management, AI-driven insights)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 92%
 * Problem Estimate (Inherent Problem Difficulty %): 90%
 * Initial Code Complexity Estimate %: 95%
 * Justification for Estimates: Advanced memory management with AI-driven pattern recognition and context enrichment
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

// MARK: - Enhanced Data Models

@objc(ConversationMemory)
public class ConversationMemory: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var summary: String
    @NSManaged public var memoryType: String // "fact", "preference", "context", "pattern", "emotion"
    @NSManaged public var keywords: String?
    @NSManaged public var context: String?
    @NSManaged public var embedding: String? // JSON array of vector embeddings
    @NSManaged public var confidence: Double
    @NSManaged public var relevanceScore: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var conversation: Conversation?
    @NSManaged public var userPreference: UserPreference?

    public var keywordsArray: [String] {
        return keywords?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
    }

    public var embeddingVector: [Double] {
        guard let embedding = embedding,
              let data = embedding.data(using: .utf8),
              let vector = try? JSONDecoder().decode([Double].self, from: data) else {
            return []
        }
        return vector
    }

    public func setEmbeddingVector(_ vector: [Double]) {
        guard let data = try? JSONEncoder().encode(vector),
              let embeddingString = String(data: data, encoding: .utf8) else {
            return
        }
        self.embedding = embeddingString
    }
}

@objc(ConversationTopic)
public class ConversationTopic: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var keywords: String?
    @NSManaged public var frequency: Int32
    @NSManaged public var confidence: Double
    @NSManaged public var relevanceScore: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var lastMentioned: Date
    @NSManaged public var conversations: NSSet?

    public var keywordsArray: [String] {
        return keywords?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
    }

    public var conversationsArray: [Conversation] {
        let set = conversations as? Set<Conversation> ?? []
        return Array(set).sorted { $0.updatedAt > $1.updatedAt }
    }
}

@objc(UserPreference)
public class UserPreference: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var preferenceKey: String
    @NSManaged public var preferenceValue: String
    @NSManaged public var preferenceType: String // "ai_provider", "voice_style", "response_length", "topic_interest"
    @NSManaged public var strength: Double
    @NSManaged public var frequency: Int32
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastUsed: Date
    @NSManaged public var relatedMemories: NSSet?

    public var relatedMemoriesArray: [ConversationMemory] {
        let set = relatedMemories as? Set<ConversationMemory> ?? []
        return Array(set).sorted { $0.updatedAt > $1.updatedAt }
    }
}

@objc(UserBehaviorPattern)
public class UserBehaviorPattern: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var pattern: String
    @NSManaged public var patternType: String // "time_preference", "topic_flow", "interaction_style", "session_length"
    @NSManaged public var strength: Double
    @NSManaged public var frequency: Int32
    @NSManaged public var timeOfDay: String?
    @NSManaged public var averageSessionLength: Double
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var lastObserved: Date
}

// MARK: - Memory Types

enum MemoryType: String, CaseIterable {
    case fact = "fact"
    case preference = "preference"
    case context = "context"
    case pattern = "pattern"
    case emotion = "emotion"
    case goal = "goal"
    case skill = "skill"

    var description: String {
        switch self {
        case .fact: return "Factual information about the user"
        case .preference: return "User preferences and choices"
        case .context: return "Conversational context and flow"
        case .pattern: return "Behavioral patterns and habits"
        case .emotion: return "Emotional context and sentiment"
        case .goal: return "User goals and objectives"
        case .skill: return "User skills and capabilities"
        }
    }
}

enum PreferenceType: String, CaseIterable {
    case aiProvider = "ai_provider"
    case voiceStyle = "voice_style"
    case responseLength = "response_length"
    case topicInterest = "topic_interest"
    case communicationStyle = "communication_style"
    case privacyLevel = "privacy_level"

    var description: String {
        switch self {
        case .aiProvider: return "Preferred AI provider"
        case .voiceStyle: return "Voice synthesis style"
        case .responseLength: return "Preferred response length"
        case .topicInterest: return "Topic interests and expertise"
        case .communicationStyle: return "Communication style preference"
        case .privacyLevel: return "Privacy and data sharing level"
        }
    }
}

enum PatternType: String, CaseIterable {
    case timePreference = "time_preference"
    case topicFlow = "topic_flow"
    case interactionStyle = "interaction_style"
    case sessionLength = "session_length"
    case questionTypes = "question_types"
    case taskPatterns = "task_patterns"

    var description: String {
        switch self {
        case .timePreference: return "Time-based usage patterns"
        case .topicFlow: return "Topic transition patterns"
        case .interactionStyle: return "Interaction and engagement style"
        case .sessionLength: return "Session duration patterns"
        case .questionTypes: return "Question and request types"
        case .taskPatterns: return "Task completion patterns"
        }
    }
}

// MARK: - Context Analysis

struct ConversationContextAnalysis {
    let topics: [String]
    let sentiment: String
    let entities: [String]
    let intent: String
    let confidence: Double
    let keywords: [String]
    let contextWeight: Double
}

struct UserInsight {
    let type: String
    let description: String
    let confidence: Double
    let actionable: Bool
    let suggestedAction: String?
}

struct ConversationSuggestion {
    let text: String
    let type: String // "question", "topic", "action", "information"
    let relevanceScore: Double
    let context: String
}

// MARK: - Enhanced Conversation Memory Manager

@MainActor
class ConversationMemoryManager: ObservableObject {
    // MARK: - Published Properties

    @Published var isProcessing = false
    @Published var recentMemories: [ConversationMemory] = []
    @Published var activeTopics: [ConversationTopic] = []
    @Published var userPreferences: [UserPreference] = []
    @Published var behaviorPatterns: [UserBehaviorPattern] = []
    @Published var contextSuggestions: [ConversationSuggestion] = []
    @Published var userInsights: [UserInsight] = []

    // MARK: - Core Data Stack

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ConversationDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Memory Manager Core Data error: \(error)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Natural Language Processing

    private let sentimentPredictor: NLModel? = nil // NLModel.sentimentPredictionModel() not available
    private let languageRecognizer = NLLanguageRecognizer()
    private let tokenizer = NLTokenizer(unit: .word)
    private let tagger = NLTagger(tagSchemes: [.nameType, .lexicalClass, .sentimentScore])

    // MARK: - Memory Configuration

    private let maxMemoriesPerConversation = 50
    private let maxActiveTopics = 10
    private let memoryRetentionDays = 90
    private let contextAnalysisWindow = 20
    private let minConfidenceThreshold = 0.7

    // MARK: - Context Cache

    private var contextCache: [UUID: ConversationContextAnalysis] = [:]
    private var suggestionCache: [UUID: [ConversationSuggestion]] = [:]
    private var lastAnalysisTime: [UUID: Date] = [:]

    // MARK: - Publishers

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init() {
        setupNaturalLanguageProcessing()
        loadRecentData()
        setupPeriodicCleanup()
    }

    private func setupNaturalLanguageProcessing() {
        tokenizer.setLanguage(.english)
        tagger.setLanguage(.english, range: NSRange(location: 0, length: 0))
    }

    private func setupPeriodicCleanup() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            Task { @MainActor in
                await self.performPeriodicMaintenance()
            }
        }
    }

    // MARK: - Core Memory Operations

    func processMessage(_ message: ConversationMessage, in conversation: Conversation) async {
        isProcessing = true

        do {
            // Analyze message content
            let analysis = await analyzeMessageContext(message.content)

            // Extract and store memories
            await extractMemories(from: message, conversation: conversation, analysis: analysis)

            // Update topics
            await updateTopics(from: analysis, conversation: conversation)

            // Learn user patterns
            await updateUserPatterns(from: message, analysis: analysis)

            // Update preferences
            await updateUserPreferences(from: message, analysis: analysis)

            // Generate context suggestions
            await generateContextSuggestions(for: conversation)

            // Update conversation context weight
            updateConversationContextWeight(conversation, analysis: analysis)

            saveContext()
            await loadRecentData()

            print("✅ Processed memory for message in conversation: \(conversation.title)")
        } catch {
            print("❌ Failed to process message memory: \(error)")
        }

        isProcessing = false
    }

    func getEnrichedContext(for conversation: Conversation) async -> String {
        let recentMessages = conversation.messagesArray.suffix(contextAnalysisWindow)
        let relevantMemories = await getRelevantMemories(for: conversation, limit: 10)
        let activeTopics = await getActiveTopics(for: conversation, limit: 5)
        let userContext = await getUserContextSummary()

        var enrichedContext = "ENHANCED CONVERSATION CONTEXT:\n\n"

        // Add user context summary
        enrichedContext += "USER PROFILE:\n\(userContext)\n\n"

        // Add relevant memories
        if !relevantMemories.isEmpty {
            enrichedContext += "RELEVANT MEMORIES:\n"
            for memory in relevantMemories {
                enrichedContext += "- \(memory.summary) (confidence: \(String(format: "%.1f", memory.confidence * 100))%)\n"
            }
            enrichedContext += "\n"
        }

        // Add active topics
        if !activeTopics.isEmpty {
            enrichedContext += "ACTIVE TOPICS:\n"
            for topic in activeTopics {
                enrichedContext += "- \(topic.name) (relevance: \(String(format: "%.1f", topic.relevanceScore * 100))%)\n"
            }
            enrichedContext += "\n"
        }

        // Add recent conversation flow
        enrichedContext += "RECENT CONVERSATION:\n"
        for message in recentMessages {
            let role = message.role.capitalized
            let content = message.content.count > 100 ? String(message.content.prefix(100)) + "..." : message.content
            enrichedContext += "\(role): \(content)\n"
        }

        return enrichedContext
    }

    func getContextualSuggestions(for conversation: Conversation) async -> [ConversationSuggestion] {
        if let cached = suggestionCache[conversation.id],
           let lastAnalysis = lastAnalysisTime[conversation.id],
           Date().timeIntervalSince(lastAnalysis) < 300 { // 5 minutes cache
            return cached
        }

        let suggestions = await generateContextSuggestions(for: conversation)
        suggestionCache[conversation.id] = suggestions
        lastAnalysisTime[conversation.id] = Date()

        return suggestions
    }

    // MARK: - Context Analysis

    private func analyzeMessageContext(_ content: String) async -> ContextAnalysis {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Tokenize content
                self.tokenizer.string = content
                let tokens = self.tokenizer.tokens(for: NSRange(location: 0, length: content.count))
                let words = tokens.compactMap { token in
                    String(content[Range(token, in: content)!])
                }

                // Extract topics using NLP
                let topics = self.extractTopics(from: content)

                // Analyze sentiment
                let sentiment = self.analyzeSentiment(content)

                // Extract entities
                let entities = self.extractEntities(from: content)

                // Determine intent
                let intent = self.determineIntent(from: content, tokens: words)

                // Calculate confidence
                let confidence = self.calculateAnalysisConfidence(topics: topics, entities: entities)

                // Extract keywords
                let keywords = self.extractKeywords(from: words)

                // Calculate context weight
                let contextWeight = self.calculateContextWeight(
                    topics: topics,
                    entities: entities,
                    sentiment: sentiment,
                    messageLength: content.count
                )

                let analysis = ContextAnalysis(
                    topics: topics,
                    sentiment: sentiment,
                    entities: entities,
                    intent: intent,
                    confidence: confidence,
                    keywords: keywords,
                    contextWeight: contextWeight
                )

                continuation.resume(returning: analysis)
            }
        }
    }

    private func extractTopics(from content: String) -> [String] {
        tagger.string = content
        var topics: [String] = []

        // Use named entity recognition to find topics
        tagger.enumerateTags(in: NSRange(location: 0, length: content.count),
                           unit: .word,
                           scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(content[Range(range, in: content)!])
                if tag == .personalName || tag == .organizationName || tag == .placeName {
                    topics.append(entity)
                }
            }
            return true
        }

        // Add topic extraction based on keywords
        let topicKeywords = [
            "work", "project", "meeting", "deadline", "task",
            "family", "friend", "relationship", "personal",
            "health", "fitness", "diet", "exercise",
            "travel", "vacation", "trip", "destination",
            "technology", "software", "programming", "AI",
            "finance", "money", "budget", "investment",
            "education", "learning", "course", "study",
        ]

        let lowercaseContent = content.lowercased()
        for keyword in topicKeywords {
            if lowercaseContent.contains(keyword) {
                topics.append(keyword.capitalized)
            }
        }

        return Array(Set(topics)) // Remove duplicates
    }

    private func analyzeSentiment(_ content: String) -> String {
        guard let prediction = try? sentimentPredictor?.prediction(from: content) else {
            return "neutral"
        }

        if let sentimentLabel = prediction.featureValue(for: "sentiment")?.stringValue {
            return sentimentLabel.lowercased()
        }

        return "neutral"
    }

    private func extractEntities(from content: String) -> [String] {
        tagger.string = content
        var entities: [String] = []

        tagger.enumerateTags(in: NSRange(location: 0, length: content.count),
                           unit: .word,
                           scheme: .nameType) { tag, range in
            if let tag = tag {
                let entity = String(content[Range(range, in: content)!])
                entities.append(entity)
            }
            return true
        }

        return entities
    }

    private func determineIntent(from content: String, tokens: [String]) -> String {
        let lowercaseContent = content.lowercased()

        // Question detection
        if lowercaseContent.contains("?") ||
           tokens.contains(where: { ["what", "how", "why", "when", "where", "who"].contains($0.lowercased()) }) {
            return "question"
        }

        // Command detection
        if tokens.first?.lowercased() == "please" ||
           tokens.contains(where: { ["create", "make", "do", "send", "call", "schedule"].contains($0.lowercased()) }) {
            return "command"
        }

        // Information sharing
        if lowercaseContent.contains("i think") || lowercaseContent.contains("in my opinion") ||
           lowercaseContent.contains("i believe") {
            return "opinion"
        }

        // Casual conversation
        return "conversation"
    }

    private func calculateAnalysisConfidence(topics: [String], entities: [String]) -> Double {
        let topicScore = min(Double(topics.count) * 0.2, 1.0)
        let entityScore = min(Double(entities.count) * 0.1, 0.5)
        return max(topicScore + entityScore, 0.3) // Minimum 30% confidence
    }

    private func extractKeywords(from words: [String]) -> [String] {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their"])

        return words
            .filter { $0.count > 2 }
            .filter { !stopWords.contains($0.lowercased()) }
            .filter { $0.rangeOfCharacter(from: .letters) != nil }
            .map { $0.lowercased() }
            .reduce(into: [String: Int]()) { counts, word in
                counts[word, default: 0] += 1
            }
            .sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }

    private func calculateContextWeight(topics: [String], entities: [String], sentiment: String, messageLength: Int) -> Double {
        var weight = 0.5 // Base weight

        // Topic contribution
        weight += min(Double(topics.count) * 0.1, 0.3)

        // Entity contribution
        weight += min(Double(entities.count) * 0.05, 0.2)

        // Sentiment contribution
        if sentiment != "neutral" {
            weight += 0.1
        }

        // Message length contribution
        if messageLength > 100 {
            weight += 0.1
        }

        return min(weight, 1.0)
    }

    // MARK: - Memory Extraction

    private func extractMemories(from message: ConversationMessage, conversation: Conversation, analysis: ContextAnalysis) async {
        // Extract factual memories
        if analysis.confidence > minConfidenceThreshold {
            for entity in analysis.entities {
                await createMemory(
                    summary: "User mentioned: \(entity)",
                    type: .fact,
                    keywords: [entity] + analysis.keywords.prefix(3),
                    context: message.content,
                    confidence: analysis.confidence,
                    conversation: conversation
                )
            }
        }

        // Extract preference memories
        if message.role == "user" && analysis.intent == "opinion" {
            await createMemory(
                summary: "User preference expressed: \(String(message.content.prefix(100)))",
                type: .preference,
                keywords: analysis.keywords.prefix(5),
                context: message.content,
                confidence: analysis.confidence * 0.8,
                conversation: conversation
            )
        }

        // Extract emotional context
        if analysis.sentiment != "neutral" {
            await createMemory(
                summary: "User showed \(analysis.sentiment) sentiment about: \(analysis.topics.joined(separator: ", "))",
                type: .emotion,
                keywords: [analysis.sentiment] + analysis.topics.prefix(3),
                context: message.content,
                confidence: analysis.confidence * 0.9,
                conversation: conversation
            )
        }

        // Extract contextual memories for important conversations
        if analysis.contextWeight > 0.7 {
            await createMemory(
                summary: "Important context: \(String(message.content.prefix(150)))",
                type: .context,
                keywords: analysis.keywords.prefix(8),
                context: buildContextString(for: conversation),
                confidence: analysis.confidence,
                conversation: conversation
            )
        }
    }

    private func createMemory(
        summary: String,
        type: MemoryType,
        keywords: [String],
        context: String,
        confidence: Double,
        conversation: Conversation
    ) async {
        let memory = ConversationMemory(context: self.context)
        memory.id = UUID()
        memory.summary = summary
        memory.memoryType = type.rawValue
        memory.keywords = keywords.joined(separator: ", ")
        memory.context = context
        memory.confidence = confidence
        memory.relevanceScore = calculateMemoryRelevance(type: type, confidence: confidence)
        memory.createdAt = Date()
        memory.updatedAt = Date()
        memory.conversation = conversation

        // Generate simple embedding (in a real app, you'd use a proper embedding model)
        let embeddingVector = generateSimpleEmbedding(from: summary + " " + keywords.joined(separator: " "))
        memory.setEmbeddingVector(embeddingVector)

        print("✅ Created \(type.rawValue) memory: \(summary)")
    }

    private func calculateMemoryRelevance(type: MemoryType, confidence: Double) -> Double {
        let typeWeight: Double
        switch type {
        case .preference: typeWeight = 1.0
        case .fact: typeWeight = 0.8
        case .context: typeWeight = 0.9
        case .emotion: typeWeight = 0.7
        case .goal: typeWeight = 1.0
        case .skill: typeWeight = 0.9
        case .pattern: typeWeight = 0.8
        }

        return confidence * typeWeight
    }

    private func generateSimpleEmbedding(from text: String) -> [Double] {
        // This is a simple hash-based embedding for demonstration
        // In a production app, you'd use a proper embedding model like SentenceTransformers
        let hash = text.hash
        let random = GKRandomSource(seed: UInt64(abs(hash)))
        return (0..<128).map { _ in random.nextUniform() * 2.0 - 1.0 }
    }

    // MARK: - Topic Management

    private func updateTopics(from analysis: ContextAnalysis, conversation: Conversation) async {
        for topicName in analysis.topics {
            if let existingTopic = await findTopic(named: topicName) {
                // Update existing topic
                existingTopic.frequency += 1
                existingTopic.lastMentioned = Date()
                existingTopic.relevanceScore = calculateTopicRelevance(
                    frequency: existingTopic.frequency,
                    lastMentioned: existingTopic.lastMentioned,
                    confidence: analysis.confidence
                )

                // Add conversation relationship
                let conversations = existingTopic.mutableSetValue(forKey: "conversations")
                conversations.add(conversation)
            } else {
                // Create new topic
                let topic = ConversationTopic(context: context)
                topic.id = UUID()
                topic.name = topicName
                topic.keywords = analysis.keywords.joined(separator: ", ")
                topic.frequency = 1
                topic.confidence = analysis.confidence
                topic.relevanceScore = analysis.confidence
                topic.createdAt = Date()
                topic.lastMentioned = Date()

                // Add conversation relationship
                let conversations = topic.mutableSetValue(forKey: "conversations")
                conversations.add(conversation)

                print("✅ Created new topic: \(topicName)")
            }
        }
    }

    private func findTopic(named name: String) async -> ConversationTopic? {
        let request: NSFetchRequest<ConversationTopic> = ConversationTopic.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1

        do {
            let topics = try context.fetch(request)
            return topics.first
        } catch {
            print("❌ Failed to find topic: \(error)")
            return nil
        }
    }

    private func calculateTopicRelevance(frequency: Int32, lastMentioned: Date, confidence: Double) -> Double {
        let frequencyScore = min(Double(frequency) * 0.1, 1.0)
        let recencyScore = max(0.0, 1.0 - (Date().timeIntervalSince(lastMentioned) / (7 * 24 * 3600))) // Decay over 7 days
        return (frequencyScore + recencyScore + confidence) / 3.0
    }

    // MARK: - User Pattern Learning

    private func updateUserPatterns(from message: ConversationMessage, analysis: ContextAnalysis) async {
        // Time-based patterns
        await updateTimePattern(message: message)

        // Topic flow patterns
        await updateTopicFlowPattern(analysis: analysis)

        // Interaction style patterns
        await updateInteractionStylePattern(message: message, analysis: analysis)

        // Session length patterns
        await updateSessionLengthPattern(message: message)
    }

    private func updateTimePattern(message: ConversationMessage) async {
        let hour = Calendar.current.component(.hour, from: message.timestamp)
        let timeSlot = getTimeSlot(for: hour)

        if let pattern = await findBehaviorPattern(type: .timePreference, value: timeSlot) {
            pattern.frequency += 1
            pattern.lastObserved = Date()
            pattern.strength = calculatePatternStrength(frequency: pattern.frequency, lastObserved: pattern.lastObserved)
        } else {
            await createBehaviorPattern(
                type: .timePreference,
                pattern: "User is active during \(timeSlot)",
                timeOfDay: timeSlot,
                frequency: 1
            )
        }
    }

    private func updateTopicFlowPattern(analysis: ContextAnalysis) async {
        let topicFlow = analysis.topics.joined(separator: " -> ")
        if !topicFlow.isEmpty {
            if let pattern = await findBehaviorPattern(type: .topicFlow, value: topicFlow) {
                pattern.frequency += 1
                pattern.lastObserved = Date()
                pattern.strength = calculatePatternStrength(frequency: pattern.frequency, lastObserved: pattern.lastObserved)
            } else {
                await createBehaviorPattern(
                    type: .topicFlow,
                    pattern: "User discusses topics in sequence: \(topicFlow)",
                    timeOfDay: nil,
                    frequency: 1
                )
            }
        }
    }

    private func updateInteractionStylePattern(message: ConversationMessage, analysis: ContextAnalysis) async {
        let style = determineInteractionStyle(message: message, analysis: analysis)

        if let pattern = await findBehaviorPattern(type: .interactionStyle, value: style) {
            pattern.frequency += 1
            pattern.lastObserved = Date()
            pattern.strength = calculatePatternStrength(frequency: pattern.frequency, lastObserved: pattern.lastObserved)
        } else {
            await createBehaviorPattern(
                type: .interactionStyle,
                pattern: "User prefers \(style) interaction style",
                timeOfDay: nil,
                frequency: 1
            )
        }
    }

    private func updateSessionLengthPattern(message: ConversationMessage) async {
        // This would require session tracking - simplified for now
        let estimatedSessionLength = 300.0 // 5 minutes default

        if let pattern = await findBehaviorPattern(type: .sessionLength, value: "average") {
            pattern.averageSessionLength = (pattern.averageSessionLength + estimatedSessionLength) / 2.0
            pattern.frequency += 1
            pattern.lastObserved = Date()
        } else {
            await createBehaviorPattern(
                type: .sessionLength,
                pattern: "User session length pattern",
                timeOfDay: nil,
                frequency: 1,
                sessionLength: estimatedSessionLength
            )
        }
    }

    private func getTimeSlot(for hour: Int) -> String {
        switch hour {
        case 6..<12: return "morning"
        case 12..<17: return "afternoon"
        case 17..<21: return "evening"
        default: return "night"
        }
    }

    private func determineInteractionStyle(message: ConversationMessage, analysis: ContextAnalysis) -> String {
        if analysis.intent == "question" {
            return "inquisitive"
        } else if analysis.intent == "command" {
            return "directive"
        } else if message.content.count > 200 {
            return "detailed"
        } else if message.content.count < 50 {
            return "concise"
        } else {
            return "conversational"
        }
    }

    private func findBehaviorPattern(type: PatternType, value: String) async -> UserBehaviorPattern? {
        let request: NSFetchRequest<UserBehaviorPattern> = UserBehaviorPattern.fetchRequest()
        request.predicate = NSPredicate(format: "patternType == %@ AND pattern CONTAINS %@", type.rawValue, value)
        request.fetchLimit = 1

        do {
            let patterns = try context.fetch(request)
            return patterns.first
        } catch {
            print("❌ Failed to find behavior pattern: \(error)")
            return nil
        }
    }

    private func createBehaviorPattern(
        type: PatternType,
        pattern: String,
        timeOfDay: String?,
        frequency: Int32,
        sessionLength: Double = 0.0
    ) async {
        let behaviorPattern = UserBehaviorPattern(context: context)
        behaviorPattern.id = UUID()
        behaviorPattern.patternType = type.rawValue
        behaviorPattern.pattern = pattern
        behaviorPattern.timeOfDay = timeOfDay
        behaviorPattern.frequency = frequency
        behaviorPattern.strength = calculatePatternStrength(frequency: frequency, lastObserved: Date())
        behaviorPattern.averageSessionLength = sessionLength
        behaviorPattern.createdAt = Date()
        behaviorPattern.updatedAt = Date()
        behaviorPattern.lastObserved = Date()

        print("✅ Created behavior pattern: \(pattern)")
    }

    private func calculatePatternStrength(frequency: Int32, lastObserved: Date) -> Double {
        let frequencyScore = min(Double(frequency) * 0.05, 1.0)
        let recencyScore = max(0.0, 1.0 - (Date().timeIntervalSince(lastObserved) / (7 * 24 * 3600)))
        return (frequencyScore + recencyScore) / 2.0
    }

    // MARK: - User Preference Learning

    private func updateUserPreferences(from message: ConversationMessage, analysis: ContextAnalysis) async {
        // AI Provider preference (based on which provider was used and user satisfaction)
        if let aiProvider = message.aiProvider, message.role == "assistant" {
            await updatePreference(
                key: "preferred_ai_provider",
                value: aiProvider,
                type: .aiProvider,
                strength: 0.1
            )
        }

        // Response length preference
        if message.role == "assistant" {
            let lengthCategory = categorizeResponseLength(message.content.count)
            await updatePreference(
                key: "preferred_response_length",
                value: lengthCategory,
                type: .responseLength,
                strength: 0.1
            )
        }

        // Topic interest preference
        for topic in analysis.topics {
            await updatePreference(
                key: "topic_interest_\(topic.lowercased())",
                value: String(analysis.confidence),
                type: .topicInterest,
                strength: analysis.confidence * 0.2
            )
        }

        // Communication style preference
        let style = determineCommunicationStyle(from: message, analysis: analysis)
        await updatePreference(
            key: "communication_style",
            value: style,
            type: .communicationStyle,
            strength: 0.15
        )
    }

    private func updatePreference(key: String, value: String, type: PreferenceType, strength: Double) async {
        if let existing = await findUserPreference(key: key, type: type) {
            existing.frequency += 1
            existing.strength = min(existing.strength + strength, 1.0)
            existing.lastUsed = Date()
            existing.updatedAt = Date()
        } else {
            let preference = UserPreference(context: context)
            preference.id = UUID()
            preference.preferenceKey = key
            preference.preferenceValue = value
            preference.preferenceType = type.rawValue
            preference.strength = strength
            preference.frequency = 1
            preference.createdAt = Date()
            preference.updatedAt = Date()
            preference.lastUsed = Date()

            print("✅ Created user preference: \(key) = \(value)")
        }
    }

    private func findUserPreference(key: String, type: PreferenceType) async -> UserPreference? {
        let request: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        request.predicate = NSPredicate(format: "preferenceKey == %@ AND preferenceType == %@", key, type.rawValue)
        request.fetchLimit = 1

        do {
            let preferences = try context.fetch(request)
            return preferences.first
        } catch {
            print("❌ Failed to find user preference: \(error)")
            return nil
        }
    }

    private func categorizeResponseLength(_ length: Int) -> String {
        switch length {
        case 0..<100: return "brief"
        case 100..<300: return "medium"
        case 300..<600: return "detailed"
        default: return "comprehensive"
        }
    }

    private func determineCommunicationStyle(from message: ConversationMessage, analysis: ContextAnalysis) -> String {
        if message.role == "user" {
            if analysis.intent == "question" && message.content.contains("please") {
                return "polite_inquisitive"
            } else if analysis.intent == "command" {
                return "direct"
            } else if analysis.sentiment == "positive" {
                return "friendly"
            } else {
                return "neutral"
            }
        }
        return "neutral"
    }

    // MARK: - Context Suggestions

    private func generateContextSuggestions(for conversation: Conversation) async -> [ConversationSuggestion] {
        var suggestions: [ConversationSuggestion] = []

        // Topic-based suggestions
        let activeTopics = await getActiveTopics(for: conversation, limit: 3)
        for topic in activeTopics {
            suggestions.append(ConversationSuggestion(
                text: "Tell me more about \(topic.name)",
                type: "question",
                relevanceScore: topic.relevanceScore,
                context: "Based on your interest in \(topic.name)"
            ))
        }

        // Memory-based suggestions
        let relevantMemories = await getRelevantMemories(for: conversation, limit: 5)
        for memory in relevantMemories.prefix(2) {
            if memory.memoryType == "preference" {
                suggestions.append(ConversationSuggestion(
                    text: "Would you like to explore \(memory.keywordsArray.first ?? "this topic") further?",
                    type: "topic",
                    relevanceScore: memory.relevanceScore,
                    context: "Based on your previous interests"
                ))
            }
        }

        // Pattern-based suggestions
        let patterns = await getStrongUserPatterns(limit: 2)
        for pattern in patterns {
            if pattern.patternType == "time_preference" && pattern.strength > 0.7 {
                suggestions.append(ConversationSuggestion(
                    text: "It's your active time - anything specific you'd like to work on?",
                    type: "action",
                    relevanceScore: pattern.strength,
                    context: "Based on your usage patterns"
                ))
            }
        }

        return suggestions.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    // MARK: - Data Retrieval

    private func getRelevantMemories(for conversation: Conversation, limit: Int) async -> [ConversationMemory] {
        let request: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        request.predicate = NSPredicate(format: "conversation == %@ AND confidence > %f", conversation, minConfidenceThreshold)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ConversationMemory.relevanceScore, ascending: false),
            NSSortDescriptor(keyPath: \ConversationMemory.updatedAt, ascending: false),
        ]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch relevant memories: \(error)")
            return []
        }
    }

    private func getActiveTopics(for conversation: Conversation, limit: Int) async -> [ConversationTopic] {
        let request: NSFetchRequest<ConversationTopic> = ConversationTopic.fetchRequest()
        request.predicate = NSPredicate(format: "conversations CONTAINS %@ AND relevanceScore > %f", conversation, 0.3)
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \ConversationTopic.relevanceScore, ascending: false),
            NSSortDescriptor(keyPath: \ConversationTopic.lastMentioned, ascending: false),
        ]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch active topics: \(error)")
            return []
        }
    }

    private func getStrongUserPatterns(limit: Int) async -> [UserBehaviorPattern] {
        let request: NSFetchRequest<UserBehaviorPattern> = UserBehaviorPattern.fetchRequest()
        request.predicate = NSPredicate(format: "strength > %f", 0.5)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserBehaviorPattern.strength, ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch user patterns: \(error)")
            return []
        }
    }

    private func getUserContextSummary() async -> String {
        let preferences = await getTopUserPreferences(limit: 5)
        let patterns = await getStrongUserPatterns(limit: 3)

        var summary = ""

        if !preferences.isEmpty {
            summary += "Preferences: "
            summary += preferences.map { "\($0.preferenceKey): \($0.preferenceValue)" }.joined(separator: ", ")
            summary += "\n"
        }

        if !patterns.isEmpty {
            summary += "Patterns: "
            summary += patterns.map { $0.pattern }.joined(separator: "; ")
        }

        return summary.isEmpty ? "No specific user context available" : summary
    }

    private func getTopUserPreferences(limit: Int) async -> [UserPreference] {
        let request: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserPreference.strength, ascending: false)]
        request.fetchLimit = limit

        do {
            return try context.fetch(request)
        } catch {
            print("❌ Failed to fetch user preferences: \(error)")
            return []
        }
    }

    // MARK: - User Insights Generation

    func generateUserInsights() async -> [UserInsight] {
        var insights: [UserInsight] = []

        // Analyze conversation patterns
        let patterns = await getStrongUserPatterns(limit: 10)
        for pattern in patterns {
            if pattern.strength > 0.8 {
                insights.append(UserInsight(
                    type: "pattern",
                    description: "Strong \(pattern.patternType) pattern detected: \(pattern.pattern)",
                    confidence: pattern.strength,
                    actionable: true,
                    suggestedAction: "Consider optimizing interactions for this pattern"
                ))
            }
        }

        // Analyze preferences
        let preferences = await getTopUserPreferences(limit: 10)
        let strongPreferences = preferences.filter { $0.strength > 0.7 }
        if !strongPreferences.isEmpty {
            insights.append(UserInsight(
                type: "preference",
                description: "Clear preferences identified in \(strongPreferences.count) areas",
                confidence: strongPreferences.map { $0.strength }.reduce(0, +) / Double(strongPreferences.count),
                actionable: true,
                suggestedAction: "Customize experience based on these preferences"
            ))
        }

        // Analyze topic interests
        let request: NSFetchRequest<ConversationTopic> = ConversationTopic.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationTopic.frequency, ascending: false)]
        request.fetchLimit = 5

        do {
            let topTopics = try context.fetch(request)
            if !topTopics.isEmpty {
                insights.append(UserInsight(
                    type: "interest",
                    description: "Primary interests: \(topTopics.map { $0.name }.joined(separator: ", "))",
                    confidence: 0.9,
                    actionable: true,
                    suggestedAction: "Suggest content related to these topics"
                ))
            }
        } catch {
            print("❌ Failed to analyze topic interests: \(error)")
        }

        return insights
    }

    // MARK: - Helper Methods

    private func loadRecentData() async {
        // Load recent memories
        let memoryRequest: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        memoryRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationMemory.updatedAt, ascending: false)]
        memoryRequest.fetchLimit = 20

        do {
            recentMemories = try context.fetch(memoryRequest)
        } catch {
            print("❌ Failed to load recent memories: \(error)")
        }

        // Load active topics
        let topicRequest: NSFetchRequest<ConversationTopic> = ConversationTopic.fetchRequest()
        topicRequest.predicate = NSPredicate(format: "relevanceScore > %f", 0.3)
        topicRequest.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationTopic.relevanceScore, ascending: false)]
        topicRequest.fetchLimit = maxActiveTopics

        do {
            activeTopics = try context.fetch(topicRequest)
        } catch {
            print("❌ Failed to load active topics: \(error)")
        }

        // Load user preferences
        let preferenceRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
        preferenceRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserPreference.strength, ascending: false)]
        preferenceRequest.fetchLimit = 20

        do {
            userPreferences = try context.fetch(preferenceRequest)
        } catch {
            print("❌ Failed to load user preferences: \(error)")
        }

        // Load behavior patterns
        let patternRequest: NSFetchRequest<UserBehaviorPattern> = UserBehaviorPattern.fetchRequest()
        patternRequest.predicate = NSPredicate(format: "strength > %f", 0.3)
        patternRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserBehaviorPattern.strength, ascending: false)]
        patternRequest.fetchLimit = 15

        do {
            behaviorPatterns = try context.fetch(patternRequest)
        } catch {
            print("❌ Failed to load behavior patterns: \(error)")
        }

        // Generate user insights
        userInsights = await generateUserInsights()
    }

    private func buildContextString(for conversation: Conversation) -> String {
        let recentMessages = conversation.messagesArray.suffix(5)
        return recentMessages.map { "\($0.role): \($0.content)" }.joined(separator: "\n")
    }

    private func updateConversationContextWeight(_ conversation: Conversation, analysis: ContextAnalysis) {
        conversation.contextWeight = analysis.contextWidth
        conversation.lastActiveAt = Date()
        conversation.contextTopics = analysis.topics.joined(separator: ", ")
        conversation.memoryKeywords = analysis.keywords.joined(separator: ", ")
    }

    private func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Memory context saved successfully")
            } catch {
                print("❌ Failed to save memory context: \(error)")
            }
        }
    }

    // MARK: - Periodic Maintenance

    private func performPeriodicMaintenance() async {
        print("🔄 Performing memory system maintenance...")

        // Clean up old memories
        await cleanupOldMemories()

        // Update topic relevance scores
        await updateTopicRelevanceScores()

        // Decay unused patterns
        await decayUnusedPatterns()

        // Consolidate similar memories
        await consolidateSimilarMemories()

        // Update cache
        contextCache.removeAll()
        suggestionCache.removeAll()
        lastAnalysisTime.removeAll()

        saveContext()
        await loadRecentData()

        print("✅ Memory system maintenance completed")
    }

    private func cleanupOldMemories() async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -memoryRetentionDays, to: Date()) ?? Date()

        let request: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt < %@ AND confidence < %f", cutoffDate as NSDate, 0.5)

        do {
            let oldMemories = try context.fetch(request)
            for memory in oldMemories {
                context.delete(memory)
            }
            print("🗑️ Cleaned up \(oldMemories.count) old memories")
        } catch {
            print("❌ Failed to cleanup old memories: \(error)")
        }
    }

    private func updateTopicRelevanceScores() async {
        let request: NSFetchRequest<ConversationTopic> = ConversationTopic.fetchRequest()

        do {
            let topics = try context.fetch(request)
            for topic in topics {
                topic.relevanceScore = calculateTopicRelevance(
                    frequency: topic.frequency,
                    lastMentioned: topic.lastMentioned,
                    confidence: topic.confidence
                )
            }
            print("📊 Updated relevance scores for \(topics.count) topics")
        } catch {
            print("❌ Failed to update topic relevance scores: \(error)")
        }
    }

    private func decayUnusedPatterns() async {
        let request: NSFetchRequest<UserBehaviorPattern> = UserBehaviorPattern.fetchRequest()

        do {
            let patterns = try context.fetch(request)
            for pattern in patterns {
                let daysSinceLastObserved = Date().timeIntervalSince(pattern.lastObserved) / (24 * 3600)
                if daysSinceLastObserved > 7 {
                    pattern.strength = max(pattern.strength - 0.1, 0.0)
                }
            }
            print("📉 Applied decay to unused patterns")
        } catch {
            print("❌ Failed to decay unused patterns: \(error)")
        }
    }

    private func consolidateSimilarMemories() async {
        // This is a simplified consolidation - in a real app, you'd use semantic similarity
        let request: NSFetchRequest<ConversationMemory> = ConversationMemory.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ConversationMemory.createdAt, ascending: false)]

        do {
            let memories = try context.fetch(request)
            var consolidatedCount = 0

            for i in 0..<memories.count {
                for j in (i+1)..<memories.count {
                    let memory1 = memories[i]
                    let memory2 = memories[j]

                    if areSimilarMemories(memory1, memory2) {
                        // Merge memories
                        memory1.confidence = max(memory1.confidence, memory2.confidence)
                        memory1.relevanceScore = max(memory1.relevanceScore, memory2.relevanceScore)
                        memory1.updatedAt = Date()

                        context.delete(memory2)
                        consolidatedCount += 1
                        break
                    }
                }
            }

            if consolidatedCount > 0 {
                print("🔗 Consolidated \(consolidatedCount) similar memories")
            }
        } catch {
            print("❌ Failed to consolidate memories: \(error)")
        }
    }

    private func areSimilarMemories(_ memory1: ConversationMemory, _ memory2: ConversationMemory) -> Bool {
        // Simple similarity check - in production, use semantic similarity
        let keywords1 = Set(memory1.keywordsArray)
        let keywords2 = Set(memory2.keywordsArray)
        let intersection = keywords1.intersection(keywords2)
        let union = keywords1.union(keywords2)

        let similarity = Double(intersection.count) / Double(union.count)
        return similarity > 0.7 && memory1.memoryType == memory2.memoryType
    }
}

// MARK: - Core Data Model Extensions

extension ConversationMemory {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationMemory> {
        return NSFetchRequest<ConversationMemory>(entityName: "ConversationMemory")
    }
}

extension ConversationTopic {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationTopic> {
        return NSFetchRequest<ConversationTopic>(entityName: "ConversationTopic")
    }
}

extension UserPreference {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPreference> {
        return NSFetchRequest<UserPreference>(entityName: "UserPreference")
    }
}

extension UserBehaviorPattern {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserBehaviorPattern> {
        return NSFetchRequest<UserBehaviorPattern>(entityName: "UserBehaviorPattern")
    }
}

// MARK: - Core Data Extensions for Enhanced Conversation Model

extension Conversation {
    public var memoriesArray: [ConversationMemory] {
        let set = memories as? Set<ConversationMemory> ?? []
        return set.sorted { $0.updatedAt > $1.updatedAt }
    }

    public var topicsArray: [ConversationTopic] {
        let set = topics as? Set<ConversationTopic> ?? []
        return set.sorted { $0.relevanceScore > $1.relevanceScore }
    }

    public var contextTopicsArray: [String] {
        return contextTopics?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
    }

    public var memoryKeywordsArray: [String] {
        return memoryKeywords?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } ?? []
    }
}

extension ConversationMessage {
    public var embeddingVector: [Double] {
        guard let embedding = contextEmbedding,
              let data = embedding.data(using: .utf8),
              let vector = try? JSONDecoder().decode([Double].self, from: data) else {
            return []
        }
        return vector
    }

    public func setEmbeddingVector(_ vector: [Double]) {
        guard let data = try? JSONEncoder().encode(vector),
              let embeddingString = String(data: data, encoding: .utf8) else {
            return
        }
        self.contextEmbedding = embeddingString
    }
}
