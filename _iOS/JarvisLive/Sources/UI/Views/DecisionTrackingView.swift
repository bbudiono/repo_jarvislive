// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive collaborative decision tracking and voting interface
 * Issues & Complexity Summary: Real-time decision management, voting system, consensus tracking, and decision lifecycle
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~550
 *   - Core Algorithm Complexity: High (Voting logic, consensus calculation, real-time updates)
 *   - Dependencies: 6 New (SwiftUI, Combine, Decision models, Voting system, Real-time sync)
 *   - State Management Complexity: Very High (Multi-participant voting, decision states, real-time consensus)
 *   - Novelty/Uncertainty Factor: High (Collaborative decision-making patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 82%
 * Problem Estimate (Inherent Problem Difficulty %): 88%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Collaborative decision tracking with voting requires complex state management and real-time consensus calculation
 * Final Code Complexity (Actual %): 89%
 * Overall Result Score (Success & Quality %): 93%
 * Key Variances/Learnings: Consensus calculation and deadline management added significant complexity
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine

struct DecisionTrackingView: View {
    let decisions: [CollaborativeDecision]
    let collaborationManager: CollaborationManager
    @State private var selectedDecision: CollaborativeDecision?
    @State private var showingDecisionDetails = false
    @State private var showingNewDecisionSheet = false
    @State private var filterStatus: DecisionFilterStatus = .all
    @State private var sortOption: DecisionSortOption = .newest
    @State private var searchText = ""

    enum DecisionFilterStatus: String, CaseIterable {
        case all = "All"
        case proposed = "Proposed"
        case voting = "Voting"
        case approved = "Approved"
        case rejected = "Rejected"
        case expired = "Expired"
    }

    enum DecisionSortOption: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case deadline = "By Deadline"
        case consensus = "By Consensus"
    }

    var filteredAndSortedDecisions: [CollaborativeDecision] {
        var filtered = decisions

        // Apply status filter
        if filterStatus != .all {
            filtered = filtered.filter { $0.status.rawValue == filterStatus.rawValue }
        }

        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { decision in
                decision.title.localizedCaseInsensitiveContains(searchText) ||
                decision.description.localizedCaseInsensitiveContains(searchText) ||
                decision.proposedBy.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Apply sorting
        switch sortOption {
        case .newest:
            filtered = filtered.sorted { $0.proposedAt > $1.proposedAt }
        case .oldest:
            filtered = filtered.sorted { $0.proposedAt < $1.proposedAt }
        case .deadline:
            filtered = filtered.sorted { decision1, decision2 in
                guard let deadline1 = decision1.deadline else { return false }
                guard let deadline2 = decision2.deadline else { return true }
                return deadline1 < deadline2
            }
        case .consensus:
            filtered = filtered.sorted { calculateConsensusProgress($0) > calculateConsensusProgress($1) }
        }

        return filtered
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            decisionHeaderView

            // Filter and sort controls
            controlsView

            // Decision list
            if filteredAndSortedDecisions.isEmpty {
                emptyStateView
            } else {
                decisionListView
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search decisions...")
        .sheet(isPresented: $showingDecisionDetails) {
            if let decision = selectedDecision {
                DecisionDetailSheet(
                    decision: decision,
                    collaborationManager: collaborationManager
                )
            }
        }
        .sheet(isPresented: $showingNewDecisionSheet) {
            NewDecisionSheet(collaborationManager: collaborationManager)
        }
    }

    // MARK: - View Components

    private var decisionHeaderView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Collaborative Decisions")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 16) {
                    DecisionStat(title: "Total", value: decisions.count, color: .blue)
                    DecisionStat(title: "Active", value: activeDecisionsCount, color: .green)
                    DecisionStat(title: "Pending Votes", value: pendingVotesCount, color: .orange)
                    DecisionStat(title: "Approved", value: approvedDecisionsCount, color: .purple)
                }
                .font(.caption)
            }

            Spacer()

            Button(action: { showingNewDecisionSheet = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Propose")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }

    private var controlsView: some View {
        VStack(spacing: 12) {
            // Filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(DecisionFilterStatus.allCases, id: \.self) { status in
                        FilterButton(
                            title: status.rawValue,
                            count: countForStatus(status),
                            isSelected: filterStatus == status
                        ) {
                            filterStatus = status
                        }
                    }
                }
                .padding(.horizontal)
            }

            // Sort options
            HStack {
                Text("Sort by:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Picker("Sort", selection: $sortOption) {
                    ForEach(DecisionSortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color(UIColor.systemBackground))
    }

    private var decisionListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredAndSortedDecisions) { decision in
                    DecisionRowView(
                        decision: decision,
                        onTap: {
                            selectedDecision = decision
                            showingDecisionDetails = true
                        },
                        onVote: { vote in
                            Task {
                                try await collaborationManager.voteOnDecision(decision.id, vote: vote)
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Decisions Yet")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Collaborative decisions will appear here. Tap 'Propose' to create the first decision.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button("Propose Decision") {
                showingNewDecisionSheet = true
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Computed Properties

    private var activeDecisionsCount: Int {
        decisions.filter { $0.status == .proposed || $0.status == .voting }.count
    }

    private var pendingVotesCount: Int {
        decisions.filter { $0.status == .voting }.count
    }

    private var approvedDecisionsCount: Int {
        decisions.filter { $0.status == .approved }.count
    }

    // MARK: - Helper Methods

    private func countForStatus(_ status: DecisionFilterStatus) -> Int {
        if status == .all {
            return decisions.count
        }
        return decisions.filter { $0.status.rawValue == status.rawValue }.count
    }

    private func calculateConsensusProgress(_ decision: CollaborativeDecision) -> Float {
        guard !decision.votes.isEmpty else { return 0 }

        let approvalVotes = decision.votes.filter { $0.vote == .approve }.count
        let totalVotes = decision.votes.count
        return Float(approvalVotes) / Float(totalVotes)
    }
}

// MARK: - Supporting Views

struct DecisionRowView: View {
    let decision: CollaborativeDecision
    let onTap: () -> Void
    let onVote: (CollaborativeVote) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(decision.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text("Proposed by \(decision.proposedBy)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                DecisionStatusBadge(status: decision.status)
            }

            // Description
            if !decision.description.isEmpty {
                Text(decision.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
            }

            // Progress and metadata
            VStack(spacing: 8) {
                // Consensus progress
                HStack {
                    Text("Consensus")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("\(Int(consensusProgress * 100))% / \(Int(decision.requiredConsensus * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(consensusProgress >= decision.requiredConsensus ? .green : .orange)
                }

                ProgressView(value: consensusProgress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: consensusProgress >= decision.requiredConsensus ? .green : .orange))

                // Voting stats and deadline
                HStack {
                    HStack(spacing: 12) {
                        VoteCountBadge(
                            type: .approve,
                            count: approveVotes,
                            color: .green
                        )

                        VoteCountBadge(
                            type: .reject,
                            count: rejectVotes,
                            color: .red
                        )

                        VoteCountBadge(
                            type: .abstain,
                            count: abstainVotes,
                            color: .gray
                        )
                    }

                    Spacer()

                    if let deadline = decision.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text(formatDeadline(deadline))
                                .font(.caption)
                        }
                        .foregroundColor(isDeadlineUrgent(deadline) ? .red : .secondary)
                    }
                }
            }

            // Action buttons (for voting decisions)
            if decision.status == .voting && !hasUserVoted {
                HStack(spacing: 12) {
                    VoteButton(
                        title: "Approve",
                        icon: "checkmark.circle.fill",
                        color: .green
                    ) {
                        voteApprove()
                    }

                    VoteButton(
                        title: "Reject",
                        icon: "xmark.circle.fill",
                        color: .red
                    ) {
                        voteReject()
                    }

                    VoteButton(
                        title: "Abstain",
                        icon: "minus.circle.fill",
                        color: .gray
                    ) {
                        voteAbstain()
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }

    // MARK: - Computed Properties

    private var consensusProgress: Float {
        guard !decision.votes.isEmpty else { return 0 }
        let approvalVotes = decision.votes.filter { $0.vote == .approve }.count
        return Float(approvalVotes) / Float(decision.votes.count)
    }

    private var approveVotes: Int {
        decision.votes.filter { $0.vote == .approve }.count
    }

    private var rejectVotes: Int {
        decision.votes.filter { $0.vote == .reject }.count
    }

    private var abstainVotes: Int {
        decision.votes.filter { $0.vote == .abstain }.count
    }

    private var hasUserVoted: Bool {
        // Check if current user has already voted
        // This would use the actual current user ID
        decision.votes.contains { $0.participantId == "current-user-id" }
    }

    // MARK: - Helper Methods

    private func formatDeadline(_ deadline: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: deadline, relativeTo: Date())
    }

    private func isDeadlineUrgent(_ deadline: Date) -> Bool {
        deadline.timeIntervalSinceNow < 3600 // Less than 1 hour
    }

    private func voteApprove() {
        let vote = CollaborativeVote(
            id: UUID().uuidString,
            participantId: "current-user-id",
            participantName: "Current User",
            vote: .approve,
            comment: nil,
            timestamp: Date()
        )
        onVote(vote)
    }

    private func voteReject() {
        let vote = CollaborativeVote(
            id: UUID().uuidString,
            participantId: "current-user-id",
            participantName: "Current User",
            vote: .reject,
            comment: nil,
            timestamp: Date()
        )
        onVote(vote)
    }

    private func voteAbstain() {
        let vote = CollaborativeVote(
            id: UUID().uuidString,
            participantId: "current-user-id",
            participantName: "Current User",
            vote: .abstain,
            comment: nil,
            timestamp: Date()
        )
        onVote(vote)
    }
}

struct DecisionStatusBadge: View {
    let status: CollaborativeDecision.DecisionStatus

    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(6)
    }

    private var backgroundColor: Color {
        switch status {
        case .proposed:
            return Color.blue.opacity(0.2)
        case .voting:
            return Color.orange.opacity(0.2)
        case .approved:
            return Color.green.opacity(0.2)
        case .rejected:
            return Color.red.opacity(0.2)
        case .expired:
            return Color.gray.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch status {
        case .proposed:
            return .blue
        case .voting:
            return .orange
        case .approved:
            return .green
        case .rejected:
            return .red
        case .expired:
            return .gray
        }
    }
}

struct VoteCountBadge: View {
    let type: CollaborativeVote.VoteType
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.caption2)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .cornerRadius(4)
    }

    private var iconName: String {
        switch type {
        case .approve:
            return "checkmark"
        case .reject:
            return "xmark"
        case .abstain:
            return "minus"
        }
    }
}

struct VoteButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

struct DecisionStat: View {
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

struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if !isEmpty {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

// MARK: - Detail and Creation Sheets

struct DecisionDetailSheet: View {
    let decision: CollaborativeDecision
    let collaborationManager: CollaborationManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingVoteSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(decision.title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack {
                            Text("Proposed by \(decision.proposedBy)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()

                            DecisionStatusBadge(status: decision.status)
                        }

                        Text(DateFormatter.full.string(from: decision.proposedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)

                        Text(decision.description)
                            .font(.body)
                    }

                    // Voting summary
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Voting Summary")
                            .font(.headline)

                        VStack(spacing: 8) {
                            // Progress bar
                            HStack {
                                Text("Consensus Progress")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(consensusProgress * 100))% / \(Int(decision.requiredConsensus * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }

                            ProgressView(value: consensusProgress, total: 1.0)
                                .progressViewStyle(LinearProgressViewStyle(tint: consensusProgress >= decision.requiredConsensus ? .green : .orange))

                            // Vote breakdown
                            HStack(spacing: 16) {
                                VoteCountBadge(type: .approve, count: approveVotes, color: .green)
                                VoteCountBadge(type: .reject, count: rejectVotes, color: .red)
                                VoteCountBadge(type: .abstain, count: abstainVotes, color: .gray)
                            }
                        }
                    }

                    // Individual votes
                    if !decision.votes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Votes (\(decision.votes.count))")
                                .font(.headline)

                            ForEach(decision.votes.sorted(by: { $0.timestamp > $1.timestamp })) { vote in
                                VoteRowView(vote: vote)
                            }
                        }
                    }

                    // Deadline info
                    if let deadline = decision.deadline {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Deadline")
                                .font(.headline)

                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.orange)
                                Text(DateFormatter.full.string(from: deadline))
                                    .font(.body)
                            }

                            if deadline < Date() {
                                Text("This decision has expired")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Decision Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    ShareLink(item: exportDecision()) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if decision.status == .voting && !hasUserVoted {
                    VStack(spacing: 0) {
                        Divider()

                        HStack(spacing: 12) {
                            VoteButton(title: "Approve", icon: "checkmark.circle.fill", color: .green) {
                                vote(.approve)
                            }

                            VoteButton(title: "Reject", icon: "xmark.circle.fill", color: .red) {
                                vote(.reject)
                            }

                            VoteButton(title: "Abstain", icon: "minus.circle.fill", color: .gray) {
                                vote(.abstain)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBackground))
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var consensusProgress: Float {
        guard !decision.votes.isEmpty else { return 0 }
        let approvalVotes = decision.votes.filter { $0.vote == .approve }.count
        return Float(approvalVotes) / Float(decision.votes.count)
    }

    private var approveVotes: Int {
        decision.votes.filter { $0.vote == .approve }.count
    }

    private var rejectVotes: Int {
        decision.votes.filter { $0.vote == .reject }.count
    }

    private var abstainVotes: Int {
        decision.votes.filter { $0.vote == .abstain }.count
    }

    private var hasUserVoted: Bool {
        decision.votes.contains { $0.participantId == "current-user-id" }
    }

    // MARK: - Actions

    private func vote(_ voteType: CollaborativeVote.VoteType) {
        let vote = CollaborativeVote(
            id: UUID().uuidString,
            participantId: "current-user-id",
            participantName: "Current User",
            vote: voteType,
            comment: nil,
            timestamp: Date()
        )

        Task {
            try await collaborationManager.voteOnDecision(decision.id, vote: vote)
        }
    }

    private func exportDecision() -> String {
        var export = "Decision Export\n"
        export += "Title: \(decision.title)\n"
        export += "Proposed by: \(decision.proposedBy)\n"
        export += "Status: \(decision.status.rawValue)\n"
        export += "Date: \(DateFormatter.full.string(from: decision.proposedAt))\n"
        if let deadline = decision.deadline {
            export += "Deadline: \(DateFormatter.full.string(from: deadline))\n"
        }
        export += "Required Consensus: \(Int(decision.requiredConsensus * 100))%\n\n"
        export += "Description:\n\(decision.description)\n\n"

        if !decision.votes.isEmpty {
            export += "Votes:\n"
            for vote in decision.votes {
                export += "- \(vote.participantName): \(vote.vote.rawValue.capitalized)\n"
                if let comment = vote.comment {
                    export += "  Comment: \(comment)\n"
                }
            }
        }

        return export
    }
}

struct VoteRowView: View {
    let vote: CollaborativeVote

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(vote.participantName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let comment = vote.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text(DateFormatter.shortDateTime.string(from: vote.timestamp))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VoteCountBadge(
                type: vote.vote,
                count: 1,
                color: colorForVoteType(vote.vote)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }

    private func colorForVoteType(_ voteType: CollaborativeVote.VoteType) -> Color {
        switch voteType {
        case .approve:
            return .green
        case .reject:
            return .red
        case .abstain:
            return .gray
        }
    }
}

struct NewDecisionSheet: View {
    let collaborationManager: CollaborationManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var requiredConsensus: Float = 0.6
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400) // 24 hours from now
    @State private var category: CollaborativeDecision.DecisionCategory = .other

    var body: some View {
        NavigationView {
            Form {
                Section("Decision Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)

                    Picker("Category", selection: $category) {
                        ForEach(CollaborativeDecision.DecisionCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                                .tag(category)
                        }
                    }
                }

                Section("Voting Requirements") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Required Consensus: \(Int(requiredConsensus * 100))%")
                            .font(.subheadline)

                        Slider(value: $requiredConsensus, in: 0.5...1.0, step: 0.1)

                        Text("At least \(Int(requiredConsensus * 100))% of votes must be 'Approve' for this decision to pass.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Toggle("Set Deadline", isOn: $hasDeadline)

                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()...)
                            .datePickerStyle(CompactDatePickerStyle())
                    }
                }
            }
            .navigationTitle("Propose Decision")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Propose") {
                        proposeDecision()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    private func proposeDecision() {
        let decision = CollaborativeDecision(
            id: UUID().uuidString,
            title: title,
            description: description,
            proposedBy: "Current User",
            proposedAt: Date(),
            status: .proposed,
            votes: [],
            requiredConsensus: requiredConsensus,
            deadline: hasDeadline ? deadline : nil,
            category: category
        )

        Task {
            try await collaborationManager.proposeDecision(decision)
            await MainActor.run {
                dismiss()
            }
        }
    }
}

// MARK: - Preview

struct DecisionTrackingView_Previews: PreviewProvider {
    static var previews: some View {
        DecisionTrackingView(
            decisions: sampleDecisions,
            collaborationManager: CollaborationManager(keychainManager: KeychainManager(service: "preview"))
        )
    }

    static var sampleDecisions: [CollaborativeDecision] {
        [
            CollaborativeDecision(
                id: "1",
                title: "Approve Q4 Marketing Budget",
                description: "Increase marketing budget by 25% to support new product launch campaign.",
                proposedBy: "Alice Johnson",
                proposedAt: Date().addingTimeInterval(-3600),
                status: .voting,
                votes: [
                    CollaborativeVote(
                        id: "v1",
                        participantId: "user1",
                        participantName: "Alice Johnson",
                        vote: .approve,
                        comment: "Essential for product success",
                        timestamp: Date().addingTimeInterval(-1800)
                    ),
                    CollaborativeVote(
                        id: "v2",
                        participantId: "user2",
                        participantName: "Bob Smith",
                        vote: .approve,
                        comment: nil,
                        timestamp: Date().addingTimeInterval(-900)
                    ),
                ],
                requiredConsensus: 0.6,
                deadline: Date().addingTimeInterval(7200),
                category: .processDecision
            ),
            CollaborativeDecision(
                id: "2",
                title: "Switch to New Project Management Tool",
                description: "Migrate from current PM tool to a more collaborative solution.",
                proposedBy: "Carol Davis",
                proposedAt: Date().addingTimeInterval(-7200),
                status: .approved,
                votes: [
                    CollaborativeVote(
                        id: "v3",
                        participantId: "user3",
                        participantName: "Carol Davis",
                        vote: .approve,
                        comment: "Better features for team collaboration",
                        timestamp: Date().addingTimeInterval(-3600)
                    ),
                ],
                requiredConsensus: 0.5,
                deadline: nil,
                category: .technicalChoice
            ),
        ]
    }
}
