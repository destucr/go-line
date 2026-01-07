# iOS Game Performance Optimization

Use this skill when optimizing iOS games to maintain 60fps, reduce memory usage, and prevent thermal throttling during gameplay.

## When to Apply

- Game frame rate drops below 60fps
- Memory warnings or crashes
- Device gets hot during play
- Battery drains too quickly
- Launch time exceeds 2 seconds
- Profiling shows CPU/GPU bottlenecks

## Instructions

### 1. Target Performance Metrics

**60fps Requirements**:
- Frame budget: 16.67ms per frame
- CPU: <10ms per frame
- GPU: <10ms per frame
- Memory: <150MB for iPhone, <300MB for iPad

**Measure with Instruments**:
```swift
// In Xcode: Product > Profile > Time Profiler
// Check: CPU usage, GPU usage, Memory, Energy Impact
```

### 2. CADisplayLink Optimization

**Efficient game loop**:
```swift
class GameEngine {
    private var displayLink: CADisplayLink?
    private var lastFrameTime: CFTimeInterval = 0
    private let targetDelta: CFTimeInterval = 1.0 / 60.0 // 60fps
    
    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func update(_ link: CADisplayLink) {
        let currentTime = link.timestamp
        let deltaTime = currentTime - lastFrameTime
        
        // Skip if running too fast (>60fps cap)
        guard deltaTime >= targetDelta else { return }
        
        lastFrameTime = currentTime
        
        // Update game state
        autoreleasepool {
            updateGameLogic(delta: Float(deltaTime))
            render()
        }
    }
    
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    deinit {
        stop()
    }
}
```

**Key points**:
- Use `preferredFramesPerSecond` to cap frame rate
- Use `autoreleasepool` to release temporary objects immediately
- Measure actual delta time (don't assume 16.67ms)

### 3. Object Pooling

Reuse expensive objects instead of creating/destroying:

```swift
protocol Poolable: AnyObject {
    func reset()
}

class ObjectPool<T: Poolable> {
    private var available: [T] = []
    private var inUse: Set<ObjectIdentifier> = []
    private let factory: () -> T
    private let maxSize: Int
    
    init(initialSize: Int = 10, maxSize: Int = 100, factory: @escaping () -> T) {
        self.factory = factory
        self.maxSize = maxSize
        available.reserveCapacity(initialSize)
        
        // Pre-populate
        for _ in 0..<initialSize {
            available.append(factory())
        }
    }
    
    func acquire() -> T {
        let object = available.popLast() ?? factory()
        inUse.insert(ObjectIdentifier(object))
        return object
    }
    
    func release(_ object: T) {
        guard available.count < maxSize else { return }
        
        inUse.remove(ObjectIdentifier(object))
        object.reset()
        available.append(object)
    }
    
    func drain() {
        available.removeAll(keepingCapacity: true)
        inUse.removeAll()
    }
}

// Usage
class Particle: Poolable {
    var position: CGPoint = .zero
    var velocity: CGVector = .zero
    
    func reset() {
        position = .zero
        velocity = .zero
    }
}

let particlePool = ObjectPool<Particle>(initialSize: 50, maxSize: 200) { Particle() }

// Spawn particle
let particle = particlePool.acquire()
particle.position = spawnPoint

// When particle dies
particlePool.release(particle)
```

### 4. Texture Atlas and Image Caching

**Single cache instance**:
```swift
final class TextureCache {
    static let shared = TextureCache()
    private var cache: [String: UIImage] = [:]
    private let lock = NSLock()
    
    private init() {}
    
    func image(named name: String) -> UIImage? {
        lock.lock()
        defer { lock.unlock() }
        
        if let cached = cache[name] {
            return cached
        }
        
        guard let image = UIImage(named: name) else { return nil }
        cache[name] = image
        return image
    }
    
    func preload(_ names: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            for name in names {
                _ = self.image(named: name)
            }
        }
    }
    
    func clearCache() {
        lock.lock()
        cache.removeAll()
        lock.unlock()
    }
}

// Preload at app start
TextureCache.shared.preload([
    "train_blue", "train_red", "station_large", "station_small"
])
```

**Use texture atlas**:
- In Assets.xcassets, create folder with `.atlas` suffix
- Add related images (e.g., all train sprites)
- iOS automatically packs into single texture

### 5. Layer Optimization

**Rasterization for static content**:
```swift
// Complex view that doesn't change
hudContainer.layer.shouldRasterize = true
hudContainer.layer.rasterizationScale = UIScreen.main.scale

// Warning: Only use for static views, expensive for animated content
```

**GPU rendering**:
```swift
// Offload drawing to GPU thread
gameView.layer.drawsAsynchronously = true
```

**Reduce transparency**:
```swift
// Opaque views render faster
view.isOpaque = true
view.backgroundColor = .white // Not .clear

// Check with Instruments > Core Animation:
// - Enable "Color Blended Layers" (red = blending, green = no blending)
```

**Shadow optimization**:
```swift
// Bad: Shadow recalculated every frame
view.layer.shadowColor = UIColor.black.cgColor
view.layer.shadowOpacity = 0.5
view.layer.shadowRadius = 5

// Good: Cache shadow path
view.layer.shadowColor = UIColor.black.cgColor
view.layer.shadowOpacity = 0.5
view.layer.shadowRadius = 5
view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath // Cache this!
```

### 6. Efficient Drawing

**Minimize setNeedsDisplay calls**:
```swift
class GameView: UIView {
    private var isDirty = false
    private var dirtyRect: CGRect = .zero
    
    func markDirty(_ rect: CGRect) {
        if isDirty {
            dirtyRect = dirtyRect.union(rect)
        } else {
            dirtyRect = rect
            isDirty = true
        }
        
        setNeedsDisplay(dirtyRect) // Partial redraw
    }
    
    override func draw(_ rect: CGRect) {
        guard isDirty else { return }
        
        // Only redraw dirty region
        // ... drawing code ...
        
        isDirty = false
    }
}
```

**Batch drawing operations**:
```swift
override func draw(_ rect: CGRect) {
    guard let context = UIGraphicsGetCurrentContext() else { return }
    
    // Save state once
    context.saveGState()
    
    // Batch same-colored objects
    context.setFillColor(UIColor.blue.cgColor)
    for train in blueTrains {
        context.fill(train.frame)
    }
    
    context.setFillColor(UIColor.red.cgColor)
    for train in redTrains {
        context.fill(train.frame)
    }
    
    // Restore once
    context.restoreGState()
}
```

### 7. Memory Management

**Detect memory warnings**:
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleMemoryWarning),
        name: UIApplication.didReceiveMemoryWarningNotification,
        object: nil
    )
}

