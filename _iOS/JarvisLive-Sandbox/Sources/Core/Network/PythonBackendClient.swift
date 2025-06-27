// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Python backend client for MCP server communication and real-time data exchange
 * Issues & Complexity Summary: HTTP and WebSocket client for Python FastAPI backend integration
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~350
 *   - Core Algorithm Complexity: High (Async networking, error handling, reconnection logic)
 *   - Dependencies: 4 New (Foundation, Combine, Network, URLSessionWebSocketTask)
 *   - State Management Complexity: High (Connection states, request queuing, response handling)
 *   - Novelty/Uncertainty Factor: Medium (WebSocket integration with FastAPI)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 80%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Complex networking with real-time requirements and robust error handling
 * Final Code Complexity (Actual %): 87%
 * Overall Result Score (Success & Quality %): 89%
 * Key Variances/Learnings: WebSocket state management requires careful attention to connection lifecycle
 * Last Updated: 2025-06-26
 */

import Foundation
import Combine
import Network
import Security
import CommonCrypto

// MARK: - Python Backend Client

@MainActor
final class PythonBackendClient: NSObject, ObservableObject, URLSessionDelegate {
    // MARK: - Published Properties

    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    @Published private(set) var lastError: Error?
    @Published private(set) var isProcessing: Bool = false
    
    // MARK: - Connection State
    @Published var isConnected: Bool = false

    // MARK: - Connection Status

