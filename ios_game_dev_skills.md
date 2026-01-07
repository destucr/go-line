# iOS UIKit Game Development

Use this skill when working on iOS games using UIKit framework, especially for landscape orientation games with custom UI, animations, touch interactions, and performance-critical rendering.

## When to Apply

- Building iOS games without game engines (native UIKit/SpriteKit)
- Implementing custom game UI, HUD, menus, or controls
- Creating touch-based interactions (gestures, line drawing, drag-drop)
- Optimizing game performance (60fps target, memory management)
- Designing landscape-oriented game layouts
- Integrating SpriteKit with UIKit navigation

## Instructions

### 1. Project Structure

```
GameProject/
├── ViewControllers/
│   ├── MenuViewController.swift
│   ├── GameViewController.swift
│   └── PauseViewController.swift
├── Views/
│   ├── GameView.swift (custom rendering)
│   ├── HUDView.swift (score, stats)
│   └── ControlsView.swift (buttons)
├── Models/
│   ├── GameState.swift
│   └── Entities/ (trains, stations)
├── Managers/
│   ├── GameCoordinator.swift
│   └── AudioManager.swift
└── Resources/
    ├── Assets.xcassets
    └── Sounds/
```

**Convention**: Separate game logic (Models), rendering (Views), and flow (ViewControllers)

### 2. Landscape Layout Configuration

Always configure landscape orientation in `Info.plist` and enforce in ViewControllers.

**Info.plist Configuration**:
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
<key>UISupportedInterfaceOrientations~ipad</key>
<array>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>
```

**ViewController Enforcement**:
```swift
override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
    return .landscape
}

override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
    return .landscapeRight
}
```

**Safe Area Handling**:
```swift
// Respect notch/home indicator on iPhone
view.addSubview(hudView)
hudView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true
hudView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
```

### 3. Custom Game View Pattern

For high-performance custom rendering:

```swift
class GameView: UIView {
    var gameObjects: [GameObject] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.contentMode = .redraw
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Draw game elements
        context.setFillColor(UIColor.systemBlue.cgColor)
        for obj in gameObjects {
            context.fill(obj.frame)
        }
    }
    
    // Trigger redraw
    func updateGame() {
        setNeedsDisplay()
    }
}
```

**Key Points**:
- Call `setNeedsDisplay()` only when visuals change (not every frame)
- Use `CADisplayLink` for smooth 60fps updates
- Set `layer.drawsAsynchronously = true` for GPU offloading

### 4. Touch and Gesture Handling

**Single Touch (Line Drawing)**:
```swift
override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    startPoint = location
}

override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    currentPath.addLine(to: location)
    setNeedsDisplay()
}
```

**Gesture Recognizers (Pinch, Pan)**:
```swift
let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))

// Allow simultaneous gestures
func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, 
                       shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
    return true
}

@objc func handlePan(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: gameView)
    
    switch gesture.state {
    case .began, .changed:
        cameraOffset.x += translation.x
        cameraOffset.y += translation.y
        gesture.setTranslation(.zero, in: gameView)
    case .ended:
        applyInertia(velocity: gesture.velocity(in: gameView))
    default: break
    }
}
```

**Hit Testing**:
```swift
func objectAt(point: CGPoint) -> GameObject? {
    return gameObjects.first { $0.frame.contains(point) }
}
```

### 5. Animation Patterns

**UIView Spring Animation** (button feedback):
```swift
UIView.animate(withDuration: 0.3, 
               delay: 0,
               usingSpringWithDamping: 0.6,
               initialSpringVelocity: 0.5,
               options: .curveEaseOut) {
    button.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
} completion: { _ in
    UIView.animate(withDuration: 0.2) {
        button.transform = .identity
    }
}
```

**CADisplayLink Game Loop**:
```swift
private var displayLink: CADisplayLink?
private var lastFrameTime: TimeInterval = 0

