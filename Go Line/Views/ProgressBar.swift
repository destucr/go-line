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
                .font(.system(size: 10))
                .foregroundColor(baseColor.opacity(0.5))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(baseColor.opacity(0.1))
                        .frame(height: 3)
                    
                    Capsule()
                        .fill(color)
                        .frame(width: geo.size.width * min(1.0, max(0, progress)), height: 3)
                        .animation(.linear(duration: 0.5), value: progress)
                }
            }
            .frame(height: 3)
            
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(baseColor.opacity(0.5))
                .frame(width: 32)
        }
    }
}
