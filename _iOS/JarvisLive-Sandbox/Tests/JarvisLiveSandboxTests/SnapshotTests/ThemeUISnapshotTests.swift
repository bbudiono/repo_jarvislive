/*
* Purpose: Snapshot tests for glassmorphism theme implementation across major UI components
* Issues & Complexity Summary: Visual regression testing for theme consistency and design validation
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: Medium (snapshot testing, device matrix)
  - Dependencies: 4 New (XCTest, SnapshotTesting, SwiftUI hosting, device configurations)
  - State Management Complexity: Medium (theme states, device variants)
  - Novelty/Uncertainty Factor: Low (established snapshot testing patterns)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 75%
* Initial Code Complexity Estimate: 80%
* Final Code Complexity: 82%
* Overall Result Score: 92%
* Key Variances/Learnings: Glassmorphism effects require careful snapshot configuration for consistency
* Last Updated: 2025-06-27
*/

import XCTest
import SwiftUI
import SnapshotTesting
@testable import JarvisLive_Sandbox

final class ThemeUISnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Ensure consistent snapshot testing environment
        isRecording = false
    }

    // MARK: - GlassViewModifier Core Tests

    func testGlassViewModifier_BasicImplementation() {
        let view = VStack {
            Text("Glassmorphism Test")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .modifier(GlassViewModifier())
        .frame(width: 300, height: 200)
        .background(Color.blue.ignoresSafeArea())

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 200)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassViewModifier_Basic"
        )
    }

    func testGlassViewModifier_DarkMode() {
        let view = VStack {
            Text("Dark Mode Glass")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .modifier(GlassViewModifier())
        .frame(width: 300, height: 200)
        .background(Color.purple.ignoresSafeArea())
        .preferredColorScheme(.dark)

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        hostingController.overrideUserInterfaceStyle = .dark

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassViewModifier_DarkMode"
        )
    }

    func testGlassViewModifier_LightMode() {
        let view = VStack {
            Text("Light Mode Glass")
                .font(.headline)
                .foregroundColor(.black)
                .padding()
        }
        .modifier(GlassViewModifier())
        .frame(width: 300, height: 200)
        .background(Color.cyan.ignoresSafeArea())
        .preferredColorScheme(.light)

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 200)
        hostingController.overrideUserInterfaceStyle = .light

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassViewModifier_LightMode"
        )
    }

    // MARK: - ContentView Theme Tests

    func testContentView_GlassmorphismTheme_iPhone16Pro() {
        let liveKitManager = LiveKitManager()
        let view = ContentView(liveKitManager: liveKitManager)
            .environmentObject(liveKitManager)

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ContentView_GlassmorphismTheme_iPhone16Pro"
        )
    }

    func testContentView_GlassmorphismTheme_iPhone16ProMax() {
        let liveKitManager = LiveKitManager()
        let view = ContentView(liveKitManager: liveKitManager)
            .environmentObject(liveKitManager)

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16ProMax),
            named: "ContentView_GlassmorphismTheme_iPhone16ProMax"
        )
    }

    func testContentView_GlassmorphismTheme_iPadPro() {
        let liveKitManager = LiveKitManager()
        let view = ContentView(liveKitManager: liveKitManager)
            .environmentObject(liveKitManager)

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro11),
            named: "ContentView_GlassmorphismTheme_iPadPro"
        )
    }

    func testContentView_GlassmorphismTheme_DarkMode() {
        let liveKitManager = LiveKitManager()
        let view = ContentView(liveKitManager: liveKitManager)
            .environmentObject(liveKitManager)
            .preferredColorScheme(.dark)

        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ContentView_GlassmorphismTheme_DarkMode"
        )
    }

    // MARK: - AuthenticationView Theme Tests

    func testAuthenticationView_GlassmorphismTheme_iPhone16Pro() {
        let view = AuthenticationView()
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "AuthenticationView_GlassmorphismTheme_iPhone16Pro"
        )
    }

    func testAuthenticationView_GlassmorphismTheme_iPadPro() {
        let view = AuthenticationView()
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro11),
            named: "AuthenticationView_GlassmorphismTheme_iPadPro"
        )
    }

    // MARK: - PostClassificationFlowView Theme Tests

    func testPostClassificationFlowView_GlassmorphismTheme_HighConfidence() {
        let result = ClassificationResult.mockHighConfidenceDocument()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlowView_GlassmorphismTheme_HighConfidence"
        )
    }

    func testPostClassificationFlowView_GlassmorphismTheme_MediumConfidence() {
        let result = ClassificationResult.mockMediumConfidenceEmail()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlowView_GlassmorphismTheme_MediumConfidence"
        )
    }

    func testPostClassificationFlowView_GlassmorphismTheme_DarkMode() {
        let result = ClassificationResult.mockHighConfidenceCalendar()
        let view = PostClassificationFlowView(classificationResult: result)
            .preferredColorScheme(.dark)
        let hostingController = UIHostingController(rootView: view)
        hostingController.overrideUserInterfaceStyle = .dark

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlowView_GlassmorphismTheme_DarkMode"
        )
    }

    // MARK: - Glass Card Component Tests

    func testGlassmorphicCard_DocumentGeneration() {
        let view = VStack(spacing: 20) {
            // Mock glassmorphic card from ContentView
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                    Text("Document Generation")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Text("Create a PDF document about quarterly results")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(width: 350, height: 150)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 350, height: 150)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassmorphicCard_DocumentGeneration"
        )
    }

    func testGlassmorphicCard_EmailManagement() {
        let view = VStack(spacing: 20) {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    Text("Email Management")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }

                Text("Send email to team about meeting")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .frame(width: 350, height: 150)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.1),
                    Color(red: 0.1, green: 0.3, blue: 0.2),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 350, height: 150)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "GlassmorphicCard_EmailManagement"
        )
    }

    // MARK: - Accessibility Theme Tests

    func testGlassmorphism_AccessibilityHighContrast() {
        let view = VStack {
            Text("High Contrast Mode")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .modifier(GlassViewModifier())
        .frame(width: 300, height: 200)
        .background(Color.black.ignoresSafeArea())
        .accessibilityDifferentiateWithoutColor(true)

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 200)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "Glassmorphism_AccessibilityHighContrast"
        )
    }

    func testGlassmorphism_DynamicTypeExtraLarge() {
        let view = VStack {
            Text("Dynamic Type XL")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .modifier(GlassViewModifier())
        .frame(width: 350, height: 250)
        .background(Color.blue.ignoresSafeArea())
        .dynamicTypeSize(.xLarge)

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 350, height: 250)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "Glassmorphism_DynamicTypeExtraLarge"
        )
    }

    // MARK: - Performance Theme Tests

    func testGlassmorphism_ComplexBackground() {
        let view = ZStack {
            // Complex background to test glass effect performance
            ForEach(0..<10, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.cyan.opacity(0.3),
                                Color.purple.opacity(0.2),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .offset(
                        x: CGFloat(index * 30 - 150),
                        y: CGFloat(index * 20 - 100)
                    )
            }

            VStack {
                Text("Complex Background Test")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
            }
            .modifier(GlassViewModifier())
        }
        .frame(width: 400, height: 300)
        .background(Color.black.ignoresSafeArea())

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 400, height: 300)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "Glassmorphism_ComplexBackground"
        )
    }

    // MARK: - Before/After Comparison Tests

    func testThemeComparison_WithoutGlass() {
        let view = VStack {
            Text("Without Glassmorphism")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .background(Color.gray.opacity(0.8))
        .cornerRadius(16)
        .frame(width: 300, height: 150)
        .background(Color.blue.ignoresSafeArea())

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 150)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ThemeComparison_WithoutGlass"
        )
    }

    func testThemeComparison_WithGlass() {
        let view = VStack {
            Text("With Glassmorphism")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
        }
        .modifier(GlassViewModifier())
        .frame(width: 300, height: 150)
        .background(Color.blue.ignoresSafeArea())

        let hostingController = UIHostingController(rootView: view)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: 300, height: 150)

        assertSnapshot(
            matching: hostingController,
            as: .image,
            named: "ThemeComparison_WithGlass"
        )
    }
}

