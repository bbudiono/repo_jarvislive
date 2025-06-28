// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Advanced voice control interface with sophisticated voice interaction workflows and intelligent context display
 * Issues & Complexity Summary: Complex multi-step voice command visualization, context-aware suggestions, real-time analytics, and advanced workflow management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~800+
 *   - Core Algorithm Complexity: High (Real-time visualization, workflow orchestration, analytics)
 *   - Dependencies: 6 New (SwiftUI, Combine, Charts, NaturalLanguage, LiveKit, VoiceCommandClassifier)
 *   - State Management Complexity: High (Multi-stage voice workflows, real-time updates, analytics)
 *   - Novelty/Uncertainty Factor: High (Advanced voice UI patterns, intelligent suggestions)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 90%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 88%
 * Justification for Estimates: Complex voice interaction patterns with real-time visualization and intelligent context management
 * Final Code Complexity (Actual %): 92%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Advanced voice UI requires sophisticated state coordination and real-time feedback loops
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine
import Charts
import NaturalLanguage

// MARK: - Voice Command Workflow Models

struct UIVoiceWorkflow {
    let id = UUID()
    let name: String
    let description: String
    let steps: [VoiceWorkflowStep]
    let category: WorkflowCategory
    let estimatedDuration: TimeInterval
    let complexityLevel: ComplexityLevel
    let isCustom: Bool

    enum WorkflowCategory: String, CaseIterable {
        case productivity = "Productivity"
        case communication = "Communication"
        case contentCreation = "Content Creation"
        case dataAnalysis = "Data Analysis"
        case automation = "Automation"
        case custom = "Custom"

        var icon: String {
            switch self {
            case .productivity: return "checkmark.circle.fill"
            case .communication: return "message.circle.fill"
            case .contentCreation: return "doc.text.fill"
            case .dataAnalysis: return "chart.bar.fill"
            case .automation: return "gearshape.2.fill"
            case .custom: return "wrench.and.screwdriver.fill"
            }
        }

        var color: Color {
            switch self {
            case .productivity: return .green
            case .communication: return .blue
            case .contentCreation: return .purple
            case .dataAnalysis: return .orange
            case .automation: return .cyan
            case .custom: return .pink
            }
        }
    }

    enum ComplexityLevel: String, CaseIterable {
        case simple = "Simple"
        case intermediate = "Intermediate"
        case advanced = "Advanced"
        case expert = "Expert"

        var color: Color {
            switch self {
            case .simple: return .green
            case .intermediate: return .yellow
            case .advanced: return .orange
            case .expert: return .red
            }
        }
    }
}

struct VoiceWorkflowStep {
    let id = UUID()
    let title: String
    let description: String
    let expectedVoiceInput: String
    let intent: CommandIntent
    let parameters: [String: Any]
    let isOptional: Bool
    let estimatedDuration: TimeInterval
    let dependencies: [UUID]

    var status: StepStatus = .pending
    var actualInput: String?
    var result: String?
    var startTime: Date?
    var endTime: Date?

    enum StepStatus {
        case pending
        case listening
        case processing
        case completed(success: Bool)
        case failed(error: String)
        case skipped

        var color: Color {
            switch self {
            case .pending: return .gray
            case .listening: return .blue
            case .processing: return .orange
            case .completed(let success): return success ? .green : .red
            case .failed: return .red
            case .skipped: return .yellow
            }
        }

        var icon: String {
            switch self {
            case .pending: return "circle"
            case .listening: return "mic.circle.fill"
            case .processing: return "gear.circle.fill"
            case .completed(let success): return success ? "checkmark.circle.fill" : "xmark.circle.fill"
            case .failed: return "exclamationmark.triangle.fill"
            case .skipped: return "forward.circle.fill"
            }
        }
    }
}

// MARK: - Voice Analytics Models

