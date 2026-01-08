import UIKit

class MenuViewController: UIViewController {
    
    var onPlayTapped: (() -> Void)?
    var onGuideTapped: (() -> Void)?
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "GO LINE"
        label.font = .systemFont(ofSize: 100, weight: .black)
        label.textColor = MetroTheme.uiInkBlack
        label.textAlignment = .center
        label.letterSpacing = -4.0
        // Dynamic font sizing for smaller screens
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "TRANSIT NETWORK SIMULATOR"
        label.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        label.textColor = MetroTheme.uiInkBlack
        label.alpha = 0.6
        label.textAlignment = .center
        label.letterSpacing = 1.0
        return label
    }()
    
    private let playButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("PLAY", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 32, weight: .heavy)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = MetroTheme.uiSafetyYellow
        
        button.layer.cornerRadius = 0
        button.layer.borderWidth = 4
        button.layer.borderColor = MetroTheme.uiInkBlack.cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 6, height: 6)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    
    private let guideButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("GUIDE", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(MetroTheme.uiInkBlack, for: .normal)
        button.backgroundColor = .white
        
        button.layer.cornerRadius = 0
        button.layer.borderWidth = 3
        button.layer.borderColor = MetroTheme.uiInkBlack.cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 4, height: 4)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    
    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        stack.distribution = .fill
        return stack
    }()
    
    // Background
    private let backgroundContainer = UIView()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MetroTheme.uiBackground
        setupBackground()
        setupLayout()
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        // Build Stack
        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(subtitleLabel)
        
        // Custom spacing after subtitle
        mainStackView.setCustomSpacing(60, after: subtitleLabel)
        
        mainStackView.addArrangedSubview(playButton)
        mainStackView.addArrangedSubview(guideButton)
        
        view.addSubview(mainStackView)
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Center Stack in Safe Area
            mainStackView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            mainStackView.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            
            // Constrain edges to ensure visibility on small screens
            mainStackView.topAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStackView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Responsive Button Widths
            playButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.4),
            playButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 300), // Min width
            playButton.widthAnchor.constraint(lessThanOrEqualToConstant: 500),  // Max width
            playButton.heightAnchor.constraint(equalToConstant: 72),
            
            guideButton.widthAnchor.constraint(equalTo: playButton.widthAnchor),
            guideButton.heightAnchor.constraint(equalToConstant: 54)
        ])
        
        playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)
        guideButton.addTarget(self, action: #selector(guideTapped), for: .touchUpInside)
    }
    
    // MARK: - Background Animation
    
    private func setupBackground() {
        backgroundContainer.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(backgroundContainer, at: 0)
        
        NSLayoutConstraint.activate([
            backgroundContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            backgroundContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        drawGrid()
        
        // Line 1: Yellow Main Line
        drawAnimatedLine(
            start: CGPoint(x: -100, y: 600),
            end: CGPoint(x: 1_200, y: 200),
            control1: CGPoint(x: 400, y: 600),
            control2: CGPoint(x: 600, y: 200),
            color: MetroTheme.uiSafetyYellow,
            lineWidth: 8
        )
        
        // Line 2: Blue Secondary Line (Lower)
        drawAnimatedLine(
            start: CGPoint(x: -100, y: 300),
            end: CGPoint(x: 1_200, y: 700),
            control1: CGPoint(x: 300, y: 300),
            control2: CGPoint(x: 800, y: 700),
            color: UIColor(red: 0.0, green: 0.35, blue: 0.85, alpha: 0.3),
            lineWidth: 4
        )
    }
    
    private func drawGrid() {
        let gridLayer = CAShapeLayer()
        gridLayer.strokeColor = MetroTheme.uiInkBlack.withAlphaComponent(0.05).cgColor
        gridLayer.lineWidth = 1
        
        let path = UIBezierPath()
        let gridSize: CGFloat = 40
        
        // Oversized grid to cover rotation/movement if needed
        for x in stride(from: 0, to: 2_000, by: gridSize) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: 1_200))
        }
        for y in stride(from: 0, to: 1_200, by: gridSize) {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: 2_000, y: y))
        }
        
        gridLayer.path = path.cgPath
        backgroundContainer.layer.addSublayer(gridLayer)
    }
    
    private func drawAnimatedLine(start: CGPoint, end: CGPoint, control1: CGPoint, control2: CGPoint, color: UIColor, lineWidth: CGFloat) {
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addCurve(to: end, controlPoint1: control1, controlPoint2: control2)
        
        // 1. The Track (Dashed Flow)
        let trackLayer = CAShapeLayer()
        trackLayer.path = linePath.cgPath
        trackLayer.strokeColor = color.withAlphaComponent(0.6).cgColor
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.lineWidth = lineWidth
        trackLayer.lineCap = .round
        trackLayer.lineDashPattern = [16, 12] // Dash pattern
        
        backgroundContainer.layer.addSublayer(trackLayer)
        
        // Animate Dash Phase (Flowing Traffic)
        let phaseAnim = CABasicAnimation(keyPath: "lineDashPhase")
        phaseAnim.fromValue = 0
        phaseAnim.toValue = -28 // Sum of dash pattern (16+12)
        phaseAnim.duration = 1.0
        phaseAnim.repeatCount = .infinity
        phaseAnim.isRemovedOnCompletion = false
        trackLayer.add(phaseAnim, forKey: "flow")
        
        // 2. The Train (Moving Node)
        let trainLayer = CALayer()
        let trainSize = lineWidth * 2.5
        trainLayer.bounds = CGRect(x: 0, y: 0, width: trainSize, height: trainSize)
        trainLayer.cornerRadius = trainSize / 2
        trainLayer.backgroundColor = color.cgColor
        trainLayer.borderWidth = 2
        trainLayer.borderColor = UIColor.white.cgColor
        
        // Shadow for train
        trainLayer.shadowColor = UIColor.black.cgColor
        trainLayer.shadowOpacity = 0.3
        trainLayer.shadowOffset = CGSize(width: 2, height: 2)
        trainLayer.shadowRadius = 2
        
        backgroundContainer.layer.addSublayer(trainLayer)
        
        // Animate Position along Path
        let positionAnim = CAKeyframeAnimation(keyPath: "position")
        positionAnim.path = linePath.cgPath
        positionAnim.duration = Double.random(in: 6...10) // Varied speed
        positionAnim.repeatCount = .infinity
        positionAnim.calculationMode = .paced
        positionAnim.isRemovedOnCompletion = false
        trainLayer.add(positionAnim, forKey: "travel")
        
        // Station Nodes (Static)
        // Add a node at roughly t=0.3 and t=0.7 along curve
        // Approximate for visual flair
        let tValues = [0.3, 0.7]
        for t in tValues {
            let node = CAShapeLayer()
            let r: CGFloat = lineWidth * 1.5
            // Bezier cubic interpolation for point
            let x = pow(1 - t, 3) * start.x + 3 * pow(1 - t, 2) * t * control1.x + 3 * (1 - t) * pow(t, 2) * control2.x + pow(t, 3) * end.x
            let y = pow(1 - t, 3) * start.y + 3 * pow(1 - t, 2) * t * control1.y + 3 * (1 - t) * pow(t, 2) * control2.y + pow(t, 3) * end.y
            
            node.path = UIBezierPath(ovalIn: CGRect(x: -r, y: -r, width: r * 2, height: r * 2)).cgPath
            node.fillColor = MetroTheme.uiBackground.cgColor
            node.strokeColor = MetroTheme.uiInkBlack.cgColor
            node.lineWidth = 2
            node.position = CGPoint(x: x, y: y)
            backgroundContainer.layer.addSublayer(node)
        }
    }
    
    // MARK: - Actions
    
    @objc private func playTapped() {
        SoundManager.shared.playSound("soft_click")
        // Tactile press effect
        UIView.animate(withDuration: 0.1, animations: {
            self.playButton.transform = CGAffineTransform(translationX: 3, y: 3)
            self.playButton.layer.shadowOffset = CGSize(width: 3, height: 3)
        }, completion: { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.playButton.transform = .identity
                self.playButton.layer.shadowOffset = CGSize(width: 6, height: 6)
            }, completion: { _ in
                self.onPlayTapped?()
            })
        })
    }
    
    @objc private func guideTapped() {
        SoundManager.shared.playSound("soft_click")
        self.onGuideTapped?()
    }
    
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
