// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: TDD tests for KeychainManager - TRUE RED PHASE IMPLEMENTATION
 * Issues & Complexity Summary: Security framework testing with iOS Keychain integration
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: High
 *   - Dependencies: 3 New (XCTest, Security, LocalAuthentication)
 *   - State Management Complexity: High
 *   - Novelty/Uncertainty Factor: Medium
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Security testing requires careful setup and validation
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: Fixed module import, implementing true TDD RED phase
 * Last Updated: 2025-06-25
 */

import XCTest
@testable import JarvisLive_Sandbox

final class KeychainManagerTests: XCTestCase {
    var keychainManager: KeychainManager!
    private let testService = "com.ablankcanvas.JarvisLive.Sandbox.tests"
    private let testKey = "test_api_key"
    private let testCredential = "sk-test-1234567890abcdef"

    override func setUp() {
        super.setUp()
        keychainManager = KeychainManager(service: testService)

        // Clean up any existing test data
        try? keychainManager.clearAllCredentials()
    }

    override func tearDown() {
        // Clean up test keychain entries
        try? keychainManager.clearAllCredentials()
        keychainManager = nil
        super.tearDown()
    }

    // MARK: - TDD RED PHASE: Basic Credential Storage

    func test_storeAndRetrieve_successfullyStoresAndRetrievesCredential() throws {
        // Given: A credential to store
        // When: Storing and retrieving a credential
        try keychainManager.storeCredential(testCredential, forKey: testKey)
        let retrievedCredential = try keychainManager.getCredential(forKey: testKey)

        // Then: Retrieved credential should match stored credential
        XCTAssertEqual(retrievedCredential, testCredential, "Stored and retrieved credentials should match")
    }