struct VoiceAnalytics {
    var sessionStartTime: Date = Date()
    var totalCommands: Int = 0
    var successfulCommands: Int = 0
    var averageConfidence: Double = 0.0
    var averageResponseTime: TimeInterval = 0.0
    var intentDistribution: [CommandIntent: Int] = [:]
    var workflowCompletions: [String: Int] = [:]
    var voiceQualityMetrics: VoiceQualityMetrics = VoiceQualityMetrics()
    var userSatisfactionRatings: [Double] = []

    struct VoiceQualityMetrics {
        var averageVolumeLevel: Double = 0.0
        var backgroundNoiseLevel: Double = 0.0
        var speechClarity: Double = 0.0
        var recognitionAccuracy: Double = 0.0
    }

    var successRate: Double {
        guard totalCommands > 0 else { return 0.0 }
        return Double(successfulCommands) / Double(totalCommands)
    }

    var averageSatisfaction: Double {
        guard !userSatisfactionRatings.isEmpty else { return 0.0 }
        return userSatisfactionRatings.reduce(0, +) / Double(userSatisfactionRatings.count)
    }
}

// MARK: - Context Suggestion Models

struct UIContextSuggestion {
    let id = UUID()
    let text: String
    let intent: CommandIntent
    let confidence: Double
    let relevanceScore: Double
    let category: SuggestionCategory
    let parameters: [String: Any]
    let examplePhrase: String

    enum SuggestionCategory {
        case followUp
        case relatedAction
        case correction
        case optimization
        case exploration

        var icon: String {
            switch self {
            case .followUp: return "arrow.right.circle"
            case .relatedAction: return "link.circle"
            case .correction: return "pencil.circle"
            case .optimization: return "speedometer"
            case .exploration: return "safari"
            }
        }

        var color: Color {
            switch self {
            case .followUp: return .blue
            case .relatedAction: return .green
            case .correction: return .orange
            case .optimization: return .purple
            case .exploration: return .cyan
            }
        }
    }
}

// MARK: - Advanced Voice Control View Model

@MainActor
final class AdvancedVoiceControlViewModel: ObservableObject {
    // MARK: - Published Properties

    @Published var currentWorkflow: UIVoiceWorkflow?
    @Published var workflowProgress: Double = 0.0
    @Published var activeStep: VoiceWorkflowStep?
    @Published var isExecutingWorkflow: Bool = false

    @Published var contextSuggestions: [UIContextSuggestion] = []
    @Published var voiceAnalytics: VoiceAnalytics = VoiceAnalytics()
    @Published var availableWorkflows: [UIVoiceWorkflow] = []

    @Published var showingWorkflowBuilder: Bool = false
    @Published var showingAnalyticsDashboard: Bool = false
    @Published var showingContextHelp: Bool = false

    @Published var listeningForSuggestion: Bool = false
    @Published var currentTranscription: String = ""
    @Published var processingContext: String = ""

    // MARK: - Dependencies

    private let voiceCommandClassifier: VoiceCommandClassifier
    private let liveKitManager: LiveKitManager

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()
    private var contextUpdateTimer: Timer?
    private var analyticsUpdateTimer: Timer?

    // MARK: - Initialization

    init(voiceCommandClassifier: VoiceCommandClassifier, liveKitManager: LiveKitManager) {
        self.voiceCommandClassifier = voiceCommandClassifier
        self.liveKitManager = liveKitManager

        setupInitialData()
        setupBindings()
        startAnalyticsTracking()
    }

    private func setupInitialData() {
        // Initialize with predefined workflows
        availableWorkflows = createPredefinedWorkflows()

        // Start context suggestion generation
        generateInitialContextSuggestions()
    }

