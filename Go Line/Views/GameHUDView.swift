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
    var dayProgress: Float
    
    var onPause: () -> Void
    var onMenu: () -> Void
    
    var body: some View {
        ZStack(alignment: .top) {
            HStack(alignment: .top) {
                // Left Side: Buttons
                HStack(spacing: 20) {
                    Button(action: onPause) {
                        Image(systemName: "pause.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(white: 0.3)) // Charcoal gray
                            .padding(5)
                            .contentShape(Rectangle())
                    }
                    
                    Button(action: onMenu) {
                        Image(systemName: "line.3.horizontal.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(Color(white: 0.5))
                            .padding(5)
                            .contentShape(Rectangle())
                    }
                }
                .padding(.leading, 20)
                
                Spacer()
                
                // Right Side: Info
                VStack(alignment: .trailing, spacing: 2) {
                    Text("STITCHES: \(stitches)")
                        .font(.custom("ChalkboardSE-Bold", size: 22))
                        .foregroundColor(Color(white: 0.2)) // Deep charcoal
                    
                    Text("\(day) - \(time) (LVL \(level))")
                        .font(.custom("ChalkboardSE-Bold", size: 16))
                        .foregroundColor(Color(white: 0.4))
                    
                    Text("THREAD: \(thread)")
                        .font(.custom("ChalkboardSE-Bold", size: 16))
                        .foregroundColor(.orange)
                }
                .padding(.trailing, 20)
            }
            .padding(.top, 10)
            
            VStack(spacing: 0) {
                // Day Cycle Progress (How level ends)
                ProgressView(value: min(1.0, Double(dayProgress)))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .frame(height: 3)

                ProgressView(value: min(1.0, Double(stitches) / 150.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: Color(white: 0.3)))
                    .frame(height: 3)
                
                ProgressView(value: min(1.0, Double(tension) / Double(maxTension)))
                    .progressViewStyle(LinearProgressViewStyle(tint: tension / maxTension > 0.8 ? .red : .orange))
                    .frame(height: 3)
            }
            .allowsHitTesting(false)
        }
    }
}
