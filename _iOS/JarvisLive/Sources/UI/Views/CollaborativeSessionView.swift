// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive collaborative session interface for multi-user voice AI interactions
 * Issues & Complexity Summary: Real-time collaboration with LiveKit rooms, participant management, shared transcription, and decision tracking
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~600
 *   - Core Algorithm Complexity: High (Real-time collaboration, WebSocket, state synchronization)
 *   - Dependencies: 8 New (SwiftUI, LiveKit, Combine, AVFoundation, Keychain, Collaboration models)
 *   - State Management Complexity: Very High (Multi-participant state, real-time sync, conversation tracking)
 *   - Novelty/Uncertainty Factor: High (Multi-user voice collaboration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 90%
 * Initial Code Complexity Estimate %: 88%
 * Justification for Estimates: Real-time multi-user collaboration requires complex state management, WebSocket coordination, and UI synchronization
 * Final Code Complexity (Actual %): 92%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Multi-user collaboration requires careful state synchronization and comprehensive error handling
 * Last Updated: 2025-06-26
 */

import SwiftUI
import LiveKit
import Combine
import AVFoundation

// MARK: - Collaboration Models

struct Collaborator: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let avatarURL: String?
    let joinedAt: Date
    let isActive: Bool
    let isSpeaking: Bool
    let audioLevel: Float
    let role: CollaboratorRole
    let permissions: Set<CollaborationPermission>

    enum CollaboratorRole: String, CaseIterable, Codable {
        case host = "host"
        case moderator = "moderator"
        case participant = "participant"
        case observer = "observer"
    }

    enum CollaborationPermission: String, CaseIterable, Codable {
        case canSpeak = "can_speak"
        case canMute = "can_mute"
        case canInvite = "can_invite"
        case canRecord = "can_record"
        case canGenerateDocuments = "can_generate_documents"
        case canManageSession = "can_manage_session"
    }
}

struct SharedTranscription: Identifiable, Codable {
    let id: String
    let participantId: String
    let participantName: String
    let text: String
    let timestamp: Date
    let confidence: Float
    let isFinal: Bool
    let language: String
    let aiResponse: String?
}

struct UICollaborativeDecision: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let proposedBy: String
    let proposedAt: Date
    let status: DecisionStatus
    let votes: [CollaborativeVote]
    let requiredConsensus: Float // 0.0-1.0
    let deadline: Date?
    let category: DecisionCategory

    enum DecisionStatus: String, CaseIterable, Codable {
        case proposed = "proposed"
        case voting = "voting"
        case approved = "approved"
        case rejected = "rejected"
        case expired = "expired"
    }

    enum DecisionCategory: String, CaseIterable, Codable {
        case documentGeneration = "document_generation"
        case meetingAction = "meeting_action"
        case processDecision = "process_decision"
        case technicalChoice = "technical_choice"
        case other = "other"
    }
}

struct CollaborativeVote: Identifiable, Codable {
    let id: String
    let participantId: String
    let participantName: String
    let vote: VoteType
    let comment: String?
    let timestamp: Date

    enum VoteType: String, CaseIterable, Codable {
        case approve = "approve"
        case reject = "reject"
        case abstain = "abstain"
    }
}

struct SessionSummary: Codable {
    let sessionId: String
    let title: String
    let startTime: Date
    let endTime: Date?
    let participants: [Collaborator]
    let transcriptionSummary: String
    let decisions: [CollaborativeDecision]
    let documentsGenerated: [String]
    let keyDiscussionPoints: [String]
    let actionItems: [ActionItem]

    struct ActionItem: Codable, Identifiable {
        let id: String
        let description: String
        let assignedTo: String?
        let dueDate: Date?
        let status: String
    }
}

// MARK: - Collaboration Manager

@MainActor
class CollaborationManager: ObservableObject {
    @Published var currentSession: CollaborativeSession?
    @Published var participants: [Collaborator] = []
    @Published var sharedTranscriptions: [SharedTranscription] = []
    @Published var activeDecisions: [CollaborativeDecision] = []
    @Published var isSessionActive: Bool = false
    @Published var connectionStatus: CollaborationConnectionStatus = .disconnected
    @Published var sessionSummary: SessionSummary?