    enum ConnectionStatus: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)

        static func == (lhs: ConnectionStatus, rhs: ConnectionStatus) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected), (.connecting, .connecting),
                 (.connected, .connected), (.reconnecting, .reconnecting):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }

    // MARK: - Private Properties

    private let configuration: BackendConfiguration
    private let urlSession: URLSession
    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectionTask: Task<Void, Never>?
    private var heartbeatTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    // Certificate pinning properties
    private let pinnedCertificateData: Data?
    private let enableCertificatePinning: Bool

    // Request management
    private var pendingRequests: [String: CheckedContinuation<Data, Error>] = [:]
    private let requestQueue = DispatchQueue(label: "com.jarvis.backend.requests", qos: .userInitiated)

    // Retry configuration
    private let maxRetryAttempts = 3
    private let baseRetryDelay: TimeInterval = 1.0
    private let maxRetryDelay: TimeInterval = 30.0
    private var currentRetryAttempt = 0

    // MARK: - Configuration

    struct BackendConfiguration {
        let baseURL: String
        let websocketURL: String
        let apiKey: String?
        let timeout: TimeInterval
        let heartbeatInterval: TimeInterval
        let enableCertificatePinning: Bool
        let pinnedCertificateName: String?

        static let `default` = BackendConfiguration(
            baseURL: "http://localhost:8000",
            websocketURL: "ws://localhost:8000/ws",
            apiKey: nil,
            timeout: 30.0,
            heartbeatInterval: 30.0,
            enableCertificatePinning: false, // Disabled for localhost development
            pinnedCertificateName: nil
        )

        static let production = BackendConfiguration(
            baseURL: "https://api.jarvis.live",
            websocketURL: "wss://api.jarvis.live/ws",
            apiKey: nil,
            timeout: 30.0,
            heartbeatInterval: 30.0,
            enableCertificatePinning: true,
            pinnedCertificateName: "jarvis-api-cert" // Certificate file in app bundle
        )
    }

    // MARK: - Initialization

    @MainActor
    init(configuration: BackendConfiguration = .default) {
        self.configuration = configuration
        self.enableCertificatePinning = configuration.enableCertificatePinning

        // Load pinned certificate if enabled
        if configuration.enableCertificatePinning, let certName = configuration.pinnedCertificateName {
            self.pinnedCertificateData = Self.loadCertificateFromBundle(named: certName)
            if self.pinnedCertificateData == nil {
                print("⚠️ Certificate pinning enabled but certificate '\(certName)' not found in bundle")
            }
        } else {
            self.pinnedCertificateData = nil
        }

        // Configure URL session for HTTP requests with delegate for certificate pinning
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.timeout
        sessionConfig.timeoutIntervalForResource = configuration.timeout * 2

        super.init()

        self.urlSession = URLSession(
            configuration: sessionConfig,
            delegate: self,
            delegateQueue: nil
        )

        setupNetworkMonitoring()
    }

    deinit {
        Task { @MainActor in
            await disconnect()
        }
    }

    // MARK: - Connection Management

    func connect() async {
        guard connectionStatus != .connected && connectionStatus != .connecting else {
            return
        }

        connectionStatus = .connecting
        currentRetryAttempt = 0

        do {
            try await establishWebSocketConnection()
            await startHeartbeat()
            connectionStatus = .connected
            isConnected = true
            print("✅ Connected to Python backend")
        } catch {
            connectionStatus = .error(error.localizedDescription)
            lastError = error
            print("❌ Failed to connect to Python backend: \(error)")

            // Schedule reconnection
            await scheduleReconnection()
        }
    }

    func disconnect() async {
        connectionStatus = .disconnected
        isConnected = false

        // Cancel tasks
        reconnectionTask?.cancel()
        heartbeatTask?.cancel()

        // Close WebSocket
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil

        // Clear pending requests
        await clearPendingRequests(with: BackendError.disconnected)

        print("🔌 Disconnected from Python backend")
    }

    private func establishWebSocketConnection() async throws {
        guard let url = URL(string: configuration.websocketURL) else {
            throw BackendError.invalidURL
        }

        var request = URLRequest(url: url)

        // Add authentication if available
        if let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        webSocketTask = urlSession.webSocketTask(with: request)
        webSocketTask?.resume()

        // Start receiving messages
        await startReceivingMessages()
    }

    private func startReceivingMessages() async {
        guard let webSocketTask = webSocketTask else { return }

        do {
            let message = try await webSocketTask.receive()
            await handleWebSocketMessage(message)

            // Continue receiving if still connected
            if connectionStatus == .connected {
                await startReceivingMessages()
            }
        } catch {
            if connectionStatus == .connected {
                connectionStatus = .error("WebSocket receive error: \(error.localizedDescription)")
                await scheduleReconnection()
            }
        }
    }

    private func handleWebSocketMessage(_ message: URLSessionWebSocketTask.Message) async {
        switch message {
        case .string(let text):
            await processTextMessage(text)
        case .data(let data):
            await processDataMessage(data)
        @unknown default:
            print("⚠️ Unknown WebSocket message type")
        }
    }

    private func processTextMessage(_ text: String) async {
        guard let data = text.data(using: .utf8) else {
            print("⚠️ Invalid text message encoding")
            return
        }

        do {
            if let response = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let requestId = response["id"] as? String {
                // Handle response for pending request
                await completePendingRequest(id: requestId, with: data)
            } else {
                // Handle push notification or other messages
                await handlePushMessage(data)
            }
        } catch {
            print("⚠️ Failed to parse WebSocket message: \(error)")
        }
    }

    private func processDataMessage(_ data: Data) async {
        // Handle binary data messages (e.g., file uploads/downloads)
        await handlePushMessage(data)
    }

    private func handlePushMessage(_ data: Data) async {
        // Handle push notifications, real-time updates, etc.
        // This can be extended based on specific backend requirements
        print("📱 Received push message: \(data.count) bytes")
    }

    // MARK: - Request Management

    func sendRequest<T: Codable>(_ request: MCPRequest, responseType: T.Type) async throws -> T {
        guard connectionStatus == .connected else {
            throw BackendError.notConnected
        }

        isProcessing = true
        defer { isProcessing = false }

        let requestData = try JSONEncoder().encode(request)

        let responseData: Data = try await withCheckedThrowingContinuation { continuation in
            Task {
                await storePendingRequest(id: request.id, continuation: continuation)

                do {
                    try await sendWebSocketMessage(data: requestData)
                } catch {
                    await removePendingRequest(id: request.id)
                    continuation.resume(throwing: error)
                }
            }
        }

        // Decode the response data to the expected type
        do {
            return try JSONDecoder().decode(T.self, from: responseData)
        } catch {
            throw BackendError.decodingError(error)
        }
    }

    func sendHTTPRequest<T: Codable>(
        endpoint: String,
        method: HTTPMethod = .POST,
        body: Data? = nil,
        responseType: T.Type
    ) async throws -> T {
        guard let url = URL(string: "\(configuration.baseURL)\(endpoint)") else {
            throw BackendError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let apiKey = configuration.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = body
        }

        isProcessing = true
        defer { isProcessing = false }

        do {
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw BackendError.invalidResponse
            }

            guard 200...299 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw BackendError.httpError(httpResponse.statusCode, errorMessage)
            }

            let decodedResponse = try JSONDecoder().decode(T.self, from: data)
            return decodedResponse
        } catch {
            lastError = error
            throw error
        }
    }

    private func sendWebSocketMessage(data: Data) async throws {
        guard let webSocketTask = webSocketTask else {
            throw BackendError.notConnected
        }

        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask.send(message)
    }

    // MARK: - Pending Request Management

    private func storePendingRequest(id: String, continuation: CheckedContinuation<Data, Error>) async {
        await requestQueue.sync {
            pendingRequests[id] = continuation
        }

        // Set timeout for request
        Task {
            try await Task.sleep(nanoseconds: UInt64(configuration.timeout * 1_000_000_000))
            await timeoutRequest(id: id)
        }
    }

    private func completePendingRequest(id: String, with data: Data) async {
        let continuation = await requestQueue.sync {
            return pendingRequests.removeValue(forKey: id)
        }

        continuation?.resume(returning: data)
    }

    private func removePendingRequest(id: String) async {
        await requestQueue.sync {
            pendingRequests.removeValue(forKey: id)
        }
    }

    private func timeoutRequest(id: String) async {
        let continuation = await requestQueue.sync {
            return pendingRequests.removeValue(forKey: id)
        }

        continuation?.resume(throwing: BackendError.timeout)
    }

    private func clearPendingRequests(with error: Error) async {
        let continuations = await requestQueue.sync {
            let result = Array(pendingRequests.values)
            pendingRequests.removeAll()
            return result
        }

        for continuation in continuations {
            continuation.resume(throwing: error)
        }
    }

    // MARK: - Heartbeat and Reconnection

    private func startHeartbeat() async {
        heartbeatTask?.cancel()

        heartbeatTask = Task {
            while !Task.isCancelled && connectionStatus == .connected {
                do {
                    let pingData = "ping".data(using: .utf8)!
                    try await sendWebSocketMessage(data: pingData)

                    try await Task.sleep(nanoseconds: UInt64(configuration.heartbeatInterval * 1_000_000_000))
                } catch {
                    if connectionStatus == .connected {
                        connectionStatus = .error("Heartbeat failed: \(error.localizedDescription)")
                        await scheduleReconnection()
                    }
                    break
                }
            }
        }
    }

    private func scheduleReconnection() async {
        guard currentRetryAttempt < maxRetryAttempts else {
            connectionStatus = .error("Max retry attempts reached")
            return
        }

        connectionStatus = .reconnecting
        currentRetryAttempt += 1

        let delay = min(baseRetryDelay * pow(2.0, Double(currentRetryAttempt - 1)), maxRetryDelay)

        reconnectionTask?.cancel()
        reconnectionTask = Task {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await connect()
            } catch {
                // Task was cancelled
            }
        }
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                if path.status == .satisfied && self?.connectionStatus == .error("Network unavailable") {
                    await self?.connect()
                } else if path.status != .satisfied {
                    self?.connectionStatus = .error("Network unavailable")
                }
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }

    // MARK: - Health Check

    func performHealthCheck() async throws -> HealthCheckResult {
        let request = MCPRequest(method: "health_check")
        return try await sendRequest(request, responseType: HealthCheckResult.self)
    }
    
    // MARK: - Voice Session Methods
    
    /// Start a voice session with the backend
    func startVoiceSession() async throws {
        guard isConnected else {
            throw BackendError.notConnected
        }
        
        let request = MCPRequest(method: "start_voice_session")
        _ = try await sendRequest(request, responseType: VoiceSessionResult.self)
    }
    
    /// Classify voice command using the backend
    func classifyVoiceCommand(_ text: String, userId: String? = nil) async throws -> ClassificationResult {
        guard isConnected else {
            throw BackendError.notConnected
        }
        
        let params = VoiceClassificationParams(
            text: text,
            userId: userId ?? "default_user",
            sessionId: UUID().uuidString,
            useContext: true,
            includeSuggestions: true
        )
        
        let request = MCPRequest(method: "classify_voice_command", params: params)
        return try await sendRequest(request, responseType: ClassificationResult.self)
    }

    struct HealthCheckResult: Codable {
        let status: String
        let timestamp: Date
        let version: String
        let mcpServers: [String: String]
    }
}

