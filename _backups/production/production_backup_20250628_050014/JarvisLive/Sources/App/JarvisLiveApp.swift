/**
 * Purpose: Main app entry point for Jarvis Live iOS application
 * Issues & Complexity Summary: Simple app lifecycle management with dependency injection
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~50
 *   - Core Algorithm Complexity: Low (App lifecycle)
 *   - Dependencies: 2 New (SwiftUI, LiveKitManager)
 *   - State Management Complexity: Low (App-level state)
 *   - Novelty/Uncertainty Factor: Low (Standard SwiftUI app)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 60%
 * Problem Estimate (Inherent Problem Difficulty %): 30%
 * Initial Code Complexity Estimate %: 40%
 * Justification for Estimates: Standard iOS app entry point with dependency setup
 * Final Code Complexity (Actual %): 40%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: Clean dependency injection for conversation management
 * Last Updated: 2025-06-26
 */

import SwiftUI

@main
struct JarvisLiveApp: App {
    // Create the main LiveKit manager instance
    @StateObject private var liveKitManager = LiveKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView(liveKitManager: liveKitManager)
                .preferredColorScheme(.dark)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        print("🚀 Jarvis Live App Starting...")
        print("💬 Enhanced Conversation Management Ready")
        print("🔗 Dependencies: LiveKitManager, ConversationManager, KeychainManager")
    }
}