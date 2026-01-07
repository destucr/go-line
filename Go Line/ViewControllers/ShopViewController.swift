import UIKit

class ShopViewController: UIViewController {
    
    var onNextDay: (() -> Void)?
    var day: Int = 1
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "SHIFT COMPLETE"
        l.font = UIFont(name: "ChalkboardSE-Bold", size: 32)
        l.textColor = .white
        l.textAlignment = .center
        return l
    }()
    
    private let threadLabel: UILabel = {
        let l = UILabel()
        l.text = "THREAD: 0"
        l.font = UIFont(name: "ChalkboardSE-Bold", size: 24)
        l.textColor = .systemOrange
        l.textAlignment = .center
        return l
    }()
    
    private let stackView: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 20
        s.distribution = .fillEqually
        return s
    }()
    
    private var upgradeButtons: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        
        setupUI()
        refreshUpgrades()
    }
    
    func setupUI() {
        view.addSubview(titleLabel)
        view.addSubview(threadLabel)
        view.addSubview(stackView)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        threadLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            threadLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            threadLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stackView.topAnchor.constraint(equalTo: threadLabel.bottomAnchor, constant: 40),
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.widthAnchor.constraint(equalToConstant: 400)
        ])
        
        createUpgradeButtons()
        
        // Next Day Button
        let nextBtn = UIButton(type: .system)
        nextBtn.setTitle("START DAY \(day + 1)", for: .normal)
        nextBtn.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 28)
        nextBtn.backgroundColor = .systemGreen
        nextBtn.setTitleColor(.white, for: .normal)
        nextBtn.layer.cornerRadius = 10
        nextBtn.addTarget(self, action: #selector(handleNextDay), for: .touchUpInside)
        
        view.addSubview(nextBtn)
        nextBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nextBtn.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            nextBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nextBtn.widthAnchor.constraint(equalToConstant: 250),
            nextBtn.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    private func createUpgradeButtons() {
        upgradeButtons.removeAll()
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Carriage
        let carriageBtn = createButton(title: "New Carriage", type: .carriage)
        upgradeButtons.append(carriageBtn)
        stackView.addArrangedSubview(carriageBtn)
        
        // Speed
        let speedBtn = createButton(title: "Faster Needle", type: .speed)
        upgradeButtons.append(speedBtn)
        stackView.addArrangedSubview(speedBtn)
        
        // Strength
        let strengthBtn = createButton(title: "Fabric Strength", type: .strength)
        upgradeButtons.append(strengthBtn)
        stackView.addArrangedSubview(strengthBtn)
    }
    
    enum UpgradeType { case carriage, speed, strength }
    
    private func createButton(title: String, type: UpgradeType) -> UIButton {
        let btn = UIButton(type: .system)
        btn.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 20)
        btn.backgroundColor = .systemGray
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 8
        btn.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Determine action and tag
        switch type {
        case .carriage:
            btn.tag = 0
        case .speed:
            btn.tag = 1
        case .strength:
            btn.tag = 2
        }
        
        btn.addTarget(self, action: #selector(handleUpgradePurchase(_:)), for: .touchUpInside)
        return btn
    }
    
    @objc private func handleUpgradePurchase(_ sender: UIButton) {
        var success = false
        switch sender.tag {
        case 0: success = UpgradeManager.shared.buyCarriage()
        case 1: success = UpgradeManager.shared.buySpeed()
        case 2: success = UpgradeManager.shared.buyStrength()
        default: break
        }
        
        if success {
            playSound("sfx_score")
            refreshUpgrades()
            
            // Subtle animation
            UIView.animate(withDuration: 0.1, animations: {
                sender.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            }, completion: { _ in
                UIView.animate(withDuration: 0.1) {
                    sender.transform = .identity
                }
            })
        } else {
            playSound("sfx_click_cancel")
            // Shake animation
            let animation = CAKeyframeAnimation(keyPath: "position.x")
            animation.values = [0, 10, -10, 10, 0]
            animation.keyTimes = [0, 0.16, 0.5, 0.83, 1]
            animation.duration = 0.4
            animation.isAdditive = true
            sender.layer.add(animation, forKey: "shake")
        }
    }
    
    func refreshUpgrades() {
        updateThreadDisplay()
        
        let total = CurrencyManager.shared.totalThread
        
        for btn in upgradeButtons {
            var cost = 0
            var title = ""
            var level = 0
            
            switch btn.tag {
            case 0:
                cost = UpgradeManager.shared.getCarriageCost()
                title = "New Carriage (+6 Cap)"
                level = UpgradeManager.shared.carriageCount
            case 1:
                cost = UpgradeManager.shared.getSpeedCost()
                title = "Faster Needle (+15% Spd)"
                level = UpgradeManager.shared.speedLevel
            case 2:
                cost = UpgradeManager.shared.getStrengthCost()
                title = "Fabric Strength (+25 HP)"
                level = UpgradeManager.shared.strengthLevel
            default: break
            }
            
            btn.setTitle("\(title)\nLvl \(level) - Cost: \(cost)", for: .normal)
            btn.titleLabel?.numberOfLines = 0
            btn.titleLabel?.textAlignment = .center
            
            let affordable = total >= cost
            btn.isEnabled = true // Always allow click to show "insufficient funds" shake?
            btn.alpha = affordable ? 1.0 : 0.5
            btn.backgroundColor = affordable ? .systemBlue : .darkGray
        }
    }
    
    func updateThreadDisplay() {
        threadLabel.text = "THREAD: \(CurrencyManager.shared.totalThread)"
    }
    
    func playSound(_ name: String) {
        print("Play Sound: \(name)")
    }
    
    @objc func handleNextDay() {
        onNextDay?()
        dismiss(animated: true, completion: nil)
    }
}