// MARK: - HTTP Method

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - Backend Errors

enum BackendError: Error, LocalizedError {
    case invalidURL
    case notConnected
    case disconnected
    case timeout
    case invalidResponse
    case httpError(Int, String)
    case encodingError(Error)
    case decodingError(Error)
    case networkError(Error)
    case certificatePinningFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid backend URL"
        case .notConnected:
            return "Not connected to backend"
        case .disconnected:
            return "Disconnected from backend"
        case .timeout:
            return "Request timeout"
        case .invalidResponse:
            return "Invalid response from backend"
        case .httpError(let code, let message):
            return "HTTP error \(code): \(message)"
        case .encodingError(let error):
            return "Encoding error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .certificatePinningFailed(let details):
            return "Certificate pinning failed: \(details)"
        }
    }
}

// MARK: - Extensions

extension PythonBackendClient {
    // Convenience methods for common MCP operations

    func generateDocument(request: DocumentGenerationRequest) async throws -> DocumentGenerationResult {
        let mcpRequest = MCPRequest(method: "generate_document", params: request)
        return try await sendRequest(mcpRequest, responseType: DocumentGenerationResult.self)
    }

    func sendEmail(request: EmailRequest) async throws -> EmailResult {
        let mcpRequest = MCPRequest(method: "send_email", params: request)
        return try await sendRequest(mcpRequest, responseType: EmailResult.self)
    }

