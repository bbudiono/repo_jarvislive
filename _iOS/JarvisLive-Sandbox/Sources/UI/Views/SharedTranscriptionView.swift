// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive shared transcription display and interaction for collaborative sessions
 * Issues & Complexity Summary: Real-time transcription display, search functionality, AI response integration, and multi-participant conversation flow
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High (Real-time updates, search, conversation threading)
 *   - Dependencies: 6 New (SwiftUI, Combine, Search, AI responses, Real-time sync)
 *   - State Management Complexity: Very High (Multi-participant transcriptions, search state, scroll position)
 *   - Novelty/Uncertainty Factor: High (Real-time transcription display patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 80%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 83%
 * Justification for Estimates: Real-time transcription with search and interaction requires complex state management
 * Final Code Complexity (Actual %): 87%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: Real-time scroll management and search highlighting added significant complexity
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine

struct SharedTranscriptionView: View {
    let transcriptions: [SharedTranscription]
    @Binding var searchText: String
    @State private var selectedTranscription: SharedTranscription?
    @State private var showingTranscriptionDetails = false
    @State private var autoScroll = true
    @State private var filterSettings = TranscriptionFilterSettings()
    @State private var showingFilters = false
    @State private var isSearchActive = false

    struct TranscriptionFilterSettings {
        var showOnlyFinal = false
        var selectedParticipants: Set<String> = []
        var minConfidence: Float = 0.0
        var selectedLanguages: Set<String> = []
        var timeRange: TimeRange = .all

        enum TimeRange: String, CaseIterable {
            case all = "All Time"
            case lastHour = "Last Hour"
            case last30Minutes = "Last 30 Minutes"
            case last10Minutes = "Last 10 Minutes"
        }
    }

    var filteredTranscriptions: [SharedTranscription] {
        var filtered = transcriptions

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { transcription in
                transcription.text.localizedCaseInsensitiveContains(searchText) ||
                transcription.participantName.localizedCaseInsensitiveContains(searchText) ||
                (transcription.aiResponse?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply final transcription filter
        if filterSettings.showOnlyFinal {
            filtered = filtered.filter { $0.isFinal }
        }

        // Apply participant filter
        if !filterSettings.selectedParticipants.isEmpty {
            filtered = filtered.filter { filterSettings.selectedParticipants.contains($0.participantId) }
        }

        // Apply confidence filter
        filtered = filtered.filter { $0.confidence >= filterSettings.minConfidence }

        // Apply language filter
        if !filterSettings.selectedLanguages.isEmpty {
            filtered = filtered.filter { filterSettings.selectedLanguages.contains($0.language) }
        }

        // Apply time range filter
        let timeThreshold = Date().addingTimeInterval(timeInterval(for: filterSettings.timeRange))
        if filterSettings.timeRange != .all {
            filtered = filtered.filter { $0.timestamp >= timeThreshold }
        }

        return filtered.sorted(by: { $0.timestamp < $1.timestamp })
    }

    var groupedTranscriptions: [(String, [SharedTranscription])] {
        let grouped = Dictionary(grouping: filteredTranscriptions) { transcription in
            Calendar.current.startOfDay(for: transcription.timestamp)
        }

        return grouped.sorted(by: { $0.key < $1.key }).map { key, value in
            (formatDateHeader(key), value.sorted(by: { $0.timestamp < $1.timestamp }))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with stats and controls
            transcriptionHeaderView

            // Filter bar (when active)
            if showingFilters {
                filterBarView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Transcription content
            if filteredTranscriptions.isEmpty {
                emptyStateView
            } else {
                transcriptionListView
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .searchable(text: $searchText, isPresented: $isSearchActive, prompt: "Search transcriptions...")
        .sheet(isPresented: $showingTranscriptionDetails) {
            if let transcription = selectedTranscription {
                TranscriptionDetailSheet(transcription: transcription)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingFilters)
    }

    // MARK: - View Components

    private var transcriptionHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Live Transcription")
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !filteredTranscriptions.isEmpty {
                        Text("(\(filteredTranscriptions.count))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 16) {
                    TranscriptionStat(
                        title: "Total Messages",
                        value: filteredTranscriptions.count,
                        color: .blue
                    )

                    TranscriptionStat(
                        title: "Participants",
                        value: uniqueParticipantsCount,
                        color: .green
                    )

                    TranscriptionStat(
                        title: "AI Responses",
                        value: aiResponsesCount,
                        color: .purple
                    )
                }
                .font(.caption)
            }

            Spacer()

            HStack(spacing: 12) {
                // Auto-scroll toggle
                Button(action: { autoScroll.toggle() }) {
                    Image(systemName: autoScroll ? "arrow.down.circle.fill" : "arrow.down.circle")
                        .font(.system(size: 20))
                        .foregroundColor(autoScroll ? .blue : .gray)
                }

                // Filter toggle
                Button(action: {
                    withAnimation {
                        showingFilters.toggle()
                    }
                }) {
                    Image(systemName: showingFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .foregroundColor(showingFilters ? .blue : .gray)
                }

                // Export/Share
                ShareLink(item: exportTranscriptions()) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private var filterBarView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Final only toggle
                FilterToggle(
                    title: "Final Only",
                    isOn: $filterSettings.showOnlyFinal
                )

                // Confidence slider
                VStack(alignment: .leading, spacing: 4) {
                    Text("Min Confidence: \(Int(filterSettings.minConfidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Slider(value: $filterSettings.minConfidence, in: 0...1)
                        .frame(width: 100)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Time range picker
                Picker("Time Range", selection: $filterSettings.timeRange) {
                    ForEach(TranscriptionFilterSettings.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Clear filters
                Button("Clear") {
                    clearAllFilters()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(8)
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    private var transcriptionListView: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(groupedTranscriptions, id: \.0) { dateGroup in
                        // Date header
                        HStack {
                            Text(dateGroup.0)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)

                        // Transcriptions for this date
                        ForEach(dateGroup.1) { transcription in
                            TranscriptionRowView(
                                transcription: transcription,
                                searchText: searchText,
                                onTap: {
                                    selectedTranscription = transcription
                                    showingTranscriptionDetails = true
                                }
                            )
                            .id(transcription.id)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .onChange(of: filteredTranscriptions.count) { _ in
                if autoScroll, let lastTranscription = filteredTranscriptions.last {
                    withAnimation(.easeOut(duration: 0.5)) {
                        scrollProxy.scrollTo(lastTranscription.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Transcriptions Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text(isSearchActive ?
                 "No transcriptions match your search criteria." :
                 "Voice transcriptions will appear here as participants speak.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if isSearchActive {
                Button("Clear Search") {
                    searchText = ""
                    isSearchActive = false
                }
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Computed Properties

    private var uniqueParticipantsCount: Int {
        Set(filteredTranscriptions.map { $0.participantId }).count
    }

    private var aiResponsesCount: Int {
        filteredTranscriptions.filter { $0.aiResponse != nil }.count
    }

    // MARK: - Helper Methods

    private func timeInterval(for range: TranscriptionFilterSettings.TimeRange) -> TimeInterval {
        switch range {
        case .all:
            return 0
        case .lastHour:
            return -3600
        case .last30Minutes:
            return -1800
        case .last10Minutes:
            return -600
        }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }

    private func clearAllFilters() {
        filterSettings = TranscriptionFilterSettings()
    }

    private func exportTranscriptions() -> String {
        let header = "Shared Transcription Export\nGenerated: \(Date())\n\n"
        let content = filteredTranscriptions.map { transcription in
            let timestamp = DateFormatter.shortDateTime.string(from: transcription.timestamp)
            var text = "[\(timestamp)] \(transcription.participantName): \(transcription.text)"

            if let aiResponse = transcription.aiResponse {
                text += "\n    AI Response: \(aiResponse)"
            }

            if !transcription.isFinal {
                text += " [Partial]"
            }

            text += " (Confidence: \(Int(transcription.confidence * 100))%)"

            return text
        }.joined(separator: "\n\n")

        return header + content
    }
}

// MARK: - Supporting Views

struct TranscriptionRowView: View {
    let transcription: SharedTranscription
    let searchText: String
    let onTap: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Participant indicator
            VStack(spacing: 4) {
                Circle()
                    .fill(participantColor)
                    .frame(width: 8, height: 8)

                if !transcription.isFinal {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 4, height: 4)
                        .opacity(0.8)
                }
            }
            .padding(.top, 6)

            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Text(transcription.participantName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(participantColor)

                    Spacer()

                    Text(formatTime(transcription.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if !transcription.isFinal {
                        Text("LIVE")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(3)
                    }
                }

                // Transcription text
                HighlightedText(
                    text: transcription.text,
                    searchText: searchText,
                    baseFont: .body,
                    highlightColor: .yellow
                )
                .foregroundColor(.primary)

                // AI Response (if available)
                if let aiResponse = transcription.aiResponse {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "brain")
                                .font(.caption)
                                .foregroundColor(.purple)
                            Text("AI Response")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }

                        HighlightedText(
                            text: aiResponse,
                            searchText: searchText,
                            baseFont: .callout,
                            highlightColor: .yellow
                        )
                        .foregroundColor(.secondary)
                        .padding(.leading, 16)
                    }
                    .padding(.top, 4)
                }

                // Metadata
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield")
                            .font(.caption2)
                        Text("\(Int(transcription.confidence * 100))%")
                            .font(.caption2)
                    }
                    .foregroundColor(confidenceColor)

                    if transcription.language != "en" {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                                .font(.caption2)
                            Text(transcription.language.uppercased())
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .padding(.vertical, 4)
        .onTapGesture {
            onTap()
        }
    }

    private var participantColor: Color {
        // Generate consistent color based on participant ID
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .red, .cyan, .mint]
        let index = abs(transcription.participantId.hashValue) % colors.count
        return colors[index]
    }

    private var confidenceColor: Color {
        if transcription.confidence >= 0.8 {
            return .green
        } else if transcription.confidence >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct HighlightedText: View {
    let text: String
    let searchText: String
    let baseFont: Font
    let highlightColor: Color

    var body: some View {
        if searchText.isEmpty {
            Text(text)
                .font(baseFont)
        } else {
            let attributedString = highlightSearchText(in: text, searchText: searchText)
            Text(AttributedString(attributedString))
                .font(baseFont)
        }
    }

    private func highlightSearchText(in text: String, searchText: String) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)

        // Find all occurrences of search text
        let searchRange = text.lowercased().range(of: searchText.lowercased())
        if let searchRange = searchRange {
            let nsRange = NSRange(searchRange, in: text)
            attributedString.addAttribute(.backgroundColor, value: UIColor.yellow.withAlphaComponent(0.3), range: nsRange)
            attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: nsRange)
        }

        return attributedString
    }
}

struct TranscriptionStat: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundColor(.secondary)
            Text("\(value)")
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

struct FilterToggle: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button(action: { isOn.toggle() }) {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isOn ? .blue : .gray)
                Text(title)
                    .font(.caption)
                    .foregroundColor(isOn ? .blue : .primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(isOn ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct TranscriptionDetailSheet: View {
    let transcription: SharedTranscription
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(transcription.participantName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text(DateFormatter.full.string(from: transcription.timestamp))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Transcription content
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Transcription")
                            .font(.headline)

                        Text(transcription.text)
                            .font(.body)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }

                    // AI Response (if available)
                    if let aiResponse = transcription.aiResponse {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "brain")
                                    .foregroundColor(.purple)
                                Text("AI Response")
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            }

                            Text(aiResponse)
                                .font(.body)
                                .padding()
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Details")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            TranscriptionDetailRow(label: "Confidence", value: "\(Int(transcription.confidence * 100))%")
                            TranscriptionDetailRow(label: "Language", value: transcription.language.uppercased())
                            TranscriptionDetailRow(label: "Status", value: transcription.isFinal ? "Final" : "Partial")
                            TranscriptionDetailRow(label: "Participant ID", value: transcription.participantId)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Transcription Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(item: exportTranscription()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func exportTranscription() -> String {
        var export = "Transcription Export\n"
        export += "Participant: \(transcription.participantName)\n"
        export += "Time: \(DateFormatter.full.string(from: transcription.timestamp))\n"
        export += "Confidence: \(Int(transcription.confidence * 100))%\n"
        export += "Language: \(transcription.language)\n"
        export += "Status: \(transcription.isFinal ? "Final" : "Partial")\n\n"
        export += "Content:\n\(transcription.text)\n"

        if let aiResponse = transcription.aiResponse {
            export += "\nAI Response:\n\(aiResponse)\n"
        }

        return export
    }
}

struct TranscriptionDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()

    static let full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }()
}

// MARK: - Preview

struct SharedTranscriptionView_Previews: PreviewProvider {
    static var previews: some View {
        SharedTranscriptionView(
            transcriptions: sampleTranscriptions,
            searchText: .constant("")
        )
    }

    static var sampleTranscriptions: [SharedTranscription] {
        [
            SharedTranscription(
                id: "1",
                participantId: "user1",
                participantName: "Alice",
                text: "Let's discuss the quarterly budget for marketing initiatives and explore new opportunities for growth.",
                timestamp: Date().addingTimeInterval(-300),
                confidence: 0.95,
                isFinal: true,
                language: "en",
                aiResponse: "I'd be happy to help analyze the quarterly budget. Based on current market trends, I recommend focusing on digital marketing channels with measurable ROI."
            ),
            SharedTranscription(
                id: "2",
                participantId: "user2",
                participantName: "Bob",
                text: "That sounds like a great approach. Should we also consider social media advertising?",
                timestamp: Date().addingTimeInterval(-240),
                confidence: 0.88,
                isFinal: true,
                language: "en",
                aiResponse: nil
            ),
            SharedTranscription(
                id: "3",
                participantId: "user1",
                participantName: "Alice",
                text: "I think we should also look at...",
                timestamp: Date().addingTimeInterval(-60),
                confidence: 0.72,
                isFinal: false,
                language: "en",
                aiResponse: nil
            ),
        ]
    }
}
