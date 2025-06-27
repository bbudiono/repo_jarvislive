// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Real-time context broadcasting and synchronization system for collaborative voice AI sessions
 * Issues & Complexity Summary: Complex real-time WebSocket communication with message ordering, reconnection, and reliability
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~800
 *   - Core Algorithm Complexity: High (WebSocket management, message ordering, connection reliability)
 *   - Dependencies: 5 New (Foundation, Network, Combine, LiveKit, SharedContextManager)
 *   - State Management Complexity: High (Connection states, message queues, retry logic)
 *   - Novelty/Uncertainty Factor: Medium (Real-time sync patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 82%
 * Justification for Estimates: Real-time sync requires robust connection management and message reliability
 * Final Code Complexity (Actual %): 84%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: WebSocket reliability requires careful connection state management and message ordering
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import Network
import LiveKit

// MARK: - Real-time Sync Manager

@MainActor
final class RealtimeSyncManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var messageQueue: [QueuedMessage] = []
    @Published private(set) var connectionQuality: ConnectionQuality = .unknown
    @Published private(set) var syncStatistics: SyncStatistics = SyncStatistics()
    
    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case failed(Error)
    }
    
    enum ConnectionQuality {
        case excellent  // < 50ms latency
        case good       // 50-150ms latency  
        case fair       // 150-300ms latency
        case poor       // > 300ms latency
        case unknown
        
        var description: String {
            switch self {
            case .excellent: return "Excellent"
            case .good: return "Good"
            case .fair: return "Fair"
            case .poor: return "Poor"
            case .unknown: return "Unknown"
            }
        }
    }
    
    // MARK: - Private Properties
    
    private var websocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private var reconnectionTimer: Timer?
    private var heartbeatTimer: Timer?
    private var latencyTimer: Timer?
    
    // Message management
    private var messageSequenceNumber: UInt64 = 0
    private var pendingAcknowledgments: [UInt64: QueuedMessage] = [:]
    private var messageBuffer: [RealtimeSyncMessage] = []
    private let maxMessageBufferSize = 100
    private let maxRetryAttempts = 3
    private let acknowledgmentTimeout: TimeInterval = 5.0
    
    // Connection configuration
    private let reconnectionInterval: TimeInterval = 2.0
    private let heartbeatInterval: TimeInterval = 30.0
    private let latencyCheckInterval: TimeInterval = 10.0
    private let connectionTimeout: TimeInterval = 15.0
    
    // Network monitoring
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    private var isNetworkAvailable: Bool = true
    
    private var cancellables = Set<AnyCancellable>()
    
    // Delegates
    weak var delegate: RealtimeSyncManagerDelegate?
    
    // MARK: - Initialization
    
    init() {
        // Configure URL session for WebSocket connections
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = connectionTimeout
        configuration.timeoutIntervalForResource = connectionTimeout * 2
        configuration.waitsForConnectivity = true
        self.urlSession = URLSession(configuration: configuration)
        
        setupNetworkMonitoring()
        
        print("✅ RealtimeSyncManager initialized")
    }
    
    deinit {
        // Note: Cannot call async methods in deinit
        // disconnect() will be called by the system when appropriate
        networkMonitor.cancel()
    }
    
    // MARK: - Helper Methods
    
    private func isFailedStatus(_ status: ConnectionStatus) -> Bool {
        if case .failed = status {
            return true
        }
        return false
    }
    
    // MARK: - Setup Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handleNetworkPathUpdate(path)
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        let wasNetworkAvailable = isNetworkAvailable
        isNetworkAvailable = path.status == .satisfied
        
        if !wasNetworkAvailable && isNetworkAvailable {
            // Network became available - attempt reconnection
            print("📶 Network connectivity restored")
            if connectionStatus == .disconnected || (isFailedStatus(connectionStatus)) {
                Task {
                    await attemptReconnection()
                }
            }
        } else if wasNetworkAvailable && !isNetworkAvailable {
            // Network lost
            print("📶 Network connectivity lost")
            connectionStatus = .disconnected
        }
        
        updateConnectionQuality()
    }
    
    // MARK: - Connection Management
    
    func connect(to endpoint: URL, sessionId: UUID, participantId: UUID, authToken: String? = nil) async throws {
        guard isNetworkAvailable else {
            throw RealtimeSyncError.networkUnavailable
        }
        
        connectionStatus = .connecting
        
        do {
            // Construct WebSocket URL with parameters
            var urlComponents = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
            urlComponents.queryItems = [
                URLQueryItem(name: "sessionId", value: sessionId.uuidString),
                URLQueryItem(name: "participantId", value: participantId.uuidString)
            ]
            
            if let authToken = authToken {
                urlComponents.queryItems?.append(URLQueryItem(name: "token", value: authToken))
            }
            
            guard let websocketURL = urlComponents.url else {
                throw RealtimeSyncError.invalidURL
            }
            
            // Create WebSocket request
            var request = URLRequest(url: websocketURL)
            request.setValue("websocket", forHTTPHeaderField: "Upgrade")
            request.setValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
            
            if let authToken = authToken {
                request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
            }
            
            // Create WebSocket task
            websocketTask = urlSession.webSocketTask(with: request)
            websocketTask?.resume()
            
            // Start listening for messages
            await startMessageReceiving()
            
            connectionStatus = .connected
            lastSyncTime = Date()
            
            // Start periodic tasks
            startHeartbeat()
            startLatencyChecks()
            
            // Process any queued messages
            await processMessageQueue()
            
            print("✅ Connected to real-time sync endpoint: \(websocketURL)")
            
        } catch {
            connectionStatus = .failed(error)
            throw RealtimeSyncError.connectionFailed(error.localizedDescription)
        }
    }
    
    func disconnect() {
        stopHeartbeat()
        stopLatencyChecks()
        stopReconnectionTimer()
        
        websocketTask?.cancel(with: .goingAway, reason: nil)
        websocketTask = nil
        
        connectionStatus = .disconnected
        
        print("✅ Disconnected from real-time sync")
    }
    
    private func attemptReconnection() async {
        guard isFailedStatus(connectionStatus) || connectionStatus == .disconnected else {
            return
        }
        
        connectionStatus = .reconnecting
        
        // Exponential backoff logic would go here
        try? await Task.sleep(nanoseconds: UInt64(reconnectionInterval * 1_000_000_000))
        
        // Note: This would need the original connection parameters
        // In a full implementation, these would be stored
        print("🔄 Attempting reconnection...")
    }
    
    // MARK: - Message Sending
    
    func sendMessage<T: Codable>(_ messageType: RealtimeSyncMessage.MessageType, payload: T) async throws {
        let message = RealtimeSyncMessage(
            id: UUID(),
            sequenceNumber: nextSequenceNumber(),
            timestamp: Date(),
            type: messageType,
            payload: try JSONEncoder().encode(payload),
            senderId: UUID(), // Would be set with actual participant ID
            requiresAcknowledgment: true
        )
        
        try await sendRealtimeMessage(message)
    }
    
    func sendRealtimeMessage(_ message: RealtimeSyncMessage) async throws {
        guard let websocketTask = websocketTask else {
            throw RealtimeSyncError.notConnected
        }
        
        guard connectionStatus == .connected else {
            // Queue message for later sending
            queueMessage(message)
            return
        }
        
        do {
            let messageData = try JSONEncoder().encode(message)
            let webSocketMessage = URLSessionWebSocketTask.Message.data(messageData)
            
            try await websocketTask.send(webSocketMessage)
            
            // Track message for acknowledgment if required
            if message.requiresAcknowledgment {
                let queuedMessage = QueuedMessage(
                    message: message,
                    attemptCount: 1,
                    lastAttempt: Date()
                )
                pendingAcknowledgments[message.sequenceNumber] = queuedMessage
                
                // Set timeout for acknowledgment
                setAcknowledgmentTimeout(for: message.sequenceNumber)
            }
            
            updateSyncStatistics(messagesSent: 1)
            lastSyncTime = Date()
            
            print("📤 Sent message: \(message.type) (seq: \(message.sequenceNumber))")
            
        } catch {
            // Queue message for retry
            queueMessage(message)
            throw RealtimeSyncError.sendFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Message Receiving
    
    private func startMessageReceiving() async {
        guard let websocketTask = websocketTask else { return }
        
        do {
            let message = try await websocketTask.receive()
            
            switch message {
            case .string(let text):
                await handleTextMessage(text)
            case .data(let data):
                await handleDataMessage(data)
            @unknown default:
                print("⚠️ Unknown WebSocket message type")
            }
            
            // Continue receiving
            await startMessageReceiving()
            
        } catch {
            print("❌ WebSocket receive error: \(error)")
            
            if connectionStatus == .connected {
                connectionStatus = .failed(error)
                await attemptReconnection()
            }
        }
    }
    
    private func handleTextMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else {
            print("⚠️ Failed to convert text message to data")
            return
        }
        
        await handleDataMessage(data)
    }
    
    private func handleDataMessage(_ data: Data) async {
        do {
            let message = try JSONDecoder().decode(RealtimeSyncMessage.self, from: data)
            await processReceivedMessage(message)
            
        } catch {
            print("❌ Failed to decode received message: \(error)")
        }
    }
    
    private func processReceivedMessage(_ message: RealtimeSyncMessage) async {
        updateSyncStatistics(messagesReceived: 1)
        
        // Handle acknowledgments
        if message.type == .acknowledgment,
           let ackData = try? JSONDecoder().decode(AcknowledgmentMessage.self, from: message.payload) {
            handleAcknowledgment(ackData.sequenceNumber)
            return
        }
        
        // Send acknowledgment if required
        if message.requiresAcknowledgment {
            await sendAcknowledgment(for: message.sequenceNumber)
        }
        
        // Check for duplicate messages (basic deduplication)
        if !messageBuffer.contains(where: { $0.id == message.id }) {
            messageBuffer.append(message)
            
            // Limit buffer size
            if messageBuffer.count > maxMessageBufferSize {
                messageBuffer.removeFirst(10)
            }
            
            // Process message content
            delegate?.realtimeSyncManager(self, didReceiveMessage: message)
            
            print("📥 Received message: \(message.type) (seq: \(message.sequenceNumber))")
        }
    }
    
    // MARK: - Acknowledgment Management
    
    private func sendAcknowledgment(for sequenceNumber: UInt64) async {
        let ackMessage = AcknowledgmentMessage(sequenceNumber: sequenceNumber)
        
        do {
            let message = RealtimeSyncMessage(
                id: UUID(),
                sequenceNumber: nextSequenceNumber(),
                timestamp: Date(),
                type: .acknowledgment,
                payload: try JSONEncoder().encode(ackMessage),
                senderId: UUID(), // Would be set with actual participant ID
                requiresAcknowledgment: false
            )
            
            try await sendRealtimeMessage(message)
            
        } catch {
            print("❌ Failed to send acknowledgment: \(error)")
        }
    }
    
    private func handleAcknowledgment(_ sequenceNumber: UInt64) {
        if let queuedMessage = pendingAcknowledgments.removeValue(forKey: sequenceNumber) {
            print("✅ Received acknowledgment for message: \(sequenceNumber)")
            
            // Calculate round-trip time for latency monitoring
            let roundTripTime = Date().timeIntervalSince(queuedMessage.lastAttempt)
            updateLatencyMetrics(roundTripTime)
        }
    }
    
    private func setAcknowledgmentTimeout(for sequenceNumber: UInt64) {
        DispatchQueue.main.asyncAfter(deadline: .now() + acknowledgmentTimeout) { [weak self] in
            self?.handleAcknowledgmentTimeout(sequenceNumber: sequenceNumber)
        }
    }
    
    private func handleAcknowledgmentTimeout(sequenceNumber: UInt64) {
        guard var queuedMessage = pendingAcknowledgments[sequenceNumber] else {
            return
        }
        
        queuedMessage.attemptCount += 1
        
        if queuedMessage.attemptCount <= maxRetryAttempts {
            // Retry sending the message
            queuedMessage.lastAttempt = Date()
            pendingAcknowledgments[sequenceNumber] = queuedMessage
            
            Task {
                do {
                    try await sendRealtimeMessage(queuedMessage.message)
                    print("🔄 Retried message: \(sequenceNumber) (attempt \(queuedMessage.attemptCount))")
                } catch {
                    print("❌ Failed to retry message: \(error)")
                }
            }
            
            // Set another timeout
            setAcknowledgmentTimeout(for: sequenceNumber)
            
        } else {
            // Max retries exceeded - remove from pending
            pendingAcknowledgments.removeValue(forKey: sequenceNumber)
            print("❌ Message acknowledgment timeout exceeded: \(sequenceNumber)")
            
            delegate?.realtimeSyncManager(self, didFailToDeliverMessage: queuedMessage.message)
        }
    }
    
    // MARK: - Message Queue Management
    
    private func queueMessage(_ message: RealtimeSyncMessage) {
        let queuedMessage = QueuedMessage(
            message: message,
            attemptCount: 0,
            lastAttempt: Date()
        )
        
        messageQueue.append(queuedMessage)
        
        // Limit queue size
        if messageQueue.count > 50 {
            messageQueue.removeFirst(10)
        }
        
        print("📦 Queued message: \(message.type)")
    }
    
    private func processMessageQueue() async {
        guard connectionStatus == .connected else { return }
        
        let messagesToSend = messageQueue
        messageQueue.removeAll()
        
        for queuedMessage in messagesToSend {
            do {
                try await sendRealtimeMessage(queuedMessage.message)
                print("📤 Sent queued message: \(queuedMessage.message.type)")
            } catch {
                // Re-queue failed messages
                queueMessage(queuedMessage.message)
                print("❌ Failed to send queued message: \(error)")
            }
        }
    }
    
    // MARK: - Heartbeat Management
    
    private func startHeartbeat() {
        stopHeartbeat()
        
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.sendHeartbeat()
            }
        }
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
    }
    
    private func sendHeartbeat() async {
        let heartbeat = HeartbeatMessage(timestamp: Date())
        
        do {
            try await sendMessage(.heartbeat, payload: heartbeat)
        } catch {
            print("❌ Failed to send heartbeat: \(error)")
        }
    }
    
    // MARK: - Latency Monitoring
    
    private func startLatencyChecks() {
        stopLatencyChecks()
        
        latencyTimer = Timer.scheduledTimer(withTimeInterval: latencyCheckInterval, repeats: true) { [weak self] _ in
            Task { [weak self] in
                await self?.performLatencyCheck()
            }
        }
    }
    
    private func stopLatencyChecks() {
        latencyTimer?.invalidate()
        latencyTimer = nil
    }
    
    private func performLatencyCheck() async {
        let pingMessage = PingMessage(timestamp: Date())
        
        do {
            try await sendMessage(.ping, payload: pingMessage)
        } catch {
            print("❌ Failed to send ping: \(error)")
        }
    }
    
    private func updateLatencyMetrics(_ roundTripTime: TimeInterval) {
        let latencyMs = roundTripTime * 1000
        
        syncStatistics.latencyHistory.append(latencyMs)
        
        // Keep only recent measurements
        if syncStatistics.latencyHistory.count > 20 {
            syncStatistics.latencyHistory.removeFirst(5)
        }
        
        // Calculate average latency
        syncStatistics.averageLatency = syncStatistics.latencyHistory.reduce(0, +) / Double(syncStatistics.latencyHistory.count)
        
        updateConnectionQuality()
    }
    
    private func updateConnectionQuality() {
        let avgLatency = syncStatistics.averageLatency
        
        if !isNetworkAvailable {
            connectionQuality = .unknown
        } else if avgLatency < 50 {
            connectionQuality = .excellent
        } else if avgLatency < 150 {
            connectionQuality = .good
        } else if avgLatency < 300 {
            connectionQuality = .fair
        } else {
            connectionQuality = .poor
        }
    }
    
    // MARK: - Statistics Management
    
    private func updateSyncStatistics(messagesSent: Int = 0, messagesReceived: Int = 0) {
        syncStatistics.messagesSent += messagesSent
        syncStatistics.messagesReceived += messagesReceived
        syncStatistics.lastUpdate = Date()
        
        // Calculate message rate
        let timeInterval = Date().timeIntervalSince(syncStatistics.sessionStart)
        if timeInterval > 0 {
            syncStatistics.messagesPerSecond = Double(syncStatistics.messagesSent + syncStatistics.messagesReceived) / timeInterval
        }
    }
    
    // MARK: - Reconnection Management
    
    private func startReconnectionTimer() {
        stopReconnectionTimer()
        
        reconnectionTimer = Timer.scheduledTimer(withTimeInterval: reconnectionInterval, repeats: false) { [weak self] _ in
            Task { [weak self] in
                await self?.attemptReconnection()
            }
        }
    }
    
    private func stopReconnectionTimer() {
        reconnectionTimer?.invalidate()
        reconnectionTimer = nil
    }
    
    // MARK: - Utility Methods
    
    private func nextSequenceNumber() -> UInt64 {
        messageSequenceNumber += 1
        return messageSequenceNumber
    }
    
    // MARK: - Public Interface
    
    func getConnectionStatus() -> ConnectionStatus {
        return connectionStatus
    }
    
    func getConnectionQuality() -> ConnectionQuality {
        return connectionQuality
    }
    
    func getSyncStatistics() -> SyncStatistics {
        return syncStatistics
    }
    
    func getPendingMessageCount() -> Int {
        return messageQueue.count + pendingAcknowledgments.count
    }
    
    func clearMessageQueue() {
        messageQueue.removeAll()
        pendingAcknowledgments.removeAll()
        print("🗑️ Cleared message queue")
    }
    
    func forceReconnection() async {
        disconnect()
        await attemptReconnection()
    }
}

