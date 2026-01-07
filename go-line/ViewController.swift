//
//  ViewController.swift
//  go-line
//
//  Created by Destu Cikal Ramdani on 1/7/26.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {
    
    private var skView: SKView!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSKView()
        showMenu()
    }
    
    private func setupSKView() {
        skView = SKView(frame: view.bounds)
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
        
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.topAnchor),
            skView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        // Debug options
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
    }
    
    // MARK: - Navigation
    
    func showMenu() {
        let menuScene = MenuScene(size: view.bounds.size)
        menuScene.scaleMode = .resizeFill
        
        // Navigation callbacks
        menuScene.onPlayButtonTapped = { [weak self] in
            self?.showGame()
        }
        menuScene.onGuideButtonTapped = { [weak self] in
            self?.showGuide()
        }
        
        present(scene: menuScene)
    }
    
    func showGame() {
        let gameScene = GameScene(size: view.bounds.size)
        gameScene.scaleMode = .resizeFill
        
        gameScene.onMenuTapped = { [weak self] in
            self?.showMenu()
        }
        
        present(scene: gameScene)
    }
    
    func showGuide() {
        let guideScene = GuideScene(size: view.bounds.size)
        guideScene.scaleMode = .resizeFill
        
        guideScene.onBackTapped = { [weak self] in
            self?.showMenu()
        }
        
        present(scene: guideScene)
    }
    
    private func present(scene: SKScene) {
        let transition = SKTransition.crossFade(withDuration: 0.3)
        skView.presentScene(scene, transition: transition)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeRight
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

