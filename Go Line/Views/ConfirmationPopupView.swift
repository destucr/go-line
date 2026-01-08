import SwiftUI

struct ConfirmationPopupView: View {
    var title: String = "EXIT TO MENU"
    var message: String = "Your current progress will be lost."
    var cancelText: String = "CANCEL"
    var exitText: String = "EXIT"
    
    var onCancel: () -> Void
    var onExit: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onCancel()
                }
            
            // Popup Container
            VStack(spacing: 25) {
                Text(title)
                    .font(.system(size: 24, weight: .black, design: .monospaced))
                    .foregroundColor(.orange)
                
                Text(message)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 20) {
                    Button(action: {
                        SoundManager.shared.playSound("sfx_click_cancel")
                        onCancel()
                    }, label: {
                        Text(cancelText)
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .frame(width: 140, height: 50)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .contentShape(Rectangle())
                    })
                    
                    Button(action: {
                        SoundManager.shared.playSound("soft_click")
                        onExit()
                    }, label: {
                        Text(exitText)
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .frame(width: 140, height: 50)
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .cornerRadius(6)
                            .contentShape(Rectangle())
                    })
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 30)
            .background(Color(white: 0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black, radius: 20)
            .frame(maxWidth: 400)
            .padding(.horizontal, 40)
        }
    }
}

struct ConfirmationPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationPopupView(onCancel: {}, onExit: {})
            .previewLayout(.sizeThatFits)
    }
}
