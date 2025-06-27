/*
* Purpose: Post-classification UI flow controller for voice command execution
* Issues & Complexity Summary: Dynamic UI flows based on classification confidence and category
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: Medium (state machine, dynamic views)
  - Dependencies: 4 New (VoiceClassificationManager, flow states, animations)
  - State Management Complexity: High (multiple flow states, transitions)
  - Novelty/Uncertainty Factor: Medium (new UI pattern)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 80%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
*/

import SwiftUI
import Combine

// MARK: - Classification Result Models

struct UIClassificationResult: Codable, Identifiable {
    let id = UUID()
    let category: CommandCategory
    let intent: String
    let confidence: Double
    let parameters: [String: UIAnyCodable]
    let suggestions: [String]
    let rawText: String
    let normalizedText: String
    let processingTime: Double

    var confidenceLevel: ConfidenceLevel {
        switch confidence {
        case 0.8...1.0: return .high
        case 0.5..<0.8: return .medium
        case 0.3..<0.5: return .low
        default: return .veryLow
        }
    }

    var requiresConfirmation: Bool {
        return confidenceLevel != .high
    }
}

enum CommandCategory: String, CaseIterable, Codable {
    case generalConversation = "general_conversation"
    case documentGeneration = "document_generation"
    case emailManagement = "email_management"
    case calendarScheduling = "calendar_scheduling"
    case webSearch = "web_search"
    case systemControl = "system_control"
    case fileManagement = "file_management"
    case taskManagement = "task_management"
    case weatherInfo = "weather_info"
    case newsBriefing = "news_briefing"
    case calculations = "calculations"
    case translations = "translations"
    case reminders = "reminders"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .generalConversation: return "Conversation"
        case .documentGeneration: return "Document Generation"
        case .emailManagement: return "Email Management"
        case .calendarScheduling: return "Calendar Scheduling"
        case .webSearch: return "Web Search"
        case .systemControl: return "System Control"
        case .fileManagement: return "File Management"
        case .taskManagement: return "Task Management"
        case .weatherInfo: return "Weather Info"
        case .newsBriefing: return "News Briefing"
        case .calculations: return "Calculations"
        case .translations: return "Translations"
        case .reminders: return "Reminders"
        case .unknown: return "Unknown"
        }
    }

    var icon: String {
        switch self {
        case .generalConversation: return "bubble.left.and.bubble.right"
        case .documentGeneration: return "doc.text"
        case .emailManagement: return "envelope"
        case .calendarScheduling: return "calendar"
        case .webSearch: return "magnifyingglass"
        case .systemControl: return "gear"
        case .fileManagement: return "folder"
        case .taskManagement: return "checklist"
        case .weatherInfo: return "cloud.sun"
        case .newsBriefing: return "newspaper"
        case .calculations: return "function"
        case .translations: return "character.bubble"
        case .reminders: return "bell"
        case .unknown: return "questionmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .generalConversation: return .blue
        case .documentGeneration: return .green
        case .emailManagement: return .orange
        case .calendarScheduling: return .purple
        case .webSearch: return .teal
        case .systemControl: return .gray
        case .fileManagement: return .brown
        case .taskManagement: return .indigo
        case .weatherInfo: return .cyan
        case .newsBriefing: return .red
        case .calculations: return .mint
        case .translations: return .pink
        case .reminders: return .yellow
        case .unknown: return .secondary
        }
    }
}

enum ConfidenceLevel: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    case veryLow = "very_low"

    var displayName: String {
        switch self {
        case .high: return "High Confidence"
        case .medium: return "Medium Confidence"
        case .low: return "Low Confidence"
        case .veryLow: return "Very Low Confidence"
        }
    }

    var color: Color {
        switch self {
        case .high: return .green
        case .medium: return .orange
        case .low: return .yellow
        case .veryLow: return .red
        }
    }
}

// MARK: - Flow State Management

enum PostClassificationFlowState: Equatable {
    case processing
    case preview(PreviewData)
    case confirmation(ConfirmationData)
    case execution(ExecutionData)
    case result(ResultData)
    case error(ErrorData)
    case clarification(ClarificationData)

    static func == (lhs: PostClassificationFlowState, rhs: PostClassificationFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.processing, .processing): return true
        case (.preview, .preview): return true
        case (.confirmation, .confirmation): return true
        case (.execution, .execution): return true
        case (.result, .result): return true
        case (.error, .error): return true
        case (.clarification, .clarification): return true
        default: return false
        }
    }
}

