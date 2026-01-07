//
//  ViewController.swift
//  go-line
//
//  Created by Destu Cikal Ramdani on 1/7/26.
//

import UIKit
internal import SpriteKit

class ViewController: UIViewController {
    
    private var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if currentViewController == nil && view.bounds.width > 0 {
            showMenu()
        }
    }
    
    func showMenu() {
        let menuVC = MenuViewController()
        menuVC.onPlayTapped = { [weak self] in self?.showGame() }
        menuVC.onGuideTapped = { [weak self] in self?.showGuide() }
        transition(to: menuVC)
    }
    
    func showGame() {
        let gameVC = GameViewController()
        gameVC.onExitTapped = { [weak self] in self?.showMenu() }
        transition(to: gameVC)
    }
    
    func showGuide() {
        let guideVC = GuideViewController()
        guideVC.onBackTapped = { [weak self] in self?.showMenu() }
        transition(to: guideVC)
    }
    
    private func transition(to nextVC: UIViewController) {
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        addChild(nextVC)
        nextVC.view.frame = view.bounds
        nextVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(nextVC.view)
        nextVC.didMove(toParent: self)
        
        currentViewController = nextVC
        
        // Simple fade transition
        nextVC.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            nextVC.view.alpha = 1
        }
    }

    override var shouldAutorotate: Bool { return false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .landscapeRight }
    override var prefersStatusBarHidden: Bool { return true }
    override var prefersHomeIndicatorAutoHidden: Bool { return true }
}

