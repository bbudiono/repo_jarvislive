// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Settings management with secure API key validation and storage
 * Issues & Complexity Summary: Secure credential management with live API validation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~350
 *   - Core Algorithm Complexity: High (Async API validation, secure storage, error handling)
 *   - Dependencies: 4 New (Foundation, KeychainManager, URLSession, Combine)
 *   - State Management Complexity: High (Multiple API states, concurrent validation)
 *   - Novelty/Uncertainty Factor: Medium (API validation patterns, error handling)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 90%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 88%
 * Justification for Estimates: Complex async operations with secure storage and live API testing
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import Foundation
import Combine

@MainActor
class SettingsManager: ObservableObject {
    // MARK: - Published Properties

    // API Keys
    @Published var claudeAPIKey: String = ""
    @Published var openaiAPIKey: String = ""
    @Published var geminiAPIKey: String = ""
    @Published var elevenLabsAPIKey: String = ""

    // LiveKit Configuration
    @Published var liveKitURL: String = ""
    @Published var liveKitToken: String = ""

    // Validation Status
    @Published var claudeStatus: ValidationStatus = .unknown
    @Published var openaiStatus: ValidationStatus = .unknown
    @Published var geminiStatus: ValidationStatus = .unknown
    @Published var elevenLabsStatus: ValidationStatus = .unknown
    @Published var liveKitStatus: ValidationStatus = .unknown

    // App Settings
    @Published var enableVoiceActivity: Bool = true
    @Published var autoSaveConversations: Bool = true
    @Published var voiceSensitivity: Double = 0.7

    // MARK: - Private Properties

    private let keychainManager: KeychainManager
    private let urlSession: URLSession

    // MARK: - Initialization

    init() {
        self.keychainManager = KeychainManager(service: "com.ablankcanvas.JarvisLive.settings")

        // Configure URL session for API validation
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 10.0
        configuration.timeoutIntervalForResource = 30.0
        self.urlSession = URLSession(configuration: configuration)
    }

    // MARK: - Settings Loading and Saving

    func loadSettings() {
        Task {
            // Load API keys
            claudeAPIKey = (try? keychainManager.getCredential(forKey: "anthropic-api-key")) ?? ""
            openaiAPIKey = (try? keychainManager.getCredential(forKey: "openai-api-key")) ?? ""
            geminiAPIKey = (try? keychainManager.getCredential(forKey: "google-api-key")) ?? ""
            elevenLabsAPIKey = (try? keychainManager.getCredential(forKey: "elevenlabs-api-key")) ?? ""

            // Load LiveKit configuration
            liveKitURL = (try? keychainManager.getCredential(forKey: "livekit-url")) ?? ""
            liveKitToken = (try? keychainManager.getCredential(forKey: "livekit-token")) ?? ""

            // Load app settings from UserDefaults
            enableVoiceActivity = UserDefaults.standard.bool(forKey: "enableVoiceActivity")
            autoSaveConversations = UserDefaults.standard.bool(forKey: "autoSaveConversations")
            voiceSensitivity = UserDefaults.standard.double(forKey: "voiceSensitivity")

            // Set defaults if not previously set
            if voiceSensitivity == 0 {
                voiceSensitivity = 0.7
            }
        }
    }

    func saveAllSettings() async {
        do {
            // Save API keys to keychain
            if !claudeAPIKey.isEmpty {
                try keychainManager.storeCredential(claudeAPIKey, forKey: "anthropic-api-key")
            }
            if !openaiAPIKey.isEmpty {
                try keychainManager.storeCredential(openaiAPIKey, forKey: "openai-api-key")
            }
            if !geminiAPIKey.isEmpty {
                try keychainManager.storeCredential(geminiAPIKey, forKey: "google-api-key")
            }
            if !elevenLabsAPIKey.isEmpty {
                try keychainManager.storeCredential(elevenLabsAPIKey, forKey: "elevenlabs-api-key")
            }

            // Save LiveKit configuration
            if !liveKitURL.isEmpty {
                try keychainManager.storeCredential(liveKitURL, forKey: "livekit-url")
            }
            if !liveKitToken.isEmpty {
                try keychainManager.storeCredential(liveKitToken, forKey: "livekit-token")
            }

            // Save app settings to UserDefaults
            UserDefaults.standard.set(enableVoiceActivity, forKey: "enableVoiceActivity")
            UserDefaults.standard.set(autoSaveConversations, forKey: "autoSaveConversations")
            UserDefaults.standard.set(voiceSensitivity, forKey: "voiceSensitivity")

            print("✅ Settings saved successfully")
        } catch {
            print("❌ Failed to save settings: \(error)")
        }
    }