struct PreviewData {
    let title: String
    let description: String
    let parameters: [String: UIAnyCodable]
    let previewContent: AnyView?
}

struct ConfirmationData {
    let title: String
    let message: String
    let confirmButtonTitle: String
    let cancelButtonTitle: String
    let destructive: Bool
}

struct ExecutionData {
    let title: String
    let message: String
    let progress: Double
    let estimatedTimeRemaining: TimeInterval?
    let canCancel: Bool
}

struct ResultData {
    let title: String
    let message: String
    let success: Bool
    let resultContent: AnyView?
    let actions: [ResultAction]
}

struct ErrorData {
    let title: String
    let message: String
    let error: Error
    let canRetry: Bool
    let suggestions: [String]
}

struct ClarificationData {
    let title: String
    let message: String
    let suggestions: [String]
    let allowManualInput: Bool
}

struct ResultAction {
    let title: String
    let icon: String
    let action: () -> Void
}

// MARK: - Flow Manager

@MainActor
class PostClassificationFlowManager: ObservableObject {
    @Published var currentState: PostClassificationFlowState = .processing
    @Published var isPresented: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var currentClassification: UIClassificationResult?

    func processClassification(_ result: UIClassificationResult) {
        currentClassification = result
        isPresented = true

        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.determineNextState(for: result)
        }
    }

    private func determineNextState(for result: UIClassificationResult) {
        switch result.confidenceLevel {
        case .high:
            showPreview(for: result)
        case .medium:
            showConfirmation(for: result)
        case .low:
            showClarification(for: result)
        case .veryLow:
            showClarification(for: result)
        }
    }

    private func showPreview(for result: UIClassificationResult) {
        let previewData = createPreviewData(for: result)
        currentState = .preview(previewData)
    }

    private func showConfirmation(for result: UIClassificationResult) {
        let confirmationData = createConfirmationData(for: result)
        currentState = .confirmation(confirmationData)
    }

    private func showClarification(for result: UIClassificationResult) {
        let clarificationData = createClarificationData(for: result)
        currentState = .clarification(clarificationData)
    }

    func executeCommand() {
        guard let classification = currentClassification else { return }

        let executionData = ExecutionData(
            title: "Executing Command",
            message: "Processing your \(classification.category.displayName.lowercased()) request...",
            progress: 0.0,
            estimatedTimeRemaining: 5.0,
            canCancel: true
        )

        currentState = .execution(executionData)

        // Simulate command execution
        simulateExecution { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    self?.showResult(success: true)
                } else {
                    self?.showError()
                }
            }
        }
    }

    func retryCommand() {
        executeCommand()
    }

    func dismiss() {
        isPresented = false
        currentState = .processing
        currentClassification = nil
    }

    // MARK: - Helper Methods

    private func createPreviewData(for result: UIClassificationResult) -> PreviewData {
        return PreviewData(
            title: "Ready to Execute",
            description: "I'm confident about this \(result.category.displayName.lowercased()) command.",
            parameters: result.parameters,
            previewContent: createCategorySpecificPreview(for: result)
        )
    }

    private func createConfirmationData(for result: UIClassificationResult) -> ConfirmationData {
        return ConfirmationData(
            title: "Confirm Command",
            message: "I think you want to \(result.intent). Is this correct?",
            confirmButtonTitle: "Yes, Execute",
            cancelButtonTitle: "Cancel",
            destructive: false
        )
    }

    private func createClarificationData(for result: UIClassificationResult) -> ClarificationData {
        return ClarificationData(
            title: "Need Clarification",
            message: "I'm not sure what you meant. Could you try one of these options?",
            suggestions: result.suggestions.isEmpty ? generateFallbackSuggestions(for: result.category) : result.suggestions,
            allowManualInput: true
        )
    }

    private func createCategorySpecificPreview(for result: UIClassificationResult) -> AnyView? {
        // Convert UIAnyCodable to AnyCodable for compatibility
        let convertedParameters = result.parameters.mapValues { uiAnyCodable in
            AnyCodable(uiAnyCodable.value)
        }
        
        switch result.category {
        case .documentGeneration:
            return AnyView(DocumentPreviewCard(parameters: convertedParameters))
        case .emailManagement:
            return AnyView(EmailPreviewCard(parameters: convertedParameters))
        case .calendarScheduling:
            return AnyView(CalendarPreviewCard(parameters: convertedParameters))
        default:
            return nil
        }
    }

    private func generateFallbackSuggestions(for category: CommandCategory) -> [String] {
        switch category {
        case .documentGeneration:
            return ["Create a PDF document", "Generate a Word document", "Make a presentation"]
        case .emailManagement:
            return ["Send an email", "Check my inbox", "Draft a message"]
        case .calendarScheduling:
            return ["Schedule a meeting", "Create an event", "Check my calendar"]
        case .webSearch:
            return ["Search the web", "Find information about", "Look up"]
        default:
            return ["Try saying it differently", "Be more specific", "Use keywords"]
        }
    }

    private func simulateExecution(completion: @escaping (Bool) -> Void) {
        // Simulate various execution stages with progress updates
        var progress: Double = 0.0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { timer in
            progress += 0.2

            if let executionData = self.currentState.executionData {
                let updatedData = ExecutionData(
                    title: executionData.title,
                    message: executionData.message,
                    progress: min(progress, 1.0),
                    estimatedTimeRemaining: max(0, (executionData.estimatedTimeRemaining ?? 0) - 0.3),
                    canCancel: executionData.canCancel
                )

                DispatchQueue.main.async {
                    self.currentState = .execution(updatedData)
                }
            }

            if progress >= 1.0 {
                timer.invalidate()
                completion(Bool.random()) // Simulate random success/failure for demo
            }
        }
    }

    private func showResult(success: Bool) {
        guard let classification = currentClassification else { return }

        let resultData = ResultData(
            title: success ? "Success!" : "Command Failed",
            message: success
                ? "Your \(classification.category.displayName.lowercased()) command was executed successfully."
                : "There was an error executing your command.",
            success: success,
            resultContent: success ? createResultContent(for: classification) : nil,
            actions: createResultActions(success: success)
        )

        currentState = .result(resultData)
    }

    private func showError() {
        let errorData = ErrorData(
            title: "Execution Failed",
            message: "An error occurred while processing your command.",
            error: NSError(domain: "CommandExecution", code: 1, userInfo: [NSLocalizedDescriptionKey: "Execution failed"]),
            canRetry: true,
            suggestions: ["Check your internet connection", "Try rephrasing your command", "Contact support"]
        )

        currentState = .error(errorData)
    }

    private func createResultContent(for classification: UIClassificationResult) -> AnyView? {
        switch classification.category {
        case .documentGeneration:
            return AnyView(DocumentResultView())
        case .emailManagement:
            return AnyView(EmailResultView())
        case .calendarScheduling:
            return AnyView(CalendarResultView())
        default:
            return nil
        }
    }

    private func createResultActions(success: Bool) -> [ResultAction] {
        var actions: [ResultAction] = []

        if success {
            actions.append(ResultAction(title: "Share", icon: "square.and.arrow.up") {
                // Share action
            })
            actions.append(ResultAction(title: "View Details", icon: "info.circle") {
                // View details action
            })
        } else {
            actions.append(ResultAction(title: "Retry", icon: "arrow.clockwise") { [weak self] in
                self?.retryCommand()
            })
        }

        actions.append(ResultAction(title: "Done", icon: "checkmark") { [weak self] in
            self?.dismiss()
        })

        return actions
    }
}

