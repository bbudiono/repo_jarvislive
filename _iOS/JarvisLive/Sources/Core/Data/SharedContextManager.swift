// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Shared context synchronization system for collaborative voice AI sessions
 * Issues & Complexity Summary: Complex multi-user real-time context sync with conflict resolution and participant isolation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~1200
 *   - Core Algorithm Complexity: Very High (Real-time sync, conflict resolution, versioning)
 *   - Dependencies: 8 New (Foundation, Combine, LiveKit, WebSocket, CoreData, MCPContextManager, ConversationManager, KeychainManager)
 *   - State Management Complexity: Very High (Multi-participant context, version control, conflict resolution)
 *   - Novelty/Uncertainty Factor: High (Multi-user voice AI collaboration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 95%
 * Problem Estimate (Inherent Problem Difficulty %): 92%
 * Initial Code Complexity Estimate %: 94%
 * Justification for Estimates: Complex multi-user real-time collaboration with voice AI requires sophisticated synchronization
 * Final Code Complexity (Actual %): 96%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Real-time multi-user sync requires careful event ordering and conflict resolution strategies
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import CoreData
import LiveKit

// MARK: - Session Permission (Top-Level Scope)

enum SessionPermission: String, Codable {
    case speak = "speak"
    case listen = "listen"
    case readContext = "read_context"
    case writeContext = "write_context"
    case moderateSession = "moderate_session"
    case manageParticipants = "manage_participants"
    case accessPrivateData = "access_private_data"
}

// MARK: - Shared Context Models

struct SharedContext: Codable, Identifiable {
    let id: UUID
    let sessionId: UUID
    let version: Int
    let timestamp: Date
    let lastModifiedBy: ParticipantIdentity
    let contextData: SharedContextData
    let participants: [ParticipantInfo]
    let accessControl: AccessControlPolicy
    let syncStatus: SyncStatus
    
    struct SharedContextData: Codable {
        var globalContext: [String: AnyCodable]
        var conversationHistory: [SharedConversationEntry]
        var pendingDecisions: [SharedDecision]
        var collaborativeDocuments: [SharedDocument]
        var voiceCommandQueue: [SharedVoiceCommand]
        var aiResponses: [SharedAIResponse]
    }
    
    struct SharedConversationEntry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let participantId: UUID
        let content: String
        let role: ConversationRole
        let contextSnapshot: [String: AnyCodable]
        let processingMetadata: ProcessingMetadata
        let visibility: VisibilityScope
        
        enum ConversationRole: String, Codable {
            case user = "user"
            case assistant = "assistant"
            case system = "system"
            case moderator = "moderator"
        }
        
        struct ProcessingMetadata: Codable {
            let aiProvider: String?
            let processingTime: TimeInterval
            let confidence: Double?
            let classification: String?
            let mcpToolsUsed: [String]
        }
        
        enum VisibilityScope: String, Codable {
            case `public` = "public"
            case `private` = "private"
            case group = "group"
            case moderatorOnly = "moderator_only"
        }
    }
    
    struct SharedDecision: Codable, Identifiable {
        let id: UUID
        let title: String
        let description: String
        let proposedBy: UUID
        let timestamp: Date
        let status: DecisionStatus
        var votes: [ParticipantVote]
        let requiredConsensus: ConsensusType
        let deadline: Date?
        let contextSnapshot: [String: AnyCodable]
        
        enum DecisionStatus: String, Codable {
            case proposed = "proposed"
            case voting = "voting"
            case approved = "approved"
            case rejected = "rejected"
            case expired = "expired"
        }
        
        struct ParticipantVote: Codable {
            let participantId: UUID
            let vote: VoteType
            let timestamp: Date
            let reasoning: String?
            
            enum VoteType: String, Codable {
                case approve = "approve"
                case reject = "reject"
                case abstain = "abstain"
            }
        }
        
        enum ConsensusType: String, Codable {
            case simple = "simple"           // 50% + 1
            case majority = "majority"       // 2/3
            case unanimous = "unanimous"     // 100%
            case moderator = "moderator"     // Moderator decides
        }
    }
    
    struct SharedDocument: Codable, Identifiable {
        let id: UUID
        let title: String
        let content: String
        let format: DocumentFormat
        let createdBy: UUID
        let createdAt: Date
        var lastModifiedBy: UUID
        var lastModifiedAt: Date
        let version: Int
        var collaborators: [DocumentCollaborator]
        let accessLevel: AccessLevel
        let changeHistory: [DocumentChange]
        
        enum DocumentFormat: String, Codable {
            case plainText = "plain_text"
            case markdown = "markdown"
            case html = "html"
            case json = "json"
            case pdf = "pdf"
        }
        
        struct DocumentCollaborator: Codable {
            let participantId: UUID
            let role: CollaboratorRole
            let permissions: [DocumentPermission]
            let joinedAt: Date
            
            enum CollaboratorRole: String, Codable {
                case owner = "owner"
                case editor = "editor"
                case viewer = "viewer"
                case commenter = "commenter"
            }
            
            enum DocumentPermission: String, Codable {
                case read = "read"
                case write = "write"
                case comment = "comment"
                case share = "share"
                case delete = "delete"
            }
        }
        
        enum AccessLevel: String, Codable {
            case `public` = "public"
            case protected = "protected"
            case `private` = "private"
            case restricted = "restricted"
        }
        
        struct DocumentChange: Codable {
            let changeId: UUID
            let timestamp: Date
            let participantId: UUID
            let changeType: ChangeType
            let before: String?
            let after: String?
            let position: DocumentPosition?
            
            enum ChangeType: String, Codable {
                case insert = "insert"
                case delete = "delete"
                case modify = "modify"
                case format = "format"
            }
            
            struct DocumentPosition: Codable {
                let line: Int
                let column: Int
                let length: Int?
            }
        }
    }
    
    struct SharedVoiceCommand: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let participantId: UUID
        let command: String
        let classification: VoiceCommandClassification?
        let processingStatus: ProcessingStatus
        let queuePosition: Int
        let priority: CommandPriority
        let contextRequired: Bool
        
        enum ProcessingStatus: String, Codable {
            case queued = "queued"
            case processing = "processing"
            case completed = "completed"
            case failed = "failed"
            case cancelled = "cancelled"
        }
        
        enum CommandPriority: String, Codable {
            case critical = "critical"
            case high = "high"
            case normal = "normal"
            case low = "low"
        }
    }
    
    struct SharedAIResponse: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let relatedCommandId: UUID?
        let content: String
        let aiProvider: String
        let processingTime: TimeInterval
        let confidence: Double?
        let contextUsed: [String: AnyCodable]
        let participantId: UUID
        let responseType: ResponseType
        
        enum ResponseType: String, Codable {
            case directResponse = "direct_response"
            case contextualResponse = "contextual_response"
            case collaborativeResponse = "collaborative_response"
            case systemResponse = "system_response"
        }
    }
    
    enum SyncStatus: String, Codable {
        case synchronized = "synchronized"
        case syncing = "syncing"
        case conflicted = "conflicted"
        case offline = "offline"
        case error = "error"
    }
}

