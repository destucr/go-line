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
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onCancel()
                }
            
            // Popup Container
            VStack(spacing: 25) {
                Text(title)
                    .font(.custom("ChalkboardSE-Bold", size: 28))
                    .foregroundColor(.indigo)
                
                Text(message)
                    .font(.custom("ChalkboardSE-Bold", size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 20) {
                    Button(action: onCancel) {
                        Text(cancelText)
                            .font(.custom("ChalkboardSE-Bold", size: 20))
                            .frame(width: 140, height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray, lineWidth: 2)
                            )
                            .contentShape(Rectangle())
                    }
                    
                    Button(action: onExit) {
                        Text(exitText)
                            .font(.custom("ChalkboardSE-Bold", size: 20))
                            .frame(width: 140, height: 50)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .contentShape(Rectangle())
                    }
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 30)
            .background(Color("BackgroundColor"))
            .cornerRadius(25)
            .shadow(radius: 20)
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