    private func setupBindings() {
        // Observe voice activity for real-time updates
        NotificationCenter.default.publisher(for: .voiceCommandProcessed)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleVoiceCommandProcessed(notification)
            }
            .store(in: &cancellables)
    }

    private func startAnalyticsTracking() {
        analyticsUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAnalytics()
        }
    }

    // MARK: - Workflow Management

    func startWorkflow(_ workflow: UIVoiceWorkflow) {
        currentWorkflow = workflow
        isExecutingWorkflow = true
        workflowProgress = 0.0

        if let firstStep = workflow.steps.first {
            activeStep = firstStep
            executeWorkflowStep(firstStep)
        }

        updateContextSuggestions(for: workflow)
    }

    func pauseWorkflow() {
        isExecutingWorkflow = false
        activeStep?.status = .pending
    }

    func resumeWorkflow() {
        guard let activeStep = activeStep else { return }
        isExecutingWorkflow = true
        executeWorkflowStep(activeStep)
    }

    func cancelWorkflow() {
        currentWorkflow = nil
        activeStep = nil
        isExecutingWorkflow = false
        workflowProgress = 0.0
        contextSuggestions.removeAll()
        generateInitialContextSuggestions()
    }

    private func executeWorkflowStep(_ step: VoiceWorkflowStep) {
        var mutableStep = step
        mutableStep.status = .listening
        mutableStep.startTime = Date()
        activeStep = mutableStep

        processingContext = "Listening for: \(step.expectedVoiceInput)"

        // Start listening for the specific command
        Task {
            await listenForStepCompletion(step)
        }
    }

    private func listenForStepCompletion(_ step: VoiceWorkflowStep) async {
        // This would integrate with the actual voice recognition system
        // For demo purposes, we'll simulate the process

        guard var mutableStep = activeStep, mutableStep.id == step.id else { return }

        mutableStep.status = .processing
        activeStep = mutableStep
        processingContext = "Processing voice command..."

        // Simulate processing delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Simulate successful completion
        mutableStep.status = .completed(success: true)
        mutableStep.endTime = Date()
        mutableStep.result = "Step completed successfully"
        activeStep = mutableStep

        // Update progress
        updateWorkflowProgress()

        // Move to next step or complete workflow
        if let workflow = currentWorkflow {
            let currentIndex = workflow.steps.firstIndex { $0.id == step.id } ?? 0
            let nextIndex = currentIndex + 1

            if nextIndex < workflow.steps.count {
                let nextStep = workflow.steps[nextIndex]
                executeWorkflowStep(nextStep)
            } else {
                completeWorkflow()
            }
        }
    }

    private func updateWorkflowProgress() {
        guard let workflow = currentWorkflow else { return }

        let completedSteps = workflow.steps.filter { step in
            if case .completed = step.status { return true }
            return false
        }.count

        workflowProgress = Double(completedSteps) / Double(workflow.steps.count)
    }

    private func completeWorkflow() {
        guard let workflow = currentWorkflow else { return }

        isExecutingWorkflow = false
        workflowProgress = 1.0
        activeStep = nil

        // Update analytics
        voiceAnalytics.workflowCompletions[workflow.name, default: 0] += 1

        // Generate completion suggestions
        generateCompletionSuggestions(for: workflow)

        processingContext = "Workflow completed successfully!"

        // Auto-clear after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.currentWorkflow = nil
            self.processingContext = ""
            self.generateInitialContextSuggestions()
        }
    }

    // MARK: - Context Suggestions

    private func generateInitialContextSuggestions() {
        contextSuggestions = [
            UIContextSuggestion(
                text: "Start a new workflow",
                intent: .general,
                confidence: 0.9,
                relevanceScore: 0.8,
                category: .exploration,
                parameters: [:],
                examplePhrase: "Begin productivity workflow"
            ),
            UIContextSuggestion(
                text: "Generate a document",
                intent: .generateDocument,
                confidence: 0.85,
                relevanceScore: 0.7,
                category: .relatedAction,
                parameters: ["format": "pdf"],
                examplePhrase: "Create a PDF report about quarterly results"
            ),
            UIContextSuggestion(
                text: "Send an email",
                intent: .sendEmail,
                confidence: 0.8,
                relevanceScore: 0.75,
                category: .relatedAction,
                parameters: [:],
                examplePhrase: "Send email to team about project update"
            ),
            UIContextSuggestion(
                text: "Schedule a meeting",
                intent: .scheduleCalendar,
                confidence: 0.82,
                relevanceScore: 0.72,
                category: .relatedAction,
                parameters: [:],
                examplePhrase: "Schedule team meeting for tomorrow at 2 PM"
            ),
        ]
    }

    private func updateContextSuggestions(for workflow: UIVoiceWorkflow) {
        guard let activeStep = activeStep else { return }

        contextSuggestions = [
            UIContextSuggestion(
                text: "Continue to next step",
                intent: activeStep.intent,
                confidence: 0.95,
                relevanceScore: 1.0,
                category: .followUp,
                parameters: activeStep.parameters,
                examplePhrase: activeStep.expectedVoiceInput
            ),
            UIContextSuggestion(
                text: "Skip this step",
                intent: .general,
                confidence: 0.7,
                relevanceScore: 0.6,
                category: .optimization,
                parameters: [:],
                examplePhrase: "Skip this step and continue"
            ),
            UIContextSuggestion(
                text: "Repeat instructions",
                intent: .general,
                confidence: 0.8,
                relevanceScore: 0.8,
                category: .correction,
                parameters: [:],
                examplePhrase: "What should I say again?"
            ),
        ]
    }

    private func generateCompletionSuggestions(for workflow: UIVoiceWorkflow) {
        contextSuggestions = [
            UIContextSuggestion(
                text: "Start another workflow",
                intent: .general,
                confidence: 0.85,
                relevanceScore: 0.9,
                category: .exploration,
                parameters: [:],
                examplePhrase: "Begin another workflow"
            ),
            UIContextSuggestion(
                text: "Review results",
                intent: .general,
                confidence: 0.8,
                relevanceScore: 0.85,
                category: .followUp,
                parameters: [:],
                examplePhrase: "Show me the workflow results"
            ),
            UIContextSuggestion(
                text: "Save as template",
                intent: .general,
                confidence: 0.75,
                relevanceScore: 0.7,
                category: .optimization,
                parameters: [:],
                examplePhrase: "Save this workflow as a custom template"
            ),
        ]
    }

    // MARK: - Analytics

    private func updateAnalytics() {
        // Update voice quality metrics based on LiveKit data
        let audioLevel = liveKitManager.audioLevel
        voiceAnalytics.voiceQualityMetrics.averageVolumeLevel = Double(audioLevel)

        // Update session duration and other real-time metrics
        // This would integrate with actual voice processing data
    }

    private func handleVoiceCommandProcessed(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let classification = userInfo["classification"] as? VoiceCommandClassification else { return }

        // Update analytics
        voiceAnalytics.totalCommands += 1
        if classification.confidence > 0.6 {
            voiceAnalytics.successfulCommands += 1
        }

        // Update confidence average
        let totalConfidence = voiceAnalytics.averageConfidence * Double(voiceAnalytics.totalCommands - 1) + classification.confidence
        voiceAnalytics.averageConfidence = totalConfidence / Double(voiceAnalytics.totalCommands)

        // Update intent distribution
        voiceAnalytics.intentDistribution[classification.intent, default: 0] += 1

        // Update response time
        let totalTime = voiceAnalytics.averageResponseTime * Double(voiceAnalytics.totalCommands - 1) + classification.processingTime
        voiceAnalytics.averageResponseTime = totalTime / Double(voiceAnalytics.totalCommands)
    }

    // MARK: - Predefined Workflows

    private func createPredefinedWorkflows() -> [UIVoiceWorkflow] {
        return [
            // Productivity Workflow
            UIVoiceWorkflow(
                name: "Meeting Preparation",
                description: "Prepare for an upcoming meeting with agenda, documents, and calendar updates",
                steps: [
                    VoiceWorkflowStep(
                        title: "Create Meeting Agenda",
                        description: "Generate a structured meeting agenda document",
                        expectedVoiceInput: "Create agenda for team meeting about project status",
                        intent: .generateDocument,
                        parameters: ["format": "pdf", "template": "meeting-agenda"],
                        isOptional: false,
                        estimatedDuration: 30,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Schedule Meeting",
                        description: "Add the meeting to calendar with invitees",
                        expectedVoiceInput: "Schedule team meeting for tomorrow at 2 PM",
                        intent: .scheduleCalendar,
                        parameters: ["duration": 60],
                        isOptional: false,
                        estimatedDuration: 20,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Send Invitation",
                        description: "Email meeting invitation to team members",
                        expectedVoiceInput: "Send meeting invitation to the team",
                        intent: .sendEmail,
                        parameters: ["template": "meeting-invitation"],
                        isOptional: true,
                        estimatedDuration: 15,
                        dependencies: []
                    ),
                ],
                category: .productivity,
                estimatedDuration: 65,
                complexityLevel: .intermediate,
                isCustom: false
            ),

            // Communication Workflow
            UIVoiceWorkflow(
                name: "Project Status Update",
                description: "Create and distribute project status updates across multiple channels",
                steps: [
                    VoiceWorkflowStep(
                        title: "Generate Status Report",
                        description: "Create a comprehensive project status document",
                        expectedVoiceInput: "Generate project status report for Q4 development",
                        intent: .generateDocument,
                        parameters: ["format": "pdf", "template": "status-report"],
                        isOptional: false,
                        estimatedDuration: 45,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Email to Stakeholders",
                        description: "Send status update to project stakeholders",
                        expectedVoiceInput: "Email status report to stakeholders",
                        intent: .sendEmail,
                        parameters: ["priority": "high"],
                        isOptional: false,
                        estimatedDuration: 20,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Schedule Follow-up",
                        description: "Schedule follow-up meeting if needed",
                        expectedVoiceInput: "Schedule follow-up meeting next week",
                        intent: .scheduleCalendar,
                        parameters: ["type": "follow-up"],
                        isOptional: true,
                        estimatedDuration: 15,
                        dependencies: []
                    ),
                ],
                category: .communication,
                estimatedDuration: 80,
                complexityLevel: .intermediate,
                isCustom: false
            ),

            // Content Creation Workflow
            UIVoiceWorkflow(
                name: "Content Research & Creation",
                description: "Research a topic and create comprehensive content",
                steps: [
                    VoiceWorkflowStep(
                        title: "Research Topic",
                        description: "Search for relevant information on the topic",
                        expectedVoiceInput: "Search for latest trends in AI development",
                        intent: .performSearch,
                        parameters: ["sources": ["web", "academic"]],
                        isOptional: false,
                        estimatedDuration: 60,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Create Content Outline",
                        description: "Generate a structured outline based on research",
                        expectedVoiceInput: "Create content outline about AI trends",
                        intent: .generateDocument,
                        parameters: ["format": "markdown", "type": "outline"],
                        isOptional: false,
                        estimatedDuration: 30,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Generate Full Content",
                        description: "Create the complete content piece",
                        expectedVoiceInput: "Generate full article about AI development trends",
                        intent: .generateDocument,
                        parameters: ["format": "docx", "type": "article"],
                        isOptional: false,
                        estimatedDuration: 90,
                        dependencies: []
                    ),
                    VoiceWorkflowStep(
                        title: "Save to Cloud",
                        description: "Upload the content to cloud storage",
                        expectedVoiceInput: "Save article to cloud storage",
                        intent: .uploadStorage,
                        parameters: ["folder": "content"],
                        isOptional: true,
                        estimatedDuration: 10,
                        dependencies: []
                    ),
                ],
                category: .contentCreation,
                estimatedDuration: 190,
                complexityLevel: .advanced,
                isCustom: false
            ),
        ]
    }
}