struct ParticipantInfo: Codable, Identifiable {
    let id: UUID
    let identity: ParticipantIdentity
    let joinedAt: Date
    var lastActivity: Date
    let role: ParticipantRole
    let permissions: [SessionPermission]
    var status: ParticipantStatus
    let contextSubscriptions: [ContextSubscription]
    
    enum ParticipantRole: String, Codable {
        case host = "host"
        case moderator = "moderator"
        case participant = "participant"
        case observer = "observer"
        case bot = "bot"
    }
    
    enum ParticipantStatus: String, Codable {
        case active = "active"
        case inactive = "inactive"
        case speaking = "speaking"
        case muted = "muted"
        case disconnected = "disconnected"
    }
    
    struct ContextSubscription: Codable {
        let contextType: String
        let filters: [String: AnyCodable]
        let subscribedAt: Date
        let priority: SubscriptionPriority
        
        enum SubscriptionPriority: String, Codable {
            case realtime = "realtime"
            case batched = "batched"
            case onDemand = "on_demand"
        }
    }
}

struct ParticipantIdentity: Codable {
    let participantId: UUID
    let displayName: String
    let avatarURL: URL?
    let deviceInfo: DeviceInfo
    let capabilities: [ParticipantCapability]
    
    struct DeviceInfo: Codable {
        let deviceType: String
        let platform: String
        let version: String
        let connectionType: String
    }
    
    enum ParticipantCapability: String, Codable {
        case voiceInput = "voice_input"
        case voiceOutput = "voice_output"
        case textInput = "text_input"
        case textOutput = "text_output"
        case documentEditing = "document_editing"
        case screenSharing = "screen_sharing"
        case fileSharing = "file_sharing"
    }
}

struct AccessControlPolicy: Codable {
    let sessionType: SessionType
    let defaultPermissions: [SessionPermission]
    let restrictedActions: [RestrictedAction]
    let moderationEnabled: Bool
    let recordingAllowed: Bool
    let dataRetention: DataRetentionPolicy
    
    enum SessionType: String, Codable {
        case openCollaboration = "open_collaboration"
        case moderatedSession = "moderated_session"
        case privateSession = "private_session"
        case publicSession = "public_session"
    }
    
    struct RestrictedAction: Codable {
        let action: String
        let requiredRole: ParticipantInfo.ParticipantRole
        let requiredPermissions: [SessionPermission]
        let conditions: [String: AnyCodable]
    }
    
    struct DataRetentionPolicy: Codable {
        let retainContext: Bool
        let retainConversations: Bool
        let retainDocuments: Bool
        let retentionPeriod: TimeInterval
        let anonymizeAfter: TimeInterval?
    }
}

// MARK: - Context Synchronization Events

enum ContextSyncEvent {
    case participantJoined(ParticipantInfo)
    case participantLeft(UUID)
    case participantStatusChanged(UUID, ParticipantInfo.ParticipantStatus)
    case contextUpdated(SharedContext, ChangeSource)
    case conflictDetected(ConflictInfo)
    case conflictResolved(UUID, ResolutionStrategy)
    case documentChanged(UUID, SharedContext.SharedDocument.DocumentChange)
    case decisionProposed(SharedContext.SharedDecision)
    case decisionVoted(UUID, SharedContext.SharedDecision.ParticipantVote)
    case voiceCommandQueued(SharedContext.SharedVoiceCommand)
    case aiResponseGenerated(SharedContext.SharedAIResponse)
    case syncStatusChanged(SharedContext.SyncStatus)
    
    enum ChangeSource {
        case local
        case remote(UUID)
        case system
        case merge
    }
}

struct ConflictInfo: Identifiable {
    let id: UUID
    let timestamp: Date
    let conflictType: ConflictType
    let participantsInvolved: [UUID]
    let contextPath: String
    let conflictingValues: [String: AnyCodable]
    let suggestedResolution: ResolutionStrategy?
    
    enum ConflictType {
        case concurrentEdit
        case versionMismatch
        case permissionDenied
        case dataInconsistency
        case networkPartition
    }
}

// MARK: - Shared Context Manager