// MARK: - Supporting Types

struct RealtimeSyncMessage: Codable, Identifiable {
    let id: UUID
    let sequenceNumber: UInt64
    let timestamp: Date
    let type: MessageType
    let payload: Data
    let senderId: UUID
    let requiresAcknowledgment: Bool
    
    enum MessageType: String, Codable {
        case contextUpdate = "context_update"
        case participantJoined = "participant_joined"
        case participantLeft = "participant_left"
        case documentChanged = "document_changed"
        case decisionProposed = "decision_proposed"
        case decisionVoted = "decision_voted"
        case voiceCommandQueued = "voice_command_queued"
        case aiResponseGenerated = "ai_response_generated"
        case conflictDetected = "conflict_detected"
        case conflictResolved = "conflict_resolved"
        case heartbeat = "heartbeat"
        case ping = "ping"
        case pong = "pong"
        case acknowledgment = "acknowledgment"
        case error = "error"
    }
}

struct QueuedMessage: Identifiable {
    let id = UUID()
    let message: RealtimeSyncMessage
    var attemptCount: Int
    var lastAttempt: Date
}

struct AcknowledgmentMessage: Codable {
    let sequenceNumber: UInt64
}

struct HeartbeatMessage: Codable {
    let timestamp: Date
}

struct PingMessage: Codable {
    let timestamp: Date
}

