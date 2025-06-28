// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Advanced analytics dashboard for voice interaction metrics and performance insights
 * Issues & Complexity Summary: Real-time data visualization, performance tracking, user behavior analytics, and voice quality metrics
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~600+
 *   - Core Algorithm Complexity: High (Real-time charting, data aggregation, metrics calculation)
 *   - Dependencies: 4 New (SwiftUI, Charts, Combine, NaturalLanguage)
 *   - State Management Complexity: Medium (Analytics data, chart states, filtering)
 *   - Novelty/Uncertainty Factor: Medium (Voice analytics visualization patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 82%
 * Justification for Estimates: Advanced analytics dashboard with real-time charting and comprehensive metrics
 * Final Code Complexity (Actual %): 88%
 * Overall Result Score (Success & Quality %): 93%
 * Key Variances/Learnings: Analytics visualization requires careful data aggregation and responsive chart design
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Charts
import Combine

// MARK: - Analytics Dashboard View

struct AnalyticsDashboardView: View {
    let analytics: VoiceAnalytics
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeRange: TimeRange = .last24Hours
    @State private var selectedMetric: MetricType = .commandSuccess
    @State private var showingDetailView: Bool = false
    @State private var selectedChartData: ChartDataPoint?

    enum TimeRange: String, CaseIterable {
        case lastHour = "Last Hour"
        case last24Hours = "Last 24 Hours"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"

        var duration: TimeInterval {
            switch self {
            case .lastHour: return 3600
            case .last24Hours: return 86400
            case .lastWeek: return 604800
            case .lastMonth: return 2592000
            }
        }
    }

    enum MetricType: String, CaseIterable {
        case commandSuccess = "Command Success"
        case responseTime = "Response Time"
        case voiceQuality = "Voice Quality"
        case intentDistribution = "Intent Distribution"
        case userSatisfaction = "User Satisfaction"

        var icon: String {
            switch self {
            case .commandSuccess: return "checkmark.circle.fill"
            case .responseTime: return "clock.fill"
            case .voiceQuality: return "waveform"
            case .intentDistribution: return "chart.pie.fill"
            case .userSatisfaction: return "star.fill"
            }
        }

        var color: Color {
            switch self {
            case .commandSuccess: return .green
            case .responseTime: return .blue
            case .voiceQuality: return .purple
            case .intentDistribution: return .orange
            case .userSatisfaction: return .yellow
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                analyticsBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Header controls
                        analyticsHeader

                        // Key metrics summary
                        keyMetricsSection

                        // Main chart
                        mainChartSection

                        // Performance breakdown
                        performanceBreakdownSection

                        // Intent distribution
                        intentDistributionSection

                        // Voice quality metrics
                        voiceQualitySection

                        // Session insights
                        sessionInsightsSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Voice Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingDetailView) {
            if let selectedData = selectedChartData {
                MetricDetailView(dataPoint: selectedData, analytics: analytics)
            }
        }
    }

    // MARK: - View Components

    private var analyticsBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.02, green: 0.05, blue: 0.15),
                Color(red: 0.05, green: 0.02, blue: 0.12),
                Color(red: 0.03, green: 0.03, blue: 0.08),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var analyticsHeader: some View {
        analyticsGlassCard {
            VStack(spacing: 15) {
                HStack {
                    Text("🧪 SANDBOX ANALYTICS")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)

                    Spacer()

                    Text("Session: \(formatDuration(Date().timeIntervalSince(analytics.sessionStartTime)))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Time range selector
                HStack {
                    Text("Time Range:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .colorScheme(.dark)
                }

                // Metric selector
                HStack {
                    Text("Metric:")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(MetricType.allCases, id: \.self) { metric in
                            HStack {
                                Image(systemName: metric.icon)
                                Text(metric.rawValue)
                            }.tag(metric)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .foregroundColor(.cyan)
                }
            }
            .padding()
        }
    }

    private var keyMetricsSection: some View {
        analyticsGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Key Metrics")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    metricCard(
                        title: "Success Rate",
                        value: "\(Int(analytics.successRate * 100))%",
                        color: .green,
                        icon: "checkmark.circle.fill"
                    )

                    metricCard(
                        title: "Avg Response",
                        value: "\(Int(analytics.averageResponseTime * 1000))ms",
                        color: .blue,
                        icon: "clock.fill"
                    )

                    metricCard(
                        title: "Total Commands",
                        value: "\(analytics.totalCommands)",
                        color: .purple,
                        icon: "mic.fill"
                    )

                    metricCard(
                        title: "Satisfaction",
                        value: "\(String(format: "%.1f", analytics.averageSatisfaction))/5",
                        color: .yellow,
                        icon: "star.fill"
                    )
                }
            }
            .padding()
        }
    }

    private var mainChartSection: some View {
        analyticsGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: selectedMetric.icon)
                        .font(.title2)
                        .foregroundColor(selectedMetric.color)

                    Text(selectedMetric.rawValue)
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { showingDetailView = true }) {
                        Image(systemName: "info.circle")
                            .foregroundColor(.cyan)
                    }
                }

                // Chart based on selected metric
                chartForSelectedMetric
                    .frame(height: 200)
            }
            .padding()
        }
    }

    @ViewBuilder
    private var chartForSelectedMetric: some View {
        switch selectedMetric {
        case .commandSuccess:
            successRateChart
        case .responseTime:
            responseTimeChart
        case .voiceQuality:
            voiceQualityChart
        case .intentDistribution:
            intentDistributionChart
        case .userSatisfaction:
            satisfactionChart
        }
    }

    private var successRateChart: some View {
        Chart {
            ForEach(generateSuccessRateData(), id: \.timestamp) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Success Rate", dataPoint.value)
                )
                .foregroundStyle(.green)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Success Rate", dataPoint.value)
                )
                .foregroundStyle(LinearGradient(
                    gradient: Gradient(colors: [.green.opacity(0.3), .clear]),
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
        }
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

    private var responseTimeChart: some View {
        Chart {
            ForEach(generateResponseTimeData(), id: \.timestamp) { dataPoint in
                BarMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Response Time", dataPoint.value)
                )
                .foregroundStyle(.blue)
            }
        }
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

    private var voiceQualityChart: some View {
        Chart {
            ForEach(generateVoiceQualityData(), id: \.timestamp) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Quality", dataPoint.value)
                )
                .foregroundStyle(.purple)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
        }
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

    private var intentDistributionChart: some View {
        Chart {
            ForEach(Array(analytics.intentDistribution.keys), id: \.self) { intent in
                SectorMark(
                    angle: .value("Count", analytics.intentDistribution[intent] ?? 0),
                    innerRadius: .ratio(0.4),
                    angularInset: 2
                )
                .foregroundStyle(colorForIntent(intent))
            }
        }
        .chartLegend(position: .bottom, alignment: .center)
        .chartAngleSelection(value: .constant(nil))
    }

    private var satisfactionChart: some View {
        Chart {
            ForEach(generateSatisfactionData(), id: \.timestamp) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Satisfaction", dataPoint.value)
                )
                .foregroundStyle(.yellow)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Satisfaction", dataPoint.value)
                )
                .foregroundStyle(.yellow)
            }
        }
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

    private var performanceBreakdownSection: some View {
        analyticsGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "speedometer")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Performance Breakdown")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(spacing: 12) {
                    performanceMetric(
                        title: "Voice Recognition",
                        value: analytics.voiceQualityMetrics.recognitionAccuracy,
                        color: .green
                    )

                    performanceMetric(
                        title: "Speech Clarity",
                        value: analytics.voiceQualityMetrics.speechClarity,
                        color: .blue
                    )

                    performanceMetric(
                        title: "Background Noise",
                        value: 1.0 - analytics.voiceQualityMetrics.backgroundNoiseLevel,
                        color: .purple
                    )

                    performanceMetric(
                        title: "Audio Volume",
                        value: analytics.voiceQualityMetrics.averageVolumeLevel / 100.0,
                        color: .cyan
                    )
                }
            }
            .padding()
        }
    }

    private var intentDistributionSection: some View {
        analyticsGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Command Distribution")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(Array(analytics.intentDistribution.keys), id: \.self) { intent in
                        intentCard(intent: intent, count: analytics.intentDistribution[intent] ?? 0)
                    }
                }
            }
            .padding()
        }
    }

    private var voiceQualitySection: some View {
        analyticsGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "waveform.path")
                        .font(.title2)
                        .foregroundColor(.cyan)

                    Text("Voice Quality Metrics")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                HStack(spacing: 20) {
                    qualityIndicator(
                        title: "Clarity",
                        value: analytics.voiceQualityMetrics.speechClarity,
                        color: .blue
                    )

                    qualityIndicator(
                        title: "Volume",
                        value: analytics.voiceQualityMetrics.averageVolumeLevel / 100.0,
                        color: .green
                    )

                    qualityIndicator(
                        title: "Noise",
                        value: 1.0 - analytics.voiceQualityMetrics.backgroundNoiseLevel,
                        color: .purple
                    )
                }
            }
            .padding()
        }
    }

    private var sessionInsightsSection: some View {
        analyticsGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.pink)

                    Text("Session Insights")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    insightRow(
                        title: "Most Used Command",
                        value: mostUsedCommand,
                        icon: "star.fill",
                        color: .yellow
                    )

                    insightRow(
                        title: "Peak Performance Time",
                        value: peakPerformanceTime,
                        icon: "clock.fill",
                        color: .green
                    )

                    insightRow(
                        title: "Improvement Suggestion",
                        value: improvementSuggestion,
                        icon: "lightbulb.fill",
                        color: .orange
                    )

                    insightRow(
                        title: "Workflow Completions",
                        value: "\(analytics.workflowCompletions.values.reduce(0, +))",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func metricCard(title: String, value: String, color: Color, icon: String) -> some View {
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
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }

    private func performanceMetric(title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Spacer()

                Text("\(Int(value * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }

            ProgressView(value: value)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .frame(height: 6)
        }
    }

    private func intentCard(intent: CommandIntent, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: iconForIntent(intent))
                    .foregroundColor(colorForIntent(intent))

                Spacer()

                Text("\(count)")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            Text(intent.rawValue)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(1)
        }
        .padding()
        .background(colorForIntent(intent).opacity(0.1))
        .cornerRadius(12)
    }

    private func qualityIndicator(title: String, value: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 8)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: value)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(value * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func insightRow(title: String, value: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func analyticsGlassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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

    // MARK: - Helper Methods

    private func formatDuration(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        let seconds = Int(interval) % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }

    private func colorForIntent(_ intent: CommandIntent) -> Color {
        switch intent {
        case .generateDocument: return .blue
        case .sendEmail: return .green
        case .scheduleCalendar: return .purple
        case .performSearch: return .orange
        case .uploadStorage: return .cyan
        case .general: return .gray
        }
    }

    private func iconForIntent(_ intent: CommandIntent) -> String {
        switch intent {
        case .generateDocument: return "doc.text.fill"
        case .sendEmail: return "envelope.fill"
        case .scheduleCalendar: return "calendar.badge.plus"
        case .performSearch: return "magnifyingglass"
        case .uploadStorage: return "icloud.and.arrow.up.fill"
        case .general: return "bubble.left.fill"
        }
    }

    private var mostUsedCommand: String {
        analytics.intentDistribution.max(by: { $0.value < $1.value })?.key.rawValue ?? "None"
    }

    private var peakPerformanceTime: String {
        // Mock data for now - would calculate based on actual usage patterns
        let hour = Calendar.current.component(.hour, from: Date())
        return "\(hour):00 - \(hour + 1):00"
    }

    private var improvementSuggestion: String {
        if analytics.voiceQualityMetrics.backgroundNoiseLevel > 0.3 {
            return "Consider using in quieter environment"
        } else if analytics.successRate < 0.8 {
            return "Try speaking more clearly"
        } else if analytics.averageResponseTime > 2.0 {
            return "Check network connection"
        } else {
            return "Great performance! Keep it up"
        }
    }

    // MARK: - Mock Data Generation

    private func generateSuccessRateData() -> [ChartDataPoint] {
        let now = Date()
        return (0..<10).map { i in
            ChartDataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-i * 3600)),
                value: Double.random(in: 0.7...1.0)
            )
        }
    }

    private func generateResponseTimeData() -> [ChartDataPoint] {
        let now = Date()
        return (0..<10).map { i in
            ChartDataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-i * 3600)),
                value: Double.random(in: 0.5...3.0)
            )
        }
    }

    private func generateVoiceQualityData() -> [ChartDataPoint] {
        let now = Date()
        return (0..<10).map { i in
            ChartDataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-i * 3600)),
                value: Double.random(in: 0.6...1.0)
            )
        }
    }

    private func generateSatisfactionData() -> [ChartDataPoint] {
        let now = Date()
        return (0..<10).map { i in
            ChartDataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-i * 3600)),
                value: Double.random(in: 3.0...5.0)
            )
        }
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint {
    let timestamp: Date
    let value: Double
}

// MARK: - Metric Detail View

struct MetricDetailView: View {
    let dataPoint: ChartDataPoint
    let analytics: VoiceAnalytics
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Detailed metric information would go here")
                        .foregroundColor(.white)
                        .padding()
                }
            }
            .background(Color.black)
            .navigationTitle("Metric Details")
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

struct AnalyticsDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsDashboardView(analytics: VoiceAnalytics())
            .preferredColorScheme(.dark)
    }
}
