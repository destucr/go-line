import UIKit

class MenuViewController: UIViewController {
    
    var onPlayTapped: (() -> Void)?
    var onGuideTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Go Line"
        label.font = UIFont(name: "ChalkboardSE-Bold", size: 72)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Stitch the City Together"
        label.font = UIFont(name: "ChalkboardSE-Regular", size: 24)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("PLAY", for: .normal)
        button.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 32)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 15
        return button
    }()
    
    private let guideButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GUIDE", for: .normal)
        button.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 24)
        button.setTitleColor(.darkGray, for: .normal)
        button.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        button.layer.cornerRadius = 15
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupLayout()
        setupAnimations()
    }
    
    private func setupLayout() {
        [titleLabel, subtitleLabel, playButton, guideButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            playButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 200),
            playButton.heightAnchor.constraint(equalToConstant: 60),
            
            guideButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 20),
            guideButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideButton.widthAnchor.constraint(equalToConstant: 160),
            guideButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        guideButton.addTarget(self, action: #selector(guideTapped), for: .touchUpInside)
    }
    
    private func setupAnimations() {
        titleLabel.alpha = 0
        titleLabel.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        playButton.alpha = 0
        playButton.transform = CGAffineTransform(translationX: 0, y: 50)
        
        guideButton.alpha = 0
        guideButton.transform = CGAffineTransform(translationX: 0, y: 50)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.titleLabel.alpha = 1
            self.titleLabel.transform = .identity
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.5, options: .curveEaseOut) {
            self.playButton.alpha = 1
            self.playButton.transform = .identity
        }
        
        UIView.animate(withDuration: 0.6, delay: 0.7, options: .curveEaseOut) {
            self.guideButton.alpha = 1
            self.guideButton.transform = .identity
        }
    }
    
    @objc private func playTapped() {
        playSound(named: "soft_click")
        UIView.animate(withDuration: 0.1, animations: {
            self.playButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.playButton.transform = .identity
            }
            self.onPlayTapped?()
        }
    }
    
    @objc private func guideTapped() {
        playSound(named: "soft_click")
        self.onGuideTapped?()
    }
    
    private func playSound(named name: String) {
        // Internal sound helper for UI feedback if needed
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