    func test_getCredential_forNonExistentKey_throwsItemNotFound() {
        // Given: A non-existent key
        let nonExistentKey = "non_existent_key"

        // When/Then: Attempting to retrieve should throw itemNotFound error
        XCTAssertThrowsError(try keychainManager.getCredential(forKey: nonExistentKey)) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.itemNotFound)
        }
    }

    func test_storeCredential_withEmptyKey_throwsInvalidKey() {
        // Given: An empty key
        let emptyKey = ""

        // When/Then: Storing with empty key should throw invalidKey error
        XCTAssertThrowsError(try keychainManager.storeCredential(testCredential, forKey: emptyKey)) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.invalidKey)
        }
    }

    func test_updateCredential_replacesExistingValue() throws {
        // Given: An existing credential
        try keychainManager.storeCredential(testCredential, forKey: testKey)

        // When: Updating with new value
        let updatedCredential = "sk-updated-9876543210fedcba"
        try keychainManager.storeCredential(updatedCredential, forKey: testKey)

        // Then: Retrieved credential should be the updated value
        let retrievedCredential = try keychainManager.getCredential(forKey: testKey)
        XCTAssertEqual(retrievedCredential, updatedCredential, "Updated credential should be retrieved")
    }

    func test_deleteCredential_removesStoredCredential() throws {
        // Given: A stored credential
        try keychainManager.storeCredential(testCredential, forKey: testKey)

        // When: Deleting the credential
        try keychainManager.deleteCredential(forKey: testKey)

        // Then: Credential should no longer exist
        XCTAssertFalse(keychainManager.credentialExists(forKey: testKey), "Deleted credential should not exist")

        // And retrieving should throw itemNotFound
        XCTAssertThrowsError(try keychainManager.getCredential(forKey: testKey)) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.itemNotFound)
        }
    }

    func test_credentialExists_returnsTrueForExistingCredential() throws {
        // Given: A stored credential
        try keychainManager.storeCredential(testCredential, forKey: testKey)

        // When: Checking if credential exists
        let exists = keychainManager.credentialExists(forKey: testKey)

        // Then: Should return true
        XCTAssertTrue(exists, "Stored credential should exist")
    }

    func test_credentialExists_returnsFalseForNonExistentCredential() {
        // Given: No stored credential
        // When: Checking if credential exists
        let exists = keychainManager.credentialExists(forKey: "non_existent_key")

        // Then: Should return false
        XCTAssertFalse(exists, "Non-existent credential should not exist")
    }

    // MARK: - TDD RED PHASE: Bulk Operations

    func test_storeCredentials_storesMultipleCredentials() throws {
        // Given: Multiple credentials to store
        let credentials = [
            "anthropic_key": "sk-ant-test-123",
            "openai_key": "sk-openai-test-456",
            "elevenlabs_key": "el-test-789",
        ]

        // When: Storing multiple credentials
        try keychainManager.storeCredentials(credentials)

        // Then: All credentials should be retrievable
        for (key, expectedValue) in credentials {
            let retrievedValue = try keychainManager.getCredential(forKey: key)
            XCTAssertEqual(retrievedValue, expectedValue, "Credential for \(key) should match")
        }
    }

    func test_getAllCredentials_returnsAllStoredCredentials() throws {
        // Given: Multiple stored credentials
        let credentials = [
            "key1": "value1",
            "key2": "value2",
            "key3": "value3",
        ]
        try keychainManager.storeCredentials(credentials)

        // When: Getting all credentials
        let retrievedCredentials = try keychainManager.getAllCredentials()

        // Then: Should return all stored credentials
        XCTAssertEqual(retrievedCredentials.count, credentials.count, "Should return all credentials")
        for (key, expectedValue) in credentials {
            XCTAssertEqual(retrievedCredentials[key], expectedValue, "Credential for \(key) should match")
        }
    }

    func test_clearAllCredentials_removesAllStoredCredentials() throws {
        // Given: Multiple stored credentials
        let credentials = [
            "key1": "value1",
            "key2": "value2",
        ]
        try keychainManager.storeCredentials(credentials)

        // When: Clearing all credentials
        try keychainManager.clearAllCredentials()

        // Then: No credentials should exist
        let remainingCredentials = try keychainManager.getAllCredentials()
        XCTAssertTrue(remainingCredentials.isEmpty, "All credentials should be cleared")
    }

    // MARK: - TDD RED PHASE: API Key Convenience Methods

    func test_storeAPIKey_storesWithStandardizedKey() throws {
        // Given: An API key for a service
        let service = "anthropic"
        let apiKey = "sk-ant-test-key"

        // When: Storing API key
        try keychainManager.storeAPIKey(apiKey, forService: service)

        // Then: Should be retrievable with service name
        let retrievedKey = try keychainManager.getAPIKey(forService: service)
        XCTAssertEqual(retrievedKey, apiKey, "API key should be stored and retrieved correctly")
    }

    func test_getAPIKey_forNonExistentService_throwsItemNotFound() {
        // Given: A non-existent service
        let nonExistentService = "nonexistent"

        // When/Then: Should throw itemNotFound error
        XCTAssertThrowsError(try keychainManager.getAPIKey(forService: nonExistentService)) { error in
            guard let keychainError = error as? KeychainManagerError else {
                XCTFail("Should throw KeychainManagerError")
                return
            }
            XCTAssertEqual(keychainError, KeychainManagerError.itemNotFound)
        }
    }

    func test_storeJarvisAPIKeys_storesAllSupportedServices() throws {
        // Given: API keys for all supported services
        let apiKeys = [
            "anthropic": "sk-ant-test",
            "openai": "sk-openai-test",
            "elevenlabs": "el-test",
            "livekit": "lk-test",
        ]

        // When: Storing Jarvis API keys
        try keychainManager.storeJarvisAPIKeys(apiKeys)

        // Then: All keys should be stored
        for (service, expectedKey) in apiKeys {
            let retrievedKey = try keychainManager.getAPIKey(forService: service)
            XCTAssertEqual(retrievedKey, expectedKey, "API key for \(service) should match")
        }
    }

    func test_getJarvisAPIKeys_returnsOnlyExistingKeys() throws {
        // Given: Some API keys stored
        try keychainManager.storeAPIKey("sk-ant-test", forService: "anthropic")
        try keychainManager.storeAPIKey("sk-openai-test", forService: "openai")

        // When: Getting Jarvis API keys
        let retrievedKeys = try keychainManager.getJarvisAPIKeys()

        // Then: Should return only existing keys
        XCTAssertEqual(retrievedKeys.count, 2, "Should return 2 stored keys")
        XCTAssertEqual(retrievedKeys["anthropic"], "sk-ant-test")
        XCTAssertEqual(retrievedKeys["openai"], "sk-openai-test")
    }

    // MARK: - ADVERSARIAL SECURITY TESTS (Task 4.2)

    func testLogoutRemovesAllSensitiveData() throws {
        // GIVEN: Multiple sensitive credentials are stored (API keys, user tokens, session data)
        let sensitiveCredentials = [
            "anthropic_api_key": "sk-ant-real-key-12345",
            "openai_api_key": "sk-openai-real-key-67890",
            "elevenlabs_api_key": "el-real-key-abcdef",
            "livekit_api_key": "lk-real-key-xyz789",
            "user_session_token": "session-token-sensitive-data",
            "user_refresh_token": "refresh-token-sensitive-data",
            "user_password_hash": "password-hash-sensitive-data"
        ]
        
        try keychainManager.storeCredentials(sensitiveCredentials)
        
        // Verify all credentials are stored
        for (key, _) in sensitiveCredentials {
            XCTAssertTrue(keychainManager.credentialExists(forKey: key), "Credential \(key) should exist before logout")
        }
        
        // WHEN: User logs out - this should trigger complete sensitive data removal
        try keychainManager.performSecureLogout()
        
        // THEN: ALL sensitive data must be completely removed from keychain
        for (key, _) in sensitiveCredentials {
            XCTAssertFalse(keychainManager.credentialExists(forKey: key), "Credential \(key) MUST NOT exist after logout")
            
            // Verify that attempting to retrieve returns nil/throws error
            XCTAssertThrowsError(try keychainManager.getCredential(forKey: key)) { error in
                guard let keychainError = error as? KeychainManagerError else {
                    XCTFail("Should throw KeychainManagerError for \(key)")
                    return
                }
                XCTAssertEqual(keychainError, KeychainManagerError.itemNotFound, "Should throw itemNotFound for \(key)")
            }
        }
        
        // Verify keychain is completely empty
        let remainingCredentials = try keychainManager.getAllCredentials()
        XCTAssertTrue(remainingCredentials.isEmpty, "CRITICAL: Keychain must be completely empty after secure logout")
        
        // ADDITIONAL ADVERSARIAL CHECK: Attempt to retrieve with raw keychain queries
        // This tests that data is actually removed, not just hidden
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: testService,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // Should return errSecItemNotFound (no items found) or empty array
        XCTAssertTrue(status == errSecItemNotFound, "Raw keychain query should find no items after secure logout")
    }

    // MARK: - Performance Tests

    func test_credentialStoragePerformance() throws {
        let key = "performance_test"
        let value = "performance_value"

        measure {
            try? keychainManager.storeCredential(value, forKey: key)
        }
    }

    func test_credentialRetrievalPerformance() throws {
        // Setup: Store credential first
        try keychainManager.storeCredential(testCredential, forKey: testKey)

        measure {
            _ = try? keychainManager.getCredential(forKey: testKey)
        }
    }
}
