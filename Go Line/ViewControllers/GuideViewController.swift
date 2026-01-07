import UIKit

class GuideViewController: UIViewController {
    
    var onBackTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "OPERATIONS MANUAL"
        label.font = .systemFont(ofSize: 32, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "GO-LINE NETWORK PROTOCOLS"
        label.font = .monospacedSystemFont(ofSize: 12, weight: .bold)
        label.textColor = .systemOrange
        label.textAlignment = .center
        return label
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = true
        return sv
    }()
    
    private let contentView: UIView = UIView()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("RETURN TO INTERFACE", for: .normal)
        button.titleLabel?.font = .monospacedSystemFont(ofSize: 14, weight: .bold)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .systemOrange
        button.layer.cornerRadius = 2
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.1, green: 0.11, blue: 0.12, alpha: 1.0)
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
            backButton.widthAnchor.constraint(equalToConstant: 220),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
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
            ("DEPLOYMENT", "Drag between nodes to establish a transit vector."),
            ("AUTOMATION", "Needle-trains deploy automatically along established paths."),
            ("LOGISTICS", "Extract passengers and deliver to matching geometric hubs."),
            ("STRESS TEST", "Maintain network tension. Do not allow hub overload."),
            ("EXPANSION", "Acquire thread resources to reinforce and expand the grid.")
        ]
        
        var lastAnchor = contentView.topAnchor
        
        for (header, body) in instructions {
            let container = UIView()
            container.backgroundColor = UIColor(white: 1.0, alpha: 0.03)
            container.layer.cornerRadius = 4
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor(white: 1.0, alpha: 0.1).cgColor
            container.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(container)
            
            let hLabel = UILabel()
            hLabel.text = header
            hLabel.font = .monospacedSystemFont(ofSize: 14, weight: .black)
            hLabel.textColor = .systemOrange
            hLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(hLabel)
            
            let bLabel = UILabel()
            bLabel.text = body
            bLabel.font = .systemFont(ofSize: 16, weight: .medium)
            bLabel.numberOfLines = 0
            bLabel.textColor = .lightGray
            bLabel.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bLabel)
            
            NSLayoutConstraint.activate([
                container.topAnchor.constraint(equalTo: lastAnchor, constant: 20),
                container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 60),
                container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -60),
                
                hLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
                hLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                
                bLabel.topAnchor.constraint(equalTo: hLabel.bottomAnchor, constant: 4),
                bLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
                bLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
                bLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
            ])
            
            lastAnchor = container.bottomAnchor
        }
        
        lastAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -60).isActive = true
    }
    
    @objc private func handleBack() {
        onBackTapped?()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
