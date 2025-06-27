// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Core conversation management with persistent storage and context handling
 * Issues & Complexity Summary: Complex data model with Core Data, conversation threading, context management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~600
 *   - Core Algorithm Complexity: High (Data persistence, context management, threading)
 *   - Dependencies: 4 New (CoreData, Foundation, Combine, SwiftUI)
 *   - State Management Complexity: High (Multiple conversation states, context tracking)
 *   - Novelty/Uncertainty Factor: Medium (Core Data integration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Complex data persistence with conversation context and threading
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import Foundation
import CoreData
import Combine
import SwiftUI

// MARK: - Data Models

@objc(Conversation)
public class Conversation: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var isArchived: Bool
    @NSManaged public var totalMessages: Int32
    @NSManaged public var conversationContext: String?
    @NSManaged public var messages: NSSet?

    public var messagesArray: [ConversationMessage] {
        let set = messages as? Set<ConversationMessage> ?? []
        return set.sorted { $0.timestamp < $1.timestamp }
    }
}

/// Core Data ConversationMessage - canonical definition for persistent storage
/// This is the authoritative definition for database-backed conversation messages
/// For simple in-memory usage, see SimpleConversationMessage in SimpleConversationManager.swift
@objc(ConversationMessage)
public class ConversationMessage: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var role: String // "user", "assistant", "system"
    @NSManaged public var timestamp: Date
    @NSManaged public var audioTranscription: String?
    @NSManaged public var aiProvider: String? // "claude", "openai", "gemini"
    @NSManaged public var processingTime: Double
    @NSManaged public var conversation: Conversation?
}

// MARK: - Conversation Manager

@MainActor
class ConversationManager: ObservableObject {
    // MARK: - Published Properties

    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var filteredConversations: [Conversation] = []

