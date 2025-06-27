// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/*
* Purpose: Data models for live authentication API integration
* Issues & Complexity Summary: Request/response models for Python backend authentication
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~100
  - Core Algorithm Complexity: Low (data models)
  - Dependencies: 1 New (Foundation)
  - State Management Complexity: Low (stateless models)
  - Novelty/Uncertainty Factor: Low (standard API models)
* AI Pre-Task Self-Assessment: 95%
* Problem Estimate: 40%
* Initial Code Complexity Estimate: 45%
* Final Code Complexity: 42%
* Overall Result Score: 98%
* Key Variances/Learnings: Standard Codable implementation
* Last Updated: 2025-06-27
*/

import Foundation

// MARK: - Authentication Request Models

/// Login request model for Python backend authentication
struct LoginRequest: Codable {
    let username: String
    let password: String

    enum CodingKeys: String, CodingKey {
        case username
        case password
    }
}

/// Token refresh request model
struct TokenRefreshRequest: Codable {
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

// MARK: - Authentication Response Models

/// Authentication response from Python backend
struct AuthenticationResponse: Codable {
    let accessToken: String
    let refreshToken: String?
    let tokenType: String
    let expiresIn: Int?
    let user: UserInfo?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
    }
}

/// User information from authentication response
struct UserInfo: Codable {
    let id: String
    let username: String
    let email: String?
    let fullName: String?
    let permissions: [String]?

    enum CodingKeys: String, CodingKey {
        case id
        case username
        case email
        case fullName = "full_name"
        case permissions
    }
}

/// Token validation response
struct TokenValidationResponse: Codable {
    let isValid: Bool
    let expiresAt: Date?
    let user: UserInfo?

    enum CodingKeys: String, CodingKey {
        case isValid = "is_valid"
        case expiresAt = "expires_at"
        case user
    }
}

// MARK: - Error Response Models

/// Error response from Python backend
struct APIErrorResponse: Codable {
    let error: String
    let message: String
    let details: [String: String]?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case error
        case message
        case details
        case code
    }
}

// MARK: - Helper Extensions

extension AuthenticationResponse {
    /// Check if the response indicates successful authentication
    var isSuccessful: Bool {
        return !accessToken.isEmpty && tokenType.lowercased() == "bearer"
    }

    /// Get the expiration date for the access token
    var accessTokenExpirationDate: Date? {
        guard let expiresIn = expiresIn else { return nil }
        return Date().addingTimeInterval(TimeInterval(expiresIn))
    }
}

extension UserInfo {
    /// Check if user has a specific permission
    func hasPermission(_ permission: String) -> Bool {
        return permissions?.contains(permission) ?? false
    }

    /// Get display name (full name or username as fallback)
    var displayName: String {
        return fullName?.isEmpty == false ? fullName! : username
    }
}

extension TokenValidationResponse {
    /// Check if token is valid and not expired
    var isValidAndNotExpired: Bool {
        guard isValid else { return false }

        if let expiresAt = expiresAt {
            return expiresAt > Date()
        }

        return true
    }
}

// MARK: - Voice Classification Request Models

/// Voice classification request for Python backend
/// This is the canonical definition used throughout the app
struct VoiceClassificationRequest: Codable {
    let text: String
    let userId: String
    let sessionId: String
    let useContext: Bool
    let includeSuggestions: Bool

    enum CodingKeys: String, CodingKey {
        case text
        case userId = "user_id"
        case sessionId = "session_id"
        case useContext = "use_context"
        case includeSuggestions = "include_suggestions"
    }
}