func startGameLoop() {
    displayLink = CADisplayLink(target: self, selector: #selector(gameLoop))
    displayLink?.add(to: .main, forMode: .common)
}

@objc func gameLoop(_ displayLink: CADisplayLink) {
    let deltaTime = displayLink.timestamp - lastFrameTime
    lastFrameTime = displayLink.timestamp
    
    // Update game state (max 60fps)
    updateGameState(delta: deltaTime)
    gameView.setNeedsDisplay()
}

func stopGameLoop() {
    displayLink?.invalidate()
    displayLink = nil
}
```

**CALayer Animation** (continuous effects):
```swift
let pulse = CABasicAnimation(keyPath: "transform.scale")
pulse.fromValue = 1.0
pulse.toValue = 1.3
pulse.duration = 0.8
pulse.autoreverses = true
pulse.repeatCount = .infinity
stationView.layer.add(pulse, forKey: "pulse")
```

### 6. HUD and UI Layout

**Typical Game Layout**:
```
Landscape View (Safe Area Aware):
┌──────────────────────────────────────────┐
│ [Score: 1234] [⚙️] [❚❚]  [Top: 16pt]    │
├──────────────────────────────────────────┤
│                                          │
│          [Game Canvas]                   │
│         (Flexible Fill)                  │
│                                          │
├──────────────────────────────────────────┤
│  [⊕ Line] [🚊 Train] [📊]  [Bottom Safe]│
└──────────────────────────────────────────┘
```

**Implementation**:
```swift
// HUD Container
let hudStack = UIStackView()
hudStack.axis = .horizontal
hudStack.distribution = .equalSpacing
hudStack.translatesAutoresizingMaskIntoConstraints = false
view.addSubview(hudStack)

NSLayoutConstraint.activate([
    hudStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
    hudStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
    hudStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),
    hudStack.heightAnchor.constraint(equalToConstant: 44)
])

// Button styling
func styleGameButton(_ button: UIButton) {
    button.layer.cornerRadius = 12
    button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
    button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 20, bottom: 12, right: 20)
    
    // Shadow
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOffset = CGSize(width: 0, height: 2)
    button.layer.shadowRadius = 4
    button.layer.shadowOpacity = 0.3
}
```

### 7. SpriteKit Integration

When game objects need physics or complex animations:

```swift
class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let skView = SKView(frame: view.bounds)
        skView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skView)
        
        // Pin to safe area
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            skView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            skView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let scene = GameScene(size: skView.bounds.size)
        scene.scaleMode = .aspectFill
        skView.presentScene(scene)
        
        // Debug (remove in production)
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
}
```

**Train Movement Example**:
```swift
class GameScene: SKScene {
    func moveTrainAlongPath(train: SKSpriteNode, path: CGPath) {
        let follow = SKAction.follow(path, asOffset: false, orientToPath: true, speed: 100)
        let complete = SKAction.run { [weak self] in
            self?.trainArrived(train)
        }
        train.run(SKAction.sequence([follow, complete]))
    }
}
```

### 8. Performance Optimization

**Target Metrics**:
- 60fps on iPhone 11+ (check Instruments)
- <150MB memory usage
- <50% CPU per core
- <70% GPU utilization

**Object Pooling**:
```swift
class ObjectPool<T> {
    private var pool: [T] = []
    private let factory: () -> T
    
    init(initialCapacity: Int = 10, factory: @escaping () -> T) {
        self.factory = factory
        pool.reserveCapacity(initialCapacity)
    }
    
    func acquire() -> T {
        return pool.isEmpty ? factory() : pool.removeLast()
    }
    
    func release(_ object: T) {
        pool.append(object)
    }
}

// Usage
let trainPool = ObjectPool<TrainView>(initialCapacity: 20) { TrainView() }
let train = trainPool.acquire()
// ... use train ...
trainPool.release(train)
```

**Texture Caching**:
```swift
enum ImageCache {
    private static var cache: [String: UIImage] = [:]
    
