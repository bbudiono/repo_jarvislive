// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Mock KeychainManager for testing VoiceCommandPipeline
 * Issues & Complexity Summary: Simple mock for secure credential storage simulation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~80
 *   - Core Algorithm Complexity: Low (In-memory storage mock)
 *   - Dependencies: 1 New (Foundation)
 *   - State Management Complexity: Low (Simple dictionary storage)
 *   - Novelty/Uncertainty Factor: Low (Standard mock implementation)
 * AI Pre-Task Self-Assessment: 70%
 * Problem Estimate: 60%
 * Initial Code Complexity Estimate: 65%
 * Final Code Complexity: 68%
 * Overall Result Score: 95%
 * Key Variances/Learnings: Simple mocks are often most effective for testing
 * Last Updated: 2025-06-26
 */

import Foundation
@testable import JarvisLiveSandbox

final class MockKeychainManager {
    // MARK: - Mock Storage

    private var storage: [String: String] = [:]
    private let service: String

    // MARK: - Mock Configuration

    var shouldThrowError: Bool = false
    var mockError: KeychainManagerError?

    // MARK: - Test Tracking

    var storeCallCount: Int = 0
    var getCallCount: Int = 0
    var deleteCallCount: Int = 0
    var clearCallCount: Int = 0

    // MARK: - Initialization

    init(service: String = "com.jarvis.test") {
        self.service = service

        // Pre-populate with common test credentials
        storage["api_key"] = "test_api_key_123"
        storage["jwt_token"] = "test_jwt_token_456"
        storage["user_id"] = "test_user"
    }

    // MARK: - Mock Implementation

    func storeCredential(_ credential: String, forKey key: String) throws {
        storeCallCount += 1

        if shouldThrowError {
            if let error = mockError {
                throw error
            } else {
                throw KeychainManagerError.storageFailure
            }
        }

        storage[key] = credential
    }

    func getCredential(forKey key: String) throws -> String {
        getCallCount += 1

        if shouldThrowError {
            if let error = mockError {
                throw error
            } else {
                throw KeychainManagerError.itemNotFound
            }
        }

        guard let credential = storage[key] else {
            throw KeychainManagerError.itemNotFound
        }

        return credential
    }

    func deleteCredential(forKey key: String) throws {
        deleteCallCount += 1

        if shouldThrowError {
            if let error = mockError {
                throw error
            } else {
                throw KeychainManagerError.deletionFailure
            }
        }

        storage.removeValue(forKey: key)
    }

    func credentialExists(forKey key: String) -> Bool {
        return storage[key] != nil
    }

    func clearAllCredentials() throws {
        clearCallCount += 1

        if shouldThrowError {
            if let error = mockError {
                throw error
            } else {
                throw KeychainManagerError.clearFailure
            }
        }

        storage.removeAll()
    }

    // MARK: - Helper Methods for Testing

    func reset() {
        storage.removeAll()
        storeCallCount = 0
        getCallCount = 0
        deleteCallCount = 0
        clearCallCount = 0
        shouldThrowError = false
        mockError = nil

        // Re-populate with test credentials
        storage["api_key"] = "test_api_key_123"
        storage["jwt_token"] = "test_jwt_token_456"
        storage["user_id"] = "test_user"
    }

    func configureMockError(_ error: KeychainManagerError) {
        shouldThrowError = true
        mockError = error
    }

    func setCredential(_ credential: String, forKey key: String) {
        storage[key] = credential
    }

    func getAllCredentials() -> [String: String] {
        return storage
    }
}