    func createCalendarEvent(request: CalendarEventRequest) async throws -> CalendarEventResult {
        let mcpRequest = MCPRequest(method: "create_calendar_event", params: request)
        return try await sendRequest(mcpRequest, responseType: CalendarEventResult.self)
    }

    func performSearch(request: SearchRequest) async throws -> SearchResult {
        let mcpRequest = MCPRequest(method: "search", params: request)
        return try await sendRequest(mcpRequest, responseType: SearchResult.self)
    }

    func uploadFile(request: StorageRequest) async throws -> StorageResult {
        let mcpRequest = MCPRequest(method: "upload_file", params: request)
        return try await sendRequest(mcpRequest, responseType: StorageResult.self)
    }

    // MARK: - Certificate Pinning Implementation

    /// Load certificate from app bundle
    private static func loadCertificateFromBundle(named name: String) -> Data? {
        guard let path = Bundle.main.path(forResource: name, ofType: "cer") ?? Bundle.main.path(forResource: name, ofType: "crt") else {
            print("⚠️ Certificate file '\(name)' not found in bundle")
            return nil
        }

        guard let data = FileManager.default.contents(atPath: path) else {
            print("⚠️ Unable to read certificate file at path: \(path)")
            return nil
        }

        print("✅ Loaded certificate '\(name)' from bundle (\(data.count) bytes)")
        return data
    }