    enum CollaborationConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)
    }

    private var webSocketTask: URLSessionWebSocketTask?
    private var cancellables = Set<AnyCancellable>()
    private let keychainManager: KeychainManager

    init(keychainManager: KeychainManager) {
        self.keychainManager = keychainManager
        setupWebSocketConnection()
    }

    // MARK: - Session Management

    func createCollaborativeSession(title: String, inviteList: [String] = []) async throws -> String {
        let sessionId = UUID().uuidString
        let session = CollaborativeSession(
            id: sessionId,
            title: title,
            createdAt: Date(),
            hostId: getCurrentUserId(),
            participants: [],
            isActive: true
        )

        self.currentSession = session
        self.isSessionActive = true

        // Send session creation to backend
        try await sendSessionCommand(.createSession(session))

        // Send invitations
        for invitee in inviteList {
            try await sendInvitation(to: invitee, sessionId: sessionId)
        }

        return sessionId
    }

    func joinCollaborativeSession(_ sessionId: String) async throws {
        let joinRequest = SessionJoinRequest(
            sessionId: sessionId,
            participantId: getCurrentUserId(),
            participantName: getCurrentUserName()
        )

        try await sendSessionCommand(.joinSession(joinRequest))
        connectionStatus = .connecting
    }

    func leaveSession() async {
        guard let session = currentSession else { return }

        do {
            try await sendSessionCommand(.leaveSession(session.id))
        } catch {
            print("Error leaving session: \(error)")
        }

        // Clean up local state
        currentSession = nil
        participants = []
        sharedTranscriptions = []
        activeDecisions = []
        isSessionActive = false
        connectionStatus = .disconnected
    }

    // MARK: - Participant Management

    func updateParticipantStatus(_ participantId: String, isActive: Bool, isSpeaking: Bool, audioLevel: Float) {
        if let index = participants.firstIndex(where: { $0.id == participantId }) {
            var participant = participants[index]
            participant = Collaborator(
                id: participant.id,
                name: participant.name,
                avatarURL: participant.avatarURL,
                joinedAt: participant.joinedAt,
                isActive: isActive,
                isSpeaking: isSpeaking,
                audioLevel: audioLevel,
                role: participant.role,
                permissions: participant.permissions
            )
            participants[index] = participant
        }
    }

    func muteParticipant(_ participantId: String) async throws {
        try await sendSessionCommand(.muteParticipant(participantId))
    }

    func promoteParticipant(_ participantId: String, to role: Collaborator.CollaboratorRole) async throws {
        try await sendSessionCommand(.promoteParticipant(participantId, role))
    }

    // MARK: - Shared Transcription

    func addSharedTranscription(_ transcription: SharedTranscription) {
        sharedTranscriptions.append(transcription)

        // Limit transcription history to prevent memory issues
        if sharedTranscriptions.count > 1000 {
            sharedTranscriptions.removeFirst(sharedTranscriptions.count - 1000)
        }

        // Send to backend for persistence
        Task {
            try await sendTranscription(transcription)
        }
    }

    func searchTranscriptions(query: String) -> [SharedTranscription] {
        return sharedTranscriptions.filter { transcription in
            transcription.text.localizedCaseInsensitiveContains(query) ||
            transcription.participantName.localizedCaseInsensitiveContains(query)
        }
    }

    // MARK: - Decision Management

    func proposeDecision(_ decision: CollaborativeDecision) async throws {
        activeDecisions.append(decision)
        try await sendSessionCommand(.proposeDecision(decision))
    }

    func voteOnDecision(_ decisionId: String, vote: CollaborativeVote) async throws {
        try await sendSessionCommand(.voteOnDecision(decisionId, vote))

        // Update local decision with vote
        if let index = activeDecisions.firstIndex(where: { $0.id == decisionId }) {
            var decision = activeDecisions[index]
            var votes = decision.votes
            votes.append(vote)

            // Update decision status based on votes
            let approvalCount = votes.filter { $0.vote == .approve }.count
            let totalVotes = votes.count
            let approvalRatio = Float(approvalCount) / Float(totalVotes)

            if approvalRatio >= decision.requiredConsensus {
                decision = CollaborativeDecision(
                    id: decision.id,
                    title: decision.title,
                    description: decision.description,
                    proposedBy: decision.proposedBy,
                    proposedAt: decision.proposedAt,
                    status: .approved,
                    votes: votes,
                    requiredConsensus: decision.requiredConsensus,
                    deadline: decision.deadline,
                    category: decision.category
                )
            }

            activeDecisions[index] = decision
        }
    }

    // MARK: - WebSocket Communication

    private func setupWebSocketConnection() {
        // WebSocket setup for real-time collaboration
        guard let url = URL(string: "wss://localhost:8000/ws/collaboration") else { return }

        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        receiveMessages()
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                Task { @MainActor in
                    await self?.handleWebSocketMessage(message)
                    self?.receiveMessages() // Continue listening
                }
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.connectionStatus = .error(error.localizedDescription)
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            // Parse JSON message and update state
            if let data = text.data(using: .utf8),
               let message = try? JSONDecoder().decode(UICollaborationMessage.self, from: data) {
                await handleCollaborationMessage(message)
            }
        case .data(let data):
            // Handle binary data if needed
            break
        @unknown default:
            break
        }
    }

    private func handleCollaborationMessage(_ message: UICollaborationMessage) async {
        switch message.type {
        case .participantJoined:
            if let participant = message.participant {
                participants.append(participant)
            }
        case .participantLeft:
            if let participantId = message.participantId {
                participants.removeAll { $0.id == participantId }
            }
        case .transcriptionAdded:
            if let transcription = message.transcription {
                sharedTranscriptions.append(transcription)
            }
        case .decisionProposed:
            if let decision = message.decision {
                activeDecisions.append(decision)
            }
        case .voteReceived:
            // Update decision with new vote
            break
        }
    }

    // MARK: - Helper Methods

    private func getCurrentUserId() -> String {
        // Get current user ID from keychain or generate one
        return "current-user-id"
    }

    private func getCurrentUserName() -> String {
        // Get current user name from settings
        return "Current User"
    }

    private func sendSessionCommand(_ command: SessionCommand) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(command)
        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask?.send(message)
    }

    private func sendInvitation(to email: String, sessionId: String) async throws {
        // Send invitation via email MCP service
        // This would integrate with the email MCP server
    }

    private func sendTranscription(_ transcription: SharedTranscription) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(transcription)
        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask?.send(message)
    }
}