    static func image(named name: String) -> UIImage? {
        if let cached = cache[name] {
            return cached
        }
        guard let image = UIImage(named: name) else { return nil }
        cache[name] = image
        return image
    }
}
```

**Layer Optimization**:
```swift
// For static complex views
view.layer.shouldRasterize = true
view.layer.rasterizationScale = UIScreen.main.scale

// For animated content
view.layer.drawsAsynchronously = true

// Reduce transparency
view.isOpaque = true
view.backgroundColor = .white // Not .clear
```

### 9. Haptic Feedback

Add tactile feedback for better game feel:

```swift
class HapticManager {
    static let shared = HapticManager()
    
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    
    func prepare() {
        light.prepare()
        medium.prepare()
    }
    
    func buttonTap() {
        light.impactOccurred()
    }
    
    func trainArrival() {
        medium.impactOccurred()
    }
    
    func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }
}

// Usage
@objc func handleButtonTap() {
    HapticManager.shared.buttonTap()
    // ... button action
}
```

### 10. Dark Mode Support

Always support both appearances:

```swift
// Dynamic colors
let backgroundColor = UIColor { traits in
    traits.userInterfaceStyle == .dark 
        ? UIColor(white: 0.1, alpha: 1.0)
        : UIColor(white: 0.95, alpha: 1.0)
}

// Asset catalogs: Provide "Any, Dark" variants
// Use semantic colors: .label, .systemBackground, .secondaryLabel

// Respond to changes
override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
        updateColorsForCurrentTheme()
    }
}
```

### 11. SF Symbols for Game Icons

Use scalable system icons:

```swift
let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium, scale: .large)
let trainIcon = UIImage(systemName: "tram.fill", withConfiguration: config)
let stationIcon = UIImage(systemName: "mappin.circle.fill", withConfiguration: config)
let menuIcon = UIImage(systemName: "line.3.horizontal", withConfiguration: config)

button.setImage(trainIcon, for: .normal)
button.tintColor = .systemBlue
```

**Common symbols for games**:
- `play.fill`, `pause.fill`, `stop.fill`
- `gear`, `ellipsis.circle`
- `star.fill`, `heart.fill`
- `arrow.clockwise`, `xmark`

## Best Practices

1. **Always test on physical devices** - Simulator doesn't reflect real performance
2. **Use Instruments** - Profile with Time Profiler, Allocations, and Core Animation
3. **Minimize draw calls** - Batch similar UI elements, use texture atlases
4. **Respect safe areas** - Essential for notched devices
5. **Provide haptic feedback** - Enhances tactile feel on supported devices
6. **Support dark mode** - Use semantic colors and asset catalog variants
7. **Test memory under pressure** - Simulate in Xcode to catch leaks
8. **Optimize assets** - Compress images, use @2x/@3x appropriately
9. **Profile frame drops** - Use `CADisplayLink` timestamp analysis
10. **Cache expensive operations** - Drawing, path calculations, image loading

## Common Pitfalls

- **Don't call `setNeedsDisplay()` every frame** - Only when content changes
- **Avoid transparency** - Set `isOpaque = true` when possible
- **Don't use `UIViewPropertyAnimator` in game loop** - Use CADisplayLink instead
- **Don't forget to invalidate CADisplayLink** - Memory leak risk
- **Don't ignore landscape constraints** - Test both left/right orientations
- **Don't skip device-specific sizing** - iPhone vs iPad have different expectations

## Testing Checklist

- [ ] Runs at 60fps on target devices (iPhone 11+)
- [ ] No frame drops during heavy scenes (10+ animated objects)
- [ ] Memory stable over 10+ minute session
- [ ] Touch response < 16ms (1 frame)
- [ ] Landscape left/right both work
- [ ] Safe area respected on all devices
- [ ] Dark mode looks correct
- [ ] Haptics work on supported devices
- [ ] App state survives backgrounding
- [ ] No crashes in 30-minute stress test