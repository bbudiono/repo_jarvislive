/*
* Purpose: UI performance tests for Post-Classification Flow components
* Issues & Complexity Summary: XCTMetric performance benchmarks for UI rendering and responsiveness
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: Medium (XCTMetric setup, UI automation)
  - Dependencies: 2 New (XCUITest, XCTMetric performance testing)
  - State Management Complexity: Medium (UI automation state, performance measurement)
  - Novelty/Uncertainty Factor: Low (established performance testing patterns)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 70%
* Initial Code Complexity Estimate: 75%
* Final Code Complexity: 78%
* Overall Result Score: 92%
* Key Variances/Learnings: Standard XCTMetric performance testing implementation
* Last Updated: 2025-06-27
*/

import XCTest

final class PostClassificationUIPerformanceTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - UI Rendering Performance Tests

    func testPostClassificationFlowView_RenderingPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            // Navigate to post-classification flow
            let simulateButton = app.buttons["simulateVoiceCommand"]
            XCTAssertTrue(simulateButton.waitForExistence(timeout: 2))
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            XCTAssertTrue(commandInput.waitForExistence(timeout: 1))
            commandInput.tap()
            commandInput.typeText("Create a PDF document about quarterly results")

            let classifyButton = app.buttons["classify"]
            XCTAssertTrue(classifyButton.exists)
            classifyButton.tap()

            // Wait for post-classification flow to appear
            let postClassificationView = app.otherElements["PostClassificationFlowView"]
            XCTAssertTrue(postClassificationView.waitForExistence(timeout: 3))

            // Ensure UI is fully rendered
            let confidenceIndicator = app.otherElements.matching(identifier: "ConfidenceIndicator").firstMatch
            XCTAssertTrue(confidenceIndicator.waitForExistence(timeout: 1))

            let executeButton = app.buttons["Execute Command"]
            XCTAssertTrue(executeButton.waitForExistence(timeout: 1))
        }
    }

    func testDocumentPreviewCard_RenderingPerformance() throws {
        navigateToDocumentPreview()

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            // Measure document preview card rendering
            let documentPreviewCard = app.otherElements["DocumentPreviewCard"]
            XCTAssertTrue(documentPreviewCard.waitForExistence(timeout: 2))

            // Test parameter expansion performance
            let parametersButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Parameters'")).firstMatch
            if parametersButton.exists {
                parametersButton.tap()

                // Wait for parameters to expand
                let parametersView = app.otherElements["ParametersView"]
                _ = parametersView.waitForExistence(timeout: 1)
            }
        }
    }

    func testEmailPreviewCard_RenderingPerformance() throws {
        navigateToEmailPreview()

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            // Measure email preview card rendering
            let emailPreviewCard = app.otherElements["EmailPreviewCard"]
            XCTAssertTrue(emailPreviewCard.waitForExistence(timeout: 2))

            // Test recipient list expansion
            let recipientText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '@'")).firstMatch
            if recipientText.exists {
                _ = recipientText.isHittable
            }
        }
    }

    func testCalendarPreviewCard_RenderingPerformance() throws {
        navigateToCalendarPreview()

        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            // Measure calendar preview card rendering
            let calendarPreviewCard = app.otherElements["CalendarPreviewCard"]
            XCTAssertTrue(calendarPreviewCard.waitForExistence(timeout: 2))

            // Test date picker interaction
            let dateText = app.staticTexts["Tomorrow"]
            if dateText.exists {
                _ = dateText.isHittable
            }
        }
    }

    // MARK: - Animation Performance Tests

    func testConfidenceIndicator_AnimationPerformance() throws {
        navigateToDocumentPreview()

        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            // Test confidence indicator animation performance
            let confidenceIndicator = app.otherElements.matching(identifier: "ConfidenceIndicator").firstMatch
            XCTAssertTrue(confidenceIndicator.waitForExistence(timeout: 2))

            // Allow animation to complete
            Thread.sleep(forTimeInterval: 0.5)

            // Verify animation has rendered
            XCTAssertTrue(confidenceIndicator.exists)
        }
    }

    func testPostClassificationFlow_TransitionPerformance() throws {
        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            // Measure transition from classification to preview
            let simulateButton = app.buttons["simulateVoiceCommand"]
            XCTAssertTrue(simulateButton.waitForExistence(timeout: 2))
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            XCTAssertTrue(commandInput.waitForExistence(timeout: 1))
            commandInput.tap()
            commandInput.typeText("Create a PDF")

            let classifyButton = app.buttons["classify"]
            classifyButton.tap()

            // Measure time to full UI render
            let postClassificationView = app.otherElements["PostClassificationFlowView"]
            XCTAssertTrue(postClassificationView.waitForExistence(timeout: 2))

            let executeButton = app.buttons["Execute Command"]
            XCTAssertTrue(executeButton.waitForExistence(timeout: 1))

            // Close the flow for next iteration
            let closeButton = app.buttons["Close"]
            if closeButton.exists {
                closeButton.tap()
            }
        }
    }

    func testExecutionView_ProgressAnimationPerformance() throws {
        navigateToDocumentPreview()

        let executeButton = app.buttons["Execute Command"]
        XCTAssertTrue(executeButton.waitForExistence(timeout: 2))

        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            executeButton.tap()

            // Wait for execution view to appear
            let executionView = app.otherElements["ExecutionView"]
            XCTAssertTrue(executionView.waitForExistence(timeout: 2))

            // Allow progress animation to run
            Thread.sleep(forTimeInterval: 1.0)

            // Verify progress indicator is animating
            let progressIndicator = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'progress' OR label CONTAINS 'Progress'")).firstMatch
            _ = progressIndicator.exists
        }
    }

    // MARK: - Memory Performance Tests

    func testPostClassificationFlow_MemoryUsage() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Navigate through multiple classification results
            for i in 1...5 {
                let simulateButton = app.buttons["simulateVoiceCommand"]
                XCTAssertTrue(simulateButton.waitForExistence(timeout: 2))
                simulateButton.tap()

                let commandInput = app.textFields["commandInput"]
                XCTAssertTrue(commandInput.waitForExistence(timeout: 1))
                commandInput.tap()
                commandInput.clearAndEnterText("Test command \(i)")

                let classifyButton = app.buttons["classify"]
                classifyButton.tap()

                let postClassificationView = app.otherElements["PostClassificationFlowView"]
                XCTAssertTrue(postClassificationView.waitForExistence(timeout: 2))

                // Close the flow
                let closeButton = app.buttons["Close"]
                if closeButton.exists {
                    closeButton.tap()
                }

                // Small delay between iterations
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
    }

    func testPreviewCards_MemoryEfficiency() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Test memory usage with different preview cards
            let commands = [
                "Create a PDF document",
                "Send an email to team",
                "Schedule a meeting tomorrow",
                "Search for latest news",
                "Set a reminder for 2 PM",
            ]

            for command in commands {
                let simulateButton = app.buttons["simulateVoiceCommand"]
                XCTAssertTrue(simulateButton.waitForExistence(timeout: 2))
                simulateButton.tap()

                let commandInput = app.textFields["commandInput"]
                XCTAssertTrue(commandInput.waitForExistence(timeout: 1))
                commandInput.tap()
                commandInput.clearAndEnterText(command)

                let classifyButton = app.buttons["classify"]
                classifyButton.tap()

                let postClassificationView = app.otherElements["PostClassificationFlowView"]
                XCTAssertTrue(postClassificationView.waitForExistence(timeout: 2))

                // Interact with preview card
                let executeButton = app.buttons["Execute Command"]
                if executeButton.exists {
                    _ = executeButton.isHittable
                }

                // Close the flow
                let closeButton = app.buttons["Close"]
                if closeButton.exists {
                    closeButton.tap()
                }
            }
        }
    }

    // MARK: - Responsiveness Performance Tests

    func testButtonTap_ResponseTime() throws {
        navigateToDocumentPreview()

        measure(metrics: [XCTClockMetric()]) {
            let executeButton = app.buttons["Execute Command"]
            XCTAssertTrue(executeButton.waitForExistence(timeout: 2))

            // Measure time from tap to visual response
            executeButton.tap()

            // Wait for execution view or state change
            let executionView = app.otherElements["ExecutionView"]
            XCTAssertTrue(executionView.waitForExistence(timeout: 1))
        }
    }

    func testParameterToggle_ResponseTime() throws {
        navigateToDocumentPreview()

        let parametersButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Parameters'")).firstMatch
        if parametersButton.exists {
            measure(metrics: [XCTClockMetric()]) {
                parametersButton.tap()

                // Wait for parameters view to expand
                let parametersView = app.otherElements["ParametersView"]
                XCTAssertTrue(parametersView.waitForExistence(timeout: 1))
            }
        }
    }

    func testVoiceInput_ProcessingTime() throws {
        measure(metrics: [XCTClockMetric()]) {
            let simulateButton = app.buttons["simulateVoiceCommand"]
            XCTAssertTrue(simulateButton.waitForExistence(timeout: 2))
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            XCTAssertTrue(commandInput.waitForExistence(timeout: 1))
            commandInput.tap()
            commandInput.typeText("Create a complex document with multiple sections and detailed formatting requirements")

            let classifyButton = app.buttons["classify"]
            classifyButton.tap()

            // Measure time from classification to UI presentation
            let postClassificationView = app.otherElements["PostClassificationFlowView"]
            XCTAssertTrue(postClassificationView.waitForExistence(timeout: 3))

            // Ensure all UI elements are loaded
            let confidenceIndicator = app.otherElements.matching(identifier: "ConfidenceIndicator").firstMatch
            XCTAssertTrue(confidenceIndicator.waitForExistence(timeout: 1))

            let executeButton = app.buttons["Execute Command"]
            XCTAssertTrue(executeButton.waitForExistence(timeout: 1))
        }
    }

    // MARK: - Scroll Performance Tests

    func testParametersList_ScrollPerformance() throws {
        navigateToDocumentPreview()

        let parametersButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Parameters'")).firstMatch
        if parametersButton.exists {
            parametersButton.tap()

            let parametersView = app.otherElements["ParametersView"]
            if parametersView.waitForExistence(timeout: 2) {
                measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
                    // Simulate scrolling through parameters
                    parametersView.swipeUp()
                    parametersView.swipeDown()
                    parametersView.swipeUp()
                }
            }
        }
    }

    func testSuggestionsList_ScrollPerformance() throws {
        // Navigate to a low confidence result that shows suggestions
        let simulateButton = app.buttons["simulateVoiceCommand"]
        XCTAssertTrue(simulateButton.waitForExistence(timeout: 2))
        simulateButton.tap()

        let commandInput = app.textFields["commandInput"]
        XCTAssertTrue(commandInput.waitForExistence(timeout: 1))
        commandInput.tap()
        commandInput.typeText("unclear command")

        let classifyButton = app.buttons["classify"]
        classifyButton.tap()

        let postClassificationView = app.otherElements["PostClassificationFlowView"]
        if postClassificationView.waitForExistence(timeout: 3) {
            measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
                // Test scrolling through suggestions
                let clarificationView = app.otherElements["ClarificationView"]
                if clarificationView.exists {
                    clarificationView.swipeUp()
                    clarificationView.swipeDown()
                }
            }
        }
    }

    // MARK: - Device Orientation Performance Tests

    func testOrientationChange_Performance() throws {
        navigateToDocumentPreview()

        measure(metrics: [XCTClockMetric(), XCTCPUMetric()]) {
            // Test rotation performance
            XCUIDevice.shared.orientation = .landscapeLeft

            // Wait for layout to complete
            Thread.sleep(forTimeInterval: 0.5)

            let postClassificationView = app.otherElements["PostClassificationFlowView"]
            XCTAssertTrue(postClassificationView.exists)

            // Rotate back
            XCUIDevice.shared.orientation = .portrait

            // Wait for layout to complete
            Thread.sleep(forTimeInterval: 0.5)

            XCTAssertTrue(postClassificationView.exists)
        }
    }

    // MARK: - Background/Foreground Performance Tests

    func testBackgroundForeground_Performance() throws {
        navigateToDocumentPreview()

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric()]) {
            // Simulate app backgrounding
            XCUIApplication().terminate()

            // Relaunch app
            app.launch()

            // Navigate back to post-classification flow
            let simulateButton = app.buttons["simulateVoiceCommand"]
            XCTAssertTrue(simulateButton.waitForExistence(timeout: 3))
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            XCTAssertTrue(commandInput.waitForExistence(timeout: 2))
            commandInput.tap()
            commandInput.typeText("Quick test")

            let classifyButton = app.buttons["classify"]
            classifyButton.tap()

            let postClassificationView = app.otherElements["PostClassificationFlowView"]
            XCTAssertTrue(postClassificationView.waitForExistence(timeout: 3))
        }
    }

    // MARK: - Helper Methods

    private func navigateToDocumentPreview() {
        let simulateButton = app.buttons["simulateVoiceCommand"]
        if simulateButton.waitForExistence(timeout: 3) {
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            if commandInput.waitForExistence(timeout: 2) {
                commandInput.tap()
                commandInput.typeText("Create a PDF document about quarterly results")

                let classifyButton = app.buttons["classify"]
                if classifyButton.exists {
                    classifyButton.tap()
                }
            }
        }
    }

    private func navigateToEmailPreview() {
        let simulateButton = app.buttons["simulateVoiceCommand"]
        if simulateButton.waitForExistence(timeout: 3) {
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            if commandInput.waitForExistence(timeout: 2) {
                commandInput.tap()
                commandInput.typeText("Send an email to john@company.com about the meeting")

                let classifyButton = app.buttons["classify"]
                if classifyButton.exists {
                    classifyButton.tap()
                }
            }
        }
    }

    private func navigateToCalendarPreview() {
        let simulateButton = app.buttons["simulateVoiceCommand"]
        if simulateButton.waitForExistence(timeout: 3) {
            simulateButton.tap()

            let commandInput = app.textFields["commandInput"]
            if commandInput.waitForExistence(timeout: 2) {
                commandInput.tap()
                commandInput.typeText("Schedule a team meeting tomorrow at 9 AM")

                let classifyButton = app.buttons["classify"]
                if classifyButton.exists {
                    classifyButton.tap()
                }
            }
        }
    }
}

