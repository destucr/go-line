import SwiftUI

struct LineSelectionView: View {
    @ObservedObject var hudManager = HUDManager.shared
    var onColorSelected: (UIColor) -> Void
    
    private struct LineColor {
        let color: UIColor
        let name: String
        let minLevel: Int
    }
    
    private let colors: [LineColor] = [
        LineColor(color: .systemRed, name: "RED", minLevel: 1),
        LineColor(color: .systemBlue, name: "BLUE", minLevel: 2),
        LineColor(color: .systemGreen, name: "GREEN", minLevel: 3),
        LineColor(color: .systemOrange, name: "ORANGE", minLevel: 4),
        LineColor(color: .systemPurple, name: "PURPLE", minLevel: 5)
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            ForEach(colors, id: \.name) { item in
                let color = item.color
                let minLevel = item.minLevel
                let isUnlocked = hudManager.level >= minLevel
                let isSelected = hudManager.selectedColor == color
                
                Button(action: {
                    SoundManager.shared.playSound("soft_click")
                    if isUnlocked {
                        onColorSelected(color)
                    }
                }, label: {
                    ZStack {
                        // Industrial square-ish look
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(color))
                            .frame(width: 30, height: 30)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2)
                                    .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                            )
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        
                        if !isUnlocked {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                })
                .disabled(!isUnlocked)
                .opacity(isUnlocked ? 1.0 : 0.3)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.white.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color(white: 0.1).opacity(0.1), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}
