import SwiftUI

struct ShopView: View {
    @State private var totalThread: Int = CurrencyManager.shared.totalThread
    @State private var carriageLevel: Int = UpgradeManager.shared.carriageCount
    @State private var speedLevel: Int = UpgradeManager.shared.speedLevel
    @State private var strengthLevel: Int = UpgradeManager.shared.strengthLevel
    
    var day: Int
    var onStartNextDay: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.9).ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Text("SHIFT COMPLETE")
                        .font(.custom("ChalkboardSE-Bold", size: 40))
                        .foregroundColor(.white)
                    
                    Text("THREAD: \(totalThread)")
                        .font(.custom("ChalkboardSE-Bold", size: 30))
                        .foregroundColor(.orange)
                    
                    HStack(spacing: geometry.size.width * 0.05) {
                        UpgradeButton(
                            title: "New Carriage (+6 Cap)",
                            level: carriageLevel,
                            cost: UpgradeManager.shared.getCarriageCost(),
                            isAffordable: totalThread >= UpgradeManager.shared.getCarriageCost(),
                            width: min(220, geometry.size.width * 0.28)
                        ) {
                            if UpgradeManager.shared.buyCarriage() {
                                syncState()
                            }
                        }
                        
                        UpgradeButton(
                            title: "Faster Needle (+15% Spd)",
                            level: speedLevel,
                            cost: UpgradeManager.shared.getSpeedCost(),
                            isAffordable: totalThread >= UpgradeManager.shared.getSpeedCost(),
                            width: min(220, geometry.size.width * 0.28)
                        ) {
                            if UpgradeManager.shared.buySpeed() {
                                syncState()
                            }
                        }
                        
                        UpgradeButton(
                            title: "Fabric Strength (+25 HP)",
                            level: strengthLevel,
                            cost: UpgradeManager.shared.getStrengthCost(),
                            isAffordable: totalThread >= UpgradeManager.shared.getStrengthCost(),
                            width: min(220, geometry.size.width * 0.28)
                        ) {
                            if UpgradeManager.shared.buyStrength() {
                                syncState()
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onStartNextDay) {
                        Text("START DAY \(day + 1)")
                            .font(.custom("ChalkboardSE-Bold", size: 28))
                            .padding(.horizontal, 60)
                            .padding(.vertical, 15)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .contentShape(Rectangle())
                    .padding(.bottom, 20)
                }
                .padding(.top, 30)
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

struct UpgradeButton: View {
    let title: String
    let level: Int
    let cost: Int
    let isAffordable: Bool
    let width: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Text(title)
                    .font(.custom("ChalkboardSE-Bold", size: 16))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("Lvl \(level) - Cost: \(cost)")
                    .font(.custom("ChalkboardSE-Bold", size: 14))
            }
            .frame(width: width, height: 70)
            .background(isAffordable ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(isAffordable ? 1.0 : 0.6)
            .contentShape(Rectangle())
        }
    }
}
