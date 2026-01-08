import SwiftUI

struct ProgressBar: View {
    let icon: String
    let progress: CGFloat
    let label: String
    let color: Color
    let isDark: Bool
    
    private var baseColor: Color {
        isDark ? .white : Color(white: 0.1)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(baseColor)
                .frame(width: 16)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track Background
                    Rectangle()
                        .fill(Color.black.opacity(0.1))
                        .overlay(
                            Rectangle()
                                .stroke(baseColor.opacity(0.3), lineWidth: 1)
                        )
                    
                    // Fill
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, max(0, progress)))
                        .animation(.linear(duration: 0.2), value: progress) // Snappier animation
                    
                    // Stripe overlay for texture
                    HStack(spacing: 4) {
                        ForEach(0..<Int(geo.size.width / 8), id: \.self) { _ in
                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .frame(width: 1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .mask(Rectangle().frame(width: geo.size.width * min(1.0, max(0, progress))))
                }
            }
            .frame(height: 12) // Thicker bar
            
            Text(label)
                .font(MetroTheme.dataFont(size: 10))
                .foregroundColor(baseColor)
                .frame(width: 36, alignment: .trailing)
        }
    }
}
