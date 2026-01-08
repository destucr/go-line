import SwiftUI

struct ConfirmationPopupView: View {
    var title: String = "SERVICE ALERT"
    var message: String = "TERMINATING SHIFT WILL RESULT IN DATA LOSS.\nCONFIRM ACTION?"
    var cancelText: String = "RESUME"
    var exitText: String = "TERMINATE"
    
    var onCancel: () -> Void
    var onExit: () -> Void
    
    var body: some View {
        ZStack {
            // Darkened Background
            Color.black.opacity(0.85)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    onCancel()
                }
            
            // Alert Box
            VStack(spacing: 0) {
                // Header Strip
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.black)
                    Text(title)
                        .font(MetroTheme.titleFont(size: 20))
                        .foregroundColor(.black)
                    Spacer()
                }
                .padding()
                .background(MetroTheme.safetyYellow)
                
                // Content
                VStack(spacing: 30) {
                    Text(message)
                        .font(MetroTheme.dataFont(size: 14))
                        .foregroundColor(MetroTheme.inkBlack)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                    
                    // Actions
                    HStack(spacing: 16) {
                        Button(action: {
                            SoundManager.shared.playSound("sfx_click_cancel")
                            onCancel()
                        }, label: {
                            Text(cancelText)
                                .font(MetroTheme.signageFont(size: 16))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color.white)
                                .foregroundColor(MetroTheme.inkBlack)
                                .border(MetroTheme.inkBlack, width: 3)
                        })
                        
                        Button(action: {
                            SoundManager.shared.playSound("soft_click")
                            onExit()
                        }, label: {
                            Text(exitText)
                                .font(MetroTheme.signageFont(size: 16))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(MetroTheme.alertRed)
                                .foregroundColor(.white)
                                .border(MetroTheme.inkBlack, width: 3)
                        })
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .background(Color.white)
            }
            .frame(maxWidth: 480)
            .border(Color.black, width: 3) // Unified border
            .compositingGroup() // Fixes shadow rendering artifact
            .shadow(color: .black.opacity(1.0), radius: 0, x: 8, y: 8) // Hard, solid shadow
            .padding(.horizontal, 20)
        }
    }
}

struct ConfirmationPopupView_Previews: PreviewProvider {
    static var previews: some View {
        ConfirmationPopupView(onCancel: {}, onExit: {})
            .previewLayout(.sizeThatFits)
    }
}
