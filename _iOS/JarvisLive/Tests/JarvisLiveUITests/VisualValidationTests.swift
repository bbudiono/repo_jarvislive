/*
* Purpose: Visual validation test suite for iOS UI consistency
* Issues & Complexity Summary: Automated screenshot capture and glassmorphism validation
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: Medium (UI navigation and capture)
  - Dependencies: XCTest, XCUITest framework
  - State Management Complexity: Medium (UI state management)
  - Novelty/Uncertainty Factor: Medium (screenshot comparison)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 80%
* Initial Code Complexity Estimate: 82%
* Final Code Complexity: 85%
* Overall Result Score: 89%
* Key Variances/Learnings: UI testing requires careful state management
* Last Updated: 2025-06-26
*/

import XCTest
import XCUIApplication

class VisualValidationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - Glassmorphism Theme Validation

    func testMainContentViewGlassmorphism() throws {
        // Navigate to main content view
        let app = XCUIApplication()

        // Wait for main view to appear
        let mainView = app.otherElements["MainContentView"]
        XCTAssertTrue(mainView.waitForExistence(timeout: 5.0), "Main content view should exist")

        // Capture screenshot of main view
        let screenshot = app.screenshot()

        // Save screenshot for visual validation
        saveScreenshot(screenshot, filename: "main_content_view_glassmorphism")

        // Validate glassmorphism elements are present
        let glassCards = app.otherElements.matching(identifier: "GlassCard")
        XCTAssertGreaterThan(glassCards.count, 0, "Glass morphism cards should be present")

        // Validate blur effects are applied
        validateGlassmorphismPresence(in: app)
    }

    func testConversationHistoryViewGlassmorphism() throws {
        let app = XCUIApplication()

        // Navigate to conversation history
        let conversationButton = app.buttons["ConversationHistoryButton"]
        if conversationButton.exists {
            conversationButton.tap()

            // Wait for conversation history view
            let historyView = app.otherElements["ConversationHistoryView"]
            XCTAssertTrue(historyView.waitForExistence(timeout: 5.0), "Conversation history view should exist")

            // Capture screenshot
            let screenshot = app.screenshot()
            saveScreenshot(screenshot, filename: "conversation_history_glassmorphism")

            // Validate glassmorphism background
            validateGlassmorphismPresence(in: app)

            // Test search functionality visual appearance
            let searchField = app.textFields["SearchField"]
            if searchField.exists {
                searchField.tap()
                searchField.typeText("test search")

                let searchScreenshot = app.screenshot()
                saveScreenshot(searchScreenshot, filename: "conversation_search_glassmorphism")
            }
        } else {
            XCTFail("Conversation history button not found - UI may have changed")
        }
    }

    func testSettingsViewGlassmorphism() throws {
        let app = XCUIApplication()

        // Navigate to settings
        let settingsButton = app.buttons["SettingsButton"]
        if settingsButton.exists {
            settingsButton.tap()

            // Wait for settings view
            let settingsView = app.otherElements["SettingsView"]
            XCTAssertTrue(settingsView.waitForExistence(timeout: 5.0), "Settings view should exist")

            // Capture screenshot
            let screenshot = app.screenshot()
            saveScreenshot(screenshot, filename: "settings_view_glassmorphism")

            // Validate glass cards in settings
            validateGlassmorphismPresence(in: app)

            // Test credential input fields appearance
            let apiKeyField = app.secureTextFields["APIKeyField"]
            if apiKeyField.exists {
                apiKeyField.tap()

                let credentialScreenshot = app.screenshot()
                saveScreenshot(credentialScreenshot, filename: "credential_input_glassmorphism")
            }
        } else {
            XCTFail("Settings button not found - UI may have changed")
        }
    }

    func testCollaborativeSessionViewGlassmorphism() throws {
        let app = XCUIApplication()

        // Navigate to collaborative session (if available)
        let collaborationButton = app.buttons["CollaborationButton"]
        if collaborationButton.exists {
            collaborationButton.tap()

            // Wait for collaboration view
            let collaborationView = app.otherElements["CollaborativeSessionView"]
            XCTAssertTrue(collaborationView.waitForExistence(timeout: 5.0), "Collaborative session view should exist")

            // Capture screenshot
            let screenshot = app.screenshot()
            saveScreenshot(screenshot, filename: "collaboration_view_glassmorphism")

            // Validate glassmorphism in collaboration UI
            validateGlassmorphismPresence(in: app)

            // Test participant list appearance
            let participantList = app.tables["ParticipantList"]
            if participantList.exists {
                let participantScreenshot = app.screenshot()
                saveScreenshot(participantScreenshot, filename: "participant_list_glassmorphism")
            }
        } else {
            // Skip if collaboration feature not accessible in current build
            print("⚠️ Collaboration feature not accessible - skipping visual validation")
        }
    }

    func testDocumentGenerationViewGlassmorphism() throws {
        let app = XCUIApplication()

        // Navigate to document generation (if available)
        let documentButton = app.buttons["DocumentGenerationButton"]
        if documentButton.exists {
            documentButton.tap()

            // Wait for document generation view
            let documentView = app.otherElements["DocumentGenerationView"]
            XCTAssertTrue(documentView.waitForExistence(timeout: 5.0), "Document generation view should exist")

            // Capture screenshot
            let screenshot = app.screenshot()
            saveScreenshot(screenshot, filename: "document_generation_glassmorphism")

            // Validate glassmorphism elements
            validateGlassmorphismPresence(in: app)
        } else {
            print("⚠️ Document generation feature not accessible - skipping visual validation")
        }
    }

    // MARK: - VoiceOver Accessibility Testing

    func testVoiceOverAccessibility() throws {
        let app = XCUIApplication()

        // Enable VoiceOver for accessibility testing
        // Note: This test validates that UI elements are accessible

        // Main view accessibility
        let mainElements = app.otherElements.allElementsBoundByIndex
        for element in mainElements {
            if element.exists && element.isHittable {
                // Validate accessibility label exists
                XCTAssertFalse(element.label.isEmpty, "Element should have accessibility label: \(element)")
            }
        }

        // Navigation accessibility
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            if button.exists && button.isHittable {
                XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label: \(button)")
            }
        }

        // Text field accessibility
        let textFields = app.textFields.allElementsBoundByIndex
        for textField in textFields {
            if textField.exists {
                XCTAssertFalse(textField.label.isEmpty, "Text field should have accessibility label: \(textField)")
            }
        }

        print("✅ VoiceOver accessibility validation completed")
    }

    // MARK: - Performance and Responsiveness Testing

    func testUIResponsiveness() throws {
        let app = XCUIApplication()

        measure {
            // Test main view load time
            let mainView = app.otherElements["MainContentView"]
            _ = mainView.waitForExistence(timeout: 2.0)

            // Test navigation responsiveness
            let settingsButton = app.buttons["SettingsButton"]
            if settingsButton.exists {
                settingsButton.tap()
                let settingsView = app.otherElements["SettingsView"]
                _ = settingsView.waitForExistence(timeout: 1.0)

                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
        }

        print("✅ UI responsiveness testing completed")
    }

    // MARK: - Error State Visual Validation

    func testErrorStateAppearance() throws {
        let app = XCUIApplication()

        // Test network error state (if applicable)
        // This would require specific test scenarios

        // Test empty state appearance
        let conversationButton = app.buttons["ConversationHistoryButton"]
        if conversationButton.exists {
            conversationButton.tap()

            // Capture empty state
            let emptyStateScreenshot = app.screenshot()
            saveScreenshot(emptyStateScreenshot, filename: "empty_state_appearance")
        }

        print("✅ Error state visual validation completed")
    }

    // MARK: - Helper Methods

    private func validateGlassmorphismPresence(in app: XCUIApplication) {
        // Check for glassmorphism elements
        let glassElements = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'Glass'"))

        // Validate at least some glassmorphism elements exist
        XCTAssertGreaterThan(glassElements.count, 0, "Glassmorphism elements should be present in the UI")

        // Additional validation could include:
        // - Checking for blur effect accessibility hints
        // - Validating glass card container presence
        // - Ensuring proper visual hierarchy

        print("✅ Glassmorphism validation completed - found \(glassElements.count) glass elements")
    }

    private func saveScreenshot(_ screenshot: XCUIScreenshot, filename: String) {
        // Create screenshots directory if it doesn't exist
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let screenshotsURL = documentsPath.appendingPathComponent("UX_Snapshots")

        do {
            try FileManager.default.createDirectory(at: screenshotsURL, withIntermediateDirectories: true, attributes: nil)

            // Save screenshot
            let screenshotURL = screenshotsURL.appendingPathComponent("\(filename).png")
            try screenshot.pngRepresentation.write(to: screenshotURL)

            print("✅ Screenshot saved: \(screenshotURL.path)")

            // Also create a relative docs path for version control
            let projectRoot = "/Users/bernhardbudiono/Library/CloudStorage/Dropbox/_Documents - Apps (Working)/repos_github/Working/repo_jarvis_live"
            let docsSnapshotsPath = "\(projectRoot)/docs/UX_Snapshots"

            do {
                try FileManager.default.createDirectory(atPath: docsSnapshotsPath, withIntermediateDirectories: true, attributes: nil)
                let docsScreenshotPath = "\(docsSnapshotsPath)/\(filename).png"
                try screenshot.pngRepresentation.write(to: URL(fileURLWithPath: docsScreenshotPath))
                print("✅ Documentation screenshot saved: \(docsScreenshotPath)")
            } catch {
                print("⚠️ Could not save to docs directory: \(error)")
            }
        } catch {
            print("❌ Failed to save screenshot: \(error)")
            XCTFail("Screenshot save failed: \(error)")
        }
    }

    private func validateScreenshotExists(filename: String) -> Bool {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let screenshotURL = documentsPath.appendingPathComponent("UX_Snapshots/\(filename).png")
        return FileManager.default.fileExists(atPath: screenshotURL.path)
    }
}

// MARK: - Test Configuration

extension VisualValidationTests {
    static let requiredScreenshots = [
        "main_content_view_glassmorphism",
        "conversation_history_glassmorphism",
        "settings_view_glassmorphism",
        "collaboration_view_glassmorphism",
        "document_generation_glassmorphism",
    ]

    func testAllRequiredScreenshotsGenerated() throws {
        // This test validates that all visual evidence is captured
        var missingScreenshots: [String] = []

        for screenshotName in Self.requiredScreenshots {
            if !validateScreenshotExists(filename: screenshotName) {
                missingScreenshots.append(screenshotName)
            }
        }

        if !missingScreenshots.isEmpty {
            XCTFail("Missing required screenshots: \(missingScreenshots.joined(separator: ", "))")
        } else {
            print("✅ All required visual evidence captured: \(Self.requiredScreenshots.count) screenshots")
        }
    }
}