    func clearAllSettings() async {
        do {
            // Clear keychain
            try keychainManager.clearAllCredentials()

            // Clear UserDefaults
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "enableVoiceActivity")
            defaults.removeObject(forKey: "autoSaveConversations")
            defaults.removeObject(forKey: "voiceSensitivity")

            // Reset UI state
            claudeAPIKey = ""
            openaiAPIKey = ""
            geminiAPIKey = ""
            elevenLabsAPIKey = ""
            liveKitURL = ""
            liveKitToken = ""

            claudeStatus = .unknown
            openaiStatus = .unknown
            geminiStatus = .unknown
            elevenLabsStatus = .unknown
            liveKitStatus = .unknown

            enableVoiceActivity = true
            autoSaveConversations = true
            voiceSensitivity = 0.7

            print("✅ All settings cleared")
        } catch {
            print("❌ Failed to clear settings: \(error)")
        }
    }

    // MARK: - API Key Validation

    func validateAPIKey(_ provider: APIProvider) async {
        switch provider {
        case .claude:
            claudeStatus = .testing
            claudeStatus = await validateClaudeAPI()
        case .openai:
            openaiStatus = .testing
            openaiStatus = await validateOpenAIAPI()
        case .gemini:
            geminiStatus = .testing
            geminiStatus = await validateGeminiAPI()
        case .elevenlabs:
            elevenLabsStatus = .testing
            elevenLabsStatus = await validateElevenLabsAPI()
        }
    }

    private func validateClaudeAPI() async -> ValidationStatus {
        guard !claudeAPIKey.isEmpty else { return .invalid }

        do {
            let url = URL(string: "https://api.anthropic.com/v1/messages")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(claudeAPIKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

            // Simple test message
            let testMessage: [String: Any] = [
                "model": "claude-3-5-sonnet-20241022",
                "max_tokens": 10,
                "messages": [
                    ["role": "user", "content": "Test"]
                ],
            ]

            request.httpBody = try JSONSerialization.data(withJSONObject: testMessage)

            let (_, response) = try await urlSession.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ Claude API key validated successfully")
                    return .valid
                case 401:
                    print("❌ Claude API key is invalid (401 Unauthorized)")
                    return .invalid
                default:
                    print("⚠️ Claude API validation returned status: \(httpResponse.statusCode)")
                    return .invalid
                }
            }

            return .invalid
        } catch {
            print("❌ Claude API validation failed: \(error)")
            return .invalid
        }
    }

    private func validateOpenAIAPI() async -> ValidationStatus {
        guard !openaiAPIKey.isEmpty else { return .invalid }

        do {
            let url = URL(string: "https://api.openai.com/v1/models")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(openaiAPIKey)", forHTTPHeaderField: "Authorization")

            let (_, response) = try await urlSession.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ OpenAI API key validated successfully")
                    return .valid
                case 401:
                    print("❌ OpenAI API key is invalid (401 Unauthorized)")
                    return .invalid
                default:
                    print("⚠️ OpenAI API validation returned status: \(httpResponse.statusCode)")
                    return .invalid
                }
            }

            return .invalid
        } catch {
            print("❌ OpenAI API validation failed: \(error)")
            return .invalid
        }
    }

    private func validateGeminiAPI() async -> ValidationStatus {
        guard !geminiAPIKey.isEmpty else { return .invalid }

        do {
            let url = URL(string: "https://generativelanguage.googleapis.com/v1/models?key=\(geminiAPIKey)")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            let (_, response) = try await urlSession.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ Google Gemini API key validated successfully")
                    return .valid
                case 401, 403:
                    print("❌ Google Gemini API key is invalid (401/403 Unauthorized)")
                    return .invalid
                default:
                    print("⚠️ Google Gemini API validation returned status: \(httpResponse.statusCode)")
                    return .invalid
                }
            }

            return .invalid
        } catch {
            print("❌ Google Gemini API validation failed: \(error)")
            return .invalid
        }
    }

    private func validateElevenLabsAPI() async -> ValidationStatus {
        guard !elevenLabsAPIKey.isEmpty else { return .invalid }

        do {
            let url = URL(string: "https://api.elevenlabs.io/v1/user")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(elevenLabsAPIKey, forHTTPHeaderField: "xi-api-key")

            let (_, response) = try await urlSession.data(for: request)

            if let httpResponse = response as? HTTPURLResponse {
                switch httpResponse.statusCode {
                case 200...299:
                    print("✅ ElevenLabs API key validated successfully")
                    return .valid
                case 401:
                    print("❌ ElevenLabs API key is invalid (401 Unauthorized)")
                    return .invalid
                default:
                    print("⚠️ ElevenLabs API validation returned status: \(httpResponse.statusCode)")
                    return .invalid
                }
            }

            return .invalid
        } catch {
            print("❌ ElevenLabs API validation failed: \(error)")
            return .invalid
        }
    }

    // MARK: - LiveKit Validation

    func validateLiveKitConnection() async {
        guard !liveKitURL.isEmpty && !liveKitToken.isEmpty else {
            liveKitStatus = .invalid
            return
        }

        liveKitStatus = .testing

        do {
            // Basic URL validation
            guard let url = URL(string: liveKitURL),
                  url.scheme == "wss" || url.scheme == "ws" else {
                liveKitStatus = .invalid
                print("❌ Invalid LiveKit URL format")
                return
            }

            // Token validation (basic JWT structure check)
            let tokenComponents = liveKitToken.components(separatedBy: ".")
            guard tokenComponents.count == 3 else {
                liveKitStatus = .invalid
                print("❌ Invalid LiveKit token format")
                return
            }

            // For now, if URL and token format are valid, consider it valid
            // In a real implementation, you might test the actual WebSocket connection
            liveKitStatus = .valid
            print("✅ LiveKit configuration validated")
        } catch {
            print("❌ LiveKit validation failed: \(error)")
            liveKitStatus = .invalid
        }
    }

    // MARK: - Helper Methods

    func hasValidAPIKey(for provider: APIProvider) -> Bool {
        switch provider {
        case .claude:
            return !claudeAPIKey.isEmpty && claudeStatus == .valid
        case .openai:
            return !openaiAPIKey.isEmpty && openaiStatus == .valid
        case .gemini:
            return !geminiAPIKey.isEmpty && geminiStatus == .valid
        case .elevenlabs:
            return !elevenLabsAPIKey.isEmpty && elevenLabsStatus == .valid
        }
    }

    func hasAnyValidAPIKey() -> Bool {
        return hasValidAPIKey(for: .claude) || hasValidAPIKey(for: .openai) || hasValidAPIKey(for: .gemini)
    }

    func getValidatedAPIKeys() -> [String: String] {
        var keys: [String: String] = [:]

        if hasValidAPIKey(for: .claude) {
            keys["anthropic-api-key"] = claudeAPIKey
        }
        if hasValidAPIKey(for: .openai) {
            keys["openai-api-key"] = openaiAPIKey
        }
        if hasValidAPIKey(for: .gemini) {
            keys["google-api-key"] = geminiAPIKey
        }
        if hasValidAPIKey(for: .elevenlabs) {
            keys["elevenlabs-api-key"] = elevenLabsAPIKey
        }

        return keys
    }

    func validateAllAPIKeys() async {
        // Validate all API keys concurrently
        await withTaskGroup(of: Void.self) { group in
            if !claudeAPIKey.isEmpty {
                group.addTask {
                    await self.validateAPIKey(.claude)
                }
            }

            if !openaiAPIKey.isEmpty {
                group.addTask {
                    await self.validateAPIKey(.openai)
                }
            }

            if !geminiAPIKey.isEmpty {
                group.addTask {
                    await self.validateAPIKey(.gemini)
                }
            }

            if !elevenLabsAPIKey.isEmpty {
                group.addTask {
                    await self.validateAPIKey(.elevenlabs)
                }
            }
        }

        // Validate LiveKit if configured
        if !liveKitURL.isEmpty && !liveKitToken.isEmpty {
            await validateLiveKitConnection()
        }
    }
}

