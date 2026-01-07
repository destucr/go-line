import UIKit
import SwiftUI
internal import SpriteKit

// Custom Hosting Controller to allow touch pass-through
class PassThroughHostingController<Content: View>: UIHostingController<Content> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
    }
    
    override func loadView() {
        super.loadView()
        view = PassThroughView()
    }
}

class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        // If the view hit is the hosting view itself (and not a button inside it), return nil to pass through
        return view == self ? nil : view
    }
}

class GameViewController: UIViewController {
    
    // SwiftUI Hosting
    private var hudHostingController: PassThroughHostingController<GameHUDView>?
    
    var onExitTapped: (() -> Void)?
    
    private var skView: SKView!
    private var gameScene: GameScene?
    
    // HUD Elements
    private let lineSelectionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 15
        stack.distribution = .fillEqually
        return stack
    }()
    
    private let redButton = GameViewController.createLineButton(color: .systemRed, title: "RED")
    private let blueButton = GameViewController.createLineButton(color: .systemBlue, title: "BLUE")
    private let greenButton = GameViewController.createLineButton(color: .systemGreen, title: "GREEN")
    private let orangeButton = GameViewController.createLineButton(color: .systemOrange, title: "ORANGE")
    private let purpleButton = GameViewController.createLineButton(color: .systemPurple, title: "PURPLE")
    
    static func createLineButton(color: UIColor, title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.backgroundColor = color
        btn.layer.cornerRadius = 25
        btn.layer.borderWidth = 3
        btn.layer.borderColor = UIColor.white.cgColor
        btn.setTitle("", for: .normal) // Just color orb
        
        // Shadow
        btn.layer.shadowColor = color.cgColor
        btn.layer.shadowOffset = CGSize(width: 0, height: 4)
        btn.layer.shadowOpacity = 0.5
        btn.layer.shadowRadius = 4
        
        return btn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSKView()
        setupHUD() // This will now be an empty method, but called for consistency
        setupLineSelection()
    }
    
    private func setupSKView() {
        skView = SKView(frame: view.bounds)
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
        
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        presentNewScene()
    }
    
    private func presentNewScene() {
        // Remove old HUD if any
        hudHostingController?.view.removeFromSuperview()
        hudHostingController?.removeFromParent()
        
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        self.gameScene = scene
        
        // Initial SwiftUI HUD
        let hudView = GameHUDView(
            stitches: 0,
            day: "Day 1",
            time: "06:00",
            thread: 0,
            tension: 0,
            maxTension: 100,
            level: 1,
            onPause: { [weak self] in self?.handlePause() },
            onMenu: { [weak self] in self?.handleMenuTap() }
        )
        
        let hosting = PassThroughHostingController(rootView: hudView)
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.heightAnchor.constraint(equalToConstant: 140) // Slightly taller to accommodate content reliably
        ])
        hosting.didMove(toParent: self)
        self.hudHostingController = hosting

        // Callbacks
        gameScene?.onMenuTapped = { [weak self] in
            self?.playSound(named: "sfx_click_cancel")
            self?.onExitTapped?()
        }
        
        gameScene?.onGameOver = { [weak self] finalScore, reason in
            self?.showGameOverOverlay(score: finalScore, reason: reason)
        }
        
        gameScene?.onScoreUpdate = { [weak self] stitches in
            self?.updateHUD()
        }
        
        gameScene?.onTimeUpdate = { [weak self] day, time in
            self?.updateHUD()
        }
        
        CurrencyManager.shared.onThreadUpdate = { [weak self] amount in
            self?.updateHUD()
        }
        
        gameScene?.onTensionUpdate = { [weak self] tension in
            self?.updateHUD()
        }
        
        gameScene?.onDayComplete = { [weak self] day in
            DispatchQueue.main.async {
                self?.showShop(day: day)
            }
        }
        
        gameScene?.onLevelUpdate = { [weak self] level in
            DispatchQueue.main.async {
                self?.updateLineButtons(level: level)
                self?.updateHUD()
            }
        }
        
        skView.presentScene(gameScene)
        
        // Initial State
        updateLineButtons(level: 1)
    }
    
    private func updateHUD() {
        guard let scene = gameScene else { return }
        
        DispatchQueue.main.async {
            self.hudHostingController?.rootView = GameHUDView(
                stitches: scene.score,
                day: "Day \(DayCycleManager.shared.currentDay)",
                time: DayCycleManager.shared.currentTimeString, // Need to add this helper to manager or use custom logic
                thread: CurrencyManager.shared.totalThread,
                tension: scene.tension,
                maxTension: scene.maxTension,
                level: scene.level,
                onPause: { [weak self] in self?.handlePause() },
                onMenu: { [weak self] in self?.handleMenuTap() }
            )
        }
    }
    
    private func updateLineButtons(level: Int) {
        // Red always unlocked
        redButton.alpha = 1.0
        redButton.isEnabled = true
        
        // Blue unlocks at level 2
        blueButton.alpha = level >= 2 ? 1.0 : 0.3
        blueButton.isEnabled = level >= 2
        
        // Green unlocks at level 3
        greenButton.alpha = level >= 3 ? 1.0 : 0.3
        greenButton.isEnabled = level >= 3
        
        // Orange unlocks at level 4
        orangeButton.alpha = level >= 4 ? 1.0 : 0.3
        orangeButton.isEnabled = level >= 4
        
        // Purple unlocks at level 5
        purpleButton.alpha = level >= 5 ? 1.0 : 0.3
        purpleButton.isEnabled = level >= 5
        
        // Fallback to red if currently selected is locked
        if level < 5 && gameScene?.currentLineColor == .systemPurple { handleLineSelection(redButton) }
        else if level < 4 && gameScene?.currentLineColor == .systemOrange { handleLineSelection(redButton) }
        else if level < 3 && gameScene?.currentLineColor == .systemGreen { handleLineSelection(redButton) }
        else if level < 2 && gameScene?.currentLineColor == .systemBlue { handleLineSelection(redButton) }
    }
    
    private func setupHUD() {
        // Obsolete: Replaced by SwiftUI in presentNewScene
    }
    
    private func setupLineSelection() {
        [redButton, blueButton, greenButton, orangeButton, purpleButton].forEach {
            lineSelectionStack.addArrangedSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
            $0.widthAnchor.constraint(equalToConstant: 50).isActive = true
            $0.addTarget(self, action: #selector(handleLineSelection(_:)), for: .touchUpInside)
        }
        
        lineSelectionStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lineSelectionStack)
        
        NSLayoutConstraint.activate([
            lineSelectionStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lineSelectionStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    @objc private func handleLineSelection(_ sender: UIButton) {
        playSound(named: "soft_click")
        
        // Reset scale
        [redButton, blueButton, greenButton, orangeButton, purpleButton].forEach { btn in
            UIView.animate(withDuration: 0.2) { btn.transform = .identity }
        }
        
        // Highlight selected
        UIView.animate(withDuration: 0.2) {
            sender.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
        
        if sender == redButton { gameScene?.currentLineColor = .systemRed }
        if sender == blueButton { gameScene?.currentLineColor = .systemBlue }
        if sender == greenButton { gameScene?.currentLineColor = .systemGreen }
        if sender == orangeButton { gameScene?.currentLineColor = .systemOrange }
        if sender == purpleButton { gameScene?.currentLineColor = .systemPurple }
    }
    
    private func showGameOverOverlay(score: Int, reason: String) {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alpha = 0
        view.addSubview(overlay)
        
        let titleLabel = UILabel()
        titleLabel.text = reason.uppercased()
        titleLabel.font = UIFont(name: "ChalkboardSE-Bold", size: 36)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        let finalScoreLabel = UILabel()
        finalScoreLabel.text = "Stitches: \(score)"
        finalScoreLabel.font = UIFont(name: "ChalkboardSE-Bold", size: 32)
        finalScoreLabel.textColor = .yellow
        finalScoreLabel.textAlignment = .center
        
        let replayBtn = UIButton(type: .system)
        replayBtn.setTitle("REPLAY", for: .normal)
        replayBtn.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 24)
        replayBtn.backgroundColor = .systemGreen
        replayBtn.setTitleColor(.white, for: .normal)
        replayBtn.layer.cornerRadius = 15
        replayBtn.addTarget(self, action: #selector(handleRestart), for: .touchUpInside)
        
        let menuBtn = UIButton(type: .system)
        menuBtn.setTitle("MENU", for: .normal)
        menuBtn.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 24)
        menuBtn.backgroundColor = .white
        menuBtn.setTitleColor(.black, for: .normal)
        menuBtn.layer.cornerRadius = 15
        menuBtn.addTarget(self, action: #selector(handleMenu), for: .touchUpInside)
        
        [titleLabel, finalScoreLabel, replayBtn, menuBtn].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            overlay.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            titleLabel.centerYAnchor.constraint(equalTo: overlay.centerYAnchor, constant: -100),
            titleLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            
            finalScoreLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            finalScoreLabel.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            
            replayBtn.topAnchor.constraint(equalTo: finalScoreLabel.bottomAnchor, constant: 40),
            replayBtn.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            replayBtn.widthAnchor.constraint(equalToConstant: 180),
            replayBtn.heightAnchor.constraint(equalToConstant: 50),
            
            menuBtn.topAnchor.constraint(equalTo: replayBtn.bottomAnchor, constant: 20),
            menuBtn.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            menuBtn.widthAnchor.constraint(equalToConstant: 180),
            menuBtn.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        UIView.animate(withDuration: 0.5) {
            overlay.alpha = 1
        }
    }
    
    @objc private func handleRestart() {
        playSound(named: "soft_click")
        // Remove overlay and reset scene
        view.subviews.last?.removeFromSuperview()
        presentNewScene()
    }
    
    @objc private func handleMenu() {
        playSound(named: "sfx_click_cancel")
        onExitTapped?()
    }
    
    private func playSound(named name: String) {
        gameScene?.run(SKAction.playSoundFileNamed(name, waitForCompletion: false))
    }
    
    @objc private func handlePause() {
        gameScene?.isPaused.toggle()
        let isPaused = gameScene?.isPaused == true
        // The tint color update logic for the pause button is now handled within the SwiftUI HUD.
        // This method is called from the SwiftUI HUD.
        playSound(named: isPaused ? "sfx_click_cancel" : "soft_click")
    }
    
    @objc private func handleMenuTap() {
        playSound(named: "soft_click")
        
        let confirmView = ConfirmationPopupView(
            onCancel: { [weak self] in
                self?.dismiss(animated: true)
            },
            onExit: { [weak self] in
                self?.dismiss(animated: true) {
                    self?.onExitTapped?()
                }
            }
        )
        
        let hosting = UIHostingController(rootView: confirmView)
        hosting.modalPresentationStyle = .overFullScreen
        hosting.modalTransitionStyle = .crossDissolve
        hosting.view.backgroundColor = .clear
        present(hosting, animated: true)
    }
    
    private func showShop(day: Int) {
        let shopView = ShopView(day: day) { [weak self] in
            self?.gameScene?.advanceDay()
            self?.dismiss(animated: true)
        }
        let hosting = UIHostingController(rootView: shopView)
        hosting.modalPresentationStyle = .fullScreen
        present(hosting, animated: true)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
