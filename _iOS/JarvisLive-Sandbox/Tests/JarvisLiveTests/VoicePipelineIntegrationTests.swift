// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive integration tests for the End-to-End Voice Command Pipeline
 * Issues & Complexity Summary: Complex integration testing covering voice classification, MCP execution, and response generation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~600
 *   - Core Algorithm Complexity: High (End-to-end pipeline testing)
 *   - Dependencies: 8 Major (Voice Pipeline, MCP, Classification, Synthesis, etc.)
 *   - State Management Complexity: High (Multi-stage pipeline validation)
 *   - Novelty/Uncertainty Factor: Medium (Integration testing patterns)
 * AI Pre-Task Self-Assessment: 85%
 * Problem Estimate: 90%
 * Initial Code Complexity Estimate: 85%
 * Final Code Complexity: TBD
 * Overall Result Score: TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import XCTest
import Combine
@testable import JarvisLive_Sandbox

@MainActor
final class VoicePipelineIntegrationTests: XCTestCase {
    // MARK: - Test Properties

    var voiceClassificationManager: VoiceClassificationManager!
    var voiceCommandExecutor: VoiceCommandExecutor!
    var conversationManager: ConversationManager!
    var elevenLabsVoiceSynthesizer: ElevenLabsVoiceSynthesizer!
    var mcpServerManager: MockMCPServerManager!
    var voiceCommandPipeline: VoiceCommandPipeline!
    var liveKitManager: LiveKitManager!

    var cancellables: Set<AnyCancellable>!

    // MARK: - Test Setup