// MARK: - Settings Manager Extensions

extension SettingsManager {
    // MARK: - Quick Setup Methods

    func setupForDevelopment() async {
        // Set up reasonable defaults for development
        liveKitURL = "wss://agents-playground.livekit.io"
        enableVoiceActivity = true
        autoSaveConversations = false  // Don't save in development
        voiceSensitivity = 0.5

        await saveAllSettings()
        print("✅ Development settings configured")
    }

    func setupForProduction() async {
        // Production settings
        enableVoiceActivity = true
        autoSaveConversations = true
        voiceSensitivity = 0.7

        await saveAllSettings()
        print("✅ Production settings configured")
    }

    // MARK: - Export/Import Settings

    func exportSettings() -> [String: Any] {
        return [
            "enableVoiceActivity": enableVoiceActivity,
            "autoSaveConversations": autoSaveConversations,
            "voiceSensitivity": voiceSensitivity,
            "liveKitURL": liveKitURL,
            // Note: API keys are not exported for security
            "exportDate": Date().timeIntervalSince1970,
        ]
    }

    func importSettings(from data: [String: Any]) async {
        if let enableVA = data["enableVoiceActivity"] as? Bool {
            enableVoiceActivity = enableVA
        }
        if let autoSave = data["autoSaveConversations"] as? Bool {
            autoSaveConversations = autoSave
        }
        if let sensitivity = data["voiceSensitivity"] as? Double {
            voiceSensitivity = sensitivity
        }
        if let url = data["liveKitURL"] as? String {
            liveKitURL = url
        }

        await saveAllSettings()
        print("✅ Settings imported successfully")
    }
}