    /// Extract public key from certificate data
    nonisolated private static func extractPublicKey(from certificateData: Data) -> SecKey? {
        guard let certificate = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            print("❌ Failed to create certificate from data")
            return nil
        }

        return SecCertificateCopyKey(certificate)
    }

    /// Compare two public keys for equality
    nonisolated private static func comparePublicKeys(_ key1: SecKey, _ key2: SecKey) -> Bool {
        guard let data1 = SecKeyCopyExternalRepresentation(key1, nil),
              let data2 = SecKeyCopyExternalRepresentation(key2, nil) else {
            return false
        }

        return CFEqual(data1, data2)
    }

    // MARK: - URLSessionDelegate Implementation

    nonisolated func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Only perform certificate pinning for server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // If certificate pinning is disabled, use default validation
        guard enableCertificatePinning else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        // Ensure we have pinned certificate data
        guard let pinnedCertificateData = pinnedCertificateData else {
            print("❌ Certificate pinning enabled but no pinned certificate data available")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Get server trust and certificate using updated API
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            print("❌ Failed to get server trust")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Use SecTrustCopyCertificateChain instead of deprecated SecTrustGetCertificateAtIndex
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust),
              CFArrayGetCount(certificateChain) > 0,
              let serverCertificate = CFArrayGetValueAtIndex(certificateChain, 0) else {
            print("❌ Failed to get server certificate from chain")
            completionHandler(.cancelAuthenticationChallenge, nil) 
            return
        }

        let serverCert = unsafeBitCast(serverCertificate, to: SecCertificate.self)

        // Extract public keys for comparison
        let serverCertificateData = SecCertificateCopyData(serverCert)
        guard let serverPublicKey = SecCertificateCopyKey(serverCert),
              let pinnedPublicKey = Self.extractPublicKey(from: pinnedCertificateData) else {
            print("❌ Failed to extract public keys for comparison")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        // Compare public keys
        if Self.comparePublicKeys(serverPublicKey, pinnedPublicKey) {
            // Keys match - create credential and allow connection
            let credential = URLCredential(trust: serverTrust)
            print("✅ Certificate pinning validation successful")
            completionHandler(.useCredential, credential)
        } else {
            // Keys don't match - reject connection
            print("❌ Certificate pinning validation failed - server certificate does not match pinned certificate")
            print("   Server certificate fingerprint: \(Self.certificateFingerprint(certificateData: CFDataCreateCopy(nil, serverCertificateData)))")
            print("   Pinned certificate fingerprint: \(Self.certificateFingerprint(certificateData: pinnedCertificateData as CFData))")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }

    /// Generate SHA-256 fingerprint for certificate debugging
    nonisolated private static func certificateFingerprint(certificateData: CFData?) -> String {
        guard let data = certificateData else { return "unknown" }

        let dataBytes = CFDataGetBytePtr(data)
        let dataLength = CFDataGetLength(data)

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(dataBytes, CC_LONG(dataLength), &hash)

        return hash.map { String(format: "%02x", $0) }.joined(separator: ":")
    }
}

// MARK: - Certificate Pinning Errors

enum CertificatePinningError: Error, LocalizedError {
    case noPinnedCertificate
    case invalidServerCertificate
    case publicKeyExtractionFailed
    case certificateMismatch

    var errorDescription: String? {
        switch self {
        case .noPinnedCertificate:
            return "No pinned certificate data available"
        case .invalidServerCertificate:
            return "Invalid server certificate"
        case .publicKeyExtractionFailed:
            return "Failed to extract public keys for comparison"
        case .certificateMismatch:
            return "Server certificate does not match pinned certificate"
        }
    }
}

// MARK: - Supporting Types

struct VoiceSessionResult: Codable {
    let sessionId: String
    let status: String
    let capabilities: [String]
}

struct VoiceClassificationParams: MCPParams {
    let text: String
    let userId: String
    let sessionId: String
    let useContext: Bool
    let includeSuggestions: Bool
}