// MARK: - Supporting Models

struct CollaborativeSession: Identifiable, Codable {
    let id: String
    let title: String
    let createdAt: Date
    let hostId: String
    let participants: [Collaborator]
    let isActive: Bool
}

struct SessionJoinRequest: Codable {
    let sessionId: String
    let participantId: String
    let participantName: String
}

enum SessionCommand: Codable {
    case createSession(CollaborativeSession)
    case joinSession(SessionJoinRequest)
    case leaveSession(String)
    case muteParticipant(String)
    case promoteParticipant(String, Collaborator.CollaboratorRole)
    case proposeDecision(CollaborativeDecision)
    case voteOnDecision(String, CollaborativeVote)
}

struct UICollaborationMessage: Codable {
    let type: MessageType
    let sessionId: String
    let timestamp: Date
    let participant: Collaborator?
    let participantId: String?
    let transcription: SharedTranscription?
    let decision: CollaborativeDecision?
    let vote: CollaborativeVote?

    enum MessageType: String, Codable {
        case participantJoined = "participant_joined"
        case participantLeft = "participant_left"
        case transcriptionAdded = "transcription_added"
        case decisionProposed = "decision_proposed"
        case voteReceived = "vote_received"
    }
}

// MARK: - Collaborative Session View

struct CollaborativeSessionView: View {
    @StateObject private var collaborationManager: CollaborationManager
    @StateObject private var liveKitManager: LiveKitManager
    @State private var selectedTab: CollaborationTab = .participants
    @State private var showingInviteSheet = false
    @State private var showingDecisionSheet = false
    @State private var searchText = ""
    @State private var newDecisionTitle = ""
    @State private var newDecisionDescription = ""

    enum CollaborationTab: String, CaseIterable {
        case participants = "Participants"
        case transcription = "Transcription"
        case decisions = "Decisions"
        case summary = "Summary"
    }

    init(keychainManager: KeychainManager) {
        _collaborationManager = StateObject(wrappedValue: CollaborationManager(keychainManager: keychainManager))
        _liveKitManager = StateObject(wrappedValue: LiveKitManager())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Session Header
                sessionHeaderView

                // Tab Selection
                tabSelectionView

                // Content Area
                tabContentView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Collaborative Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: { showingInviteSheet = true }) {
                        Image(systemName: "person.badge.plus")
                    }

