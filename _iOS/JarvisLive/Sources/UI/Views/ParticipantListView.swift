// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive participant list and management interface for collaborative sessions
 * Issues & Complexity Summary: Real-time participant status, audio visualization, role management, and interaction controls
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400
 *   - Core Algorithm Complexity: Medium (Participant state management, audio visualization)
 *   - Dependencies: 5 New (SwiftUI, Combine, AVFoundation, Real-time updates)
 *   - State Management Complexity: High (Multi-participant state, permissions, audio levels)
 *   - Novelty/Uncertainty Factor: Medium (Participant management patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 70%
 * Initial Code Complexity Estimate %: 72%
 * Justification for Estimates: Participant management requires real-time updates and permission handling
 * Final Code Complexity (Actual %): 78%
 * Overall Result Score (Success & Quality %): 89%
 * Key Variances/Learnings: Real-time audio visualization and permission management added complexity
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine

struct ParticipantListView: View {
    let participants: [Collaborator]
    @State private var selectedParticipant: Collaborator?
    @State private var showingParticipantDetails = false
    @State private var showingRoleChangeAlert = false
    @State private var newRole: Collaborator.CollaboratorRole = .participant
    @State private var searchText = ""

    var filteredParticipants: [Collaborator] {
        if searchText.isEmpty {
            return participants.sorted { participant1, participant2 in
                // Sort by: active first, then speaking, then by join time
                if participant1.isActive != participant2.isActive {
                    return participant1.isActive && !participant2.isActive
                }
                if participant1.isSpeaking != participant2.isSpeaking {
                    return participant1.isSpeaking && !participant2.isSpeaking
                }
                return participant1.joinedAt < participant2.joinedAt
            }
        } else {
            return participants.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search and Filters
            searchAndFilterView

            // Participant Statistics
            participantStatsView

            // Participant List
            if filteredParticipants.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredParticipants) { participant in
                            ParticipantRowView(
                                participant: participant,
                                onTap: {
                                    selectedParticipant = participant
                                    showingParticipantDetails = true
                                },
                                onRoleChange: { newRole in
                                    self.newRole = newRole
                                    selectedParticipant = participant
                                    showingRoleChangeAlert = true
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .searchable(text: $searchText, prompt: "Search participants...")
        .sheet(isPresented: $showingParticipantDetails) {
            if let participant = selectedParticipant {
                ParticipantDetailSheet(participant: participant)
            }
        }
        .alert("Change Role", isPresented: $showingRoleChangeAlert) {
            Button("Confirm") {
                if let participant = selectedParticipant {
                    changeParticipantRole(participant, to: newRole)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let participant = selectedParticipant {
                Text("Change \(participant.name)'s role to \(newRole.rawValue.capitalized)?")
            }
        }
    }

    // MARK: - View Components

    private var searchAndFilterView: some View {
        VStack(spacing: 12) {
            // Quick filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(title: "All", count: participants.count, isSelected: true)
                    FilterButton(title: "Active", count: activeParticipantsCount, isSelected: false)
                    FilterButton(title: "Speaking", count: speakingParticipantsCount, isSelected: false)
                    FilterButton(title: "Hosts", count: hostParticipantsCount, isSelected: false)
                    FilterButton(title: "Observers", count: observerParticipantsCount, isSelected: false)
                }
                .padding(.horizontal)
            }
        }
        .padding(.top)
        .background(Color(UIColor.systemBackground))
    }

    private var participantStatsView: some View {
        HStack(spacing: 20) {
            StatItem(title: "Total", value: "\(participants.count)", icon: "person.3", color: .blue)
            StatItem(title: "Active", value: "\(activeParticipantsCount)", icon: "person.wave.2", color: .green)
            StatItem(title: "Speaking", value: "\(speakingParticipantsCount)", icon: "mic", color: .orange)
            StatItem(title: "Quiet", value: "\(participants.count - speakingParticipantsCount)", icon: "mic.slash", color: .gray)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)

            Text("No Participants Found")
                .font(.headline)
                .foregroundColor(.primary)

            Text(searchText.isEmpty ?
                 "Participants will appear here when they join the session." :
                 "No participants match your search criteria.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Computed Properties

    private var activeParticipantsCount: Int {
        participants.filter { $0.isActive }.count
    }

    private var speakingParticipantsCount: Int {
        participants.filter { $0.isSpeaking }.count
    }

    private var hostParticipantsCount: Int {
        participants.filter { $0.role == .host || $0.role == .moderator }.count
    }

    private var observerParticipantsCount: Int {
        participants.filter { $0.role == .observer }.count
    }

    // MARK: - Actions

    private func changeParticipantRole(_ participant: Collaborator, to role: Collaborator.CollaboratorRole) {
        // This would send a role change request to the collaboration manager
        print("Changing \(participant.name)'s role to \(role.rawValue)")
    }
}

// MARK: - Supporting Views

struct ParticipantRowView: View {
    let participant: Collaborator
    let onTap: () -> Void
    let onRoleChange: (Collaborator.CollaboratorRole) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Avatar and Status
            ZStack {
                // Avatar
                AsyncImage(url: participant.avatarURL.flatMap(URL.init)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Text(participant.name.prefix(1))
                                .font(.headline)
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())

                // Status indicators
                VStack {
                    Spacer()
                    HStack {
                        Spacer()

                        if participant.isSpeaking {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        } else if participant.isActive {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                )
                        }
                    }
                }
            }

            // Participant Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(participant.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if participant.role == .host {
                        Text("HOST")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    } else if participant.role == .moderator {
                        Text("MOD")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    Spacer()
                }

                HStack(spacing: 8) {
                    Text("Joined \(formatJoinTime(participant.joinedAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if participant.isSpeaking {
                        HStack(spacing: 4) {
                            Image(systemName: "mic.fill")
                                .font(.caption2)
                            AudioLevelIndicator(level: participant.audioLevel)
                        }
                        .foregroundColor(.green)
                    } else if !participant.isActive {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.fill")
                                .font(.caption2)
                            Text("Away")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                    }
                }
            }

            // Action Menu
            Menu {
                if participant.role != .host {
                    Menu("Change Role") {
                        ForEach(Collaborator.CollaboratorRole.allCases, id: \.self) { role in
                            if role != participant.role {
                                Button(role.rawValue.capitalized) {
                                    onRoleChange(role)
                                }
                            }
                        }
                    }
                }

                Button("View Details") {
                    onTap()
                }

                if participant.isActive && participant.permissions.contains(.canSpeak) {
                    Button("Mute", role: .destructive) {
                        // Mute participant
                    }
                }

                if !participant.isActive {
                    Button("Remove from Session", role: .destructive) {
                        // Remove participant
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
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

    private func formatJoinTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AudioLevelIndicator: View {
    let level: Float

    var body: some View {
        HStack(spacing: 1) {
            ForEach(0..<5, id: \.self) { index in
                Rectangle()
                    .fill(level > Float(index) * 0.2 ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 2, height: CGFloat(4 + index * 2))
                    .cornerRadius(1)
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool

    var body: some View {
        Button(action: {
            // Filter action
        }) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                Text("\(count)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white : Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(16)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ParticipantDetailSheet: View {
    let participant: Collaborator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        AsyncImage(url: participant.avatarURL.flatMap(URL.init)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Text(participant.name.prefix(2))
                                        .font(.title)
                                        .foregroundColor(.white)
                                )
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

                        VStack(spacing: 8) {
                            Text(participant.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            Text(participant.role.rawValue.capitalized)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }

                    // Status Information
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Status")

                        InfoRow(label: "Connection", value: participant.isActive ? "Active" : "Inactive")
                        InfoRow(label: "Audio", value: participant.isSpeaking ? "Speaking" : "Muted")
                        InfoRow(label: "Joined", value: formatDateTime(participant.joinedAt))
                        InfoRow(label: "Audio Level", value: "\(Int(participant.audioLevel * 100))%")
                    }

                    // Permissions
                    VStack(alignment: .leading, spacing: 16) {
                        SectionHeader(title: "Permissions")

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 12) {
                            ForEach(Array(participant.permissions), id: \.self) { permission in
                                PermissionBadge(permission: permission)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Participant Details")
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

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct PermissionBadge: View {
    let permission: Collaborator.CollaborationPermission

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForPermission(permission))
                .font(.caption)
            Text(permission.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.2))
        .foregroundColor(.green)
        .cornerRadius(6)
    }

    private func iconForPermission(_ permission: Collaborator.CollaborationPermission) -> String {
        switch permission {
        case .canSpeak:
            return "mic.fill"
        case .canMute:
            return "mic.slash.fill"
        case .canInvite:
            return "person.badge.plus"
        case .canRecord:
            return "record.circle"
        case .canGenerateDocuments:
            return "doc.text"
        case .canManageSession:
            return "gearshape.fill"
        }
    }
}

// MARK: - Preview

struct ParticipantListView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantListView(participants: sampleParticipants)
    }

    static var sampleParticipants: [Collaborator] {
        [
            Collaborator(
                id: "1",
                name: "Alice Johnson",
                avatarURL: nil,
                joinedAt: Date().addingTimeInterval(-300),
                isActive: true,
                isSpeaking: true,
                audioLevel: 0.8,
                role: .host,
                permissions: [.canSpeak, .canMute, .canInvite, .canManageSession]
            ),
            Collaborator(
                id: "2",
                name: "Bob Smith",
                avatarURL: nil,
                joinedAt: Date().addingTimeInterval(-180),
                isActive: true,
                isSpeaking: false,
                audioLevel: 0.0,
                role: .participant,
                permissions: [.canSpeak]
            ),
            Collaborator(
                id: "3",
                name: "Carol Davis",
                avatarURL: nil,
                joinedAt: Date().addingTimeInterval(-120),
                isActive: false,
                isSpeaking: false,
                audioLevel: 0.0,
                role: .observer,
                permissions: []
            ),
        ]
    }
}