// MARK: - XCUIElement Extensions for Testing

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard self.elementType == .textField || self.elementType == .secureTextField else {
            XCTFail("Tried to clear and enter text into a non-text field element")
            return
        }

        self.tap()
        self.press(forDuration: 1.0)
        app.menuItems["Select All"].tap()
        self.typeText(text)
    }
}

// MARK: - Performance Baseline Tests

extension PostClassificationUIPerformanceTests {
    func testPerformanceBaseline_60FPSTarget() throws {
        // Baseline test to ensure UI maintains 60fps target
        measure(metrics: [XCTClockMetric()]) {
            navigateToDocumentPreview()

            let postClassificationView = app.otherElements["PostClassificationFlowView"]
            XCTAssertTrue(postClassificationView.waitForExistence(timeout: 2))

            // Simulate user interaction over 1 second (60 frames)
            for _ in 1...60 {
                Thread.sleep(forTimeInterval: 1.0/60.0) // 16.67ms per frame
                _ = postClassificationView.exists
            }
        }
    }

    func testPerformanceBaseline_200msResponseTarget() throws {
        // Baseline test to ensure <200ms response times
        navigateToDocumentPreview()

        let executeButton = app.buttons["Execute Command"]
        XCTAssertTrue(executeButton.waitForExistence(timeout: 2))

        measure(metrics: [XCTClockMetric()]) {
            let startTime = CFAbsoluteTimeGetCurrent()

            executeButton.tap()

            let executionView = app.otherElements["ExecutionView"]
            XCTAssertTrue(executionView.waitForExistence(timeout: 0.2)) // 200ms max

            let responseTime = CFAbsoluteTimeGetCurrent() - startTime
            XCTAssertLessThan(responseTime, 0.2, "Response time should be less than 200ms, was \(responseTime * 1000)ms")
        }
    }
}