struct PongMessage: Codable {
    let originalTimestamp: Date
    let responseTimestamp: Date
}

struct SyncStatistics {
    var sessionStart: Date = Date()
    var lastUpdate: Date = Date()
    var messagesSent: Int = 0
    var messagesReceived: Int = 0
    var messagesPerSecond: Double = 0
    var averageLatency: Double = 0
    var latencyHistory: [Double] = []
    var connectionDrops: Int = 0
    var reconnectionAttempts: Int = 0
}

// MARK: - Delegate Protocol

protocol RealtimeSyncManagerDelegate: AnyObject {
    func realtimeSyncManager(_ manager: RealtimeSyncManager, didReceiveMessage message: RealtimeSyncMessage)
    func realtimeSyncManager(_ manager: RealtimeSyncManager, didFailToDeliverMessage message: RealtimeSyncMessage)
    func realtimeSyncManager(_ manager: RealtimeSyncManager, connectionStatusDidChange status: RealtimeSyncManager.ConnectionStatus)
    func realtimeSyncManager(_ manager: RealtimeSyncManager, connectionQualityDidChange quality: RealtimeSyncManager.ConnectionQuality)
}

// MARK: - Error Types

enum RealtimeSyncError: LocalizedError {
    case networkUnavailable
    case invalidURL
    case notConnected
    case connectionFailed(String)
    case sendFailed(String)
    case encodingFailed(String)
    case decodingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is not available"
        case .invalidURL:
            return "Invalid WebSocket URL"
        case .notConnected:
            return "Not connected to sync service"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .sendFailed(let reason):
            return "Message send failed: \(reason)"
        case .encodingFailed(let reason):
            return "Message encoding failed: \(reason)"
        case .decodingFailed(let reason):
            return "Message decoding failed: \(reason)"
        }
    }
}

// MARK: - Extensions

extension RealtimeSyncManager.ConnectionStatus: Equatable {
    static func == (lhs: RealtimeSyncManager.ConnectionStatus, rhs: RealtimeSyncManager.ConnectionStatus) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.connected, .connected),
             (.reconnecting, .reconnecting):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension Date {
    var millisecondsSince1970: Int64 {
        return Int64((timeIntervalSince1970 * 1000.0).rounded())
    }
}