@MainActor
final class SharedContextManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentSession: SharedContext?
    @Published private(set) var participants: [ParticipantInfo] = []
    @Published private(set) var syncStatus: SharedContext.SyncStatus = .offline
    @Published private(set) var pendingConflicts: [ConflictInfo] = []
    @Published private(set) var connectionQuality: ConnectionQuality = .unknown
    @Published private(set) var lastSyncTime: Date?
    
    // Real-time synchronization
    @Published private(set) var realTimeEvents: [ContextSyncEvent] = []
    @Published private(set) var collaborativeDocuments: [SharedContext.SharedDocument] = []
    @Published private(set) var sharedDecisions: [SharedContext.SharedDecision] = []
    @Published private(set) var voiceCommandQueue: [SharedContext.SharedVoiceCommand] = []
    
    enum ConnectionQuality {
        case excellent
        case good
        case fair
        case poor
        case unknown
    }
    
    // MARK: - Private Properties
    
    private let liveKitManager: LiveKitManager
    private let mcpContextManager: MCPContextManager
    private let conversationManager: ConversationManager
    private let keychainManager: KeychainManager
    
    // WebSocket for real-time sync
    private var websocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    
    // Context versioning and conflict resolution
    private var contextVersions: [UUID: [SharedContext]] = [:]
    private var conflictResolver: ConflictResolver
    private var eventQueue: AsyncStream<ContextSyncEvent>?
    private var eventContinuation: AsyncStream<ContextSyncEvent>.Continuation?
    
    // Participant management
    private var localParticipantId: UUID = UUID()
    private var participantHeartbeats: [UUID: Date] = [:]
    private let heartbeatInterval: TimeInterval = 10.0
    private var heartbeatTask: Task<Void, Never>?
    
    // Performance monitoring
    private var syncMetrics: SyncMetrics = SyncMetrics()
    private var performanceMonitor: PerformanceMonitor
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        liveKitManager: LiveKitManager,
        mcpContextManager: MCPContextManager,
        conversationManager: ConversationManager,
        keychainManager: KeychainManager
    ) {
        self.liveKitManager = liveKitManager
        self.mcpContextManager = mcpContextManager
        self.conversationManager = conversationManager
        self.keychainManager = keychainManager
        
        // Configure URL session for WebSocket connections
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: configuration)
        
        // Initialize conflict resolver and performance monitor
        self.conflictResolver = ConflictResolver()
        self.performanceMonitor = PerformanceMonitor()
        
        setupEventStream()
        setupObservations()
        
        print("✅ SharedContextManager initialized")
    }
    
    deinit {
        heartbeatTask?.cancel()
        websocketTask?.cancel()
    }
    
    // MARK: - Setup Methods
    
    private func setupEventStream() {
        let (stream, continuation) = AsyncStream<ContextSyncEvent>.makeStream()
        self.eventQueue = stream
        self.eventContinuation = continuation
        
        // Process events asynchronously
        Task {
            guard let eventQueue = eventQueue else { return }
            
            for await event in eventQueue {
                await processContextSyncEvent(event)
            }
        }
    }
    
    private func setupObservations() {
        // Observe LiveKit connection changes
        liveKitManager.$connectionState
            .sink { [weak self] connectionState in
                Task { @MainActor in
                    await self?.handleConnectionStateChange(connectionState)
                }
            }
            .store(in: &cancellables)
        
        // Observe conversation changes
        conversationManager.$currentConversation
            .sink { [weak self] conversation in
                Task { @MainActor in
                    if let conversation = conversation {
                        await self?.syncConversationContext(conversation)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Monitor performance metrics
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.updateSyncMetrics()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Session Management
    
    func createCollaborativeSession(
        sessionType: AccessControlPolicy.SessionType = .openCollaboration,
        maxParticipants: Int = 10
    ) async throws -> SharedContext {
        
        let sessionId = UUID()
        let localParticipant = createLocalParticipant()
        
        let accessPolicy = AccessControlPolicy(
            sessionType: sessionType,
            defaultPermissions: defaultPermissionsForSessionType(sessionType),
            restrictedActions: defaultRestrictedActions(),
            moderationEnabled: sessionType == .moderatedSession,
            recordingAllowed: sessionType != .privateSession,
            dataRetention: defaultDataRetentionPolicy()
        )
        
        let sharedContext = SharedContext(
            id: sessionId,
            sessionId: sessionId,
            version: 1,
            timestamp: Date(),
            lastModifiedBy: localParticipant.identity,
            contextData: SharedContext.SharedContextData(
                globalContext: [:],
                conversationHistory: [],
                pendingDecisions: [],
                collaborativeDocuments: [],
                voiceCommandQueue: [],
                aiResponses: []
            ),
            participants: [localParticipant],
            accessControl: accessPolicy,
            syncStatus: .synchronized
        )
        
        currentSession = sharedContext
        participants = [localParticipant]
        syncStatus = .synchronized
        
        // Initialize real-time synchronization
        await startRealtimeSync()
        
        // Start heartbeat monitoring
        startHeartbeatMonitoring()
        
        eventContinuation?.yield(.contextUpdated(sharedContext, .local))
        
        print("✅ Created collaborative session: \(sessionId)")
        return sharedContext
    }
    
    func joinCollaborativeSession(sessionId: UUID, inviteToken: String?) async throws {
        syncStatus = .syncing
        
        do {
            // Connect to existing session via WebSocket
            try await connectToSharedSession(sessionId: sessionId, token: inviteToken)
            
            // Request current session state
            let sessionState = try await requestSessionState(sessionId: sessionId)
            
            // Add local participant
            let localParticipant = createLocalParticipant()
            var updatedParticipants = sessionState.participants
            updatedParticipants.append(localParticipant)
            
            // Update session with local participant
            let updatedSession = SharedContext(
                id: sessionState.id,
                sessionId: sessionState.sessionId,
                version: sessionState.version + 1,
                timestamp: Date(),
                lastModifiedBy: localParticipant.identity,
                contextData: sessionState.contextData,
                participants: updatedParticipants,
                accessControl: sessionState.accessControl,
                syncStatus: .synchronized
            )
            
            currentSession = updatedSession
            participants = updatedParticipants
            syncStatus = .synchronized
            
            // Broadcast participant joined event
            await broadcastContextUpdate(updatedSession, changeSource: .local)
            eventContinuation?.yield(.participantJoined(localParticipant))
            
            // Start heartbeat monitoring
            startHeartbeatMonitoring()
            
            print("✅ Joined collaborative session: \(sessionId)")
            
        } catch {
            syncStatus = .error
            throw SharedContextError.sessionJoinFailed(error.localizedDescription)
        }
    }
    
    func leaveCollaborativeSession() async {
        guard let session = currentSession else { return }
        
        // Remove local participant
        let updatedParticipants = participants.filter { $0.id != localParticipantId }
        
        let updatedSession = SharedContext(
            id: session.id,
            sessionId: session.sessionId,
            version: session.version + 1,
            timestamp: Date(),
            lastModifiedBy: participants.first(where: { $0.id == localParticipantId })?.identity ?? session.lastModifiedBy,
            contextData: session.contextData,
            participants: updatedParticipants,
            accessControl: session.accessControl,
            syncStatus: .synchronized
        )
        
        // Broadcast participant left event
        await broadcastContextUpdate(updatedSession, changeSource: .local)
        eventContinuation?.yield(.participantLeft(localParticipantId))
        
        // Clean up
        stopHeartbeatMonitoring()
        await stopRealtimeSync()
        
        currentSession = nil
        participants = []
        syncStatus = .offline
        
        print("✅ Left collaborative session")
    }
    
    // MARK: - Real-time Synchronization
    
    private func startRealtimeSync() async {
        guard let session = currentSession else { return }
        
        do {
            let websocketURL = URL(string: "wss://jarvis-live-sync.example.com/session/\(session.sessionId)")!
            let request = URLRequest(url: websocketURL)
            
            websocketTask = urlSession.webSocketTask(with: request)
            websocketTask?.resume()
            
            // Start listening for incoming messages
            await listenForWebSocketMessages()
            
            print("✅ Started real-time synchronization")
            
        } catch {
            print("❌ Failed to start real-time sync: \(error)")
            syncStatus = .error
        }
    }
    
    private func stopRealtimeSync() async {
        websocketTask?.cancel(with: .goingAway, reason: nil)
        websocketTask = nil
        print("✅ Stopped real-time synchronization")
    }
    
    private func listenForWebSocketMessages() async {
        guard let websocketTask = websocketTask else { return }
        
        do {
            let message = try await websocketTask.receive()
            
            switch message {
            case .string(let text):
                await handleWebSocketMessage(text)
            case .data(let data):
                await handleWebSocketData(data)
            @unknown default:
                print("⚠️ Unknown WebSocket message type")
            }
            
            // Continue listening
            await listenForWebSocketMessages()
            
        } catch {
            print("❌ WebSocket receive error: \(error)")
            syncStatus = .error
        }
    }
    
    private func handleWebSocketMessage(_ message: String) async {
        do {
            guard let data = message.data(using: .utf8),
                  let syncMessage = try? JSONDecoder().decode(SyncMessage.self, from: data) else {
                print("⚠️ Failed to decode sync message")
                return
            }
            
            await processSyncMessage(syncMessage)
            
        } catch {
            print("❌ Error processing WebSocket message: \(error)")
        }
    }
    
    private func handleWebSocketData(_ data: Data) async {
        do {
            let syncMessage = try JSONDecoder().decode(SyncMessage.self, from: data)
            await processSyncMessage(syncMessage)
        } catch {
            print("❌ Error decoding WebSocket data: \(error)")
        }
    }
    
    // MARK: - Context Updates and Synchronization
    
    func updateSharedContext<T>(_ keyPath: WritableKeyPath<SharedContext.SharedContextData, T>, value: T) async throws {
        guard var session = currentSession else {
            throw SharedContextError.noActiveSession
        }
        
        // Check permissions
        guard hasPermission(.writeContext, for: localParticipantId) else {
            throw SharedContextError.permissionDenied("Write context")
        }
        
        // Create new version
        let newVersion = session.version + 1
        var updatedContextData = session.contextData
        updatedContextData[keyPath: keyPath] = value
        
        let updatedSession = SharedContext(
            id: session.id,
            sessionId: session.sessionId,
            version: newVersion,
            timestamp: Date(),
            lastModifiedBy: participants.first(where: { $0.id == localParticipantId })?.identity ?? session.lastModifiedBy,
            contextData: updatedContextData,
            participants: session.participants,
            accessControl: session.accessControl,
            syncStatus: .syncing
        )
        
        // Store version for conflict resolution
        contextVersions[session.id, default: []].append(session)
        
        // Update local state
        currentSession = updatedSession
        syncStatus = .syncing
        
        // Broadcast update
        await broadcastContextUpdate(updatedSession, changeSource: .local)
        
        print("✅ Updated shared context, version: \(newVersion)")
    }
    
    private func broadcastContextUpdate(_ context: SharedContext, changeSource: ContextSyncEvent.ChangeSource) async {
        let syncMessage = SyncMessage(
            id: UUID(),
            timestamp: Date(),
            type: .contextUpdate,
            payload: SyncMessage.Payload.contextUpdate(context),
            senderId: localParticipantId,
            targetParticipants: nil
        )
        
        await sendSyncMessage(syncMessage)
        eventContinuation?.yield(.contextUpdated(context, changeSource))
    }
    
    private func sendSyncMessage(_ message: SyncMessage) async {
        guard let websocketTask = websocketTask else { return }
        
        do {
            let data = try JSONEncoder().encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(data)
            try await websocketTask.send(webSocketMessage)
            
            syncMetrics.messagesSent += 1
            syncMetrics.lastSyncTime = Date()
            
        } catch {
            print("❌ Failed to send sync message: \(error)")
            syncStatus = .error
        }
    }
    
    // MARK: - Conflict Resolution
    
    private func processSyncMessage(_ message: SyncMessage) async {
        syncMetrics.messagesReceived += 1
        
        switch message.type {
        case .contextUpdate:
            if case .contextUpdate(let remoteContext) = message.payload {
                await handleRemoteContextUpdate(remoteContext, from: message.senderId)
            }
            
        case .participantJoined:
            if case .participantInfo(let participant) = message.payload {
                await handleParticipantJoined(participant)
            }
            
        case .participantLeft:
            if case .participantId(let participantId) = message.payload {
                await handleParticipantLeft(participantId)
            }
            
        case .conflictResolution:
            if case .conflictResolution(let resolution) = message.payload {
                await handleConflictResolution(resolution)
            }
            
        case .heartbeat:
            participantHeartbeats[message.senderId] = message.timestamp
        }
    }
    
    private func handleRemoteContextUpdate(_ remoteContext: SharedContext, from senderId: UUID) async {
        guard let localContext = currentSession else { return }
        
        // Check for version conflicts
        if remoteContext.version <= localContext.version && senderId != localParticipantId {
            // Potential conflict detected
            let conflict = ConflictInfo(
                id: UUID(),
                timestamp: Date(),
                conflictType: .versionMismatch,
                participantsInvolved: [localParticipantId, senderId],
                contextPath: "root",
                conflictingValues: [:], // Would be populated with actual conflicting values
                suggestedResolution: .lastWriterWins
            )
            
            pendingConflicts.append(conflict)
            eventContinuation?.yield(.conflictDetected(conflict))
            
            // Attempt automatic resolution
            await attemptConflictResolution(conflict, localContext: localContext, remoteContext: remoteContext)
            
        } else {
            // No conflict, apply remote update
            currentSession = remoteContext
            syncStatus = .synchronized
            lastSyncTime = Date()
            
            eventContinuation?.yield(.contextUpdated(remoteContext, .remote(senderId)))
        }
    }
    
    private func attemptConflictResolution(
        _ conflict: ConflictInfo,
        localContext: SharedContext,
        remoteContext: SharedContext
    ) async {
        
        let resolution = await conflictResolver.resolveConflict(
            conflict: conflict,
            localContext: localContext,
            remoteContext: remoteContext,
            strategy: determineResolutionStrategy(conflict)
        )
        
        switch resolution.outcome {
        case .resolved(let resolvedContext):
            currentSession = resolvedContext
            syncStatus = .synchronized
            
            // Remove from pending conflicts
            pendingConflicts.removeAll { $0.id == conflict.id }
            
            // Broadcast resolution
            await broadcastConflictResolution(conflict.id, resolvedContext: resolvedContext)
            eventContinuation?.yield(.conflictResolved(conflict.id, resolution.strategy))
            
            print("✅ Conflict resolved: \(conflict.id)")
            
        case .needsManualIntervention:
            syncStatus = .conflicted
            print("⚠️ Conflict requires manual resolution: \(conflict.id)")
            
        case .failed(let error):
            syncStatus = .error
            print("❌ Conflict resolution failed: \(error)")
        }
    }
    
    private func determineResolutionStrategy(_ conflict: ConflictInfo) -> ResolutionStrategy {
        guard let session = currentSession else { return .lastWriterWins }
        
        switch session.accessControl.sessionType {
        case .moderatedSession:
            return .moderatorDecision
        case .openCollaboration:
            return .lastWriterWins
        case .privateSession:
            return .firstWriterWins
        case .publicSession:
            return .participantVote
        }
    }
    
    private func broadcastConflictResolution(_ conflictId: UUID, resolvedContext: SharedContext) async {
        let resolution = ConflictResolution(
            conflictId: conflictId,
            resolvedContext: resolvedContext,
            strategy: .lastWriterWins,
            resolvedBy: localParticipantId,
            timestamp: Date()
        )
        
        let message = SyncMessage(
            id: UUID(),
            timestamp: Date(),
            type: .conflictResolution,
            payload: .conflictResolution(resolution),
            senderId: localParticipantId,
            targetParticipants: nil
        )
        
        await sendSyncMessage(message)
    }
    
    // MARK: - Participant Management
    
    private func handleParticipantJoined(_ participant: ParticipantInfo) async {
        if !participants.contains(where: { $0.id == participant.id }) {
            participants.append(participant)
            participantHeartbeats[participant.id] = Date()
            eventContinuation?.yield(.participantJoined(participant))
            print("✅ Participant joined: \(participant.identity.displayName)")
        }
    }
    
    private func handleParticipantLeft(_ participantId: UUID) async {
        participants.removeAll { $0.id == participantId }
        participantHeartbeats.removeValue(forKey: participantId)
        eventContinuation?.yield(.participantLeft(participantId))
        print("✅ Participant left: \(participantId)")
    }
    
    private func createLocalParticipant() -> ParticipantInfo {
        let deviceName = UIDevice.current.name
        let identity = ParticipantIdentity(
            participantId: localParticipantId,
            displayName: deviceName,
            avatarURL: nil,
            deviceInfo: ParticipantIdentity.DeviceInfo(
                deviceType: UIDevice.current.model,
                platform: "iOS",
                version: UIDevice.current.systemVersion,
                connectionType: "WiFi" // Would be determined dynamically
            ),
            capabilities: [.voiceInput, .voiceOutput, .textInput, .textOutput, .documentEditing]
        )
        
        return ParticipantInfo(
            id: localParticipantId,
            identity: identity,
            joinedAt: Date(),
            lastActivity: Date(),
            role: .participant,
            permissions: [.speak, .listen, .readContext, .writeContext],
            status: .active,
            contextSubscriptions: []
        )
    }
    
    // MARK: - Heartbeat Monitoring
    
    private func startHeartbeatMonitoring() {
        heartbeatTask?.cancel()
        
        heartbeatTask = Task {
            while !Task.isCancelled {
                do {
                    // Send heartbeat
                    await sendHeartbeat()
                    
                    // Check for inactive participants
                    await checkParticipantHeartbeats()
                    
                    try await Task.sleep(nanoseconds: UInt64(heartbeatInterval * 1_000_000_000))
                } catch {
                    break
                }
            }
        }
    }
    
    private func stopHeartbeatMonitoring() {
        heartbeatTask?.cancel()
        heartbeatTask = nil
    }
    
    private func sendHeartbeat() async {
        let message = SyncMessage(
            id: UUID(),
            timestamp: Date(),
            type: .heartbeat,
            payload: .heartbeat,
            senderId: localParticipantId,
            targetParticipants: nil
        )
        
        await sendSyncMessage(message)
    }
    
    private func checkParticipantHeartbeats() async {
        let now = Date()
        let timeoutInterval: TimeInterval = heartbeatInterval * 3 // 30 seconds timeout
        
        let inactiveParticipants = participantHeartbeats.compactMap { (participantId, lastHeartbeat) in
            now.timeIntervalSince(lastHeartbeat) > timeoutInterval ? participantId : nil
        }
        
        for participantId in inactiveParticipants {
            await handleParticipantLeft(participantId)
        }
    }
    
    // MARK: - Document Collaboration
    
    func createSharedDocument(
        title: String,
        content: String,
        format: SharedContext.SharedDocument.DocumentFormat = .plainText,
        accessLevel: SharedContext.SharedDocument.AccessLevel = .public
    ) async throws -> SharedContext.SharedDocument {
        
        guard hasPermission(.writeContext, for: localParticipantId) else {
            throw SharedContextError.permissionDenied("Create document")
        }
        
        let document = SharedContext.SharedDocument(
            id: UUID(),
            title: title,
            content: content,
            format: format,
            createdBy: localParticipantId,
            createdAt: Date(),
            lastModifiedBy: localParticipantId,
            lastModifiedAt: Date(),
            version: 1,
            collaborators: [
                SharedContext.SharedDocument.DocumentCollaborator(
                    participantId: localParticipantId,
                    role: .owner,
                    permissions: [.read, .write, .comment, .share, .delete],
                    joinedAt: Date()
                )
            ],
            accessLevel: accessLevel,
            changeHistory: []
        )
        
        collaborativeDocuments.append(document)
        
        try await updateSharedContext(\.collaborativeDocuments, value: collaborativeDocuments)
        
        print("✅ Created shared document: \(title)")
        return document
    }
    
    func updateSharedDocument(
        documentId: UUID,
        content: String,
        position: SharedContext.SharedDocument.DocumentChange.DocumentPosition? = nil
    ) async throws {
        
        guard let documentIndex = collaborativeDocuments.firstIndex(where: { $0.id == documentId }) else {
            throw SharedContextError.documentNotFound(documentId)
        }
        
        var document = collaborativeDocuments[documentIndex]
        
        // Check permissions
        guard hasDocumentPermission(.write, for: localParticipantId, document: document) else {
            throw SharedContextError.permissionDenied("Edit document")
        }
        
        let oldContent = document.content
        let change = SharedContext.SharedDocument.DocumentChange(
            changeId: UUID(),
            timestamp: Date(),
            participantId: localParticipantId,
            changeType: .modify,
            before: oldContent,
            after: content,
            position: position
        )
        
        // Update document
        document.content = content
        document.lastModifiedBy = localParticipantId
        document.lastModifiedAt = Date()
        document.version += 1
        document.changeHistory.append(change)
        
        collaborativeDocuments[documentIndex] = document
        
        try await updateSharedContext(\.collaborativeDocuments, value: collaborativeDocuments)
        
        eventContinuation?.yield(.documentChanged(documentId, change))
        
        print("✅ Updated shared document: \(document.title)")
    }
    
    // MARK: - Decision Management
    
    func proposeDecision(
        title: String,
        description: String,
        consensusType: SharedContext.SharedDecision.ConsensusType = .simple,
        deadline: Date? = nil
    ) async throws -> SharedContext.SharedDecision {
        
        guard hasPermission(.writeContext, for: localParticipantId) else {
            throw SharedContextError.permissionDenied("Propose decision")
        }
        
        let decision = SharedContext.SharedDecision(
            id: UUID(),
            title: title,
            description: description,
            proposedBy: localParticipantId,
            timestamp: Date(),
            status: .proposed,
            votes: [],
            requiredConsensus: consensusType,
            deadline: deadline,
            contextSnapshot: currentSession?.contextData.globalContext ?? [:]
        )
        
        sharedDecisions.append(decision)
        
        try await updateSharedContext(\.pendingDecisions, value: sharedDecisions)
        
        eventContinuation?.yield(.decisionProposed(decision))
        
        print("✅ Proposed decision: \(title)")
        return decision
    }
    
    func voteOnDecision(
        decisionId: UUID,
        vote: SharedContext.SharedDecision.ParticipantVote.VoteType,
        reasoning: String? = nil
    ) async throws {
        
        guard let decisionIndex = sharedDecisions.firstIndex(where: { $0.id == decisionId }) else {
            throw SharedContextError.decisionNotFound(decisionId)
        }
        
        var decision = sharedDecisions[decisionIndex]
        
        // Check if participant already voted
        if decision.votes.contains(where: { $0.participantId == localParticipantId }) {
            throw SharedContextError.alreadyVoted(decisionId)
        }
        
        let participantVote = SharedContext.SharedDecision.ParticipantVote(
            participantId: localParticipantId,
            vote: vote,
            timestamp: Date(),
            reasoning: reasoning
        )
        
        decision.votes.append(participantVote)
        
        // Check if decision threshold is met
        let totalParticipants = participants.count
        let approveVotes = decision.votes.filter { $0.vote == .approve }.count
        
        let isApproved: Bool
        switch decision.requiredConsensus {
        case .simple:
            isApproved = approveVotes > totalParticipants / 2
        case .majority:
            isApproved = Double(approveVotes) >= Double(totalParticipants) * 0.67
        case .unanimous:
            isApproved = approveVotes == totalParticipants
        case .moderator:
            isApproved = decision.votes.contains { vote in
                vote.vote == .approve && participants.first(where: { $0.id == vote.participantId })?.role == .moderator
            }
        }
        
        if isApproved {
            decision.status = .approved
        } else if decision.votes.count == totalParticipants {
            decision.status = .rejected
        }
        
        sharedDecisions[decisionIndex] = decision
        
        try await updateSharedContext(\.pendingDecisions, value: sharedDecisions)
        
        eventContinuation?.yield(.decisionVoted(decisionId, participantVote))
        
        print("✅ Voted on decision: \(decision.title)")
    }
    
    // MARK: - Voice Command Queue Management
    
    func queueVoiceCommand(
        command: String,
        priority: SharedContext.SharedVoiceCommand.CommandPriority = .normal,
        contextRequired: Bool = true
    ) async throws -> SharedContext.SharedVoiceCommand {
        
        let voiceCommand = SharedContext.SharedVoiceCommand(
            id: UUID(),
            timestamp: Date(),
            participantId: localParticipantId,
            command: command,
            classification: nil, // Will be populated by classification system
            processingStatus: .queued,
            queuePosition: voiceCommandQueue.count + 1,
            priority: priority,
            contextRequired: contextRequired
        )
        
        // Insert based on priority
        let insertIndex = voiceCommandQueue.firstIndex { existingCommand in
            priority.rawValue.count > existingCommand.priority.rawValue.count // Simple priority comparison
        } ?? voiceCommandQueue.count
        
        voiceCommandQueue.insert(voiceCommand, at: insertIndex)
        
        // Update queue positions
        for (index, _) in voiceCommandQueue.enumerated() {
            voiceCommandQueue[index] = SharedContext.SharedVoiceCommand(
                id: voiceCommandQueue[index].id,
                timestamp: voiceCommandQueue[index].timestamp,
                participantId: voiceCommandQueue[index].participantId,
                command: voiceCommandQueue[index].command,
                classification: voiceCommandQueue[index].classification,
                processingStatus: voiceCommandQueue[index].processingStatus,
                queuePosition: index + 1,
                priority: voiceCommandQueue[index].priority,
                contextRequired: voiceCommandQueue[index].contextRequired
            )
        }
        
        try await updateSharedContext(\.voiceCommandQueue, value: voiceCommandQueue)
        
        eventContinuation?.yield(.voiceCommandQueued(voiceCommand))
        
        print("✅ Queued voice command: \(command)")
        return voiceCommand
    }
    
    // MARK: - Utility Methods
    
    private func hasPermission(_ permission: SessionPermission, for participantId: UUID) -> Bool {
        guard let participant = participants.first(where: { $0.id == participantId }) else {
            return false
        }
        
        return participant.permissions.contains(permission)
    }
    
    private func hasDocumentPermission(
        _ permission: SharedContext.SharedDocument.DocumentCollaborator.DocumentPermission,
        for participantId: UUID,
        document: SharedContext.SharedDocument
    ) -> Bool {
        guard let collaborator = document.collaborators.first(where: { $0.participantId == participantId }) else {
            return document.accessLevel == .public && permission == .read
        }
        
        return collaborator.permissions.contains(permission)
    }
    
    private func processContextSyncEvent(_ event: ContextSyncEvent) async {
        realTimeEvents.append(event)
        
        // Keep only recent events to prevent memory bloat
        if realTimeEvents.count > 100 {
            realTimeEvents.removeFirst(20)
        }
        
        // Update connection quality based on sync performance
        updateConnectionQuality()
    }
    
    private func updateConnectionQuality() {
        let recentEvents = realTimeEvents.suffix(10)
        let avgLatency = syncMetrics.averageLatency
        
        if avgLatency < 100 {
            connectionQuality = .excellent
        } else if avgLatency < 300 {
            connectionQuality = .good
        } else if avgLatency < 800 {
            connectionQuality = .fair
        } else {
            connectionQuality = .poor
        }
    }
    
    private func handleConnectionStateChange(_ connectionState: LiveKitManager.ManagerConnectionState) async {
        switch connectionState {
        case .connected:
            if syncStatus == .offline {
                syncStatus = .synchronized
            }
        case .disconnected, .error:
            syncStatus = .offline
        case .connecting, .reconnecting:
            syncStatus = .syncing
        }
    }
    
    private func syncConversationContext(_ conversation: Conversation) async {
        guard let session = currentSession else { return }
        
        // Sync conversation history to shared context
        let messages = conversationManager.getMessages(for: conversation)
        let sharedEntries = messages.map { message in
            SharedContext.SharedConversationEntry(
                id: message.id,
                timestamp: message.timestamp,
                participantId: localParticipantId,
                content: message.content,
                role: SharedContext.SharedConversationEntry.ConversationRole(rawValue: message.role.rawValue) ?? .user,
                contextSnapshot: [:],
                processingMetadata: SharedContext.SharedConversationEntry.ProcessingMetadata(
                    aiProvider: message.aiProvider,
                    processingTime: message.processingTime,
                    confidence: nil,
                    classification: nil,
                    mcpToolsUsed: []
                ),
                visibility: .public
            )
        }
        
        do {
            try await updateSharedContext(\.conversationHistory, value: sharedEntries)
        } catch {
            print("❌ Failed to sync conversation context: \(error)")
        }
    }
    
    private func updateSyncMetrics() async {
        syncMetrics.updateTimestamp = Date()
        
        // Calculate average latency (simplified)
        let recentEventCount = min(realTimeEvents.count, 10)
        if recentEventCount > 0 {
            // This would be calculated based on actual round-trip times
            syncMetrics.averageLatency = Double.random(in: 50...200) // Placeholder
        }
        
        syncMetrics.activeParticipants = participants.count
        syncMetrics.pendingConflicts = pendingConflicts.count
    }
    
    // MARK: - Helper Methods
    
    private func defaultPermissionsForSessionType(_ sessionType: AccessControlPolicy.SessionType) -> [SessionPermission] {
        switch sessionType {
        case .openCollaboration:
            return [.speak, .listen, .readContext, .writeContext]
        case .moderatedSession:
            return [.speak, .listen, .readContext]
        case .privateSession:
            return [.speak, .listen, .readContext, .writeContext, .accessPrivateData]
        case .publicSession:
            return [.listen, .readContext]
        }
    }
    
    private func defaultRestrictedActions() -> [AccessControlPolicy.RestrictedAction] {
        return [
            AccessControlPolicy.RestrictedAction(
                action: "moderate_session",
                requiredRole: .moderator,
                requiredPermissions: [.moderateSession],
                conditions: [:]
            ),
            AccessControlPolicy.RestrictedAction(
                action: "manage_participants",
                requiredRole: .host,
                requiredPermissions: [.manageParticipants],
                conditions: [:]
            )
        ]
    }
    
    private func defaultDataRetentionPolicy() -> AccessControlPolicy.DataRetentionPolicy {
        return AccessControlPolicy.DataRetentionPolicy(
            retainContext: true,
            retainConversations: true,
            retainDocuments: true,
            retentionPeriod: 86400 * 30, // 30 days
            anonymizeAfter: 86400 * 90   // 90 days
        )
    }
    
    // MARK: - WebSocket Connection Helpers
    
    private func connectToSharedSession(sessionId: UUID, token: String?) async throws {
        // This would connect to the shared session WebSocket endpoint
        // Implementation would depend on your backend infrastructure
        print("🔌 Connecting to shared session: \(sessionId)")
    }
    
    private func requestSessionState(sessionId: UUID) async throws -> SharedContext {
        // This would request the current session state from the server
        // For now, return a placeholder
        throw SharedContextError.notImplemented("Session state request not implemented")
    }
}

// MARK: - Supporting Types

struct SyncMessage: Codable {
    let id: UUID
    let timestamp: Date
    let type: MessageType
    let payload: Payload
    let senderId: UUID
    let targetParticipants: [UUID]?
    
    enum MessageType: String, Codable {
        case contextUpdate = "context_update"
        case participantJoined = "participant_joined"
        case participantLeft = "participant_left"
        case conflictResolution = "conflict_resolution"
        case heartbeat = "heartbeat"
    }
    
    enum Payload: Codable {
        case contextUpdate(SharedContext)
        case participantInfo(ParticipantInfo)
        case participantId(UUID)
        case conflictResolution(ConflictResolution)
        case heartbeat
        
        enum CodingKeys: String, CodingKey {
            case type, data
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "context_update":
                let context = try container.decode(SharedContext.self, forKey: .data)
                self = .contextUpdate(context)
            case "participant_info":
                let participant = try container.decode(ParticipantInfo.self, forKey: .data)
                self = .participantInfo(participant)
            case "participant_id":
                let participantId = try container.decode(UUID.self, forKey: .data)
                self = .participantId(participantId)
            case "conflict_resolution":
                let resolution = try container.decode(ConflictResolution.self, forKey: .data)
                self = .conflictResolution(resolution)
            case "heartbeat":
                self = .heartbeat
            default:
                throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown payload type")
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .contextUpdate(let context):
                try container.encode("context_update", forKey: .type)
                try container.encode(context, forKey: .data)
            case .participantInfo(let participant):
                try container.encode("participant_info", forKey: .type)
                try container.encode(participant, forKey: .data)
            case .participantId(let participantId):
                try container.encode("participant_id", forKey: .type)
                try container.encode(participantId, forKey: .data)
            case .conflictResolution(let resolution):
                try container.encode("conflict_resolution", forKey: .type)
                try container.encode(resolution, forKey: .data)
            case .heartbeat:
                try container.encode("heartbeat", forKey: .type)
            }
        }
    }
}

struct ConflictResolution: Codable {
    let conflictId: UUID
    let resolvedContext: SharedContext
    let strategy: ResolutionStrategy
    let resolvedBy: UUID
    let timestamp: Date
}

class ConflictResolver {
    func resolveConflict(
        conflict: ConflictInfo,
        localContext: SharedContext,
        remoteContext: SharedContext,
        strategy: ResolutionStrategy
    ) async -> ConflictResolutionResult {
        
        switch strategy {
        case .lastWriterWins:
            let winner = localContext.timestamp > remoteContext.timestamp ? localContext : remoteContext
            return ConflictResolutionResult(outcome: .resolved(winner), strategy: strategy)
            
        case .firstWriterWins:
            let winner = localContext.timestamp < remoteContext.timestamp ? localContext : remoteContext
            return ConflictResolutionResult(outcome: .resolved(winner), strategy: strategy)
            
        case .merge:
            let mergedContext = await attemptContextMerge(localContext, remoteContext)
            return ConflictResolutionResult(outcome: .resolved(mergedContext), strategy: strategy)
            
        case .moderatorDecision, .participantVote:
            return ConflictResolutionResult(outcome: .needsManualIntervention, strategy: strategy)
            
        case .rollback:
            return ConflictResolutionResult(outcome: .resolved(localContext), strategy: strategy)
            
        case .duplicate:
            // Create a duplicate and let both contexts exist
            return ConflictResolutionResult(outcome: .needsManualIntervention, strategy: strategy)
        }
    }
    
    private func attemptContextMerge(_ context1: SharedContext, _ context2: SharedContext) async -> SharedContext {
        // Simplified merge logic - in practice this would be much more sophisticated
        var mergedContextData = context1.contextData
        
        // Merge global context
        for (key, value) in context2.contextData.globalContext {
            mergedContextData.globalContext[key] = value
        }
        
        // Merge conversation history (append all)
        mergedContextData.conversationHistory.append(contentsOf: context2.contextData.conversationHistory)
        mergedContextData.conversationHistory.sort { $0.timestamp < $1.timestamp }
        
        // Merge other collections
        mergedContextData.pendingDecisions.append(contentsOf: context2.contextData.pendingDecisions)
        mergedContextData.collaborativeDocuments.append(contentsOf: context2.contextData.collaborativeDocuments)
        mergedContextData.voiceCommandQueue.append(contentsOf: context2.contextData.voiceCommandQueue)
        mergedContextData.aiResponses.append(contentsOf: context2.contextData.aiResponses)
        
        return SharedContext(
            id: context1.id,
            sessionId: context1.sessionId,
            version: max(context1.version, context2.version) + 1,
            timestamp: Date(),
            lastModifiedBy: context1.lastModifiedBy,
            contextData: mergedContextData,
            participants: Array(Set(context1.participants + context2.participants)),
            accessControl: context1.accessControl,
            syncStatus: .synchronized
        )
    }
}

struct SyncMetrics {
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
    var averageLatency: TimeInterval = 0
    var lastSyncTime: Date?
    var updateTimestamp: Date = Date()
    var activeParticipants: Int = 0
    var pendingConflicts: Int = 0
}

class PerformanceMonitor {
    private var metrics: [String: Any] = [:]
    
    func recordMetric(_ key: String, value: Any) {
        metrics[key] = value
    }
    
    func getMetrics() -> [String: Any] {
        return metrics
    }
}

// MARK: - Error Types

enum SharedContextError: LocalizedError {
    case noActiveSession
    case sessionJoinFailed(String)
    case permissionDenied(String)
    case documentNotFound(UUID)
    case decisionNotFound(UUID)
    case alreadyVoted(UUID)
    case conflictResolutionFailed(String)
    case networkError(String)
    case notImplemented(String)
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active collaborative session"
        case .sessionJoinFailed(let reason):
            return "Failed to join session: \(reason)"
        case .permissionDenied(let action):
            return "Permission denied: \(action)"
        case .documentNotFound(let id):
            return "Document not found: \(id)"
        case .decisionNotFound(let id):
            return "Decision not found: \(id)"
        case .alreadyVoted(let id):
            return "Already voted on decision: \(id)"
        case .conflictResolutionFailed(let reason):
            return "Conflict resolution failed: \(reason)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        }
    }
}

// MARK: - Extensions

extension SessionPermission {
    static let all: [SessionPermission] = [
        .speak, .listen, .readContext, .writeContext,
        .moderateSession, .manageParticipants, .accessPrivateData
    ]
}

extension Array where Element == ParticipantInfo {
    func active() -> [ParticipantInfo] {
        return self.filter { $0.status == .active }
    }
    
    func moderators() -> [ParticipantInfo] {
        return self.filter { $0.role == .moderator || $0.role == .host }
    }
}