import SwiftUI

struct GameHUDView: View {
    @ObservedObject var hudManager = HUDManager.shared
    
    var onPause: () -> Void
    var onMenu: () -> Void
    
    // Industrial Palette for Light Background
    private let textPrimary = Color(white: 0.15)
    private let textSecondary = Color(white: 0.4)
    private let accentColor = Color.orange
    private let containerBg = Color.white.opacity(0.85)
    private let strokeColor = Color(white: 0.1).opacity(0.1)
    
    var body: some View {
        VStack(spacing: 8) {
            // Top Bar
            HStack(alignment: .center) {
                // Left: Controls
                HStack(spacing: 8) {
                    HUDButton(icon: "pause.fill", action: onPause)
                    HUDButton(icon: "line.3.horizontal", action: onMenu)
                }
                .frame(width: 100, alignment: .leading)
                
                Spacer()
                
                // Center: Score/Stitches
                VStack(spacing: 0) {
                    Text("\(hudManager.stitches)")
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .foregroundColor(textPrimary)
                    Text("STITCHES")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(textSecondary)
                }
                .frame(minWidth: 80)
                
                Spacer()
                
                // Right: Thread & Shift
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "f.circle.fill")
                            .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.0)) // Darker Orange
                            .font(.system(size: 14, weight: .bold))
                        Text("\(hudManager.thread)")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(textPrimary)
                    }
                    
                    Text("DAY \(hudManager.day) • \(hudManager.time)")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(textSecondary)
                }
                .frame(width: 120, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            
            // Network Tension & Shift Progress
            HStack(spacing: 30) {
                ProgressBar(
                    icon: "waveform.path.ecg",
                    progress: hudManager.tension / hudManager.maxTension,
                    label: "\(Int(hudManager.tension))%",
                    color: hudManager.tension > 80 ? .red : accentColor,
                    isDark: false
                )
                
                ProgressBar(
                    icon: "clock.fill",
                    progress: CGFloat(hudManager.dayProgress),
                    label: "\(Int(hudManager.dayProgress * 100))%",
                    color: .green,
                    isDark: false
                )
            }
            .padding(.horizontal, 80)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .padding(.horizontal, 60)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct HUDButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            SoundManager.shared.playSound("soft_click")
            action()
        }, label: {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color(white: 0.1).opacity(0.1), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .foregroundColor(Color(white: 0.15))
        })
    }
}