// MARK: - Main Flow View

struct PostClassificationFlowView: View {
    let classificationResult: UIClassificationResult
    @StateObject private var flowManager = PostClassificationFlowManager()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView

                // Content
                VStack(spacing: 0) {
                    headerView
                    contentView
                    footerView
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                flowManager.processClassification(classificationResult)
            }
        }
        .modifier(GlassViewModifier())
    }

    // MARK: - Subviews

    private var backgroundView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            // Animated particles for glassmorphism effect
            ForEach(0..<15, id: \.self) { _ in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 20...60))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .linear(duration: Double.random(in: 10...20))
                        .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            }
        }
    }

    private var headerView: some View {
        HStack {
            // Classification badge
            HStack(spacing: 8) {
                Image(systemName: classificationResult.category.icon)
                    .foregroundColor(classificationResult.category.color)

                Text(classificationResult.category.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                // Confidence indicator
                ConfidenceIndicatorView(confidence: classificationResult.confidence)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )

            Spacer()

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    )
            }
            .accessibilityLabel("Close")
        }
        .padding()
    }

    @ViewBuilder
    private var contentView: some View {
        switch flowManager.currentState {
        case .processing:
            ProcessingView()
        case .preview(let data):
            PreviewView(data: data, onExecute: flowManager.executeCommand)
        case .confirmation(let data):
            ConfirmationView(data: data, onConfirm: flowManager.executeCommand, onCancel: { dismiss() })
        case .execution(let data):
            ExecutionView(data: data, onCancel: { dismiss() })
        case .result(let data):
            ResultView(data: data)
        case .error(let data):
            ErrorView(data: data, onRetry: flowManager.retryCommand, onDismiss: { dismiss() })
        case .clarification(let data):
            ClarificationView(data: data, onSelection: { _ in
                // Handle suggestion selection
                flowManager.executeCommand()
            })
        }
    }

    private var footerView: some View {
        VStack(spacing: 12) {
            // Original command text
            HStack {
                Image(systemName: "quote.bubble")
                    .foregroundColor(.secondary)

                Text("\"\(classificationResult.rawText)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                Spacer()
            }
            .padding(.horizontal)

            // Processing time
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.secondary)

                Text("Processed in \(String(format: "%.0fms", classificationResult.processingTime * 1000))")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

// MARK: - Extensions

extension PostClassificationFlowState {
    var executionData: ExecutionData? {
        if case .execution(let data) = self {
            return data
        }
        return nil
    }
}

// MARK: - AnyCodable Helper

struct UIAnyCodable: Codable {
    let value: Any

    init<T>(_ value: T?) {
        self.value = value ?? ()
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "UIAnyCodable value cannot be decoded")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intVal as Int:
            try container.encode(intVal)
        case let doubleVal as Double:
            try container.encode(doubleVal)
        case let boolVal as Bool:
            try container.encode(boolVal)
        case let stringVal as String:
            try container.encode(stringVal)
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "UIAnyCodable value cannot be encoded"))
        }
    }
}

