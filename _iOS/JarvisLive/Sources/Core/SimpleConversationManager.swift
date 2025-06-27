/**
 * Purpose: Simplified conversation management without Core Data for immediate implementation
 * Issues & Complexity Summary: In-memory conversation storage with basic persistence
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: Medium (In-memory management, basic persistence)
 *   - Dependencies: 2 New (Foundation, Combine)
 *   - State Management Complexity: Medium (Conversation state tracking)
 *   - Novelty/Uncertainty Factor: Low (Simple data structures)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 60%
 * Initial Code Complexity Estimate %: 65%
 * Justification for Estimates: Simple in-memory conversation management
 * Final Code Complexity (Actual %): 65%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: In-memory approach provides quick implementation
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine

// MARK: - Simple Data Models

struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    var totalMessages: Int
    var messages: [ConversationMessage]
    
    init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isArchived = false
        self.totalMessages = 0
        self.messages = []
    }
}

struct ConversationMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
    let audioTranscription: String?
    let aiProvider: String?
    let processingTime: Double
    
    init(content: String, role: MessageRole, audioTranscription: String? = nil, aiProvider: String? = nil, processingTime: Double = 0.0) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
        self.audioTranscription = audioTranscription
        self.aiProvider = aiProvider
        self.processingTime = processingTime
    }
}

enum MessageRole: String, CaseIterable, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

// MARK: - Simple Conversation Manager

@MainActor
class ConversationManager: ObservableObject {
    
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filteredConversations: [Conversation] = []
    
    private let userDefaults = UserDefaults.standard
    private let conversationsKey = "SavedConversations"
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSearchBinding()
        loadConversations()
    }
    
    // MARK: - Search Functionality
    
    private func setupSearchBinding() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                self?.filterConversations(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    private func filterConversations(searchText: String) {
        if searchText.isEmpty {
            filteredConversations = conversations
        } else {
            filteredConversations = conversations.filter { conversation in
                conversation.title.localizedCaseInsensitiveContains(searchText) ||
                conversation.messages.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    func saveConversations() {
        do {
            let data = try JSONEncoder().encode(conversations)
            userDefaults.set(data, forKey: conversationsKey)
            print("✅ Saved \(conversations.count) conversations")
        } catch {
            print("❌ Failed to save conversations: \(error)")
        }
    }
    
    func loadConversations() {
        isLoading = true
        
        guard let data = userDefaults.data(forKey: conversationsKey) else {
            conversations = []
            filteredConversations = []
            isLoading = false
            return
        }
        
        do {
            conversations = try JSONDecoder().decode([Conversation].self, from: data)
            filteredConversations = conversations.filter { !$0.isArchived }
            print("✅ Loaded \(conversations.count) conversations")
        } catch {
            print("❌ Failed to load conversations: \(error)")
            conversations = []
            filteredConversations = []
        }
        
        isLoading = false
    }
    
    // MARK: - Conversation Management
    
    func createNewConversation(title: String? = nil) -> Conversation {
        let conversation = Conversation(title: title ?? "New Conversation")
        conversations.insert(conversation, at: 0) // Add to beginning
        saveConversations()
        filterConversations(searchText: searchText)
        print("✅ Created new conversation: \(conversation.title)")
        return conversation
    }
    
    func setCurrentConversation(_ conversation: Conversation) {
        currentConversation = conversation
        print("✅ Set current conversation: \(conversation.title)")
    }
    
    func updateConversationTitle(_ conversation: Conversation, title: String) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].title = title
            conversations[index].updatedAt = Date()
            saveConversations()
            filterConversations(searchText: searchText)
        }
    }
    
    func archiveConversation(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].isArchived = true
            conversations[index].updatedAt = Date()
            
            if currentConversation?.id == conversation.id {
                currentConversation = nil
            }
            
            saveConversations()
            filterConversations(searchText: searchText)
            print("✅ Archived conversation: \(conversation.title)")
        }
    }
    
    func deleteConversation(_ conversation: Conversation) {
        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }
        
        conversations.removeAll { $0.id == conversation.id }
        saveConversations()
        filterConversations(searchText: searchText)
        print("✅ Deleted conversation: \(conversation.title)")
    }
    
    // MARK: - Message Management
    
    func addMessage(
        to conversation: Conversation,
        content: String,
        role: MessageRole,
        audioTranscription: String? = nil,
        aiProvider: String? = nil,
        processingTime: Double = 0.0
    ) -> ConversationMessage {
        let message = ConversationMessage(
            content: content,
            role: role,
            audioTranscription: audioTranscription,
            aiProvider: aiProvider,
            processingTime: processingTime
        )
        
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index].messages.append(message)
            conversations[index].totalMessages += 1
            conversations[index].updatedAt = Date()
            
            // Auto-generate title for first user message
            if conversations[index].totalMessages == 1 && role == .user {
                let title = generateConversationTitle(from: content)
                conversations[index].title = title
            }
            
            // Update current conversation if it matches
            if currentConversation?.id == conversation.id {
                currentConversation = conversations[index]
            }
            
            saveConversations()
            filterConversations(searchText: searchText)
        }
        
        print("✅ Added \(role.rawValue) message to conversation: \(conversation.title)")
        return message
    }
    
    func getMessages(for conversation: Conversation) -> [ConversationMessage] {
        return conversation.messages
    }
    
    // MARK: - Context Management
    
    func buildAIContext(for conversation: Conversation) -> String {
        let recentMessages = Array(conversation.messages.suffix(10)) // Last 10 messages
        
        var contextString = "Previous conversation context:\n"
        for message in recentMessages {
            let role = message.role.rawValue.capitalized
            contextString += "\(role): \(message.content)\n"
        }
        
        return contextString
    }
    
    // MARK: - Export Functionality
    
    func exportConversation(_ conversation: Conversation) -> String {
        var export = "Conversation: \(conversation.title)\n"
        export += "Created: \(conversation.createdAt)\n"
        export += "Messages: \(conversation.totalMessages)\n\n"
        
        for message in conversation.messages {
            export += "[\(message.timestamp)] \(message.role.rawValue.capitalized): \(message.content)\n"
            if let provider = message.aiProvider {
                export += "  (AI Provider: \(provider), Processing: \(message.processingTime)s)\n"
            }
            export += "\n"
        }
        
        return export
    }
    
    func exportAllConversations() -> String {
        var export = "Jarvis Live - Conversation Export\n"
        export += "Exported: \(Date())\n"
        export += "Total Conversations: \(conversations.count)\n\n"
        export += String(repeating: "=", count: 50) + "\n\n"
        
        for conversation in conversations {
            export += exportConversation(conversation)
            export += String(repeating: "-", count: 30) + "\n\n"
        }
        
        return export
    }
    
    // MARK: - Statistics
    
    func getConversationStats() -> ConversationStats {
        let totalMessages = conversations.reduce(0) { $0 + $1.totalMessages }
        let totalConversations = conversations.count
        let archivedCount = conversations.filter { $0.isArchived }.count
        
        return ConversationStats(
            totalConversations: totalConversations,
            totalMessages: totalMessages,
            archivedConversations: archivedCount,
            averageMessagesPerConversation: totalConversations > 0 ? Double(totalMessages) / Double(totalConversations) : 0
        )
    }
    
    // MARK: - Utility Functions
    
    private func generateConversationTitle(from content: String) -> String {
        let words = content.components(separatedBy: .whitespacesAndNewlines)
        let firstWords = Array(words.prefix(6)).joined(separator: " ")
        
        if firstWords.count > 50 {
            return String(firstWords.prefix(47)) + "..."
        }
        
        return firstWords.isEmpty ? "New Conversation" : firstWords
    }
}

// MARK: - Supporting Types

struct ConversationStats {
    let totalConversations: Int
    let totalMessages: Int
    let archivedConversations: Int
    let averageMessagesPerConversation: Double
}