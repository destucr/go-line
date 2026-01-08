import SwiftUI

struct ShopView: View {
    @ObservedObject var hudManager = HUDManager.shared
    
    var day: Int
    var onStartNextDay: () -> Void
    
    var body: some View {
        ZStack {
            MetroTheme.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("SHIFT \(day) COMPLETE")
                            .font(MetroTheme.dataFont(size: 14))
                            .foregroundColor(MetroTheme.inkGray)
                            .padding(.bottom, 4)
                        
                        Text("SERVICE DEPOT")
                            .font(MetroTheme.titleFont(size: 32))
                            .foregroundColor(MetroTheme.inkBlack)
                    }
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 12) {
                        StatusIndicator(label: "NET STATUS", value: "STABLE", color: MetroTheme.goGreen)
                        StatusIndicator(label: "THREAD", value: "\(hudManager.thread)", color: MetroTheme.inkBlack)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 40)
                
                Spacer()
                
                // MARK: - Cards
                HStack(spacing: 24) {
                    UpgradeCard(
                        icon: "tram.fill",
                        title: "CARRIAGE",
                        subtitle: "+4 Capacity",
                        level: hudManager.carriageLevel,
                        cost: UpgradeManager.shared.getCarriageCost(),
                        isAffordable: hudManager.thread >= UpgradeManager.shared.getCarriageCost()
                    ) {
                        SoundManager.shared.playSound("soft_click")
                        if UpgradeManager.shared.buyCarriage() {
                            SoundManager.shared.playSound("sfx_levelup")
                        }
                    }
                    
                    UpgradeCard(
                        icon: "speedometer",
                        title: "VELOCITY",
                        subtitle: "Increase Train Speed",
                        level: hudManager.speedLevel,
                        cost: UpgradeManager.shared.getSpeedCost(),
                        isAffordable: hudManager.thread >= UpgradeManager.shared.getSpeedCost()
                    ) {
                        SoundManager.shared.playSound("soft_click")
                        if UpgradeManager.shared.buySpeed() {
                            SoundManager.shared.playSound("sfx_levelup")
                        }
                    }
                    
                    UpgradeCard(
                        icon: "shield.fill",
                        title: "TENSILE",
                        subtitle: "Increase Max Tension",
                        level: hudManager.strengthLevel,
                        cost: UpgradeManager.shared.getStrengthCost(),
                        isAffordable: hudManager.thread >= UpgradeManager.shared.getStrengthCost()
                    ) {
                        SoundManager.shared.playSound("soft_click")
                        if UpgradeManager.shared.buyStrength() {
                            SoundManager.shared.playSound("sfx_levelup")
                        }
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // MARK: - Footer
                Button(action: {
                    SoundManager.shared.playSound("soft_click")
                    onStartNextDay()
                }, label: {
                    HStack {
                        Text("START SHIFT")
                        Image(systemName: "arrow.right")
                    }
                    .font(MetroTheme.titleFont(size: 20))
                    .foregroundColor(MetroTheme.inkBlack)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(MetroTheme.safetyYellow)
                    .border(MetroTheme.inkBlack, width: 3) // Hard border on footer
                })
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
    }
}

struct StatusIndicator: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(label)
                .font(MetroTheme.dataFont(size: 10))
                .foregroundColor(MetroTheme.inkGray)
            Text(value)
                .font(MetroTheme.dataFont(size: 24))
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white)
        .border(MetroTheme.inkBlack, width: 2)
    }
}

struct UpgradeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let level: Int
    let cost: Int
    let isAffordable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Icon Header
                HStack {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(isAffordable ? MetroTheme.inkBlack : MetroTheme.inkGray.opacity(0.3))
                    Spacer()
                    Text("LVL \(level)")
                        .font(MetroTheme.dataFont(size: 14))
                        .foregroundColor(MetroTheme.inkGray)
                }
                .padding(.bottom, 20)
                
                Text(title)
                    .font(MetroTheme.titleFont(size: 20))
                    .foregroundColor(isAffordable ? MetroTheme.inkBlack : MetroTheme.inkGray)
                
                Text(subtitle.uppercased())
                    .font(MetroTheme.dataFont(size: 10))
                    .foregroundColor(MetroTheme.inkGray)
                    .padding(.bottom, 20)
                
                Spacer()
                
                // Cost Pill
                HStack {
                    Text("COST")
                        .font(MetroTheme.dataFont(size: 10))
                        .foregroundColor(MetroTheme.inkGray)
                    Spacer()
                    Text("\(cost)")
                        .font(MetroTheme.dataFont(size: 18))
                        .foregroundColor(isAffordable ? MetroTheme.inkBlack : MetroTheme.inkGray)
                }
                .padding(.top, 12)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(MetroTheme.inkBlack.opacity(0.1)),
                    alignment: .top
                )
            }
            .metroCardStyle(borderColor: isAffordable ? MetroTheme.inkBlack : MetroTheme.inkBlack.opacity(0.1))
        }
        .buttonStyle(PlainButtonStyle())
        .frame(height: 220)
        .disabled(!isAffordable)
        .opacity(isAffordable ? 1.0 : 0.6)
    }
}