// MARK: - Classification Result Conversion

extension UIClassificationResult {
    /// Convert from VoiceClassificationManager's ClassificationResult to UI model
    init(from classificationResult: ClassificationResult) {
        // Convert category string to enum
        let categoryEnum = CommandCategory(rawValue: classificationResult.category) ?? .unknown
        
        // Convert parameters to UIAnyCodable
        let uiParameters = classificationResult.parameters.mapValues { value in
            UIAnyCodable(value)
        }
        
        self.init(
            category: categoryEnum,
            intent: classificationResult.intent,
            confidence: classificationResult.confidence,
            parameters: uiParameters,
            suggestions: classificationResult.suggestions,
            rawText: classificationResult.rawText,
            normalizedText: classificationResult.normalizedText,
            processingTime: classificationResult.preprocessingTime + classificationResult.classificationTime
        )
    }
}

extension ClassificationResult {
    /// Convert from UI model to VoiceClassificationManager model
    init(from uiResult: UIClassificationResult) {
        // Convert parameters back to [String: String]
        let parameters = uiResult.parameters.mapValues { uiAnyCodable in
            String(describing: uiAnyCodable.value)
        }
        
        self.init(
            category: uiResult.category.rawValue,
            intent: uiResult.intent,
            confidence: uiResult.confidence,
            parameters: parameters,
            suggestions: uiResult.suggestions,
            rawText: uiResult.rawText,
            normalizedText: uiResult.normalizedText,
            confidenceLevel: uiResult.confidenceLevel.rawValue,
            contextUsed: false, // Default value
            preprocessingTime: uiResult.processingTime * 0.3, // Approximate split
            classificationTime: uiResult.processingTime * 0.7, // Approximate split
            requiresConfirmation: uiResult.requiresConfirmation
        )
    }
}

#Preview {
    let sampleResult = UIClassificationResult(
        category: .documentGeneration,
        intent: "Create a PDF document about quarterly results",
        confidence: 0.85,
        parameters: [
            "format": UIAnyCodable("PDF"),
            "content": UIAnyCodable("quarterly results"),
            "title": UIAnyCodable("Q3 Results Report"),
        ],
        suggestions: ["Create PDF", "Generate report", "Make document"],
        rawText: "Create a PDF about our Q3 results",
        normalizedText: "create pdf quarterly results",
        processingTime: 0.045
    )

    PostClassificationFlowView(classificationResult: sampleResult)
}