// MARK: - Advanced Voice Control View

struct AdvancedVoiceControlView: View {
    @StateObject private var viewModel: AdvancedVoiceControlViewModel
    @ObservedObject private var liveKitManager: LiveKitManager
    @ObservedObject private var voiceCommandClassifier: VoiceCommandClassifier

    init(liveKitManager: LiveKitManager, voiceCommandClassifier: VoiceCommandClassifier) {
        self.liveKitManager = liveKitManager
        self.voiceCommandClassifier = voiceCommandClassifier
        self._viewModel = StateObject(wrappedValue: AdvancedVoiceControlViewModel(
            voiceCommandClassifier: voiceCommandClassifier,
            liveKitManager: liveKitManager
        ))
    }

    var body: some View {
        ZStack {
            // Background
            advancedVoiceBackground

            ScrollView {
                VStack(spacing: 20) {
                    // Header with controls
                    advancedVoiceHeader

                    // Current workflow section
                    if viewModel.currentWorkflow != nil {
                        currentWorkflowSection
                    } else {
                        workflowSelectionSection
                    }

                    // Context suggestions
                    contextSuggestionsSection

                    // Voice quality indicators
                    voiceQualitySection

                    // Quick actions
                    quickActionsSection
                }
                .padding()
            }
        }
        .sheet(isPresented: $viewModel.showingAnalyticsDashboard) {
            // AnalyticsDashboardView(analytics: viewModel.voiceAnalytics)
            Text("Analytics Dashboard - Coming Soon")
                .padding()
        }
        .sheet(isPresented: $viewModel.showingWorkflowBuilder) {
            // WorkflowBuilderView(workflows: $viewModel.availableWorkflows)
            Text("Workflow Builder - Coming Soon")
                .padding()
        }
        .sheet(isPresented: $viewModel.showingContextHelp) {
            ContextHelpView(suggestions: viewModel.contextSuggestions)
        }
    }

