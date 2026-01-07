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
    private let accentColor = Color.orange
    private let glassBackground = Color.white.opacity(0.05)
    
    var body: some View {
        ZStack {
            // Background with subtle gradient
            LinearGradient(colors: [primaryDark, Color(white: 0.05)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Header Bar
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SHIFT \(day) COMPLETE")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                        Text("INFRASTRUCTURE UPGRADES")
                            .font(.system(size: 24, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Compact Performance
                    HStack(spacing: 20) {
                        PerformanceItem(
                            icon: "waveform.path.ecg",
                            value: "\(Int(hudManager.tension))%",
                            label: "TENSION",
                            progress: hudManager.tension / hudManager.maxTension,
                            color: hudManager.tension > 80 ? .red : accentColor
                        )
                        .frame(width: 140)
                        
                        PerformanceItem(
                            icon: "clock.fill",
                            value: "\(Int(hudManager.dayProgress * 100))%",
                            label: "QUOTA",
                            progress: CGFloat(hudManager.dayProgress),
                            color: .green
                        )
                        .frame(width: 140)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                
                Spacer()
                
                // Resources & Upgrades Container
                VStack(spacing: 16) {
                    // Available Thread
                    HStack(spacing: 12) {
                        Image(systemName: "f.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.system(size: 20))
                        Text("\(totalThread)")
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        Text("AVAILABLE THREAD")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(glassBackground))
                    
                    // Upgrade Grid
                    HStack(spacing: 16) {
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
                    .padding(.horizontal, 30)
                }
                
                Spacer()
                
                // Footer Action
                Button(action: onStartNextDay) {
                    HStack {
                        Text("INITIALIZE SHIFT \(day + 1)")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundColor(.black)
                    .padding(.horizontal, 60)
                    .padding(.vertical, 14)
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

struct PerformanceItem: View {
    let icon: String
    let value: String
    let label: String
    let progress: CGFloat
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                Text(value)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule().fill(color)
                    .frame(width: max(0, min(140 * progress, 140)))
            }
            .frame(height: 3)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03)))
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
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isAffordable ? .orange : .white.opacity(0.2))
                
                VStack(spacing: 2) {
                    Text(title.uppercased())
                        .font(.system(size: 10, weight: .black))
                        .foregroundColor(.white)
                    Text(description)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                
                Divider().background(Color.white.opacity(0.1))
                
                VStack(spacing: 2) {
                    Text("LEVEL \(level)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "f.circle.fill")
                            .font(.system(size: 9))
                        Text("\(cost)")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(isAffordable ? .orange : .white.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isAffordable ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .disabled(!isAffordable)
        .opacity(isAffordable ? 1.0 : 0.6)
    }
}