// MARK: - Mock Extensions for Testing

extension ClassificationResult {
    static func mockHighConfidenceDocument() -> ClassificationResult {
        return ClassificationResult(
            category: .documentGeneration,
            intent: "Create PDF document",
            confidence: 0.92,
            parameters: ["format": AnyCodable("PDF"), "topic": AnyCodable("quarterly results")],
            suggestions: [],
            rawText: "Create a PDF document about quarterly results",
            normalizedText: "create pdf document quarterly results",
            processingTime: 0.05
        )
    }

    static func mockMediumConfidenceEmail() -> ClassificationResult {
        return ClassificationResult(
            category: .emailManagement,
            intent: "Send email",
            confidence: 0.65,
            parameters: ["recipient": AnyCodable("team"), "subject": AnyCodable("meeting")],
            suggestions: ["Send email to team", "Create calendar event", "Draft message"],
            rawText: "Send email to team about meeting",
            normalizedText: "send email team meeting",
            processingTime: 0.08
        )
    }

    static func mockHighConfidenceCalendar() -> ClassificationResult {
        return ClassificationResult(
            category: .calendarScheduling,
            intent: "Schedule meeting",
            confidence: 0.88,
            parameters: ["title": AnyCodable("Team Meeting"), "duration": AnyCodable("1 hour")],
            suggestions: [],
            rawText: "Schedule a team meeting for tomorrow",
            normalizedText: "schedule team meeting tomorrow",
            processingTime: 0.04
        )
    }
}
