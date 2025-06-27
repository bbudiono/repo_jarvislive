import XCTest
@testable import JarvisLive_Sandbox
import LiveKit
import Combine

// A standalone mock that conforms to our LiveKitRoom protocol for testing.
// We use @unchecked Sendable because this mock is only used for testing
// in a controlled, single-threaded manner, and we can guarantee its safety.
class MockLiveKitRoom: LiveKitRoom, @unchecked Sendable {
    // Hold a weak reference to the delegate to avoid retain cycles.
    weak var delegate: RoomDelegate?

    // --- Test Control Properties ---
    var shouldSucceed: Bool = true
    private(set) var connectCalled = false
    private(set) var disconnectCalled = false

    // A mock error to simulate failure
    let mockError = LiveKitError(.unknown, message: "Test connection failure")

    func add(delegate: RoomDelegate) {
        self.delegate = delegate
    }

    func connect(url: String, token: String, connectOptions: ConnectOptions?, roomOptions: RoomOptions?) async throws {
        connectCalled = true

        if !shouldSucceed {
            throw mockError
        }
        // Success case - the actual delegate updates will be tested via LiveKitManager directly
    }

    func disconnect() async {
        disconnectCalled = true
        // Mock disconnect - LiveKitManager will handle state updates
    }
}

@MainActor
class LiveKitManagerTests: XCTestCase {
    var liveKitManager: LiveKitManager!
    var mockRoom: MockLiveKitRoom!
    var mockKeychainManager: KeychainManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRoom = MockLiveKitRoom()
        mockKeychainManager = KeychainManager(service: "com.ablankcanvas.JarvisLive.tests")
        liveKitManager = LiveKitManager(room: mockRoom, keychainManager: mockKeychainManager)
        cancellables = []

