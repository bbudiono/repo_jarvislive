// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Connection button component displayed when not connected to LiveKit
 * Issues & Complexity Summary: Animated connection button with gradient effects
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~60
 *   - Core Algorithm Complexity: Medium (gradient animations, connection states)
 *   - Dependencies: 1 (SwiftUI)
 *   - State Management Complexity: Medium (connection state, animations)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 70%
 * Initial Code Complexity Estimate %: 75%
 * Justification for Estimates: Connection button with gradients and animations
 * Final Code Complexity (Actual %): 77%
 * Overall Result Score (Success & Quality %): 93%
 * Key Variances/Learnings: Complex visual effects benefit from modular extraction
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct ConnectionButtonView: View {
    let statusColor: Color
    let microphoneIcon: String
    let isConnecting: Bool
    let onConnect: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Button(action: onConnect) {
                ZStack {
                    // Outer glow ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    statusColor.opacity(0.3),
                                    statusColor.opacity(0.1),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 100, height: 100)

                    // Main button background
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    statusColor.opacity(0.3),
                                    statusColor.opacity(0.1),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 1)

                    // Connection icon
                    Image(systemName: microphoneIcon)
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white)
                        .scaleEffect(isConnecting ? 0.9 : 1.0)
                        .animation(
                            isConnecting ?
                            Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true) :
                            .default,
                            value: isConnecting
                        )
                }
            }
            .buttonStyle(GlassmorphicButtonStyle())

            Text("Connect to start voice chat")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .modifier(GlassViewModifier())
    }
}

struct ConnectionButtonView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ConnectionButtonView(
                statusColor: .cyan,
                microphoneIcon: "mic.slash.fill",
                isConnecting: false,
                onConnect: {}
            )

            ConnectionButtonView(
                statusColor: .orange,
                microphoneIcon: "mic.badge.plus",
                isConnecting: true,
                onConnect: {}
            )
        }
        .preferredColorScheme(.dark)
    }
}