    // MARK: - Core Data Stack

    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "ConversationDataModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                print("❌ Core Data error: \(error)")
            }
        }
        return container
    }()

    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    // MARK: - Conversation Context Management

    private var conversationContexts: [UUID: [String: Any]] = [:]
    private let maxContextMessages = 20

    // MARK: - Publishers

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    @MainActor
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
                conversation.messagesArray.contains { message in
                    message.content.localizedCaseInsensitiveContains(searchText)
                }
            }
        }
    }

    // MARK: - Core Data Operations

    func loadConversations() {
        isLoading = true

        let request: NSFetchRequest<Conversation> = Conversation.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.updatedAt, ascending: false)]
        request.predicate = NSPredicate(format: "isArchived == NO")

        do {
            conversations = try context.fetch(request)
            filteredConversations = conversations
            print("✅ Loaded \(conversations.count) conversations")
        } catch {
            print("❌ Failed to load conversations: \(error)")
        }

        isLoading = false
    }

    func saveContext() {
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Context saved successfully")
            } catch {
                print("❌ Failed to save context: \(error)")
            }
        }
    }

    // MARK: - Conversation Management

    func createNewConversation(title: String? = nil) -> Conversation {
        let conversation = Conversation(context: context)
        conversation.id = UUID()
        conversation.title = title ?? "New Conversation"
        conversation.createdAt = Date()
        conversation.updatedAt = Date()
        conversation.isArchived = false
        conversation.totalMessages = 0

        saveContext()
        loadConversations()

        print("✅ Created new conversation: \(conversation.title)")
        return conversation
    }

    func setCurrentConversation(_ conversation: Conversation) {
        currentConversation = conversation
        loadConversationContext(for: conversation)
        print("✅ Set current conversation: \(conversation.title)")
    }

    func updateConversationTitle(_ conversation: Conversation, title: String) {
        conversation.title = title
        conversation.updatedAt = Date()
        saveContext()
        loadConversations()
    }

    func archiveConversation(_ conversation: Conversation) {
        conversation.isArchived = true
        conversation.updatedAt = Date()
        saveContext()

        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }

        loadConversations()
        print("✅ Archived conversation: \(conversation.title)")
    }

    func deleteConversation(_ conversation: Conversation) {
        if currentConversation?.id == conversation.id {
            currentConversation = nil
        }

        conversationContexts.removeValue(forKey: conversation.id)
        context.delete(conversation)
        saveContext()
        loadConversations()
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
        let message = ConversationMessage(context: context)
        message.id = UUID()
        message.content = content
        message.role = role.rawValue
        message.timestamp = Date()
        message.audioTranscription = audioTranscription
        message.aiProvider = aiProvider
        message.processingTime = processingTime
        message.conversation = conversation

        conversation.totalMessages += 1
        conversation.updatedAt = Date()

        // Auto-generate title for first user message
        if conversation.totalMessages == 1 && role == .user {
            let title = generateConversationTitle(from: content)
            conversation.title = title
        }

        // Update conversation context
        updateConversationContext(for: conversation, with: message)

        saveContext()
        loadConversations()

        print("✅ Added \(role.rawValue) message to conversation: \(conversation.title)")
        return message
    }

    func getMessages(for conversation: Conversation) -> [ConversationMessage] {
        return conversation.messagesArray
    }

    // MARK: - Context Management

    func getConversationContext(for conversation: Conversation) -> [String: Any] {
        return conversationContexts[conversation.id] ?? [:]
    }

    private func loadConversationContext(for conversation: Conversation) {
        if let contextData = conversation.conversationContext?.data(using: .utf8),
           let context = try? JSONSerialization.jsonObject(with: contextData) as? [String: Any] {
            conversationContexts[conversation.id] = context
        } else {
            conversationContexts[conversation.id] = [:]
        }
    }

    private func updateConversationContext(for conversation: Conversation, with message: ConversationMessage) {
        var context = conversationContexts[conversation.id] ?? [:]

        // Add message to context
        var contextMessages = context["messages"] as? [[String: Any]] ?? []
        let messageData: [String: Any] = [
            "role": message.role,
            "content": message.content,
            "timestamp": message.timestamp.timeIntervalSince1970,
            "aiProvider": message.aiProvider ?? "",
        ]
        contextMessages.append(messageData)

        // Keep only recent messages for context
        if contextMessages.count > maxContextMessages {
            contextMessages = Array(contextMessages.suffix(maxContextMessages))
        }

        context["messages"] = contextMessages
        context["lastUpdated"] = Date().timeIntervalSince1970
        context["messageCount"] = contextMessages.count

        conversationContexts[conversation.id] = context

        // Save to Core Data
        if let contextData = try? JSONSerialization.data(withJSONObject: context),
           let contextString = String(data: contextData, encoding: .utf8) {
            conversation.conversationContext = contextString
        }
    }

    func buildAIContext(for conversation: Conversation) -> String {
        let messages = getMessages(for: conversation)
        let recentMessages = Array(messages.suffix(maxContextMessages))

        var contextString = "Previous conversation context:\n"
        for message in recentMessages {
            let role = message.role.capitalized
            contextString += "\(role): \(message.content)\n"
        }

        return contextString
    }

    // MARK: - MCP Context Integration

    func addMCPContextMessage(
        to conversation: Conversation,
        userInput: String,
        aiResponse: String,
        toolName: String? = nil,
        parameters: [String: Any]? = nil,
        result: Any? = nil,
        processingTime: Double = 0.0
    ) {
        // Add user message
        let userMessage = addMessage(
            to: conversation,
            content: userInput,
            role: .user,
            processingTime: processingTime
        )

        // Add AI response with MCP context
        let responseContent = aiResponse
        let aiMessage = addMessage(
            to: conversation,
            content: responseContent,
            role: .assistant,
            processingTime: processingTime
        )

        // Store MCP context in conversation
        if let toolName = toolName {
            var mcpContext = getMCPContext(for: conversation)
            mcpContext["last_tool"] = toolName
            mcpContext["last_parameters"] = parameters
            mcpContext["last_result"] = result
            mcpContext["last_execution_time"] = Date().timeIntervalSince1970

            storeMCPContext(mcpContext, for: conversation)
        }

        print("✅ Added MCP context message to conversation: \(conversation.title)")
    }

    func getMCPContext(for conversation: Conversation) -> [String: Any] {
        guard let contextString = conversation.conversationContext,
              let contextData = contextString.data(using: .utf8),
              let context = try? JSONSerialization.jsonObject(with: contextData) as? [String: Any] else {
            return [:]
        }

        return context["mcp_context"] as? [String: Any] ?? [:]
    }

    func storeMCPContext(_ context: [String: Any], for conversation: Conversation) {
        var fullContext = [String: Any]()

        // Preserve existing context
        if let existingContextString = conversation.conversationContext,
           let existingContextData = existingContextString.data(using: .utf8),
           let existingContext = try? JSONSerialization.jsonObject(with: existingContextData) as? [String: Any] {
            fullContext = existingContext
        }

        fullContext["mcp_context"] = context
        fullContext["last_updated"] = Date().timeIntervalSince1970

        // Save back to conversation
        if let contextData = try? JSONSerialization.data(withJSONObject: fullContext),
           let contextString = String(data: contextData, encoding: .utf8) {
            conversation.conversationContext = contextString
            saveContext()
        }
    }

    func getRecentMCPHistory(for conversation: Conversation, limit: Int = 5) -> [MCPHistoryEntry] {
        let mcpContext = getMCPContext(for: conversation)
        let historyArray = mcpContext["history"] as? [[String: Any]] ?? []

        return Array(historyArray.suffix(limit)).compactMap { entry in
            guard let toolName = entry["tool_name"] as? String,
                  let timestamp = entry["timestamp"] as? TimeInterval,
                  let userInput = entry["user_input"] as? String else {
                return nil
            }

            return MCPHistoryEntry(
                toolName: toolName,
                timestamp: Date(timeIntervalSince1970: timestamp),
                userInput: userInput,
                parameters: entry["parameters"] as? [String: Any] ?? [:],
                result: entry["result"],
                success: entry["success"] as? Bool ?? false
            )
        }
    }

    func addMCPHistoryEntry(
        to conversation: Conversation,
        toolName: String,
        userInput: String,
        parameters: [String: Any],
        result: Any?,
        success: Bool
    ) {
        var mcpContext = getMCPContext(for: conversation)
        var history = mcpContext["history"] as? [[String: Any]] ?? []

        let entry: [String: Any] = [
            "tool_name": toolName,
            "timestamp": Date().timeIntervalSince1970,
            "user_input": userInput,
            "parameters": parameters,
            "result": result ?? NSNull(),
            "success": success,
        ]

        history.append(entry)

        // Keep only recent history (last 20 entries)
        if history.count > 20 {
            history = Array(history.suffix(20))
        }

        mcpContext["history"] = history
        storeMCPContext(mcpContext, for: conversation)
    }

    func buildMCPPromptContext(for conversation: Conversation) -> String {
        let messages = getMessages(for: conversation)
        let recentMessages = Array(messages.suffix(10))
        let mcpHistory = getRecentMCPHistory(for: conversation)

        var contextPrompt = "Conversation Context:\n"

        // Add recent messages
        for message in recentMessages {
            contextPrompt += "\(message.role.capitalized): \(message.content)\n"
        }

        // Add MCP tool usage history
        if !mcpHistory.isEmpty {
            contextPrompt += "\nRecent MCP Tool Usage:\n"
            for entry in mcpHistory {
                contextPrompt += "- \(entry.toolName): \(entry.userInput) -> \(entry.success ? "Success" : "Failed")\n"
            }
        }

        contextPrompt += "\nThis context should help maintain continuity in multi-turn conversations and tool operations.\n"

        return contextPrompt
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

    // MARK: - Export/Import Functionality

    func exportConversation(_ conversation: Conversation) -> String {
        let messages = getMessages(for: conversation)
        var export = "Conversation: \(conversation.title)\n"
        export += "Created: \(conversation.createdAt)\n"
        export += "Messages: \(conversation.totalMessages)\n\n"

        for message in messages {
            export += "[\(message.timestamp)] \(message.role.capitalized): \(message.content)\n"
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

    // MARK: - Voice Integration Methods

    /// Add a voice interaction to the conversation
    func addVoiceInteraction(
        to conversation: Conversation,
        userVoiceText: String,
        aiResponse: String,
        processingTime: Double = 0.0,
        aiProvider: String? = nil
    ) -> (userMessage: ConversationMessage, aiMessage: ConversationMessage) {
        // Add user voice message
        let userMessage = addMessage(
            to: conversation,
            content: userVoiceText,
            role: .user,
            audioTranscription: userVoiceText,
            aiProvider: nil,
            processingTime: processingTime
        )
        
        // Add AI response
        let aiMessage = addMessage(
            to: conversation,
            content: aiResponse,
            role: .assistant,
            audioTranscription: nil,
            aiProvider: aiProvider,
            processingTime: processingTime
        )
        
        return (userMessage: userMessage, aiMessage: aiMessage)
    }

    /// Add command completion event to conversation
    func addCommandCompletion(
        to conversation: Conversation,
        command: String,
        result: String,
        success: Bool,
        processingTime: Double = 0.0
    ) -> ConversationMessage {
        let content = success 
            ? "Command '\(command)' completed successfully: \(result)"
            : "Command '\(command)' failed: \(result)"
        
        return addMessage(
            to: conversation,
            content: content,
            role: .system,
            audioTranscription: nil,
            aiProvider: "system",
            processingTime: processingTime
        )
    }

    /// Add error event to conversation
    func addErrorEvent(
        to conversation: Conversation,
        error: Error,
        context: String? = nil
    ) -> ConversationMessage {
        let content = context != nil 
            ? "Error in \(context!): \(error.localizedDescription)"
            : "Error: \(error.localizedDescription)"
        
        return addMessage(
            to: conversation,
            content: content,
            role: .system,
            audioTranscription: nil,
            aiProvider: "system",
            processingTime: 0.0
        )
    }

    // MARK: - Statistics

    func getConversationStats() -> ConversationStats {
        let totalMessages = conversations.reduce(0) { $0 + Int($1.totalMessages) }
        let totalConversations = conversations.count
        let archivedCount = conversations.filter { $0.isArchived }.count

        return ConversationStats(
            totalConversations: totalConversations,
            totalMessages: totalMessages,
            archivedConversations: archivedCount,
            averageMessagesPerConversation: totalConversations > 0 ? Double(totalMessages) / Double(totalConversations) : 0
        )
    }
}

// MARK: - Supporting Types

enum MessageRole: String, CaseIterable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

struct ConversationStats {
    let totalConversations: Int
    let totalMessages: Int
    let archivedConversations: Int
    let averageMessagesPerConversation: Double
}

struct MCPHistoryEntry {
    let toolName: String
    let timestamp: Date
    let userInput: String
    let parameters: [String: Any]
    let result: Any?
    let success: Bool
}

// MARK: - Core Data Model Extensions

extension Conversation {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }
}

extension ConversationMessage {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ConversationMessage> {
        return NSFetchRequest<ConversationMessage>(entityName: "ConversationMessage")
    }
}
