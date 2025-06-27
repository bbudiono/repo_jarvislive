/*
* Purpose: Category-specific preview cards for different command types
* Issues & Complexity Summary: Rich UI previews for document, email, calendar, and other command categories
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~600
  - Core Algorithm Complexity: Medium (category-specific UI logic)
  - Dependencies: 4 New (SwiftUI forms, data visualization, category models)
  - State Management Complexity: Medium (individual preview states)
  - Novelty/Uncertainty Factor: Low (standard form and preview patterns)
* AI Pre-Task Self-Assessment: 88%
* Problem Estimate: 70%
* Initial Code Complexity Estimate: 75%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
*/

import SwiftUI

// MARK: - Document Generation Preview

struct DocumentPreviewCard: View {
    let parameters: [String: AnyCodable]
    @State private var selectedTemplate: DocumentTemplate = .professional
    @State private var showingTemplateSelector = false

    enum DocumentTemplate: String, CaseIterable {
        case professional = "Professional"
        case creative = "Creative"
        case minimal = "Minimal"
        case academic = "Academic"

        var icon: String {
            switch self {
            case .professional: return "doc.text"
            case .creative: return "paintbrush"
            case .minimal: return "doc.plaintext"
            case .academic: return "graduationcap"
            }
        }

        var color: Color {
            switch self {
            case .professional: return .blue
            case .creative: return .purple
            case .minimal: return .gray
            case .academic: return .green
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Document Preview")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(documentFormat)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Format badge
                Text(documentFormat.uppercased())
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green, in: Capsule())
            }

            // Document content preview
            VStack(alignment: .leading, spacing: 12) {
                // Title
                HStack {
                    Text("Title:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(documentTitle)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Spacer()
                }

                // Content preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content Preview:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Text(documentContent)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(3)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }

                // Template selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("Template:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Button(action: { showingTemplateSelector.toggle() }) {
                        HStack {
                            Image(systemName: selectedTemplate.icon)
                                .foregroundColor(selectedTemplate.color)

                            Text(selectedTemplate.rawValue)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(showingTemplateSelector ? 180 : 0))
                                .animation(.easeInOut(duration: 0.3), value: showingTemplateSelector)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    if showingTemplateSelector {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 8) {
                            ForEach(DocumentTemplate.allCases, id: \.self) { template in
                                Button(action: {
                                    selectedTemplate = template
                                    showingTemplateSelector = false
                                }) {
                                    HStack {
                                        Image(systemName: template.icon)
                                            .foregroundColor(template.color)

                                        Text(template.rawValue)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                    .padding(8)
                                    .background(
                                        selectedTemplate == template ? template.color.opacity(0.2) : .quaternary,
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(selectedTemplate == template ? template.color : .clear, lineWidth: 1)
                                    )
                                }
                                .accessibilityLabel("Select \(template.rawValue) template")
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }

            // Estimated details
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Pages")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(estimatedPages)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Generation Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("~\(estimatedTime)s")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: showingTemplateSelector)
    }

    // MARK: - Computed Properties

    private var documentFormat: String {
        (parameters["format"]?.value as? String) ?? "PDF"
    }

    private var documentTitle: String {
        (parameters["title"]?.value as? String) ?? "Untitled Document"
    }

    private var documentContent: String {
        let content = (parameters["content"]?.value as? String) ?? "Document content"
        return "This document will contain information about \(content). The content will be automatically formatted and structured based on the selected template."
    }

    private var estimatedPages: Int {
        let contentLength = documentContent.count
        return max(1, contentLength / 500) // Rough estimate
    }

    private var estimatedTime: Int {
        return estimatedPages * 2 + 3 // Rough time estimate
    }
}

// MARK: - Email Preview

struct EmailPreviewCard: View {
    let parameters: [String: AnyCodable]
    @State private var showingFullContent = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "envelope.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Preview")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Ready to send")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Priority indicator
                if isHighPriority {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.red)
                        .accessibilityLabel("High priority")
                }
            }

