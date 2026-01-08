import SwiftUI

struct GameHUDView: View {
    @ObservedObject var hudManager = HUDManager.shared
    
    var onPause: () -> Void
    var onMenu: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Dashboard Header
            HStack(alignment: .top, spacing: 0) {
                
                // LEFT: Controls
                HStack(spacing: 0) {
                    HUDButton(icon: "pause.fill", action: onPause)
                    Rectangle().fill(Color.black).frame(width: 2, height: 44)
                    HUDButton(icon: "line.3.horizontal", action: onMenu)
                }
                .background(Color.white)
                .border(Color.black, width: 2)
                
                Spacer()
                
                // CENTER: Primary Score (Ticket Style)
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NET SCORE")
                            .font(MetroTheme.dataFont(size: 8))
                            .foregroundColor(MetroTheme.inkGray)
                        Text("\(hudManager.stitches)")
                            .font(MetroTheme.dataFont(size: 24))
                            .foregroundColor(MetroTheme.inkBlack)
                    }
                    
                    Rectangle().fill(MetroTheme.inkBlack.opacity(0.1)).frame(width: 2, height: 30)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("THREAD")
                            .font(MetroTheme.dataFont(size: 8))
                            .foregroundColor(MetroTheme.inkGray)
                        Text("\(hudManager.thread)")
                            .font(MetroTheme.dataFont(size: 24))
                            .foregroundColor(MetroTheme.inkBlack)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.white)
                .border(Color.black, width: 2)
                .offset(y: 10) // Push down slightly to detach from top edge visually
                
                Spacer()
                
                // RIGHT: System Status (Meters & Time)
                VStack(spacing: 0) {
                    // Top Row: Time & Day
                    HStack {
                        Text("SHIFT \(hudManager.day)")
                            .font(MetroTheme.dataFont(size: 10))
                            .foregroundColor(MetroTheme.inkBlack)
                        Spacer()
                        Text(hudManager.time)
                            .font(MetroTheme.dataFont(size: 10))
                            .foregroundColor(MetroTheme.inkBlack)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(MetroTheme.safetyYellow)
                    .border(Color.black, width: 2)
                    
                    // Meters Container
                    VStack(spacing: 0) {
                        // Tension Meter
                        HStack(spacing: 8) {
                            Text("TENS")
                                .font(MetroTheme.dataFont(size: 9))
                                .frame(width: 30, alignment: .leading)
                            
                            ProgressBar(
                                icon: "waveform.path.ecg",
                                progress: hudManager.tension / hudManager.maxTension,
                                label: "", // Hide label inside bar
                                color: hudManager.tension > 80 ? MetroTheme.alertRed : MetroTheme.inkBlack,
                                isDark: false
                            )
                        }
                        .padding(6)
                        
                        Divider().background(Color.black)
                        
                        // Shift Meter
                        HStack(spacing: 8) {
                            Text("TIME")
                                .font(MetroTheme.dataFont(size: 9))
                                .frame(width: 30, alignment: .leading)
                            
                            ProgressBar(
                                icon: "clock.fill",
                                progress: CGFloat(hudManager.dayProgress),
                                label: "",
                                color: MetroTheme.goGreen,
                                isDark: false
                            )
                        }
                        .padding(6)
                    }
                    .background(Color.white)
                    .border(Color.black, width: 2)
                }
                .frame(width: 180) // Fixed width for stability
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Spacer()
        }
    }
}

struct HUDButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 50, height: 44)
                .foregroundColor(MetroTheme.inkBlack)
        })
    }
}
