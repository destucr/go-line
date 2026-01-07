import SwiftUI

struct GameHUDView: View {
    @ObservedObject var hudManager = HUDManager.shared
    
    var onPause: () -> Void
    var onMenu: () -> Void
    
    // Modern Palette
    private let primaryDark = Color(white: 0.1)
    private let primaryLight = Color(white: 0.95)
    private let accentColor = Color.orange
    
    var body: some View {
        VStack(spacing: 8) {
            // Top Bar
            HStack {
                // Left: Controls
                HStack(spacing: 12) {
                    Button(action: onPause) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(primaryDark.opacity(0.8)))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: onMenu) {
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 18, weight: .bold))
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(primaryDark.opacity(0.8)))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                // Center: Score/Stitches
                VStack(spacing: 0) {
                    Text("\(hudManager.stitches)")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(primaryDark)
                    Text("STITCHES")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(primaryDark.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.9))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
                
                Spacer()
                
                // Right: Thread & Shift
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "f.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.system(size: 14))
                        Text("\(hudManager.thread)")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(primaryDark)
                    }
                    
                    Text("\(hudManager.day) • \(hudManager.time)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(primaryDark.opacity(0.7))
                }
            }
            .padding(.horizontal, 20)
            
            // Network Tension & Shift Progress (Side-by-Side)
            HStack(spacing: 24) {
                // Tension Bar
                ProgressBar(
                    icon: "waveform.path.ecg",
                    progress: hudManager.tension / hudManager.maxTension,
                    label: "\(Int(hudManager.tension))%",
                    color: hudManager.tension > 80 ? .red : accentColor,
                    isDark: false
                )
                
                // Shift Progress Bar
                ProgressBar(
                    icon: "clock.fill",
                    progress: CGFloat(hudManager.dayProgress),
                    label: "\(Int(hudManager.dayProgress * 100))%",
                    color: .green,
                    isDark: false
                )
            }
            .padding(.horizontal, 40)
            .padding(.top, -4) // Tuck closer to the top bar
            
            Spacer()
        }
    }
}