            // Email details
            VStack(spacing: 12) {
                // Recipients
                EmailFieldView(
                    label: "To",
                    content: recipients,
                    icon: "person.fill",
                    color: .blue
                )

                // Subject
                EmailFieldView(
                    label: "Subject",
                    content: subject,
                    icon: "textformat",
                    color: .purple
                )

                // Body preview
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.green)

                        Text("Body")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: { showingFullContent.toggle() }) {
                            Text(showingFullContent ? "Show Less" : "Show More")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }

                    Text(emailBody)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(showingFullContent ? nil : 3)
                        .padding()
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                        .animation(.easeInOut(duration: 0.3), value: showingFullContent)
                }

                // Attachments (if any)
                if !attachments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "paperclip")
                                .foregroundColor(.orange)

                            Text("Attachments (\(attachments.count))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }

                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 4) {
                            ForEach(attachments, id: \.self) { attachment in
                                HStack {
                                    Image(systemName: "doc")
                                        .foregroundColor(.gray)

                                    Text(attachment)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    Spacer()
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }

            // Email statistics
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Word Count")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(wordCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .center, spacing: 4) {
                    Text("Read Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("~\(readTime)min")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Recipients")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(recipientCount)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Computed Properties

    private var recipients: String {
        (parameters["recipient"]?.value as? String) ?? "recipient@example.com"
    }

    private var subject: String {
        (parameters["subject"]?.value as? String) ?? "Subject"
    }

    private var emailBody: String {
        let content = (parameters["body"]?.value as? String) ?? "Email body content"
        return "Hi,\n\n\(content)\n\nBest regards,\n[Your Name]"
    }

    private var attachments: [String] {
        (parameters["attachments"]?.value as? [String]) ?? []
    }

    private var isHighPriority: Bool {
        (parameters["priority"]?.value as? String)?.lowercased() == "high"
    }

    private var wordCount: Int {
        emailBody.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }

    private var readTime: Int {
        max(1, wordCount / 200) // Average reading speed
    }

    private var recipientCount: Int {
        recipients.components(separatedBy: ",").count
    }
}

// MARK: - Calendar Preview

struct CalendarPreviewCard: View {
    let parameters: [String: AnyCodable]
    @State private var selectedCalendar: String = "Personal"
    @State private var showingCalendarSelector = false

    private let availableCalendars = ["Personal", "Work", "Family", "Projects"]

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "calendar.circle.fill")
                    .font(.title2)
                    .foregroundColor(.purple)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Calendar Event")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("New event")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Duration badge
                Text(duration)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.purple, in: Capsule())
            }

            // Event details
            VStack(spacing: 12) {
                // Title
                EventFieldView(
                    label: "Title",
                    content: eventTitle,
                    icon: "textformat",
                    color: .blue
                )

                // Date and time
                EventFieldView(
                    label: "Date & Time",
                    content: dateTimeString,
                    icon: "clock.fill",
                    color: .orange
                )

                // Location (if provided)
                if !location.isEmpty {
                    EventFieldView(
                        label: "Location",
                        content: location,
                        icon: "location.fill",
                        color: .red
                    )
                }

                // Calendar selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calendar")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)

                    Button(action: { showingCalendarSelector.toggle() }) {
                        HStack {
                            Circle()
                                .fill(calendarColor)
                                .frame(width: 12, height: 12)

                            Text(selectedCalendar)
                                .foregroundColor(.primary)

                            Spacer()

                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(showingCalendarSelector ? 180 : 0))
                                .animation(.easeInOut(duration: 0.3), value: showingCalendarSelector)
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }

                    if showingCalendarSelector {
                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 6) {
                            ForEach(availableCalendars, id: \.self) { calendar in
                                Button(action: {
                                    selectedCalendar = calendar
                                    showingCalendarSelector = false
                                }) {
                                    HStack {
                                        Circle()
                                            .fill(colorForCalendar(calendar))
                                            .frame(width: 8, height: 8)

                                        Text(calendar)
                                            .font(.caption)
                                            .foregroundColor(.primary)

                                        Spacer()

                                        if selectedCalendar == calendar {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .foregroundColor(.blue)
                                        }
                                    }
                                    .padding(8)
                                    .background(
                                        selectedCalendar == calendar ? .blue.opacity(0.2) : .quaternary,
                                        in: RoundedRectangle(cornerRadius: 6)
                                    )
                                }
                                .accessibilityLabel("Select \(calendar) calendar")
                            }
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }

                // Attendees (if any)
                if !attendees.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attendees (\(attendees.count))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                        ], spacing: 6) {
                            ForEach(attendees, id: \.self) { attendee in
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundColor(.blue)

                                    Text(attendee)
                                        .font(.caption)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                            }
                        }
                    }
                }
            }

            // Event summary
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Conflicts")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(hasConflicts ? "⚠️ 1 conflict" : "✅ None")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(hasConflicts ? .red : .green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Reminder")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("15 min before")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: showingCalendarSelector)
    }

    // MARK: - Computed Properties

    private var eventTitle: String {
        (parameters["title"]?.value as? String) ?? "Meeting"
    }

    private var dateTimeString: String {
        let date = (parameters["date"]?.value as? String) ?? "Today"
        let time = (parameters["time"]?.value as? String) ?? "2:00 PM"
        return "\(date) at \(time)"
    }

    private var location: String {
        (parameters["location"]?.value as? String) ?? ""
    }

    private var duration: String {
        let durationValue = (parameters["duration"]?.value as? Int) ?? 60
        if durationValue < 60 {
            return "\(durationValue)m"
        } else {
            let hours = durationValue / 60
            let minutes = durationValue % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }

    private var attendees: [String] {
        (parameters["attendees"]?.value as? [String]) ?? []
    }

    private var hasConflicts: Bool {
        // Simulate conflict detection
        Bool.random()
    }

    private var calendarColor: Color {
        colorForCalendar(selectedCalendar)
    }

    private func colorForCalendar(_ calendar: String) -> Color {
        switch calendar {
        case "Personal": return .blue
        case "Work": return .orange
        case "Family": return .green
        case "Projects": return .purple
        default: return .gray
        }
    }
}

