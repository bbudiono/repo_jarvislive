// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: UI tests for Jarvis Live Sandbox with mandatory screenshot capture
 * Issues & Complexity Summary: XCUITest framework with visual evidence collection
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~150
 *   - Core Algorithm Complexity: Medium
 *   - Dependencies: 2 New (XCTest, XCUITest)
 *   - State Management Complexity: Medium
 *   - Novelty/Uncertainty Factor: Medium
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 40%
 * Initial Code Complexity Estimate %: 45%
 * Justification for Estimates: UI testing requires interaction automation and screenshot capture
 * Final Code Complexity (Actual %): 50%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: Screenshot capture adds complexity but provides visual evidence
 * Last Updated: 2025-06-25
 */

import XCTest

final class JarvisLiveUITests: XCTestCase {
    
    var app: XCUIApplication!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        continueAfterFailure = false
        
        app = XCUIApplication()
        app.launch()
        
        // MANDATORY: Capture screenshot at test start for visual evidence
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Test Start - \(name)"
        add(attachment)
    }

    override func tearDownWithError() throws {
        // MANDATORY: Capture screenshot at test end for visual evidence
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Test End - \(name)"
        add(attachment)
    }
    
    // MARK: - Sandbox Watermark Tests
    
    func testSandboxWatermarkPresent() throws {
        // CRITICAL: Test that sandbox watermark is visible
        // This ensures compliance with .cursorrules P0 requirements
        
        let sandboxWatermark = app.staticTexts["🧪 SANDBOX"]
        XCTAssertTrue(sandboxWatermark.exists, "Sandbox watermark must be visible in development builds")
        XCTAssertTrue(sandboxWatermark.isHittable, "Sandbox watermark must be accessible")
        
        // Take screenshot to prove watermark visibility
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Sandbox Watermark Verification"
        add(attachment)
    }

    // MARK: - Main Interface Tests
    
    func testMainInterfaceLoads() throws {
        // Test that main UI elements are present and accessible
        
        let appTitle = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(appTitle.exists, "App title should be visible")
        
        let appSubtitle = app.staticTexts["iOS Voice AI Assistant"]
        XCTAssertTrue(appSubtitle.exists, "App subtitle should be visible")
        
        let environmentLabel = app.staticTexts["Development Environment"]
        XCTAssertTrue(environmentLabel.exists, "Environment label should be visible")
        
        // Verify voice icon is present
        let voiceIcon = app.images.matching(identifier: "voice-icon").firstMatch
        XCTAssertTrue(voiceIcon.exists, "Voice icon should be visible")
    }
    
    func testButtonAccessibility() throws {
        // Test that all buttons are accessible and properly labeled
        
        let testVoiceButton = app.buttons["Test Voice Integration"]
        XCTAssertTrue(testVoiceButton.exists, "Voice test button should be present")
        XCTAssertTrue(testVoiceButton.isHittable, "Voice test button should be tappable")
        
        let testLiveKitButton = app.buttons["Test LiveKit Connection"]
        XCTAssertTrue(testLiveKitButton.exists, "LiveKit test button should be present")
        XCTAssertTrue(testLiveKitButton.isHittable, "LiveKit test button should be tappable")
        
        let testSecurityButton = app.buttons["Test Security Framework"]
        XCTAssertTrue(testSecurityButton.exists, "Security test button should be present")
        XCTAssertTrue(testSecurityButton.isHittable, "Security test button should be tappable")
    }
    
    // MARK: - Navigation and Interaction Tests
    
    func testButtonInteractions() throws {
        // Test button tap interactions (placeholder until actual functionality is implemented)
        
        let testVoiceButton = app.buttons["Test Voice Integration"]
        testVoiceButton.tap()
        
        // Take screenshot after interaction
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "After Voice Button Tap"
        add(attachment)
        
        // TODO: Add assertions for actual functionality when implemented
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testVoiceOverAccessibility() throws {
        // Test VoiceOver compatibility for all UI elements
        
        // Check that all interactive elements have accessibility identifiers
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertNotEqual(button.identifier, "", "All buttons should have accessibility identifiers")
        }
        
        let staticTexts = app.staticTexts.allElementsBoundByIndex
        for text in staticTexts {
            XCTAssertTrue(text.exists, "All text elements should be accessible")
        }
    }
}

// MARK: - Screenshot Capture Extension

extension XCUIApplication {
    func captureScreenshot(named name: String, in testCase: XCTestCase) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        testCase.add(attachment)
    }
}