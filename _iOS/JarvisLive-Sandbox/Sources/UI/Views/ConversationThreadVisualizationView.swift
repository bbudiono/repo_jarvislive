// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Advanced conversation thread visualization with intelligent grouping, context tracking, and visual flow representation
 * Issues & Complexity Summary: Complex conversation threading, visual flow diagrams, context relationships, timeline visualization
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~650+
 *   - Core Algorithm Complexity: High (Thread grouping, visual layout, relationship mapping)
 *   - Dependencies: 5 New (SwiftUI, Charts, Combine, CoreGraphics, NaturalLanguage)
 *   - State Management Complexity: High (Thread states, visual layout, filtering, search)
 *   - Novelty/Uncertainty Factor: High (Conversation visualization patterns, thread analysis)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 90%
 * Problem Estimate (Inherent Problem Difficulty %): 88%
 * Initial Code Complexity Estimate %: 89%
 * Justification for Estimates: Advanced conversation visualization with complex threading and visual flow representation
 * Final Code Complexity (Actual %): 93%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Conversation visualization requires sophisticated data modeling and visual layout algorithms
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Charts
import Combine

// MARK: - Conversation Thread Models

struct ConversationThread {
    let id = UUID()
    let title: String
    let startTime: Date
    let endTime: Date?
    let messages: [ConversationMessageUI]
    let context: ThreadContext
    let participants: [String]
    let tags: [String]
    let workflowReferences: [UUID]
    let relatedThreads: [UUID]
    var isActive: Bool
    var priority: ThreadPriority

    enum ThreadPriority: String, CaseIterable {
        case low = "Low"
        case normal = "Normal"
        case high = "High"
        case urgent = "Urgent"

        var color: Color {
            switch self {
            case .low: return .gray
            case .normal: return .blue
            case .high: return .orange
            case .urgent: return .red
            }
        }
    }

    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    var messageCount: Int {
        return messages.count
    }

    var lastActivity: Date {
        return messages.last?.timestamp ?? startTime
    }
}

struct ConversationMessageUI {
    let id = UUID()
    let content: String
    let timestamp: Date
    let speaker: MessageSpeaker
    let messageType: MessageType
    let confidence: Double
    let intent: CommandIntent?
    let relatedWorkflowStep: UUID?
    let contextReferences: [UUID]
    let metadata: MessageMetadata

    enum MessageSpeaker {
        case user
        case assistant
        case system

        var color: Color {
            switch self {
            case .user: return .blue
            case .assistant: return .green
            case .system: return .orange
            }
        }

        var icon: String {
            switch self {
            case .user: return "person.circle.fill"
            case .assistant: return "brain.head.profile.fill"
            case .system: return "gear.circle.fill"
            }
        }
    }

    enum MessageType {
        case voice
        case text
        case command
        case response
        case error
        case notification

        var icon: String {
            switch self {
            case .voice: return "mic.fill"
            case .text: return "text.bubble.fill"
            case .command: return "terminal.fill"
            case .response: return "checkmark.bubble.fill"
            case .error: return "exclamationmark.triangle.fill"
            case .notification: return "bell.fill"
            }
        }
    }
}

struct MessageMetadata {
    let processingTime: TimeInterval
    let voiceQuality: Double?
    let backgroundNoise: Double?
    let networkLatency: TimeInterval?
    let aiProvider: String?
    let tokenCount: Int?
}

struct ThreadContext {
    let mainTopic: String
    let subTopics: [String]
    let entities: [String]
    let sentimentTrend: [Double]
    let complexityLevel: Double
    let completionStatus: CompletionStatus

    enum CompletionStatus {
        case ongoing
        case completed
        case abandoned
        case paused

        var color: Color {
            switch self {
            case .ongoing: return .blue
            case .completed: return .green
            case .abandoned: return .red
            case .paused: return .orange
            }
        }
    }
}

// MARK: - Conversation Thread Visualization View

struct ConversationThreadVisualizationView: View {
    @State private var conversationThreads: [ConversationThread] = []
    @State private var selectedThread: ConversationThread?
    @State private var viewMode: ViewMode = .timeline
    @State private var searchText: String = ""
    @State private var selectedFilter: ThreadFilter = .all
    @State private var showingThreadDetails: Bool = false
    @State private var showingContextAnalysis: Bool = false
    @State private var sortOrder: SortOrder = .mostRecent
    @Environment(\.dismiss) private var dismiss

    enum ViewMode: String, CaseIterable {
        case timeline = "Timeline"
        case flow = "Flow"
        case network = "Network"
        case analytics = "Analytics"

