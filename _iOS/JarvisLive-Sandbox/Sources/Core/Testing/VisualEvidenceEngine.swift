// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Visual Evidence Engine for screenshot capture and test verification
 * Issues & Complexity Summary: UI testing screenshot automation with file management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~150
 *   - Core Algorithm Complexity: Medium
 *   - Dependencies: 3 New (XCTest, UIKit, Foundation)
 *   - State Management Complexity: Medium
 *   - Novelty/Uncertainty Factor: Medium
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 65%
 * Initial Code Complexity Estimate %: 70%
 * Justification for Estimates: Screenshot capture with file management and test integration
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import Foundation
import UIKit
import XCTest

/// Visual Evidence Engine for capturing and managing screenshots during testing
@MainActor
public final class VisualEvidenceEngine {
    // MARK: - Types

    public struct ScreenshotMetadata {
        public let testName: String
        public let timestamp: Date
        public let fileName: String
        public let filePath: URL
        public let deviceInfo: String

        public init(testName: String, timestamp: Date, fileName: String, filePath: URL, deviceInfo: String) {
            self.testName = testName
            self.timestamp = timestamp
            self.fileName = fileName
            self.filePath = filePath
            self.deviceInfo = deviceInfo
        }
    }

    // MARK: - Properties

    public static let shared = VisualEvidenceEngine()

    private let documentsDirectory: URL
    private let screenshotsDirectory: URL
    private var capturedScreenshots: [ScreenshotMetadata] = []

    // MARK: - Initialization

    private init() {
        // Create screenshots directory in Documents
        self.documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.screenshotsDirectory = documentsDirectory.appendingPathComponent("VisualEvidence", isDirectory: true)

        // Ensure screenshots directory exists
        try? FileManager.default.createDirectory(at: screenshotsDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Public Interface

    /// Captures a screenshot of the current app state
    /// - Parameter testName: Name of the test case for organization
    /// - Returns: Metadata about the captured screenshot
    @discardableResult
    public func captureScreenshot(testName: String) -> ScreenshotMetadata? {
        guard let window = getKeyWindow() else {
            print("❌ VisualEvidenceEngine: No key window found for screenshot")
            return nil
        }

        let timestamp = Date()
        let fileName = generateFileName(testName: testName, timestamp: timestamp)
        let filePath = screenshotsDirectory.appendingPathComponent(fileName)

        // Capture screenshot
        guard let screenshot = captureWindow(window) else {
            print("❌ VisualEvidenceEngine: Failed to capture screenshot")
            return nil
        }

        // Save to file
        guard let imageData = screenshot.pngData(),
              (try? imageData.write(to: filePath)) != nil else {
            print("❌ VisualEvidenceEngine: Failed to save screenshot to \(filePath)")
            return nil
        }

        let metadata = ScreenshotMetadata(
            testName: testName,
            timestamp: timestamp,
            fileName: fileName,
            filePath: filePath,
            deviceInfo: getDeviceInfo()
        )

        capturedScreenshots.append(metadata)
        print("✅ VisualEvidenceEngine: Screenshot captured - \(fileName)")

        return metadata
    }

    /// Captures multiple screenshots with delay between them
    /// - Parameters:
    ///   - testName: Name of the test case
    ///   - count: Number of screenshots to capture
    ///   - delay: Delay between captures in seconds
    /// - Returns: Array of screenshot metadata
    public func captureSequence(testName: String, count: Int, delay: TimeInterval = 0.5) async -> [ScreenshotMetadata] {
        var screenshots: [ScreenshotMetadata] = []

        for i in 0..<count {
            let sequenceName = "\(testName)_sequence_\(i+1)"
            if let metadata = captureScreenshot(testName: sequenceName) {
                screenshots.append(metadata)
            }

            if i < count - 1 {
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        return screenshots
    }

    /// Gets all captured screenshots for a specific test
    /// - Parameter testName: Name of the test case
    /// - Returns: Array of screenshot metadata for the test
    public func getScreenshots(forTest testName: String) -> [ScreenshotMetadata] {
        return capturedScreenshots.filter { $0.testName.contains(testName) }
    }

    /// Gets all captured screenshots
    /// - Returns: Array of all screenshot metadata
    public func getAllScreenshots() -> [ScreenshotMetadata] {
        return capturedScreenshots
    }

    /// Clears all captured screenshots from memory and disk
    public func clearAllScreenshots() {
        // Remove files from disk
        for metadata in capturedScreenshots {
            try? FileManager.default.removeItem(at: metadata.filePath)
        }

        // Clear memory
        capturedScreenshots.removeAll()
        print("🧹 VisualEvidenceEngine: All screenshots cleared")
    }

    /// Generates a detailed report of all captured screenshots
    /// - Returns: Formatted report string
    public func generateReport() -> String {
        var report = "# Visual Evidence Report\n"
        report += "Generated: \(Date())\n"
        report += "Screenshots Directory: \(screenshotsDirectory.path)\n"
        report += "Total Screenshots: \(capturedScreenshots.count)\n\n"

        let groupedByTest = Dictionary(grouping: capturedScreenshots) { $0.testName }

        for (testName, screenshots) in groupedByTest.sorted(by: { $0.key < $1.key }) {
            report += "## Test: \(testName)\n"
            report += "Screenshots: \(screenshots.count)\n"

            for screenshot in screenshots.sorted(by: { $0.timestamp < $1.timestamp }) {
                report += "- \(screenshot.fileName) (\(formatTimestamp(screenshot.timestamp)))\n"
                report += "  Path: \(screenshot.filePath.path)\n"
                report += "  Device: \(screenshot.deviceInfo)\n"
            }
            report += "\n"
        }

        return report
    }

    // MARK: - Private Methods

    private func getKeyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    private func captureWindow(_ window: UIWindow) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    private func generateFileName(testName: String, timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        let timeString = formatter.string(from: timestamp)

        let cleanTestName = testName
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "", options: .regularExpression)

        return "\(cleanTestName)_\(timeString).png"
    }

    private func getDeviceInfo() -> String {
        let device = UIDevice.current
        return "\(device.model) (\(device.systemName) \(device.systemVersion))"
    }

    private func formatTimestamp(_ timestamp: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }
}

// MARK: - XCTest Integration

#if canImport(XCTest)
extension XCTestCase {
    /// Captures a screenshot with automatic test name detection
    /// - Parameter suffix: Optional suffix to add to the test name
    /// - Returns: Screenshot metadata
    @MainActor
    @discardableResult
    public func captureVisualEvidence(suffix: String = "") -> VisualEvidenceEngine.ScreenshotMetadata? {
        let testName = suffix.isEmpty ? name : "\(name)_\(suffix)"
        return VisualEvidenceEngine.shared.captureScreenshot(testName: testName)
    }

    /// Captures a screenshot and attaches it to the test for Xcode
    /// - Parameter suffix: Optional suffix to add to the test name
    @MainActor
    public func captureAndAttachScreenshot(suffix: String = "") {
        guard let metadata = captureVisualEvidence(suffix: suffix) else { return }

        // Attach to XCTest for Xcode integration
        if let imageData = try? Data(contentsOf: metadata.filePath) {
            let attachment = XCTAttachment(data: imageData, uniformTypeIdentifier: "public.png")
            attachment.name = metadata.fileName
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
}
#endif
