// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Context-aware help system with smart suggestions and interactive guidance for voice interactions
 * Issues & Complexity Summary: Dynamic help content, context awareness, suggestion filtering, interactive tutorials
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400+
 *   - Core Algorithm Complexity: Medium (Context analysis, suggestion filtering, help content generation)
 *   - Dependencies: 3 New (SwiftUI, Combine, NaturalLanguage)
 *   - State Management Complexity: Medium (Help states, suggestion filtering, tutorial progress)
 *   - Novelty/Uncertainty Factor: Medium (Context-aware help patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 70%
 * Problem Estimate (Inherent Problem Difficulty %): 65%
 * Initial Code Complexity Estimate %: 68%
 * Justification for Estimates: Context help system with smart filtering and interactive guidance
 * Final Code Complexity (Actual %): 74%
 * Overall Result Score (Success & Quality %): 89%
 * Key Variances/Learnings: Context help requires good UX patterns and clear information hierarchy
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine

// MARK: - Context Help View

struct ContextHelpView: View {
    let suggestions: [UIContextSuggestion]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedHelpCategory: HelpCategory = .gettingStarted
    @State private var searchText: String = ""
    @State private var showingTutorial: Bool = false
    @State private var selectedSuggestion: UIContextSuggestion?
    @State private var filteredSuggestions: [UIContextSuggestion] = []

    enum HelpCategory: String, CaseIterable {
        case gettingStarted = "Getting Started"
        case voiceCommands = "Voice Commands"
        case workflows = "Workflows"
        case troubleshooting = "Troubleshooting"
        case tips = "Tips & Tricks"
        case advanced = "Advanced"

        var icon: String {
            switch self {
            case .gettingStarted: return "play.circle.fill"
            case .voiceCommands: return "mic.fill"
            case .workflows: return "list.bullet.rectangle"
            case .troubleshooting: return "wrench.and.screwdriver.fill"
            case .tips: return "lightbulb.fill"
            case .advanced: return "gear.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .gettingStarted: return .green
            case .voiceCommands: return .blue
            case .workflows: return .purple
            case .troubleshooting: return .orange
            case .tips: return .yellow
            case .advanced: return .red
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                contextHelpBackground

                VStack(spacing: 0) {
                    // Search and filters
                    searchSection

                    // Category selector
                    categorySelector

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            // Current suggestions section
                            if !filteredSuggestions.isEmpty {
                                currentSuggestionsSection
                            }

                            // Help content based on category
                            helpContentSection

                            // Quick actions
                            quickActionsSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Context Help")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTutorial = true }) {
                        Image(systemName: "play.rectangle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .sheet(isPresented: $showingTutorial) {
            InteractiveTutorialView()
        }
        .sheet(item: $selectedSuggestion) { suggestion in
            SuggestionDetailView(suggestion: suggestion)
        }
        .onAppear {
            updateFilteredSuggestions()
        }
        .onChange(of: searchText) { _ in
            updateFilteredSuggestions()
        }
        .onChange(of: selectedHelpCategory) { _ in
            updateFilteredSuggestions()
        }
    }

    // MARK: - View Components

    private var contextHelpBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.04, green: 0.08, blue: 0.18),
                Color(red: 0.06, green: 0.04, blue: 0.15),
                Color(red: 0.02, green: 0.02, blue: 0.08),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var searchSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.7))

                TextField("Search help topics...", text: $searchText)
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

            Text("🧪 SANDBOX HELP")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    categoryTab(category)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private func categoryTab(_ category: HelpCategory) -> some View {
        Button(action: { selectedHelpCategory = category }) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedHelpCategory == category ? .white : .white.opacity(0.7))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                selectedHelpCategory == category
                    ? category.color.opacity(0.3)
                    : Color.white.opacity(0.1)
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        selectedHelpCategory == category
                            ? category.color
                            : Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }

    private var currentSuggestionsSection: some View {
        contextHelpCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.cyan)

                    Text("Smart Suggestions")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(filteredSuggestions.count)")
                        .font(.caption)
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.2))
                        .cornerRadius(8)
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 1), spacing: 12) {
                    ForEach(filteredSuggestions, id: \.id) { suggestion in
                        suggestionRow(suggestion)
                    }
                }
            }
            .padding()
        }
    }

    private var helpContentSection: some View {
        contextHelpCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: selectedHelpCategory.icon)
                        .font(.title2)
                        .foregroundColor(selectedHelpCategory.color)

                    Text(selectedHelpCategory.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                helpContentForCategory
            }
            .padding()
        }
    }

    @ViewBuilder
    private var helpContentForCategory: some View {
        switch selectedHelpCategory {
        case .gettingStarted:
            gettingStartedContent
        case .voiceCommands:
            voiceCommandsContent
        case .workflows:
            workflowsContent
        case .troubleshooting:
            troubleshootingContent
        case .tips:
            tipsContent
        case .advanced:
            advancedContent
        }
    }

    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            helpSection(
                title: "Welcome to Jarvis Live!",
                content: "Your AI-powered voice assistant for productivity and automation.",
                icon: "hand.wave.fill",
                color: .green
            )

            helpSection(
                title: "First Steps",
                content: "1. Grant microphone permissions\n2. Try saying 'Hello Jarvis'\n3. Explore available workflows",
                icon: "list.number",
                color: .blue
            )

            helpSection(
                title: "Voice Quality",
                content: "Speak clearly and in a quiet environment for best results. The system learns from your voice patterns.",
                icon: "waveform",
                color: .purple
            )
        }
    }

    private var voiceCommandsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            helpSection(
                title: "Basic Commands",
                content: "• 'Generate document about [topic]'\n• 'Send email to [contact]'\n• 'Schedule meeting for [time]'\n• 'Search for [query]'",
                icon: "mic.circle.fill",
                color: .blue
            )

            helpSection(
                title: "Command Tips",
                content: "Be specific with your requests. Instead of 'send email', say 'send email to John about project update'.",
                icon: "lightbulb.fill",
                color: .yellow
            )

            helpSection(
                title: "Context Awareness",
                content: "Jarvis remembers conversation context. You can say 'send that to Sarah' after generating a document.",
                icon: "brain.head.profile",
                color: .cyan
            )
        }
    }

    private var workflowsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            helpSection(
                title: "What are Workflows?",
                content: "Multi-step automated processes that combine several voice commands into a sequence.",
                icon: "arrow.right.arrow.left",
                color: .purple
            )

            helpSection(
                title: "Starting Workflows",
                content: "Say 'Start [workflow name]' or select from the available workflows in the main interface.",
                icon: "play.circle.fill",
                color: .green
            )

            helpSection(
                title: "Custom Workflows",
                content: "Create your own workflows using the Workflow Builder. Combine any supported voice commands.",
                icon: "wrench.and.screwdriver.fill",
                color: .orange
            )
        }
    }

    private var troubleshootingContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            helpSection(
                title: "Voice Not Recognized",
                content: "• Check microphone permissions\n• Reduce background noise\n• Speak more clearly\n• Check internet connection",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            )

            helpSection(
                title: "Slow Response",
                content: "• Verify internet connection\n• Check server status\n• Try simpler commands first",
                icon: "clock.arrow.circlepath",
                color: .blue
            )

            helpSection(
                title: "Commands Not Working",
                content: "• Ensure command is supported\n• Check command syntax\n• Try alternative phrasing",
                icon: "xmark.circle.fill",
                color: .red
            )
        }
    }

    private var tipsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            helpSection(
                title: "Pro Tips",
                content: "• Use 'please' and 'thank you' for better interaction\n• Speak at normal conversation pace\n• Be specific with your requests",
                icon: "star.fill",
                color: .yellow
            )

            helpSection(
                title: "Efficiency Tips",
                content: "• Create custom workflows for repeated tasks\n• Use context to chain commands\n• Review analytics to optimize usage",
                icon: "speedometer",
                color: .green
            )

            helpSection(
                title: "Voice Training",
                content: "The more you use Jarvis, the better it learns your voice patterns and preferences.",
                icon: "brain.head.profile.fill",
                color: .purple
            )
        }
    }

    private var advancedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            helpSection(
                title: "MCP Integration",
                content: "Jarvis uses Meta-Cognitive Primitive servers for enhanced functionality and document generation.",
                icon: "cube.transparent.fill",
                color: .cyan
            )

            helpSection(
                title: "Live Audio Processing",
                content: "Real-time audio processing using LiveKit for low-latency voice interactions.",
                icon: "waveform.path.ecg",
                color: .green
            )

            helpSection(
                title: "AI Providers",
                content: "Multiple AI providers (Claude, GPT, Gemini) are available based on task requirements and cost optimization.",
                icon: "brain.fill",
                color: .pink
            )
        }
    }

    private var quickActionsSection: some View {
        contextHelpCard {
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

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    quickActionButton("Start Tutorial", "play.rectangle.fill", .green) {
                        showingTutorial = true
                    }

                    quickActionButton("View Analytics", "chart.bar.fill", .blue) {
                        // Would navigate to analytics
                    }

                    quickActionButton("Reset Voice", "arrow.clockwise.circle.fill", .orange) {
                        // Would reset voice training
                    }

                    quickActionButton("Contact Support", "questionmark.circle.fill", .purple) {
                        // Would open support
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func suggestionRow(_ suggestion: UIContextSuggestion) -> some View {
        Button(action: { selectedSuggestion = suggestion }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: suggestion.category.icon)
                    .foregroundColor(suggestion.category.color)
                    .font(.headline)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Text("Say: \"\(suggestion.examplePhrase)\"")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .italic()

                    HStack {
                        Text(suggestion.category.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression))
                            .font(.caption2)
                            .foregroundColor(suggestion.category.color)

                        Spacer()

                        Text("\(Int(suggestion.confidence * 100))% confidence")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.4))
                    .font(.caption)
            }
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func helpSection(title: String, content: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.headline)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()
            }

            Text(content)
                .font(.body)
                .foregroundColor(.white.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    private func quickActionButton(_ title: String, _ icon: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(height: 70)
            .frame(maxWidth: .infinity)
            .background(color.opacity(0.2))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private func contextHelpCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Methods

    private func updateFilteredSuggestions() {
        var filtered = suggestions

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { suggestion in
                suggestion.text.localizedCaseInsensitiveContains(searchText) ||
                suggestion.examplePhrase.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Sort by relevance and confidence
        filtered.sort { first, second in
            if first.relevanceScore != second.relevanceScore {
                return first.relevanceScore > second.relevanceScore
            }
            return first.confidence > second.confidence
        }

        filteredSuggestions = Array(filtered.prefix(5)) // Limit to top 5
    }
}

// MARK: - Supporting Views

struct InteractiveTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Interactive Tutorial")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .padding()

                Text("Tutorial content would go here")
                    .foregroundColor(.white.opacity(0.8))
                    .padding()

                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Tutorial")
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

struct SuggestionDetailView: View {
    let suggestion: UIContextSuggestion
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: suggestion.category.icon)
                                .foregroundColor(suggestion.category.color)
                                .font(.title)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.text)
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(suggestion.category.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression))
                                    .font(.caption)
                                    .foregroundColor(suggestion.category.color)
                            }

                            Spacer()
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Example Phrase:")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Text("\"\(suggestion.examplePhrase)\"")
                                .font(.body)
                                .foregroundColor(.green)
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(8)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Confidence")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                Text("\(Int(suggestion.confidence * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Relevance")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))

                                Text("\(Int(suggestion.relevanceScore * 100))%")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Suggestion Details")
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

// MARK: - Preview

struct ContextHelpView_Previews: PreviewProvider {
    static var previews: some View {
        ContextHelpView(suggestions: [])
            .preferredColorScheme(.dark)
    }
}
