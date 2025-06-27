// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Connection status display component with animated indicators
 * Issues & Complexity Summary: Extracted modular component for LiveKit connection status
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~40
 *   - Core Algorithm Complexity: Low (status display with animations)
 *   - Dependencies: 1 (SwiftUI)
 *   - State Management Complexity: Low (receives computed properties)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 88%
 * Problem Estimate (Inherent Problem Difficulty %): 65%
 * Initial Code Complexity Estimate %: 70%
 * Justification for Estimates: Simple status component with animation logic
 * Final Code Complexity (Actual %): 72%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Animation state needs to be passed down from parent
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct ConnectionStatusView: View {
    let statusText: String
    let statusColor: Color
    let isConnected: Bool
    let isConnecting: Bool

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)
                    .scaleEffect(isConnecting ? 1.2 : 1.0)
                    .animation(
                        isConnecting ?
                        Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true) :
                        .default,
                        value: isConnecting
                    )

                Text(statusText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .accessibilityIdentifier("ConnectionStatus")
            }

            if isConnected {
                Text("Voice commands are active")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .modifier(GlassViewModifier())
    }
}

struct ConnectionStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConnectionStatusView(
                statusText: "Connected to LiveKit",
                statusColor: .mint,
                isConnected: true,
                isConnecting: false
            )

            ConnectionStatusView(
                statusText: "Connecting...",
                statusColor: .orange,
                isConnected: false,
                isConnecting: true
            )

            ConnectionStatusView(
                statusText: "Ready to Connect",
                statusColor: .cyan,
                isConnected: false,
                isConnecting: false
            )
        }
        .preferredColorScheme(.dark)
    }
}
