import UIKit
import SwiftUI
internal import SpriteKit

class GameViewController: UIViewController {
    
    // SwiftUI Hosting
    private var hudHostingController: UIHostingController<GameHUDView>?
    private var selectionHostingController: UIHostingController<LineSelectionView>?
    
    var onExitTapped: (() -> Void)?
    
    private var skView: SKView!
    private var gameScene: GameScene?
    private var dayProgress: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundColor")
        setupSKView()
        setupHUD() // This will now be an empty method, but called for consistency
        setupGestures()
    }
    
    private func setupGestures() {
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            gameScene?.setCameraZoom(1.0 / gesture.scale)
            gesture.scale = 1.0
        }
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
        selectionHostingController?.view.removeFromSuperview()
        selectionHostingController?.removeFromParent()
        
        HUDManager.shared.reset()
        
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .resizeFill
        self.gameScene = scene
        
        // Initial SwiftUI HUD
        let hudView = GameHUDView(
            onPause: { [weak self] in self?.handlePause() },
            onMenu: { [weak self] in self?.handleMenuTap() }
        )
        
        let hosting = UIHostingController(rootView: hudView)
        hosting.view.backgroundColor = .clear
        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.heightAnchor.constraint(equalToConstant: 110)
        ])
        hosting.didMove(toParent: self)
        self.hudHostingController = hosting
        
        // Initial Selection HUD
        let selectionHosting = UIHostingController(rootView: LineSelectionView(onColorSelected: { [weak self] color in
            self?.handleColorSelection(color)
        }))
        selectionHosting.view.backgroundColor = .clear
        addChild(selectionHosting)
        view.addSubview(selectionHosting.view)
        selectionHosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectionHosting.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            selectionHosting.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        selectionHosting.didMove(toParent: self)
        self.selectionHostingController = selectionHosting

        // Callbacks
        gameScene?.onMenuTapped = { [weak self] in
            self?.playSound(named: "sfx_click_cancel")
            self?.onExitTapped?()
        }
        
        gameScene?.onGameOver = { [weak self] finalScore, reason in
            self?.showGameOverOverlay(score: finalScore, reason: reason)
        }
        
        gameScene?.onScoreUpdate = { [weak self] _ in
            self?.updateHUD()
        }
        
        gameScene?.onTimeUpdate = { [weak self] _, _, progress in
            self?.dayProgress = progress
            self?.updateHUD()
        }
        
        CurrencyManager.shared.onThreadUpdate = { [weak self] _ in
            self?.updateHUD()
        }
        
        gameScene?.onTensionUpdate = { [weak self] _ in
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
        self.dayProgress = 0
        updateHUD()
        updateLineButtons(level: 1)
    }
    
    private func updateHUD() {
        guard let scene = gameScene else { return }
        
        DispatchQueue.main.async {
            let state = HUDState(
                stitches: scene.score,
                day: "Day \(DayCycleManager.shared.currentDay)",
                time: DayCycleManager.shared.currentTimeString,
                thread: CurrencyManager.shared.totalThread,
                tension: scene.tension,
                maxTension: scene.maxTension,
                level: scene.level,
                dayProgress: self.dayProgress,
                selectedColor: scene.currentLineColor
            )
            HUDManager.shared.update(with: state)
        }
    }
    
    private func handleColorSelection(_ color: UIColor) {
        playSound(named: "soft_click")
        gameScene?.currentLineColor = color
        updateHUD()
    }
    
    private func updateLineButtons(level: Int) {
        // Fallback to red if currently selected is locked
        if let scene = gameScene {
            if level < 5 && scene.currentLineColor == .systemPurple {
                handleColorSelection(.systemRed)
            } else if level < 4 && scene.currentLineColor == .systemOrange {
                handleColorSelection(.systemRed)
            } else if level < 3 && scene.currentLineColor == .systemGreen {
                handleColorSelection(.systemRed)
            } else if level < 2 && scene.currentLineColor == .systemBlue {
                handleColorSelection(.systemRed)
            } else {
                updateHUD()
            }
        }
    }
    
    private func setupHUD() {
        // Obsolete: Replaced by SwiftUI in presentNewScene
    }
    
    private func showGameOverOverlay(score: Int, reason: String) {
        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlay.alpha = 0
        view.addSubview(overlay)
        
        let titleLabel = UILabel()
        titleLabel.text = reason.uppercased()
        titleLabel.font = UIFont(name: "AvenirNext-Heavy", size: 36)
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        
        let finalScoreLabel = UILabel()
        finalScoreLabel.text = "Stitches: \(score)"
        finalScoreLabel.font = UIFont(name: "AvenirNext-Bold", size: 32)
        finalScoreLabel.textColor = .yellow
        finalScoreLabel.textAlignment = .center
        
        let replayBtn = UIButton(type: .system)
        replayBtn.setTitle("REPLAY", for: .normal)
        replayBtn.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 24)
        replayBtn.backgroundColor = .systemGreen
        replayBtn.setTitleColor(.white, for: .normal)
        replayBtn.layer.cornerRadius = 15
        replayBtn.addTarget(self, action: #selector(handleRestart), for: .touchUpInside)
        
        let menuBtn = UIButton(type: .system)
        menuBtn.setTitle("MENU", for: .normal)
        menuBtn.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 24)
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
