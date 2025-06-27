// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Complete Settings UI for API key configuration and system settings
 * Issues & Complexity Summary: Secure API key management with validation and testing
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400
 *   - Core Algorithm Complexity: High (API validation, secure storage, async testing)
 *   - Dependencies: 5 New (SwiftUI, KeychainManager, URLSession, Combine, Security)
 *   - State Management Complexity: High (Multiple API states, validation, error handling)
 *   - Novelty/Uncertainty Factor: Medium (API key validation patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Complex UI with secure credential management and live API testing
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import SwiftUI
import Combine

struct SettingsView: View {
    @ObservedObject var liveKitManager: LiveKitManager
    @StateObject private var settingsManager = SettingsManager()
    @Environment(\.dismiss) private var dismiss

    // UI State
    @State private var isValidatingAPI = false
    @State private var showingAPITest = false
    @State private var selectedAPIProvider: APIProvider = .claude

    var body: some View {
        NavigationView {
            ZStack {
                // Background matching main app
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        settingsCard {
                            VStack(spacing: 15) {
                                HStack {
                                    Image(systemName: "gearshape.fill")
                                        .font(.title2)
                                        .foregroundColor(.cyan)

                                    Text("Settings")
                                        .font(.title)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)

                                    Spacer()
                                }

                                Text("Configure your AI providers and system settings")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                        }

                        // API Configuration Section
                        settingsCard {
                            VStack(alignment: .leading, spacing: 20) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                    Text("AI Providers")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                // Claude API Configuration
                                APIKeySection(
                                    provider: .claude,
                                    title: "Claude (Anthropic)",
                                    icon: "brain.head.profile",
                                    color: .orange,
                                    keyBinding: $settingsManager.claudeAPIKey,
                                    statusBinding: $settingsManager.claudeStatus,
                                    isValidating: $isValidatingAPI,
                                    onTest: { testAPIKey(.claude) }
                                )

                                Divider()
                                    .background(Color.white.opacity(0.3))

                                // OpenAI API Configuration
                                APIKeySection(
                                    provider: .openai,
                                    title: "OpenAI (GPT-4)",
                                    icon: "cpu",
                                    color: .green,
                                    keyBinding: $settingsManager.openaiAPIKey,
                                    statusBinding: $settingsManager.openaiStatus,
                                    isValidating: $isValidatingAPI,
                                    onTest: { testAPIKey(.openai) }
                                )

                                Divider()
                                    .background(Color.white.opacity(0.3))

                                // Google Gemini API Configuration
                                APIKeySection(
                                    provider: .gemini,
                                    title: "Google Gemini",
                                    icon: "sparkles",
                                    color: .purple,
                                    keyBinding: $settingsManager.geminiAPIKey,
                                    statusBinding: $settingsManager.geminiStatus,
                                    isValidating: $isValidatingAPI,
                                    onTest: { testAPIKey(.gemini) }
                                )

                                Divider()
                                    .background(Color.white.opacity(0.3))

                                // ElevenLabs API Configuration
                                APIKeySection(
                                    provider: .elevenlabs,
                                    title: "ElevenLabs (Voice)",
                                    icon: "speaker.wave.3",
                                    color: .blue,
                                    keyBinding: $settingsManager.elevenLabsAPIKey,
                                    statusBinding: $settingsManager.elevenLabsStatus,
                                    isValidating: $isValidatingAPI,
                                    onTest: { testAPIKey(.elevenlabs) }
                                )
                            }
                            .padding()
                        }

                        // LiveKit Configuration Section
                        settingsCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                        .foregroundColor(.cyan)
                                    Text("LiveKit Configuration")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("URL")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))

                                    SecureField("wss://your-livekit-url.com", text: $settingsManager.liveKitURL)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Token")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))

                                    SecureField("LiveKit Token", text: $settingsManager.liveKitToken)
                                        .textFieldStyle(CustomTextFieldStyle())
                                }

                                Button(action: {
                                    Task {
                                        await testLiveKitConnection()
                                    }
                                }) {
                                    HStack {
                                        if settingsManager.liveKitStatus == .testing {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        } else {
                                            Image(systemName: "antenna.radiowaves.left.and.right")
                                        }
                                        Text("Test Connection")
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.cyan.opacity(0.3))
                                    )
                                }
                                .disabled(settingsManager.liveKitStatus == .testing)

                                // Connection Status
                                HStack {
                                    Circle()
                                        .fill(statusColor(settingsManager.liveKitStatus))
                                        .frame(width: 8, height: 8)

                                    Text(statusText(settingsManager.liveKitStatus))
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding()
                        }

                        // App Settings Section
                        settingsCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "app.badge")
                                        .foregroundColor(.indigo)
                                    Text("App Settings")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                Toggle("Enable Voice Activity Detection", isOn: $settingsManager.enableVoiceActivity)
                                    .toggleStyle(SwitchToggleStyle(tint: .cyan))
                                    .foregroundColor(.white)

                                Toggle("Auto-Save Conversations", isOn: $settingsManager.autoSaveConversations)
                                    .toggleStyle(SwitchToggleStyle(tint: .cyan))
                                    .foregroundColor(.white)

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Voice Sensitivity")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))

                                    Slider(value: $settingsManager.voiceSensitivity, in: 0.1...1.0, step: 0.1)
                                        .accentColor(.cyan)

                                    Text("\(Int(settingsManager.voiceSensitivity * 100))%")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding()
                        }

                        // Actions Section
                        settingsCard {
                            VStack(spacing: 15) {
                                Button(action: saveAllSettings) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Save Settings")
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.green.opacity(0.8))
                                    )
                                }

                                Button(action: clearAllSettings) {
                                    HStack {
                                        Image(systemName: "trash.circle.fill")
                                        Text("Clear All Settings")
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.red.opacity(0.8))
                                    )
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .onAppear {
            settingsManager.loadSettings()
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }

    // MARK: - API Testing Functions

    private func testAPIKey(_ provider: APIProvider) {
        guard !isValidatingAPI else { return }

        isValidatingAPI = true
        selectedAPIProvider = provider

        Task {
            await settingsManager.validateAPIKey(provider)
            isValidatingAPI = false
        }
    }

    func testLiveKitConnection() async {
        await settingsManager.validateLiveKitConnection()
    }

    private func saveAllSettings() {
        Task {
            await settingsManager.saveAllSettings()

            // Configure LiveKit manager with new credentials
            try? await liveKitManager.configureCredentials(
                liveKitURL: settingsManager.liveKitURL,
                liveKitToken: settingsManager.liveKitToken
            )

            // Configure AI credentials
            try? await liveKitManager.configureAICredentials(
                claude: settingsManager.claudeAPIKey.isEmpty ? nil : settingsManager.claudeAPIKey,
                openAI: settingsManager.openaiAPIKey.isEmpty ? nil : settingsManager.openaiAPIKey,
                gemini: settingsManager.geminiAPIKey.isEmpty ? nil : settingsManager.geminiAPIKey,
                elevenLabs: settingsManager.elevenLabsAPIKey.isEmpty ? nil : settingsManager.elevenLabsAPIKey
            )
        }
    }

    private func clearAllSettings() {
        Task {
            await settingsManager.clearAllSettings()
        }
    }

    private func statusColor(_ status: ValidationStatus) -> Color {
        switch status {
        case .unknown: return .gray
        case .testing: return .orange
        case .valid: return .green
        case .invalid: return .red
        }
    }

    private func statusText(_ status: ValidationStatus) -> String {
        switch status {
        case .unknown: return "Not tested"
        case .testing: return "Testing..."
        case .valid: return "Valid"
        case .invalid: return "Invalid"
        }
    }
}