// MARK: - Helper Views

struct EmailFieldView: View {
    let label: String
    let content: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct EventFieldView: View {
    let label: String
    let content: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding()
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Result Views

struct DocumentResultView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("Document Generated Successfully")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Your PDF document is ready to view and share.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 16) {
                Button("Preview") {
                    // Preview action
                }
                .buttonStyle(.borderedProminent)

                Button("Share") {
                    // Share action
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct EmailResultView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundColor(.green)

            Text("Email Sent Successfully")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Your email has been delivered to the recipients.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CalendarResultView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(.purple)

            Text("Event Created Successfully")
                .font(.headline)
                .foregroundColor(.primary)

            Text("The event has been added to your calendar.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("View in Calendar") {
                // Open calendar action
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Document Preview") {
    DocumentPreviewCard(parameters: [
        "format": AnyCodable("PDF"),
        "content": AnyCodable("quarterly financial results"),
        "title": AnyCodable("Q3 2024 Financial Report"),
    ])
    .padding()
    .modifier(GlassViewModifier())
}

#Preview("Email Preview") {
    EmailPreviewCard(parameters: [
        "recipient": AnyCodable("john@company.com"),
        "subject": AnyCodable("Meeting Follow-up"),
        "body": AnyCodable("Thanks for the productive meeting today. I wanted to follow up on the action items we discussed."),
        "priority": AnyCodable("high"),
    ])
    .padding()
    .modifier(GlassViewModifier())
}

#Preview("Calendar Preview") {
    CalendarPreviewCard(parameters: [
        "title": AnyCodable("Team Standup"),
        "date": AnyCodable("Tomorrow"),
        "time": AnyCodable("9:00 AM"),
        "duration": AnyCodable(30),
        "location": AnyCodable("Conference Room A"),
    ])
    .padding()
    .modifier(GlassViewModifier())
}
