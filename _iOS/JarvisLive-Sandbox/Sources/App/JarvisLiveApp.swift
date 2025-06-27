/**
 * Purpose: Main application entry point for Jarvis Live Production with authentication flow
 * Issues & Complexity Summary: SwiftUI App implementation with authentication-aware root view
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~20
 *   - Core Algorithm Complexity: Low
 *   - Dependencies: 2 (SwiftUI, RootContentView)
 *   - State Management Complexity: Low
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 95%
 * Problem Estimate (Inherent Problem Difficulty %): 60%
 * Initial Code Complexity Estimate %: 65%
 * Justification for Estimates: Standard App entry point with authentication integration
 * Final Code Complexity (Actual %): 70%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Clean separation of authentication and main app concerns
 * Last Updated: 2025-06-28
 */

import SwiftUI

@main
struct JarvisLiveApp: App {
    var body: some Scene {
        WindowGroup {
            // Use the new root content view that manages authentication flow
            RootContentView()
                .preferredColorScheme(.dark) // Ensure consistent dark theme
        }
    }
}