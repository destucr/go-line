import UIKit

class GuideViewController: UIViewController {
    
    var onBackTapped: (() -> Void)?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "How to Stitch"
        label.font = UIFont(name: "ChalkboardSE-Bold", size: 48)
        label.textColor = .black
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
        button.setTitle("Back", for: .normal)
        button.titleLabel?.font = UIFont(name: "ChalkboardSE-Bold", size: 20)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 10
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundColor")
        setupLayout()
    }
    
    private func setupLayout() {
        [titleLabel, scrollView, backButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        scrollView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 100),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
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
            "1. Drag between stations to create a transit line.",
            "2. Trains will automatically follow the line.",
            "3. Collect passengers and deliver them to matching shapes.",
            "4. Don't let stations get too overcrowded!",
            "5. Use different colored threads to build your network."
        ]
        
        var lastAnchor = contentView.topAnchor
        
        for text in instructions {
            let label = UILabel()
            label.text = text
            label.font = UIFont(name: "ChalkboardSE-Regular", size: 20)
            label.numberOfLines = 0
            label.textColor = .darkGray
            label.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: lastAnchor, constant: 30),
                label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
                label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40)
            ])
            
            lastAnchor = label.bottomAnchor
        }
        
        lastAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40).isActive = true
    }
    
    @objc private func handleBack() {
        onBackTapped?()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }
}
