import SwiftUI

struct ShopView: View {
    @ObservedObject var hudManager = HUDManager.shared
    @State private var totalThread: Int = CurrencyManager.shared.totalThread
    @State private var carriageLevel: Int = UpgradeManager.shared.carriageCount
    @State private var speedLevel: Int = UpgradeManager.shared.speedLevel
    @State private var strengthLevel: Int = UpgradeManager.shared.strengthLevel
    
    var day: Int
    var onStartNextDay: () -> Void
    
    // Modern Industrial Palette
    private let primaryDark = Color(white: 0.1)
    private let primaryLight = Color(white: 0.95)
    private let accentColor = Color.orange
    private let glassBackground = Color.white.opacity(0.05)
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(colors: [primaryDark, Color(white: 0.05)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("SHIFT \(day) COMPLETE")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(accentColor)
                        .kerning(2)
                    
                    Text("INFRASTRUCTURE UPGRADES")
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top, 20)
                
                // Shift Performance (New Revamped Section)
                VStack(spacing: 8) {
                    Text("SHIFT PERFORMANCE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.4))
                        .kerning(1)
                    
                    HStack(spacing: 30) {
                        ProgressBar(
                            icon: "waveform.path.ecg",
                            progress: hudManager.tension / hudManager.maxTension,
                            label: "\(Int(hudManager.tension))%",
                            color: hudManager.tension > 80 ? .red : accentColor,
                            isDark: true
                        )
                        
                        ProgressBar(
                            icon: "clock.fill",
                            progress: CGFloat(hudManager.dayProgress),
                            label: "\(Int(hudManager.dayProgress * 100))%",
                            color: .green,
                            isDark: true
                        )
                    }
                    .padding(.horizontal, 40)
                }
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.03)))
                .padding(.horizontal, 80)
                
                // Resources
                HStack(spacing: 12) {
                    Image(systemName: "f.circle.fill")
                        .foregroundColor(accentColor)
                        .font(.system(size: 24))
                    Text("\(totalThread)")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("AVAILABLE THREAD")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(glassBackground))
                
                // Upgrade Grid
                HStack(spacing: 20) {
                    UpgradeCard(
                        icon: "tram.fill",
                        title: "New Carriage",
                        description: "+6 Capacity",
                        level: carriageLevel,
                        cost: UpgradeManager.shared.getCarriageCost(),
                        isAffordable: totalThread >= UpgradeManager.shared.getCarriageCost()
                    ) {
                        if UpgradeManager.shared.buyCarriage() { syncState() }
                    }
                    
                    UpgradeCard(
                        icon: "bolt.fill",
                        title: "Faster Needle",
                        description: "+15% Speed",
                        level: speedLevel,
                        cost: UpgradeManager.shared.getSpeedCost(),
                        isAffordable: totalThread >= UpgradeManager.shared.getSpeedCost()
                    ) {
                        if UpgradeManager.shared.buySpeed() { syncState() }
                    }
                    
                    UpgradeCard(
                        icon: "shield.fill",
                        title: "Fabric Strength",
                        description: "+25 Max Tension",
                        level: strengthLevel,
                        cost: UpgradeManager.shared.getStrengthCost(),
                        isAffordable: totalThread >= UpgradeManager.shared.getStrengthCost()
                    ) {
                        if UpgradeManager.shared.buyStrength() { syncState() }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer Action
                Button(action: onStartNextDay) {
                    HStack {
                        Text("INITIALIZE SHIFT \(day + 1)")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 18)
                    .background(Capsule().fill(accentColor))
                }
                .padding(.bottom, 20)
            }
        }
    }
    
    private func syncState() {
        totalThread = CurrencyManager.shared.totalThread
        carriageLevel = UpgradeManager.shared.carriageCount
        speedLevel = UpgradeManager.shared.speedLevel
        strengthLevel = UpgradeManager.shared.strengthLevel
    }
}

struct UpgradeCard: View {
    let icon: String
    let title: String
    let description: String
    let level: Int
    let cost: Int
    let isAffordable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(isAffordable ? .orange : .white.opacity(0.2))
                
                VStack(spacing: 4) {
                    Text(title.uppercased())
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                VStack(spacing: 4) {
                    Text("LEVEL \(level)")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "f.circle.fill")
                            .font(.system(size: 10))
                        Text("\(cost)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(isAffordable ? .orange : .white.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isAffordable ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .disabled(!isAffordable)
        .opacity(isAffordable ? 1.0 : 0.6)
    }
}