@objc private func handleMemoryWarning() {
    // Clear caches
    TextureCache.shared.clearCache()
    particlePool.drain()
    
    // Stop non-essential animations
    pauseBackgroundEffects()
}
```

**Weak references for delegates**:
```swift
protocol GameDelegate: AnyObject {
    func gameDidEnd(score: Int)
}

class GameEngine {
    weak var delegate: GameDelegate? // Prevent retain cycle
}
```

**Use value types when possible**:
```swift
// Struct (stack allocated, faster)
struct Particle {
    var position: CGPoint
    var velocity: CGVector
}

// Only use class if inheritance/identity needed
```

### 8. CPU Optimization

**Profiling hotspots**:
```swift
// Instruments > Time Profiler
// Look for functions taking >5ms
// Common culprits: collision detection, pathfinding, sorting
```

**Spatial partitioning** (for collision detection):
```swift
class QuadTree {
    // Divide space into grid
    // Only check nearby objects for collision
    // Reduces O(n²) to O(n log n)
}

// Example: Only check trains in same region
func checkCollisions() {
    let nearbyTrains = spatialHash.query(region: currentRegion)
    for train in nearbyTrains {
        // Check collision
    }
}
```

**Throttle expensive operations**:
```swift
class AIManager {
    private var lastPathUpdate: TimeInterval = 0
    private let pathUpdateInterval: TimeInterval = 0.5 // 2 times per second
    
    func update(currentTime: TimeInterval) {
        // Update AI paths less frequently
        if currentTime - lastPathUpdate > pathUpdateInterval {
            recalculatePaths()
            lastPathUpdate = currentTime
        }
        
        // Update positions every frame
        updatePositions()
    }
}
```

### 9. GPU Optimization

**Reduce overdraw**:
```swift
// Draw back-to-front
// Set clipsToBounds = true
// Don't draw offscreen objects

