import SwiftUI

struct GameHUDView: View {
    // These would be @ObservedObject or passed in via state in a real app
    // For now we'll use simple properties or a shared state
    var stitches: Int
    var day: String
    var time: String
    var thread: Int
    var tension: CGFloat
    var maxTension: CGFloat
    var level: Int
    
    var onPause: () -> Void
    var onMenu: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background to visualize safe area (optional, keep clear for game)
            Color.clear.frame(height: 100)

            HStack(alignment: .top) {
                // Left Side: Buttons
                HStack(spacing: 20) {
                    Button(action: onPause) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.indigo)
                            .padding(5)
                    }
                    .contentShape(Rectangle())
                    
                    Button(action: onMenu) {
                        Image(systemName: "line.3.horizontal.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.gray)
                            .padding(5)
                    }
                    .contentShape(Rectangle())
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // Right Side: Info
                VStack(alignment: .trailing, spacing: 2) {
                    Text("STITCHES: \(stitches)")
                        .font(.custom("ChalkboardSE-Bold", size: 22))
                        .foregroundColor(.indigo)
                    
                    Text("\(day) - \(time)")
                        .font(.custom("ChalkboardSE-Bold", size: 16))
                        .foregroundColor(.gray)
                    
                    Text("THREAD: \(thread)")
                        .font(.custom("ChalkboardSE-Bold", size: 16))
                        .foregroundColor(.orange)
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 10)
            
            VStack(spacing: 0) {
                ProgressView(value: min(1.0, Double(stitches) / 150.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .indigo))
                    .frame(height: 3)
                
                ProgressView(value: min(1.0, Double(tension) / Double(maxTension)))
                    .progressViewStyle(LinearProgressViewStyle(tint: tension / maxTension > 0.8 ? .red : .orange))
                    .frame(height: 3)
            }
            .allowsHitTesting(false)
        }
    }
}
