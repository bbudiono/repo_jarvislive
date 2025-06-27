// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive conversation history management UI with search and organization
 * Issues & Complexity Summary: Complex UI with search, filtering, conversation management, and glassmorphism
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High (UI state management, search, filtering)
 *   - Dependencies: 4 New (SwiftUI, Core Data, ConversationManager, Combine)
 *   - State Management Complexity: High (Multiple UI states, search, selection)
 *   - Novelty/Uncertainty Factor: Medium (Complex SwiftUI layouts)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 75%
 * Initial Code Complexity Estimate %: 80%
 * Justification for Estimates: Complex conversation management UI with search and glassmorphism
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import SwiftUI
import Combine

struct ConversationHistoryView: View {
    @StateObject private var conversationManager = ConversationManager()
    @Environment(\.dismiss) private var dismiss

    // State management
    @State private var selectedConversation: Conversation?
    @State private var showingNewConversationAlert = false
    @State private var newConversationTitle = ""
    @State private var showingExportSheet = false
    @State private var exportText = ""
    @State private var showingDeleteAlert = false
    @State private var conversationToDelete: Conversation?

    // Animation states
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Glassmorphism Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.4),
                    Color(red: 0.2, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.1, blue: 0.2),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated background particles
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.3),
                                Color.blue.opacity(0.2),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: 15)
                    .offset(
                        x: isAnimating ? CGFloat.random(in: -100...100) : 0,
                        y: isAnimating ? CGFloat.random(in: -150...150) : 0
                    )
                    .animation(
                        Animation.easeInOut(duration: 4 + Double(index))
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }

            VStack(spacing: 0) {
                // Header Section
                headerSection

                // Search Bar
                searchSection

                // Stats Section
                statsSection

                // Conversation List
                conversationListSection

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("Conversations")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(.cyan)
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: { showingExportSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.cyan)
                    }

                    Button(action: { showingNewConversationAlert = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .onAppear {
            isAnimating = true
            conversationManager.loadConversations()
        }
        .alert("New Conversation", isPresented: $showingNewConversationAlert) {
            TextField("Conversation Title", text: $newConversationTitle)
            Button("Create") {
                createNewConversation()
            }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Delete Conversation", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let conversation = conversationToDelete {
                    conversationManager.deleteConversation(conversation)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportView(exportText: exportText)
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        glassmorphicCard {
            VStack(spacing: 15) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title)
                        .foregroundColor(.cyan)

                    Text("Conversation History")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Spacer()

                    // Sandbox Indicator
                    Text("SANDBOX")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(6)
                }

                Text("Manage and review your AI conversations")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
        }
        .padding(.top, 10)
    }

    // MARK: - Search Section

    private var searchSection: some View {
        glassmorphicCard {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white.opacity(0.6))

                TextField("Search conversations...", text: $conversationManager.searchText)
                    .foregroundColor(.white)
                    .placeholder(when: conversationManager.searchText.isEmpty) {
                        Text("Search conversations...")
                            .foregroundColor(.white.opacity(0.5))
                    }

                if !conversationManager.searchText.isEmpty {
                    Button(action: { conversationManager.searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        let stats = conversationManager.getConversationStats()

        return glassmorphicCard {
            HStack(spacing: 20) {
                StatItem(
                    title: "Total",
                    value: "\(stats.totalConversations)",
                    icon: "bubble.left.and.bubble.right",
                    color: .cyan
                )

                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 30)

                StatItem(
                    title: "Messages",
                    value: "\(stats.totalMessages)",
                    icon: "message",
                    color: .green
                )

                Divider()
                    .background(Color.white.opacity(0.3))
                    .frame(height: 30)

                StatItem(
                    title: "Avg/Conv",
                    value: String(format: "%.1f", stats.averageMessagesPerConversation),
                    icon: "chart.bar",
                    color: .purple
                )
            }
            .padding()
        }
    }

    // MARK: - Conversation List Section

    private var conversationListSection: some View {
        glassmorphicCard {
            VStack(spacing: 0) {
                HStack {
                    Text("Recent Conversations")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text("\(conversationManager.filteredConversations.count) items")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal)
                .padding(.top)

                if conversationManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .padding()
                } else if conversationManager.filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(conversationManager.filteredConversations, id: \.id) { conversation in
                                ConversationRowView(
                                    conversation: conversation,
                                    onSelect: { selectConversation(conversation) },
                                    onDelete: { deleteConversation(conversation) },
                                    onArchive: { archiveConversation(conversation) }
                                )
                            }
                        }
                        .padding()
                    }
                    .frame(maxHeight: 400)
                }
            }
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 50))
                .foregroundColor(.white.opacity(0.3))

            Text("No Conversations")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)

            Text("Start a new conversation to begin")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.6))

            Button(action: { showingNewConversationAlert = true }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Conversation")
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.cyan.opacity(0.8))
                .cornerRadius(10)
            }
        }
        .padding(40)
    }

    // MARK: - Glassmorphism Helper

    @ViewBuilder
    private func glassmorphicCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.25),
                                Color.white.opacity(0.1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.6),
                                        Color.white.opacity(0.2),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    // MARK: - Action Methods

    private func createNewConversation() {
        let title = newConversationTitle.isEmpty ? "New Conversation" : newConversationTitle
        let conversation = conversationManager.createNewConversation(title: title)
        selectedConversation = conversation
        newConversationTitle = ""
    }

    private func selectConversation(_ conversation: Conversation) {
        conversationManager.setCurrentConversation(conversation)
        selectedConversation = conversation
        // Navigate to conversation detail or dismiss
        dismiss()
    }

    private func deleteConversation(_ conversation: Conversation) {
        conversationToDelete = conversation
        showingDeleteAlert = true
    }

    private func archiveConversation(_ conversation: Conversation) {
        conversationManager.archiveConversation(conversation)
    }

    private func exportConversations() {
        exportText = conversationManager.exportAllConversations()
        showingExportSheet = true
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct ConversationRowView: View {
    let conversation: Conversation
    let onSelect: () -> Void
    let onDelete: () -> Void
    let onArchive: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            // Conversation Icon
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.cyan.opacity(0.8),
                            Color.blue.opacity(0.6),
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 45, height: 45)
                .overlay(
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                )

            // Conversation Info
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack {
                    Text("\(conversation.totalMessages) messages")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()

                    Text(formatDate(conversation.updatedAt))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }

            Spacer()

            // Action Menu
            Menu {
                Button(action: onSelect) {
                    Label("Open", systemImage: "arrow.right.circle")
                }

                Button(action: onArchive) {
                    Label("Archive", systemImage: "archivebox")
                }

                Button(action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .onTapGesture {
            onSelect()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isToday(date) {
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else if Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "E"
            return formatter.string(from: date)
        } else {
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

struct ExportView: View {
    let exportText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    Text(exportText)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink("Share", item: exportText)
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

// MARK: - TextField Placeholder Extension

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Preview

struct ConversationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ConversationHistoryView()
            .preferredColorScheme(.dark)
    }
}
