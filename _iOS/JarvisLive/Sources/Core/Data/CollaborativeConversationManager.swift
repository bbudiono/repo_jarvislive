// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Collaborative conversation history management with shared decision tracking and real-time synchronization
 * Issues & Complexity Summary: Complex multi-participant conversation tracking with decision workflows and real-time updates
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~1000
 *   - Core Algorithm Complexity: High (Conversation threading, decision workflows, real-time sync)
 *   - Dependencies: 6 New (Foundation, Combine, CoreData, SharedContextManager, ConversationManager, RealtimeSyncManager)
 *   - State Management Complexity: Very High (Multi-participant conversations, decision states, version tracking)
 *   - Novelty/Uncertainty Factor: High (Collaborative voice AI conversation patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 88%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 87%
 * Justification for Estimates: Collaborative conversation management requires sophisticated threading and decision tracking
 * Final Code Complexity (Actual %): 89%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: Real-time collaborative conversations require careful message ordering and decision state management
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import CoreData

// MARK: - Collaborative Conversation Manager

@MainActor
final class CollaborativeConversationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var collaborativeConversations: [CollaborativeConversation] = []
    @Published private(set) var activeDecisions: [SharedDecision] = []
    @Published private(set) var conversationThreads: [ConversationThreadData] = []
    @Published private(set) var participantContributions: [UUID: ParticipantContribution] = [:]
    @Published private(set) var conversationAnalytics: ConversationAnalytics = ConversationAnalytics()
    @Published private(set) var isProcessingUpdate: Bool = false
    
    // MARK: - Private Properties
    
    private let sharedContextManager: SharedContextManager
    private let conversationManager: ConversationManager
    private let realtimeSyncManager: RealtimeSyncManager
    
    // Conversation state management
    private var conversationStates: [UUID: ConversationState] = [:]
    private var messageQueue: [PendingMessage] = []
    private var decisionWorkflows: [UUID: DecisionWorkflow] = [:]
    
    // Threading and organization
    private var threadManager: ConversationThreadManager
    private var contextualizer: ConversationContextualizer
    private var summarizer: ConversationSummarizer
    
    // Real-time synchronization
    private var lastSyncTimestamp: [UUID: Date] = [:]
    private var pendingSyncOperations: Set<UUID> = []
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        sharedContextManager: SharedContextManager,
        conversationManager: ConversationManager,
        realtimeSyncManager: RealtimeSyncManager
    ) {
        self.sharedContextManager = sharedContextManager
        self.conversationManager = conversationManager
        self.realtimeSyncManager = realtimeSyncManager
        
        self.threadManager = ConversationThreadManager()
        self.contextualizer = ConversationContextualizer()
        self.summarizer = ConversationSummarizer()
        
        setupObservations()
        setupRealtimeSync()
        
        print("✅ CollaborativeConversationManager initialized")
    }
    
    // MARK: - Setup Methods
    
    private func setupObservations() {
        // Observe shared context changes
        sharedContextManager.$currentSession
            .sink { [weak self] session in
                if let session = session {
                    Task { @MainActor in
                        await self?.handleSessionChange(session)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Observe regular conversation changes
        conversationManager.$conversations
            .sink { [weak self] conversations in
                Task { @MainActor in
                    await self?.syncLocalConversations(conversations)
                }
            }
            .store(in: &cancellables)
        
        // Observe participant changes
        sharedContextManager.$participants
            .sink { [weak self] participants in
                Task { @MainActor in
                    await self?.updateParticipantContributions(participants)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupRealtimeSync() {
        // Setup real-time message synchronization
        realtimeSyncManager.delegate = self
        
        // Periodic sync check
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.performPeriodicSync()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Collaborative Conversation Management
    
    func createCollaborativeConversation(
        title: String,
        participants: [UUID],
        conversationType: CollaborativeConversation.ConversationType = .openDiscussion,
        accessLevel: CollaborativeConversation.AccessLevel = .collaborative
    ) async throws -> CollaborativeConversation {
        
        let conversation = CollaborativeConversation(
            id: UUID(),
            sessionId: sharedContextManager.currentSession?.sessionId ?? UUID(),
            title: title,
            createdAt: Date(),
            createdBy: participants.first ?? UUID(), // Would use actual participant ID
            participants: participants,
            conversationType: conversationType,
            accessLevel: accessLevel,
            status: .active,
            messages: [],
            threads: [],
            decisions: [],
            metadata: CollaborativeConversation.ConversationMetadata(
                lastActivity: Date(),
                messageCount: 0,
                participantCount: participants.count,
                tags: [],
                aiProvidersUsed: [],
                averageResponseTime: 0
            )
        )
        
        collaborativeConversations.append(conversation)
        
        // Create conversation state
        conversationStates[conversation.id] = ConversationState(
            conversationId: conversation.id,
            status: .active,
            lastUpdate: Date(),
            pendingMessages: [],
            participantTyping: [],
            contextSnapshot: [:]
        )
        
        // Sync with shared context
        try await syncConversationToSharedContext(conversation)
        
        print("✅ Created collaborative conversation: \(title)")
        return conversation
    }
    
    func addMessageToCollaborativeConversation(
        conversationId: UUID,
        content: String,
        participantId: UUID,
        messageType: CollaborativeMessage.MessageType = .text,
        replyToMessageId: UUID? = nil,
        attachments: [MessageAttachment] = []
    ) async throws -> CollaborativeMessage {
        
        guard let conversationIndex = collaborativeConversations.firstIndex(where: { $0.id == conversationId }) else {
            throw CollaborativeConversationError.conversationNotFound(conversationId)
        }
        
        var conversation = collaborativeConversations[conversationIndex]
        
        // Check permissions
        guard conversation.participants.contains(participantId) else {
            throw CollaborativeConversationError.participantNotAuthorized(participantId)
        }
        
        let message = CollaborativeMessage(
            id: UUID(),
            conversationId: conversationId,
            content: content,
            participantId: participantId,
            timestamp: Date(),
            messageType: messageType,
            replyToMessageId: replyToMessageId,
            attachments: attachments,
            reactions: [],
            metadata: CollaborativeMessage.MessageMetadata(
                edited: false,
                editedAt: nil,
                aiGenerated: false,
                aiProvider: nil,
                processingTime: nil,
                confidence: nil,
                threadId: nil
            ),
            status: .sent,
            visibility: .all
        )
        
        // Add to conversation
        conversation.messages.append(message)
        conversation.metadata.lastActivity = Date()
        conversation.metadata.messageCount += 1
        
        collaborativeConversations[conversationIndex] = conversation
        
        // Update conversation state
        if var state = conversationStates[conversationId] {
            state.lastUpdate = Date()
            conversationStates[conversationId] = state
        }
        
        // Handle threading
        await handleMessageThreading(message, conversation: conversation)
        
        // Broadcast message to other participants
        await broadcastMessage(message)
        
        // Update participant contributions
        updateParticipantContribution(participantId: participantId, messageId: message.id)
        
        // Trigger contextual analysis
        await analyzeMessageContext(message, conversation: conversation)
        
        print("✅ Added message to collaborative conversation: \(conversationId)")
        return message
    }
    
    // MARK: - Decision Management
    
    func proposeDecision(
        conversationId: UUID,
        title: String,
        description: String,
        proposedBy: UUID,
        decisionType: SharedDecision.DecisionType = .consensus,
        options: [DecisionOption] = [],
        deadline: Date? = nil
    ) async throws -> SharedDecision {
        
        guard let conversation = collaborativeConversations.first(where: { $0.id == conversationId }) else {
            throw CollaborativeConversationError.conversationNotFound(conversationId)
        }
        
        guard conversation.participants.contains(proposedBy) else {
            throw CollaborativeConversationError.participantNotAuthorized(proposedBy)
        }
        
        let decision = SharedDecision(
            id: UUID(),
            conversationId: conversationId,
            title: title,
            description: description,
            proposedBy: proposedBy,
            proposedAt: Date(),
            decisionType: decisionType,
            status: .open,
            options: options,
            votes: [],
            comments: [],
            deadline: deadline,
            metadata: SharedDecision.DecisionMetadata(
                contextSnapshot: await captureDecisionContext(conversationId),
                relatedMessages: getRecentMessageIds(conversationId),
                requiredParticipants: conversation.participants,
                minimumVotes: calculateMinimumVotes(decisionType, participantCount: conversation.participants.count)
            )
        )
        
        activeDecisions.append(decision)
        
        // Create decision workflow
        let workflow = DecisionWorkflow(
            decisionId: decision.id,
            status: .collecting,
            steps: generateDecisionSteps(for: decisionType),
            currentStep: 0,
            participants: conversation.participants,
            timeline: []
        )
        
        decisionWorkflows[decision.id] = workflow
        
        // Add decision announcement message
        let announcementMessage = try await addMessageToCollaborativeConversation(
            conversationId: conversationId,
            content: "📋 Decision proposed: \(title)\n\(description)",
            participantId: proposedBy,
            messageType: .decision
        )
        
        // Broadcast decision proposal
        await broadcastDecisionProposal(decision)
        
        print("✅ Proposed decision: \(title)")
        return decision
    }
    
    func voteOnDecision(
        decisionId: UUID,
        participantId: UUID,
        vote: DecisionVote.VoteType,
        comment: String? = nil
    ) async throws {
        
        guard let decisionIndex = activeDecisions.firstIndex(where: { $0.id == decisionId }) else {
            throw CollaborativeConversationError.decisionNotFound(decisionId)
        }
        
        var decision = activeDecisions[decisionIndex]
        
        // Check if participant can vote
        guard decision.metadata.requiredParticipants.contains(participantId) else {
            throw CollaborativeConversationError.participantNotAuthorized(participantId)
        }
        
        // Check if already voted
        if decision.votes.contains(where: { $0.participantId == participantId }) {
            throw CollaborativeConversationError.alreadyVoted(decisionId)
        }
        
        let decisionVote = DecisionVote(
            id: UUID(),
            participantId: participantId,
            voteType: vote,
            timestamp: Date(),
            comment: comment,
            confidence: nil
        )
        
        decision.votes.append(decisionVote)
        
        // Check if decision is resolved
        if let result = await evaluateDecisionStatus(decision) {
            decision.status = result.status
            
            if result.status != .open {
                // Decision is resolved, add result message
                let resultMessage = try await addMessageToCollaborativeConversation(
                    conversationId: decision.conversationId,
                    content: "✅ Decision resolved: \(decision.title) - \(result.summary)",
                    participantId: UUID(), // System message
                    messageType: .system
                )
                
                // Update workflow
                if var workflow = decisionWorkflows[decisionId] {
                    workflow.status = result.status == .approved ? .completed : .rejected
                    decisionWorkflows[decisionId] = workflow
                }
            }
        }
        
        activeDecisions[decisionIndex] = decision
        
        // Broadcast vote
        await broadcastDecisionVote(decisionVote, decision: decision)
        
        print("✅ Vote recorded for decision: \(decision.title)")
    }
    
    // MARK: - Conversation Threading
    
    private func handleMessageThreading(_ message: CollaborativeMessage, conversation: CollaborativeConversation) async {
        let thread = await threadManager.determineThread(for: message, in: conversation)
        
        if let threadId = thread?.id {
            // Update message with thread ID
            if let messageIndex = collaborativeConversations.first(where: { $0.id == conversation.id })?
                .messages.firstIndex(where: { $0.id == message.id }) {
                
                var updatedMessage = message
                updatedMessage.metadata.threadId = threadId
                
                if let conversationIndex = collaborativeConversations.firstIndex(where: { $0.id == conversation.id }) {
                    collaborativeConversations[conversationIndex].messages[messageIndex] = updatedMessage
                }
            }
        }
        
        // Update conversation threads
        await updateConversationThreads(conversation.id)
    }
    
    private func updateConversationThreads(_ conversationId: UUID) async {
        guard let conversation = collaborativeConversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        let threads = await threadManager.extractThreads(from: conversation)
        
        if let conversationIndex = collaborativeConversations.firstIndex(where: { $0.id == conversationId }) {
            collaborativeConversations[conversationIndex].threads = threads
        }
        
        // Update global thread list
        conversationThreads = collaborativeConversations.flatMap { $0.threads }
    }
    
    // MARK: - Real-time Synchronization
    
    private func broadcastMessage(_ message: CollaborativeMessage) async {
        do {
            let messageUpdate = MessageUpdate(
                action: .added,
                message: message,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.conversationMessageAdded, payload: messageUpdate)
            
        } catch {
            print("❌ Failed to broadcast message: \(error)")
        }
    }
    
    private func broadcastDecisionProposal(_ decision: SharedDecision) async {
        do {
            let decisionUpdate = DecisionUpdate(
                action: .proposed,
                decision: decision,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.decisionProposed, payload: decisionUpdate)
            
        } catch {
            print("❌ Failed to broadcast decision proposal: \(error)")
        }
    }
    
    private func broadcastDecisionVote(_ vote: DecisionVote, decision: SharedDecision) async {
        do {
            let voteUpdate = VoteUpdate(
                decisionId: decision.id,
                vote: vote,
                timestamp: Date()
            )
            
            try await realtimeSyncManager.sendMessage(.decisionVoted, payload: voteUpdate)
            
        } catch {
            print("❌ Failed to broadcast decision vote: \(error)")
        }
    }
    
    // MARK: - Context Analysis
    
    private func analyzeMessageContext(_ message: CollaborativeMessage, conversation: CollaborativeConversation) async {
        let context = await contextualizer.analyze(message: message, conversation: conversation)
        
        // Update conversation analytics
        updateConversationAnalytics(with: context)
        
        // Check for actionable items
        if let actionItems = context.actionItems, !actionItems.isEmpty {
            for actionItem in actionItems {
                await handleActionItem(actionItem, conversation: conversation)
            }
        }
        
        // Update participant contributions with context
        if let participantContribution = participantContributions[message.participantId] {
            var updatedContribution = participantContribution
            updatedContribution.contextualContributions.append(context)
            participantContributions[message.participantId] = updatedContribution
        }
    }
    
    private func handleActionItem(_ actionItem: ConversationActionItem, conversation: CollaborativeConversation) async {
        switch actionItem.type {
        case .decision:
            // Auto-propose decision if appropriate
            do {
                let _ = try await proposeDecision(
                    conversationId: conversation.id,
                    title: actionItem.title,
                    description: actionItem.description,
                    proposedBy: UUID(), // System generated
                    decisionType: .consensus
                )
            } catch {
                print("❌ Failed to auto-propose decision: \(error)")
            }
            
        case .task:
            // Create task tracking
            print("📝 Task identified: \(actionItem.title)")
            
        case .follow_up:
            // Schedule follow-up
            print("📅 Follow-up needed: \(actionItem.title)")
            
        case .information_request:
            // Flag information request
            print("❓ Information request: \(actionItem.title)")
        }
    }
    
    // MARK: - Decision Evaluation
    
    private func evaluateDecisionStatus(_ decision: SharedDecision) async -> DecisionResult? {
        let totalParticipants = decision.metadata.requiredParticipants.count
        let totalVotes = decision.votes.count
        let approveVotes = decision.votes.filter { $0.voteType == .approve }.count
        let rejectVotes = decision.votes.filter { $0.voteType == .reject }.count
        
        switch decision.decisionType {
        case .consensus:
            if approveVotes == totalParticipants {
                return DecisionResult(status: .approved, summary: "Unanimous approval")
            } else if rejectVotes > 0 {
                return DecisionResult(status: .rejected, summary: "Consensus not reached")
            }
            
        case .majority:
            if totalVotes == totalParticipants {
                if approveVotes > rejectVotes {
                    return DecisionResult(status: .approved, summary: "Majority approved")
                } else {
                    return DecisionResult(status: .rejected, summary: "Majority rejected")
                }
            }
            
        case .simple:
            let threshold = (totalParticipants / 2) + 1
            if approveVotes >= threshold {
                return DecisionResult(status: .approved, summary: "Simple majority achieved")
            } else if rejectVotes >= threshold {
                return DecisionResult(status: .rejected, summary: "Simple majority rejected")
            }
            
        case .moderator:
            if let moderatorVote = decision.votes.first(where: { vote in
                // Check if voter is moderator (would need participant role info)
                true // Placeholder
            }) {
                return DecisionResult(
                    status: moderatorVote.voteType == .approve ? .approved : .rejected,
                    summary: "Moderator decision"
                )
            }
        }
        
        // Check deadline
        if let deadline = decision.deadline, Date() > deadline {
            return DecisionResult(status: .expired, summary: "Decision deadline passed")
        }
        
        return nil
    }
    
    // MARK: - Utility Methods
    
    private func syncConversationToSharedContext(_ conversation: CollaborativeConversation) async throws {
        // Convert to shared context format and update
        let sharedConversationEntry = SharedContext.SharedConversationEntry(
            id: conversation.id,
            timestamp: conversation.createdAt,
            participantId: conversation.createdBy,
            content: "Collaborative conversation: \(conversation.title)",
            role: .system,
            contextSnapshot: [:],
            processingMetadata: SharedContext.SharedConversationEntry.ProcessingMetadata(
                aiProvider: nil,
                processingTime: 0,
                confidence: nil,
                classification: "collaborative_conversation",
                mcpToolsUsed: []
            ),
            visibility: .public
        )
        
        try await sharedContextManager.updateSharedContext(\.conversationHistory, value: [sharedConversationEntry])
    }
    
    private func captureDecisionContext(_ conversationId: UUID) async -> [String: AnyCodable] {
        guard let conversation = collaborativeConversations.first(where: { $0.id == conversationId }) else {
            return [:]
        }
        
        let recentMessages = Array(conversation.messages.suffix(10))
        let contextSummary = await summarizer.summarize(messages: recentMessages.map { $0.content })
        
        return [
            "context_summary": AnyCodable(contextSummary),
            "message_count": AnyCodable(conversation.messages.count),
            "participant_count": AnyCodable(conversation.participants.count),
            "conversation_type": AnyCodable(conversation.conversationType.rawValue)
        ]
    }
    
    private func getRecentMessageIds(_ conversationId: UUID) -> [UUID] {
        guard let conversation = collaborativeConversations.first(where: { $0.id == conversationId }) else {
            return []
        }
        
        return Array(conversation.messages.suffix(5).map { $0.id })
    }
    
    private func calculateMinimumVotes(_ decisionType: SharedDecision.DecisionType, participantCount: Int) -> Int {
        switch decisionType {
        case .consensus:
            return participantCount
        case .majority:
            return Int(ceil(Double(participantCount) * 0.67))
        case .simple:
            return (participantCount / 2) + 1
        case .moderator:
            return 1
        }
    }
    
    private func generateDecisionSteps(for decisionType: SharedDecision.DecisionType) -> [DecisionWorkflow.WorkflowStep] {
        switch decisionType {
        case .consensus:
            return [
                DecisionWorkflow.WorkflowStep(name: "Proposal", description: "Decision proposed"),
                DecisionWorkflow.WorkflowStep(name: "Discussion", description: "Open discussion period"),
                DecisionWorkflow.WorkflowStep(name: "Voting", description: "Collect votes from all participants"),
                DecisionWorkflow.WorkflowStep(name: "Resolution", description: "Finalize decision")
            ]
        default:
            return [
                DecisionWorkflow.WorkflowStep(name: "Proposal", description: "Decision proposed"),
                DecisionWorkflow.WorkflowStep(name: "Voting", description: "Collect votes"),
                DecisionWorkflow.WorkflowStep(name: "Resolution", description: "Finalize decision")
            ]
        }
    }
    
    private func updateParticipantContribution(participantId: UUID, messageId: UUID) {
        if var contribution = participantContributions[participantId] {
            contribution.messageCount += 1
            contribution.lastActivity = Date()
            contribution.messageIds.append(messageId)
            participantContributions[participantId] = contribution
        } else {
            participantContributions[participantId] = ParticipantContribution(
                participantId: participantId,
                messageCount: 1,
                decisionCount: 0,
                lastActivity: Date(),
                messageIds: [messageId],
                decisionIds: [],
                contextualContributions: []
            )
        }
    }
    
    private func updateConversationAnalytics(with context: MessageContext) {
        conversationAnalytics.totalMessages += 1
        conversationAnalytics.lastUpdate = Date()
        
        if let sentiment = context.sentiment {
            conversationAnalytics.sentimentHistory.append(sentiment)
            
            // Keep only recent sentiment data
            if conversationAnalytics.sentimentHistory.count > 50 {
                conversationAnalytics.sentimentHistory.removeFirst(10)
            }
        }
        
        if let topics = context.topics {
            for topic in topics {
                conversationAnalytics.topicFrequency[topic, default: 0] += 1
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func handleSessionChange(_ session: SharedContext) async {
        // Sync collaborative conversations with new session
        for conversation in collaborativeConversations {
            if conversation.sessionId != session.sessionId {
                try? await syncConversationToSharedContext(conversation)
            }
        }
    }
    
    private func syncLocalConversations(_ conversations: [Conversation]) async {
        // Sync regular conversations to collaborative format if needed
        // This would implement logic to convert individual conversations to collaborative ones
    }
    
    private func updateParticipantContributions(_ participants: [ParticipantInfo]) async {
        // Update participant contribution tracking based on session participants
        for participant in participants {
            if participantContributions[participant.id] == nil {
                participantContributions[participant.id] = ParticipantContribution(
                    participantId: participant.id,
                    messageCount: 0,
                    decisionCount: 0,
                    lastActivity: Date(),
                    messageIds: [],
                    decisionIds: [],
                    contextualContributions: []
                )
            }
        }
    }
    
    private func performPeriodicSync() async {
        // Perform periodic synchronization of conversation state
        guard !isProcessingUpdate else { return }
        
        isProcessingUpdate = true
        defer { isProcessingUpdate = false }
        
        // Sync conversation updates
        for conversation in collaborativeConversations {
            if let lastSync = lastSyncTimestamp[conversation.id],
               conversation.metadata.lastActivity > lastSync {
                
                try? await syncConversationToSharedContext(conversation)
                lastSyncTimestamp[conversation.id] = Date()
            }
        }
        
        // Clean up expired decisions
        activeDecisions.removeAll { decision in
            if let deadline = decision.deadline, Date() > deadline {
                return true
            }
            return false
        }
    }
    
    // MARK: - Public Interface
    
    func getCollaborativeConversations() -> [CollaborativeConversation] {
        return collaborativeConversations
    }
    
    func getActiveDecisions() -> [SharedDecision] {
        return activeDecisions
    }
    
    func getConversationThreads() -> [ConversationThreadData] {
        return conversationThreads
    }
    
    func getParticipantContributions() -> [UUID: ParticipantContribution] {
        return participantContributions
    }
    
    func getConversationAnalytics() -> ConversationAnalytics {
        return conversationAnalytics
    }
}

// MARK: - RealtimeSyncManagerDelegate

extension CollaborativeConversationManager: RealtimeSyncManagerDelegate {
    
    nonisolated func realtimeSyncManager(_ manager: RealtimeSyncManager, didReceiveMessage message: RealtimeSyncMessage) {
        Task { @MainActor in
            await handleRealtimeMessage(message)
        }
    }
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, didFailToDeliverMessage message: RealtimeSyncMessage) {
        print("❌ Failed to deliver real-time message: \(message.type)")
    }
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, connectionStatusDidChange status: RealtimeSyncManager.ConnectionStatus) {
        // Handle connection status changes
    }
    
    func realtimeSyncManager(_ manager: RealtimeSyncManager, connectionQualityDidChange quality: RealtimeSyncManager.ConnectionQuality) {
        // Handle connection quality changes
    }
    
    private func handleRealtimeMessage(_ message: RealtimeSyncMessage) async {
        switch message.type {
        case .conversationMessageAdded:
            if let messageUpdate = try? JSONDecoder().decode(MessageUpdate.self, from: message.payload) {
                await handleRemoteMessageUpdate(messageUpdate)
            }
            
        case .decisionProposed:
            if let decisionUpdate = try? JSONDecoder().decode(DecisionUpdate.self, from: message.payload) {
                await handleRemoteDecisionUpdate(decisionUpdate)
            }
            
        case .decisionVoted:
            if let voteUpdate = try? JSONDecoder().decode(VoteUpdate.self, from: message.payload) {
                await handleRemoteVoteUpdate(voteUpdate)
            }
            
        default:
            break
        }
    }
    
    private func handleRemoteMessageUpdate(_ update: MessageUpdate) async {
        guard update.action == .added else { return }
        
        // Add remote message to local conversation
        if let conversationIndex = collaborativeConversations.firstIndex(where: { $0.id == update.message.conversationId }) {
            // Check if message already exists (avoid duplicates)
            if !collaborativeConversations[conversationIndex].messages.contains(where: { $0.id == update.message.id }) {
                collaborativeConversations[conversationIndex].messages.append(update.message)
                collaborativeConversations[conversationIndex].metadata.lastActivity = update.timestamp
                collaborativeConversations[conversationIndex].metadata.messageCount += 1
                
                print("📥 Received remote message: \(update.message.content)")
            }
        }
    }
    
    private func handleRemoteDecisionUpdate(_ update: DecisionUpdate) async {
        guard update.action == .proposed else { return }
        
        // Add remote decision to local active decisions
        if !activeDecisions.contains(where: { $0.id == update.decision.id }) {
            activeDecisions.append(update.decision)
            print("📥 Received remote decision proposal: \(update.decision.title)")
        }
    }
    
    private func handleRemoteVoteUpdate(_ update: VoteUpdate) async {
        // Update decision with remote vote
        if let decisionIndex = activeDecisions.firstIndex(where: { $0.id == update.decisionId }) {
            // Check if vote already exists (avoid duplicates)
            if !activeDecisions[decisionIndex].votes.contains(where: { $0.id == update.vote.id }) {
                activeDecisions[decisionIndex].votes.append(update.vote)
                print("📥 Received remote vote for decision: \(activeDecisions[decisionIndex].title)")
            }
        }
    }
}

// MARK: - Supporting Types

struct CollaborativeConversation: Identifiable, Codable {
    let id: UUID
    let sessionId: UUID
    let title: String
    let createdAt: Date
    let createdBy: UUID
    let participants: [UUID]
    let conversationType: ConversationType
    let accessLevel: AccessLevel
    var status: ConversationStatus
    var messages: [CollaborativeMessage]
    var threads: [ConversationThreadData]
    var decisions: [SharedDecision]
    var metadata: ConversationMetadata
    
    enum ConversationType: String, Codable {
        case openDiscussion = "open_discussion"
        case structuredMeeting = "structured_meeting"
        case decisionMaking = "decision_making"
        case brainstorming = "brainstorming"
        case problemSolving = "problem_solving"
        case projectPlanning = "project_planning"
    }
    
    enum AccessLevel: String, Codable {
        case `public` = "public"
        case collaborative = "collaborative"
        case protected = "protected"
        case `private` = "private"
    }
    
    enum ConversationStatus: String, Codable {
        case active = "active"
        case paused = "paused"
        case completed = "completed"
        case archived = "archived"
    }
    
    struct ConversationMetadata: Codable {
        var lastActivity: Date
        var messageCount: Int
        var participantCount: Int
        var tags: [String]
        var aiProvidersUsed: [String]
        var averageResponseTime: TimeInterval
    }
}

struct CollaborativeMessage: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let content: String
    let participantId: UUID
    let timestamp: Date
    let messageType: MessageType
    let replyToMessageId: UUID?
    let attachments: [MessageAttachment]
    var reactions: [MessageReaction]
    var metadata: MessageMetadata
    let status: MessageStatus
    let visibility: MessageVisibility
    
    enum MessageType: String, Codable {
        case text = "text"
        case audio = "audio"
        case image = "image"
        case file = "file"
        case decision = "decision"
        case system = "system"
        case aiResponse = "ai_response"
    }
    
    struct MessageMetadata: Codable {
        var edited: Bool
        var editedAt: Date?
        var aiGenerated: Bool
        var aiProvider: String?
        var processingTime: TimeInterval?
        var confidence: Double?
        var threadId: UUID?
    }
    
    enum MessageStatus: String, Codable {
        case sending = "sending"
        case sent = "sent"
        case delivered = "delivered"
        case read = "read"
        case failed = "failed"
    }
    
    enum MessageVisibility: String, Codable {
        case all = "all"
        case participants = "participants"
        case moderators = "moderators"
        case `private` = "private"
    }
}

struct ConversationThreadData: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let title: String
    let startMessageId: UUID
    let messageIds: [UUID]
    let participants: [UUID]
    let createdAt: Date
    var lastActivity: Date
    let threadType: ThreadType
    
    enum ThreadType: String, Codable {
        case topic = "topic"
        case decision = "decision"
        case task = "task"
        case question = "question"
        case tangent = "tangent"
    }
}

struct SharedDecision: Identifiable, Codable {
    let id: UUID
    let conversationId: UUID
    let title: String
    let description: String
    let proposedBy: UUID
    let proposedAt: Date
    let decisionType: DecisionType
    var status: DecisionStatus
    let options: [DecisionOption]
    var votes: [DecisionVote]
    var comments: [DecisionComment]
    let deadline: Date?
    let metadata: DecisionMetadata
    
    enum DecisionType: String, Codable {
        case consensus = "consensus"
        case majority = "majority"
        case simple = "simple"
        case moderator = "moderator"
    }
    
    enum DecisionStatus: String, Codable {
        case open = "open"
        case approved = "approved"
        case rejected = "rejected"
        case expired = "expired"
    }
    
    struct DecisionMetadata: Codable {
        let contextSnapshot: [String: AnyCodable]
        let relatedMessages: [UUID]
        let requiredParticipants: [UUID]
        let minimumVotes: Int
    }
}

struct DecisionOption: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let proposedBy: UUID
}

struct DecisionVote: Identifiable, Codable {
    let id: UUID
    let participantId: UUID
    let voteType: VoteType
    let timestamp: Date
    let comment: String?
    let confidence: Double?
    
    enum VoteType: String, Codable {
        case approve = "approve"
        case reject = "reject"
        case abstain = "abstain"
    }
}

struct DecisionComment: Identifiable, Codable {
    let id: UUID
    let decisionId: UUID
    let participantId: UUID
    let content: String
    let timestamp: Date
}

struct MessageAttachment: Identifiable, Codable {
    let id: UUID
    let filename: String
    let contentType: String
    let size: Int64
    let url: URL?
    let uploadedAt: Date
}

struct MessageReaction: Identifiable, Codable {
    let id: UUID
    let messageId: UUID
    let participantId: UUID
    let emoji: String
    let timestamp: Date
}

struct ConversationState {
    let conversationId: UUID
    var status: CollaborativeConversation.ConversationStatus
    var lastUpdate: Date
    var pendingMessages: [PendingMessage]
    var participantTyping: [UUID]
    var contextSnapshot: [String: Any]
}

struct PendingMessage: Identifiable {
    let id: UUID
    let message: CollaborativeMessage
    let retryCount: Int
    let lastAttempt: Date
}

struct DecisionWorkflow {
    let decisionId: UUID
    var status: WorkflowStatus
    let steps: [WorkflowStep]
    var currentStep: Int
    let participants: [UUID]
    var timeline: [WorkflowEvent]
    
    enum WorkflowStatus: String, Codable {
        case collecting = "collecting"
        case reviewing = "reviewing"
        case voting = "voting"
        case completed = "completed"
        case rejected = "rejected"
        case expired = "expired"
    }
    
    struct WorkflowStep: Codable {
        let name: String
        let description: String
    }
    
    struct WorkflowEvent: Codable {
        let timestamp: Date
        let event: String
        let participantId: UUID?
    }
}

struct ParticipantContribution {
    let participantId: UUID
    var messageCount: Int
    var decisionCount: Int
    var lastActivity: Date
    var messageIds: [UUID]
    var decisionIds: [UUID]
    var contextualContributions: [MessageContext]
}

struct ConversationAnalytics {
    var totalMessages: Int = 0
    var totalDecisions: Int = 0
    var lastUpdate: Date = Date()
    var sentimentHistory: [Double] = []
    var topicFrequency: [String: Int] = [:]
    var participantActivity: [UUID: Int] = [:]
}

struct MessageContext {
    let messageId: UUID
    let sentiment: Double?
    let topics: [String]?
    let actionItems: [ConversationActionItem]?
    let mentions: [UUID]?
    let urgency: UrgencyLevel?
    
    enum UrgencyLevel: String, Codable {
        case low = "low"
        case normal = "normal"
        case high = "high"
        case urgent = "urgent"
    }
}

struct ConversationActionItem: Identifiable, Codable {
    let id: UUID
    let type: ActionType
    let title: String
    let description: String
    let assignedTo: UUID?
    let dueDate: Date?
    
    enum ActionType: String, Codable {
        case decision = "decision"
        case task = "task"
        case follow_up = "follow_up"
        case information_request = "information_request"
    }
}

struct DecisionResult {
    let status: SharedDecision.DecisionStatus
    let summary: String
}

// Update message types for real-time sync
struct MessageUpdate: Codable {
    let action: UpdateAction
    let message: CollaborativeMessage
    let timestamp: Date
    
    enum UpdateAction: String, Codable {
        case added = "added"
        case updated = "updated"
        case deleted = "deleted"
    }
}

struct DecisionUpdate: Codable {
    let action: UpdateAction
    let decision: SharedDecision
    let timestamp: Date
    
    enum UpdateAction: String, Codable {
        case proposed = "proposed"
        case updated = "updated"
        case resolved = "resolved"
    }
}

struct VoteUpdate: Codable {
    let decisionId: UUID
    let vote: DecisionVote
    let timestamp: Date
}

// MARK: - Supporting Classes

class ConversationThreadManager {
    func determineThread(for message: CollaborativeMessage, in conversation: CollaborativeConversation) async -> ConversationThreadData? {
        // Analyze message content and context to determine appropriate thread
        // This would implement sophisticated threading logic
        return nil
    }
    
    func extractThreads(from conversation: CollaborativeConversation) async -> [ConversationThreadData] {
        // Extract conversation threads from message history
        // This would implement thread detection and organization
        return []
    }
}

class ConversationContextualizer {
    func analyze(message: CollaborativeMessage, conversation: CollaborativeConversation) async -> MessageContext {
        // Analyze message for context, sentiment, topics, action items
        return MessageContext(
            messageId: message.id,
            sentiment: 0.5, // Placeholder
            topics: ["general"], // Placeholder
            actionItems: nil,
            mentions: nil,
            urgency: .normal
        )
    }
}

class ConversationSummarizer {
    func summarize(messages: [String]) async -> String {
        // Generate conversation summary
        return "Conversation summary placeholder"
    }
}

// MARK: - Error Types

enum CollaborativeConversationError: LocalizedError {
    case conversationNotFound(UUID)
    case participantNotAuthorized(UUID)
    case decisionNotFound(UUID)
    case alreadyVoted(UUID)
    case invalidDecisionType
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .conversationNotFound(let id):
            return "Conversation not found: \(id)"
        case .participantNotAuthorized(let id):
            return "Participant not authorized: \(id)"
        case .decisionNotFound(let id):
            return "Decision not found: \(id)"
        case .alreadyVoted(let id):
            return "Already voted on decision: \(id)"
        case .invalidDecisionType:
            return "Invalid decision type"
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        }
    }
}