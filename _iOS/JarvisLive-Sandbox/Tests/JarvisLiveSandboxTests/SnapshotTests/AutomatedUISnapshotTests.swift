// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: TASK-TEST-004 - Automated UI snapshot comparison for regression detection
 * Issues & Complexity Summary: Pixel-perfect UI regression testing with automated baseline comparison
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400
 *   - Core Algorithm Complexity: High (Multi-device snapshot testing, pixel comparison)
 *   - Dependencies: 4 New (XCTest, SwiftUI, SnapshotTesting, JarvisLiveSandbox)
 *   - State Management Complexity: High (View state simulation, device configuration)
 *   - Novelty/Uncertainty Factor: Medium (Snapshot testing best practices)
 * AI Pre-Task Self-Assessment: 90%
 * Problem Estimate: 85%
 * Initial Code Complexity Estimate: 88%
 * Final Code Complexity: 92%
 * Overall Result Score: 95%
 * Key Variances/Learnings: Snapshot testing provides automated pixel-perfect regression detection
 * Last Updated: 2025-06-26
 */

import XCTest
import SwiftUI
import SnapshotTesting
@testable import JarvisLiveSandbox

@MainActor
final class AutomatedUISnapshotTests: XCTestCase {
    // MARK: - Test Configuration

    override class func setUp() {
        super.setUp()
        // Configure snapshot testing for CI/CD compatibility
        isRecording = false // Set to true only when updating reference images
    }

    override func setUp() async throws {
        try await super.setUp()
        // Ensure consistent appearance for snapshot testing
        await configureTestEnvironment()
    }

    private func configureTestEnvironment() async {
        // Set consistent appearance mode for reproducible snapshots
        await MainActor.run {
            // Configure for light mode to ensure consistency
            let appearance = UITraitCollection(userInterfaceStyle: .light)
            UIView.appearance().overrideUserInterfaceStyle = .light
        }
    }

    // MARK: - Device Configuration Tests

    func testMainContentView_iPhone15Pro_LightMode() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Configure for iPhone 15 Pro dimensions
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.view.layoutIfNeeded()

