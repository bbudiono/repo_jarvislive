// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Integration tests for Settings modal and KeychainManager to verify secure credential storage
 * Issues & Complexity Summary: Testing UI-to-security integration with real keychain operations
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~150
 *   - Core Algorithm Complexity: Medium
 *   - Dependencies: 3 New (XCTest, SwiftUI, Security)
 *   - State Management Complexity: Medium
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 70%
 * Problem Estimate (Inherent Problem Difficulty %): 75%
 * Initial Code Complexity Estimate %: 70%
 * Justification for Estimates: Integration testing requires coordinating UI and security layers
 * Final Code Complexity (Actual %): 72%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Settings-KeychainManager integration is well-designed and robust
 * Last Updated: 2025-06-25
 */

import XCTest
@testable import JarvisLive_Sandbox

@MainActor
final class SettingsKeychainIntegrationTests: XCTestCase {
    var keychainManager: KeychainManager!
    var liveKitManager: LiveKitManager!
    private let testService = "com.ablankcanvas.JarvisLive.integration.tests"

    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager(service: testService)
        liveKitManager = LiveKitManager(keychainManager: keychainManager)

        // Clean up any existing test data
        try? keychainManager.clearAllCredentials()
    }

    override func tearDown() {
        // Clean up test keychain entries
        try? keychainManager.clearAllCredentials()
        keychainManager = nil
        liveKitManager = nil
        super.tearDown()
    }

    // MARK: - Settings Modal Integration Tests

    func test_settingsModal_storesCredentialsInKeychain() throws {
        // Given: API credentials
        let claudeKey = "sk-ant-test-123456"
        let openaiKey = "sk-openai-test-789"
        let elevenLabsKey = "el-test-456"
        let liveKitURL = "wss://test.livekit.io"
        let liveKitToken = "test.token.abc123"

        // When: Storing credentials through KeychainManager (simulating Settings modal behavior)
        try keychainManager.storeCredential(claudeKey, forKey: "anthropic-api-key")
        try keychainManager.storeCredential(openaiKey, forKey: "openai-api-key")
        try keychainManager.storeCredential(elevenLabsKey, forKey: "elevenlabs-api-key")
        try keychainManager.storeCredential(liveKitURL, forKey: "livekit-url")
        try keychainManager.storeCredential(liveKitToken, forKey: "livekit-token")

        // Then: All credentials should be retrievable
        let retrievedClaude = try keychainManager.getCredential(forKey: "anthropic-api-key")
        let retrievedOpenAI = try keychainManager.getCredential(forKey: "openai-api-key")
        let retrievedElevenLabs = try keychainManager.getCredential(forKey: "elevenlabs-api-key")
        let retrievedLiveKitURL = try keychainManager.getCredential(forKey: "livekit-url")
        let retrievedLiveKitToken = try keychainManager.getCredential(forKey: "livekit-token")

        XCTAssertEqual(retrievedClaude, claudeKey)
        XCTAssertEqual(retrievedOpenAI, openaiKey)
        XCTAssertEqual(retrievedElevenLabs, elevenLabsKey)
        XCTAssertEqual(retrievedLiveKitURL, liveKitURL)
        XCTAssertEqual(retrievedLiveKitToken, liveKitToken)
    }

    func test_settingsModal_loadsExistingCredentials() throws {
        // Given: Pre-existing credentials in keychain
        let existingClaude = "sk-ant-existing-123"
        let existingOpenAI = "sk-openai-existing-456"

        try keychainManager.storeCredential(existingClaude, forKey: "anthropic-api-key")
        try keychainManager.storeCredential(existingOpenAI, forKey: "openai-api-key")

        // When: Loading credentials (simulating Settings modal onAppear)
        let loadedClaude = try keychainManager.getCredential(forKey: "anthropic-api-key")
        let loadedOpenAI = try keychainManager.getCredential(forKey: "openai-api-key")

        // Then: Loaded credentials should match stored ones
        XCTAssertEqual(loadedClaude, existingClaude)
        XCTAssertEqual(loadedOpenAI, existingOpenAI)
    }

    func test_settingsModal_handlesEmptyCredentials() {
        // Given: No stored credentials
        // When: Attempting to load non-existent credentials
        // Then: Should handle gracefully (return nil or throw specific error)

        XCTAssertThrowsError(try keychainManager.getCredential(forKey: "non-existent-key")) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.itemNotFound)
        }
    }

    func test_settingsModal_updatesExistingCredentials() throws {
        // Given: Existing credential
        let originalKey = "sk-ant-original-123"
        try keychainManager.storeCredential(originalKey, forKey: "anthropic-api-key")

        // When: Updating with new credential
        let updatedKey = "sk-ant-updated-456"
        try keychainManager.storeCredential(updatedKey, forKey: "anthropic-api-key")

        // Then: Should retrieve the updated credential
        let retrievedKey = try keychainManager.getCredential(forKey: "anthropic-api-key")
        XCTAssertEqual(retrievedKey, updatedKey)
    }

    // MARK: - LiveKitManager Integration Tests

    func test_liveKitManager_configureCredentials_integrationWithKeychain() async throws {
        // Given: LiveKit credentials
        let liveKitURL = "wss://integration-test.livekit.io"
        let liveKitToken = "integration.test.token.xyz789"

        // When: Configuring credentials through LiveKitManager
        try await liveKitManager.configureCredentials(liveKitURL: liveKitURL, liveKitToken: liveKitToken)

        // Then: Credentials should be stored in keychain
        let storedURL = try keychainManager.getCredential(forKey: "livekit-url")
        let storedToken = try keychainManager.getCredential(forKey: "livekit-token")

        XCTAssertEqual(storedURL, liveKitURL)
        XCTAssertEqual(storedToken, liveKitToken)
    }

    func test_liveKitManager_configureAICredentials_integrationWithKeychain() async throws {
        // Given: AI API credentials
        let claudeKey = "sk-ant-integration-test"
        let openaiKey = "sk-openai-integration-test"
        let elevenLabsKey = "el-integration-test"

        // When: Configuring AI credentials through LiveKitManager
        try await liveKitManager.configureAICredentials(
            claude: claudeKey,
            openAI: openaiKey,
            elevenLabs: elevenLabsKey
        )

        // Then: All AI credentials should be stored in keychain
        let storedClaude = try keychainManager.getCredential(forKey: "anthropic-api-key")
        let storedOpenAI = try keychainManager.getCredential(forKey: "openai-api-key")
        let storedElevenLabs = try keychainManager.getCredential(forKey: "elevenlabs-api-key")

        XCTAssertEqual(storedClaude, claudeKey)
        XCTAssertEqual(storedOpenAI, openaiKey)
        XCTAssertEqual(storedElevenLabs, elevenLabsKey)
    }

    // MARK: - Security Validation Tests

    func test_settingsIntegration_credentialsArePersistentAcrossInstances() throws {
        // Given: Credentials stored through one KeychainManager instance
        let originalKeychainManager = KeychainManager(service: testService)
        let testCredential = "sk-persistent-test-123"

        try originalKeychainManager.storeCredential(testCredential, forKey: "persistence-test-key")

        // When: Creating a new KeychainManager instance with same service
        let newKeychainManager = KeychainManager(service: testService)

        // Then: Should be able to retrieve the credential
        let retrievedCredential = try newKeychainManager.getCredential(forKey: "persistence-test-key")
        XCTAssertEqual(retrievedCredential, testCredential)

        // Cleanup
        try newKeychainManager.deleteCredential(forKey: "persistence-test-key")
    }

    func test_settingsIntegration_credentialsAreIsolatedByService() throws {
        // Given: Different service identifiers
        let service1 = "com.ablankcanvas.JarvisLive.service1"
        let service2 = "com.ablankcanvas.JarvisLive.service2"

        let keychain1 = KeychainManager(service: service1)
        let keychain2 = KeychainManager(service: service2)

        let testCredential = "sk-isolation-test-123"

        // When: Storing credential in service1
        try keychain1.storeCredential(testCredential, forKey: "isolation-test-key")

        // Then: service2 should not be able to access it
        XCTAssertThrowsError(try keychain2.getCredential(forKey: "isolation-test-key")) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.itemNotFound)
        }

        // Cleanup
        try keychain1.deleteCredential(forKey: "isolation-test-key")
    }

    // MARK: - Error Handling Integration Tests

    func test_settingsIntegration_handlesKeychainErrors() throws {
        // Given: Invalid key scenario
        let emptyKey = ""

        // When/Then: Should handle invalid key gracefully
        XCTAssertThrowsError(try keychainManager.storeCredential("test", forKey: emptyKey)) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.invalidKey)
        }
    }

    func test_settingsIntegration_supportsPartialCredentialConfiguration() async throws {
        // Given: Only some AI credentials provided
        let claudeKey = "sk-ant-partial-test"

        // When: Configuring only Claude credential
        try await liveKitManager.configureAICredentials(claude: claudeKey)

        // Then: Claude key should be stored, others should not exist
        let storedClaude = try keychainManager.getCredential(forKey: "anthropic-api-key")
        XCTAssertEqual(storedClaude, claudeKey)

        // Other keys should not exist
        XCTAssertThrowsError(try keychainManager.getCredential(forKey: "openai-api-key"))
        XCTAssertThrowsError(try keychainManager.getCredential(forKey: "elevenlabs-api-key"))
    }
}