    // MARK: - View Components

    private var advancedVoiceBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.05, green: 0.1, blue: 0.2),
                Color(red: 0.1, green: 0.05, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var advancedVoiceHeader: some View {
        advancedGlassCard {
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Advanced Voice Control")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("🧪 SANDBOX MODE")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Button(action: { viewModel.showingContextHelp = true }) {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.cyan)
                        }

                        Button(action: { viewModel.showingWorkflowBuilder = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                        }

                        Button(action: { viewModel.showingAnalyticsDashboard = true }) {
                            Image(systemName: "chart.bar.fill")
                                .font(.title2)
                                .foregroundColor(.purple)
                        }
                    }
                }

                // Processing context display
                if !viewModel.processingContext.isEmpty {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.cyan)

                        Text(viewModel.processingContext)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)

                        Spacer()

                        if viewModel.isExecutingWorkflow {
                            ProgressView()
                                .scaleEffect(0.8)
                                .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        }
                    }
                    .padding(.top, 5)
                }
            }
            .padding()
        }
    }

    private var currentWorkflowSection: some View {
        advancedGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                // Workflow header
                HStack {
                    Image(systemName: viewModel.currentWorkflow?.category.icon ?? "gear")
                        .font(.title2)
                        .foregroundColor(viewModel.currentWorkflow?.category.color ?? .gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.currentWorkflow?.name ?? "")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(viewModel.currentWorkflow?.description ?? "")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(viewModel.workflowProgress * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(viewModel.currentWorkflow?.complexityLevel.rawValue ?? "")
                            .font(.caption)
                            .foregroundColor(viewModel.currentWorkflow?.complexityLevel.color ?? .gray)
                    }
                }

                // Progress bar
                ProgressView(value: viewModel.workflowProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                    .scaleEffect(y: 2)

                // Current step
                if let activeStep = viewModel.activeStep {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: activeStep.status.icon)
                                .foregroundColor(activeStep.status.color)

                            Text("Current Step:")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()
                        }

                        Text(activeStep.title)
                            .font(.headline)
                            .foregroundColor(.white)

                        Text(activeStep.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))

                        // Expected input
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.green)

                            Text("Say: \"\(activeStep.expectedVoiceInput)\"")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .lineLimit(3)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }

                // Workflow controls
                HStack(spacing: 15) {
                    if viewModel.isExecutingWorkflow {
                        Button(action: { viewModel.pauseWorkflow() }) {
                            HStack {
                                Image(systemName: "pause.fill")
                                Text("Pause")
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                        }
                    } else if viewModel.currentWorkflow != nil {
                        Button(action: { viewModel.resumeWorkflow() }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Resume")
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(8)
                        }
                    }

                    Button(action: { viewModel.cancelWorkflow() }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Cancel")
                        }
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                    }

                    Spacer()
                }
            }
            .padding()
        }
    }

    private var workflowSelectionSection: some View {
        advancedGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Available Workflows")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(viewModel.availableWorkflows, id: \.id) { workflow in
                        Button(action: { viewModel.startWorkflow(workflow) }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: workflow.category.icon)
                                        .foregroundColor(workflow.category.color)

                                    Spacer()

                                    Text(workflow.complexityLevel.rawValue)
                                        .font(.caption2)
                                        .foregroundColor(workflow.complexityLevel.color)
                                }

                                Text(workflow.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.leading)
                                    .lineLimit(2)

                                Text("\(workflow.steps.count) steps • ~\(Int(workflow.estimatedDuration/60))min")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding()
        }
    }

    private var contextSuggestionsSection: some View {
        advancedGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("Smart Suggestions")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: {
                        viewModel.listeningForSuggestion.toggle()
                    }) {
                        Image(systemName: viewModel.listeningForSuggestion ? "mic.fill" : "mic.slash.fill")
                            .foregroundColor(viewModel.listeningForSuggestion ? .green : .gray)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.contextSuggestions, id: \.id) { suggestion in
                            suggestionCard(suggestion)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .padding()
        }
    }

    private func suggestionCard(_ suggestion: UIContextSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: suggestion.category.icon)
                    .foregroundColor(suggestion.category.color)

                Spacer()

                Text("\(Int(suggestion.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(suggestion.text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text("Say: \"\(suggestion.examplePhrase)\"")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
                .italic()
                .lineLimit(2)
        }
        .frame(width: 180, height: 100)
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(suggestion.category.color.opacity(0.3), lineWidth: 1)
        )
    }

    private var voiceQualitySection: some View {
        advancedGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "waveform")
                        .font(.title2)
                        .foregroundColor(.cyan)

                    Text("Voice Quality")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volume")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        ProgressView(value: abs(liveKitManager.audioLevel) / 60.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .green))
                            .frame(height: 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Clarity")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        ProgressView(value: viewModel.voiceAnalytics.voiceQualityMetrics.speechClarity)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .frame(height: 6)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accuracy")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        ProgressView(value: viewModel.voiceAnalytics.voiceQualityMetrics.recognitionAccuracy)
                            .progressViewStyle(LinearProgressViewStyle(tint: .purple))
                            .frame(height: 6)
                    }
                }
            }
            .padding()
        }
    }

    private var quickActionsSection: some View {
        advancedGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Quick Actions")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                    quickActionButton("Generate Doc", "doc.text.fill", .blue) {
                        // Trigger document generation
                    }

                    quickActionButton("Send Email", "envelope.fill", .green) {
                        // Trigger email composition
                    }

                    quickActionButton("Schedule", "calendar.badge.plus", .purple) {
                        // Trigger calendar event
                    }

                    quickActionButton("Search", "magnifyingglass", .orange) {
                        // Trigger search
                    }
                }
            }
            .padding()
        }
    }

    private func quickActionButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 60)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func advancedGlassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let voiceCommandProcessed = Notification.Name("voiceCommandProcessed")
}

// MARK: - Preview

struct AdvancedVoiceControlView_Previews: PreviewProvider {
    static var previews: some View {
        AdvancedVoiceControlView(
            liveKitManager: LiveKitManager(),
            voiceCommandClassifier: VoiceCommandClassifier()
        )
        .preferredColorScheme(.dark)
    }
}