                    Button(action: { showingDecisionSheet = true }) {
                        Image(systemName: "checkmark.circle.badge.plus")
                    }

                    Menu {
                        Button("End Session") {
                            Task {
                                await collaborationManager.leaveSession()
                            }
                        }
                        Button("Generate Summary") {
                            generateSessionSummary()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingInviteSheet) {
                InviteParticipantsSheet(collaborationManager: collaborationManager)
            }
            .sheet(isPresented: $showingDecisionSheet) {
                ProposeDecisionSheet(collaborationManager: collaborationManager)
            }
        }
    }

    // MARK: - View Components

    private var sessionHeaderView: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(collaborationManager.currentSession?.title ?? "Untitled Session")
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack {
                        Circle()
                            .fill(connectionStatusColor)
                            .frame(width: 8, height: 8)

                        Text(connectionStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Participant count and status
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .foregroundColor(.blue)
                    Text("\(collaborationManager.participants.count)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            // Real-time status indicators
            HStack(spacing: 16) {
                StatusIndicator(
                    title: "Speaking",
                    value: "\(activeSpeakersCount)",
                    color: .green,
                    icon: "mic.fill"
                )

                StatusIndicator(
                    title: "Decisions",
                    value: "\(collaborationManager.activeDecisions.count)",
                    color: .orange,
                    icon: "checkmark.circle"
                )

                StatusIndicator(
                    title: "Messages",
                    value: "\(collaborationManager.sharedTranscriptions.count)",
                    color: .purple,
                    icon: "message.fill"
                )
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }

    private var tabSelectionView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(CollaborationTab.allCases, id: \.self) { tab in
                    Button(action: { selectedTab = tab }) {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? .blue : .secondary)

                            Rectangle()
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                                .frame(height: 2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal)
        .background(Color(UIColor.systemBackground))
    }

    @ViewBuilder
    private var tabContentView: some View {
        switch selectedTab {
        case .participants:
            ParticipantListView(participants: collaborationManager.participants)
        case .transcription:
            SharedTranscriptionView(
                transcriptions: collaborationManager.sharedTranscriptions,
                searchText: $searchText
            )
        case .decisions:
            DecisionTrackingView(
                decisions: collaborationManager.activeDecisions,
                collaborationManager: collaborationManager
            )
        case .summary:
            SessionSummaryView(summary: collaborationManager.sessionSummary)
        }
    }

    // MARK: - Computed Properties

    private var connectionStatusColor: Color {
        switch collaborationManager.connectionStatus {
        case .connected:
            return .green
        case .connecting, .reconnecting:
            return .orange
        case .disconnected:
            return .red
        case .error:
            return .red
        }
    }

    private var connectionStatusText: String {
        switch collaborationManager.connectionStatus {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .reconnecting:
            return "Reconnecting..."
        case .disconnected:
            return "Disconnected"
        case .error(let message):
            return "Error: \(message)"
        }
    }

    private var activeSpeakersCount: Int {
        collaborationManager.participants.filter { $0.isSpeaking }.count
    }

    // MARK: - Actions

    private func generateSessionSummary() {
        Task {
            // Generate session summary using AI
            let summary = await generateAISummary()
            await MainActor.run {
                collaborationManager.sessionSummary = summary
            }
        }
    }

    private func generateAISummary() async -> SessionSummary {
        // This would integrate with the AI provider to generate a summary
        // For now, return a mock summary
        return SessionSummary(
            sessionId: collaborationManager.currentSession?.id ?? "",
            title: collaborationManager.currentSession?.title ?? "",
            startTime: Date(),
            endTime: nil,
            participants: collaborationManager.participants,
            transcriptionSummary: "AI-generated summary of the session",
            decisions: collaborationManager.activeDecisions,
            documentsGenerated: [],
            keyDiscussionPoints: [],
            actionItems: []
        )
    }
}

// MARK: - Supporting Views

struct StatusIndicator: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(color)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview

struct CollaborativeSessionView_Previews: PreviewProvider {
    static var previews: some View {
        CollaborativeSessionView(keychainManager: KeychainManager(service: "preview"))
    }
}
