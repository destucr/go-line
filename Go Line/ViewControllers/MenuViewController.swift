import UIKit

class MenuViewController: UIViewController {
    
    var onPlayTapped: (() -> Void)?
    var onGuideTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "GO LINE"
        label.font = .systemFont(ofSize: 84, weight: .black)
        label.textColor = UIColor(red: 0.7, green: 0.72, blue: 0.75, alpha: 1.0)
        label.textAlignment = .center
        label.letterSpacing = 4.0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "NETWORK OPERATIONS INTERFACE v2.0"
        label.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        label.textColor = .systemOrange
        label.textAlignment = .center
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("INITIALIZE SHIFT", for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 20, weight: .black)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 2
        return button
    }()
    
    private let guideButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("OPERATIONS GUIDE", for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(UIColor(white: 0.7, alpha: 1.0), for: .normal)
        button.backgroundColor = UIColor(white: 0.15, alpha: 1.0)
        button.layer.borderColor = UIColor(white: 0.3, alpha: 1.0).cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 2
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.1, green: 0.11, blue: 0.12, alpha: 1.0)
        setupLayout()
    }
    
    private func setupLayout() {
        [titleLabel, subtitleLabel, playButton, guideButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            playButton.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 60),
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 280),
            playButton.heightAnchor.constraint(equalToConstant: 54),
            
            guideButton.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: 12),
            guideButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            guideButton.widthAnchor.constraint(equalToConstant: 280),
            guideButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        guideButton.addTarget(self, action: #selector(guideTapped), for: .touchUpInside)
    }
    
    @objc private func playTapped() {
        playSound(named: "soft_click")
        UIView.animate(withDuration: 0.05, animations: {
            self.playButton.alpha = 0.7
        }, completion: { _ in
            self.playButton.alpha = 1.0
            self.onPlayTapped?()
        })
    }
    
    @objc private func guideTapped() {
        playSound(named: "soft_click")
        self.onGuideTapped?()
    }
    
    private func playSound(named name: String) { }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}

extension UILabel {
    var letterSpacing: CGFloat {
        get {
            if let currentAttrString = attributedText {
                var range = NSRange(location: 0, length: currentAttrString.length)
                if let kern = currentAttrString.attribute(NSAttributedString.Key.kern, at: 0, effectiveRange: &range) as? CGFloat {
                    return kern
                }
            }
            return 0
        }
        set {
            let attributedString: NSMutableAttributedString
            if let currentAttrString = attributedText {
                attributedString = NSMutableAttributedString(attributedString: currentAttrString)
            } else {
                attributedString = NSMutableAttributedString(string: text ?? "")
            }
            attributedString.addAttribute(NSAttributedString.Key.kern, value: newValue, range: NSRange(location: 0, length: attributedString.length))
            attributedText = attributedString
        }
    }
}
