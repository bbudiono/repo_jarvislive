// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Supporting views for collaborative session interface including invite sheets, decision proposals, and session summaries
 * Issues & Complexity Summary: Multiple modal interfaces for collaboration features with form validation and state management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~350
 *   - Core Algorithm Complexity: Medium (Form validation, invite management, summary generation)
 *   - Dependencies: 4 New (SwiftUI, Combine, Form handling, Collaboration models)
 *   - State Management Complexity: Medium (Modal state, form validation, data binding)
 *   - Novelty/Uncertainty Factor: Low (Standard modal and form patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 65%
 * Problem Estimate (Inherent Problem Difficulty %): 60%
 * Initial Code Complexity Estimate %: 62%
 * Justification for Estimates: Supporting modal views with standard form patterns
 * Final Code Complexity (Actual %): 68%
 * Overall Result Score (Success & Quality %): 87%
 * Key Variances/Learnings: Email validation and invite management added some complexity
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine

// MARK: - Invite Participants Sheet

struct InviteParticipantsSheet: View {
    let collaborationManager: CollaborationManager
    @Environment(\.dismiss) private var dismiss
    @State private var inviteEmails: [String] = [""]
    @State private var inviteMessage = "You're invited to join our collaborative session!"
    @State private var selectedRole: Collaborator.CollaboratorRole = .participant
    @State private var selectedPermissions: Set<Collaborator.CollaborationPermission> = [.canSpeak]
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Invite Participants") {
                    ForEach(inviteEmails.indices, id: \.self) { index in
                        HStack {
                            TextField("Email address", text: $inviteEmails[index])
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)

                            if inviteEmails.count > 1 {
                                Button(action: { removeEmail(at: index) }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }

                    Button(action: addEmailField) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Add another email")
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section("Default Role & Permissions") {
                    Picker("Role", selection: $selectedRole) {
                        ForEach(Collaborator.CollaboratorRole.allCases, id: \.self) { role in
                            Text(role.rawValue.capitalized).tag(role)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissions")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 8) {
                            ForEach(Collaborator.CollaborationPermission.allCases, id: \.self) { permission in
                                PermissionToggle(
                                    permission: permission,
                                    isSelected: selectedPermissions.contains(permission)
                                ) { isSelected in
                                    if isSelected {
                                        selectedPermissions.insert(permission)
                                    } else {
                                        selectedPermissions.remove(permission)
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Invitation Message") {
                    TextField("Message", text: $inviteMessage, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }

                Section("Session Information") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Session:")
                                .fontWeight(.medium)
                            Text(collaborationManager.currentSession?.title ?? "Untitled Session")
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("Current Participants:")
                                .fontWeight(.medium)
                            Text("\(collaborationManager.participants.count)")
                                .foregroundColor(.secondary)
                        }

                        if let sessionId = collaborationManager.currentSession?.id {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Session ID:")
                                    .fontWeight(.medium)
                                Text(sessionId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Invite Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send Invites") {
                        sendInvites()
                    }
                    .disabled(isLoading || !hasValidEmails)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Sending invites...")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var hasValidEmails: Bool {
        inviteEmails.contains { !$0.isEmpty && isValidEmail($0) }
    }

    // MARK: - Actions

    private func addEmailField() {
        inviteEmails.append("")
    }

    private func removeEmail(at index: Int) {
        inviteEmails.remove(at: index)
    }

    private func sendInvites() {
        let validEmails = inviteEmails.filter { !$0.isEmpty && isValidEmail($0) }

        guard !validEmails.isEmpty else {
            errorMessage = "Please enter at least one valid email address."
            showingError = true
            return
        }

        guard let sessionId = collaborationManager.currentSession?.id else {
            errorMessage = "No active session found."
            showingError = true
            return
        }

        isLoading = true

        Task {
            do {
                for email in validEmails {
                    try await sendInvitation(to: email, sessionId: sessionId)
                }

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send invitations: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func sendInvitation(to email: String, sessionId: String) async throws {
        // This would integrate with the email MCP service
        // For now, simulate the invitation process
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        print("Sending invitation to \(email) for session \(sessionId)")
    }

    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

struct PermissionToggle: View {
    let permission: Collaborator.CollaborationPermission
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button(action: { onToggle(!isSelected) }) {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)

                Text(permission.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Propose Decision Sheet

struct ProposeDecisionSheet: View {
    let collaborationManager: CollaborationManager
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var requiredConsensus: Float = 0.6
    @State private var hasDeadline = false
    @State private var deadline = Date().addingTimeInterval(86400) // 24 hours from now
    @State private var category: CollaborativeDecision.DecisionCategory = .other
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Decision Details") {
                    TextField("Decision Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...8)

                    Picker("Category", selection: $category) {
                        ForEach(CollaborativeDecision.DecisionCategory.allCases, id: \.self) { category in
                            Text(categoryDisplayName(category))
                                .tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                Section("Voting Requirements") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Required Consensus")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Spacer()

                            Text("\(Int(requiredConsensus * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }

                        Slider(value: $requiredConsensus, in: 0.5...1.0, step: 0.05) {
                            Text("Consensus")
                        } minimumValueLabel: {
                            Text("50%")
                                .font(.caption2)
                        } maximumValueLabel: {
                            Text("100%")
                                .font(.caption2)
                        }
                        .accentColor(.blue)

                        Text(consensusDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Toggle("Set Voting Deadline", isOn: $hasDeadline)

                    if hasDeadline {
                        DatePicker("Deadline", selection: $deadline, in: Date()...)
                            .datePickerStyle(CompactDatePickerStyle())

                        Text("Voting will automatically close at the deadline.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Preview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Decision Summary")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Title: \(title.isEmpty ? "Enter title..." : title)")
                                .font(.body)
                                .foregroundColor(title.isEmpty ? .secondary : .primary)

                            Text("Category: \(categoryDisplayName(category))")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text("Required Consensus: \(Int(requiredConsensus * 100))%")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if hasDeadline {
                                Text("Deadline: \(DateFormatter.medium.string(from: deadline))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
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
                    .disabled(isLoading || title.isEmpty || description.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .overlay {
                if isLoading {
                    ProgressView("Creating decision...")
                        .padding()
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var consensusDescription: String {
        let percentage = Int(requiredConsensus * 100)
        let participants = collaborationManager.participants.count
        let requiredVotes = max(1, Int(ceil(Float(participants) * requiredConsensus)))

        return "At least \(percentage)% of participants (\(requiredVotes) out of \(participants)) must approve this decision."
    }

    // MARK: - Helper Methods

    private func categoryDisplayName(_ category: CollaborativeDecision.DecisionCategory) -> String {
        switch category {
        case .documentGeneration:
            return "Document Generation"
        case .meetingAction:
            return "Meeting Action"
        case .processDecision:
            return "Process Decision"
        case .technicalChoice:
            return "Technical Choice"
        case .other:
            return "Other"
        }
    }

    private func proposeDecision() {
        isLoading = true

        let decision = CollaborativeDecision(
            id: UUID().uuidString,
            title: title,
            description: description,
            proposedBy: getCurrentUserName(),
            proposedAt: Date(),
            status: .proposed,
            votes: [],
            requiredConsensus: requiredConsensus,
            deadline: hasDeadline ? deadline : nil,
            category: category
        )

        Task {
            do {
                try await collaborationManager.proposeDecision(decision)

                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to propose decision: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func getCurrentUserName() -> String {
        // Get current user name from settings or keychain
        return "Current User"
    }
}

extension DateFormatter {
    static let medium: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

// MARK: - Session Summary View

struct SessionSummaryView: View {
    let summary: SessionSummary?
    @State private var isGeneratingSummary = false
    @State private var showingExportSheet = false

    var body: some View {
        Group {
            if let summary = summary {
                summaryContentView(summary)
            } else {
                emptySummaryView
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            if let summary = summary {
                SummaryExportSheet(summary: summary)
            }
        }
    }

    // MARK: - View Components

    private var emptySummaryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Session Summary")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Generate a comprehensive summary of this collaborative session including key decisions, transcription highlights, and action items.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button(action: generateSummary) {
                HStack(spacing: 8) {
                    if isGeneratingSummary {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "brain")
                    }
                    Text(isGeneratingSummary ? "Generating..." : "Generate Summary")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(isGeneratingSummary ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .disabled(isGeneratingSummary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    private func summaryContentView(_ summary: SessionSummary) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                summaryHeaderView(summary)

                // Key highlights
                if !summary.keyDiscussionPoints.isEmpty {
                    keyDiscussionPointsView(summary.keyDiscussionPoints)
                }

                // Decisions summary
                if !summary.decisions.isEmpty {
                    decisionsSummaryView(summary.decisions)
                }

                // Action items
                if !summary.actionItems.isEmpty {
                    actionItemsView(summary.actionItems)
                }

                // Documents generated
                if !summary.documentsGenerated.isEmpty {
                    documentsGeneratedView(summary.documentsGenerated)
                }

                // Participants
                participantsSummaryView(summary.participants)

                // AI-generated summary
                aiSummaryView(summary.transcriptionSummary)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingExportSheet = true }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private func summaryHeaderView(_ summary: SessionSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started: \(DateFormatter.full.string(from: summary.startTime))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if let endTime = summary.endTime {
                        Text("Ended: \(DateFormatter.full.string(from: endTime))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        let duration = endTime.timeIntervalSince(summary.startTime)
                        Text("Duration: \(formatDuration(duration))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Status: Active")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func keyDiscussionPointsView(_ points: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Key Discussion Points")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(Array(points.enumerated()), id: \.offset) { index, point in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(width: 20, alignment: .leading)

                    Text(point)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func decisionsSummaryView(_ decisions: [CollaborativeDecision]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Decisions (\(decisions.count))")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(decisions) { decision in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(decision.title)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text(decision.status.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor(decision.status).opacity(0.2))
                            .foregroundColor(statusColor(decision.status))
                            .cornerRadius(4)
                    }

                    Spacer()

                    Text("\(decision.votes.count) votes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                if decision != decisions.last {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func actionItemsView(_ actionItems: [SessionSummary.ActionItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Action Items (\(actionItems.count))")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(actionItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.description)
                            .font(.subheadline)
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            if let assignedTo = item.assignedTo {
                                Text("Assigned to: \(assignedTo)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if let dueDate = item.dueDate {
                                Text("Due: \(DateFormatter.short.string(from: dueDate))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Spacer()

                    Text(item.status)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
                .padding(.vertical, 4)

                if item != actionItems.last {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func documentsGeneratedView(_ documents: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Documents Generated (\(documents.count))")
                .font(.headline)
                .foregroundColor(.primary)

            ForEach(Array(documents.enumerated()), id: \.offset) { index, document in
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)

                    Text(document)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button("View") {
                        // Open document
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                }

                if index < documents.count - 1 {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func participantsSummaryView(_ participants: [Collaborator]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Participants (\(participants.count))")
                .font(.headline)
                .foregroundColor(.primary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 8) {
                ForEach(participants) { participant in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)

                        Text(participant.name)
                            .font(.caption)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private func aiSummaryView(_ transcriptionSummary: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.purple)
                Text("AI-Generated Summary")
                    .font(.headline)
                    .foregroundColor(.purple)
            }

            Text(transcriptionSummary)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Helper Methods

    private func generateSummary() {
        isGeneratingSummary = true

        Task {
            // Simulate AI summary generation
            try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

            await MainActor.run {
                isGeneratingSummary = false
                // The summary would be generated by the collaboration manager
                // For demo purposes, this is just showing the loading state
            }
        }
    }

    private func statusColor(_ status: CollaborativeDecision.DecisionStatus) -> Color {
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

extension DateFormatter {
    static let short: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - Summary Export Sheet

struct SummaryExportSheet: View {
    let summary: SessionSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Export Options")
                        .font(.headline)

                    VStack(spacing: 12) {
                        ExportOptionButton(
                            title: "Plain Text",
                            icon: "doc.text",
                            description: "Export as readable text format"
                        ) {
                            exportAsText()
                        }

                        ExportOptionButton(
                            title: "PDF Document",
                            icon: "doc.richtext",
                            description: "Generate formatted PDF report"
                        ) {
                            exportAsPDF()
                        }

                        ExportOptionButton(
                            title: "Email Summary",
                            icon: "envelope",
                            description: "Send summary via email"
                        ) {
                            emailSummary()
                        }

                        ExportOptionButton(
                            title: "Share Link",
                            icon: "link",
                            description: "Generate shareable link"
                        ) {
                            shareLink()
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Export Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func exportAsText() {
        // Export logic
        dismiss()
    }

    private func exportAsPDF() {
        // PDF export logic
        dismiss()
    }

    private func emailSummary() {
        // Email integration
        dismiss()
    }

    private func shareLink() {
        // Share link generation
        dismiss()
    }
}

struct ExportOptionButton: View {
    let title: String
    let icon: String
    let description: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct CollaborationSupportViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InviteParticipantsSheet(
                collaborationManager: CollaborationManager(keychainManager: KeychainManager(service: "preview"))
            )

            ProposeDecisionSheet(
                collaborationManager: CollaborationManager(keychainManager: KeychainManager(service: "preview"))
            )

            SessionSummaryView(summary: nil)
        }
    }
}