// MARK: - API Key Section Component

struct APIKeySection: View {
    let provider: APIProvider
    let title: String
    let icon: String
    let color: Color

    @Binding var keyBinding: String
    @Binding var statusBinding: ValidationStatus
    @Binding var isValidating: Bool
    let onTest: () -> Void

    @State private var isSecureEntry = true

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(statusText)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            HStack {
                Group {
                    if isSecureEntry {
                        SecureField("Enter API Key", text: keyBinding)
                    } else {
                        TextField("Enter API Key", text: keyBinding)
                    }
                }
                .textFieldStyle(CustomTextFieldStyle())

                Button(action: { isSecureEntry.toggle() }) {
                    Image(systemName: isSecureEntry ? "eye" : "eye.slash")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }

                Button(action: onTest) {
                    if isValidating && statusBinding == .testing {
                        ProgressView()
                            .scaleEffect(0.6)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(color)
                    }
                }
                .disabled(keyBinding.isEmpty || isValidating)
            }
        }
    }

    private var statusColor: Color {
        switch statusBinding {
        case .unknown: return .gray
        case .testing: return .orange
        case .valid: return .green
        case .invalid: return .red
        }
    }

    private var statusText: String {
        switch statusBinding {
        case .unknown: return "Not tested"
        case .testing: return "Testing..."
        case .valid: return "Valid"
        case .invalid: return "Invalid"
        }
    }
}

// MARK: - Custom Text Field Style

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .foregroundColor(.white)
            .font(.system(.body, design: .monospaced))
    }
}

// MARK: - Supporting Types

enum APIProvider: String, CaseIterable {
    case claude = "claude"
    case openai = "openai"
    case gemini = "gemini"
    case elevenlabs = "elevenlabs"

    var displayName: String {
        switch self {
        case .claude: return "Claude (Anthropic)"
        case .openai: return "OpenAI (GPT-4)"
        case .gemini: return "Google Gemini"
        case .elevenlabs: return "ElevenLabs (Voice)"
        }
    }
}

enum ValidationStatus {
    case unknown
    case testing
    case valid
    case invalid
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(liveKitManager: LiveKitManager())
            .preferredColorScheme(.dark)
    }
}