func render() {
    let visibleRect = gameView.bounds
    
    for object in gameObjects where object.frame.intersects(visibleRect) {
        object.draw() // Only draw visible
    }
}
```

**Use lower resolution for backgrounds**:
```swift
// @1x for background, @2x/@3x for foreground
let backgroundImage = UIImage(named: "background")?.resizeTo(width: view.bounds.width)
```

### 10. Thermal Management

**Detect thermal state**:
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(thermalStateChanged),
        name: ProcessInfo.thermalStateDidChangeNotification,
        object: nil
    )
}

@objc private func thermalStateChanged() {
    let state = ProcessInfo.processInfo.thermalState
    
    switch state {
    case .nominal:
        qualityLevel = .high
    case .fair:
        qualityLevel = .medium
    case .serious:
        qualityLevel = .low
        reduceParticleEffects()
    case .critical:
        qualityLevel = .minimum
        disableNonEssentialEffects()
    @unknown default:
        break
    }
}
```

**Quality scaling**:
```swift
enum QualityLevel {
    case high, medium, low, minimum
    
    var particleCount: Int {
        switch self {
        case .high: return 200
        case .medium: return 100
        case .low: return 50
        case .minimum: return 20
        }
    }
    
    var shadowsEnabled: Bool {
        return self == .high || self == .medium
    }
}
```

### 11. Launch Time Optimization

**Lazy initialization**:
```swift
// Bad: Load everything at launch
override func viewDidLoad() {
    loadAllAssets()
    initializeAllSystems()
}

// Good: Load on-demand
private lazy var particleSystem: ParticleSystem = {
    return ParticleSystem()
}()

func startGame() {
    // Load game assets now
    loadGameAssets()
}
```

**Background loading**:
```swift
func preloadAssets() {
    DispatchQueue.global(qos: .userInitiated).async {
        let assets = ["train1", "train2", "station"]
        assets.forEach { TextureCache.shared.image(named: $0) }
        
        DispatchQueue.main.async {
            self.assetsLoaded = true
        }
    }
}
```

## Profiling Workflow

1. **Profile with Instruments**:
   ```
   Xcode > Product > Profile > Select Instrument
   - Time Profiler: CPU hotspots
   - Allocations: Memory leaks
   - Core Animation: GPU rendering issues
   - Energy Log: Battery impact
   ```

2. **Identify bottlenecks**:
   - Functions taking >5ms
   - Memory allocations in game loop
   - Excessive layer compositing

3. **Optimize iteratively**:
   - Fix highest impact issues first
   - Measure before/after
   - Test on target devices (not Simulator)

4. **Regression testing**:
   - Profile regularly
   - Track metrics over time
   - Set performance budgets

## Performance Checklist

- [ ] 60fps maintained with 10+ animated objects
- [ ] No frame drops during heavy scenes
- [ ] Memory usage <150MB on iPhone
- [ ] No memory leaks after 10-minute session
- [ ] Launch time <2 seconds
- [ ] No thermal throttling after 15 minutes
- [ ] Battery drain <10% per 30 minutes
- [ ] Works smoothly on iPhone 11 (minimum target)

## Common Issues & Fixes

| Issue | Cause | Solution |
|-------|-------|----------|
| Frame drops | Too many draw calls | Batch drawing, use texture atlas |
| High CPU | Collision O(n²) | Spatial partitioning |
| Memory spikes | Creating/destroying objects | Object pooling |
| Slow launch | Loading all assets | Lazy loading, background threads |
| Device hot | High GPU usage | Reduce overdraw, lower quality |
| Jittery animation | Inconsistent delta time | Cap frame rate, measure actual delta |

## Best Practices

1. **Profile early and often** on real devices
2. **Set performance budgets** (time/memory per system)
3. **Use object pools** for frequently created/destroyed objects
4. **Cache expensive calculations** (paths, layouts)
5. **Throttle expensive operations** (AI, physics)
6. **Monitor thermal state** and adapt quality
7. **Test on oldest supported device** (worst case)
8. **Use Instruments** to find actual bottlenecks (don't guess)