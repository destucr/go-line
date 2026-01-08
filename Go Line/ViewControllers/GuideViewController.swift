import UIKit

class GuideViewController: UIViewController {
    
    var onBackTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "FIELD MANUAL"
        label.font = .systemFont(ofSize: 48, weight: .black)
        label.textColor = MetroTheme.uiInkBlack
        label.textAlignment = .center
        label.letterSpacing = -2.0
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "OPERATIONAL PROTOCOLS // REV 4.0"
        label.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        label.textColor = MetroTheme.uiInkBlack
        label.alpha = 0.6
        label.textAlignment = .center
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()
    
    private let contentView: UIView = UIView()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("RETURN", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        button.setTitleColor(MetroTheme.uiInkBlack, for: .normal)
        button.backgroundColor = .white
        button.layer.borderWidth = 3
        button.layer.borderColor = MetroTheme.uiInkBlack.cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 4, height: 4)
        button.layer.shadowOpacity = 1.0
        button.layer.shadowRadius = 0
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = MetroTheme.uiBackground
        setupLayout()
    }
    
    private func setupLayout() {
        [titleLabel, subtitleLabel, scrollView, backButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 120),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        setupGuideContent()
        
        backButton.addTarget(self, action: #selector(handleBack), for: .touchUpInside)
    }
    
    private func setupGuideContent() {
        let instructions = [
            ("DEPLOYMENT", "Establish transit vectors by connecting station nodes."),
            ("AUTOMATION", "Trains deploy and navigate automatically along the network."),
            ("LOGISTICS", "Transport passengers to stations matching their geometric signature."),
            ("STRESS TEST", "Maintain network stability. Prevent hub overload at all costs."),
            ("EXPANSION", "Utilize thread resources to expand capacity and speed.")
        ]
        
        var lastAnchor = contentView.topAnchor
        
        for (header, body) in instructions {
            let container = UIView()
            container.backgroundColor = .white
            container.layer.borderWidth = 2
            container.layer.borderColor = MetroTheme.uiInkBlack.cgColor
            container.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(container)
            
            // Hard Shadow for cards
            container.layer.shadowColor = UIColor.black.cgColor
            container.layer.shadowOffset = CGSize(width: 4, height: 4)
            container.layer.shadowOpacity = 0.1
            container.layer.shadowRadius = 0
            
            let hLabel = UILabel()
            hLabel.text = header
            hLabel.font = .monospacedSystemFont(ofSize: 12, weight: .black)
            hLabel.textColor = .white
            hLabel.backgroundColor = MetroTheme.uiInkBlack
            hLabel.textAlignment = .center
            hLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(hLabel)
            
            let bLabel = UILabel()
            bLabel.text = body
            bLabel.font = .systemFont(ofSize: 16, weight: .bold)
            bLabel.numberOfLines = 0
            bLabel.textColor = MetroTheme.uiInkBlack
            bLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bLabel)
            
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: lastAnchor, constant: 24),
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 100),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -100),
                
                hLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: -10),
                hLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                hLabel.widthAnchor.constraint(equalToConstant: 120),
                hLabel.heightAnchor.constraint(equalToConstant: 24),
                
                bLabel.topAnchor.constraint(equalTo: hLabel.bottomAnchor, constant: 12),
                bLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                bLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                bLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
            ])
            
            lastAnchor = container.bottomAnchor
        }
        
        lastAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60).isActive = true
    }
    
    @objc private func handleBack() {
        SoundManager.shared.playSound("sfx_click_cancel")
        onBackTapped?()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