        // Set up test credentials for LiveKit connection tests
        try? mockKeychainManager.storeCredential("ws://test.livekit.io", forKey: "livekit-url")
        try? mockKeychainManager.storeCredential("test-token-123", forKey: "livekit-token")
    }

    override func tearDown() {
        // Clean up test credentials
        try? mockKeychainManager.deleteCredential(forKey: "livekit-url")
        try? mockKeychainManager.deleteCredential(forKey: "livekit-token")

        // Clean up AI API credentials that may be created during tests
        try? mockKeychainManager.deleteCredential(forKey: "anthropic-api-key")
        try? mockKeychainManager.deleteCredential(forKey: "openai-api-key")
        try? mockKeychainManager.deleteCredential(forKey: "elevenlabs-api-key")

        liveKitManager = nil
        mockRoom = nil
        mockKeychainManager = nil
        cancellables = nil
        super.tearDown()
    }

    func test_initialState_isDisconnected() {
        XCTAssertEqual(liveKitManager.connectionState, .disconnected)
    }

    func test_connect_whenSucceeds_callsRoomConnect() async {
        // Given
        mockRoom.shouldSucceed = true

        // When
        await liveKitManager.connect()

        // Then
        XCTAssertTrue(mockRoom.connectCalled)
        XCTAssertEqual(liveKitManager.connectionState, .connecting)
    }

    func test_connect_whenFails_updatesStateToError() async {
        // Given
        mockRoom.shouldSucceed = false

        // When
        await liveKitManager.connect()

        // Then
        XCTAssertTrue(mockRoom.connectCalled)
        if case .error(let errorMessage) = liveKitManager.connectionState {
            XCTAssertEqual(errorMessage, "Connection failed: \(mockRoom.mockError.localizedDescription)")
        } else {
            XCTFail("Expected error state")
        }
    }

    func test_disconnect_callsRoomDisconnect() async {
        // When
        await liveKitManager.disconnect()

        // Then
        XCTAssertTrue(mockRoom.disconnectCalled)
        XCTAssertEqual(liveKitManager.connectionState, .disconnected)
    }

    // MARK: - Audio Engine State Tests

    func test_startAudioSession_whenDisconnected_doesNotChangeAudioState() async {
        // Given: Manager is disconnected
        XCTAssertEqual(liveKitManager.connectionState, .disconnected)
        XCTAssertEqual(liveKitManager.audioState, .idle)

        // When: Attempting to start audio session
        await liveKitManager.startAudioSession()

        // Then: Audio state should remain idle
        XCTAssertEqual(liveKitManager.audioState, .idle)
    }

    func test_stopAudioSession_whenIdle_remainsIdle() async {
        // Given: Manager with idle audio state
        XCTAssertEqual(liveKitManager.audioState, .idle)

        // When: Stopping audio session
        await liveKitManager.stopAudioSession()

        // Then: Audio state should remain idle
        XCTAssertEqual(liveKitManager.audioState, .idle)
    }

    // MARK: - Voice Activity Detection Tests

    func test_voiceActivityDetection_initialState() {
        // Given: Fresh manager instance
        // Then: Voice activity should not be detected
        XCTAssertFalse(liveKitManager.isVoiceActivityDetected)
        XCTAssertEqual(liveKitManager.audioLevel, 0.0)
    }

    // MARK: - Conversation History Tests

    func test_conversationHistory_initiallyEmpty() {
        // Given: Fresh manager instance
        // Then: Conversation history should be empty
        let history = liveKitManager.getConversationHistory()
        XCTAssertTrue(history.isEmpty, "Conversation history should be initially empty")
    }

    func test_clearConversationHistory_removesAllEntries() {
        // Given: Manager instance
        // When: Clearing conversation history
        liveKitManager.clearConversationHistory()

        // Then: History should be empty
        let history = liveKitManager.getConversationHistory()
        XCTAssertTrue(history.isEmpty, "Conversation history should be empty after clearing")
    }

    // MARK: - Credential Configuration Tests

    func test_configureCredentials_storesInKeychain() async throws {
        // Given: Valid LiveKit credentials
        let testURL = "wss://test.livekit.io"
        let testToken = "test.token.12345"

        // When: Configuring credentials
        try await liveKitManager.configureCredentials(liveKitURL: testURL, liveKitToken: testToken)

        // Then: Credentials should be stored (method should not throw)
        let storedURL = try mockKeychainManager.getCredential(forKey: "livekit-url")
        let storedToken = try mockKeychainManager.getCredential(forKey: "livekit-token")
        XCTAssertEqual(storedURL, testURL)
        XCTAssertEqual(storedToken, testToken)
    }

    func test_configureAICredentials_storesAPIKeys() async throws {
        // Given: Valid AI API credentials
        let claudeKey = "sk-ant-test"
        let openAIKey = "sk-openai-test"
        let elevenLabsKey = "el-test"

        // When: Configuring AI credentials
        try await liveKitManager.configureAICredentials(
            claude: claudeKey,
            openAI: openAIKey,
            elevenLabs: elevenLabsKey
        )

        // Then: All credentials should be stored
        let storedClaude = try mockKeychainManager.getCredential(forKey: "anthropic-api-key")
        let storedOpenAI = try mockKeychainManager.getCredential(forKey: "openai-api-key")
        let storedElevenLabs = try mockKeychainManager.getCredential(forKey: "elevenlabs-api-key")

        XCTAssertEqual(storedClaude, claudeKey)
        XCTAssertEqual(storedOpenAI, openAIKey)
        XCTAssertEqual(storedElevenLabs, elevenLabsKey)
    }

    func test_configureAICredentials_withPartialCredentials_storesOnlyProvided() async throws {
        // Given: Only Claude credential provided
        let claudeKey = "sk-ant-test-partial"

        // When: Configuring only Claude credential
        try await liveKitManager.configureAICredentials(claude: claudeKey)

        // Then: Only Claude key should be stored
        let storedClaude = try mockKeychainManager.getCredential(forKey: "anthropic-api-key")
        XCTAssertEqual(storedClaude, claudeKey)

        // Other keys should not exist (will throw)
        XCTAssertThrowsError(try mockKeychainManager.getCredential(forKey: "openai-api-key"))
        XCTAssertThrowsError(try mockKeychainManager.getCredential(forKey: "elevenlabs-api-key"))
    }

    // MARK: - Error Handling Tests

    func test_connectionError_handledGracefully() async {
        // Given: Manager configured to fail connection
        mockRoom.shouldSucceed = false

        // When: Attempting to connect
        await liveKitManager.connect()

        // Then: Should handle error gracefully without crashing
        if case .error(let message) = liveKitManager.connectionState {
            XCTAssertFalse(message.isEmpty, "Error message should not be empty")
        } else {
            XCTFail("Expected error state")
        }

        // Audio state should remain idle on connection error
        XCTAssertEqual(liveKitManager.audioState, .idle)
    }
}

// MARK: - Mock Voice Activity Delegate for Testing

class MockVoiceActivityDelegate: VoiceActivityDelegate {
    var onVoiceStart: (() -> Void)?
    var onVoiceEnd: (() -> Void)?
    var onSpeechResult: ((String, Bool) -> Void)?
    var onAIResponse: ((String, Bool) -> Void)?

    func voiceActivityDidStart() {
        onVoiceStart?()
    }

    func voiceActivityDidEnd() {
        onVoiceEnd?()
    }

    func speechRecognitionResult(_ text: String, isFinal: Bool) {
        onSpeechResult?(text, isFinal)
    }

    func aiResponseReceived(_ response: String, isComplete: Bool) {
        onAIResponse?(response, isComplete)
    }
}