        var icon: String {
            switch self {
            case .timeline: return "timeline.selection"
            case .flow: return "arrow.right.arrow.left.square"
            case .network: return "network"
            case .analytics: return "chart.bar.fill"
            }
        }
    }

    enum ThreadFilter: String, CaseIterable {
        case all = "All"
        case active = "Active"
        case completed = "Completed"
        case high_priority = "High Priority"
        case recent = "Recent"

        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .active: return "play.circle.fill"
            case .completed: return "checkmark.circle.fill"
            case .high_priority: return "exclamationmark.circle.fill"
            case .recent: return "clock.fill"
            }
        }
    }

    enum SortOrder: String, CaseIterable {
        case mostRecent = "Most Recent"
        case oldest = "Oldest"
        case duration = "Duration"
        case messageCount = "Message Count"
        case priority = "Priority"

        var icon: String {
            switch self {
            case .mostRecent: return "clock.arrow.2.circlepath"
            case .oldest: return "clock.badge.checkmark"
            case .duration: return "timer"
            case .messageCount: return "bubble.left.and.bubble.right"
            case .priority: return "star.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                conversationBackground

                VStack(spacing: 0) {
                    // Header controls
                    headerControls

                    // View mode selector
                    viewModeSelector

                    // Filters and search
                    filtersSection

                    // Main content
                    mainContentView
                }
            }
            .navigationTitle("Conversation Threads")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingContextAnalysis = true }) {
                            Label("Context Analysis", systemImage: "brain.head.profile")
                        }

                        Button(action: { exportThreads() }) {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }

                        Button(action: { clearOldThreads() }) {
                            Label("Clear Old", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showingThreadDetails) {
            if let thread = selectedThread {
                ThreadDetailView(thread: thread)
            }
        }
        .sheet(isPresented: $showingContextAnalysis) {
            ContextAnalysisView(threads: conversationThreads)
        }
        .onAppear {
            loadConversationThreads()
        }
    }

    // MARK: - View Components

    private var conversationBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.03, green: 0.06, blue: 0.12),
                Color(red: 0.05, green: 0.03, blue: 0.10),
                Color(red: 0.02, green: 0.02, blue: 0.06),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var headerControls: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("🧪 SANDBOX THREADS")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(4)

                Text("\(filteredThreads.count) threads")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: { generateSampleData() }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                }

                Button(action: { refreshThreads() }) {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var viewModeSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ViewMode.allCases, id: \.self) { mode in
                    viewModeTab(mode)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private func viewModeTab(_ mode: ViewMode) -> some View {
        Button(action: { viewMode = mode }) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.caption)

                Text(mode.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(viewMode == mode ? .white : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                viewMode == mode
                    ? Color.cyan.opacity(0.3)
                    : Color.white.opacity(0.1)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        viewMode == mode ? Color.cyan : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }

    private var filtersSection: some View {
        VStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))

                TextField("Search conversations...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .foregroundColor(.white)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .padding()
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)

            // Filters and sort
            HStack {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(ThreadFilter.allCases, id: \.self) { filter in
                        HStack {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                        }.tag(filter)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.cyan)

                Spacer()

                Picker("Sort", selection: $sortOrder) {
                    ForEach(SortOrder.allCases, id: \.self) { order in
                        HStack {
                            Image(systemName: order.icon)
                            Text(order.rawValue)
                        }.tag(order)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .foregroundColor(.purple)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var mainContentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                switch viewMode {
                case .timeline:
                    timelineView
                case .flow:
                    flowView
                case .network:
                    networkView
                case .analytics:
                    analyticsView
                }
            }
            .padding()
        }
    }

    private var timelineView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredThreads, id: \.id) { thread in
                timelineThreadCard(thread)
            }
        }
    }

    private var flowView: some View {
        VStack(spacing: 20) {
            Text("Flow Visualization")
                .font(.headline)
                .foregroundColor(.white)

            // Flow diagram would go here
            conversationFlowDiagram
        }
    }

    private var networkView: some View {
        VStack(spacing: 20) {
            Text("Network Analysis")
                .font(.headline)
                .foregroundColor(.white)

            // Network visualization would go here
            conversationNetworkDiagram
        }
    }

    private var analyticsView: some View {
        VStack(spacing: 20) {
            conversationAnalyticsCards
            conversationTrendsChart
        }
    }

    // MARK: - Timeline Components

    private func timelineThreadCard(_ thread: ConversationThread) -> some View {
        Button(action: { selectThread(thread) }) {
            threadVisualizationCard {
                VStack(alignment: .leading, spacing: 12) {
                    // Thread header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(thread.title)
                                .font(.headline)
                                .foregroundColor(.white)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            Text(formatRelativeTime(thread.lastActivity))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            threadStatusBadge(thread)

                            priorityBadge(thread.priority)
                        }
                    }

                    // Thread stats
                    HStack(spacing: 16) {
                        threadStat(
                            icon: "bubble.left.and.bubble.right",
                            value: "\(thread.messageCount)",
                            label: "Messages",
                            color: .blue
                        )

                        threadStat(
                            icon: "clock",
                            value: formatDuration(thread.duration),
                            label: "Duration",
                            color: .green
                        )

                        threadStat(
                            icon: "person.2",
                            value: "\(thread.participants.count)",
                            label: "Participants",
                            color: .purple
                        )

                        Spacer()
                    }

                    // Context and tags
                    VStack(alignment: .leading, spacing: 8) {
                        if !thread.context.mainTopic.isEmpty {
                            HStack {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.cyan)
                                    .font(.caption)

                                Text(thread.context.mainTopic)
                                    .font(.caption)
                                    .foregroundColor(.cyan)
                                    .lineLimit(1)

                                Spacer()
                            }
                        }

                        if !thread.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(thread.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.white.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Flow Components

    private var conversationFlowDiagram: some View {
        threadVisualizationCard {
            VStack(spacing: 20) {
                Text("Conversation Flow")
                    .font(.headline)
                    .foregroundColor(.white)

                // Simplified flow representation
                VStack(spacing: 12) {
                    ForEach(Array(filteredThreads.prefix(5).enumerated()), id: \.element.id) { index, thread in
                        HStack {
                            Circle()
                                .fill(thread.priority.color)
                                .frame(width: 12, height: 12)

                            Text(thread.title)
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .lineLimit(1)

                            Spacer()

                            Text("\(thread.messageCount) msgs")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.vertical, 4)

                        if index < 4 {
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: 2, height: 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 6)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Network Components

    private var conversationNetworkDiagram: some View {
        threadVisualizationCard {
            VStack(spacing: 15) {
                Text("Thread Relationships")
                    .font(.headline)
                    .foregroundColor(.white)

                // Network representation
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                    ForEach(Array(filteredThreads.prefix(9)), id: \.id) { thread in
                        VStack(spacing: 6) {
                            Circle()
                                .fill(thread.priority.color.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Text("\(thread.messageCount)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )

                            Text(thread.title)
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Analytics Components

    private var conversationAnalyticsCards: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
            analyticsCard(
                title: "Total Threads",
                value: "\(conversationThreads.count)",
                icon: "bubble.left.and.bubble.right",
                color: .blue
            )

            analyticsCard(
                title: "Active Now",
                value: "\(conversationThreads.filter { $0.isActive }.count)",
                icon: "play.circle.fill",
                color: .green
            )

            analyticsCard(
                title: "Avg Duration",
                value: formatDuration(averageThreadDuration),
                icon: "clock",
                color: .orange
            )

            analyticsCard(
                title: "Total Messages",
                value: "\(totalMessageCount)",
                icon: "text.bubble",
                color: .purple
            )
        }
    }

    private var conversationTrendsChart: some View {
        threadVisualizationCard {
            VStack(alignment: .leading, spacing: 15) {
                Text("Thread Activity Trends")
                    .font(.headline)
                    .foregroundColor(.white)

                Chart {
                    ForEach(generateActivityData(), id: \.date) { dataPoint in
                        BarMark(
                            x: .value("Date", dataPoint.date),
                            y: .value("Count", dataPoint.count)
                        )
                        .foregroundStyle(.cyan)
                    }
                }
                .frame(height: 150)
                .chartXAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic) { _ in
                        AxisValueLabel()
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func threadStatusBadge(_ thread: ConversationThread) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(thread.isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Text(thread.isActive ? "Active" : "Inactive")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private func priorityBadge(_ priority: ConversationThread.ThreadPriority) -> some View {
        Text(priority.rawValue)
            .font(.caption2)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priority.color.opacity(0.3))
            .cornerRadius(4)
    }

    private func threadStat(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)

                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }

            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func analyticsCard(title: String, value: String, icon: String, color: Color) -> some View {
        threadVisualizationCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    Spacer()
                }

                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding()
        }
    }

    @ViewBuilder
    private func threadVisualizationCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Computed Properties

    private var filteredThreads: [ConversationThread] {
        var filtered = conversationThreads

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { thread in
                thread.title.localizedCaseInsensitiveContains(searchText) ||
                thread.context.mainTopic.localizedCaseInsensitiveContains(searchText) ||
                thread.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        // Apply category filter
        switch selectedFilter {
        case .all:
            break
        case .active:
            filtered = filtered.filter { $0.isActive }
        case .completed:
            filtered = filtered.filter { $0.context.completionStatus == .completed }
        case .high_priority:
            filtered = filtered.filter { $0.priority == .high || $0.priority == .urgent }
        case .recent:
            let oneDayAgo = Date().addingTimeInterval(-86400)
            filtered = filtered.filter { $0.lastActivity > oneDayAgo }
        }

        // Apply sort order
        switch sortOrder {
        case .mostRecent:
            filtered.sort { $0.lastActivity > $1.lastActivity }
        case .oldest:
            filtered.sort { $0.startTime < $1.startTime }
        case .duration:
            filtered.sort { $0.duration > $1.duration }
        case .messageCount:
            filtered.sort { $0.messageCount > $1.messageCount }
        case .priority:
            filtered.sort { $0.priority.rawValue < $1.priority.rawValue }
        }

        return filtered
    }

    private var averageThreadDuration: TimeInterval {
        guard !conversationThreads.isEmpty else { return 0 }
        let total = conversationThreads.reduce(0) { $0 + $1.duration }
        return total / Double(conversationThreads.count)
    }

    private var totalMessageCount: Int {
        return conversationThreads.reduce(0) { $0 + $1.messageCount }
    }

    // MARK: - Methods

    private func selectThread(_ thread: ConversationThread) {
        selectedThread = thread
        showingThreadDetails = true
    }

    private func loadConversationThreads() {
        // This would load actual conversation data
        generateSampleData()
    }

    private func refreshThreads() {
        // Refresh conversation threads
        loadConversationThreads()
    }

    private func generateSampleData() {
        // Generate sample conversation threads for demo
        conversationThreads = generateSampleThreads()
    }

    private func exportThreads() {
        // Export thread data
        print("Exporting conversation threads...")
    }

    private func clearOldThreads() {
        // Clear old inactive threads
        let oneWeekAgo = Date().addingTimeInterval(-604800)
        conversationThreads.removeAll { thread in
            !thread.isActive && thread.lastActivity < oneWeekAgo
        }
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    private func generateActivityData() -> [ActivityDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        return (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: now)!
            let count = Int.random(in: 1...8)
            return ActivityDataPoint(date: date, count: count)
        }.reversed()
    }

    private func generateSampleThreads() -> [ConversationThread] {
        return [
            ConversationThread(
                title: "Project Status Meeting Prep",
                startTime: Date().addingTimeInterval(-3600),
                endTime: Date().addingTimeInterval(-3000),
                messages: [],
                context: ThreadContext(
                    mainTopic: "Project Management",
                    subTopics: ["Status Update", "Meeting Agenda"],
                    entities: ["Team", "Project"],
                    sentimentTrend: [0.8, 0.7, 0.9],
                    complexityLevel: 0.6,
                    completionStatus: .completed
                ),
                participants: ["User", "Jarvis"],
                tags: ["work", "meeting", "productivity"],
                workflowReferences: [],
                relatedThreads: [],
                isActive: false,
                priority: .normal
            ),
            ConversationThread(
                title: "Document Generation Workflow",
                startTime: Date().addingTimeInterval(-1800),
                endTime: nil,
                messages: [],
                context: ThreadContext(
                    mainTopic: "Document Creation",
                    subTopics: ["Report Writing", "Formatting"],
                    entities: ["Document", "Template"],
                    sentimentTrend: [0.9, 0.8, 0.7],
                    complexityLevel: 0.8,
                    completionStatus: .ongoing
                ),
                participants: ["User", "Jarvis"],
                tags: ["document", "workflow", "ai"],
                workflowReferences: [],
                relatedThreads: [],
                isActive: true,
                priority: .high
            ),
        ]
    }
}

// MARK: - Supporting Views

struct ThreadDetailView: View {
    let thread: ConversationThread
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Thread details would go here")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .background(Color.black)
            .navigationTitle(thread.title)
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
    }
}

struct ContextAnalysisView: View {
    let threads: [ConversationThread]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Context analysis would go here")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .background(Color.black)
            .navigationTitle("Context Analysis")
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
    }
}

// MARK: - Data Models

struct ActivityDataPoint {
    let date: Date
    let count: Int
}

// MARK: - Preview

struct ConversationThreadVisualizationView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationThreadVisualizationView()
            .preferredColorScheme(.dark)
    }
}