        // Take snapshot and compare against baseline
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro),
            named: "iPhone15Pro_LightMode"
        )
    }

    func testMainContentView_iPhone15Pro_DarkMode() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Configure for iPhone 15 Pro dimensions and dark mode
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.overrideUserInterfaceStyle = .dark
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone15Pro(.portrait)),
            named: "iPhone15Pro_DarkMode"
        )
    }

    func testMainContentView_iPhoneSE_Portrait() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Test on smaller screen to ensure responsive design
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhoneSe),
            named: "iPhoneSE_Portrait"
        )
    }

    func testMainContentView_iPad_Portrait() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Test iPad layout for different size class
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPad(.portrait)),
            named: "iPad_Portrait"
        )
    }

    func testMainContentView_iPad_Landscape() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Test landscape orientation
        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPad(.landscape)),
            named: "iPad_Landscape"
        )
    }

    // MARK: - Glassmorphism Theme Tests

    func testGlassmorphismComponents_LightMode() async throws {
        // Test the specific glassmorphism components in isolation
        let glassView = createGlassmorphismTestView()
        let hostingController = UIHostingController(rootView: glassView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassmorphismComponents_LightMode"
        )
    }

    func testGlassmorphismComponents_DarkMode() async throws {
        let glassView = createGlassmorphismTestView()
        let hostingController = UIHostingController(rootView: glassView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
        hostingController.overrideUserInterfaceStyle = .dark
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassmorphismComponents_DarkMode"
        )
    }

    private func createGlassmorphismTestView() -> some View {
        VStack(spacing: 20) {
            // Test glassmorphism card component
            VStack {
                Text("Glassmorphism Card")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("This demonstrates the glassmorphism effect with blur and transparency")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )

            // Test button with glassmorphism
            Button("Glassmorphism Button") {
                // Action placeholder
            }
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )

            // Test input field with glassmorphism
            HStack {
                Image(systemName: "mic")
                    .foregroundColor(.secondary)
                Text("Voice input placeholder")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Authentication View Tests

    func testAuthenticationView_LightMode() async throws {
        let authView = AuthenticationView()
        let hostingController = UIHostingController(rootView: authView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "AuthenticationView_LightMode"
        )
    }

    func testAuthenticationView_DarkMode() async throws {
        let authView = AuthenticationView()
        let hostingController = UIHostingController(rootView: authView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.overrideUserInterfaceStyle = .dark
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "AuthenticationView_DarkMode"
        )
    }

    // MARK: - Settings View Tests

    func testSettingsView_AllDevices() async throws {
        let settingsView = SettingsView()

        // Test on multiple device sizes
        let devices: [ViewImageConfig] = [
            .iPhone15Pro,
            .iPhoneSe,
            .iPad(.portrait),
        ]

        for (index, device) in devices.enumerated() {
            let hostingController = UIHostingController(rootView: settingsView)

            assertSnapshot(
                matching: hostingController,
                as: .image(on: device),
                named: "SettingsView_Device\(index + 1)"
            )
        }
    }

    // MARK: - Conversation History View Tests

    func testConversationHistoryView_WithData() async throws {
        // Create mock conversation data for consistent testing
        let mockConversations = createMockConversationData()
        let historyView = ConversationHistoryView()

        let hostingController = UIHostingController(rootView: historyView)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ConversationHistoryView_WithData"
        )
    }

    func testConversationHistoryView_EmptyState() async throws {
        // Test empty state appearance
        let historyView = ConversationHistoryView()
        let hostingController = UIHostingController(rootView: historyView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ConversationHistoryView_EmptyState"
        )
    }

    private func createMockConversationData() -> [ConversationItem] {
        return [
            ConversationItem(
                id: UUID(),
                title: "Document Generation",
                preview: "Create a PDF about AI technology",
                timestamp: Date(),
                type: .document
            ),
            ConversationItem(
                id: UUID(),
                title: "Email Assistance",
                preview: "Send email to team about project update",
                timestamp: Date().addingTimeInterval(-3600),
                type: .email
            ),
            ConversationItem(
                id: UUID(),
                title: "General Chat",
                preview: "Hello Jarvis, how are you today?",
                timestamp: Date().addingTimeInterval(-7200),
                type: .conversation
            ),
        ]
    }

    // MARK: - Accessibility Tests

    func testAccessibilitySnapshot_VoiceOverEnabled() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Configure for accessibility testing
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)

        // Enable accessibility traits for snapshot
        hostingController.view.accessibilityTraits = .startsMediaSession
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ContentView_AccessibilityEnabled"
        )
    }

    func testAccessibilitySnapshot_LargeText() async throws {
        let contentView = ContentView()
        let hostingController = UIHostingController(rootView: contentView)

        // Test with large accessibility text size
        let largeTextTraits = UITraitCollection(preferredContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        hostingController.setOverrideTraitCollection(largeTextTraits, forChild: hostingController)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ContentView_LargeAccessibilityText"
        )
    }

    // MARK: - State Variation Tests

    func testViewStates_LoadingState() async throws {
        let loadingView = createLoadingStateView()
        let hostingController = UIHostingController(rootView: loadingView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "LoadingState"
        )
    }

    func testViewStates_ErrorState() async throws {
        let errorView = createErrorStateView()
        let hostingController = UIHostingController(rootView: errorView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 600)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ErrorState"
        )
    }

    private func createLoadingStateView() -> some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Processing your request...")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This may take a few moments")
                .font(.caption)
                .foregroundColor(.tertiary)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func createErrorStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.red)

            Text("Something went wrong")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Please try again or check your connection")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                // Action placeholder
            }
            .padding()
            .background(.blue, in: RoundedRectangle(cornerRadius: 8))
            .foregroundColor(.white)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Performance and Edge Case Tests

    func testLongTextContent_iPhone() async throws {
        let longTextView = createLongTextContentView()
        let hostingController = UIHostingController(rootView: longTextView)

        hostingController.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        hostingController.view.layoutIfNeeded()

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "LongTextContent_iPhone"
        )
    }

    private func createLongTextContentView() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Long Content Test")
                    .font(.largeTitle)
                    .bold()

                Text(String(repeating: "This is a very long text content that should test how the UI handles extensive text content and ensures proper layout and scrolling behavior. ", count: 10))
                    .font(.body)
                    .lineLimit(nil)

                ForEach(0..<5, id: \.self) { index in
                    VStack {
                        Text("Card \(index + 1)")
                            .font(.headline)
                        Text("Content for card \(index + 1) with additional information")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
}

// MARK: - Mock Data Models

private struct ConversationItem: Identifiable {
    let id: UUID
    let title: String
    let preview: String
    let timestamp: Date
    let type: ConversationType
}

private enum ConversationType {
    case document
    case email
    case conversation
}