    override func setUp() async throws {
        await super.setUp()

        cancellables = Set<AnyCancellable>()

        // Initialize test components
        await setupTestComponents()

        // Wait for initialization to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }

    override func tearDown() async throws {
        // Clean up resources
        cancellables.removeAll()

        if let mcpManager = mcpServerManager {
            await mcpManager.disconnect()
        }

        await super.tearDown()
    }

    private func setupTestComponents() async {
        // Initialize core components
        conversationManager = ConversationManager()
        mcpServerManager = MockMCPServerManager()

        // Initialize voice classification manager (with mock configuration)
        let mockConfig = VoiceClassificationManager.Configuration(
            baseURL: URL(string: "http://localhost:8000")!,
            apiKeyService: "test-service",
            timeout: 10.0,
            maxRetryAttempts: 1,
            retryDelay: 0.1
        )

        voiceClassificationManager = VoiceClassificationManager(
            configuration: mockConfig,
            session: MockNetworkSession(),
            keychainManager: MockKeychainManager()
        )

        // Initialize voice synthesizer
        let synthConfig = ElevenLabsVoiceSynthesizer.Configuration(
            baseURL: "https://api.elevenlabs.io",
            apiVersion: "v1",
            maxCacheSize: 10,
            cacheExpirationTime: 60,
            requestTimeout: 5.0,
            maxRetries: 1
        )

        elevenLabsVoiceSynthesizer = ElevenLabsVoiceSynthesizer(
            configuration: synthConfig,
            keychainManager: MockKeychainManager()
        )

        // Initialize voice command executor
        voiceCommandExecutor = VoiceCommandExecutor(
            mcpServerManager: mcpServerManager
        )

        // Initialize the complete voice pipeline
        voiceCommandPipeline = VoiceCommandPipeline(
            voiceClassifier: voiceClassificationManager,
            commandExecutor: voiceCommandExecutor,
            conversationManager: conversationManager,
            collaborationManager: nil,
            voiceSynthesizer: elevenLabsVoiceSynthesizer,
            mcpServerManager: mcpServerManager
        )

        // Initialize LiveKit manager
        liveKitManager = LiveKitManager(
            room: MockLiveKitRoom(),
            keychainManager: MockKeychainManager()
        )
    }

    // MARK: - Complete Voice Pipeline Tests

    func test_completeVoicePipeline_connectionToRecording() async throws {
        // Given: Fresh system setup
        XCTAssertEqual(liveKitManager.connectionState, .disconnected)
        XCTAssertEqual(liveKitManager.audioState, .idle)

        // Step 1: Connect to LiveKit
        mockRoom.shouldSucceed = true
        await liveKitManager.connect()

        // Verify connection established
        XCTAssertTrue(mockRoom.connectCalled)
        XCTAssertEqual(liveKitManager.connectionState, .connecting)

        // Step 2: Set up voice activity delegate
        liveKitManager.voiceActivityDelegate = voiceCoordinator

        // Step 3: Start audio session
        await liveKitManager.startAudioSession()

        // Verify audio session started (audio state should transition)
        // Note: In real implementation, this would change to .recording
        XCTAssertNotEqual(liveKitManager.audioState, .idle)
    }

    func test_credentialConfiguration_endToEnd() async throws {
        // Given: Clean state
        let testClaudeKey = "sk-ant-e2e-test-key"
        let testOpenAIKey = "sk-openai-e2e-test"
        let testElevenLabsKey = "el-e2e-test"

        // When: Configuring all AI credentials
        try await liveKitManager.configureAICredentials(
            claude: testClaudeKey,
            openAI: testOpenAIKey,
            elevenLabs: testElevenLabsKey
        )

        // Then: All credentials should be retrievable
        let storedClaude = try mockKeychainManager.getCredential(forKey: "anthropic-api-key")
        let storedOpenAI = try mockKeychainManager.getCredential(forKey: "openai-api-key")
        let storedElevenLabs = try mockKeychainManager.getCredential(forKey: "elevenlabs-api-key")

        XCTAssertEqual(storedClaude, testClaudeKey)
        XCTAssertEqual(storedOpenAI, testOpenAIKey)
        XCTAssertEqual(storedElevenLabs, testElevenLabsKey)
    }

    func test_voiceActivityDetectionWorkflow() async {
        // Given: Connected system with delegate
        mockRoom.shouldSucceed = true
        await liveKitManager.connect()
        liveKitManager.voiceActivityDelegate = voiceCoordinator

        // Create expectation for voice activity callback
        let voiceStartExpectation = expectation(description: "Voice activity started")
        let voiceEndExpectation = expectation(description: "Voice activity ended")

        voiceCoordinator.onVoiceStart = {
            voiceStartExpectation.fulfill()
        }

        voiceCoordinator.onVoiceEnd = {
            voiceEndExpectation.fulfill()
        }

        // When: Simulate voice activity
        voiceCoordinator.voiceActivityDidStart()
        await fulfillment(of: [voiceStartExpectation], timeout: 1.0)

        // Verify voice activity state
        XCTAssertTrue(voiceCoordinator.showVoiceActivity)

        // When: End voice activity
        voiceCoordinator.voiceActivityDidEnd()
        await fulfillment(of: [voiceEndExpectation], timeout: 1.0)

        // Verify state reset
        XCTAssertFalse(voiceCoordinator.showVoiceActivity)
    }

    func test_speechRecognitionIntegration() async {
        // Given: System with speech delegate configured
        liveKitManager.voiceActivityDelegate = voiceCoordinator

        let speechExpectation = expectation(description: "Speech recognition result")
        let testTranscription = "Hello, this is a test transcription"

        voiceCoordinator.onSpeechResult = { text, isFinal in
            if text == testTranscription && isFinal {
                speechExpectation.fulfill()
            }
        }

        // When: Simulate speech recognition result
        voiceCoordinator.speechRecognitionResult(testTranscription, isFinal: true)

        // Then: Verify transcription was received
        await fulfillment(of: [speechExpectation], timeout: 1.0)
        XCTAssertEqual(voiceCoordinator.currentTranscription, testTranscription)
    }

    func test_aiResponseIntegration() async {
        // Given: System configured for AI responses
        liveKitManager.voiceActivityDelegate = voiceCoordinator

        let aiResponseExpectation = expectation(description: "AI response received")
        let testResponse = "This is a test AI response from Claude"

        voiceCoordinator.onAIResponse = { response, isComplete in
            if response == testResponse && isComplete {
                aiResponseExpectation.fulfill()
            }
        }

        // When: Simulate AI response
        voiceCoordinator.aiResponseReceived(testResponse, isComplete: true)

        // Then: Verify response was received
        await fulfillment(of: [aiResponseExpectation], timeout: 1.0)
        XCTAssertEqual(voiceCoordinator.currentAIResponse, testResponse)
    }

    func test_conversationHistoryManagement() {
        // Given: Fresh manager
        XCTAssertTrue(liveKitManager.getConversationHistory().isEmpty)

        // When: Adding conversation entries through voice coordinator
        voiceCoordinator.currentTranscription = "User said hello"
        voiceCoordinator.currentAIResponse = "AI responded with greeting"

        // Then: Clear history functionality works
        liveKitManager.clearConversationHistory()
        XCTAssertTrue(liveKitManager.getConversationHistory().isEmpty)
    }

    func test_errorRecoveryWorkflow() async {
        // Given: System that will fail connection
        mockRoom.shouldSucceed = false

        // When: Attempting to connect
        await liveKitManager.connect()

        // Then: System should handle error gracefully
        if case .error(let message) = liveKitManager.connectionState {
            XCTAssertFalse(message.isEmpty)
            XCTAssertEqual(liveKitManager.audioState, .idle)
        } else {
            XCTFail("Expected error state")
        }

        // When: Attempting audio session during error state
        await liveKitManager.startAudioSession()

        // Then: Audio session should not start
        XCTAssertEqual(liveKitManager.audioState, .idle)
    }

    func test_systemStateConsistency() async {
        // Test that the system maintains consistent state across operations

        // Initial state verification
        XCTAssertEqual(liveKitManager.connectionState, .disconnected)
        XCTAssertEqual(liveKitManager.audioState, .idle)
        XCTAssertFalse(liveKitManager.isVoiceActivityDetected)
        XCTAssertEqual(liveKitManager.audioLevel, 0.0)

        // Connect and verify state consistency
        mockRoom.shouldSucceed = true
        await liveKitManager.connect()

        // State should be consistent after connection
        XCTAssertNotEqual(liveKitManager.connectionState, .disconnected)
        XCTAssertEqual(liveKitManager.audioState, .idle) // Still idle until audio session starts

        // Disconnect and verify cleanup
        await liveKitManager.disconnect()
        XCTAssertEqual(liveKitManager.connectionState, .disconnected)
        XCTAssertEqual(liveKitManager.audioState, .idle)
    }

    // MARK: - End-to-End Voice Pipeline Integration Tests

    func testCompleteVoiceCommandFlow_DocumentGeneration() async throws {
        print("🧪 Testing complete voice command flow for document generation")

        // Test input
        let voiceInput = "Create a PDF document about artificial intelligence"

        // Prepare request
        let request = VoiceProcessingRequest(
            audioInput: voiceInput,
            userId: "test_user",
            sessionId: "test_session",
            collaborationContext: nil,
            conversationHistory: [],
            enableMCPExecution: true,
            enableVoiceResponse: false // Disable for faster testing
        )

        // Process through pipeline
        let result = try await voiceCommandPipeline.processVoiceInput(request)

        // Validate results
        XCTAssertEqual(result.classification.category, "document_generation", "Should classify as document generation")
        XCTAssertGreaterThan(result.classification.confidence, 0.5, "Should have reasonable confidence")
        XCTAssertNotNil(result.execution, "Should have execution result")
        XCTAssertTrue(result.execution?.success == true, "Execution should succeed")
        XCTAssertFalse(result.response.isEmpty, "Should have response text")

        // Validate processing metrics
        let metrics = result.processingMetrics
        XCTAssertGreaterThan(metrics.totalProcessingTime, 0, "Should have processing time")
        XCTAssertGreaterThan(metrics.classificationTime, 0, "Should have classification time")
        XCTAssertNotNil(metrics.executionTime, "Should have execution time")
        XCTAssertTrue(metrics.success, "Overall processing should succeed")

        print("✅ Document generation test completed successfully")
        print("   Classification: \(result.classification.category) (\(result.classification.confidence))")
        print("   Execution: \(result.execution?.success == true ? "Success" : "Failed")")
        print("   Response: \(result.response)")
        print("   Total time: \(metrics.totalProcessingTime)s")
    }

    func testCompleteVoiceCommandFlow_EmailManagement() async throws {
        print("🧪 Testing complete voice command flow for email management")

        // Test input
        let voiceInput = "Send an email to john@example.com with subject Meeting tomorrow"

        // Prepare request
        let request = VoiceProcessingRequest(
            audioInput: voiceInput,
            userId: "test_user",
            sessionId: "test_session",
            collaborationContext: nil,
            conversationHistory: [],
            enableMCPExecution: true,
            enableVoiceResponse: false
        )

        // Process through pipeline
        let result = try await voiceCommandPipeline.processVoiceInput(request)

        // Validate results
        XCTAssertEqual(result.classification.category, "email_management", "Should classify as email management")
        XCTAssertGreaterThan(result.classification.confidence, 0.5, "Should have reasonable confidence")
        XCTAssertNotNil(result.execution, "Should have execution result")
        XCTAssertTrue(result.execution?.success == true, "Execution should succeed")

        // Validate conversation update
        XCTAssertNotNil(result.conversationUpdate, "Should have conversation update")
        XCTAssertEqual(result.conversationUpdate.newMessage.role, .assistant, "Should create assistant message")

        print("✅ Email management test completed successfully")
    }

    func testCompleteVoiceCommandFlow_CalendarScheduling() async throws {
        print("🧪 Testing complete voice command flow for calendar scheduling")

        // Test input
        let voiceInput = "Schedule a team meeting for tomorrow at 2 PM"

        // Prepare request
        let request = VoiceProcessingRequest(
            audioInput: voiceInput,
            userId: "test_user",
            sessionId: "test_session",
            collaborationContext: nil,
            conversationHistory: [],
            enableMCPExecution: true,
            enableVoiceResponse: false
        )

        // Process through pipeline
        let result = try await voiceCommandPipeline.processVoiceInput(request)

        // Validate results
        XCTAssertEqual(result.classification.category, "calendar_scheduling", "Should classify as calendar scheduling")
        XCTAssertNotNil(result.execution, "Should have execution result")
        XCTAssertTrue(result.execution?.success == true, "Execution should succeed")

        print("✅ Calendar scheduling test completed successfully")
    }

    func testVoicePipelinePerformance() async throws {
        print("🧪 Testing voice pipeline performance")

        let testInputs = [
            "Create a document about AI",
            "Send email to test@example.com",
            "Schedule meeting tomorrow",
            "Search for Swift tutorials",
            "Hello there",
        ]

        var totalTime: TimeInterval = 0
        var successCount = 0

        for input in testInputs {
            let startTime = Date()

            let request = VoiceProcessingRequest(
                audioInput: input,
                userId: "test_user",
                sessionId: "test_session",
                collaborationContext: nil,
                conversationHistory: [],
                enableMCPExecution: true,
                enableVoiceResponse: false
            )

            do {
                let result = try await voiceCommandPipeline.processVoiceInput(request)
                let processingTime = Date().timeIntervalSince(startTime)
                totalTime += processingTime

                if result.processingMetrics.success {
                    successCount += 1
                }

                print("  Input: '\(input)' -> \(processingTime)s")

                // Performance requirement: <2 seconds per request
                XCTAssertLessThan(processingTime, 2.0, "Processing should complete within 2 seconds")
            } catch {
                print("  Failed: '\(input)' -> \(error.localizedDescription)")
            }
        }

        let averageTime = totalTime / Double(testInputs.count)
        let successRate = Double(successCount) / Double(testInputs.count)

        print("✅ Performance test results:")
        print("   Average time: \(averageTime)s")
        print("   Success rate: \(successRate * 100)%")

        XCTAssertGreaterThan(successRate, 0.8, "Success rate should be > 80%")
        XCTAssertLessThan(averageTime, 1.0, "Average processing time should be < 1 second")
    }

    func testLiveKitManagerVoicePipelineIntegration() async throws {
        print("🧪 Testing LiveKit Manager integration with voice pipeline")

        // Verify the pipeline is properly initialized in LiveKitManager
        XCTAssertNotNil(liveKitManager.voiceCommandPipeline, "LiveKit manager should have voice pipeline")
        XCTAssertNotNil(liveKitManager.voiceClassificationManager, "LiveKit manager should have voice classifier")
        XCTAssertNotNil(liveKitManager.elevenLabsVoiceSynthesizer, "LiveKit manager should have voice synthesizer")

        // Test that the pipeline health check works
        let healthStatus = await liveKitManager.voiceCommandPipeline?.performHealthCheck()
        XCTAssertNotNil(healthStatus, "Should be able to perform health check")

        if let health = healthStatus {
            print("  Health check results: \(health)")
        }

        print("✅ LiveKit Manager integration test completed")
    }

    // MARK: - Mock Implementation Classes

    private class MockNetworkSession: NetworkSession {
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            // Mock voice classification response
            if request.url?.path.contains("/voice/classify") == true {
                let mockResponse = ClassificationResult(
                    category: "document_generation",
                    intent: "create_document",
                    confidence: 0.85,
                    parameters: ["content": "AI document", "format": "pdf"],
                    suggestions: [],
                    rawText: "Create a PDF document about artificial intelligence",
                    normalizedText: "create pdf document artificial intelligence",
                    confidenceLevel: "high",
                    contextUsed: false,
                    preprocessingTime: 0.01,
                    classificationTime: 0.05,
                    requiresConfirmation: false
                )

                let data = try JSONEncoder().encode(mockResponse)
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!

                return (data, response)
            }

            // Mock token response
            if request.url?.path.contains("/auth/token") == true {
                let tokenResponse = TokenResponse(
                    accessToken: "mock_token",
                    tokenType: "Bearer",
                    expiresIn: 3600
                )

                let data = try JSONEncoder().encode(tokenResponse)
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!

                return (data, response)
            }

            // Default mock response
            let data = Data()
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!

            return (data, response)
        }
    }

    private class MockKeychainManager: KeychainManager {
        private var storage: [String: String] = [
            "api_key": "mock_api_key",
            "elevenlabs_api_key": "mock_elevenlabs_key",
        ]

        override func storeCredential(_ credential: String, forKey key: String) throws {
            storage[key] = credential
        }

        override func getCredential(forKey key: String) throws -> String {
            guard let credential = storage[key] else {
                throw KeychainManagerError.itemNotFound
            }
            return credential
        }

        override func deleteCredential(forKey key: String) throws {
            storage.removeValue(forKey: key)
        }
    }

    private class MockLiveKitRoom: LiveKitRoom {
        func add(delegate: RoomDelegate) {
            // Mock implementation
        }

        func connect(url: String, token: String, connectOptions: ConnectOptions?, roomOptions: RoomOptions?) async throws {
            // Mock implementation
        }

        func disconnect() async {
            // Mock implementation
        }
    }
}

// MARK: - Integration Test Infrastructure Complete
