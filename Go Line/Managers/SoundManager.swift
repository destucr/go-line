import AVFoundation
internal import SpriteKit

class SoundManager {
    static let shared = SoundManager()
    
    private var players: [String: AVAudioPlayer] = [:]
    
    private init() {}

    func playSound(_ name: String) {
        // Handle different extensions
        let fileName: String
        let fileExtension: String?
        
        if name.contains(".") {
            let parts = name.split(separator: ".")
            fileName = String(parts[0])
            fileExtension = String(parts[1])
        } else {
            fileName = name
            fileExtension = nil
        }
        
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            // Try with common extensions if none provided
            let extensions = ["wav", "mp3", "m4a"]
            for ext in extensions {
                if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                    playFromUrl(url, key: name)
                    return
                }
            }
            print("Sound file \(name) not found")
            return
        }
        
        playFromUrl(url, key: name)
    }
    
    private func playFromUrl(_ url: URL, key: String) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
            players[key] = player
        } catch {
            print("Could not play sound \(key): \(error)")
        }
    }
}
